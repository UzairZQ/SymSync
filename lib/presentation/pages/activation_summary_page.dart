import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/connection_badge.dart';
import '../../widgets/heatmap_silhouette_widget.dart';
import '../../widgets/terms_glossary_sheet.dart';

class ActivationSummaryPage extends StatefulWidget {
  const ActivationSummaryPage({super.key});

  @override
  State<ActivationSummaryPage> createState() => _ActivationSummaryPageState();
}

class _ActivationSummaryPageState extends State<ActivationSummaryPage> {
  int _periodIndex = 1;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final now = DateTime.now();
        final periods = <Duration>[
          const Duration(days: 1),
          const Duration(days: 7),
          const Duration(days: 30),
        ];
        final cutoff = now.subtract(periods[_periodIndex]);
        final filteredHistory = state.history
            .where((s) => s.startedAt.isAfter(cutoff))
            .toList();

        final historyCount = filteredHistory.length;

        final symmetryScores = filteredHistory
            .map((s) => s.averageSymmetryIndex)
            .whereType<double>()
            .toList();
        final avgSI = symmetryScores.isEmpty
            ? null
            : symmetryScores.reduce((a, b) => a + b) / symmetryScores.length;
        final avgDeviation = avgSI == null ? null : avgSI.abs();

        final trendPercent = _trendPercent(filteredHistory);
        final trendingUp = trendPercent == null ? null : trendPercent >= 0;
        final isConnected = state.isConnected;
        final isConnecting = state.status == SessionStatus.connecting;

        // Compute time-averaged left / right activations from filtered history
        double leftAvg = 0.0;
        double rightAvg = 0.0;
        if (filteredHistory.isNotEmpty) {
          final leftVals = filteredHistory
              .map((s) => s.averageLeftActivation)
              .whereType<double>();
          final rightVals = filteredHistory
              .map((s) => s.averageRightActivation)
              .whereType<double>();
          if (leftVals.isNotEmpty) {
            leftAvg = leftVals.reduce((a, b) => a + b) / leftVals.length;
          }
          if (rightVals.isNotEmpty) {
            rightAvg = rightVals.reduce((a, b) => a + b) / rightVals.length;
          }
        }

        // Primary imbalance label
        String primaryImbalance;
        if (avgSI == null) {
          primaryImbalance = 'Pending';
        } else if (avgSI < -15) {
          primaryImbalance = 'Left Trap Dominance';
        } else if (avgSI > 15) {
          primaryImbalance = 'Right Trap Dominance';
        } else {
          primaryImbalance = 'Balanced';
        }

        return ListView(
          key: const PageStorageKey<String>('summary'),
          padding: const EdgeInsets.only(bottom: AppTheme.spaceLG),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Activation Summary',
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
                  tooltip: 'Explain summary terms',
                  onPressed: () => showTermsGlossarySheet(context),
                  style: IconButton.styleFrom(
                    backgroundColor: context.bgCard,
                    foregroundColor: context.txtSecondary,
                    side: BorderSide(color: context.dividerClr),
                  ),
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'Review your recent symmetry and muscle pattern trends',
              style: AppTheme.bodyMedium.copyWith(color: context.txtSecondary),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            AppCard(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Imbalance heatmap',
                    style: AppTheme.labelSmall.copyWith(
                      color: context.txtTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  SizedBox(
                    height: 260,
                    child: historyCount > 0
                        ? HeatmapSilhouetteWidget(
                            leftActivation: leftAvg.clamp(0.0, 1.0),
                            rightActivation: rightAvg.clamp(0.0, 1.0),
                            width: 200,
                          )
                        : const _EmptyHeatmap(),
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  // Muscle chip row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _MuscleChip(label: 'Trapezius', isActive: true),
                      const SizedBox(width: AppTheme.spaceSM),
                      Tooltip(
                        message: 'Coming soon',
                        triggerMode: TooltipTriggerMode.tap,
                        child: _MuscleChip(label: 'Deltoid', isActive: false),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Tooltip(
                        message: 'Coming soon',
                        triggerMode: TooltipTriggerMode.tap,
                        child: _MuscleChip(label: 'Lat', isActive: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _summaryMetric(
                          context: context,
                          label: 'Sessions',
                          value: '$historyCount',
                          color: AppTheme.accentTeal,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Expanded(
                        child: _summaryMetric(
                          context: context,
                          label: 'Trend',
                          value: trendPercent == null
                              ? '—'
                              : '${trendingUp! ? '+' : ''}${trendPercent.toStringAsFixed(0)}%',
                          color: trendPercent == null || !trendingUp!
                              ? AppTheme.accentRed
                              : AppTheme.accentLime,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceSM,
              ),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(color: context.dividerClr),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List<Widget>.generate(3, (index) {
                  const labels = <String>['Today', '7 Days', '30 Days'];
                  final active = _periodIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _periodIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceXS,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spaceSM,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.accentTeal.withValues(alpha: 0.16)
                              : context.bgElevated,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLG,
                          ),
                        ),
                        child: Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium.copyWith(
                            color: active
                                ? context.txtPrimary
                                : context.txtSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            AppCard(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Pattern Analysis',
                        style: AppTheme.headingMedium.copyWith(
                          color: context.txtPrimary,
                        ),
                      ),
                      if (trendPercent != null)
                        Text(
                          '${trendingUp! ? '+' : ''}${trendPercent.toStringAsFixed(0)}%',
                          style: AppTheme.labelSmall.copyWith(
                            color: trendingUp
                                ? AppTheme.accentLime
                                : AppTheme.accentRed,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _analysisItem(
                        context: context,
                        title: 'Avg. Deviation',
                        value: avgDeviation == null
                            ? '—'
                            : '${avgDeviation.toStringAsFixed(0)}%',
                        valueColor: context.txtSecondary,
                      ),
                      _analysisItem(
                        context: context,
                        title: 'Primary Imbalance',
                        value: primaryImbalance,
                        valueColor: primaryImbalance == 'Balanced'
                            ? AppTheme.accentLime
                            : AppTheme.accentAmber,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  double? _trendPercent(List history) {
    if (history.length < 2) return null;
    final scores = history
        .map((s) => s.averageSymmetryIndex)
        .whereType<double>()
        .toList();
    if (scores.length < 2) return null;
    final recent = scores.first.abs();
    final prior = scores[1].abs();
    if (prior == 0) return 0;
    return ((prior - recent) / prior) * 100;
  }

  Widget _summaryMetric({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: context.txtSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          value,
          style: AppTheme.headingMedium.copyWith(color: color, fontSize: 20),
        ),
      ],
    );
  }

  Widget _analysisItem({
    required BuildContext context,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: AppTheme.labelSmall.copyWith(color: context.txtSecondary),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            value,
            style: AppTheme.bodyLarge.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _MuscleChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.accentTeal.withValues(alpha: 0.16)
            : context.bgElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: isActive ? AppTheme.accentTeal : context.dividerClr,
        ),
      ),
      child: Text(
        label,
        style: AppTheme.bodySmall.copyWith(
          color: isActive ? AppTheme.accentTeal : context.txtTertiary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptyHeatmap extends StatelessWidget {
  const _EmptyHeatmap();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.heat_pump_outlined,
            size: 40,
            color: context.txtTertiary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            'No data yet',
            style: AppTheme.bodyMedium.copyWith(color: context.txtSecondary),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            'Run a session to see your heatmap',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(color: context.txtTertiary),
          ),
        ],
      ),
    );
  }
}
