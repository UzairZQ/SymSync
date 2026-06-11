import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SymmetryArc extends StatelessWidget {
  const SymmetryArc({super.key, required this.symmetryIndex});

  final double symmetryIndex;

  @override
  Widget build(BuildContext context) {
    final normalized = symmetryIndex.clamp(-1.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: normalized, end: normalized),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return SizedBox(
          height: 180,
          child: CustomPaint(painter: _SymmetryArcPainter(value)),
        );
      },
    );
  }
}

class _SymmetryArcPainter extends CustomPainter {
  _SymmetryArcPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height - strokeWidth / 2);
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = AppTheme.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final leftPaint = Paint()
      ..color = AppTheme.leftTrap
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rightPaint = Paint()
      ..color = AppTheme.rightTrap
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, math.pi, -math.pi, false, backgroundPaint);
    canvas.drawArc(arcRect, math.pi, -math.pi / 2, false, leftPaint);
    canvas.drawArc(arcRect, math.pi / 2, -math.pi / 2, false, rightPaint);

    final positionAngle = math.pi * (1 - (value + 1) / 2);
    final dot = Offset(
      center.dx + radius * math.cos(positionAngle),
      center.dy - radius * math.sin(positionAngle),
    );

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppTheme.accentTeal.withOpacity(0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: dot, radius: 28));

    canvas.drawCircle(dot, 24, glowPaint);
    canvas.drawCircle(
      dot,
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _SymmetryArcPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
