import 'package:flutter/material.dart';

import '../theme/accessibility_provider.dart';

class HeatmapGradient {
  static const colors = <Color>[
    Color(0xFF2A6F97),
    Color(0xFF61A5C2),
    Color(0xFFF6C85F),
    Color(0xFFF28E2B),
    Color(0xFFC62828),
  ];
  static const accessibleColors = <Color>[
    Color(0xFF440154),
    Color(0xFF3B528B),
    Color(0xFF21918C),
    Color(0xFF5EC962),
    Color(0xFFFDE725),
  ];

  static List<Color> get activeColors =>
      AccessibilityProvider.colorBlindMode ? accessibleColors : colors;

  static Color at(double t) {
    t = t.clamp(0.0, 1.0);
    final palette = activeColors;
    if (t >= 1.0) return palette.last;
    if (t <= 0.0) return palette.first;
    final segment = t * (palette.length - 1);
    final index = segment.floor();
    final frac = segment - index;
    return Color.lerp(palette[index], palette[index + 1], frac)!;
  }

  static LinearGradient horizontal() => LinearGradient(
    colors: activeColors,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient vertical() => LinearGradient(
    colors: activeColors,
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static Color at3(double t) {
    return at(t);
  }

  static LinearGradient horizontal3() => LinearGradient(
    colors: activeColors,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient vertical3() => LinearGradient(
    colors: activeColors,
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}

class BalanceGradient {
  static const Color extreme = Color(0xFFC65D2E);
  static const Color moderate = Color(0xFFE9B44C);
  static const Color balanced = Color(0xFF4F8A78);

  static const colors = <Color>[extreme, moderate, balanced, moderate, extreme];
  static const accessibleColors = <Color>[
    Color(0xFF0072B2),
    Color(0xFF56B4E9),
    Color(0xFF009E73),
    Color(0xFFE69F00),
    Color(0xFFD55E00),
  ];

  static List<Color> get activeColors =>
      AccessibilityProvider.colorBlindMode ? accessibleColors : colors;

  static LinearGradient horizontal() => LinearGradient(
    colors: activeColors,
    stops: <double>[0.0, 0.25, 0.5, 0.75, 1.0],
  );

  static Color at(double t) {
    if (AccessibilityProvider.colorBlindMode) {
      final value = t.clamp(0.0, 1.0);
      final segment = value * (accessibleColors.length - 1);
      final index = segment.floor().clamp(0, accessibleColors.length - 2);
      return Color.lerp(
        accessibleColors[index],
        accessibleColors[index + 1],
        segment - index,
      )!;
    }
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
