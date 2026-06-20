import 'package:flutter/material.dart';

class HeatmapGradient {
  static const colors = <Color>[
    Color(0xFF2A6F97),
    Color(0xFF61A5C2),
    Color(0xFFF6C85F),
    Color(0xFFF28E2B),
    Color(0xFFC62828),
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

  static Color at3(double t) {
    return at(t);
  }

  static LinearGradient horizontal3() => LinearGradient(
    colors: colors,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient vertical3() => LinearGradient(
    colors: colors,
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}

class BalanceGradient {
  static const Color extreme = Color(0xFFC65D2E);
  static const Color moderate = Color(0xFFE9B44C);
  static const Color balanced = Color(0xFF4F8A78);

  static const colors = <Color>[extreme, moderate, balanced, moderate, extreme];

  static LinearGradient horizontal() => const LinearGradient(
    colors: colors,
    stops: <double>[0.0, 0.25, 0.5, 0.75, 1.0],
  );

  static Color at(double t) {
    final distanceFromCenter = ((t.clamp(0.0, 1.0) - 0.5).abs() * 2.0);
    if (distanceFromCenter < 0.5) {
      return Color.lerp(balanced, moderate, distanceFromCenter / 0.5)!;
    }
    return Color.lerp(moderate, extreme, (distanceFromCenter - 0.5) / 0.5)!;
  }
}

class HeatmapUtils {
  static Color activationColour(double activation) {
    return HeatmapGradient.at(activation);
  }
}
