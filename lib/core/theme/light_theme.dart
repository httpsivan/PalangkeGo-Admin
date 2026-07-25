import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_extensions.dart';

ThemeData buildLightTheme() {
  const primary = Color(0xFF0F4A3C);
  const text = Color(0xFF1F2937);
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAF7ED),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: text,
      error: const Color(0xFFEF4444),
    ),
    textTheme: GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: text, displayColor: text),
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    ),
    dividerColor: const Color(0xFFE5E7EB),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primary,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    extensions: const [
      AppSemanticColors(
        success: Color(0xFF10B981),
        successContainer: Color(0xFFDDF8EA),
        warning: Color(0xFFF59E0B),
        warningContainer: Color(0xFFFFF3D9),
        danger: Color(0xFFEF4444),
        dangerContainer: Color(0xFFFFE4E6),
        info: Color(0xFF2563EB),
        infoContainer: Color(0xFFE8EEFF),
        mutedText: Color(0xFF9CA3AF),
        subtleBorder: Color(0xFFE5E7EB),
        tableHeader: Color(0xFFF3F5FF),
        hoverSurface: Color(0xFFF5F8F7),
        overlayScrim: Color(0x80031E18),
        heroBackground: Color(0xFF0F4A3C),
        elevatedSurface: Color(0xFFFFFFFF),
      ),
    ],
  );
}
