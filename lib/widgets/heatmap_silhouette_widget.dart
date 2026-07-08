import 'package:flutter/material.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart';

import '../domain/models/target_muscle.dart';
import '../utils/heatmap_utils.dart';

enum HeatmapDisplayStyle { liveGlow, summaryHeatmap }

class HeatmapSilhouetteWidget extends StatelessWidget {
  const HeatmapSilhouetteWidget({
    super.key,
    required this.leftActivation,
    required this.rightActivation,
    this.width = 220,
    this.style = HeatmapDisplayStyle.liveGlow,
    this.targetMuscle = TargetMuscle.trapezius,
  });

  final double leftActivation;
  final double rightActivation;
  final double width;
  final HeatmapDisplayStyle style;
  final TargetMuscle targetMuscle;

  @override
  Widget build(BuildContext context) {
    final left = leftActivation.clamp(0.0, 1.0);
    final right = rightActivation.clamp(0.0, 1.0);
    final isBiceps = targetMuscle == TargetMuscle.biceps;
    return Semantics(
      label: _semanticLabel(left, right),
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
                  height: width * (isBiceps ? 1.04 : 0.96),
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            minWidth: width * (isBiceps ? 1.42 : 1.34),
                            maxWidth: width * (isBiceps ? 1.42 : 1.34),
                            minHeight: width * 2.02,
                            maxHeight: width * 2.02,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                -width * (isBiceps ? 0.06 : 0.10),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: width * 0.04,
                                  horizontal: width * 0.02,
                                ),
                                child: BodyAtlasView<MuscleInfo>(
                                  view: isBiceps
                                      ? AtlasAsset.musclesFront
                                      : AtlasAsset.musclesBack,
                                  resolver: const MuscleResolver(),
                                  colorMapping: _atlasMapping(
                                    left: left,
                                    right: right,
                                    style: style,
                                    targetMuscle: targetMuscle,
                                  ),
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
                            painter: _TargetMuscleHeatmapPainter(
                              leftActivation: left,
                              rightActivation: right,
                              style: style,
                              targetMuscle: targetMuscle,
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

  String _semanticLabel(double left, double right) {
    return switch (targetMuscle) {
      TargetMuscle.trapezius =>
        'Upper back muscle atlas. '
            'Left upper trapezius ${(left * 100).round()} percent. '
            'Right upper trapezius ${(right * 100).round()} percent.',
      TargetMuscle.biceps =>
        'Front arm muscle atlas. '
            'Left biceps ${(left * 100).round()} percent. '
            'Right biceps ${(right * 100).round()} percent.',
    };
  }

  static Map<MuscleInfo, Color> _atlasMapping({
    required double left,
    required double right,
    required HeatmapDisplayStyle style,
    required TargetMuscle targetMuscle,
  }) {
    final leftColor = _atlasColor(left, style);
    final rightColor = _atlasColor(right, style);
    return switch (targetMuscle) {
      TargetMuscle.trapezius => <MuscleInfo, Color>{
        MuscleCatalog.byIdOrThrow('trapezius_upper_l'): leftColor,
        MuscleCatalog.byIdOrThrow('trapezius_upper_r'): rightColor,
      },
      TargetMuscle.biceps => <MuscleInfo, Color>{
        MuscleCatalog.byIdOrThrow('biceps_brachii_caput_breve_l'): leftColor,
        MuscleCatalog.byIdOrThrow('biceps_brachii_caput_longum_l'): leftColor,
        MuscleCatalog.byIdOrThrow('biceps_brachii_caput_breve_r'): rightColor,
        MuscleCatalog.byIdOrThrow('biceps_brachii_caput_longum_r'): rightColor,
      },
    };
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

class _TargetMuscleHeatmapPainter extends CustomPainter {
  const _TargetMuscleHeatmapPainter({
    required this.leftActivation,
    required this.rightActivation,
    required this.style,
    required this.targetMuscle,
  });

  final double leftActivation;
  final double rightActivation;
  final HeatmapDisplayStyle style;
  final TargetMuscle targetMuscle;

  @override
  void paint(Canvas canvas, Size size) {
    if (targetMuscle == TargetMuscle.biceps) {
      _drawBicepsHeat(
        canvas,
        size,
        activation: leftActivation,
        center: Offset(size.width * 0.28, size.height * 0.39),
        side: -1,
      );
      _drawBicepsHeat(
        canvas,
        size,
        activation: rightActivation,
        center: Offset(size.width * 0.72, size.height * 0.39),
        side: 1,
      );
      return;
    }

    _drawUpperTrapHeat(
      canvas,
      size,
      activation: leftActivation,
      neckAnchor: Offset(size.width * 0.46, size.height * 0.20),
      shoulderAnchor: Offset(size.width * 0.36, size.height * 0.32),
      side: -1,
    );
    _drawUpperTrapHeat(
      canvas,
      size,
      activation: rightActivation,
      neckAnchor: Offset(size.width * 0.54, size.height * 0.20),
      shoulderAnchor: Offset(size.width * 0.64, size.height * 0.32),
      side: 1,
    );
  }

  void _drawBicepsHeat(
    Canvas canvas,
    Size size, {
    required double activation,
    required Offset center,
    required int side,
  }) {
    final value = activation.clamp(0.0, 1.0);
    if (value <= 0.01) return;

    final color = HeatmapGradient.at(value);
    final isSummary = style == HeatmapDisplayStyle.summaryHeatmap;
    final visualValue = value < 0.08 ? value * 0.65 : value;
    final alpha =
        (isSummary ? 0.34 : 0.18) + visualValue * (isSummary ? 0.40 : 0.22);
    final radius =
        size.width * ((isSummary ? 0.13 : 0.10) + visualValue * 0.06);

    _drawBlob(
      canvas,
      center: center,
      radius: radius,
      color: color.withValues(alpha: alpha),
      scaleX: isSummary ? 0.62 : 0.54,
      scaleY: isSummary ? 1.22 : 1.10,
      rotation: side * -0.12,
    );
    _drawBlob(
      canvas,
      center: center.translate(side * size.width * 0.025, size.height * 0.04),
      radius: radius * 0.72,
      color: color.withValues(alpha: alpha * 0.60),
      scaleX: 0.46,
      scaleY: 0.95,
      rotation: side * -0.10,
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
    final visualValue = value < 0.08 ? value * 0.65 : value;
    final alpha =
        (isSummary ? 0.34 : 0.18) + visualValue * (isSummary ? 0.40 : 0.22);
    final radius =
        size.width * ((isSummary ? 0.14 : 0.11) + visualValue * 0.07);

    _drawBlob(
      canvas,
      center: shoulderAnchor,
      radius: radius,
      color: color.withValues(alpha: alpha),
      scaleX: isSummary ? 1.22 : 1.10,
      scaleY: isSummary ? 0.58 : 0.52,
      rotation: side * -0.48,
    );
    _drawBlob(
      canvas,
      center: Offset.lerp(neckAnchor, shoulderAnchor, 0.45)!,
      radius: radius * 0.68,
      color: color.withValues(alpha: alpha * 0.68),
      scaleX: 0.72,
      scaleY: 1.05,
      rotation: side * -0.24,
    );

    if (isSummary) {
      _drawBlob(
        canvas,
        center: neckAnchor,
        radius: radius * 0.45,
        color: color.withValues(alpha: alpha * 0.46),
        scaleX: 0.62,
        scaleY: 0.92,
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
  bool shouldRepaint(covariant _TargetMuscleHeatmapPainter oldDelegate) {
    return oldDelegate.leftActivation != leftActivation ||
        oldDelegate.rightActivation != rightActivation ||
        oldDelegate.style != style ||
        oldDelegate.targetMuscle != targetMuscle;
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
