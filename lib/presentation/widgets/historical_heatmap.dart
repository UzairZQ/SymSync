import 'package:flutter/material.dart';

import '../../domain/services/session_aggregator.dart';
import '../../utils/heatmap_utils.dart';
import '../widgets/session_visuals.dart';
import '../../theme/app_theme.dart';

class HistoricalLegHeatmap extends StatelessWidget {
  final SessionHeatmapData data;
  final String leftLabel;
  final String rightLabel;

  const HistoricalLegHeatmap({
    super.key,
    required this.data,
    this.leftLabel = 'Left trapezius',
    this.rightLabel = 'Right trapezius',
  });

  @override
  Widget build(BuildContext context) {
    if (!data.hasData) {
      return _EmptyHeatmapPlaceholder(
        message: 'No session data yet\nComplete sessions to see heatmap',
      );
    }

    final leftAvg = _averageIntensity(data.leftIntensities);
    final rightAvg = _averageIntensity(data.rightIntensities);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: LegPairSilhouette(
                leftActivation: leftAvg,
                rightActivation: rightAvg,
                leftLabel: leftLabel,
                rightLabel: rightLabel,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            _HeatmapLegend(
              sessionCount: data.sessionCount,
              averageSymmetry: data.averageSymmetry,
              leftAvg: leftAvg,
              rightAvg: rightAvg,
            ),
          ],
        );
      },
    );
  }

  double _averageIntensity(List<List<double>> grid) {
    if (grid.isEmpty) return 0.0;
    double sum = 0.0;
    int count = 0;
    for (final row in grid) {
      for (final v in row) {
        sum += v;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }
}

class _GradientLegend extends StatelessWidget {
  const _GradientLegend();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          'Activation Intensity',
          style: AppTheme.labelSmall.copyWith(color: context.txtTertiary),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            gradient: HeatmapGradient.horizontal(),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Low',
              style: AppTheme.labelSmall.copyWith(
                color: context.txtTertiary,
                fontSize: 10,
              ),
            ),
            Text(
              'High',
              style: AppTheme.labelSmall.copyWith(
                color: context.txtTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  final int sessionCount;
  final double averageSymmetry;
  final double leftAvg;
  final double rightAvg;

  const _HeatmapLegend({
    required this.sessionCount,
    required this.averageSymmetry,
    required this.leftAvg,
    required this.rightAvg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: context.dividerClr),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _LegendStat(
                label: 'Sessions',
                value: '$sessionCount',
                color: AppTheme.accentTeal,
              ),
              _LegendStat(
                label: 'Avg. Symmetry',
                value: '${averageSymmetry.toStringAsFixed(1)}%',
                color: AppTheme.accentLime,
              ),
              _LegendStat(
                label: 'L / R Balance',
                value:
                    '${(leftAvg * 100).toStringAsFixed(0)}% / ${(rightAvg * 100).toStringAsFixed(0)}%',
                color: AppTheme.accentAmber,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          const _GradientLegend(),
        ],
      ),
    );
  }
}

class _LegendStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LegendStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: AppTheme.labelSmall.copyWith(
            color: context.txtTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyHeatmapPlaceholder extends StatelessWidget {
  final String message;

  const _EmptyHeatmapPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.analytics_outlined, size: 48, color: context.txtTertiary),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(
              color: context.txtSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
