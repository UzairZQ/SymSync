import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sym_sync/data/emg/emg_hardware.dart';
import 'package:sym_sync/data/history/session_history_store.dart';
import 'package:sym_sync/data/notifications/local_notification_service.dart';
import 'package:sym_sync/data/research/research_context_store.dart';
import 'package:sym_sync/domain/models/emg_frame.dart';
import 'package:sym_sync/domain/models/feedback_view.dart';
import 'package:sym_sync/domain/models/research_context.dart';
import 'package:sym_sync/domain/models/target_muscle.dart';
import 'package:sym_sync/presentation/bloc/session_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('disconnect preserves the loaded research context', () async {
    final hardware = _FakeEmgHardware();
    final bloc = SessionBloc(
      hardware: hardware,
      historyStore: SessionHistoryStore(),
      researchContextStore: ResearchContextStore(),
      notificationService: _FakeNotificationService(),
    );
    addTearDown(bloc.close);
    addTearDown(hardware.dispose);

    await bloc.start();
    final participant = await bloc.createParticipant();
    await bloc.selectScenario(UsageScenario.everydayStairs);
    await bloc.setChannelMapping('left', 'right');
    await bloc.connect('00:00:00:00:00:00');

    expect(bloc.state.status, SessionStatus.connected);
    expect(bloc.state.researchContextLoaded, isTrue);

    await bloc.disconnect();

    expect(bloc.state.status, SessionStatus.disconnected);
    expect(bloc.state.busy, isFalse);
    expect(bloc.state.researchContextLoaded, isTrue);
    expect(bloc.state.participants, <ParticipantProfile>[participant]);
    expect(bloc.state.activeParticipantId, participant.id);
    expect(bloc.state.selectedScenario, UsageScenario.everydayStairs);
    expect(bloc.state.channelMapping, <String, String>{
      'A': 'left',
      'B': 'right',
    });
    expect(bloc.state.connectedAtMs, isNull);
    expect(bloc.state.lastFrameMs, isNull);
    expect(hardware.disconnectCalls, 1);
  });

  test(
    'failed acquisition rolls back the partial hardware connection',
    () async {
      final hardware = _FakeEmgHardware()..failAcquisition = true;
      final bloc = SessionBloc(
        hardware: hardware,
        historyStore: SessionHistoryStore(),
        researchContextStore: ResearchContextStore(),
        notificationService: _FakeNotificationService(),
      );
      addTearDown(bloc.close);
      addTearDown(hardware.dispose);

      await bloc.start();
      await bloc.connect('00:00:00:00:00:00');

      expect(bloc.state.status, SessionStatus.error);
      expect(bloc.state.busy, isFalse);
      expect(hardware.stopCalls, 1);
      expect(hardware.disconnectCalls, 1);
    },
  );

  test('stream failure closes and saves an active recording', () async {
    final hardware = _FakeEmgHardware();
    final bloc = SessionBloc(
      hardware: hardware,
      historyStore: SessionHistoryStore(),
      researchContextStore: ResearchContextStore(),
      notificationService: _FakeNotificationService(),
    );
    addTearDown(bloc.close);
    addTearDown(hardware.dispose);

    await bloc.start();
    await bloc.createParticipant();
    await bloc.connect('00:00:00:00:00:00');
    await bloc.startRecording(feedbackView: FeedbackView.balanceMonitor);
    hardware.emit(const EmgFrame(timestamp: 1, ch1: 34000, ch3: 33000));
    await Future<void>.delayed(Duration.zero);
    hardware.emitError(StateError('link lost'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.status, SessionStatus.error);
    expect(bloc.state.isRecording, isFalse);
    expect(bloc.state.history, hasLength(1));
    expect(hardware.disconnectCalls, 1);
  });

  test(
    'optional notification startup failure does not block app data',
    () async {
      final hardware = _FakeEmgHardware();
      final bloc = SessionBloc(
        hardware: hardware,
        historyStore: SessionHistoryStore(),
        researchContextStore: ResearchContextStore(),
        notificationService: _FailingNotificationService(),
      );
      addTearDown(bloc.close);
      addTearDown(hardware.dispose);

      await bloc.start();

      expect(bloc.state.researchContextLoaded, isTrue);
      expect(bloc.state.errorMessage, contains('notifications'));
    },
  );

  test('recording condition metadata stays locked and is persisted', () async {
    final hardware = _FakeEmgHardware();
    final bloc = SessionBloc(
      hardware: hardware,
      historyStore: SessionHistoryStore(),
      researchContextStore: ResearchContextStore(),
      notificationService: _FakeNotificationService(),
    );
    addTearDown(bloc.close);
    addTearDown(hardware.dispose);

    await bloc.start();
    await bloc.createParticipant();
    bloc.selectTargetMuscle(TargetMuscle.biceps);
    bloc.selectFeedbackView(FeedbackView.balanceMonitor);
    await bloc.connect('00:00:00:00:00:00');
    await bloc.startRecording(feedbackView: bloc.state.selectedFeedbackView!);
    expect(bloc.state.status, SessionStatus.connected);
    expect(bloc.state.isRecording, isTrue);
    expect(hardware.hasFrameListener, isTrue);
    hardware.emit(const EmgFrame(timestamp: 1, ch1: 34000, ch3: 33000));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(
      () => bloc.selectFeedbackView(FeedbackView.anatomicalHeatmap),
      throwsStateError,
    );
    expect(
      () => bloc.selectTargetMuscle(TargetMuscle.trapezius),
      throwsStateError,
    );
    await expectLater(
      bloc.setChannelMapping('right', 'left'),
      throwsStateError,
    );

    await bloc.stopRecording();

    expect(bloc.state.history.single.feedbackView, FeedbackView.balanceMonitor);
    expect(bloc.state.history.single.targetMuscle, TargetMuscle.biceps);
  });
}

class _FakeEmgHardware implements EmgHardware {
  final StreamController<EmgFrame> _frames =
      StreamController<EmgFrame>.broadcast(sync: true);

  int disconnectCalls = 0;
  int stopCalls = 0;
  bool failAcquisition = false;

  @override
  bool get isSimulated => false;

  @override
  Stream<EmgFrame> get frames => _frames.stream;

  @override
  Future<void> connect(String macAddress) async {}

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
  }

  @override
  Future<void> startAcquisition({
    List<int> channels = const <int>[1, 3],
    int sampleRate = 1000,
  }) async {
    if (failAcquisition) throw StateError('start failed');
  }

  @override
  Future<void> stopAcquisition() async {
    stopCalls++;
  }

  void emit(EmgFrame frame) => _frames.add(frame);

  void emitError(Object error) => _frames.addError(error);

  bool get hasFrameListener => _frames.hasListener;

  Future<void> dispose() => _frames.close();
}

class _FakeNotificationService extends LocalNotificationService {
  @override
  Future<void> initialize() async {}
}

class _FailingNotificationService extends LocalNotificationService {
  @override
  Future<void> initialize() => Future<void>.error(StateError('unavailable'));
}
