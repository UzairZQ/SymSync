import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTheme {
  // ── DARK THEME COLOURS ──────────────────────────────────────────────────
  static const Color backgroundPrimary  = Color(0xFF080D14);
  static const Color backgroundCard     = Color(0xFF0F1923);
  static const Color backgroundElevated = Color(0xFF162030);
  static const Color textPrimary        = Color(0xFFF0F4FF);
  static const Color textSecondary      = Color(0xFF8A9BB0);
  static const Color textTertiary       = Color(0xFF4A5A6B);
  static const Color divider            = Color(0xFF1A2738);

  // ── LIGHT THEME COLOURS ─────────────────────────────────────────────────
  static const Color lightBackgroundPrimary  = Color(0xFFF5F7FA);
  static const Color lightBackgroundCard     = Color(0xFFFFFFFF);
  static const Color lightBackgroundElevated = Color(0xFFEEF2F7);
  static const Color lightTextPrimary        = Color(0xFF0D1B2A);
  static const Color lightTextSecondary      = Color(0xFF4A5A6B);
  static const Color lightTextTertiary       = Color(0xFF9AAABB);
  static const Color lightDivider            = Color(0xFFDDE3EA);

  // ── ACCENT COLOURS (identical in both themes) ────────────────────────────
  static const Color accentTeal  = Color(0xFF00E5CC);
  static const Color accentBlue  = Color(0xFF4A9EFF);
  static const Color accentAmber = Color(0xFFFFB340);
  static const Color accentRed   = Color(0xFFFF4D6A);
  static const Color accentGreen = Color(0xFF00D68F);
  static const Color leftLeg     = Color(0xFF4A9EFF);
  static const Color rightLeg    = Color(0xFF00E5CC);

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF00E5CC), Color(0xFF4A9EFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFFB340), Color(0xFFFF4D6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── SHADOWS ──────────────────────────────────────────────────────────────
  static const List<BoxShadow> tealGlow = <BoxShadow>[
    BoxShadow(color: Color(0x4000E5CC), blurRadius: 24, spreadRadius: 0),
  ];
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x30000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> lightCardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 4,  offset: Offset(0, 1)),
  ];

  // ── SPACING ───────────────────────────────────────────────────────────────
  static const double spaceXS  = 4.0;
  static const double spaceSM  = 8.0;
  static const double spaceMD  = 16.0;
  static const double spaceLG  = 24.0;
  static const double spaceXL  = 32.0;
  static const double spaceXXL = 48.0;

  // ── RADII ─────────────────────────────────────────────────────────────────
  static const double radiusSM = 8.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 24.0;
  static const double radiusXL = 32.0;
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(radiusMD));

  // ── TEXT STYLES ───────────────────────────────────────────────────────────
  static final TextStyle displayHero = GoogleFonts.dmSerifDisplay(
    fontSize: 72, color: textPrimary, letterSpacing: -2,
  );
  static final TextStyle displayLarge = GoogleFonts.dmSerifDisplay(
    fontSize: 48, color: textPrimary, letterSpacing: -1,
  );
  static final TextStyle displayMedium = GoogleFonts.dmSerifDisplay(
    fontSize: 32, color: textPrimary,
  );
  static final TextStyle headingLarge = GoogleFonts.dmSans(
    fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3,
  );
  static final TextStyle headingMedium = GoogleFonts.dmSans(
    fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
  );
  static final TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 16, fontWeight: FontWeight.w400, color: textSecondary,
  );
  static final TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary,
  );
  static final TextStyle labelSmall = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w600, color: textTertiary,
    letterSpacing: 1.2, height: 1.3,
  );
  static final TextStyle monoLarge = GoogleFonts.jetBrainsMono(
    fontSize: 28, fontWeight: FontWeight.w500, color: accentTeal,
  );
  static final TextStyle monoSmall = GoogleFonts.jetBrainsMono(
    fontSize: 13, color: textSecondary,
  );

  // ── THEME DATA ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundPrimary,
      primaryColor: accentTeal,
      cardColor: backgroundCard,
      canvasColor: backgroundPrimary,
      textTheme: _buildTextTheme(textPrimary, textSecondary),
      iconTheme: const IconThemeData(color: textPrimary),
      splashColor: accentTeal.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: cardRadius),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accentTeal : textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accentTeal.withValues(alpha: 0.4)
              : backgroundElevated,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundCard,
        selectedItemColor: accentTeal,
        unselectedItemColor: textTertiary,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        surface: backgroundCard,
        primary: accentTeal,
        secondary: accentBlue,
        error: accentRed,
        onPrimary: Colors.white,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: Colors.white,
      ).copyWith(surface: backgroundPrimary),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackgroundPrimary,
      primaryColor: accentTeal,
      cardColor: lightBackgroundCard,
      canvasColor: lightBackgroundPrimary,
      textTheme: _buildTextTheme(lightTextPrimary, lightTextSecondary),
      iconTheme: const IconThemeData(color: lightTextPrimary),
      splashColor: accentTeal.withValues(alpha: 0.10),
      highlightColor: Colors.transparent,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: cardRadius),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accentTeal : lightTextTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accentTeal.withValues(alpha: 0.4)
              : lightBackgroundElevated,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightBackgroundCard,
        selectedItemColor: accentTeal,
        unselectedItemColor: lightTextTertiary,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.light(
        surface: lightBackgroundCard,
        primary: accentTeal,
        secondary: accentBlue,
        error: accentRed,
        onPrimary: Colors.white,
        onSecondary: lightTextPrimary,
        onSurface: lightTextPrimary,
        onError: Colors.white,
      ).copyWith(surface: lightBackgroundPrimary),
      dividerColor: lightDivider,
      dividerTheme: const DividerThemeData(color: lightDivider, thickness: 1),
    );
  }

  // Keep old themeData() as a delegate so existing code still compiles
  static ThemeData themeData() => darkTheme;

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.dmSerifDisplay(
        fontSize: 72, color: primary, letterSpacing: -2,
      ),
      displayMedium: GoogleFonts.dmSerifDisplay(
        fontSize: 48, color: primary, letterSpacing: -1,
      ),
      displaySmall: GoogleFonts.dmSerifDisplay(
        fontSize: 32, color: primary,
      ),
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 22, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 18, fontWeight: FontWeight.w600, color: primary,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 20, fontWeight: FontWeight.w700, color: primary,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 18, fontWeight: FontWeight.w700, color: primary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w600, color: primary,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w400, color: secondary,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w400, color: secondary,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w400, color: secondary,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w700, color: primary,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11, fontWeight: FontWeight.w600, color: secondary,
        letterSpacing: 1.2, height: 1.3,
      ),
    ).apply(bodyColor: primary, displayColor: primary);
  }
}

// ── THEME CONTEXT EXTENSION ─────────────────────────────────────────────────
extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgPrimary    => isDark ? AppTheme.backgroundPrimary   : AppTheme.lightBackgroundPrimary;
  Color get bgCard       => isDark ? AppTheme.backgroundCard      : AppTheme.lightBackgroundCard;
  Color get bgElevated   => isDark ? AppTheme.backgroundElevated  : AppTheme.lightBackgroundElevated;
  Color get txtPrimary   => isDark ? AppTheme.textPrimary         : AppTheme.lightTextPrimary;
  Color get txtSecondary => isDark ? AppTheme.textSecondary       : AppTheme.lightTextSecondary;
  Color get txtTertiary  => isDark ? AppTheme.textTertiary        : AppTheme.lightTextTertiary;
  Color get dividerClr   => isDark ? AppTheme.divider             : AppTheme.lightDivider;
  List<BoxShadow> get cardShadow => isDark ? AppTheme.cardShadow  : AppTheme.lightCardShadow;

  // kept for backward-compat
  Color get accentTeal   => AppTheme.accentTeal;
}
// keep old extension name for any file that already imported it
extension AppThemeContextExtension on BuildContext {}
