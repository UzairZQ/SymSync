import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/session_summary.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/connection_badge.dart';
import '../../widgets/theme_toggle.dart';
import '../bloc/session_bloc.dart';
import '../../screens/calibration_screen.dart';
import 'session_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onOpenSession,
    required this.onOpenSummary,
    required this.onConnect,
    required this.onDisconnect,
    required this.onCalibrate,
  });

  final VoidCallback onOpenSession;
  final VoidCallback onOpenSummary;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onCalibrate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final symmetry = state.symmetryIndex;
        final hasSymmetry = symmetry != null;
        final symmetryScores = state.history
            .map((s) => s.averageSymmetryIndex)
            .whereType<double>()
            .toList();
        final indexScore = hasSymmetry
            ? (100 - min(65, symmetry.abs() * 100)).round()
            : null;
        final avgSymmetry = hasSymmetry
            ? (100 - symmetry.abs() * 100).toStringAsFixed(1)
            : null;
        final bestSymmetry = symmetryScores.isEmpty
            ? null
            : (100 -
                      symmetryScores.map((s) => s.abs()).reduce(min) * 100)
                  .toStringAsFixed(0);
        final channelA = state.latestRaw;
        final channelB = state.rawPoints3.isEmpty ? 712 : state.rawPoints3.last;
        final isConnected = state.isConnected;
        final isConnecting = state.status == SessionStatus.connecting;
        final hasAnyData = state.history.isNotEmpty || hasSymmetry;
        final recent = state.history.take(3).toList();

        final now = DateTime.now();
        final calibratedAt = state.calibratedAt;
        final isCalibratedRecently = calibratedAt != null &&
            now.difference(calibratedAt).inMinutes < 2;

        return ListView(
          key: const PageStorageKey<String>('dashboard'),
          padding: const EdgeInsets.only(bottom: 28),
          children: <Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'SymSync',
                    style: AppTheme.headingLarge.copyWith(
                      color: context.txtPrimary,
                      fontSize: 28,
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
            Text(
              '${state.greeting},\n${state.displayName}',
              style: AppTheme.displayLarge.copyWith(
                color: context.txtPrimary,
                fontSize: 32,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasAnyData
                  ? 'Stay consistent — your next session will build on the progress you have already made.'
                  : 'Pair your sensors and run a session to start tracking your bilateral symmetry.',
              style: AppTheme.bodyMedium.copyWith(
                color: context.txtSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 148,
                    width: 148,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        SizedBox(
                          height: 148,
                          width: 148,
                          child: CircularProgressIndicator(
                            value: (indexScore ?? 0) / 100,
                            strokeWidth: 9,
                            backgroundColor: context.bgElevated,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              indexScore == null
                                  ? context.txtTertiary
                                  : AppTheme.accentTeal,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              indexScore == null ? '—' : '$indexScore%',
                              style: AppTheme.displayMedium.copyWith(
                                color: context.txtPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'INDEX',
                              style: AppTheme.labelSmall.copyWith(
                                color: context.txtTertiary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  _MetricRow(
                    label: 'Sessions Today',
                    value: '${state.history.length}',
                  ),
                  _MetricRow(
                    label: 'Avg Symmetry',
                    value: avgSymmetry ?? '—',
                  ),
                  _MetricRow(
                    label: 'Best Balance',
                    value: bestSymmetry == null ? '—' : '$bestSymmetry%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.txtPrimary,
                borderRadius: AppTheme.cardRadius,
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 22,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Quick Start',
                    style: AppTheme.headingMedium.copyWith(
                      color: context.bgPrimary,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isConnected
                        ? 'Sensors are streaming. Open a session to begin bilateral analysis.'
                        : 'Connect your biosignalsplux sensors to start a real-time session.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: context.bgPrimary.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.bgPrimary.withValues(alpha: 0.16),
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.sensors_outlined,
                          color: isConnected
                              ? AppTheme.accentLime
                              : (isConnecting
                                    ? AppTheme.accentAmber
                                    : context.bgPrimary),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isConnecting
                                ? 'BIOSIGNALSPLUX: CONNECTING…'
                                : (isConnected
                                      ? 'BIOSIGNALSPLUX: CONNECTED'
                                      : 'BIOSIGNALSPLUX: NOT CONNECTED'),
                            style: AppTheme.labelSmall.copyWith(
                              color: context.bgPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: isConnected ? onDisconnect : onConnect,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: context.bgPrimary.withValues(alpha: 0.8),
                      ),
                      foregroundColor: context.bgPrimary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      isConnected ? 'Disconnect Device' : 'Connect Device',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            if (isConnected && isCalibratedRecently) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SessionScreen(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CalibrationScreen(),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start Session'),
                          style: FilledButton.styleFrom(
                            backgroundColor: context.bgPrimary,
                            foregroundColor: context.txtPrimary,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      if (isConnected && isCalibratedRecently) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.accentGreen, width: 1.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.accentGreen,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Calibrated ✓",
                                style: TextStyle(
                                  color: AppTheme.accentGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ChannelCard(
              label: 'CHANNEL 1',
              title: 'R — Trapezius',
              value: hasSymmetry || isConnected ? channelA.toString() : '—',
              color: AppTheme.rightTrap,
              hasData: hasSymmetry || isConnected,
            ),
            const SizedBox(height: 12),
            _ChannelCard(
              label: 'CHANNEL 3',
              title: 'L — Trapezius',
              value: hasSymmetry || isConnected ? channelB.toString() : '—',
              color: AppTheme.leftTrap,
              hasData: hasSymmetry || isConnected,
            ),
            const SizedBox(height: 14),
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
                  'Port 1 → Right  /  Port 3 → Left',
                  style: AppTheme.labelSmall.copyWith(
                    color: context.txtTertiary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Recent\nSessions',
                          style: AppTheme.headingMedium.copyWith(
                            color: context.txtPrimary,
                            fontSize: 22,
                            height: 1.05,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onOpenSummary,
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No sessions yet — your history will appear here.',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium.copyWith(
                            color: context.txtTertiary,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final s in recent)
                      _SessionListItem(
                        title: s.note.isNotEmpty ? s.note : _defaultTitle(s),
                        tag: _tagFor(s),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _defaultTitle(SessionSummary s) {
    final h = s.startedAt.hour;
    if (h < 12) return 'Morning Session';
    if (h < 17) return 'Afternoon Session';
    if (h < 21) return 'Evening Session';
    return 'Night Session';
  }

  String _tagFor(SessionSummary s) {
    final v = s.averageSymmetryIndex;
    if (v == null) return 'Recorded';
    final score = 100 - v.abs() * 100;
    if (score >= 90) return 'Optimal';
    if (score >= 75) return 'Fair';
    return 'Critical';
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: AppTheme.labelSmall.copyWith(
                color: context.txtTertiary,
                letterSpacing: 1,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              color: context.txtPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.label,
    required this.title,
    required this.value,
    required this.color,
    required this.hasData,
  });

  final String label;
  final String title;
  final String value;
  final Color color;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: context.txtTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTheme.headingMedium.copyWith(
              color: context.txtPrimary,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                value,
                style: AppTheme.displayMedium.copyWith(
                  color: context.txtPrimary,
                  fontSize: 30,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'uV',
                  style: AppTheme.bodyMedium.copyWith(
                    color: context.txtTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: hasData
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List<Widget>.generate(8, (index) {
                      final heights = <double>[16, 22, 30, 18, 26, 14, 24, 20];
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: heights[index],
                          decoration: BoxDecoration(
                            color: color.withValues(
                              alpha: index.isEven ? 0.55 : 0.8,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                      );
                    }),
                  )
                : Center(
                    child: Text(
                      'No data yet',
                      style: AppTheme.bodyMedium.copyWith(
                        color: context.txtTertiary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SessionListItem extends StatelessWidget {
  const _SessionListItem({required this.title, required this.tag});

  final String title;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final tagColor = switch (tag) {
      'Optimal' => AppTheme.accentLime,
      'Fair' => AppTheme.accentAmber,
      'Critical' => AppTheme.accentRed,
      _ => AppTheme.accentTeal,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_walk, color: tagColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                color: context.txtPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag,
              style: AppTheme.labelSmall.copyWith(
                color: tag == 'Critical'
                    ? AppTheme.accentRed
                    : (tag == 'Fair'
                          ? AppTheme.accentAmber
                          : AppTheme.accentGreen),
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
