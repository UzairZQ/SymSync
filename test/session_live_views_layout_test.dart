import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sym_sync/data/emg/emg_hardware.dart';
import 'package:sym_sync/data/history/session_history_store.dart';
import 'package:sym_sync/data/notifications/local_notification_service.dart';
import 'package:sym_sync/data/research/research_context_store.dart';
import 'package:sym_sync/domain/models/emg_frame.dart';
import 'package:sym_sync/domain/models/research_context.dart';
import 'package:sym_sync/domain/models/session_summary.dart';
import 'package:sym_sync/presentation/bloc/session_bloc.dart';
import 'package:sym_sync/presentation/pages/anatomical_view_page.dart';
import 'package:sym_sync/presentation/pages/balance_monitor_page.dart';
import 'package:sym_sync/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final participant = ParticipantProfile(
      id: 'P001',
      createdAt: DateTime(2026, 6, 21),
    );
    final summary = SessionSummary(
      startedAt: DateTime(2026, 6, 21, 10),
      endedAt: DateTime(2026, 6, 21, 10, 1),
      durationSeconds: 60,
      peakRaw: 35000,
      averageActivation: 0.58,
      averageSymmetryIndex: 24,
      averageLeftActivation: 0.42,
      averageRightActivation: 0.58,
      note: 'Layout regression session',
      participantId: participant.id,
      scenarioId: UsageScenario.everydayStairs.id,
    );

    SharedPreferences.setMockInitialValues(<String, Object>{
      'sym_sync.participants.v1': <String>[jsonEncode(participant.toJson())],
      'sym_sync.active_participant.v1': participant.id,
      'sym_sync.active_scenario.v1': UsageScenario.everydayStairs.id,
      'sym_sync.session_history.v1': <String>[jsonEncode(summary.toJson())],
    });
  });

  testWidgets('anatomical view fits without scrolling in session viewport', (
    tester,
  ) async {
    final bloc = await _startedBloc();
    try {
      await _pumpSessionViewport(
        tester,
        bloc: bloc,
        child: const AnatomicalViewContent(),
      );

      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.maxScrollExtent, 0);
      expect(find.text('See which shoulder is working more.'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await bloc.close();
    }
  });

  testWidgets('balance view fits without scrolling in session viewport', (
    tester,
  ) async {
    final bloc = await _startedBloc();
    try {
      await _pumpSessionViewport(
        tester,
        bloc: bloc,
        child: const BalanceMonitorContent(),
      );

      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.maxScrollExtent, 0);
      expect(find.text('Balance Monitor'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await bloc.close();
    }
  });

  testWidgets('balance view centers stale imbalance while activation is tiny', (
    tester,
  ) async {
    final bloc = await _startedBloc();
    try {
      bloc.setTestState(
        bloc.state.copyWith(
          status: SessionStatus.connected,
          isRecording: true,
          symmetryIndex: 100,
          normalisedLeftActivation: 0.01,
          normalisedRightActivation: 0.01,
        ),
      );

      await _pumpSessionViewport(
        tester,
        bloc: bloc,
        child: const BalanceMonitorContent(),
      );

      expect(find.text('Both sides are symmetrical'), findsOneWidget);
      expect(find.text('Left Trap'), findsOneWidget);
      expect(find.text('Right Trap'), findsOneWidget);
      expect(find.text('Right side is working more'), findsNothing);
      expect(find.text('+100% relative imbalance'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await bloc.close();
    }
  });
}

Future<_TestSessionBloc> _startedBloc() async {
  final bloc = _TestSessionBloc(
    hardware: _LayoutHardware(),
    historyStore: SessionHistoryStore(),
    researchContextStore: ResearchContextStore(),
    notificationService: _LayoutNotificationService(),
  );
  await bloc.start();
  return bloc;
}

class _TestSessionBloc extends SessionBloc {
  _TestSessionBloc({
    required super.hardware,
    required super.historyStore,
    required super.researchContextStore,
    required super.notificationService,
  });

  void setTestState(SessionState state) => emit(state);
}

Future<void> _pumpSessionViewport(
  WidgetTester tester, {
  required SessionBloc bloc,
  required Widget child,
}) async {
  tester.view.physicalSize = const Size(412, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    BlocProvider<SessionBloc>.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SizedBox.expand(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _LayoutHardware implements EmgHardware {
  final StreamController<EmgFrame> _frames =
      StreamController<EmgFrame>.broadcast();

  @override
  Stream<EmgFrame> get frames => _frames.stream;

  @override
  Future<void> connect(String macAddress) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> startAcquisition({
    List<int> channels = const <int>[1, 3],
    int sampleRate = 1000,
  }) async {}

  @override
  Future<void> stopAcquisition() async {}
}

class _LayoutNotificationService extends LocalNotificationService {
  @override
  Future<void> initialize() async {}
}
