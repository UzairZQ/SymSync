import 'package:flutter/material.dart';

class HeatmapUtils {
  static Color activationColour(double activation) {
    final value = activation.clamp(0.0, 1.0);
    if (value < 0.5) {
      return Color.lerp(
        const Color(0xFF2563EB),
        const Color(0xFFF59E0B),
        value / 0.5,
      )!;
    }
    return Color.lerp(
      const Color(0xFFF59E0B),
      const Color(0xFFDC2626),
      (value - 0.5) / 0.5,
    )!;
  }
}
