import 'dart:async';
import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/emg/emg_hardware.dart';
import '../../data/history/session_history_store.dart';
import '../../data/notifications/local_notification_service.dart';
import '../../data/research/research_context_store.dart';
import '../../domain/models/emg_frame.dart';
import '../../domain/models/feedback_view.dart';
import '../../domain/models/research_context.dart';
import '../../domain/models/session_summary.dart';
import '../../domain/models/session_tab.dart';
import '../../domain/models/target_muscle.dart';
import '../../domain/services/signal_processor.dart';

enum SessionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  signalLost,
  error,
}

String greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class SessionState extends Equatable {
  const SessionState({
    required this.status,
    required this.selectedTab,
    required this.busy,
    required this.latestRaw,
    required this.samplesPerSecond,
    required this.sessionSeconds,
    required this.calibrationMidpoint,
    required this.liveActivation,
    required this.symmetryIndex,
    required this.rawPoints,
    required this.rawPoints3,
    required this.history,
    required this.notice,
    required this.errorMessage,
    required this.connectedAtMs,
    required this.lastFrameMs,
    required this.channelMapping,
    required this.leftTrapRms,
    required this.rightTrapRms,
    required this.normalisedLeftActivation,
    required this.normalisedRightActivation,
    required this.baselineRmsLeft,
    required this.baselineRmsRight,
    required this.isRecording,
    required this.researchContextLoaded,
    required this.participants,
    required this.activeParticipantId,
    required this.selectedScenario,
    required this.targetMuscle,
    required this.selectedFeedbackView,
    required this.isSimulatedHardware,
    required this.notificationPreferences,
    this.calibratedAt,
  });

  factory SessionState.initial({required bool isSimulatedHardware}) {
    return SessionState(
      status: SessionStatus.disconnected,
      selectedTab: SessionTab.dashboard,
      busy: false,
      latestRaw: SignalProcessor.adcMidpoint,
      samplesPerSecond: 0,
      sessionSeconds: 0,
      calibrationMidpoint: SignalProcessor.adcMidpoint,
      liveActivation: 0,
      symmetryIndex: null,
      rawPoints: List<int>.filled(
        3000,
        SignalProcessor.adcMidpoint,
        growable: true,
      ),
      rawPoints3: List<int>.filled(
        3000,
        SignalProcessor.adcMidpoint,
        growable: true,
      ),
      history: const <SessionSummary>[],
      notice: null,
      errorMessage: null,
      connectedAtMs: null,
      lastFrameMs: null,
      channelMapping: {'A': 'right', 'B': 'left'},
      leftTrapRms: 0.0,
      rightTrapRms: 0.0,
      normalisedLeftActivation: 0.0,
      normalisedRightActivation: 0.0,
      baselineRmsLeft: 0.0,
      baselineRmsRight: 0.0,
      isRecording: false,
      researchContextLoaded: false,
      participants: const <ParticipantProfile>[],
      activeParticipantId: null,
      selectedScenario: UsageScenario.officeDesk,
      targetMuscle: TargetMuscle.trapezius,
      selectedFeedbackView: FeedbackView.anatomicalHeatmap,
      isSimulatedHardware: isSimulatedHardware,
      notificationPreferences: const NotificationPreferences(),
      calibratedAt: null,
    );
  }

  final SessionStatus status;
  final SessionTab selectedTab;
  final bool busy;
  final int latestRaw;
  final int samplesPerSecond;
  final int sessionSeconds;
  final int calibrationMidpoint;
  final double liveActivation;
  final double? symmetryIndex;
  final List<int> rawPoints;
  final List<int> rawPoints3;
  final List<SessionSummary> history;
  final String? notice;
  final String? errorMessage;
  final int? connectedAtMs;
  final int? lastFrameMs;
  final Map<String, String> channelMapping;

  final double leftTrapRms;
  final double rightTrapRms;
  final double normalisedLeftActivation;
  final double normalisedRightActivation;
  final double baselineRmsLeft;
  final double baselineRmsRight;
  final bool isRecording;
  final bool researchContextLoaded;
  final List<ParticipantProfile> participants;
  final String? activeParticipantId;
  final UsageScenario selectedScenario;
  final TargetMuscle targetMuscle;
  final FeedbackView? selectedFeedbackView;
  final bool isSimulatedHardware;
  final NotificationPreferences notificationPreferences;
  final DateTime? calibratedAt;

  bool get isConnected =>
      status == SessionStatus.connected || status == SessionStatus.signalLost;

  bool get bilateralReady => symmetryIndex != null;

  String get greeting => greetingForHour(DateTime.now().hour);

  ParticipantProfile? get activeParticipant {
    for (final participant in participants) {
      if (participant.id == activeParticipantId) return participant;
    }
    return null;
  }

  String get displayName => activeParticipant?.displayLabel ?? 'Participant';

  List<SessionSummary> get activeHistory => history
      .where((summary) => summary.participantId == activeParticipantId)
      .toList(growable: false);

  double get baselineCorrectedSI {
    final l = leftTrapRms - baselineRmsLeft;
    final r = rightTrapRms - baselineRmsRight;
    final denom = l.abs() + r.abs();
    if (denom == 0) return 0.0;
    return ((r - l) / denom) * 100.0;
  }

  SessionState copyWith({
    SessionStatus? status,
    SessionTab? selectedTab,
    bool? busy,
    int? latestRaw,
    int? samplesPerSecond,
    int? sessionSeconds,
    int? calibrationMidpoint,
    double? liveActivation,
    double? symmetryIndex,
    bool clearSymmetryIndex = false,
    List<int>? rawPoints,
    List<int>? rawPoints3,
    List<SessionSummary>? history,
    String? notice,
    bool clearNotice = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? connectedAtMs,
    bool clearConnectedAtMs = false,
    int? lastFrameMs,
    bool clearLastFrameMs = false,
    Map<String, String>? channelMapping,
    double? leftTrapRms,
    double? rightTrapRms,
    double? normalisedLeftActivation,
    double? normalisedRightActivation,
    double? baselineRmsLeft,
    double? baselineRmsRight,
    bool? isRecording,
    bool? researchContextLoaded,
    List<ParticipantProfile>? participants,
    String? activeParticipantId,
    bool clearActiveParticipantId = false,
    UsageScenario? selectedScenario,
    TargetMuscle? targetMuscle,
    FeedbackView? selectedFeedbackView,
    bool clearSelectedFeedbackView = false,
    bool? isSimulatedHardware,
    NotificationPreferences? notificationPreferences,
    DateTime? calibratedAt,
    bool clearCalibratedAt = false,
  }) {
    return SessionState(
      status: status ?? this.status,
      selectedTab: selectedTab ?? this.selectedTab,
      busy: busy ?? this.busy,
      latestRaw: latestRaw ?? this.latestRaw,
      samplesPerSecond: samplesPerSecond ?? this.samplesPerSecond,
      sessionSeconds: sessionSeconds ?? this.sessionSeconds,
      calibrationMidpoint: calibrationMidpoint ?? this.calibrationMidpoint,
      liveActivation: liveActivation ?? this.liveActivation,
      symmetryIndex: clearSymmetryIndex
          ? null
          : (symmetryIndex ?? this.symmetryIndex),
      rawPoints: rawPoints ?? this.rawPoints,
      rawPoints3: rawPoints3 ?? this.rawPoints3,
      history: history ?? this.history,
      notice: clearNotice ? null : (notice ?? this.notice),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      connectedAtMs: clearConnectedAtMs
          ? null
          : (connectedAtMs ?? this.connectedAtMs),
      lastFrameMs: clearLastFrameMs ? null : (lastFrameMs ?? this.lastFrameMs),
      channelMapping: channelMapping ?? this.channelMapping,
      leftTrapRms: leftTrapRms ?? this.leftTrapRms,
      rightTrapRms: rightTrapRms ?? this.rightTrapRms,
      normalisedLeftActivation:
          normalisedLeftActivation ?? this.normalisedLeftActivation,
      normalisedRightActivation:
          normalisedRightActivation ?? this.normalisedRightActivation,
      baselineRmsLeft: baselineRmsLeft ?? this.baselineRmsLeft,
      baselineRmsRight: baselineRmsRight ?? this.baselineRmsRight,
      isRecording: isRecording ?? this.isRecording,
      researchContextLoaded:
          researchContextLoaded ?? this.researchContextLoaded,
      participants: participants ?? this.participants,
      activeParticipantId: clearActiveParticipantId
          ? null
          : (activeParticipantId ?? this.activeParticipantId),
      selectedScenario: selectedScenario ?? this.selectedScenario,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      selectedFeedbackView: clearSelectedFeedbackView
          ? null
          : (selectedFeedbackView ?? this.selectedFeedbackView),
      isSimulatedHardware: isSimulatedHardware ?? this.isSimulatedHardware,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      calibratedAt: clearCalibratedAt
          ? null
          : (calibratedAt ?? this.calibratedAt),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    selectedTab,
    busy,
    latestRaw,
    samplesPerSecond,
    sessionSeconds,
    calibrationMidpoint,
    liveActivation,
    symmetryIndex,
    rawPoints,
    rawPoints3,
    history,
    notice,
    errorMessage,
    connectedAtMs,
    lastFrameMs,
    channelMapping,
    leftTrapRms,
    rightTrapRms,
    normalisedLeftActivation,
    normalisedRightActivation,
    baselineRmsLeft,
    baselineRmsRight,
    isRecording,
    researchContextLoaded,
    participants,
    activeParticipantId,
    selectedScenario,
    targetMuscle,
    selectedFeedbackView,
    isSimulatedHardware,
    notificationPreferences,
    calibratedAt,
  ];
}

class SessionBloc extends Cubit<SessionState> {
  static const int _maxSavedSessions = 500;

  SessionBloc({
    required EmgHardware hardware,
    required SessionHistoryStore historyStore,
    required ResearchContextStore researchContextStore,
    required LocalNotificationService notificationService,
  }) : _hardware = hardware,
       _historyStore = historyStore,
       _researchContextStore = researchContextStore,
       _notificationService = notificationService,
       _signalProcessor = const SignalProcessor(),
       super(SessionState.initial(isSimulatedHardware: hardware.isSimulated)) {
    _rebuildTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (isClosed) {
        return;
      }
      _emitSnapshot();
    });
    _spsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) {
        return;
      }
      _samplesPerSecond = _samplesThisSecond;
      _samplesThisSecond = 0;
      if (_sessionStartedAt != null) {
        final seconds = DateTime.now()
            .difference(_sessionStartedAt!)
            .inSeconds
            .clamp(0, 9999);
        emit(state.copyWith(sessionSeconds: seconds));
        _autoSaveCounter++;
        if (_autoSaveCounter >= 30 && !_autoSaveInFlight) {
          _autoSaveCounter = 0;
          _autoSaveInFlight = true;
          unawaited(_runAutoSave());
        }
      }
    });
    _signalLossTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (isClosed) {
        return;
      }
      final lastFrame = _lastFrameAt;
      if (lastFrame == null) {
        return;
      }
      final elapsed = DateTime.now().difference(lastFrame);
      if (state.isConnected &&
          elapsed.inMilliseconds > 2000 &&
          state.status != SessionStatus.signalLost) {
        if (_sessionStartedAt != null) {
          _siBuffer.clear();
        }
        emit(
          state.copyWith(
            status: SessionStatus.signalLost,
            notice: 'Signal lost',
          ),
        );
      }
    });
  }

  final EmgHardware _hardware;
  final SessionHistoryStore _historyStore;
  final ResearchContextStore _researchContextStore;
  final LocalNotificationService _notificationService;
  final SignalProcessor _signalProcessor;

  StreamSubscription<EmgFrame>? _frameSubscription;
  Timer? _rebuildTimer;
  Timer? _spsTimer;
  Timer? _signalLossTimer;
  int _autoSaveCounter = 0;

  final List<int> _rawPoints = List<int>.filled(
    3000,
    SignalProcessor.adcMidpoint,
    growable: true,
  );
  final List<int> _rawPoints3 = List<int>.filled(
    3000,
    SignalProcessor.adcMidpoint,
    growable: true,
  );
  final List<double> _activationPoints = <double>[];
  final List<SessionSummary> _history = <SessionSummary>[];

  DateTime? _sessionStartedAt;
  FeedbackView? _recordingFeedbackView;
  DateTime? _connectedAt;
  DateTime? _lastFrameAt;
  int _samplesThisSecond = 0;
  int _samplesPerSecond = 0;
  int _latestRaw = SignalProcessor.adcMidpoint;
  int _calibrationMidpoint = SignalProcessor.adcMidpoint;
  double _liveActivation = 0;
  double _activationSum = 0;
  double _activationSumRight = 0;
  int _activationCount = 0;
  int _peakRaw = SignalProcessor.adcMidpoint;
  bool _busy = false;
  DateTime? _imbalanceStartedAt;
  DateTime? _lastGuidanceNotificationAt;
  bool _notificationInFlight = false;
  bool _autoSaveInFlight = false;

  double _sessionPeakLeft = 0.0;
  double _sessionPeakRight = 0.0;
  double _sessionPeakRmsLeft = 0.0;
  double _sessionPeakRmsRight = 0.0;
  double _windowActivationSum = 0;
  double _windowActivationSumRight = 0;
  double _windowRmsSumLeft = 0;
  double _windowRmsSumRight = 0;
  int _windowActivationCount = 0;
  double _sessionSymmetrySum = 0.0;
  int _sessionSymmetryCount = 0;

  final _leftFilter = SignalFilterState();
  final _rightFilter = SignalFilterState();

  final Queue<double> _siBuffer = Queue<double>();
  static const int _siBufferSize = 8;
  static const double _minimumCombinedRmsForBalance = 80.0;
  static const double _minimumCombinedActivationForBalance = 0.12;
  static const double _minimumSingleSideActivationForBalance = 0.04;

  Future<void> start() async {
    final failures = <String>[];
    final steps = <(String, Future<void> Function())>[
      ('session history', _loadHistory),
      ('research settings', _loadResearchContext),
      ('channel mapping', _loadChannelMapping),
      ('notifications', _notificationService.initialize),
    ];
    for (final (label, action) in steps) {
      try {
        await action();
      } catch (_) {
        failures.add(label);
      }
    }
    if (!isClosed && failures.isNotEmpty) {
      emit(
        state.copyWith(
          researchContextLoaded:
              state.researchContextLoaded ||
              failures.contains('research settings'),
          errorMessage:
              'Some local features could not be initialized: '
              '${failures.join(', ')}.',
        ),
      );
    }
  }

  Future<void> _loadResearchContext() async {
    final snapshot = await _researchContextStore.load();
    if (isClosed) return;
    emit(
      state.copyWith(
        researchContextLoaded: true,
        participants: List<ParticipantProfile>.unmodifiable(
          snapshot.participants,
        ),
        activeParticipantId: snapshot.activeParticipantId,
        clearActiveParticipantId: snapshot.activeParticipantId == null,
        selectedScenario: snapshot.scenario,
        notificationPreferences: snapshot.notificationPreferences,
        errorMessage: snapshot.rejectedEntryCount == 0
            ? state.errorMessage
            : '${snapshot.rejectedEntryCount} unreadable research setting '
                  '${snapshot.rejectedEntryCount == 1 ? 'entry was' : 'entries were'} ignored.',
      ),
    );
  }

  Future<ParticipantProfile> createParticipant() async {
    if (state.isRecording) {
      throw StateError('Stop recording before changing participants.');
    }
    final used = state.participants.map((item) => item.id).toSet();
    var number = 1;
    while (used.contains('P${number.toString().padLeft(3, '0')}')) {
      number++;
    }
    final participant = ParticipantProfile(
      id: 'P${number.toString().padLeft(3, '0')}',
      createdAt: DateTime.now(),
    );
    final participants = <ParticipantProfile>[
      ...state.participants,
      participant,
    ];
    await _researchContextStore.saveParticipants(participants, participant.id);
    emit(
      state.copyWith(
        participants: List<ParticipantProfile>.unmodifiable(participants),
        activeParticipantId: participant.id,
      ),
    );
    return participant;
  }

  Future<void> selectParticipant(String participantId) async {
    if (state.isRecording) {
      throw StateError('Stop recording before changing participants.');
    }
    if (!state.participants.any((item) => item.id == participantId)) return;
    await _researchContextStore.saveParticipants(
      state.participants,
      participantId,
    );
    emit(state.copyWith(activeParticipantId: participantId));
  }

  Future<void> deleteParticipant(String participantId) async {
    if (state.isRecording) {
      throw StateError('Stop recording before deleting a participant.');
    }
    final participants = state.participants
        .where((item) => item.id != participantId)
        .toList(growable: false);
    _history.removeWhere((item) => item.participantId == participantId);
    final nextActive = state.activeParticipantId == participantId
        ? (participants.isEmpty ? null : participants.first.id)
        : state.activeParticipantId;
    await Future.wait(<Future<void>>[
      _researchContextStore.saveParticipants(participants, nextActive),
      _historyStore.save(_history),
    ]);
    emit(
      state.copyWith(
        participants: participants,
        activeParticipantId: nextActive,
        clearActiveParticipantId: nextActive == null,
        history: List<SessionSummary>.unmodifiable(_history),
      ),
    );
  }

  Future<void> selectScenario(UsageScenario scenario) async {
    if (state.isRecording) {
      throw StateError('Stop recording before changing the scenario.');
    }
    await _researchContextStore.saveScenario(scenario);
    emit(state.copyWith(selectedScenario: scenario));
  }

  void selectTargetMuscle(TargetMuscle muscle) {
    if (state.isRecording) {
      throw StateError('Stop recording before changing the target muscle.');
    }
    emit(state.copyWith(targetMuscle: muscle));
  }

  void selectFeedbackView(FeedbackView? feedbackView) {
    if (state.isRecording) {
      throw StateError('Stop recording before changing the feedback view.');
    }
    emit(
      state.copyWith(
        selectedFeedbackView: feedbackView,
        clearSelectedFeedbackView: feedbackView == null,
      ),
    );
  }

  Future<void> saveBaselineReference(
    BaselineReferencePosition position, {
    double? leftRms,
    double? rightRms,
  }) async {
    final participantId = state.activeParticipantId;
    if (participantId == null) {
      throw StateError('Select a participant before saving baseline values.');
    }
    if (!state.isConnected) {
      throw StateError(
        'Connect the EMG sensors before saving baseline values.',
      );
    }
    final lastFrameMs = state.lastFrameMs;
    final hasRecentSignal =
        lastFrameMs != null &&
        DateTime.now().millisecondsSinceEpoch - lastFrameMs < 2000;
    final capturedLeft = leftRms ?? state.leftTrapRms;
    final capturedRight = rightRms ?? state.rightTrapRms;
    if (!hasRecentSignal ||
        !capturedLeft.isFinite ||
        !capturedRight.isFinite ||
        capturedLeft <= 0 ||
        capturedRight <= 0) {
      throw StateError('Wait for a stable signal before saving a baseline.');
    }

    final reference = BaselineReference(
      position: position,
      leftRms: capturedLeft,
      rightRms: capturedRight,
      recordedAt: DateTime.now(),
    );
    final participants = state.participants
        .map(
          (participant) => participant.id == participantId
              ? participant.copyWithBaseline(reference)
              : participant,
        )
        .toList(growable: false);

    await _researchContextStore.saveParticipants(participants, participantId);

    emit(
      state.copyWith(
        participants: List<ParticipantProfile>.unmodifiable(participants),
        baselineRmsLeft: position == BaselineReferencePosition.straightAhead
            ? reference.leftRms
            : state.baselineRmsLeft,
        baselineRmsRight: position == BaselineReferencePosition.straightAhead
            ? reference.rightRms
            : state.baselineRmsRight,
        calibratedAt: position == BaselineReferencePosition.straightAhead
            ? reference.recordedAt
            : state.calibratedAt,
        notice:
            '${position.label} baseline saved (${reference.leftRms.toStringAsFixed(0)} / ${reference.rightRms.toStringAsFixed(0)} ADC RMS)',
      ),
    );
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    var allowed = true;
    if (enabled) {
      allowed = await _notificationService.requestPermission();
    }
    final preferences = state.notificationPreferences.copyWith(
      enabled: enabled && allowed,
    );
    await _researchContextStore.saveNotificationPreferences(preferences);
    emit(state.copyWith(notificationPreferences: preferences));
    return allowed;
  }

  Future<void> updateNotificationPreferences({
    int? imbalanceThreshold,
    int? sustainedSeconds,
    int? cooldownMinutes,
  }) async {
    final preferences = state.notificationPreferences.copyWith(
      imbalanceThreshold: imbalanceThreshold,
      sustainedSeconds: sustainedSeconds,
      cooldownMinutes: cooldownMinutes,
    );
    await _researchContextStore.saveNotificationPreferences(preferences);
    emit(state.copyWith(notificationPreferences: preferences));
  }

  Future<void> _loadChannelMapping() async {
    final prefs = await SharedPreferences.getInstance();
    final storedA = prefs.getString('channel_mapping.A');
    final storedB = prefs.getString('channel_mapping.B');

    if (_isValidChannelMapping(storedA, storedB) && !isClosed) {
      final mapping = {'A': storedA!, 'B': storedB!};
      if (mapping != state.channelMapping) {
        emit(state.copyWith(channelMapping: mapping));
      }
    }
  }

  Future<void> setChannelMapping(String channelA, String channelB) async {
    if (state.isRecording) {
      throw StateError('Stop recording before changing channel mapping.');
    }
    if (!_isValidChannelMapping(channelA, channelB)) {
      throw ArgumentError('Channels must map once each to left and right.');
    }
    final mapping = {'A': channelA, 'B': channelB};
    emit(state.copyWith(channelMapping: mapping));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('channel_mapping.A', channelA);
    await prefs.setString('channel_mapping.B', channelB);
  }

  bool get isChannelMappingConfigured {
    final mapping = state.channelMapping;
    return mapping['A'] != null && mapping['B'] != null;
  }

  bool _isValidChannelMapping(String? channelA, String? channelB) {
    return <String?>{
          channelA,
          channelB,
        }.containsAll(<String>{'left', 'right'}) &&
        channelA != channelB;
  }

  Future<void> connect(String macAddress) async {
    if (_busy || state.busy || state.isConnected) {
      return;
    }
    _busy = true;
    emit(
      state.copyWith(
        status: SessionStatus.connecting,
        busy: true,
        notice: 'Connecting to biosignalsplux...',
        clearErrorMessage: true,
      ),
    );

    try {
      await _hardware.connect(macAddress);
      await _hardware.startAcquisition(
        channels: const <int>[1, 3],
        sampleRate: 1000,
      );

      await _frameSubscription?.cancel();
      _frameSubscription = _hardware.frames.listen(
        _onFrame,
        onError: _onFrameError,
      );
      _connectedAt = DateTime.now();

      emit(
        state.copyWith(
          status: SessionStatus.connected,
          busy: false,
          connectedAtMs: _connectedAt!.millisecondsSinceEpoch,
          notice: 'Connected',
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      await _bestEffort(
        () => _frameSubscription?.cancel() ?? Future<void>.value(),
        const Duration(seconds: 1),
      );
      _frameSubscription = null;
      await _bestEffort(_hardware.stopAcquisition, const Duration(seconds: 2));
      await _bestEffort(_hardware.disconnect, const Duration(seconds: 3));
      _connectedAt = null;
      emit(
        state.copyWith(
          status: SessionStatus.error,
          busy: false,
          errorMessage: _displayError(error),
          clearNotice: true,
        ),
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> disconnect() async {
    if (_busy || state.busy) {
      return;
    }
    _busy = true;
    emit(
      state.copyWith(
        status: SessionStatus.disconnecting,
        busy: true,
        notice: 'Disconnecting...',
        clearErrorMessage: true,
      ),
    );

    await _bestEffort(
      () => _frameSubscription?.cancel() ?? Future<void>.value(),
      const Duration(seconds: 1),
    );
    _frameSubscription = null;

    await _bestEffort(_hardware.stopAcquisition, const Duration(seconds: 2));
    await _bestEffort(_hardware.disconnect, const Duration(seconds: 3));
    await _bestEffort(_persistSessionIfNeeded, const Duration(seconds: 2));

    _resetSession();
    _busy = false;
    emit(
      state.copyWith(
        status: SessionStatus.disconnected,
        busy: false,
        latestRaw: SignalProcessor.adcMidpoint,
        samplesPerSecond: 0,
        sessionSeconds: 0,
        calibrationMidpoint: SignalProcessor.adcMidpoint,
        liveActivation: 0,
        clearSymmetryIndex: true,
        rawPoints: List<int>.unmodifiable(_rawPoints),
        rawPoints3: List<int>.unmodifiable(_rawPoints3),
        history: List<SessionSummary>.unmodifiable(_history),
        leftTrapRms: 0,
        rightTrapRms: 0,
        normalisedLeftActivation: 0,
        normalisedRightActivation: 0,
        baselineRmsLeft: 0,
        baselineRmsRight: 0,
        isRecording: false,
        clearConnectedAtMs: true,
        clearLastFrameMs: true,
        clearCalibratedAt: true,
        notice: 'Disconnected',
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _bestEffort(
    Future<void> Function() action,
    Duration timeout,
  ) async {
    try {
      await action().timeout(timeout);
    } catch (_) {}
  }

  void calibrate() {
    final baselineLeft = state.leftTrapRms;
    final baselineRight = state.rightTrapRms;
    emit(
      state.copyWith(
        baselineRmsLeft: baselineLeft,
        baselineRmsRight: baselineRight,
        calibratedAt: DateTime.now(),
        notice: 'Resting EMG baseline saved',
      ),
    );
  }

  void saveCalibration({
    required double baselineLeft,
    required double baselineRight,
  }) {
    emit(
      state.copyWith(
        baselineRmsLeft: baselineLeft,
        baselineRmsRight: baselineRight,
        calibratedAt: DateTime.now(),
      ),
    );
  }

  void selectTab(SessionTab tab) {
    emit(state.copyWith(selectedTab: tab));
  }

  Future<void> startRecording({required FeedbackView feedbackView}) async {
    if (_busy || state.isRecording || !state.isConnected) {
      return;
    }
    if (state.activeParticipantId == null) {
      throw StateError('Select a participant before recording.');
    }
    _busy = true;
    _recordingFeedbackView = feedbackView;
    _sessionStartedAt = DateTime.now();
    _lastFrameAt = _sessionStartedAt;
    _samplesThisSecond = 0;
    _samplesPerSecond = 0;
    _activationSum = 0;
    _activationSumRight = 0;
    _activationCount = 0;
    _peakRaw = SignalProcessor.adcMidpoint;
    _sessionPeakLeft = 0.0;
    _sessionPeakRight = 0.0;
    _sessionPeakRmsLeft = 0.0;
    _sessionPeakRmsRight = 0.0;
    _leftFilter.reset();
    _rightFilter.reset();
    _siBuffer.clear();
    _windowActivationSum = 0;
    _windowActivationSumRight = 0;
    _windowRmsSumLeft = 0;
    _windowRmsSumRight = 0;
    _windowActivationCount = 0;
    _sessionSymmetrySum = 0.0;
    _sessionSymmetryCount = 0;
    _autoSaveCounter = 0;
    _imbalanceStartedAt = null;
    _lastGuidanceNotificationAt = null;
    _rawPoints.fillRange(0, _rawPoints.length, SignalProcessor.adcMidpoint);
    _rawPoints3.fillRange(0, _rawPoints3.length, SignalProcessor.adcMidpoint);
    _busy = false;
    emit(
      state.copyWith(
        isRecording: true,
        sessionSeconds: 0,
        symmetryIndex: null,
        lastFrameMs: _lastFrameAt!.millisecondsSinceEpoch,
        notice: 'Recording started',
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> stopRecording() async {
    if (_busy || !state.isRecording) {
      return;
    }
    _busy = true;
    final hadSamples = _activationCount > 0;
    Object? persistenceError;
    try {
      await _persistSessionIfNeeded();
    } catch (error) {
      persistenceError = error;
    }
    _sessionStartedAt = null;
    _recordingFeedbackView = null;
    _lastFrameAt = null;
    _samplesThisSecond = 0;
    _samplesPerSecond = 0;
    _activationSum = 0;
    _activationSumRight = 0;
    _activationCount = 0;
    _peakRaw = SignalProcessor.adcMidpoint;
    _sessionPeakLeft = 0.0;
    _sessionPeakRight = 0.0;
    _siBuffer.clear();
    _windowActivationSum = 0;
    _windowActivationSumRight = 0;
    _windowRmsSumLeft = 0;
    _windowRmsSumRight = 0;
    _windowActivationCount = 0;
    _sessionSymmetrySum = 0.0;
    _sessionSymmetryCount = 0;
    _autoSaveCounter = 0;
    _imbalanceStartedAt = null;
    _rawPoints.fillRange(0, _rawPoints.length, SignalProcessor.adcMidpoint);
    _rawPoints3.fillRange(0, _rawPoints3.length, SignalProcessor.adcMidpoint);
    _busy = false;
    emit(
      state.copyWith(
        isRecording: false,
        sessionSeconds: 0,
        symmetryIndex: null,
        lastFrameMs: null,
        history: List<SessionSummary>.unmodifiable(_history),
        notice: persistenceError != null
            ? 'Recording stopped'
            : hadSamples
            ? 'Recording saved'
            : 'Recording stopped — no samples were captured',
        errorMessage: persistenceError == null
            ? state.errorMessage
            : 'Recording could not be saved: ${_displayError(persistenceError)}',
        clearErrorMessage: persistenceError == null,
      ),
    );
  }

  void _onFrame(EmgFrame frame) {
    _latestRaw = frame.ch1;
    _peakRaw = frame.ch1 > _peakRaw ? frame.ch1 : _peakRaw;
    _lastFrameAt = DateTime.now();
    _samplesThisSecond++;

    final channelAIsLeft = state.channelMapping['A'] == 'left';
    final leftRaw = channelAIsLeft ? frame.ch1 : frame.ch3;
    final rightRaw = channelAIsLeft ? frame.ch3 : frame.ch1;

    // The native bridge emits raw 16-bit ADC counts. The UI uses a
    // 20–400 Hz band-pass approximation followed by a 100 ms RMS envelope.
    final rightFiltered = _rightFilter.filter(rightRaw.toDouble());
    final leftFiltered = _leftFilter.filter(leftRaw.toDouble());
    final rightRms = _rightFilter.processRms(rightFiltered);
    final leftRms = _leftFilter.processRms(leftFiltered);
    final rightLevel = _signalProcessor.baselineCorrectedRms(
      rightRms,
      state.baselineRmsRight,
    );
    final leftLevel = _signalProcessor.baselineCorrectedRms(
      leftRms,
      state.baselineRmsLeft,
    );

    _liveActivation = rightLevel;
    _activationSum += leftLevel;
    _activationSumRight += rightLevel;
    _activationCount++;
    _windowActivationSum += leftLevel;
    _windowActivationSumRight += rightLevel;
    _windowRmsSumLeft += leftRms;
    _windowRmsSumRight += rightRms;
    _windowActivationCount++;

    if (leftLevel > _sessionPeakRmsLeft) {
      _sessionPeakRmsLeft = leftLevel;
    }
    if (rightLevel > _sessionPeakRmsRight) {
      _sessionPeakRmsRight = rightLevel;
    }

    // Keep legacy activationFromRaw tracking for session summaries
    final double rightActivation = _signalProcessor.activationFromRaw(rightRaw);
    final double leftActivation = _signalProcessor.activationFromRaw(leftRaw);
    if (leftActivation > _sessionPeakLeft) {
      _sessionPeakLeft = leftActivation;
    }
    if (rightActivation > _sessionPeakRight) {
      _sessionPeakRight = rightActivation;
    }

    _rawPoints.add(frame.ch1);
    if (_rawPoints.length > 3000) {
      _rawPoints.removeRange(0, _rawPoints.length - 3000);
    }
    _rawPoints3.add(frame.ch3);
    if (_rawPoints3.length > 3000) {
      _rawPoints3.removeRange(0, _rawPoints3.length - 3000);
    }
    _activationPoints.add(rightRms);
    if (_activationPoints.length > 3000) {
      _activationPoints.removeRange(0, _activationPoints.length - 3000);
    }
  }

  void _onFrameError(Object error, StackTrace stackTrace) {
    addError(error, stackTrace);
    unawaited(_handleFrameError(error));
  }

  Future<void> _handleFrameError(Object error) async {
    if (_busy || isClosed) return;
    _busy = true;
    await _bestEffort(_persistSessionIfNeeded, const Duration(seconds: 2));
    await _bestEffort(
      () => _frameSubscription?.cancel() ?? Future<void>.value(),
      const Duration(seconds: 1),
    );
    _frameSubscription = null;
    await _bestEffort(_hardware.stopAcquisition, const Duration(seconds: 2));
    await _bestEffort(_hardware.disconnect, const Duration(seconds: 3));
    _resetSession();
    _busy = false;
    if (isClosed) return;
    emit(
      state.copyWith(
        status: SessionStatus.error,
        busy: false,
        isRecording: false,
        history: List<SessionSummary>.unmodifiable(_history),
        clearConnectedAtMs: true,
        clearLastFrameMs: true,
        errorMessage: 'Sensor stream stopped: ${_displayError(error)}',
        clearNotice: true,
      ),
    );
  }

  Future<void> _loadHistory() async {
    final result = await _historyStore.loadWithReport();
    _history
      ..clear()
      ..addAll(result.sessions.take(_maxSavedSessions));
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        history: List<SessionSummary>.unmodifiable(_history),
        errorMessage: result.rejectedEntryCount == 0
            ? state.errorMessage
            : '${result.rejectedEntryCount} unreadable saved session '
                  '${result.rejectedEntryCount == 1 ? 'was' : 'records were'} ignored.',
      ),
    );
  }

  Future<void> clearSessionHistory() async {
    if (state.isRecording || _sessionStartedAt != null) {
      throw StateError(
        'Stop the active recording before clearing session data.',
      );
    }

    await _historyStore.clear();
    _history.clear();

    if (!isClosed) {
      emit(
        state.copyWith(
          history: const <SessionSummary>[],
          notice: 'All recorded session data was deleted.',
          clearErrorMessage: true,
        ),
      );
    }
  }

  Future<void> resetResearchData() async {
    if (state.isRecording || _sessionStartedAt != null) {
      throw StateError('Stop the active recording before resetting data.');
    }
    await Future.wait(<Future<void>>[
      _historyStore.clear(),
      _researchContextStore.clear(),
    ]);
    _history.clear();
    _imbalanceStartedAt = null;
    emit(
      state.copyWith(
        history: const <SessionSummary>[],
        participants: const <ParticipantProfile>[],
        clearActiveParticipantId: true,
        selectedScenario: UsageScenario.officeDesk,
        notificationPreferences: const NotificationPreferences(),
        notice: 'All participant and session data was deleted.',
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _persistSessionIfNeeded() async {
    if (_sessionStartedAt == null || _activationCount == 0) {
      return;
    }
    final now = DateTime.now();
    final duration = now.difference(_sessionStartedAt!).inSeconds;

    final double leftAvg = _sessionPeakRmsLeft > 0
        ? ((_activationSum / _activationCount) / _sessionPeakRmsLeft).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    final double rightAvg = _sessionPeakRmsRight > 0
        ? ((_activationSumRight / _activationCount) / _sessionPeakRmsRight)
              .clamp(0.0, 1.0)
        : 0.0;
    final double? finalSymmetryIndex =
        _sessionAverageSymmetryIndex ??
        _smoothedSI ??
        _calculateSymmetryIndex();

    final summary = SessionSummary(
      startedAt: _sessionStartedAt!,
      endedAt: now,
      durationSeconds: duration,
      peakRaw: _peakRaw,
      averageActivation: leftAvg,
      averageSymmetryIndex: finalSymmetryIndex,
      averageLeftActivation: leftAvg,
      averageRightActivation: rightAvg,
      note: _sessionNote(_sessionStartedAt!),
      channelMapping: Map<String, String>.from(state.channelMapping),
      participantId: state.activeParticipantId,
      scenarioId: state.selectedScenario.id,
      feedbackView: _recordingFeedbackView,
      targetMuscle: state.targetMuscle,
      simulatedInput: state.isSimulatedHardware,
    );
    _history.removeWhere(
      (item) =>
          item.startedAt == _sessionStartedAt &&
          item.participantId == state.activeParticipantId,
    );
    _history.insert(0, summary);
    _trimHistory();
    await _historyStore.save(_history);
  }

  Future<void> _autoSaveSession() async {
    if (_sessionStartedAt == null || _activationCount == 0) {
      return;
    }
    final now = DateTime.now();
    final duration = now.difference(_sessionStartedAt!).inSeconds;
    final double leftAvg = _sessionPeakRmsLeft > 0
        ? ((_activationSum / _activationCount) / _sessionPeakRmsLeft).clamp(
            0.0,
            1.0,
          )
        : 0.0;
    final double rightAvg = _sessionPeakRmsRight > 0
        ? ((_activationSumRight / _activationCount) / _sessionPeakRmsRight)
              .clamp(0.0, 1.0)
        : 0.0;
    final double? finalSymmetryIndex =
        _sessionAverageSymmetryIndex ??
        _smoothedSI ??
        _calculateSymmetryIndex();
    final summary = SessionSummary(
      startedAt: _sessionStartedAt!,
      endedAt: now,
      durationSeconds: duration,
      peakRaw: _peakRaw,
      averageActivation: leftAvg,
      averageSymmetryIndex: finalSymmetryIndex,
      averageLeftActivation: leftAvg,
      averageRightActivation: rightAvg,
      note: 'Auto-save — ${_sessionNote(_sessionStartedAt!)}',
      channelMapping: Map<String, String>.from(state.channelMapping),
      participantId: state.activeParticipantId,
      scenarioId: state.selectedScenario.id,
      feedbackView: _recordingFeedbackView,
      targetMuscle: state.targetMuscle,
      simulatedInput: state.isSimulatedHardware,
    );
    final existingIndex = _history.indexWhere(
      (item) =>
          item.startedAt == _sessionStartedAt &&
          item.participantId == state.activeParticipantId,
    );
    if (existingIndex == -1) {
      _history.insert(0, summary);
    } else {
      _history[existingIndex] = summary;
    }
    _trimHistory();
    await _historyStore.save(_history);
    if (!isClosed) {
      emit(
        state.copyWith(history: List<SessionSummary>.unmodifiable(_history)),
      );
    }
  }

  Future<void> _runAutoSave() async {
    try {
      await _autoSaveSession();
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(errorMessage: 'Automatic save failed: $error'));
      }
    } finally {
      _autoSaveInFlight = false;
    }
  }

  void _trimHistory() {
    if (_history.length > _maxSavedSessions) {
      _history.removeRange(_maxSavedSessions, _history.length);
    }
  }

  void _resetSession() {
    _sessionStartedAt = null;
    _recordingFeedbackView = null;
    _connectedAt = null;
    _lastFrameAt = null;
    _samplesThisSecond = 0;
    _samplesPerSecond = 0;
    _latestRaw = SignalProcessor.adcMidpoint;
    _calibrationMidpoint = SignalProcessor.adcMidpoint;
    _liveActivation = 0;
    _activationSum = 0;
    _activationSumRight = 0;
    _activationCount = 0;
    _peakRaw = SignalProcessor.adcMidpoint;
    _sessionPeakLeft = 0.0;
    _sessionPeakRight = 0.0;
    _sessionPeakRmsLeft = 0.0;
    _sessionPeakRmsRight = 0.0;
    _leftFilter.reset();
    _rightFilter.reset();
    _siBuffer.clear();
    _windowActivationSum = 0;
    _windowActivationSumRight = 0;
    _windowRmsSumLeft = 0;
    _windowRmsSumRight = 0;
    _windowActivationCount = 0;
    _sessionSymmetrySum = 0.0;
    _sessionSymmetryCount = 0;
    _imbalanceStartedAt = null;
    _rawPoints.fillRange(0, _rawPoints.length, SignalProcessor.adcMidpoint);
    _rawPoints3.fillRange(0, _rawPoints3.length, SignalProcessor.adcMidpoint);
  }

  String _sessionNote(DateTime startedAt) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = startedAt.day.toString().padLeft(2, '0');
    final month = months[startedAt.month - 1];
    final area = state.targetMuscle == TargetMuscle.biceps
        ? 'Biceps'
        : 'Upper back';
    return '$area symmetry - $day $month ${startedAt.year}';
  }

  void _addSymmetryIndex(double newSI) {
    _siBuffer.addLast(newSI);
    if (_siBuffer.length > _siBufferSize) {
      _siBuffer.removeFirst();
    }
    if (state.isRecording) {
      _sessionSymmetrySum += newSI;
      _sessionSymmetryCount++;
    }
  }

  double? get _sessionAverageSymmetryIndex {
    if (_sessionSymmetryCount == 0) {
      return null;
    }
    return _sessionSymmetrySum / _sessionSymmetryCount;
  }

  double? get _smoothedSI {
    if (_siBuffer.isEmpty) {
      return null;
    }
    return _siBuffer.reduce((a, b) => a + b) / _siBuffer.length;
  }

  double? _calculateSymmetryIndex() {
    if (state.status != SessionStatus.connected) {
      return null;
    }
    final sampleCount = _rawPoints.length;
    if (sampleCount == 0) {
      return null;
    }
    if (_windowActivationCount > 0) {
      final leftAvg = _windowActivationSum / _windowActivationCount;
      final rightAvg = _windowActivationSumRight / _windowActivationCount;
      final peakLeft = _sessionPeakRmsLeft > 0.001 ? _sessionPeakRmsLeft : null;
      final peakRight = _sessionPeakRmsRight > 0.001
          ? _sessionPeakRmsRight
          : null;
      final leftActivation = _normalisedLevel(leftAvg, peakLeft);
      final rightActivation = _normalisedLevel(rightAvg, peakRight);
      if (!_hasMeaningfulBalanceSignal(
        leftLevel: leftAvg,
        rightLevel: rightAvg,
        peakLeft: peakLeft,
        peakRight: peakRight,
      )) {
        return 0.0;
      }
      return _signalProcessor.activationDifferenceIndex(
        leftActivation,
        rightActivation,
      );
    }
    return null;
  }

  bool _hasMeaningfulBalanceSignal({
    required double leftLevel,
    required double rightLevel,
    required double? peakLeft,
    required double? peakRight,
  }) {
    if ((leftLevel + rightLevel) < _minimumCombinedRmsForBalance) {
      return false;
    }
    final leftActivation = _normalisedLevel(leftLevel, peakLeft);
    final rightActivation = _normalisedLevel(rightLevel, peakRight);
    return (leftActivation + rightActivation) >=
            _minimumCombinedActivationForBalance &&
        (leftActivation > _minimumSingleSideActivationForBalance ||
            rightActivation > _minimumSingleSideActivationForBalance);
  }

  double _normalisedLevel(double level, double? peak) {
    if (peak == null || peak <= 0.001) {
      return level.clamp(0.0, 1.0).toDouble();
    }
    return (level / peak).clamp(0.0, 1.0).toDouble();
  }

  void _emitSnapshot() {
    final startedAt = _sessionStartedAt;
    final sessionSeconds = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inSeconds;

    final bool hasWindowData = _windowActivationCount > 0;

    final double leftAct = hasWindowData
        ? _windowActivationSum / _windowActivationCount
        : 0.0;
    final double rightAct = hasWindowData
        ? _windowActivationSumRight / _windowActivationCount
        : 0.0;
    final double leftRms = hasWindowData
        ? _windowRmsSumLeft / _windowActivationCount
        : state.leftTrapRms;
    final double rightRms = hasWindowData
        ? _windowRmsSumRight / _windowActivationCount
        : state.rightTrapRms;

    final peakLeft = _sessionPeakRmsLeft > 0.001 ? _sessionPeakRmsLeft : null;
    final peakRight = _sessionPeakRmsRight > 0.001
        ? _sessionPeakRmsRight
        : null;

    if (hasWindowData) {
      final leftActivation = _normalisedLevel(leftAct, peakLeft);
      final rightActivation = _normalisedLevel(rightAct, peakRight);
      final hasMeaningfulSignal = _hasMeaningfulBalanceSignal(
        leftLevel: leftAct,
        rightLevel: rightAct,
        peakLeft: peakLeft,
        peakRight: peakRight,
      );
      final newSI = hasMeaningfulSignal
          ? _signalProcessor.activationDifferenceIndex(
              leftActivation,
              rightActivation,
            )
          : 0.0;

      _windowActivationSum = 0;
      _windowActivationSumRight = 0;
      _windowRmsSumLeft = 0;
      _windowRmsSumRight = 0;
      _windowActivationCount = 0;

      if (!hasMeaningfulSignal) {
        _siBuffer.clear();
      }
      _addSymmetryIndex(newSI);
    }

    final smoothedSI = _smoothedSI;
    _evaluateLocalGuidance(smoothedSI);

    final isLost =
        _lastFrameAt != null &&
        DateTime.now().difference(_lastFrameAt!).inMilliseconds > 2000;
    final newStatus = state.status == SessionStatus.signalLost && !isLost
        ? SessionStatus.connected
        : state.status == SessionStatus.connected && isLost
        ? SessionStatus.signalLost
        : state.status;

    emit(
      state.copyWith(
        status: newStatus,
        busy: _busy,
        latestRaw: _latestRaw,
        samplesPerSecond: _samplesPerSecond,
        sessionSeconds: sessionSeconds,
        calibrationMidpoint: _calibrationMidpoint,
        liveActivation: _liveActivation,
        symmetryIndex: smoothedSI,
        clearSymmetryIndex: smoothedSI == null,
        rawPoints: List<int>.unmodifiable(_rawPoints),
        rawPoints3: List<int>.unmodifiable(_rawPoints3),
        history: List<SessionSummary>.unmodifiable(_history),
        connectedAtMs: _connectedAt?.millisecondsSinceEpoch,
        lastFrameMs: _lastFrameAt?.millisecondsSinceEpoch,
        leftTrapRms: leftRms,
        rightTrapRms: rightRms,
        normalisedLeftActivation: peakLeft != null
            ? (leftAct / peakLeft).clamp(0.0, 1.0)
            : leftAct.clamp(0.0, 1.0),
        normalisedRightActivation: peakRight != null
            ? (rightAct / peakRight).clamp(0.0, 1.0)
            : rightAct.clamp(0.0, 1.0),
      ),
    );
  }

  void _evaluateLocalGuidance(double? symmetryIndex) {
    final preferences = state.notificationPreferences;
    if (!state.isRecording ||
        !preferences.enabled ||
        symmetryIndex == null ||
        symmetryIndex.abs() < preferences.imbalanceThreshold) {
      _imbalanceStartedAt = null;
      return;
    }

    final now = DateTime.now();
    _imbalanceStartedAt ??= now;
    final scenarioMinimum =
        state.selectedScenario.defaultNotificationDelaySeconds;
    final requiredSeconds = preferences.sustainedSeconds > scenarioMinimum
        ? preferences.sustainedSeconds
        : scenarioMinimum;
    if (now.difference(_imbalanceStartedAt!).inSeconds < requiredSeconds) {
      return;
    }

    final lastNotification = _lastGuidanceNotificationAt;
    if (_notificationInFlight ||
        (lastNotification != null &&
            now.difference(lastNotification).inMinutes <
                preferences.cooldownMinutes)) {
      return;
    }

    final participantId = state.activeParticipantId;
    if (participantId == null) return;
    _notificationInFlight = true;
    _lastGuidanceNotificationAt = now;
    _imbalanceStartedAt = null;
    unawaited(
      _showGuidanceNotification(
        participantId: participantId,
        symmetryIndex: symmetryIndex,
      ),
    );
  }

  Future<void> _showGuidanceNotification({
    required String participantId,
    required double symmetryIndex,
  }) async {
    try {
      await _notificationService.showCorrectiveGuidance(
        participantId: participantId,
        scenario: state.selectedScenario.shortLabel,
        symmetryIndex: symmetryIndex,
        instruction: _signalProcessor.correctiveInstruction(symmetryIndex),
      );
    } catch (_) {
      // Guidance is optional; a platform notification failure must not stop EMG.
    } finally {
      _notificationInFlight = false;
    }
  }

  String _displayError(Object error) {
    if (error is PlatformException) {
      return error.message ?? error.code;
    }
    if (error is StateError) {
      return error.message.toString();
    }
    return error.toString();
  }

  @override
  Future<void> close() async {
    await _frameSubscription?.cancel();
    _rebuildTimer?.cancel();
    _spsTimer?.cancel();
    _signalLossTimer?.cancel();
    await _bestEffort(_hardware.stopAcquisition, const Duration(seconds: 2));
    await _bestEffort(_hardware.disconnect, const Duration(seconds: 3));
    return super.close();
  }
}
