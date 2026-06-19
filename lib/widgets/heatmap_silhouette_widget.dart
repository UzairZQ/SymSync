import 'package:flutter/material.dart';

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
              const SizedBox(width: 8),
              _VerticalLegend(height: width * 1.5 / 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeatmapGradient {
  _HeatmapGradient._();

  static const Color lightBlue = Color(0xFF5C9CE6);
  static const Color orange = Color(0xFFD99058);
  static const Color red = Color(0xFFBA1A1A);

  static Color at(double t) {
    t = t.clamp(0.0, 1.0);
    if (t < 0.5) return Color.lerp(lightBlue, orange, t / 0.5)!;
    return Color.lerp(orange, red, (t - 0.5) / 0.5)!;
  }

  static LinearGradient vertical() => LinearGradient(
    colors: [lightBlue, orange, red],
    stops: const [0.0, 0.5, 1.0],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}

class _HeatmapPainter extends CustomPainter {
  const _HeatmapPainter({
    required this.leftActivation,
    required this.rightActivation,
  });

  final double leftActivation;
  final double rightActivation;

  static const double _sigmaRel = 0.10;
  static const double _elecSpreadX = 0.035;
  static const double _elecSpreadY = 0.045;
  static const double _leftCX = 0.34;
  static const double _rightCX = 0.66;
  static const double _centreY = 0.38;

  static List<Offset> _electrodeGrid(Offset centre, double dx, double dy) {
    return [
      Offset(centre.dx - dx, centre.dy - dy),
      Offset(centre.dx, centre.dy - dy),
      Offset(centre.dx + dx, centre.dy - dy),
      Offset(centre.dx - dx, centre.dy),
      Offset(centre.dx, centre.dy),
      Offset(centre.dx + dx, centre.dy),
      Offset(centre.dx - dx, centre.dy + dy),
      Offset(centre.dx, centre.dy + dy),
      Offset(centre.dx + dx, centre.dy + dy),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final blurRadius = size.width * _sigmaRel;
    final elecDx = size.width * _elecSpreadX;
    final elecDy = size.height * _elecSpreadY;
    final leftCentre = Offset(size.width * _leftCX, size.height * _centreY);
    final rightCentre = Offset(size.width * _rightCX, size.height * _centreY);

    final leftActive = leftActivation > 0.01;
    final rightActive = rightActivation > 0.01;
    if (!leftActive && !rightActive) return;

    final leftPoints = _electrodeGrid(leftCentre, elecDx, elecDy);
    final rightPoints = _electrodeGrid(rightCentre, elecDx, elecDy);

    final paint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

    if (leftActive) {
      paint.color = _HeatmapGradient.at(leftActivation).withValues(alpha: 0.40);
      for (final pt in leftPoints) {
        canvas.drawCircle(pt, blurRadius * 0.6, paint);
      }
    }
    if (rightActive) {
      paint.color = _HeatmapGradient.at(rightActivation).withValues(alpha: 0.40);
      for (final pt in rightPoints) {
        canvas.drawCircle(pt, blurRadius * 0.6, paint);
      }
    }
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
    final txtColor = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.55);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('High', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: txtColor)),
        const SizedBox(height: 2),
        SizedBox(
          width: 16,
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    width: 16,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: _HeatmapGradient.vertical(),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    top: constraints.maxHeight * 0.50 - 5,
                    child: Text('50%', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: txtColor)),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 2),
        Text('Low', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: txtColor)),
      ],
    );
  }
}
