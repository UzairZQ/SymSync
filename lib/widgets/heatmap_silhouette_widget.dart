import 'package:flutter/material.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart';

import '../utils/heatmap_utils.dart';

enum HeatmapDisplayStyle { liveGlow, summaryHeatmap }

class HeatmapSilhouetteWidget extends StatelessWidget {
  const HeatmapSilhouetteWidget({
    super.key,
    required this.leftActivation,
    required this.rightActivation,
    this.width = 220,
    this.style = HeatmapDisplayStyle.liveGlow,
  });

  final double leftActivation;
  final double rightActivation;
  final double width;
  final HeatmapDisplayStyle style;

  @override
  Widget build(BuildContext context) {
    final left = leftActivation.clamp(0.0, 1.0);
    final right = rightActivation.clamp(0.0, 1.0);
    return Semantics(
      label:
          'Upper back muscle atlas. '
          'Left upper trapezius ${(left * 100).round()} percent. '
          'Right upper trapezius ${(right * 100).round()} percent.',
      image: true,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: RepaintBoundary(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: width * 0.10),
                SizedBox(
                  width: width,
                  height: width * 0.96,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            minWidth: width * 1.34,
                            maxWidth: width * 1.34,
                            minHeight: width * 2.02,
                            maxHeight: width * 2.02,
                            child: Transform.translate(
                              offset: Offset(0, -width * 0.10),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: width * 0.04,
                                  horizontal: width * 0.02,
                                ),
                                child: BodyAtlasView<MuscleInfo>(
                                  view: AtlasAsset.musclesBack,
                                  resolver: const MuscleResolver(),
                                  colorMapping: {
                                    MuscleCatalog.byIdOrThrow(
                                      'trapezius_upper_l',
                                    ): _atlasColor(
                                      left,
                                      style,
                                    ),
                                    MuscleCatalog.byIdOrThrow(
                                      'trapezius_upper_r',
                                    ): _atlasColor(
                                      right,
                                      style,
                                    ),
                                  },
                                  hoverColor: (color) =>
                                      color.withValues(alpha: 0.60),
                                  onTapElement: (_) {},
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _UpperTrapHeatmapPainter(
                              leftActivation: left,
                              rightActivation: right,
                              style: style,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: width * 0.18),
                _VerticalLegend(height: width * 0.62),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _atlasColor(double activation, HeatmapDisplayStyle style) {
    if (style == HeatmapDisplayStyle.summaryHeatmap) {
      return Colors.blueGrey.withValues(alpha: 0.24);
    }
    if (activation <= 0.01) {
      return Colors.blueGrey.withValues(alpha: 0.30);
    }
    return HeatmapGradient.at(
      activation,
    ).withValues(alpha: 0.48 + activation * 0.44);
  }
}

class _UpperTrapHeatmapPainter extends CustomPainter {
  const _UpperTrapHeatmapPainter({
    required this.leftActivation,
    required this.rightActivation,
    required this.style,
  });

  final double leftActivation;
  final double rightActivation;
  final HeatmapDisplayStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    _drawUpperTrapHeat(
      canvas,
      size,
      activation: leftActivation,
      neckAnchor: Offset(size.width * 0.46, size.height * 0.22),
      shoulderAnchor: Offset(size.width * 0.34, size.height * 0.38),
      side: -1,
    );
    _drawUpperTrapHeat(
      canvas,
      size,
      activation: rightActivation,
      neckAnchor: Offset(size.width * 0.54, size.height * 0.22),
      shoulderAnchor: Offset(size.width * 0.66, size.height * 0.38),
      side: 1,
    );
  }

  void _drawUpperTrapHeat(
    Canvas canvas,
    Size size, {
    required double activation,
    required Offset neckAnchor,
    required Offset shoulderAnchor,
    required int side,
  }) {
    final value = activation.clamp(0.0, 1.0);
    if (value <= 0.01) return;

    final color = HeatmapGradient.at(value);
    final isSummary = style == HeatmapDisplayStyle.summaryHeatmap;
    final alpha = (isSummary ? 0.30 : 0.16) + value * (isSummary ? 0.42 : 0.24);
    final radius = size.width * ((isSummary ? 0.22 : 0.17) + value * 0.10);

    _drawBlob(
      canvas,
      center: shoulderAnchor,
      radius: radius,
      color: color.withValues(alpha: alpha),
      scaleX: 1.55,
      scaleY: 0.72,
      rotation: side * -0.42,
    );
    _drawBlob(
      canvas,
      center: Offset.lerp(neckAnchor, shoulderAnchor, 0.45)!,
      radius: radius * 0.76,
      color: color.withValues(alpha: alpha * 0.72),
      scaleX: 0.92,
      scaleY: 1.22,
      rotation: side * -0.22,
    );

    if (isSummary) {
      _drawBlob(
        canvas,
        center: neckAnchor,
        radius: radius * 0.56,
        color: color.withValues(alpha: alpha * 0.58),
        scaleX: 0.82,
        scaleY: 1.18,
        rotation: side * -0.14,
      );
    }
  }

  void _drawBlob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double scaleX,
    required double scaleY,
    required double rotation,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color,
          color.withValues(alpha: color.a * 0.42),
          color.withValues(alpha: 0),
        ],
        stops: const <double>[0, 0.48, 1],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(scaleX, scaleY);
    canvas.drawCircle(Offset.zero, radius, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _UpperTrapHeatmapPainter oldDelegate) {
    return oldDelegate.leftActivation != leftActivation ||
        oldDelegate.rightActivation != rightActivation ||
        oldDelegate.style != style;
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
          'MUSCLE\nACTIVITY',
          style: TextStyle(
            fontSize: 7,
            height: 1.15,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w800,
            color: txtColor,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: <Widget>[
            Container(
              width: 10,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
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
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: txtColor,
                    ),
                  ),
                  Text(
                    '50%',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: txtColor,
                    ),
                  ),
                  Text(
                    '0%',
                    style: TextStyle(
                      fontSize: 7,
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
