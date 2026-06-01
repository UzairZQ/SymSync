import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/connection_badge.dart';
import '../widgets/session_visuals.dart';

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
        final symmetry = state.symmetryIndex;
        final hasSymmetry = symmetry != null;
        final historyCount = state.history.length;

        final symmetryScores = state.history
            .map((s) => s.averageSymmetryIndex)
            .whereType<double>()
            .toList();
        final avgDeviation = symmetryScores.isEmpty
            ? null
            : symmetryScores.map((s) => s.abs()).reduce((a, b) => a + b) /
                  symmetryScores.length;
        final trendPercent = _trendPercent(state.history);
        final trendingUp = trendPercent == null
            ? null
            : trendPercent >= 0;
        final leftActivation = state.liveActivation;
        final rightActivation = hasSymmetry
            ? (state.liveActivation * (1 - symmetry))
            : null;
        final isConnected = state.isConnected;
        final isConnecting = state.status == SessionStatus.connecting;
        final hasData = historyCount > 0 || hasSymmetry;

        return ListView(
          key: const PageStorageKey<String>('summary'),
          padding: const EdgeInsets.only(bottom: AppTheme.spaceXL),
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
              ],
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'Review your recent symmetry and muscle pattern trends',
              style: AppTheme.bodyLarge.copyWith(color: context.txtSecondary),
            ),
            const SizedBox(height: AppTheme.spaceXL),
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
                  const SizedBox(height: AppTheme.spaceMD),
                  SizedBox(
                    height: 280,
                    child: hasData
                        ? LegPairSilhouette(
                            leftActivation: leftActivation.clamp(0.0, 1.0),
                            rightActivation: rightActivation?.clamp(0.0, 1.0),
                          )
                        : _EmptyHeatmap(),
                  ),
                  const SizedBox(height: AppTheme.spaceXL),
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
            const SizedBox(height: AppTheme.spaceXL),
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
            const SizedBox(height: AppTheme.spaceXL),
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
                            : '${(avgDeviation * 100).toStringAsFixed(0)}%',
                        valueColor: context.txtSecondary,
                      ),
                      _analysisItem(
                        context: context,
                        title: 'Balance',
                        value: historyCount > 0 ? 'Stable' : 'Pending',
                        valueColor: context.txtPrimary,
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
          style: AppTheme.headingMedium.copyWith(
            color: color,
            fontSize: 24,
          ),
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

class _EmptyHeatmap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.heat_pump_outlined,
            size: 56,
            color: context.txtTertiary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'No data yet',
            style: AppTheme.bodyLarge.copyWith(color: context.txtSecondary),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            'Run a session to see your heatmap',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(color: context.txtTertiary),
          ),
        ],
      ),
    );
  }
}
