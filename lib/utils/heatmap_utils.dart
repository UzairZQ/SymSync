import 'package:flutter/material.dart';

class HeatmapGradient {
  static const colors = <Color>[
    Color(0xFF355CFF),
    Color(0xFF8BC6FF),
    Color(0xFFA7F3D0),
    Color(0xFFFFD166),
    Color(0xFFFF7A59),
  ];

  static Color at(double t) {
    t = t.clamp(0.0, 1.0);
    if (t >= 1.0) return colors.last;
    if (t <= 0.0) return colors.first;
    final segment = t * (colors.length - 1);
    final index = segment.floor();
    final frac = segment - index;
    return Color.lerp(colors[index], colors[index + 1], frac)!;
  }

  static LinearGradient horizontal() => LinearGradient(
    colors: colors,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient vertical() => LinearGradient(
    colors: colors,
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  // 3-color heatmap gradient: light blue -> orange -> red
  static const Color lightBlue = Color(0xFF5C9CE6);
  static const Color orange   = Color(0xFFD99058);
  static const Color darkRed  = Color(0xFFBA1A1A);

  static Color at3(double t) {
    t = t.clamp(0.0, 1.0);
    if (t < 0.5) return Color.lerp(lightBlue, orange, t / 0.5)!;
    return Color.lerp(orange, darkRed, (t - 0.5) / 0.5)!;
  }

  static LinearGradient horizontal3() => LinearGradient(
    colors: const [lightBlue, orange, darkRed],
    stops: const [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient vertical3() => LinearGradient(
    colors: const [lightBlue, orange, darkRed],
    stops: const [0.0, 0.5, 1.0],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}

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
