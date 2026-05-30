import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/section_label.dart';
import '../../widgets/status_badge.dart';
import '../bloc/session_bloc.dart';

class DashboardPage extends StatefulWidget {
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
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const List<String> _tips = <String>[
    'Keep your step rhythm even to reduce bias between legs.',
    'Breathe steadily and let the biofeedback guide your balance.',
    'A small shift toward the weaker leg can improve symmetry fast.',
    'Use the live view to correct muscle dominance in real time.',
    'Consistency over intensity helps the nervous system learn better.',
  ];

  late final String _tip = _tips[DateTime.now().millisecond % _tips.length];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final lastSummary = state.history.isNotEmpty
            ? state.history.first
            : null;
        final bestScore = state.history
            .map((summary) => summary.averageSymmetryIndex)
            .whereType<double>()
            .fold<double?>(null, (previous, value) {
              if (previous == null) {
                return value.abs();
              }
              return min(previous, value.abs());
            });
        final averageScore = state.symmetryIndex;
        final scoreLabel = averageScore == null
            ? '--'
            : '${(averageScore * 100).toStringAsFixed(0)}%';
        final summaryLabel = averageScore == null
            ? 'No session yet'
            : averageScore >= 0
            ? 'Right side stronger'
            : 'Left side stronger';
        final recentDate = lastSummary == null
            ? 'No recent session'
            : '${lastSummary.startedAt.month}/${lastSummary.startedAt.day}/${lastSummary.startedAt.year}';
        final bestBalanceLabel = bestScore == null
            ? '--'
            : '${(bestScore * 100).toStringAsFixed(0)}%';
        final stats = <_StatCardData>[
          _StatCardData(
            'Today’s Sessions',
            '${state.history.length}',
            'this week',
          ),
          _StatCardData('Avg Symmetry', scoreLabel, 'real-time index'),
          _StatCardData('Best Balance', bestBalanceLabel, 'lowest asymmetry'),
        ];
        final rawSpots = <FlSpot>[];
        final rawPoints = state.rawPoints.take(40).toList();
        for (var i = 0; i < rawPoints.length; i++) {
          rawSpots.add(FlSpot(i.toDouble(), rawPoints[i].toDouble()));
        }

        final loading = state.history.isEmpty && state.symmetryIndex == null;

        return ListView(
          key: const PageStorageKey<String>('dashboard'),
          padding: const EdgeInsets.only(bottom: 24),
          children: <Widget>[
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Good morning,',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        'Zoro',
                        style: AppTheme.headingMedium.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: state.status == SessionStatus.connected
                      ? 'Connected'
                      : state.status == SessionStatus.connecting
                      ? 'Connecting'
                      : 'Disconnected',
                  state: state.status == SessionStatus.connected
                      ? StatusBadgeState.connected
                      : state.status == SessionStatus.connecting
                      ? StatusBadgeState.recording
                      : StatusBadgeState.disconnected,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXL),
            Row(
              children: stats
                  .asMap()
                  .entries
                  .map(
                    (entry) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: entry.key == 0 ? 0 : AppTheme.spaceSM,
                        ),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppTheme.spaceMD),
                          child: loading
                              ? _ShimmerStatCard(
                                  label: entry.value.title,
                                  value: entry.value.value,
                                  subtitle: entry.value.subtitle,
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    SectionLabel(label: entry.value.title),
                                    const SizedBox(height: AppTheme.spaceSM),
                                    Text(
                                      entry.value.value,
                                      style: AppTheme.displayMedium.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontSize: 30,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spaceXS),
                                    Text(
                                      entry.value.subtitle,
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SectionLabel(label: 'Last Session'),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      recentDate,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMD),
                    SizedBox(
                      height: 90,
                      child: rawSpots.isEmpty
                          ? Center(
                              child: Text(
                                'Waiting for session data',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                backgroundColor: Colors.transparent,
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                minY: 0,
                                maxY: 4096,
                                lineBarsData: <LineChartBarData>[
                                  LineChartBarData(
                                    spots: rawSpots,
                                    color: AppTheme.accentTeal,
                                    isCurved: true,
                                    barWidth: 3,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: AppTheme.spaceMD),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Symmetry overview',
                          style: AppTheme.headingMedium.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SectionLabel(label: 'Quick Start'),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      'Ready to begin a new bilateral recording?',
                      style: AppTheme.headingMedium.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      'Tap to begin bilateral EMG recording',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMD),
                    GradientButton(
                      label: 'Start New Session',
                      onPressed: widget.onOpenSession,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppTheme.dangerGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: const Icon(Icons.lightbulb, color: Colors.white),
                    ),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'HMI Tip',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceSM),
                          Text(
                            _tip,
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Recent symmetry',
                      style: AppTheme.headingMedium.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      summaryLabel,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCardData {
  const _StatCardData(this.title, this.value, this.subtitle);

  final String title;
  final String value;
  final String subtitle;
}

class _ShimmerStatCard extends StatelessWidget {
  const _ShimmerStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.backgroundElevated,
      highlightColor: AppTheme.backgroundCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(height: 10, width: 100, color: Colors.white),
          const SizedBox(height: AppTheme.spaceSM),
          Container(height: 32, width: 72, color: Colors.white),
          const SizedBox(height: AppTheme.spaceSM),
          Container(height: 12, width: 120, color: Colors.white),
        ],
      ),
    );
  }
}
