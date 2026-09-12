import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'duwa_colors.dart';

class DuwaThemeData {
  final DuwaThemeVibe vibe;
  final Color background;
  final Color surfaceLowest;
  final Color surfaceLow;
  final Color surface;
  final Color surfaceLight;
  final Color surfaceHighest;
  final Color cardBorder;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color highlight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final LinearGradient primaryGradient;
  final LinearGradient heroCardGradient;
  final LinearGradient accentGradient;

  const DuwaThemeData({
    required this.vibe,
    required this.background,
    required this.surfaceLowest,
    required this.surfaceLow,
    required this.surface,
    required this.surfaceLight,
    required this.surfaceHighest,
    required this.cardBorder,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.highlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primaryGradient,
    required this.heroCardGradient,
    required this.accentGradient,
  });

  bool get isCozy => false;
  bool get isObsidian => vibe == DuwaThemeVibe.obsidianVoid;
  bool get isCleanLight => vibe == DuwaThemeVibe.cleanLight;
  bool get isDark => vibe == DuwaThemeVibe.obsidianVoid;
  bool get isLight => vibe == DuwaThemeVibe.cleanLight;
  bool get isMystic => false;
  bool get isBloom => false;
  String get vibeName => isDark ? 'Obsidian Dark' : 'Minimal White';
  String get vibeEmoji => isDark ? '🌙' : '☀️';
  String get targetAudienceTag => isDark
      ? 'Tactical Charcoal & Solar Flame'
      : 'Crisp Porcelain & Electric Indigo';

  Color get tertiaryAccent => highlight;
  Color get tertiaryContainer => secondaryContainer;
  Color get onTertiaryContainer => textPrimary;

  static DuwaThemeData cozyWellness() => cleanLight();

  static DuwaThemeData obsidianVoid() {
    return const DuwaThemeData(
      vibe: DuwaThemeVibe.obsidianVoid,
      background: DuwaColors.obsidianBackground,
      surfaceLowest: DuwaColors.obsidianSurfaceLowest,
      surfaceLow: DuwaColors.obsidianSurfaceLow,
      surface: DuwaColors.obsidianSurface,
      surfaceLight: DuwaColors.obsidianSurfaceHigh,
      surfaceHighest: DuwaColors.obsidianSurfaceHighest,
      cardBorder: DuwaColors.obsidianCardBorder,
      primaryAccent: DuwaColors.solarFlame,
      secondaryAccent: DuwaColors.ionMint,
      secondaryContainer: Color(0xFF281E18),
      onSecondaryContainer: DuwaColors.emberGold,
      highlight: DuwaColors.hyperIndigo,
      textPrimary: DuwaColors.obsidianTextPrimary,
      textSecondary: DuwaColors.obsidianTextSecondary,
      textMuted: DuwaColors.obsidianTextMuted,
      primaryGradient: LinearGradient(
        colors: [Color(0xFFFF6B2B), Color(0xFFFF4800)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      heroCardGradient: LinearGradient(
        colors: [Color(0xFF161B2B), Color(0xFF0E121E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentGradient: LinearGradient(
        colors: [Color(0xFFFF7A3D), Color(0xFFFF4800)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
  }

  static DuwaThemeData cleanLight() {
    return const DuwaThemeData(
      vibe: DuwaThemeVibe.cleanLight,
      background: DuwaColors.lightBackground,
      surfaceLowest: DuwaColors.lightSurfaceLowest,
      surfaceLow: DuwaColors.lightSurfaceLow,
      surface: DuwaColors.lightSurface,
      surfaceLight: DuwaColors.lightSurfaceHigh,
      surfaceHighest: DuwaColors.lightSurfaceHighest,
      cardBorder: DuwaColors.lightCardBorder,
      primaryAccent: DuwaColors.lightPrimary,
      secondaryAccent: DuwaColors.lightSecondary,
      secondaryContainer: DuwaColors.lightSecondaryContainer,
      onSecondaryContainer: DuwaColors.lightOnSecondaryContainer,
      highlight: DuwaColors.lightHighlight,
      textPrimary: DuwaColors.lightTextPrimary, // Crisp Jet Black (0xFF09090B)
      textSecondary: DuwaColors.lightTextSecondary,
      textMuted: DuwaColors.lightTextMuted,
      primaryGradient: LinearGradient(
        colors: [Color(0xFF5B52F2), Color(0xFF4338CA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      heroCardGradient: LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentGradient: LinearGradient(
        colors: [Color(0xFF5B52F2), Color(0xFF4338CA)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
  }

  static DuwaThemeData mysticOcean() => obsidianVoid();
  static DuwaThemeData bloom() => obsidianVoid();
}

class DuwaTheme {
  static List<BoxShadow> get cozyShadow => [
        const BoxShadow(
          color: Color(0x0D2D3142),
          blurRadius: 24,
          offset: Offset(0, 8),
          spreadRadius: -4,
        ),
        const BoxShadow(
          color: Color(0x082D3142),
          blurRadius: 8,
          offset: Offset(0, 2),
          spreadRadius: -1,
        ),
      ];

  static List<BoxShadow> get cozyShadowLift => [
        const BoxShadow(
          color: Color(0x1F5B5CE6),
          blurRadius: 32,
          offset: Offset(0, 14),
          spreadRadius: -6,
        ),
        const BoxShadow(
          color: Color(0x0A2D3142),
          blurRadius: 12,
          offset: Offset(0, 4),
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> get navShadow => [
        const BoxShadow(
          color: Color(0x141E1E24),
          blurRadius: 30,
          offset: Offset(0, 12),
        ),
      ];

  static ThemeData buildMaterialTheme(DuwaThemeData duwaTheme) {
    final isLight = duwaTheme.isCleanLight || duwaTheme.isCozy;
    final colorScheme = ColorScheme(
      brightness: isLight ? Brightness.light : Brightness.dark,
      primary: duwaTheme.primaryAccent,
      onPrimary: Colors.white,
      secondary: duwaTheme.secondaryAccent,
      onSecondary: Colors.white,
      error: DuwaColors.errorRed,
      onError: Colors.white,
      surface: duwaTheme.surface,
      onSurface: duwaTheme.textPrimary,
    );

    final baseTextTheme = ThemeData(brightness: isLight ? Brightness.light : Brightness.dark).textTheme;
    final bodyTextTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);
    final outfitHeadline = GoogleFonts.outfit(
      color: duwaTheme.textPrimary,
      fontWeight: FontWeight.w700,
    );

    final modernTextTheme = bodyTextTheme.copyWith(
      displayLarge: outfitHeadline.copyWith(fontSize: 34, letterSpacing: -0.02 * 34),
      displayMedium: outfitHeadline.copyWith(fontSize: 28, letterSpacing: -0.015 * 28),
      headlineLarge: outfitHeadline.copyWith(fontSize: 26, letterSpacing: -0.015 * 26),
      headlineMedium: outfitHeadline.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: outfitHeadline.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: outfitHeadline.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: duwaTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(color: duwaTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.plusJakartaSans(color: duwaTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.plusJakartaSans(color: duwaTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.plusJakartaSans(color: duwaTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.14),
      labelMedium: GoogleFonts.plusJakartaSans(color: duwaTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.24),
      labelSmall: GoogleFonts.plusJakartaSans(color: duwaTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.44),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isLight ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: duwaTheme.background,
      colorScheme: colorScheme,
      cardColor: duwaTheme.surface,
      dividerColor: duwaTheme.cardBorder,
      textTheme: modernTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: duwaTheme.background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: duwaTheme.textPrimary,
          letterSpacing: -0.8,
        ),
        iconTheme: IconThemeData(color: duwaTheme.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: duwaTheme.primaryAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: duwaTheme.surface,
        modalBackgroundColor: duwaTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: duwaTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: duwaTheme.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: duwaTheme.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: duwaTheme.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: duwaTheme.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: duwaTheme.primaryAccent, width: 1.5)),
      ),
    );
  }
}

/// Centralized 8-point spacing tokens for DUWA
class DuwaSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double s = 12.0;
  static const double m = 16.0;
  static const double l = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;
  static const double colossal = 64.0;
}

/// Soft rounded geometry tokens (16, 20, 24, 28, 32px)
class DuwaRadii {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 28.0;
  static const double hero = 32.0;
  static const double pill = 999.0;

  static const Radius r16 = Radius.circular(16);
  static const Radius r20 = Radius.circular(20);
  static const Radius r24 = Radius.circular(24);
  static const Radius r28 = Radius.circular(28);
  static const Radius r32 = Radius.circular(32);

  static final BorderRadius br16 = BorderRadius.circular(16);
  static final BorderRadius br20 = BorderRadius.circular(20);
  static final BorderRadius br24 = BorderRadius.circular(24);
  static final BorderRadius br28 = BorderRadius.circular(28);
  static final BorderRadius br32 = BorderRadius.circular(32);
}

/// Centralized animation durations and curves
class DuwaMotion {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration button = Duration(milliseconds: 180);
  static const Duration card = Duration(milliseconds: 240);
  static const Duration screen = Duration(milliseconds: 300);
  static const Duration major = Duration(milliseconds: 400);

  static const Curve springCurve = Curves.easeOutBack;
  static const Curve smoothCurve = Curves.fastOutSlowIn;
}

