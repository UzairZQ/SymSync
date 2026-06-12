import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/services/signal_processor.dart';

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
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/leg_silhouette.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _LegActivationPainter(
                  leftActivation: leftActivation,
                  rightActivation: rightActivation,
                ),
              ),
            ],
          ),
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

  Color _heatColor(double value) {
    final clamped = value.clamp(0.0, 1.0);
    return Color.lerp(
      const Color(0xFF355CFF),
      const Color(0xFFFF7A59),
      clamped,
    )!;
  }

  void _drawLegHeatmap(
    Canvas canvas,
    Rect area,
    double activation, {
    required bool active,
  }) {
    const cols = 4;
    const rows = 14;
    final spacingX = area.width / (cols + 1);
    final spacingY = area.height / (rows + 1);
    final dotRadius = (spacingX * 0.35).clamp(2.0, 6.0);

    final base = active ? _heatColor(activation) : const Color(0xFFB7BED4);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = area.left + spacingX * (c + 1);
        final y = area.top + spacingY * (r + 1);

        final vertical = (r / (rows - 1)).clamp(0.0, 1.0);
        final horizontal = (c / (cols - 1) - 0.5).abs() * 2.0;
        final intensity =
            (1.0 - (vertical * 0.6 + horizontal * 0.4)) * (active ? 1.0 : 0.35);

        final color = active
            ? _heatColor(activation * intensity.clamp(0.0, 1.0))
            : base;
        final alpha = active ? (0.30 + intensity.clamp(0.0, 1.0) * 0.70) : 0.25;

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

  @override
  Widget build(BuildContext context) {
    final tiltDegrees = symmetryIndex == null
        ? 0.0
        : (symmetryIndex! / 3.0).clamp(-20.0, 20.0);
    final hasData = symmetryIndex != null;
    final position = (tiltDegrees + 20.0) / 40.0;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.5, end: hasData ? position : 0.5),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedPosition, child) {
        return Column(
          children: <Widget>[
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _TiltMeterPainter(
                  normalizedPosition: animatedPosition,
                  active: hasData,
                ),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasData
                  ? 'Live bilateral symmetry'
                  : 'Connect the second EMG cable to begin bilateral tracking',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF5A6478),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TiltMeterPainter extends CustomPainter {
  _TiltMeterPainter({required this.normalizedPosition, required this.active});

  final double normalizedPosition;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.62);
    final trackRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.78,
      height: 18,
    );
    final trackPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF355CFF),
          Color(0xFF8BC6FF),
          Color(0xFFA7F3D0),
          Color(0xFFFFD166),
          Color(0xFFFF7A59),
        ],
      ).createShader(trackRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, const Radius.circular(999)),
      trackPaint,
    );

    final railPaint = Paint()
      ..color = const Color(0xFF1D2433).withValues(alpha: 0.07);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, 34),
          width: size.width * 0.84,
          height: 4,
        ),
        const Radius.circular(999),
      ),
      railPaint,
    );

    final markerX =
        trackRect.left + (trackRect.width * normalizedPosition.clamp(0.0, 1.0));
    final markerPaint = Paint()
      ..color = active ? const Color(0xFF355CFF) : const Color(0xFFB7BED4);
    canvas.drawCircle(Offset(markerX, trackRect.center.dy), 14, markerPaint);
    canvas.drawCircle(
      Offset(markerX, trackRect.center.dy),
      6,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _TiltMeterPainter oldDelegate) {
    return oldDelegate.normalizedPosition != normalizedPosition ||
        oldDelegate.active != active;
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
