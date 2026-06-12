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

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final leftTrap = Path()
      ..moveTo(centerX - size.width * 0.04, size.height * 0.18)
      ..lineTo(centerX - size.width * 0.26, size.height * 0.27)
      ..quadraticBezierTo(
        centerX - size.width * 0.22,
        size.height * 0.42,
        centerX - size.width * 0.08,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        centerX - size.width * 0.03,
        size.height * 0.36,
        centerX - size.width * 0.04,
        size.height * 0.18,
      );

    final rightTrap = Path()
      ..moveTo(centerX + size.width * 0.04, size.height * 0.18)
      ..lineTo(centerX + size.width * 0.26, size.height * 0.27)
      ..quadraticBezierTo(
        centerX + size.width * 0.22,
        size.height * 0.42,
        centerX + size.width * 0.08,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        centerX + size.width * 0.03,
        size.height * 0.36,
        centerX + size.width * 0.04,
        size.height * 0.18,
      );

    canvas.drawPath(
      leftTrap,
      Paint()
        ..color = HeatmapUtils.activationColour(
          leftActivation,
        ).withValues(alpha: 0.38 + leftActivation * 0.58),
    );
    canvas.drawPath(
      rightTrap,
      Paint()
        ..color = HeatmapUtils.activationColour(
          rightActivation,
        ).withValues(alpha: 0.38 + rightActivation * 0.58),
    );

    final spinePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX, size.height * 0.22),
      Offset(centerX, size.height * 0.60),
      spinePaint,
    );

    final electrodePaint = Paint()..color = const Color(0xFF2563EB);
    canvas.drawCircle(
      Offset(centerX - size.width * 0.15, size.height * 0.34),
      size.width * 0.018,
      electrodePaint,
    );
    canvas.drawCircle(
      Offset(centerX + size.width * 0.15, size.height * 0.34),
      size.width * 0.018,
      electrodePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.leftActivation != leftActivation ||
        oldDelegate.rightActivation != rightActivation;
  }
}
