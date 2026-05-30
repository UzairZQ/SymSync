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
    this.leftLabel = 'Left leg',
    this.rightLabel = 'Right leg',
  });

  final double leftActivation;
  final double? rightActivation;
  final String leftLabel;
  final String rightLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _LegPairPainter(
            leftActivation: leftActivation,
            rightActivation: rightActivation,
          ),
        );
      },
    );
  }
}

class _LegPairPainter extends CustomPainter {
  _LegPairPainter({
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

  void _drawLeg(
    Canvas canvas,
    Rect thigh,
    Rect calf,
    double activation, {
    bool active = true,
  }) {
    final color = active ? _heatColor(activation) : const Color(0xFFB7BED4);
    final thighPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          color.withValues(alpha: active ? 0.95 : 0.45),
          color.withValues(alpha: active ? 0.70 : 0.25),
        ],
      ).createShader(thigh);
    final calfPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          color.withValues(alpha: active ? 0.88 : 0.42),
          color.withValues(alpha: active ? 0.55 : 0.20),
        ],
      ).createShader(calf);
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF1D2433).withValues(alpha: 0.08);

    canvas.drawRRect(
      RRect.fromRectAndRadius(thigh, const Radius.circular(26)),
      thighPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(thigh, const Radius.circular(26)),
      edgePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(calf, const Radius.circular(22)),
      calfPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(calf, const Radius.circular(22)),
      edgePaint,
    );

    final jointPaint = Paint()
      ..color = color.withValues(alpha: active ? 0.55 : 0.2);
    canvas.drawCircle(Offset(thigh.center.dx, thigh.bottom - 6), 8, jointPaint);
    canvas.drawCircle(Offset(calf.center.dx, calf.top + 6), 7, jointPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pelvisPaint = Paint()
      ..color = const Color(0xFF1D2433).withValues(alpha: 0.07);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.16),
          width: size.width * 0.34,
          height: size.height * 0.08,
        ),
        const Radius.circular(18),
      ),
      pelvisPaint,
    );

    final leftThigh = Rect.fromCenter(
      center: Offset(size.width * 0.38, size.height * 0.40),
      width: size.width * 0.13,
      height: size.height * 0.36,
    );
    final leftCalf = Rect.fromCenter(
      center: Offset(size.width * 0.38, size.height * 0.74),
      width: size.width * 0.11,
      height: size.height * 0.34,
    );
    final rightThigh = Rect.fromCenter(
      center: Offset(size.width * 0.62, size.height * 0.40),
      width: size.width * 0.13,
      height: size.height * 0.36,
    );
    final rightCalf = Rect.fromCenter(
      center: Offset(size.width * 0.62, size.height * 0.74),
      width: size.width * 0.11,
      height: size.height * 0.34,
    );

    _drawLeg(canvas, leftThigh, leftCalf, leftActivation);
    _drawLeg(
      canvas,
      rightThigh,
      rightCalf,
      rightActivation ?? 0.12,
      active: rightActivation != null,
    );

    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF355CFF).withValues(alpha: 0.08);
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.10),
      Offset(size.width / 2, size.height * 0.98),
      guidePaint,
    );

    final footPaint = Paint()
      ..color = const Color(0xFF1D2433).withValues(alpha: 0.08);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.38, size.height * 0.99),
        width: size.width * 0.16,
        height: size.height * 0.05,
      ),
      footPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, size.height * 0.99),
        width: size.width * 0.16,
        height: size.height * 0.05,
      ),
      footPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LegPairPainter oldDelegate) {
    return oldDelegate.leftActivation != leftActivation ||
        oldDelegate.rightActivation != rightActivation;
  }
}

class TiltMeter extends StatelessWidget {
  const TiltMeter({super.key, required this.symmetryIndex});

  final double? symmetryIndex;

  @override
  Widget build(BuildContext context) {
    final tiltDegrees = symmetryIndex == null
        ? 0.0
        : (symmetryIndex! / 3.0).clamp(-20.0, 20.0);
    final hasData = symmetryIndex != null;
    final position = (tiltDegrees + 20.0) / 40.0;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 180,
          child: CustomPaint(
            painter: _TiltMeterPainter(
              normalizedPosition: hasData ? position : 0.5,
              active: hasData,
            ),
            child: Center(
              child: Text(
                hasData ? '${tiltDegrees.toStringAsFixed(0)}°' : '—',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasData
              ? 'tilt from bilateral symmetry'
              : 'awaiting second leg channel',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF5A6478),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
