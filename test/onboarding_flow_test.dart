import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sym_sync/data/emg/emg_hardware.dart';
import 'package:sym_sync/data/history/session_history_store.dart';
import 'package:sym_sync/data/notifications/local_notification_service.dart';
import 'package:sym_sync/data/research/research_context_store.dart';
import 'package:sym_sync/domain/models/emg_frame.dart';
import 'package:sym_sync/presentation/bloc/session_bloc.dart';
import 'package:sym_sync/presentation/pages/onboarding_page.dart';
import 'package:sym_sync/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('onboarding persists a valid cable mapping before completion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final hardware = _OnboardingHardware();
    final bloc = SessionBloc(
      hardware: hardware,
      historyStore: SessionHistoryStore(),
      researchContextStore: ResearchContextStore(),
      notificationService: _OnboardingNotificationService(),
    );
    var completed = false;

    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: OnboardingPage(onComplete: () => completed = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(completed, isTrue);
    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(prefs.getString('channel_mapping.A'), 'left');
    expect(prefs.getString('channel_mapping.B'), 'right');

    await tester.pumpWidget(const SizedBox.shrink());
    await bloc.close();
    await hardware.dispose();
  });
}

class _OnboardingHardware implements EmgHardware {
  final StreamController<EmgFrame> _frames =
      StreamController<EmgFrame>.broadcast();

  @override
  bool get isSimulated => false;

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

  Future<void> dispose() => _frames.close();
}

class _OnboardingNotificationService extends LocalNotificationService {
  @override
  Future<void> initialize() async {}
}
