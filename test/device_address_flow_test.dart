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
import 'package:sym_sync/presentation/pages/home_shell_page.dart';
import 'package:sym_sync/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('connection asks for and remembers a user-entered PLUX address', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final hardware = _AddressHardware();
    final bloc = SessionBloc(
      hardware: hardware,
      historyStore: SessionHistoryStore(),
      researchContextStore: ResearchContextStore(),
      notificationService: _AddressNotificationService(),
    );
    await bloc.start();
    await bloc.createParticipant();

    await tester.pumpWidget(
      BlocProvider<SessionBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeShellPage(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Connect Device').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Connect biosignalsplux'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );

    const address = '12:34:56:78:9A:BC';
    await tester.enterText(find.byType(TextField), address.toLowerCase());
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    expect(hardware.connectedAddress, address);
    expect(prefs.getString('plux_device_address'), address);

    await tester.runAsync(bloc.disconnect);
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await bloc.close();
  });
}

class _AddressHardware implements EmgHardware {
  String? connectedAddress;

  @override
  bool get isSimulated => false;

  @override
  Stream<EmgFrame> get frames => const Stream<EmgFrame>.empty();

  @override
  Future<void> connect(String macAddress) async {
    connectedAddress = macAddress;
  }

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

class _AddressNotificationService extends LocalNotificationService {
  @override
  Future<void> initialize() async {}
}
