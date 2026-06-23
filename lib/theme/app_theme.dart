import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTheme {
  // ── DARK THEME COLOURS ──────────────────────────────────────────────────
  static const Color backgroundPrimary = Color(0xFF171916);
  static const Color backgroundCard = Color(0xFF22241F);
  static const Color backgroundElevated = Color(0xFF2C2E2A);
  static const Color textPrimary = Color(0xFFFDF9EC);
  static const Color textSecondary = Color(0xFFC6C7C0);
  static const Color textTertiary = Color(0xFF949590);
  static const Color divider = Color(0xFF3A3D36);

  // ── LIGHT THEME COLOURS ─────────────────────────────────────────────────
  static const Color lightBackgroundPrimary = Color(0xFFFDF9EC);
  static const Color lightBackgroundCard = Color(0xFFFFFFFF);
  static const Color lightBackgroundElevated = Color(0xFFF8F3E6);
  static const Color lightTextPrimary = Color(0xFF171916);
  static const Color lightTextSecondary = Color(0xFF454842);
  static const Color lightTextTertiary = Color(0xFF767872);
  static const Color lightDivider = Color(0xFFE9E2D0);

  // ── ACCENT COLOURS (identical in both themes) ────────────────────────────
  static const Color accentTeal = Color(0xFF5C8F88);
  static const Color accentBlue = Color(0xFF2F80ED);
  static const Color accentAmber = Color(0xFFD99058);
  static const Color accentRed = Color(0xFFBA1A1A);
  static const Color accentGreen = Color(0xFF2E6C00);
  static const Color accentLime = Color(0xFFADF67F);
  static const Color leftTrap = Color(0xFFC56D5D);
  static const Color rightTrap = Color(0xFF8BAEA3);

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
    BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  // ── SPACING ───────────────────────────────────────────────────────────────
  static const double spaceXS = 4.0;
  static const double spaceSM = 6.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 28.0;

  // ── RADII ─────────────────────────────────────────────────────────────────
  static const double radiusSM = 8.0;
  static const double radiusMD = 20.0;
  static const double radiusLG = 28.0;
  static const double radiusXL = 32.0;
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(radiusXL),
  );

  // ── TEXT STYLES ───────────────────────────────────────────────────────────
  static final TextStyle displayHero = GoogleFonts.inter(
    fontSize: 64,
    color: textPrimary,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 36,
    color: textPrimary,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 26,
    color: textPrimary,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle headingLarge = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: textPrimary,
  );
  static final TextStyle headingMedium = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static final TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  static final TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textTertiary,
    letterSpacing: 1.2,
    height: 1.3,
  );
  static final TextStyle monoLarge = GoogleFonts.jetBrainsMono(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    color: accentTeal,
  );
  static final TextStyle monoSmall = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    color: textSecondary,
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
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundCard,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: Color(0x66000000),
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
          (s) =>
              s.contains(WidgetState.selected) ? accentTeal : lightTextTertiary,
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
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackgroundCard,
        foregroundColor: lightTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Color(0x26000000),
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
        fontSize: 64,
        color: primary,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 44,
        color: primary,
        fontWeight: FontWeight.w800,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 32,
        color: primary,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: primary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: secondary,
        letterSpacing: 1.2,
        height: 1.3,
      ),
    ).apply(bodyColor: primary, displayColor: primary);
  }
}

// ── THEME CONTEXT EXTENSION ─────────────────────────────────────────────────
extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgPrimary =>
      isDark ? AppTheme.backgroundPrimary : AppTheme.lightBackgroundPrimary;
  Color get bgCard =>
      isDark ? AppTheme.backgroundCard : AppTheme.lightBackgroundCard;
  Color get bgElevated =>
      isDark ? AppTheme.backgroundElevated : AppTheme.lightBackgroundElevated;
  Color get txtPrimary =>
      isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color get txtSecondary =>
      isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
  Color get txtTertiary =>
      isDark ? AppTheme.textTertiary : AppTheme.lightTextTertiary;
  Color get dividerClr => isDark ? AppTheme.divider : AppTheme.lightDivider;
  List<BoxShadow> get cardShadow =>
      isDark ? AppTheme.cardShadow : AppTheme.lightCardShadow;

  // kept for backward-compat
  Color get accentTeal => AppTheme.accentTeal;
}

// keep old extension name for any file that already imported it
extension AppThemeContextExtension on BuildContext {}
