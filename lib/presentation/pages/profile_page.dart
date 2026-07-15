import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/export/research_data_export_service.dart';
import '../../domain/models/research_context.dart';
import '../../theme/app_theme.dart';
import '../../theme/accessibility_provider.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/connection_badge.dart';
import '../../widgets/sensor_placement_guide.dart';
import '../../widgets/theme_toggle.dart';
import '../../widgets/terms_glossary_sheet.dart';
import '../../widgets/research_context_sheet.dart';
import '../bloc/session_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final participantHistory = state.activeHistory;
        final sessionCount = participantHistory.length;
        final totalSeconds = participantHistory.fold<int>(
          0,
          (sum, item) => sum + item.durationSeconds,
        );
        final trackedTimeValue = totalSeconds >= 3600
            ? (totalSeconds / 3600).toStringAsFixed(1)
            : totalSeconds >= 60
            ? (totalSeconds / 60).round().toString()
            : totalSeconds.toString();
        final trackedTimeUnit = totalSeconds >= 3600
            ? 'h Tracked'
            : totalSeconds >= 60
            ? 'min Tracked'
            : 'sec Tracked';
        final symmetryScores = participantHistory
            .map((s) => s.averageSymmetryIndex)
            .whereType<double>()
            .toList();
        final avgSI = symmetryScores.isEmpty
            ? null
            : symmetryScores.reduce((a, b) => a + b) / symmetryScores.length;
        final balanceScore = avgSI == null
            ? null
            : (100 - avgSI.abs()).clamp(0.0, 100.0);
        final balance = balanceScore == null
            ? '—'
            : balanceScore.toStringAsFixed(1);
        final balanceLabel = avgSI == null
            ? 'Awaiting data'
            : balanceScore! >= 90
            ? 'Optimal'
            : 'Tracking';
        final displayName = state.displayName;
        final initials = _initials(displayName);
        final isConnected = state.isConnected;
        final isConnecting = state.status == SessionStatus.connecting;
        final hasData = sessionCount > 0;

        return ListView(
          key: const PageStorageKey<String>('profile'),
          padding: const EdgeInsets.only(bottom: 20),
          children: <Widget>[
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Profile',
                    style: AppTheme.headingLarge.copyWith(
                      color: context.txtPrimary,
                    ),
                  ),
                ),
                ConnectionBadge(
                  isConnected: isConnected,
                  isConnecting: isConnecting,
                ),
                const SizedBox(width: AppTheme.spaceSM),
                const ThemeToggle(),
              ],
            ),
            const SizedBox(height: 28),
            const ResearchContextBanner(),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: context.txtPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.bgPrimary, width: 3),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 22,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: AppTheme.displayMedium.copyWith(
                    color: context.bgPrimary,
                    fontSize: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasData ? 'TRACKING' : 'NEW USER',
              textAlign: TextAlign.center,
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.accentGreen,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: AppTheme.displayMedium.copyWith(
                color: context.txtPrimary,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hasData
                  ? 'Monitoring bilateral performance and\nsymmetry trends across your sessions.'
                  : 'Set up your sensors and run your first\nsession to start tracking your progress.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(
                color: context.txtSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: context.dividerClr),
                ),
                child: Text(
                  'Data stored locally',
                  style: AppTheme.labelSmall.copyWith(
                    color: context.txtSecondary,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _ProfileStatCard(
              icon: Icons.grid_view_outlined,
              title: 'Sessions',
              value: '$sessionCount',
              suffix: hasData ? 'Recorded' : 'None yet',
            ),
            const SizedBox(height: 10),
            _ProfileStatCard(
              icon: Icons.timer_outlined,
              title: 'Time',
              value: trackedTimeValue,
              suffix: trackedTimeUnit,
            ),
            const SizedBox(height: 10),
            _ProfileStatCard(
              icon: Icons.balance_outlined,
              title: 'Balance',
              value: balance,
              suffix: balanceLabel,
              inverted: true,
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Research'),
            _ActionRow(
              icon: Icons.groups_2_outlined,
              title: 'Participants',
              body:
                  'Create or switch anonymous IDs and keep measurements separated.',
              onTap: () => showParticipantManagerSheet(context),
            ),
            _ActionRow(
              icon: Icons.file_download_outlined,
              title: 'Export research data',
              body:
                  'Share CSV and JSON copies of participants, scenarios, feedback views, durations, and summary metrics.',
              onTap: () => _exportResearchData(context, state),
            ),
            _ActionRow(
              icon: Icons.tune_rounded,
              title: 'Notification thresholds',
              body:
                  'Set the sustained imbalance, sensitivity, and reminder cooldown.',
              onTap: () => _showNotificationSettings(context),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Learn'),
            _ActionRow(
              icon: Icons.menu_book_outlined,
              title: 'SymSync terms',
              body:
                  'Understand symmetry, balance, activation, trends, and signal quality.',
              onTap: () => showTermsGlossarySheet(context),
            ),
            _ActionRow(
              icon: Icons.sensors_outlined,
              title: 'Sensor placement',
              body:
                  'Review the ${state.targetMuscle.chipLabel.toLowerCase()} landmarks and bilateral setup steps.',
              onTap: () => showSensorPlacementSheet(
                context,
                targetMuscle: state.targetMuscle,
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Preferences'),
            _ToggleRow(
              title: 'Dark Theme',
              body: 'Adjust interface luminosity for low-light environments.',
              value: context.isDark,
              onChanged: (isDark) {
                unawaited(
                  ThemeProvider.setThemeMode(
                    isDark ? ThemeMode.dark : ThemeMode.light,
                  ),
                );
              },
            ),
            _ToggleRow(
              title: 'Color-blind mode',
              body:
                  'Uses a perceptually distinct palette plus labels and marker patterns.',
              value: AccessibilityProvider.colorBlindMode,
              onChanged: AccessibilityProvider.setColorBlindMode,
            ),
            _ToggleRow(
              title: 'Corrective notifications',
              body:
                  'Local reminders appear only after a sustained imbalance threshold.',
              value: state.notificationPreferences.enabled,
              onChanged: (enabled) async {
                final allowed = await context
                    .read<SessionBloc>()
                    .setNotificationsEnabled(enabled);
                if (enabled && !allowed && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification permission was not granted.'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 28),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Danger Zone',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.accentRed,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This action is irreversible. All recorded biometric history will be permanently deleted from local storage.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: context.txtSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: state.isRecording
                        ? null
                        : () => _confirmClearSessionData(
                            context,
                            hasData: state.history.isNotEmpty,
                          ),
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: Text(
                      state.isRecording
                          ? 'Stop Recording to Clear Data'
                          : 'Clear All Session Data',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.accentRed.withValues(
                        alpha: 0.35,
                      ),
                      disabledForegroundColor: Colors.white70,
                      shape: const StadiumBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: state.isRecording
                        ? null
                        : () => _confirmResetResearchData(context),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reset Participant Registry and Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentRed,
                      side: const BorderSide(color: AppTheme.accentRed),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportResearchData(
    BuildContext context,
    SessionState state,
  ) async {
    if (state.history.isEmpty && state.participants.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('There is no research data to export.')),
        );
      return;
    }

    final shouldExport = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.ios_share_outlined),
        title: const Text('Export research data?'),
        content: Text(
          'This creates read-only copies of ${state.participants.length} '
          'participant records and ${state.history.length} saved sessions. '
          'The files include pseudonymous IDs and biometric summaries, but no '
          'raw EMG waveform. Your data will remain stored in SymSync.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Create export'),
          ),
        ],
      ),
    );
    if (shouldExport != true || !context.mounted) return;

    try {
      const service = ResearchDataExportService();
      final bundle = service.buildBundle(
        participants: state.participants,
        sessions: state.history,
      );
      await service.share(bundle);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not export research data: $error')),
        );
    }
  }

  Future<void> _confirmClearSessionData(
    BuildContext context, {
    required bool hasData,
  }) async {
    if (!hasData) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('There is no session data to delete.')),
        );
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.delete_forever_outlined,
            color: AppTheme.accentRed,
          ),
          title: const Text('Clear all session data?'),
          content: const Text(
            'This permanently deletes every recorded session and resets the '
            'Summary and Profile statistics on this device. Sensor mapping, '
            'calibration preferences, onboarding, and theme settings are kept.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete permanently'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !context.mounted) {
      return;
    }

    try {
      await context.read<SessionBloc>().clearSessionHistory();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('All recorded session data was deleted.'),
          ),
        );
    } on StateError catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message.toString())));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Session data could not be deleted. Please try again.',
            ),
          ),
        );
    }
  }

  Future<void> _confirmResetResearchData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.accentRed,
        ),
        title: const Text('Reset all research data?'),
        content: const Text(
          'This deletes every participant ID and every recorded session. '
          'Use this before enrolling real participants after dummy testing. '
          'Onboarding, theme, and sensor mapping remain available.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<SessionBloc>().resetResearchData();
  }

  Future<void> _showNotificationSettings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<SessionBloc>(),
        child: const _NotificationSettingsSheet(),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '·';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet();

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  late double _threshold;
  late double _seconds;
  late double _cooldown;

  @override
  void initState() {
    super.initState();
    final preferences = context
        .read<SessionBloc>()
        .state
        .notificationPreferences;
    _threshold = preferences.imbalanceThreshold.toDouble();
    _seconds = preferences.sustainedSeconds.toDouble();
    _cooldown = preferences.cooldownMinutes.toDouble();
  }

  Future<void> _save() async {
    await context.read<SessionBloc>().updateNotificationPreferences(
      imbalanceThreshold: _threshold.round(),
      sustainedSeconds: _seconds.round(),
      cooldownMinutes: _cooldown.round(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scenario = context.read<SessionBloc>().state.selectedScenario;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Corrective notification logic',
              style: AppTheme.headingLarge.copyWith(color: context.txtPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Short intentional asymmetry is ignored. ${scenario.label} '
              'currently enforces at least '
              '${scenario.defaultNotificationDelaySeconds} seconds before an alert.',
              style: AppTheme.bodyMedium.copyWith(
                color: context.txtSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            _SettingSlider(
              label: 'Imbalance threshold',
              valueLabel: '${_threshold.round()}%',
              value: _threshold,
              min: 10,
              max: 50,
              divisions: 8,
              onChanged: (value) => setState(() => _threshold = value),
            ),
            _SettingSlider(
              label: 'Sustained duration',
              valueLabel: '${_seconds.round()} seconds',
              value: _seconds,
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (value) => setState(() => _seconds = value),
            ),
            _SettingSlider(
              label: 'Notification cooldown',
              valueLabel: '${_cooldown.round()} minutes',
              value: _cooldown,
              min: 1,
              max: 30,
              divisions: 29,
              onChanged: (value) => setState(() => _cooldown = value),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: const Text('Save Settings')),
          ],
        ),
      ),
    );
  }
}

class _SettingSlider extends StatelessWidget {
  const _SettingSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(label)),
              Text(
                valueLabel,
                style: AppTheme.bodyMedium.copyWith(
                  color: context.txtPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.accentTeal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTheme.headingMedium.copyWith(
                      color: context.txtPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: AppTheme.bodySmall.copyWith(
                      color: context.txtSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.txtTertiary),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.suffix,
    this.inverted = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String suffix;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final bg = inverted ? context.txtPrimary : context.bgCard;
    final fg = inverted ? context.bgPrimary : context.txtPrimary;
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppTheme.cardRadius,
        border: inverted ? null : Border.all(color: const Color(0xFFF2EEE1)),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                icon,
                color: inverted
                    ? context.bgPrimary.withValues(alpha: 0.72)
                    : context.txtSecondary,
                size: 16,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  color: inverted
                      ? context.bgPrimary.withValues(alpha: 0.72)
                      : context.txtSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                value,
                style: AppTheme.displayLarge.copyWith(color: fg, fontSize: 36),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  suffix,
                  style: AppTheme.labelSmall.copyWith(
                    color: inverted
                        ? AppTheme.accentLime
                        : AppTheme.accentGreen,
                    letterSpacing: 0,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.dividerClr)),
      ),
      child: Text(
        title,
        style: AppTheme.headingLarge.copyWith(color: context.txtPrimary),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String body;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTheme.headingMedium.copyWith(
                    color: context.txtPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppTheme.bodySmall.copyWith(
                    color: context.txtSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.accentGreen,
          ),
        ],
      ),
    );
  }
}
