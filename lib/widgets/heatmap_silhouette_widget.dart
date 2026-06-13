import 'package:flutter/material.dart';

import '../utils/heatmap_utils.dart';

class HeatmapSilhouetteWidget extends StatelessWidget {
  const HeatmapSilhouetteWidget({
    super.key,
    required this.leftActivation,
    required this.rightActivation,
    this.width = 220,
  });

  final double leftActivation;
  final double rightActivation;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Upper back muscle activity heatmap. '
          'Left trapezius ${(leftActivation * 100).round()} percent. '
          'Right trapezius ${(rightActivation * 100).round()} percent.',
      image: true,
      child: Center(
        child: RepaintBoundary(
          child: SizedBox(
            width: width,
            height: width * 1.5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/upper_body.png',
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HeatmapPainter(
                      leftActivation: leftActivation.clamp(0.0, 1.0),
                      rightActivation: rightActivation.clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  const _HeatmapPainter({
    required this.leftActivation,
    required this.rightActivation,
  });

  final double leftActivation;
  final double rightActivation;

  void _drawActivationBlob(
    Canvas canvas,
    Offset centre,
    double activation,
    Size size,
  ) {
    final radius = size.width * 0.18;
    final opacity = (activation * 0.72).clamp(0.0, 0.72);
    final centreColour = HeatmapUtils.activationColour(activation)
        .withValues(alpha: opacity);

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        centreColour,
        centreColour.withValues(alpha: opacity * 0.5),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromCircle(center: centre, radius: radius);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.srcOver;

    canvas.drawCircle(centre, radius, paint);
  }

  void _drawElectrodeDot(Canvas canvas, Offset centre) {
    final dotPaint = Paint()..color = const Color(0xFF2563EB);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(centre, 6, dotPaint);
    canvas.drawCircle(centre, 6, borderPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final leftCentre = Offset(size.width * 0.34, size.height * 0.454);
    final rightCentre = Offset(size.width * 0.66, size.height * 0.454);

    _drawActivationBlob(canvas, leftCentre, leftActivation, size);
    _drawActivationBlob(canvas, rightCentre, rightActivation, size);

    _drawElectrodeDot(canvas, leftCentre);
    _drawElectrodeDot(canvas, rightCentre);
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.leftActivation != leftActivation ||
        oldDelegate.rightActivation != rightActivation;
  }
}
