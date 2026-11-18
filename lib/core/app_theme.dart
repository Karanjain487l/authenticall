import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

/// Builds the full Material theme for light & dark pastel modes.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? Palette.lavenderBright : Palette.lavender,
      onPrimary: isDark ? Palette.darkBackground : Colors.white,
      primaryContainer: isDark ? Palette.darkSurfaceAlt : Palette.lavenderMist,
      onPrimaryContainer: isDark ? Palette.darkInk : Palette.lightInk,
      secondary: isDark ? Palette.mintBright : Palette.mint,
      onSecondary: isDark ? Palette.darkBackground : Colors.white,
      secondaryContainer: isDark ? Color(0xFF2E4A42) : Palette.mintMist,
      onSecondaryContainer: isDark ? Palette.darkInk : Color(0xFF2F5D4C),
      tertiary: isDark ? Palette.blushBright : Palette.blush,
      tertiaryContainer: isDark ? Color(0xFF4A3140) : Palette.blushMist,
      onTertiaryContainer: isDark ? Palette.darkInk : Color(0xFF7A3A50),
      error: isDark ? Palette.coralBright : Palette.coral,
      onError: Colors.white,
      errorContainer: isDark ? Color(0xFF523038) : Palette.coralMist,
      onErrorContainer: isDark ? Palette.darkInk : Color(0xFF8E3B45),
      surface: isDark ? Palette.darkSurface : Palette.lightSurface,
      onSurface: isDark ? Palette.darkInk : Palette.lightInk,
      surfaceContainerHighest:
          isDark ? Palette.darkSurfaceAlt : Palette.lightSurfaceAlt,
      onSurfaceVariant: isDark ? Palette.darkInkSub : Palette.lightInkSub,
      outline: isDark ? Palette.darkOutline : Palette.lightOutline,
      outlineVariant: isDark ? Color(0xFF3A3358) : Palette.lightOutline,
      shadow: isDark ? Colors.black : Color(0xFF5B4E86),
      scrim: Colors.black,
      inverseSurface: isDark ? Palette.lightSurface : Palette.lightInk,
      onInverseSurface: isDark ? Palette.lightInk : Colors.white,
      inversePrimary: isDark ? Palette.lavender : Palette.lavenderSoft,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      scaffoldBackgroundColor:
          isDark ? Palette.darkBackground : Palette.lightBackground,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: GoogleFonts.quicksand(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: isDark ? Color(0xFF3B3360) : Palette.lightInk,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 13.5),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primaryContainer,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withOpacity(0.14),
        valueIndicatorColor: scheme.primary,
        valueIndicatorTextStyle: TextStyle(color: scheme.onPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : (isDark ? Palette.darkInkSub : Palette.lightInkSub),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : (isDark ? Palette.darkSurfaceAlt : Palette.lightSurfaceAlt),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
