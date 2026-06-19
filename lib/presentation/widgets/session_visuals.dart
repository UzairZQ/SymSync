import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/services/signal_processor.dart';
import '../../theme/app_theme.dart';
import '../../utils/heatmap_utils.dart';

class EmgWaveformChart extends StatelessWidget {
  const EmgWaveformChart({super.key, required this.samples});

  final List<int> samples;

  @override
  Widget build(BuildContext context) {
    final spots = List<FlSpot>.generate(
      samples.length,
      (index) => FlSpot(index.toDouble(), samples[index].toDouble()),
    );
    final maxX = samples.isEmpty ? 1.0 : (samples.length - 1).toDouble();
    return AspectRatio(
      aspectRatio: 1.8,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: SignalProcessor.fullScale.toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 16384,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFF1D2433).withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: const Color(0xFF1D2433).withValues(alpha: 0.08),
            ),
          ),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: const Color(0xFF355CFF),
              barWidth: 1.6,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF355CFF).withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegPairSilhouette extends StatelessWidget {
  const LegPairSilhouette({
    super.key,
    required this.leftActivation,
    this.rightActivation,
    this.leftLabel = 'Left trapezius',
    this.rightLabel = 'Right trapezius',
  });

  final double leftActivation;
  final double? rightActivation;
  final String leftLabel;
  final String rightLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final legendWidth = 20.0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: constraints.maxWidth - legendWidth,
              height: constraints.maxHeight,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/upper_body.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    width: constraints.maxWidth - legendWidth,
                    height: constraints.maxHeight,
                  ),
                  CustomPaint(
                    size: Size(constraints.maxWidth - legendWidth, constraints.maxHeight),
                    painter: _LegActivationPainter(
                      leftActivation: leftActivation,
                      rightActivation: rightActivation,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            _GradientLegend(height: constraints.maxHeight / 2),
          ],
        );
      },
    );
  }
}

class _LegActivationPainter extends CustomPainter {
  _LegActivationPainter({
    required this.leftActivation,
    required this.rightActivation,
  });

  final double leftActivation;
  final double? rightActivation;

  void _drawLegHeatmap(
    Canvas canvas,
    Rect area,
    double activation, {
    required bool active,
  }) {
    if (!active) return;
    const cols = 4;
    const rows = 14;
    final spacingX = area.width / (cols + 1);
    final spacingY = area.height / (rows + 1);
    final dotRadius = (spacingX * 0.35).clamp(2.0, 6.0);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = area.left + spacingX * (c + 1);
        final y = area.top + spacingY * (r + 1);

        final vertical = (r / (rows - 1)).clamp(0.0, 1.0);
        final horizontal = (c / (cols - 1) - 0.5).abs() * 2.0;
        final intensity =
            0.3 + (1.0 - (vertical * 0.5 + horizontal * 0.3)) * 0.7;

        final color =
            HeatmapGradient.at((activation * intensity).clamp(0.0, 1.0));
        final alpha = 0.50 + intensity.clamp(0.0, 1.0) * 0.50;

        final paint = Paint()..color = color.withValues(alpha: alpha);
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final leftThigh = Rect.fromLTWH(
      size.width * 0.30,
      size.height * 0.22,
      size.width * 0.13,
      size.height * 0.22,
    );
    final leftCalf = Rect.fromLTWH(
      size.width * 0.30,
      size.height * 0.52,
      size.width * 0.12,
      size.height * 0.28,
    );
    final rightThigh = Rect.fromLTWH(
      size.width * 0.57,
      size.height * 0.22,
      size.width * 0.13,
      size.height * 0.22,
    );
    final rightCalf = Rect.fromLTWH(
      size.width * 0.58,
      size.height * 0.52,
      size.width * 0.12,
      size.height * 0.28,
    );

    _drawLegHeatmap(canvas, leftThigh, leftActivation, active: true);
    _drawLegHeatmap(canvas, leftCalf, leftActivation, active: true);
    _drawLegHeatmap(
      canvas,
      rightThigh,
      rightActivation ?? 0.0,
      active: rightActivation != null,
    );
    _drawLegHeatmap(
      canvas,
      rightCalf,
      rightActivation ?? 0.0,
      active: rightActivation != null,
    );

    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF355CFF).withValues(alpha: 0.10);
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.10),
      Offset(size.width / 2, size.height * 0.98),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LegActivationPainter oldDelegate) {
    return oldDelegate.leftActivation != leftActivation ||
        oldDelegate.rightActivation != rightActivation;
  }
}

class TiltMeter extends StatelessWidget {
  const TiltMeter({
    super.key,
    required this.symmetryIndex,
    required this.label,
  });

  final double? symmetryIndex;
  final String label;

  static const _degreeLabels = <String>[
    '-20°', '-10°', '0°', '+10°', '+20°',
  ];

  @override
  Widget build(BuildContext context) {
    final tiltDegrees = symmetryIndex == null
        ? 0.0
        : (symmetryIndex! / 3.0).clamp(-20.0, 20.0);
    final hasData = symmetryIndex != null;
    final position = (tiltDegrees + 20.0) / 40.0;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.5, end: hasData ? position : 0.5),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, animatedPosition, child) {
        final leftColor = AppTheme.accentAmber;
        final centerColor = AppTheme.accentTeal;
        final rightColor = AppTheme.accentBlue;
        final thumbColor = hasData
            ? (animatedPosition < 0.45
                  ? leftColor
                  : animatedPosition > 0.55
                      ? rightColor
                      : centerColor)
            : context.txtTertiary;
        return Column(
          children: <Widget>[
            _HeaderRow(animatedPosition: animatedPosition, hasData: hasData),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackLeft = constraints.maxWidth * 0.04;
                  final trackWidth = constraints.maxWidth * 0.92;
                  final trackTop = (constraints.maxHeight - 6) / 2;
                  final markerX =
                      trackLeft + (trackWidth * animatedPosition.clamp(0.0, 1.0));
                  return Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      // Background track — glassmorphism
                      Positioned(
                        left: trackLeft,
                        top: trackTop,
                        child: Container(
                          width: trackWidth,
                          height: 6,
                          decoration: BoxDecoration(
                            color: context.bgElevated.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: context.dividerClr.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                      // Active fill — gradient from left edge to thumb
                      if (hasData)
                        Positioned(
                          left: trackLeft,
                          top: trackTop,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Container(
                              width: (markerX - trackLeft).clamp(0, trackWidth),
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    leftColor.withValues(alpha: 0.7),
                                    centerColor,
                                    rightColor.withValues(alpha: 0.7),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Tick marks
                      for (int i = 0; i < 5; i++) ...[
                        Positioned(
                          left: trackLeft + (trackWidth * i / 4) - 1.5,
                          top: trackTop + 6 - 1.5,
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: context.txtTertiary.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                      // Thumb with glow
                      Positioned(
                        left: markerX - 14,
                        top: trackTop - 7,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: thumbColor,
                            shape: BoxShape.circle,
                            boxShadow: hasData
                                ? [
                                    BoxShadow(
                                      color: thumbColor.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                            border: Border.all(
                              color: hasData
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : context.dividerClr,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _degreeLabels.map((d) {
                return Text(
                  d,
                  style: AppTheme.labelSmall.copyWith(
                    color: context.txtTertiary.withValues(alpha: 0.5),
                    fontSize: 10,
                    letterSpacing: 0,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (hasData)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.accentLime,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentLime.withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                if (hasData) const SizedBox(width: 6),
                Text(
                  hasData ? 'Live bilateral symmetry' : 'No signal detected',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySmall.copyWith(
                    color: hasData ? context.txtSecondary : context.txtTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.animatedPosition, required this.hasData});

  final double animatedPosition;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final leftActive = hasData && animatedPosition < 0.45;
    final rightActive = hasData && animatedPosition > 0.55;
    final centerActive = hasData && !leftActive && !rightActive;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _Label(
          text: 'Left',
          active: leftActive,
          activeColor: AppTheme.accentAmber,
          align: TextAlign.start,
        ),
        _Label(
          text: 'Center',
          active: centerActive,
          activeColor: AppTheme.accentTeal,
          align: TextAlign.center,
        ),
        _Label(
          text: 'Right',
          active: rightActive,
          activeColor: AppTheme.accentBlue,
          align: TextAlign.end,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.text,
    required this.active,
    required this.activeColor,
    required this.align,
  });

  final String text;
  final bool active;
  final Color activeColor;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 13,
        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
        color: active
            ? activeColor
            : context.txtTertiary.withValues(alpha: 0.5),
      ),
    );
  }
}

class _GradientLegend extends StatelessWidget {
  const _GradientLegend({this.height = 200});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'High',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 14,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: HeatmapGradient.vertical(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Low',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class SummaryBars extends StatelessWidget {
  const SummaryBars({
    super.key,
    required this.leftValue,
    required this.rightValue,
  });

  final double leftValue;
  final double? rightValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _SummaryBar(
            label: 'Left',
            value: leftValue,
            tint: const Color(0xFF355CFF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryBar(
            label: 'Right',
            value: rightValue ?? 0.12,
            tint: rightValue == null
                ? const Color(0xFFB7BED4)
                : const Color(0xFFFF7A59),
            pending: rightValue == null,
          ),
        ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.label,
    required this.value,
    required this.tint,
    this.pending = false,
  });

  final String label;
  final double value;
  final Color tint;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tint,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            pending ? 'pending' : '${(value * 100).toStringAsFixed(0)}%',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pending ? 0.28 : value.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(tint),
            ),
          ),
        ],
      ),
    );
  }
}
