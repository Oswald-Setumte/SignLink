import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  SIGNLINK DESIGN TOKENS
//  Single source of truth for every color,
//  radius, spacing and text style in the app.
// ─────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Background / Surface hierarchy
  static const Color background          = Color(0xFF061423);
  static const Color surfaceDim          = Color(0xFF061423);
  static const Color surfaceContainerLowest = Color(0xFF020F1E);
  static const Color surfaceContainerLow = Color(0xFF0F1C2C);
  static const Color surfaceContainer    = Color(0xFF132030);
  static const Color surfaceContainerHigh= Color(0xFF1E2B3B);
  static const Color surfaceContainerHighest = Color(0xFF283646);
  static const Color surfaceBright       = Color(0xFF2D3A4A);

  // On-surface text
  static const Color onSurface          = Color(0xFFD6E4F9);
  static const Color onSurfaceVariant   = Color(0xFFBDC9C7);
  static const Color outline            = Color(0xFF889391);
  static const Color outlineVariant     = Color(0xFF3E4948);

  // Primary — teal spectrum
  static const Color primary            = Color(0xFF7CD6CF);
  static const Color onPrimary          = Color(0xFF003734);
  static const Color primaryContainer   = Color(0xFF0B7A75);
  static const Color onPrimaryContainer = Color(0xFFADFFF8);
  static const Color inversePrimary     = Color(0xFF006A65);

  // Secondary
  static const Color secondary          = Color(0xFF6BD8CB);
  static const Color onSecondary        = Color(0xFF003732);
  static const Color secondaryContainer = Color(0xFF29A195);

  // Tertiary — mint highlight
  static const Color tertiary           = Color(0xFF4DDCC6);
  static const Color tertiaryContainer  = Color(0xFF007B6D);
  static const Color mint               = Color(0xFF5EEAD4);

  // Error
  static const Color error              = Color(0xFFFFB4AB);
  static const Color errorContainer     = Color(0xFF93000A);

  // Convenience aliases used throughout the app
  static const Color liveGreen          = mint;
  static const Color cardBorder         = Color(0x0DFFFFFF); // 5% white
  static const Color whiteBorder10      = Color(0x1AFFFFFF); // 10% white
  static const Color cameraOverlay      = Color(0x80061423); // 50% bg over camera
}

class AppRadius {
  AppRadius._();
  static const double sm      = 4.0;
  static const double md      = 8.0;  // buttons, inputs
  static const double lg      = 12.0; // cards
  static const double xl      = 16.0;
  static const double xxl     = 24.0;
  static const double full    = 9999.0;
}

class AppSpacing {
  AppSpacing._();
  static const double xs      = 4.0;
  static const double sm      = 8.0;
  static const double md      = 16.0;
  static const double lg      = 24.0;
  static const double xl      = 32.0;
  static const double gutter  = 16.0;
}

class AppTextStyles {
  AppTextStyles._();

  // Sora — brand / headlines
  static TextStyle displayLg(BuildContext context) =>
      GoogleFonts.sora(fontSize: 48, fontWeight: FontWeight.w700,
          height: 1.1, letterSpacing: -0.96, color: AppColors.onSurface);

  static TextStyle headlineLg(BuildContext context) =>
      GoogleFonts.sora(fontSize: 32, fontWeight: FontWeight.w600,
          height: 1.2, color: AppColors.onSurface);

  static TextStyle headlineLgMobile(BuildContext context) =>
      GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w600,
          height: 1.2, color: AppColors.onSurface);

  static TextStyle headlineMd(BuildContext context) =>
      GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w600,
          height: 1.3, color: AppColors.onSurface);

  // Hanken Grotesk — body
  static TextStyle bodyLg(BuildContext context) =>
      GoogleFonts.hankenGrotesk(fontSize: 18, fontWeight: FontWeight.w400,
          height: 1.6, color: AppColors.onSurface);

  static TextStyle bodyMd(BuildContext context) =>
      GoogleFonts.hankenGrotesk(fontSize: 16, fontWeight: FontWeight.w400,
          height: 1.6, color: AppColors.onSurface);

  static TextStyle bodySm(BuildContext context) =>
      GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w400,
          height: 1.5, color: AppColors.onSurfaceVariant);

  // JetBrains Mono — translation output / labels
  static TextStyle translationOutput(BuildContext context) =>
      GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.w500,
          height: 1.5, letterSpacing: 0.2, color: AppColors.onSurface);

  static TextStyle labelSm(BuildContext context) =>
      GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600,
          height: 1.0, color: AppColors.onSurfaceVariant);

  static TextStyle labelSmAccent(BuildContext context) =>
      GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600,
          height: 1.0, color: AppColors.mint);

  // Wordmark composites — "SIGN" white + "LINK" mint
  static TextStyle wordmarkBase(BuildContext context, {double size = 20}) =>
      GoogleFonts.sora(fontSize: size, fontWeight: FontWeight.w700,
          color: AppColors.onSurface, letterSpacing: 0.5);

  static TextStyle wordmarkAccent(BuildContext context, {double size = 20}) =>
      GoogleFonts.sora(fontSize: size, fontWeight: FontWeight.w700,
          color: AppColors.mint, letterSpacing: 0.5);
}

// ─────────────────────────────────────────────
//  MATERIAL THEME
// ─────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.tertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        surface: AppColors.surfaceContainer,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.onPrimary;
          return AppColors.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryContainer;
          return AppColors.surfaceBright;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
