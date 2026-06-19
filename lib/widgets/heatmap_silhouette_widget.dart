import 'dart:math' as math;

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

  static const _stops = [
    0.0, 0.09, 0.18, 0.27, 0.36, 0.45, 0.55, 0.64, 0.73, 0.82, 0.91, 1.0,
  ];

  // Visible on dark background: dark blue -> teal -> green -> lime -> gold -> orange -> red
  static const _colors = [
    Color(0xFF1E3A5F),
    Color(0xFF21608C),
    Color(0xFF268AA0),
    Color(0xFF2EAD88),
    Color(0xFF4DC464),
    Color(0xFF81D548),
    Color(0xFFB5CF3C),
    Color(0xFFD9B43C),
    Color(0xFFED9240),
    Color(0xFFF07045),
    Color(0xFFE04A40),
    Color(0xFFC02030),
  ];

  static Color at(double t) {
    t = t.clamp(0.0, 1.0);
    if (t <= 0.0) return _colors.first;
    if (t >= 1.0) return _colors.last;
    for (int i = 0; i < _stops.length - 1; i++) {
      if (t >= _stops[i] && t <= _stops[i + 1]) {
        final frac = (t - _stops[i]) / (_stops[i + 1] - _stops[i]);
        return Color.lerp(_colors[i], _colors[i + 1], frac)!;
      }
    }
    return _colors.last;
  }

  static LinearGradient vertical() => LinearGradient(
    colors: _colors,
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

  // Grid resolution for smooth continuous heatmap (200×300 = 60k cells)
  static const int _gridX = 200;
  static const int _gridY = 300;

  // Gaussian kernel bandwidth as fraction of widget width
  static const double _sigmaRel = 0.045;

  // Virtual electrode spread as fraction of widget dimensions
  static const double _elecSpreadX = 0.040;
  static const double _elecSpreadY = 0.055;

  // Centre positions of left and right trapezius (fractional)
  static const double _leftCX = 0.34;
  static const double _rightCX = 0.66;
  static const double _centreY = 0.38;

  // Heatmap opacity over the silhouette
  static const double _alpha = 0.72;

  // Gaussian cutoff (exp(-4.5) ≈ 0.011)
  static const double _cutoffSigma = 3.0;

  static double _gauss(double dx, double dy, double sigma) {
    return math.exp(-(dx * dx + dy * dy) / (2 * sigma * sigma));
  }

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
    final sigma = size.width * _sigmaRel;
    final cellW = size.width / _gridX;
    final cellH = size.height / _gridY;
    final leftCentre = Offset(size.width * _leftCX, size.height * _centreY);
    final rightCentre = Offset(size.width * _rightCX, size.height * _centreY);
    final elecDx = size.width * _elecSpreadX;
    final elecDy = size.height * _elecSpreadY;

    final leftActive = leftActivation > 0.01;
    final rightActive = rightActivation > 0.01;
    if (!leftActive && !rightActive) return;

    final leftPoints = _electrodeGrid(leftCentre, elecDx, elecDy);
    final rightPoints = _electrodeGrid(rightCentre, elecDx, elecDy);
    final nPoints = leftPoints.length;

    // Compute bounding box in grid coords for each active region
    final marginX = (_cutoffSigma * sigma) / cellW;
    final marginY = (_cutoffSigma * sigma) / cellH;
    final spreadX = elecDx / cellW;
    final spreadY = elecDy / cellH;

    final lcX = leftCentre.dx / cellW;
    final lcY = leftCentre.dy / cellH;
    final rcX = rightCentre.dx / cellW;
    final rcY = rightCentre.dy / cellH;

    final gxLo0 = (lcX - spreadX - marginX).floor().clamp(0, _gridX - 1);
    final gxHi0 = (lcX + spreadX + marginX).ceil().clamp(0, _gridX - 1);
    final gyLo0 = (lcY - spreadY - marginY).floor().clamp(0, _gridY - 1);
    final gyHi0 = (lcY + spreadY + marginY).ceil().clamp(0, _gridY - 1);

    final gxLo1 = (rcX - spreadX - marginX).floor().clamp(0, _gridX - 1);
    final gxHi1 = (rcX + spreadX + marginX).ceil().clamp(0, _gridX - 1);
    final gyLo1 = (rcY - spreadY - marginY).floor().clamp(0, _gridY - 1);
    final gyHi1 = (rcY + spreadY + marginY).ceil().clamp(0, _gridY - 1);

    final paint = Paint()..blendMode = BlendMode.srcOver;

    // Combine both bounding boxes into one vertical span per column
    final gyLoAll = math.min(gyLo0, gyLo1);
    final gyHiAll = math.max(gyHi0, gyHi1);
    final gxLoAll = math.min(gxLo0, gxLo1);
    final gxHiAll = math.max(gxHi0, gxHi1);

    for (int gy = gyLoAll; gy <= gyHiAll; gy++) {
      for (int gx = gxLoAll; gx <= gxHiAll; gx++) {
        final isInLeft = gx >= gxLo0 && gx <= gxHi0 && gy >= gyLo0 && gy <= gyHi0;
        final isInRight = gx >= gxLo1 && gx <= gxHi1 && gy >= gyLo1 && gy <= gyHi1;
        if (!isInLeft && !isInRight) continue;

        final cx = (gx + 0.5) * cellW;
        final cy = (gy + 0.5) * cellH;

        double sum = 0.0;
        if (leftActive && isInLeft) {
          for (final pt in leftPoints) {
            sum += leftActivation * _gauss(cx - pt.dx, cy - pt.dy, sigma);
          }
        }
        if (rightActive && isInRight) {
          for (final pt in rightPoints) {
            sum += rightActivation * _gauss(cx - pt.dx, cy - pt.dy, sigma);
          }
        }

        final intensity = (sum / nPoints).clamp(0.0, 1.0);
        if (intensity < 0.008) continue;

        paint.color = _HeatmapGradient.at(intensity).withValues(alpha: _alpha);
        canvas.drawRect(
          Rect.fromLTWH(gx * cellW, gy * cellH, cellW + 1.0, cellH + 1.0),
          paint,
        );
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
        Text('100%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: txtColor)),
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
                    top: constraints.maxHeight * 0.25 - 5,
                    child: Text('75%', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: txtColor)),
                  ),
                  Positioned(
                    left: 20,
                    top: constraints.maxHeight * 0.50 - 5,
                    child: Text('50%', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: txtColor)),
                  ),
                  Positioned(
                    left: 20,
                    top: constraints.maxHeight * 0.75 - 5,
                    child: Text('25%', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: txtColor)),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 2),
        Text('0%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: txtColor)),
      ],
    );
  }
}
