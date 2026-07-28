import 'package:flutter/material.dart';

/// Shared dark palette for the PalengkeGo Admin application.
///
/// Keeping these values in one place makes it possible for reusable widgets
/// and the page themes to use the same visual language without duplicating
/// page-specific dark-mode colors.
abstract final class AdminDarkColors {
  static const pageBackground = Color(0xFF0D1412);
  static const headerBackground = Color(0xFF073E32);
  static const headerSecondary = Color(0xFF0A493A);

  static const surface = Color(0xFF151D1B);
  static const elevatedSurface = Color(0xFF1B2522);
  static const inputSurface = Color(0xFF202A27);
  static const tableHeader = Color(0xFF1C2926);

  static const border = Color(0xFF34423E);
  static const divider = Color(0xFF2C3935);

  static const primaryText = Color(0xFFF4F7F6);
  static const secondaryText = Color(0xFFC2CCC8);
  static const mutedText = Color(0xFF8F9C97);

  static const primaryGreen = Color(0xFF24C58A);
  static const selectedGreen = Color(0xFF0F5D49);
  static const hoverGreen = Color(0xFF174F41);

  static const modalBarrier = Color(0xB3000D0A);

  static const success = Color(0xFF42E6AA);
  static const successContainer = Color(0xFF123D31);
  static const info = Color(0xFF73A7FF);
  static const infoContainer = Color(0xFF152F50);
  static const warning = Color(0xFFFFBF55);
  static const warningContainer = Color(0xFF493619);
  static const danger = Color(0xFFFF7A84);
  static const dangerContainer = Color(0xFF4A2025);
}
