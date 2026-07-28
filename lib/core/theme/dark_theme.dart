import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'theme_extensions.dart';

ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: AdminDarkColors.border),
  );
  final scheme = ColorScheme.fromSeed(
    seedColor: AdminDarkColors.primaryGreen,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AdminDarkColors.primaryGreen,
    onPrimary: AdminDarkColors.headerBackground,
    secondary: AdminDarkColors.primaryGreen,
    onSecondary: AdminDarkColors.headerBackground,
    surface: AdminDarkColors.surface,
    onSurface: AdminDarkColors.primaryText,
    outline: AdminDarkColors.border,
    error: AdminDarkColors.danger,
    onError: AdminDarkColors.primaryText,
    surfaceTint: AdminDarkColors.primaryGreen,
  );

  return base.copyWith(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AdminDarkColors.pageBackground,
    canvasColor: AdminDarkColors.pageBackground,
    cardColor: AdminDarkColors.surface,
    colorScheme: scheme,
    textTheme: GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(
      bodyColor: AdminDarkColors.primaryText,
      displayColor: AdminDarkColors.primaryText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AdminDarkColors.headerBackground,
      foregroundColor: AdminDarkColors.primaryText,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AdminDarkColors.inputSurface,
      hintStyle: const TextStyle(
        color: AdminDarkColors.mutedText,
        fontSize: 12,
      ),
      labelStyle: const TextStyle(color: AdminDarkColors.secondaryText),
      floatingLabelStyle: const TextStyle(color: AdminDarkColors.primaryGreen),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(
          color: AdminDarkColors.primaryGreen,
          width: 1.5,
        ),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AdminDarkColors.danger),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AdminDarkColors.danger, width: 1.5),
      ),
    ),
    dividerColor: AdminDarkColors.divider,
    dividerTheme:
        const DividerThemeData(color: AdminDarkColors.divider, space: 1),
    popupMenuTheme: PopupMenuThemeData(
      color: AdminDarkColors.elevatedSurface,
      surfaceTintColor: AdminDarkColors.elevatedSurface,
      textStyle: GoogleFonts.inter(
        color: AdminDarkColors.primaryText,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        backgroundColor:
            WidgetStatePropertyAll(AdminDarkColors.elevatedSurface),
        surfaceTintColor:
            WidgetStatePropertyAll(AdminDarkColors.elevatedSurface),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AdminDarkColors.selectedGreen,
      contentTextStyle: GoogleFonts.inter(
        color: AdminDarkColors.primaryText,
        fontSize: 13,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AdminDarkColors.elevatedSurface,
      surfaceTintColor: AdminDarkColors.elevatedSurface,
      titleTextStyle: GoogleFonts.inter(
        color: AdminDarkColors.primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: AdminDarkColors.secondaryText,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AdminDarkColors.elevatedSurface,
        border: Border.all(color: AdminDarkColors.border),
        borderRadius: BorderRadius.circular(7),
      ),
      textStyle: GoogleFonts.inter(
        color: AdminDarkColors.primaryText,
        fontSize: 11,
      ),
    ),
    scrollbarTheme: const ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(AdminDarkColors.mutedText),
      trackColor: WidgetStatePropertyAll(AdminDarkColors.tableHeader),
      radius: Radius.circular(8),
      thickness: WidgetStatePropertyAll(7),
    ),
    dataTableTheme: DataTableThemeData(
      headingTextStyle: GoogleFonts.inter(
        color: AdminDarkColors.secondaryText,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      dataTextStyle: GoogleFonts.inter(
        color: AdminDarkColors.primaryText,
        fontSize: 13,
      ),
      dividerThickness: 1,
    ),
    extensions: const [
      AppSemanticColors(
        pageBackground: AdminDarkColors.pageBackground,
        navigationBackground: AdminDarkColors.headerBackground,
        navigationHover: AdminDarkColors.hoverGreen,
        navigationControl: AdminDarkColors.elevatedSurface,
        activeNavigation: Color(0xFFE5F4EE),
        activeNavigationText: AdminDarkColors.headerBackground,
        borderOnHero: AdminDarkColors.border,
        cardBackground: AdminDarkColors.surface,
        elevatedSurface: AdminDarkColors.elevatedSurface,
        inputSurface: AdminDarkColors.inputSurface,
        modalSurface: AdminDarkColors.elevatedSurface,
        selectedSurface: Color(0xFF173B31),
        primaryText: AdminDarkColors.primaryText,
        secondaryText: AdminDarkColors.secondaryText,
        disabledText: Color(0xFF61716B),
        accent: AdminDarkColors.primaryGreen,
        accentStrong: AdminDarkColors.primaryGreen,
        accentDark: AdminDarkColors.selectedGreen,
        divider: AdminDarkColors.divider,
        success: AdminDarkColors.success,
        successContainer: AdminDarkColors.successContainer,
        warning: AdminDarkColors.warning,
        warningContainer: AdminDarkColors.warningContainer,
        danger: AdminDarkColors.danger,
        dangerContainer: AdminDarkColors.dangerContainer,
        info: AdminDarkColors.info,
        infoContainer: AdminDarkColors.infoContainer,
        mutedText: AdminDarkColors.mutedText,
        subtleBorder: AdminDarkColors.border,
        tableHeader: AdminDarkColors.tableHeader,
        hoverSurface: Color(0xFF1D2B27),
        overlayScrim: AdminDarkColors.modalBarrier,
        heroBackground: AdminDarkColors.headerBackground,
        heroForeground: AdminDarkColors.primaryText,
        heroMuted: AdminDarkColors.secondaryText,
      ),
    ],
  );
}
