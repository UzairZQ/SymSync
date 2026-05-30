import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTheme {
  static const Color backgroundPrimary = Color(0xFF080D14);
  static const Color backgroundCard = Color(0xFF0F1923);
  static const Color backgroundElevated = Color(0xFF162030);
  static const Color accentTeal = Color(0xFF00E5CC);
  static const Color accentBlue = Color(0xFF4A9EFF);
  static const Color accentAmber = Color(0xFFFFB340);
  static const Color accentRed = Color(0xFFFF4D6A);
  static const Color accentGreen = Color(0xFF00D68F);
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8A9BB0);
  static const Color textTertiary = Color(0xFF4A5A6B);
  static const Color divider = Color(0xFF1A2738);
  static const Color leftLeg = Color(0xFF4A9EFF);
  static const Color rightLeg = Color(0xFF00E5CC);

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

  static final TextStyle displayHero = GoogleFonts.dmSerifDisplay(
    fontSize: 72,
    color: textPrimary,
    letterSpacing: -2,
  );

  static final TextStyle displayLarge = GoogleFonts.dmSerifDisplay(
    fontSize: 48,
    color: textPrimary,
    letterSpacing: -1,
  );

  static final TextStyle displayMedium = GoogleFonts.dmSerifDisplay(
    fontSize: 32,
    color: textPrimary,
  );

  static final TextStyle headingLarge = GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static final TextStyle headingMedium = GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static final TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static final TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static final TextStyle labelSmall = GoogleFonts.dmSans(
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

  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  static const double radiusSM = 8.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 24.0;
  static const double radiusXL = 32.0;
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(radiusMD),
  );

  static const List<BoxShadow> tealGlow = <BoxShadow>[
    BoxShadow(color: Color(0x4000E5CC), blurRadius: 24, spreadRadius: 0),
  ];

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x30000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static ThemeData themeData() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundPrimary,
      primaryColor: accentTeal,
      cardColor: backgroundCard,
      canvasColor: backgroundPrimary,
      textTheme: TextTheme(
        displayLarge: displayHero,
        displayMedium: displayLarge,
        displaySmall: displayMedium,
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        labelSmall: labelSmall,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      iconTheme: const IconThemeData(color: textPrimary),
      splashColor: accentTeal.withOpacity(0.12),
      highlightColor: Colors.transparent,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: cardRadius),
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
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: Colors.white,
      ).copyWith(surface: backgroundPrimary),
    );
  }
}

extension AppThemeContextExtension on BuildContext {
  Color get bgElevated => AppTheme.backgroundElevated;
  Color get bgCard => AppTheme.backgroundCard;
  Color get txtPrimary => AppTheme.textPrimary;
  Color get txtSecondary => AppTheme.textSecondary;
  Color get txtTertiary => AppTheme.textTertiary;
  Color get dividerClr => AppTheme.divider;
  Color get accentTeal => AppTheme.accentTeal;
}

