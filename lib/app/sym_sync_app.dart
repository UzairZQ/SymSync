import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/emg/emg_hardware.dart';
import '../data/emg/plux_emg_hardware.dart';
import '../data/emg/simulated_emg_hardware.dart';
import '../data/history/session_history_store.dart';
import '../presentation/bloc/session_bloc.dart';
import '../presentation/pages/home_shell_page.dart';
import '../theme/app_theme.dart';
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
    await ThemeProvider.init();
    if (mounted) {
      setState(() {
        _onboardingComplete = false;
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.themeNotifier,
      builder: (context, themeMode, _) {
        return RepositoryProvider<SessionHistoryStore>(
          create: (_) => SessionHistoryStore(),
          child: RepositoryProvider<EmgHardware>(
            create: (_) => _buildHardware(),
            child: BlocProvider(
              create: (ctx) => SessionBloc(
                hardware: ctx.read<EmgHardware>(),
                historyStore: ctx.read<SessionHistoryStore>(),
              )..start(),
              child: MaterialApp(
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
              ),
            ),
          ),
        );
      },
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
