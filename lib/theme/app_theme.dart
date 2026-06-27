import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette — "Binary Amber" aesthetic
  // Inspired by old compression terminals and punch-card machines
  static const Color background = Color(0xFF0D0F14);      // near-black
  static const Color surface = Color(0xFF151821);          // card bg
  static const Color surfaceVariant = Color(0xFF1C2030);   // elevated
  static const Color accent = Color(0xFFE8A838);           // amber/gold
  static const Color accentDim = Color(0xFF7A5520);        // muted amber
  static const Color userBubble = Color(0xFF1E2A42);       // cool navy
  static const Color aiBubble = Color(0xFF181E2A);         // deep navy
  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color divider = Color(0xFF232A38);
  static const Color success = Color(0xFF3DD68C);
  static const Color error = Color(0xFFE05C5C);
  static const Color inputBg = Color(0xFF1A1F2E);
  static const Color inputBorder = Color(0xFF2D3548);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentDim,
        surface: surface,
        error: error,
        onPrimary: background,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      dividerColor: divider,
      cardColor: surface,
    );
  }

  // Typography helpers
  static TextStyle get displayFont =>
      GoogleFonts.spaceGrotesk(color: textPrimary, fontWeight: FontWeight.w700);

  static TextStyle get monoFont =>
      GoogleFonts.jetBrainsMono(color: accent, fontSize: 12);

  static TextStyle get bodyFont => GoogleFonts.inter(color: textPrimary);
}