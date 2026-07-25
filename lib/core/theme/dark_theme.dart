import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_extensions.dart';

ThemeData buildDarkTheme() {
  const primary = Color(0xFF46C99A);
  const text = Color(0xFFF5F7F6);
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF071713),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: const Color(0xFF062D25),
      surface: const Color(0xFF10241F),
      onSurface: text,
      error: const Color(0xFFFF858A),
    ),
    textTheme: GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: text, displayColor: text),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF062D25),
      foregroundColor: text,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF142923),
      hintStyle: const TextStyle(color: Color(0xFF82938D), fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFF29433C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFF29433C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFFF858A)),
      ),
    ),
    dividerColor: const Color(0xFF29433C),
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFF152D27),
      surfaceTintColor: const Color(0xFF152D27),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1B7F62),
      contentTextStyle: GoogleFonts.inter(color: text, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF10241F),
      surfaceTintColor: const Color(0xFF10241F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    extensions: const [
      AppSemanticColors(
        success: Color(0xFF5EE6B3),
        successContainer: Color(0xFF123D31),
        warning: Color(0xFFF9C66B),
        warningContainer: Color(0xFF493516),
        danger: Color(0xFFFF858A),
        dangerContainer: Color(0xFF4B2024),
        info: Color(0xFF88AEFF),
        infoContainer: Color(0xFF1B315E),
        mutedText: Color(0xFF82938D),
        subtleBorder: Color(0xFF29433C),
        tableHeader: Color(0xFF18332D),
        hoverSurface: Color(0xFF142A24),
        overlayScrim: Color(0xAD000000),
        heroBackground: Color(0xFF062D25),
        elevatedSurface: Color(0xFF152D27),
      ),
    ],
  );
}
