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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
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
              const SizedBox(width: 4),
              _VerticalLegend(height: width * 1.5 / 2),
            ],
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

  void _drawGlow(Canvas canvas, Offset centre, double activation, Size size) {
    final baseRadius = size.width * 0.13;
    final radius = baseRadius * (0.5 + activation * 0.5);

    if (radius < 2.0) return;

    // Boost sensitivity so mid-range activation reaches orange/red
    final colourT = (activation * 1.4).clamp(0.0, 1.0);
    final glowColour = HeatmapGradient.at(colourT);
    // Fade out when inactive
    final centreAlpha = 0.1 + activation * 0.75;

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        glowColour.withValues(alpha: centreAlpha),
        glowColour.withValues(alpha: centreAlpha * 0.3),
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

  @override
  void paint(Canvas canvas, Size size) {
    final leftCentre = Offset(size.width * 0.34, size.height * 0.38);
    final rightCentre = Offset(size.width * 0.66, size.height * 0.38);

    _drawGlow(canvas, leftCentre, leftActivation, size);
    _drawGlow(canvas, rightCentre, rightActivation, size);
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.leftActivation != leftActivation ||
        oldDelegate.rightActivation != rightActivation;
  }
}

class _VerticalLegend extends StatelessWidget {
  const _VerticalLegend({this.height = 200});

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
