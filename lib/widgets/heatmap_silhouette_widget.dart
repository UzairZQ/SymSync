import 'package:flutter/material.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart';

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
                  height: width * 1.5,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: width * 0.04,
                            horizontal: width * 0.02,
                          ),
                          child: BodyAtlasView<MuscleInfo>(
                            view: AtlasAsset.musclesBack,
                            resolver: const MuscleResolver(),
                            colorMapping: {
                              MuscleCatalog.byIdOrThrow('trapezius_upper_l'):
                                  _atlasColor(left),
                              MuscleCatalog.byIdOrThrow('trapezius_upper_r'):
                                  _atlasColor(right),
                            },
                            hoverColor: (color) =>
                                color.withValues(alpha: 0.60),
                            onTapElement: (_) {},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: width * 0.18),
                _VerticalLegend(height: width * 0.72),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _atlasColor(double activation) {
    if (activation <= 0.01) {
      return Colors.blueGrey.withValues(alpha: 0.30);
    }
    return HeatmapGradient.at(
      activation,
    ).withValues(alpha: 0.48 + activation * 0.44);
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
