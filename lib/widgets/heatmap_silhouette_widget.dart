import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/heatmap_utils.dart';

class HeatmapSilhouetteWidget extends StatelessWidget {
  /// Normalised RMS amplitude for the left trapezius [0.0–1.0].
  final double leftActivation;

  /// Normalised RMS amplitude for the right trapezius [0.0–1.0].
  final double rightActivation;

  /// Width of the rendered widget. Height is derived at 1.3× aspect ratio.
  final double width;

  const HeatmapSilhouetteWidget({
    super.key,
    required this.leftActivation,
    required this.rightActivation,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 1.3;

    return Semantics(
      label: "Upper back muscle activity heatmap. "
          "Left trapezius ${(leftActivation * 100).round()} percent. "
          "Right trapezius ${(rightActivation * 100).round()} percent.",
      image: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      'assets/images/upper_body_silhouette.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HeatmapPainter(
                        leftActivation: leftActivation,
                        rightActivation: rightActivation,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4E9AF1),
                  Color(0xFFF59E0B),
                  Color(0xFFEF4444),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Low",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                "Moderate",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                "High",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final double leftActivation;
  final double rightActivation;

  _HeatmapPainter({
    required this.leftActivation,
    required this.rightActivation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200.0;
    final matrix = Matrix4.identity()..scale(scale);
    final storage = matrix.storage;

    // Fills
    final leftColor = HeatmapUtils.activationColour(leftActivation).withOpacity(0.65);
    final rightColor = HeatmapUtils.activationColour(rightActivation).withOpacity(0.65);

    final leftPaint = Paint()..color = leftColor..style = PaintingStyle.fill;
    final rightPaint = Paint()..color = rightColor..style = PaintingStyle.fill;

    // Outlines
    final outlinePaint = Paint()
      ..color = const Color(0xFF8899BB)
      ..strokeWidth = 0.8 * scale
      ..style = PaintingStyle.stroke;

    // Region 1: left_trapezius_upper
    final pathLeftTrapUpper = (Path()
      ..moveTo(100, 60)
      ..lineTo(92, 60)
      ..lineTo(92, 70)
      ..cubicTo(85, 73, 78, 78, 75, 84)
      ..lineTo(100, 80)
      ..close()).transform(storage);
    canvas.drawPath(pathLeftTrapUpper, leftPaint);
    canvas.drawPath(pathLeftTrapUpper, outlinePaint);

    // Region 2: right_trapezius_upper
    final pathRightTrapUpper = (Path()
      ..moveTo(100, 60)
      ..lineTo(108, 60)
      ..lineTo(108, 70)
      ..cubicTo(115, 73, 122, 78, 125, 84)
      ..lineTo(100, 80)
      ..close()).transform(storage);
    canvas.drawPath(pathRightTrapUpper, rightPaint);
    canvas.drawPath(pathRightTrapUpper, outlinePaint);

    // Region 3: left_trapezius_mid
    final pathLeftTrapMid = (Path()
      ..moveTo(100, 80)
      ..lineTo(75, 84)
      ..cubicTo(76, 92, 76, 98, 77, 105)
      ..lineTo(100, 115)
      ..close()).transform(storage);
    canvas.drawPath(pathLeftTrapMid, leftPaint);
    canvas.drawPath(pathLeftTrapMid, outlinePaint);

    // Region 4: right_trapezius_mid
    final pathRightTrapMid = (Path()
      ..moveTo(100, 80)
      ..lineTo(125, 84)
      ..cubicTo(124, 92, 124, 98, 123, 105)
      ..lineTo(100, 115)
      ..close()).transform(storage);
    canvas.drawPath(pathRightTrapMid, rightPaint);
    canvas.drawPath(pathRightTrapMid, outlinePaint);

    // Region 5: left_deltoid
    final pathLeftDeltoid = (Path()
      ..moveTo(75, 84)
      ..cubicTo(65, 86, 55, 100, 48, 125)
      ..cubicTo(56, 128, 62, 126, 68, 118)
      ..cubicTo(72, 108, 74, 98, 75, 84)
      ..close()).transform(storage);
    canvas.drawPath(pathLeftDeltoid, leftPaint);
    canvas.drawPath(pathLeftDeltoid, outlinePaint);

    // Region 6: right_deltoid
    final pathRightDeltoid = (Path()
      ..moveTo(125, 84)
      ..cubicTo(135, 86, 145, 100, 152, 125)
      ..cubicTo(144, 128, 138, 126, 132, 118)
      ..cubicTo(128, 108, 126, 98, 125, 84)
      ..close()).transform(storage);
    canvas.drawPath(pathRightDeltoid, rightPaint);
    canvas.drawPath(pathRightDeltoid, outlinePaint);

    // Region 7: left_lat
    final pathLeftLat = (Path()
      ..moveTo(100, 115)
      ..lineTo(68, 118)
      ..cubicTo(70, 145, 74, 185, 80, 220)
      ..lineTo(100, 220)
      ..close()).transform(storage);
    canvas.drawPath(pathLeftLat, leftPaint);
    canvas.drawPath(pathLeftLat, outlinePaint);

    // Region 8: right_lat
    final pathRightLat = (Path()
      ..moveTo(100, 115)
      ..lineTo(132, 118)
      ..cubicTo(130, 145, 126, 185, 120, 220)
      ..lineTo(100, 220)
      ..close()).transform(storage);
    canvas.drawPath(pathRightLat, rightPaint);
    canvas.drawPath(pathRightLat, outlinePaint);

    // Electrode markers: cx=92/108, cy=75
    final electrodePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    final electrodeBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5 * scale
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(92 * scale, 75 * scale), 5 * scale, electrodePaint);
    canvas.drawCircle(Offset(92 * scale, 75 * scale), 5 * scale, electrodeBorderPaint);

    canvas.drawCircle(Offset(108 * scale, 75 * scale), 5 * scale, electrodePaint);
    canvas.drawCircle(Offset(108 * scale, 75 * scale), 5 * scale, electrodeBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return leftActivation != oldDelegate.leftActivation ||
        rightActivation != oldDelegate.rightActivation;
  }
}
