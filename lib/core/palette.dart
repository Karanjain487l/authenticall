import 'package:flutter/material.dart';

/// "Softscape" - the calming pastel design system of AuthentiCall.
///
/// Light mode  : warm cream base with lavender / mint / blush / peach pastels.
/// Dark mode   : deep plum night sky with glowing muted pastels.
class Palette {
  Palette._();

  // ---------- shared accents ----------
  static const Color lavender = Color(0xFF8B7BD8);
  static const Color lavenderSoft = Color(0xFFB7A6E3);
  static const Color lavenderMist = Color(0xFFE7E1F9);
  static const Color mint = Color(0xFF7FC8A9);
  static const Color mintSoft = Color(0xFFA8D8C4);
  static const Color mintMist = Color(0xFFDFF3E9);
  static const Color blush = Color(0xFFEFA3B8);
  static const Color blushSoft = Color(0xFFF5C1CE);
  static const Color blushMist = Color(0xFFFBE3EA);
  static const Color peach = Color(0xFFF6B68B);
  static const Color peachMist = Color(0xFFFDE8D9);
  static const Color butter = Color(0xFFEFC96E);
  static const Color butterMist = Color(0xFFFAF0D3);
  static const Color coral = Color(0xFFE4707E);
  static const Color coralMist = Color(0xFFF9DCDF);

  // ---------- light mode ----------
  static const Color lightBackground = Color(0xFFFAF7F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF3F0FB);
  static const Color lightInk = Color(0xFF37304E);
  static const Color lightInkSub = Color(0xFF756D91);
  static const Color lightOutline = Color(0xFFE6E0F2);

  // ---------- dark mode ----------
  static const Color darkBackground = Color(0xFF221D35);
  static const Color darkSurface = Color(0xFF2C2645);
  static const Color darkSurfaceAlt = Color(0xFF37305A);
  static const Color darkInk = Color(0xFFF2EFFA);
  static const Color darkInkSub = Color(0xFFB7AFD6);
  static const Color darkOutline = Color(0xFF453D6B);

  // ---------- helpers ----------
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext c) =>
      isDark(c) ? darkBackground : lightBackground;

  static Color surface(BuildContext c) =>
      isDark(c) ? darkSurface : lightSurface;

  static Color surfaceAlt(BuildContext c) =>
      isDark(c) ? darkSurfaceAlt : lightSurfaceAlt;

  static Color ink(BuildContext c) => isDark(c) ? darkInk : lightInk;

  static Color inkSub(BuildContext c) => isDark(c) ? darkInkSub : lightInkSub;

  static Color outline(BuildContext c) =>
      isDark(c) ? darkOutline : lightOutline;

  /// In dark mode the pastel accents get a little brighter so every
  /// button / chip stays clearly visible on the plum background.
  static Color accent(BuildContext c, Color light, Color dark) =>
      isDark(c) ? dark : light;

  static const Color lavenderBright = Color(0xFFB4A3F0);
  static const Color mintBright = Color(0xFF8FD6B6);
  static const Color blushBright = Color(0xFFF0A8BE);
  static const Color peachBright = Color(0xFFF2B48C);
  static const Color butterBright = Color(0xFFEFD08A);
  static const Color coralBright = Color(0xFFEE8E9A);

  static LinearGradient heroGradient(BuildContext c) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark(c)
            ? [Color(0xFF3A3160), Color(0xFF4A3355)]
            : [lavenderMist, blushMist],
      );

  static LinearGradient primaryGradient(BuildContext c) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark(c)
            ? [lavenderBright, blushBright]
            : [lavender, blush],
      );

  static LinearGradient freshGradient(BuildContext c) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark(c)
            ? [mintBright, butterBright]
            : [mint, butter],
      );
}
