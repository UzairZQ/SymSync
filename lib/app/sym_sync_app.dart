import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/emg/emg_hardware.dart';
import '../data/emg/plux_emg_hardware.dart';
import '../data/emg/simulated_emg_hardware.dart';
import '../data/history/session_history_store.dart';
import '../data/notifications/local_notification_service.dart';
import '../data/research/research_context_store.dart';
import '../presentation/bloc/session_bloc.dart';
import '../presentation/pages/home_shell_page.dart';
import '../theme/app_theme.dart';
import '../theme/accessibility_provider.dart';
import '../theme/theme_provider.dart';
import '../plux_service.dart';
import '../presentation/pages/onboarding_page.dart';

class SymSyncApp extends StatefulWidget {
  const SymSyncApp({super.key});

  @override
  State<SymSyncApp> createState() => _SymSyncAppState();
}

class _SymSyncAppState extends State<SymSyncApp> {
  bool _onboardingComplete = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait(<Future<void>>[
      ThemeProvider.init(),
      AccessibilityProvider.init(),
    ]);
    if (mounted) {
      setState(() {
        _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
        _loading = false;
      });
    }
  }

  EmgHardware _buildHardware() {
    if (Platform.isAndroid) {
      return PluxEmgHardware(PluxService());
    }
    return SimulatedEmgHardware();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<dynamic>>[
        RepositoryProvider<SessionHistoryStore>(
          create: (_) => SessionHistoryStore(),
        ),
        RepositoryProvider<ResearchContextStore>(
          create: (_) => ResearchContextStore(),
        ),
        RepositoryProvider<LocalNotificationService>(
          create: (_) => LocalNotificationService(),
        ),
        RepositoryProvider<EmgHardware>(create: (_) => _buildHardware()),
      ],
      child: BlocProvider(
        create: (ctx) => SessionBloc(
          hardware: ctx.read<EmgHardware>(),
          historyStore: ctx.read<SessionHistoryStore>(),
          researchContextStore: ctx.read<ResearchContextStore>(),
          notificationService: ctx.read<LocalNotificationService>(),
        )..start(),
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeProvider.themeNotifier,
          builder: (context, themeMode, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: AccessibilityProvider.colorBlindNotifier,
              builder: (context, colorBlindMode, _) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'SymSync',
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  home: _loading
                      ? const _SplashScreen()
                      : _onboardingComplete
                      ? const HomeShellPage()
                      : OnboardingPage(
                          onComplete: () {
                            setState(() => _onboardingComplete = true);
                          },
                        ),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(highContrast: colorBlindMode),
                    child: child!,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
