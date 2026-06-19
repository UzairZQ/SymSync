import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/connection_badge.dart';
import '../../widgets/theme_toggle.dart';
import '../bloc/session_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final sessionCount = state.history.length;
        final totalSeconds = state.history.fold<int>(
          0,
          (sum, item) => sum + item.durationSeconds,
        );
        final totalMinutes = (totalSeconds / 60).round();
        final totalHours = (totalSeconds / 3600).round();
        final symmetryScores = state.history
            .map((s) => s.averageSymmetryIndex)
            .whereType<double>()
            .toList();
        final avgSI = symmetryScores.isEmpty
            ? null
            : symmetryScores.reduce((a, b) => a + b) / symmetryScores.length;
        final balance = avgSI == null
            ? '—'
            : (100 - avgSI.abs()).toStringAsFixed(1);
        final balanceLabel = avgSI == null
            ? 'Awaiting data'
            : (100 - avgSI.abs()) >= 90
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
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: <Widget>[
                  Container(
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
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.bgPrimary, width: 2),
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
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
              value: totalSeconds == 0
                  ? '0'
                  : (totalHours >= 1 ? '$totalHours' : '$totalMinutes'),
              suffix: totalSeconds == 0
                  ? 'h Total'
                  : (totalHours >= 1 ? 'h Tracked' : 'min Tracked'),
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
            const _SectionTitle('Preferences'),
            _ToggleRow(
              title: 'Dark Theme',
              body: 'Adjust interface luminosity for low-light environments.',
              value: context.isDark,
              onChanged: (isDark) {
                ThemeProvider.setThemeMode(
                  isDark ? ThemeMode.dark : ThemeMode.light,
                );
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
                    onPressed: () {},
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: const Text('Clear All Session Data'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: Colors.white,
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
                style: AppTheme.displayLarge.copyWith(
                  color: fg,
                  fontSize: 36,
                ),
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
        style: AppTheme.headingLarge.copyWith(
          color: context.txtPrimary,
        ),
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
