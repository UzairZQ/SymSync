import 'package:flutter/material.dart';

import '../../domain/services/session_aggregator.dart';
import '../../theme/app_theme.dart';

class HistoricalLegHeatmap extends StatelessWidget {
  final SessionHeatmapData data;
  final String leftLabel;
  final String rightLabel;

  const HistoricalLegHeatmap({
    super.key,
    required this.data,
    this.leftLabel = 'Left leg',
    this.rightLabel = 'Right leg',
  });

  @override
  Widget build(BuildContext context) {
    if (!data.hasData) {
      return _EmptyHeatmapPlaceholder(
        message: 'No session data yet\nComplete sessions to see heatmap',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _LegHeatmapPair(
                      intensities: data.leftIntensities,
                      label: leftLabel,
                      color: AppTheme.leftLeg,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: _LegHeatmapPair(
                      intensities: data.rightIntensities,
                      label: rightLabel,
                      color: AppTheme.rightLeg,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            _HeatmapLegend(
              sessionCount: data.sessionCount,
              averageSymmetry: data.averageSymmetry,
            ),
          ],
        );
      },
    );
  }
}

class _LegHeatmapPair extends StatelessWidget {
  final List<List<double>> intensities;
  final String label;
  final Color color;

  const _LegHeatmapPair({
    required this.intensities,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _HistoricalHeatmapPainter(
              intensities: intensities,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: context.txtSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HistoricalHeatmapPainter extends CustomPainter {
  final List<List<double>> intensities;

  _HistoricalHeatmapPainter({required this.intensities});

  Color _heatColor(double value) {
    final clamped = value.clamp(0.0, 1.0);
    return Color.lerp(
      const Color(0xFF355CFF),
      const Color(0xFFFF7A59),
      clamped,
    )!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 4;
    final rows = intensities.length;

    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final intensity = intensities[r][c];
        final rect = Rect.fromLTWH(
          c * cellWidth,
          r * cellHeight,
          cellWidth,
          cellHeight,
        );

        final paint = Paint()
          ..color = _heatColor(intensity)
          ..style = PaintingStyle.fill;

        canvas.drawRect(rect, paint);

        final borderPaint = Paint()
          ..color = const Color(0x00000000).withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_HistoricalHeatmapPainter oldDelegate) {
    return oldDelegate.intensities != intensities;
  }
}

class _HeatmapLegend extends StatelessWidget {
  final int sessionCount;
  final double averageSymmetry;

  const _HeatmapLegend({
    required this.sessionCount,
    required this.averageSymmetry,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Analysis',
                style: AppTheme.labelSmall.copyWith(
                  color: context.txtTertiary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                '$sessionCount sessions',
                style: AppTheme.bodyMedium.copyWith(
                  color: context.txtPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Avg. Symmetry',
                style: AppTheme.labelSmall.copyWith(
                  color: context.txtTertiary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                '${averageSymmetry.toStringAsFixed(1)}%',
                style: AppTheme.bodyMedium.copyWith(
                  color: context.txtPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          _GradientLegend(),
        ],
      ),
    );
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
          'Intensity',
          style: AppTheme.labelSmall.copyWith(
            color: context.txtTertiary,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        Container(
          width: 80,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF355CFF),
                Color(0xFFFF7A59),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
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
            const SizedBox(width: AppTheme.spaceSM),
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

class _EmptyHeatmapPlaceholder extends StatelessWidget {
  final String message;

  const _EmptyHeatmapPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: context.txtTertiary,
          ),
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
