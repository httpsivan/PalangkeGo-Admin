import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_extensions.dart';

ThemeData buildLightTheme() {
  const primary = Color(0xFF0F4A3C);
  const text = Color(0xFF1F2937);
  final base = ThemeData.light(useMaterial3: true);
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
  );

  return base.copyWith(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAF7ED),
    canvasColor: const Color(0xFFFAF7ED),
    cardColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: text,
      outline: const Color(0xFFE5E7EB),
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
      labelStyle: const TextStyle(color: text),
      floatingLabelStyle: const TextStyle(color: primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    ),
    dividerColor: const Color(0xFFE5E7EB),
    dividerTheme: const DividerThemeData(color: Color(0xFFE5E7EB), space: 1),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      textStyle: GoogleFonts.inter(color: text, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        shadowColor: WidgetStatePropertyAll(Colors.black.withOpacity(.14)),
      ),
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
      titleTextStyle: GoogleFonts.inter(
        color: text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: GoogleFonts.inter(color: text, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF161D1B),
        borderRadius: BorderRadius.circular(7),
      ),
      textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 11),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: const WidgetStatePropertyAll(Color(0xFF94A3B8)),
      trackColor: const WidgetStatePropertyAll(Color(0xFFE5E7EB)),
      radius: const Radius.circular(8),
      thickness: const WidgetStatePropertyAll(7),
    ),
    dataTableTheme: DataTableThemeData(
      headingTextStyle: GoogleFonts.inter(
        color: const Color(0xFF64748B),
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      dataTextStyle: GoogleFonts.inter(color: text, fontSize: 13),
      dividerThickness: 1,
    ),
    extensions: const [
      AppSemanticColors(
        pageBackground: Color(0xFFFAF7ED),
        navigationBackground: primary,
        navigationHover: Color(0xFF174F41),
        navigationControl: Color(0x1FFFFFFF),
        activeNavigation: Colors.white,
        activeNavigationText: Color(0xFF073E32),
        borderOnHero: Color(0x2EFFFFFF),
        cardBackground: Colors.white,
        elevatedSurface: Colors.white,
        inputSurface: Color(0xFFF8FAFC),
        modalSurface: Colors.white,
        selectedSurface: Color(0xFFF5F8F7),
        primaryText: text,
        secondaryText: Color(0xFF475569),
        disabledText: Color(0xFF94A3B8),
        accent: primary,
        accentStrong: Color(0xFF10B981),
        accentDark: primary,
        divider: Color(0xFFE5E7EB),
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
        heroBackground: primary,
        heroForeground: Colors.white,
        heroMuted: Color(0xB3FFFFFF),
      ),
    ],
  );
}
