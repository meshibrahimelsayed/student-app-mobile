import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Warm Mocha Dark Palette ───────────────────────────────
  static const Color canvasColor     = Color(0xFF0E0B08); // Deep espresso black
  static const Color surfaceCard     = Color(0xFF1C1510); // Lifted mocha card
  static const Color surfaceElevated = Color(0xFF261C13); // Warm elevated surface
  static const Color surfaceChip     = Color(0xFF2E2016); // Chip / tag bg
  static const Color surfaceColor    = surfaceCard; // Backward-compatible alias

  static const Color accentWarm      = Color(0xFFC9915E); // Warm terracotta
  static const Color accentGold      = Color(0xFFD4A853); // Gold accent
  static const Color accentGoldLight = Color(0xFFF0C97A); // Light gold highlight
  static const Color accentCream     = Color(0xFFF5EDD8); // Cream white text
  static const Color accentSage      = Color(0xFF8FAF90); // Muted sage green

  static const Color textPrimary     = Color(0xFFF5EDD8); // Cream
  static const Color textSecondary   = Color(0xFFBFA98E); // Warm sand
  static const Color textMuted       = Color(0xFF7A6655); // Muted brown

  static const Color borderSubtle    = Color(0x18F5EDD8); // Cream border 10%
  static const Color borderMedium    = Color(0x28F5EDD8); // Cream border 16%

  // ─── Accent Semantic Aliases (kept for compatibility) ──────
  static const Color accentCobalt    = accentWarm;
  static const Color accentEmerald   = accentSage;
  static const Color accentAmber     = accentGold;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: canvasColor,
      colorScheme: const ColorScheme.dark(
        primary: accentWarm,
        secondary: accentGold,
        surface: surfaceCard,
        surfaceContainerHighest: surfaceElevated,
        onSurface: textPrimary,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge:  TextStyle(fontWeight: FontWeight.w800, color: textPrimary,   letterSpacing: -0.8, fontSize: 28),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: textPrimary,   letterSpacing: -0.5, fontSize: 22),
        titleLarge:     TextStyle(fontWeight: FontWeight.bold, color: textPrimary,   letterSpacing: -0.3, fontSize: 18),
        titleMedium:    TextStyle(fontWeight: FontWeight.w600, color: textPrimary,   fontSize: 15),
        bodyLarge:      TextStyle(color: textSecondary, fontSize: 14),
        bodyMedium:     TextStyle(color: textMuted,     fontSize: 12),
        labelSmall:     TextStyle(color: textMuted,     fontSize: 10, letterSpacing: 0.4),
      ),
      cardTheme: CardTheme(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceElevated,
        indicatorColor: accentWarm.withOpacity(0.18),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentGold);
          }
          return const TextStyle(fontSize: 10, color: textMuted);
        }),
      ),
    );
  }
}
