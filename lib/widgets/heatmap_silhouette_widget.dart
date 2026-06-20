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
        child: FittedBox(
          fit: BoxFit.contain,
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
                          'assets/images/upper_body_clinical.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
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
                const SizedBox(width: 12),
                _VerticalLegend(height: width * 0.86),
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

  static const double _leftCX = 0.36;
  static const double _rightCX = 0.64;
  static const double _centreY = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    final leftCentre = Offset(size.width * _leftCX, size.height * _centreY);
    final rightCentre = Offset(size.width * _rightCX, size.height * _centreY);

    _drawActivation(canvas, size, leftCentre, leftActivation);
    _drawActivation(canvas, size, rightCentre, rightActivation);
  }

  void _drawActivation(
    Canvas canvas,
    Size size,
    Offset centre,
    double activation,
  ) {
    if (activation <= 0.01) return;
    final radius = size.width * (0.13 + activation * 0.09);
    final color = HeatmapGradient.at(activation);
    final heatPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: 0.70),
          color.withValues(alpha: 0.30),
          color.withValues(alpha: 0.0),
        ],
        stops: const <double>[0.0, 0.52, 1.0],
      ).createShader(Rect.fromCircle(center: centre, radius: radius));
    canvas.drawCircle(centre, radius, heatPaint);

    final markerPaint = Paint()..color = color;
    canvas.drawCircle(centre, size.width * 0.023, markerPaint);
    final markerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.008
      ..color = Colors.white.withValues(alpha: 0.95);
    canvas.drawCircle(centre, size.width * 0.029, markerRing);
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
    final txtColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'RELATIVE\nACTIVATION',
          style: TextStyle(
            fontSize: 8,
            height: 1.15,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w800,
            color: txtColor,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Container(
              width: 14,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: txtColor.withValues(alpha: 0.22),
                  width: 0.8,
                ),
                gradient: HeatmapGradient.vertical(),
              ),
            ),
            const SizedBox(width: 5),
            SizedBox(
              height: height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '100%',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: txtColor,
                    ),
                  ),
                  Text(
                    '50%',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: txtColor,
                    ),
                  ),
                  Text(
                    '0%',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: txtColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
