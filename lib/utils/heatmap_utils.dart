import 'dart:ui';

class HeatmapUtils {
  /// Maps a normalised activation value [0.0–1.0] to an ARGB colour.
  static Color activationColour(double normalised) {
    final t = normalised.clamp(0.0, 1.0);
    if (t < 0.25) {
      // blue → amber
      return Color.lerp(
        const Color(0xFF4E9AF1),
        const Color(0xFFF59E0B),
        t / 0.25,
      )!;
    } else {
      // amber → red
      return Color.lerp(
        const Color(0xFFF59E0B),
        const Color(0xFFEF4444),
        (t - 0.25) / 0.75,
      )!;
    }
  }

  /// Maps a symmetry index [-100, +100] to [0.0–1.0] for the imbalance side.
  /// Positive SI = right dominant, negative = left dominant.
  static double symmetryToNormalised(double si) => (si.abs() / 100.0).clamp(0.0, 1.0);
}
