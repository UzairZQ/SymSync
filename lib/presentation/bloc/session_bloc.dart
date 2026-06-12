import 'dart:async';
import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/emg/emg_hardware.dart';
import '../../data/history/session_history_store.dart';
import '../../domain/models/emg_frame.dart';
import '../../domain/models/session_summary.dart';
import '../../domain/models/session_tab.dart';
import '../../domain/services/signal_processor.dart';

enum SessionStatus { disconnected, connecting, connected, signalLost, error }

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
    this.calibratedAt,
  });

  factory SessionState.initial() {
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
  final DateTime? calibratedAt;

  bool get isConnected =>
      status == SessionStatus.connected || status == SessionStatus.signalLost;

  bool get bilateralReady => symmetryIndex != null;

  String get greeting => greetingForHour(DateTime.now().hour);

  String get displayName => 'Participant';

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
    int? lastFrameMs,
    Map<String, String>? channelMapping,
    double? leftTrapRms,
    double? rightTrapRms,
    double? normalisedLeftActivation,
    double? normalisedRightActivation,
    double? baselineRmsLeft,
    double? baselineRmsRight,
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
      connectedAtMs: connectedAtMs ?? this.connectedAtMs,
      lastFrameMs: lastFrameMs ?? this.lastFrameMs,
      channelMapping: channelMapping ?? this.channelMapping,
      leftTrapRms: leftTrapRms ?? this.leftTrapRms,
      rightTrapRms: rightTrapRms ?? this.rightTrapRms,
      normalisedLeftActivation:
          normalisedLeftActivation ?? this.normalisedLeftActivation,
      normalisedRightActivation:
          normalisedRightActivation ?? this.normalisedRightActivation,
      baselineRmsLeft: baselineRmsLeft ?? this.baselineRmsLeft,
      baselineRmsRight: baselineRmsRight ?? this.baselineRmsRight,
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
    calibratedAt,
  ];
}

class SessionBloc extends Cubit<SessionState> {
  SessionBloc({
    required EmgHardware hardware,
    required SessionHistoryStore historyStore,
  }) : _hardware = hardware,
       _historyStore = historyStore,
       _signalProcessor = const SignalProcessor(),
       super(SessionState.initial()) {
    _loadHistory();
    _loadChannelMapping();
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
      }
    });
    _signalLossTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (isClosed || _sessionStartedAt == null) {
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
  final SignalProcessor _signalProcessor;

  StreamSubscription<EmgFrame>? _frameSubscription;
  Timer? _rebuildTimer;
  Timer? _spsTimer;
  Timer? _signalLossTimer;

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

  double _sessionPeakLeft = 0.0;
  double _sessionPeakRight = 0.0;
  final Queue<double> _siBuffer = Queue<double>();
  static const int _siBufferSize = 20;

  Future<void> start() async {
    await _loadHistory();
    await _loadChannelMapping();
  }

  Future<void> _loadChannelMapping() async {
    final prefs = await SharedPreferences.getInstance();
    final storedA = prefs.getString('channel_mapping.A');
    final storedB = prefs.getString('channel_mapping.B');

    if ((storedA != null && storedB != null) && !isClosed) {
      final mapping = {'A': storedA, 'B': storedB};
      if (mapping != state.channelMapping) {
        emit(state.copyWith(channelMapping: mapping));
      }
    }
  }

  Future<void> setChannelMapping(String channelA, String channelB) async {
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
      _siBuffer.clear();
      await _frameSubscription?.cancel();
      _frameSubscription = _hardware.frames.listen(
        _onFrame,
        onError: _onFrameError,
      );

      emit(
        state.copyWith(
          status: SessionStatus.connected,
          busy: false,
          connectedAtMs: _sessionStartedAt!.millisecondsSinceEpoch,
          lastFrameMs: _lastFrameAt!.millisecondsSinceEpoch,
          notice: 'Connected',
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SessionStatus.error,
          busy: false,
          errorMessage: error.toString(),
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
        busy: true,
        notice: 'Disconnecting...',
        clearErrorMessage: true,
      ),
    );

    try {
      await _frameSubscription?.cancel();
      _frameSubscription = null;
      await _hardware.stopAcquisition();
      await _hardware.disconnect();
      await _persistSessionIfNeeded();
      final selectedTab = state.selectedTab;
      _resetSession();
      emit(
        SessionState.initial().copyWith(
          selectedTab: selectedTab,
          history: List<SessionSummary>.unmodifiable(_history),
          notice: 'Disconnected',
        ),
      );
    } catch (error) {
      emit(state.copyWith(busy: false, errorMessage: error.toString()));
    } finally {
      _busy = false;
    }
  }

  void calibrate() {
    _calibrationMidpoint = _latestRaw;
    emit(
      state.copyWith(
        calibrationMidpoint: _calibrationMidpoint,
        notice: 'Calibration saved at $_calibrationMidpoint',
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

  void _onFrame(EmgFrame frame) {
    _latestRaw = frame.ch1;
    _peakRaw = frame.ch1 > _peakRaw ? frame.ch1 : _peakRaw;
    _lastFrameAt = DateTime.now();
    _samplesThisSecond++;
    final double rightActivation = _signalProcessor.activationFromRaw(
      frame.ch1 - _calibrationMidpoint + SignalProcessor.adcMidpoint,
    );
    final double leftActivation = _signalProcessor.activationFromRaw(
      frame.ch3 - _calibrationMidpoint + SignalProcessor.adcMidpoint,
    );
    _liveActivation = rightActivation;
    _activationSum += leftActivation;
    _activationSumRight += rightActivation;
    _activationCount++;
    _rawPoints.add(frame.ch1);
    if (_rawPoints.length > 3000) {
      _rawPoints.removeRange(0, _rawPoints.length - 3000);
    }
    _rawPoints3.add(frame.ch3);
    if (_rawPoints3.length > 3000) {
      _rawPoints3.removeRange(0, _rawPoints3.length - 3000);
    }
    _activationPoints.add(_liveActivation);
    if (_activationPoints.length > 3000) {
      _activationPoints.removeRange(0, _activationPoints.length - 3000);
    }

    if (leftActivation > _sessionPeakLeft) {
      _sessionPeakLeft = leftActivation;
    }
    if (rightActivation > _sessionPeakRight) {
      _sessionPeakRight = rightActivation;
    }

    final symmetryIndex = _calculateSymmetryIndex();
    if (symmetryIndex != null) {
      _addSymmetryIndex(symmetryIndex);
    } else {
      _siBuffer.clear();
    }

    if (state.status == SessionStatus.signalLost) {
      emit(
        state.copyWith(
          status: SessionStatus.connected,
          notice: 'Signal recovered',
        ),
      );
    }
  }

  void _onFrameError(Object error, StackTrace stackTrace) {
    addError(error, stackTrace);
    emit(
      state.copyWith(
        status: SessionStatus.error,
        busy: false,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _loadHistory() async {
    final loaded = await _historyStore.load();
    _history
      ..clear()
      ..addAll(loaded);
    if (isClosed) {
      return;
    }
    emit(state.copyWith(history: List<SessionSummary>.unmodifiable(_history)));
  }

  Future<void> _persistSessionIfNeeded() async {
    if (_sessionStartedAt == null || _activationCount == 0) {
      return;
    }
    final now = DateTime.now();
    final duration = now.difference(_sessionStartedAt!).inSeconds;

    final double leftAvg = _activationSum / _activationCount;
    final double rightAvg = _activationSumRight / _activationCount;
    // Calculate right activation average by using final session corrected SI if possible
    final double? finalSymmetryIndex = _calculateSymmetryIndex();

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
    );
    _history.insert(0, summary);
    await _historyStore.save(_history.take(10).toList(growable: false));
  }

  void _resetSession() {
    _sessionStartedAt = null;
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
    _siBuffer.clear();
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
    return 'Upper back symmetry - $day $month ${startedAt.year}';
  }

  void _addSymmetryIndex(double newSI) {
    _siBuffer.addLast(newSI);
    if (_siBuffer.length > _siBufferSize) {
      _siBuffer.removeFirst();
    }
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
    final startIndex = sampleCount > 2000 ? sampleCount - 2000 : 0;

    int min1 = 999999;
    int max1 = -999999;
    for (int i = startIndex; i < sampleCount; i++) {
      final v = _rawPoints[i];
      if (v < min1) min1 = v;
      if (v > max1) max1 = v;
    }
    final ch1Active = (max1 - min1) > 50;

    int min3 = 999999;
    int max3 = -999999;
    for (int i = startIndex; i < sampleCount; i++) {
      if (i < _rawPoints3.length) {
        final v = _rawPoints3[i];
        if (v < min3) min3 = v;
        if (v > max3) max3 = v;
      }
    }
    final ch3Active = (max3 - min3) > 50;

    if (ch1Active && ch3Active) {
      final leftActivation = _signalProcessor.activationFromRaw(
        (_rawPoints3.isNotEmpty
                ? _rawPoints3.last
                : SignalProcessor.adcMidpoint) -
            _calibrationMidpoint +
            SignalProcessor.adcMidpoint,
      );
      final rightActivation = _liveActivation;
      return _signalProcessor.symmetryIndexFromLevels(
        leftActivation,
        rightActivation,
      );
    }
    return null;
  }

  void _emitSnapshot() {
    final startedAt = _sessionStartedAt;
    final sessionSeconds = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inSeconds;

    final double leftAct = _signalProcessor.activationFromRaw(
      (_rawPoints3.isNotEmpty
              ? _rawPoints3.last
              : SignalProcessor.adcMidpoint) -
          _calibrationMidpoint +
          SignalProcessor.adcMidpoint,
    );
    final double rightAct = _liveActivation;

    final peakLeft = _sessionPeakLeft > 0 ? _sessionPeakLeft : 1.0;
    final peakRight = _sessionPeakRight > 0 ? _sessionPeakRight : 1.0;

    final smoothedSI = _smoothedSI;

    emit(
      state.copyWith(
        status:
            state.status == SessionStatus.connected &&
                _lastFrameAt != null &&
                DateTime.now().difference(_lastFrameAt!).inMilliseconds > 2000
            ? SessionStatus.signalLost
            : state.status,
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
        connectedAtMs: startedAt?.millisecondsSinceEpoch,
        lastFrameMs: _lastFrameAt?.millisecondsSinceEpoch,
        leftTrapRms: leftAct,
        rightTrapRms: rightAct,
        normalisedLeftActivation: (leftAct / peakLeft).clamp(0.0, 1.0),
        normalisedRightActivation: (rightAct / peakRight).clamp(0.0, 1.0),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _frameSubscription?.cancel();
    _rebuildTimer?.cancel();
    _spsTimer?.cancel();
    _signalLossTimer?.cancel();
    unawaited(_hardware.stopAcquisition());
    unawaited(_hardware.disconnect());
    return super.close();
  }
}
