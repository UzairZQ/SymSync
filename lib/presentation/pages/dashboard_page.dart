import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/session_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/heatmap_utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/connection_badge.dart';
import '../../widgets/terms_glossary_sheet.dart';
import '../../widgets/theme_toggle.dart';
import '../../widgets/research_context_sheet.dart';
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
        final participantHistory = state.activeHistory;
        final symmetryScores = participantHistory
            .map((s) => s.averageSymmetryIndex)
            .whereType<double>()
            .toList();
        final indexScore = hasSymmetry
            ? (100 - min(65, symmetry.abs())).round()
            : null;
        final avgSymmetry = hasSymmetry
            ? (100 - symmetry.abs()).clamp(0, 100).toStringAsFixed(1)
            : null;
        final bestSymmetry = symmetryScores.isEmpty
            ? null
            : (100 - symmetryScores.map((s) => s.abs()).reduce(min))
                  .clamp(0, 100)
                  .toStringAsFixed(0);
        final isConnected = state.isConnected;
        final isConnecting = state.status == SessionStatus.connecting;
        final hasAnyData = participantHistory.isNotEmpty || hasSymmetry;
        final recent = participantHistory.take(3).toList();

        final now = DateTime.now();
        final calibratedAt = state.calibratedAt;
        final isCalibratedRecently =
            calibratedAt != null && now.difference(calibratedAt).inMinutes < 2;

        return ListView(
          key: const PageStorageKey<String>('dashboard'),
          padding: const EdgeInsets.only(bottom: 20),
          children: <Widget>[
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'SymSync',
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
                IconButton(
                  tooltip: 'Explain SymSync terms',
                  onPressed: () => showTermsGlossarySheet(context),
                  style: IconButton.styleFrom(
                    backgroundColor: context.bgCard,
                    foregroundColor: context.txtSecondary,
                    side: BorderSide(color: context.dividerClr),
                  ),
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                ),
                const SizedBox(width: AppTheme.spaceSM),
                const ThemeToggle(),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '${state.greeting},\n${state.displayName}',
              style: AppTheme.displayLarge.copyWith(
                color: context.txtPrimary,
                fontSize: 26,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasAnyData
                  ? 'Stay consistent — your next session will build on the progress you have already made.'
                  : 'Pair your sensors and run a session to start tracking your bilateral symmetry.',
              style: AppTheme.bodyMedium.copyWith(
                color: context.txtSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            const ResearchContextBanner(compact: true),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: CircularProgressIndicator(
                            value: (indexScore ?? 0) / 100,
                            strokeWidth: 8,
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
                                fontSize: 26,
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
                  const SizedBox(height: 18),
                  _MetricRow(
                    label: 'Sessions Today',
                    value: '${participantHistory.length}',
                  ),
                  _MetricRow(label: 'Avg Symmetry', value: avgSymmetry ?? '—'),
                  _MetricRow(
                    label: 'Best Balance',
                    value: bestSymmetry == null ? '—' : '$bestSymmetry%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
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
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isConnected
                        ? 'Sensors are streaming. Open a session to begin bilateral analysis.'
                        : 'Connect your biosignalsplux sensors to start a real-time session.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: context.bgPrimary.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
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
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: isConnected ? onDisconnect : onConnect,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: context.bgPrimary.withValues(alpha: 0.8),
                      ),
                      foregroundColor: context.bgPrimary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      isConnected ? 'Disconnect Device' : 'Connect Device',
                    ),
                  ),
                  const SizedBox(height: 6),
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                            color: AppTheme.accentGreen.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.accentGreen,
                              width: 1.5,
                            ),
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
            const SizedBox(height: 12),
            _LiveChannelStatusCard(
              leftActivation: state.normalisedLeftActivation,
              rightActivation: state.normalisedRightActivation,
              leftActive: isConnected && state.normalisedLeftActivation > 0.03,
              rightActive:
                  isConnected && state.normalisedRightActivation > 0.03,
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(18),
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
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = s.startedAt.day.toString().padLeft(2, '0');
    return 'Upper back symmetry - $day ${months[s.startedAt.month - 1]} ${s.startedAt.year}';
  }

  String _tagFor(SessionSummary s) {
    final v = s.averageSymmetryIndex;
    if (v == null) return 'Recorded';
    final score = 100 - v.abs();
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

class _LiveChannelStatusCard extends StatelessWidget {
  const _LiveChannelStatusCard({
    required this.leftActivation,
    required this.rightActivation,
    required this.leftActive,
    required this.rightActive,
  });

  final double leftActivation;
  final double rightActivation;
  final bool leftActive;
  final bool rightActive;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Live Channel Status',
            style: AppTheme.headingMedium.copyWith(color: context.txtPrimary),
          ),
          const SizedBox(height: 12),
          _ActivationStatusRow(
            label: 'LEFT TRAPEZIUS',
            activation: leftActivation,
            active: leftActive,
          ),
          const SizedBox(height: 12),
          _ActivationStatusRow(
            label: 'RIGHT TRAPEZIUS',
            activation: rightActivation,
            active: rightActive,
          ),
        ],
      ),
    );
  }
}

class _ActivationStatusRow extends StatelessWidget {
  const _ActivationStatusRow({
    required this.label,
    required this.activation,
    required this.active,
  });

  final String label;
  final double activation;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final displayActivation = active ? activation.clamp(0.0, 1.0) : 0.0;
    final color = active
        ? HeatmapUtils.activationColour(displayActivation)
        : const Color(0xFF9CA3AF);
    final pct = (displayActivation * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: AppTheme.labelSmall.copyWith(
                  color: context.txtTertiary,
                  letterSpacing: 1,
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF9CA3AF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              active ? 'Active' : 'Inactive',
              style: AppTheme.bodyMedium.copyWith(
                color: active ? context.txtPrimary : context.txtTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: displayActivation,
                  minHeight: 8,
                  backgroundColor: context.bgElevated,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 92,
              child: Text(
                '$pct% activation',
                textAlign: TextAlign.end,
                style: AppTheme.bodyMedium.copyWith(
                  color: active ? context.txtSecondary : context.txtTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
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
            child: Icon(
              Icons.accessibility_new_rounded,
              color: tagColor,
              size: 16,
            ),
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
