import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/session_tab.dart';
import '../../plux_service.dart';
import '../bloc/session_bloc.dart';
import '../../theme/app_theme.dart';
import 'activation_summary_page.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'participant_setup_page.dart';
import 'session_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  static const String _deviceAddressKey = 'plux_device_address';
  static final RegExp _macAddressPattern = RegExp(
    r'^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$',
  );

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;
    final sdk = await PluxService().androidSdkInt() ?? 31;
    final permissions = sdk >= 31
        ? <Permission>[Permission.bluetoothConnect, Permission.bluetoothScan]
        : <Permission>[Permission.locationWhenInUse];
    final statuses = await permissions.request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<void> _connect(BuildContext context) async {
    final bloc = context.read<SessionBloc>();
    if (bloc.state.isSimulatedHardware) {
      unawaited(bloc.connect('SIMULATED'));
      return;
    }
    final deviceAddress = await _promptForDeviceAddress(context);
    if (deviceAddress == null || !context.mounted) return;
    final granted = await _requestPermissions();
    if (!granted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth permissions are required.')),
      );
      return;
    }
    if (!context.mounted) return;
    unawaited(bloc.connect(deviceAddress));
  }

  Future<String?> _promptForDeviceAddress(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return null;
    final address = await showDialog<String>(
      context: context,
      builder: (_) => _DeviceAddressDialog(
        initialAddress: prefs.getString(_deviceAddressKey) ?? '',
        addressPattern: _macAddressPattern,
      ),
    );
    if (address != null) {
      await prefs.setString(_deviceAddressKey, address);
    }
    return address;
  }

  Future<void> _disconnect(BuildContext context) async {
    unawaited(context.read<SessionBloc>().disconnect());
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
      ),
      const SessionPage(),
      const ActivationSummaryPage(),
      const ProfilePage(),
    ];

    return BlocBuilder<SessionBloc, SessionState>(
      buildWhen: (previous, current) =>
          previous.researchContextLoaded != current.researchContextLoaded ||
          previous.participants != current.participants,
      builder: (context, researchState) {
        if (!researchState.researchContextLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (researchState.participants.isEmpty) {
          return const ParticipantSetupPage();
        }
        return BlocListener<SessionBloc, SessionState>(
          listenWhen: (prev, cur) =>
              prev.errorMessage != cur.errorMessage && cur.errorMessage != null,
          listener: (context, state) {
            if (state.errorMessage != null) {
              _showError(context, state.errorMessage!);
            }
          },
          child: Scaffold(
            body: Stack(
              children: <Widget>[
                Container(color: context.bgPrimary),
                Column(
                  children: <Widget>[
                    Expanded(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                          child: BlocBuilder<SessionBloc, SessionState>(
                            buildWhen: (prev, cur) =>
                                prev.selectedTab != cur.selectedTab,
                            builder: (context, state) {
                              final index = state.selectedTab.index.clamp(
                                0,
                                pages.length - 1,
                              );
                              return IndexedStack(
                                index: index,
                                children: pages.asMap().entries.map((entry) {
                                  return AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: index == entry.key ? 1 : 0,
                                    curve: Curves.easeInOut,
                                    child: IgnorePointer(
                                      ignoring: index != entry.key,
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
      },
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
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights,
            label: 'Summary',
          ),
          _NavItemData(
            tab: SessionTab.profile,
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
          ),
        ];

        final selectedTab = state.selectedTab;

        return Container(
          height: 72 + bottomPadding,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: EdgeInsets.fromLTRB(6, 6, 6, bottomPadding + 6),
          decoration: BoxDecoration(
            color: context.dividerClr,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: items.map((item) {
              final selected = item.tab == selectedTab;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(item.tab),
                  borderRadius: BorderRadius.circular(999),
                  splashColor: AppTheme.accentGreen.withValues(alpha: 0.12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: selected ? context.txtPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          selected ? item.selectedIcon : item.icon,
                          color: selected
                              ? context.bgPrimary
                              : context.txtTertiary,
                          size: 17,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: AppTheme.labelSmall.copyWith(
                            color: selected
                                ? context.bgPrimary
                                : context.txtSecondary,
                            fontSize: 9.5,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

class _DeviceAddressDialog extends StatefulWidget {
  const _DeviceAddressDialog({
    required this.initialAddress,
    required this.addressPattern,
  });

  final String initialAddress;
  final RegExp addressPattern;

  @override
  State<_DeviceAddressDialog> createState() => _DeviceAddressDialogState();
}

class _DeviceAddressDialogState extends State<_DeviceAddressDialog> {
  late final TextEditingController _controller;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final address = _controller.text.trim().toUpperCase();
    if (!widget.addressPattern.hasMatch(address)) {
      setState(() => _validationMessage = 'Enter a valid Bluetooth address.');
      return;
    }
    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connect biosignalsplux'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Enter the address printed on the biosignalsplux device. '
            'This phone will remember it for next time.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              labelText: 'Bluetooth address',
              hintText: '00:00:00:00:00:00',
              errorText: _validationMessage,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Connect')),
      ],
    );
  }
}
