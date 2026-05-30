import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/emg/emg_hardware.dart';
import '../data/emg/plux_emg_hardware.dart';
import '../data/emg/simulated_emg_hardware.dart';
import '../data/history/session_history_store.dart';
import '../presentation/bloc/session_bloc.dart';
import '../presentation/pages/home_shell_page.dart';
import 'sym_sync_theme.dart';
import '../plux_service.dart';

class SymSyncApp extends StatelessWidget {
  const SymSyncApp({super.key});

  EmgHardware _buildHardware() {
    if (Platform.isAndroid) {
      return PluxEmgHardware(PluxService());
    }
    return SimulatedEmgHardware();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<SessionHistoryStore>(
      create: (_) => SessionHistoryStore(),
      child: RepositoryProvider<EmgHardware>(
        create: (_) => _buildHardware(),
        child: BlocProvider(
          create: (context) => SessionBloc(
            hardware: context.read<EmgHardware>(),
            historyStore: context.read<SessionHistoryStore>(),
          )..start(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SymSync',
            theme: SymSyncTheme.light(),
            home: const HomeShellPage(),
          ),
        ),
      ),
    );
  }
}
