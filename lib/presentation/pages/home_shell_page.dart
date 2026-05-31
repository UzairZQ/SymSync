import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/models/session_tab.dart';
import '../bloc/session_bloc.dart';
import '../../theme/app_theme.dart';
import 'activation_summary_page.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'session_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  static const String _deviceMac = '00:07:80:8C:0A:27';

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;
    final statuses = await <Permission>[
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<void> _connect(BuildContext context) async {
    final granted = await _requestPermissions();
    if (!granted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth permissions are required.')),
      );
      return;
    }
    if (!context.mounted) return;
    unawaited(context.read<SessionBloc>().connect(_deviceMac));
  }

  Future<void> _disconnect(BuildContext context) async {
    unawaited(context.read<SessionBloc>().disconnect());
  }

  Future<void> _calibrate(BuildContext context) async {
    context.read<SessionBloc>().calibrate();
  }

  void _showError(BuildContext context, String message) {
    final lower = message.toLowerCase();
    final friendly =
        lower.contains('not found') ||
            lower.contains('unable to connect') ||
            lower.contains('could not connect')
        ? 'Not found — check Bluetooth is on and device is powered'
        : message;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(friendly)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(
        onOpenSession: () =>
            context.read<SessionBloc>().selectTab(SessionTab.session),
        onOpenSummary: () =>
            context.read<SessionBloc>().selectTab(SessionTab.summary),
        onConnect: () => _connect(context),
        onDisconnect: () => _disconnect(context),
        onCalibrate: () => _calibrate(context),
      ),
      const SessionPage(),
      const ActivationSummaryPage(),
      const ProfilePage(),
    ];

    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (prev, cur) =>
          prev.errorMessage != cur.errorMessage && cur.errorMessage != null,
      listener: (context, state) {
        if (state.errorMessage != null)
          _showError(context, state.errorMessage!);
      },
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            // Theme-aware background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.bgPrimary, context.bgElevated],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Column(
              children: <Widget>[
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: BlocBuilder<SessionBloc, SessionState>(
                        buildWhen: (prev, cur) =>
                            prev.selectedTab != cur.selectedTab,
                        builder: (context, state) {
                          return IndexedStack(
                            index: state.selectedTab.index,
                            children: pages.asMap().entries.map((entry) {
                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: state.selectedTab.index == entry.key
                                    ? 1
                                    : 0,
                                curve: Curves.easeInOut,
                                child: IgnorePointer(
                                  ignoring:
                                      state.selectedTab.index != entry.key,
                                  child: entry.value,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                _BottomNav(
                  onChanged: (tab) =>
                      context.read<SessionBloc>().selectTab(tab),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.onChanged});

  final ValueChanged<SessionTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final items = <_NavItemData>[
          _NavItemData(
            tab: SessionTab.dashboard,
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view,
            label: 'Dashboard',
          ),
          _NavItemData(
            tab: SessionTab.session,
            icon: Icons.monitor_heart_outlined,
            selectedIcon: Icons.monitor_heart,
            label: 'Session',
          ),
          _NavItemData(
            tab: SessionTab.summary,
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart,
            label: 'Summary',
          ),
          _NavItemData(
            tab: SessionTab.profile,
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
          ),
        ];

        return Container(
          height: 72 + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: context.bgCard,
            border: Border(top: BorderSide(color: context.dividerClr)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: items.map((item) {
              final selected = item.tab == state.selectedTab;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(item.tab),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  splashColor: AppTheme.accentTeal.withValues(alpha: 0.12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spaceSM,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          selected ? item.selectedIcon : item.icon,
                          color: selected
                              ? AppTheme.accentTeal
                              : context.txtTertiary,
                        ),
                        if (selected) ...[
                          const SizedBox(height: AppTheme.spaceXS),
                          Text(
                            item.label,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.accentTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Container(
                            width: 24,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.accentTeal,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.tab,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final SessionTab tab;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
