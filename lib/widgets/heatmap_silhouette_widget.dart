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
            height: width * 1.28,
            child: CustomPaint(
              painter: _HeatmapPainter(
                leftActivation: leftActivation.clamp(0.0, 1.0),
                rightActivation: rightActivation.clamp(0.0, 1.0),
              ),
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
    final silhouettePaint = Paint()..color = const Color(0xFFD0D8E8);
    final outlinePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(centerX, size.height * 0.14),
      size.width * 0.105,
      silhouettePaint,
    );

    final torso = Path()
      ..moveTo(centerX - size.width * 0.18, size.height * 0.24)
      ..quadraticBezierTo(
        centerX,
        size.height * 0.19,
        centerX + size.width * 0.18,
        size.height * 0.24,
      )
      ..lineTo(centerX + size.width * 0.25, size.height * 0.72)
      ..quadraticBezierTo(
        centerX,
        size.height * 0.82,
        centerX - size.width * 0.25,
        size.height * 0.72,
      )
      ..close();
    canvas.drawPath(torso, silhouettePaint);
    canvas.drawPath(torso, outlinePaint);

    final leftArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - size.width * 0.38,
        size.height * 0.28,
        size.width * 0.13,
        size.height * 0.42,
      ),
      Radius.circular(size.width * 0.06),
    );
    final rightArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX + size.width * 0.25,
        size.height * 0.28,
        size.width * 0.13,
        size.height * 0.42,
      ),
      Radius.circular(size.width * 0.06),
    );
    canvas.drawRRect(leftArm, silhouettePaint);
    canvas.drawRRect(rightArm, silhouettePaint);

    final leftTrap = Path()
      ..moveTo(centerX - size.width * 0.04, size.height * 0.23)
      ..lineTo(centerX - size.width * 0.23, size.height * 0.31)
      ..quadraticBezierTo(
        centerX - size.width * 0.18,
        size.height * 0.43,
        centerX - size.width * 0.07,
        size.height * 0.47,
      )
      ..quadraticBezierTo(
        centerX - size.width * 0.02,
        size.height * 0.36,
        centerX - size.width * 0.04,
        size.height * 0.23,
      );
    final rightTrap = Path()
      ..moveTo(centerX + size.width * 0.04, size.height * 0.23)
      ..lineTo(centerX + size.width * 0.23, size.height * 0.31)
      ..quadraticBezierTo(
        centerX + size.width * 0.18,
        size.height * 0.43,
        centerX + size.width * 0.07,
        size.height * 0.47,
      )
      ..quadraticBezierTo(
        centerX + size.width * 0.02,
        size.height * 0.36,
        centerX + size.width * 0.04,
        size.height * 0.23,
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
      Offset(centerX, size.height * 0.28),
      Offset(centerX, size.height * 0.70),
      spinePaint,
    );

    final electrodePaint = Paint()..color = const Color(0xFF2563EB);
    canvas.drawCircle(
      Offset(centerX - size.width * 0.14, size.height * 0.34),
      size.width * 0.018,
      electrodePaint,
    );
    canvas.drawCircle(
      Offset(centerX + size.width * 0.14, size.height * 0.34),
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
