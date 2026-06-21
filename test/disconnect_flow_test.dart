import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sym_sync/data/emg/emg_hardware.dart';
import 'package:sym_sync/data/history/session_history_store.dart';
import 'package:sym_sync/data/notifications/local_notification_service.dart';
import 'package:sym_sync/data/research/research_context_store.dart';
import 'package:sym_sync/domain/models/emg_frame.dart';
import 'package:sym_sync/domain/models/research_context.dart';
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
}

class _FakeEmgHardware implements EmgHardware {
  final StreamController<EmgFrame> _frames =
      StreamController<EmgFrame>.broadcast();

  int disconnectCalls = 0;

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
  }) async {}

  @override
  Future<void> stopAcquisition() async {}

  Future<void> dispose() => _frames.close();
}

class _FakeNotificationService extends LocalNotificationService {
  @override
  Future<void> initialize() async {}
}
