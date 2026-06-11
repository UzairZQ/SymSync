import 'package:flutter/material.dart';

class HeatmapSilhouetteWidget extends StatelessWidget {
  final double leftActivation;
  final double rightActivation;
  final double width;

  const HeatmapSilhouetteWidget({
    super.key,
    required this.leftActivation,
    required this.rightActivation,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Upper back muscle activity heatmap. "
          "Left trapezius ${(leftActivation * 100).round()} percent. "
          "Right trapezius ${(rightActivation * 100).round()} percent.",
      image: true,
      child: Center(
        child: SizedBox(
          width: width,
          child: Image.asset(
            'assets/images/upper_body.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
