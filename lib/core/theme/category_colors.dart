import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Style definition for a marketplace category.
@immutable
class CategoryColorStyle {
  const CategoryColorStyle({
    required this.name,
    required this.background,
    required this.text,
    required this.border,
    required this.accent,
  });

  final String name;
  final Color background;
  final Color text;
  final Color border;
  final Color accent;
}

/// Centralized marketplace category color palette.
///
/// Ensures Meat, Fish, Fruits, and Vegetables are instantly recognizable
/// with identical colors across tables, badges, filters, charts, and modals.
abstract final class CategoryColors {
  /// 1. FRESH FISH: Background #CFFAFE, Text #0E7490, Border #A5F3FC, Accent #0E7490
  static const freshFish = CategoryColorStyle(
    name: 'Fresh Fish',
    background: Color(0xFFCFFAFE),
    text: Color(0xFF0E7490),
    border: Color(0xFFA5F3FC),
    accent: Color(0xFF0E7490),
  );

  /// 2. DRIED FISH: Background #E0E7FF, Text #4338CA, Border #C7D2FE, Accent #4338CA
  static const driedFish = CategoryColorStyle(
    name: 'Dried Fish',
    background: Color(0xFFE0E7FF),
    text: Color(0xFF4338CA),
    border: Color(0xFFC7D2FE),
    accent: Color(0xFF4338CA),
  );

  /// 3. MEAT: Background #FEE2E2, Text #B91C1C, Border #FECACA, Accent #B91C1C
  static const meat = CategoryColorStyle(
    name: 'Meat',
    background: Color(0xFFFEE2E2),
    text: Color(0xFFB91C1C),
    border: Color(0xFFFECACA),
    accent: Color(0xFFB91C1C),
  );

  /// 4. CHICKEN: Background #FFEDD5, Text #C2410C, Border #FED7AA, Accent #C2410C
  static const chicken = CategoryColorStyle(
    name: 'Chicken',
    background: Color(0xFFFFEDD5),
    text: Color(0xFFC2410C),
    border: Color(0xFFFED7AA),
    accent: Color(0xFFC2410C),
  );

  /// 5. FRUITS: Background #FEF3C7, Text #B45309, Border #FDE68A, Accent #B45309
  static const fruits = CategoryColorStyle(
    name: 'Fruits',
    background: Color(0xFFFEF3C7),
    text: Color(0xFFB45309),
    border: Color(0xFFFDE68A),
    accent: Color(0xFFB45309),
  );

  /// 6. VEGETABLES: Background #DCFCE7, Text #15803D, Border #BBF7D0, Accent #15803D
  static const vegetables = CategoryColorStyle(
    name: 'Vegetables',
    background: Color(0xFFDCFCE7),
    text: Color(0xFF15803D),
    border: Color(0xFFBBF7D0),
    accent: Color(0xFF15803D),
  );

  /// 7. MARITATAS: Background #F3E8FF, Text #7E22CE, Border #E9D5FF, Accent #7E22CE
  static const maritatas = CategoryColorStyle(
    name: 'Maritatas',
    background: Color(0xFFF3E8FF),
    text: Color(0xFF7E22CE),
    border: Color(0xFFE9D5FF),
    accent: Color(0xFF7E22CE),
  );

  /// 8. SARI-SARI: Background #FCE7F3, Text #BE185D, Border #FBCFE8, Accent #BE185D
  static const sariSari = CategoryColorStyle(
    name: 'Sari-Sari',
    background: Color(0xFFFCE7F3),
    text: Color(0xFFBE185D),
    border: Color(0xFFFBCFE8),
    accent: Color(0xFFBE185D),
  );

  /// Backward compatibility alias
  static const fish = freshFish;

  /// Fallback for unclassified categories
  static const fallback = CategoryColorStyle(
    name: 'Other',
    background: Color(0xFFF1F5F9),
    text: Color(0xFF475569),
    border: Color(0xFFE2E8F0),
    accent: Color(0xFF64748B),
  );

  /// All recognized categories in standard display order
  static const all = [
    freshFish,
    driedFish,
    meat,
    chicken,
    fruits,
    vegetables,
    maritatas,
    sariSari,
  ];

  /// Resolves the color style for a given category name (case-insensitive).
  static CategoryColorStyle get(String? category) {
    if (category == null || category.trim().isEmpty) return fallback;
    final normalized = category.trim().toLowerCase();

    if (normalized.contains('dried') ||
        normalized.contains('daing') ||
        normalized.contains('tuyo') ||
        normalized.contains('tinapa')) {
      return driedFish;
    }
    if (normalized.contains('chicken') ||
        normalized.contains('poultry') ||
        normalized.contains('manok')) {
      return chicken;
    }
    if (normalized.contains('fresh fish') ||
        normalized.contains('fish') ||
        normalized.contains('seafood') ||
        normalized.contains('bangus') ||
        normalized.contains('tilapia')) {
      return freshFish;
    }
    if (normalized.contains('meat') ||
        normalized.contains('pork') ||
        normalized.contains('beef') ||
        normalized.contains('butchery')) {
      return meat;
    }
    if (normalized.contains('fruit')) {
      return fruits;
    }
    if (normalized.contains('veg') ||
        normalized.contains('produce') ||
        normalized.contains('green')) {
      return vegetables;
    }
    if (normalized.contains('maritata')) {
      return maritatas;
    }
    if (normalized.contains('sari') ||
        normalized.contains('grocery') ||
        normalized.contains('dry goods') ||
        normalized.contains('merchandise')) {
      return sariSari;
    }

    return fallback;
  }

  /// Checks if a string represents a known marketplace category.
  static bool isCategory(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final normalized = value.trim().toLowerCase();
    if (normalized == 'all categories' ||
        normalized == 'all' ||
        normalized == 'stall category' ||
        normalized == 'customer account') {
      return false;
    }
    return normalized.contains('fish') ||
        normalized.contains('dried') ||
        normalized.contains('meat') ||
        normalized.contains('chicken') ||
        normalized.contains('fruit') ||
        normalized.contains('veg') ||
        normalized.contains('maritata') ||
        normalized.contains('sari');
  }
}

/// A standard category pill badge.
///
/// Features:
/// - Exact light category background + dark category text + 1px border.
/// - Medium font weight.
/// - Uppercase text by default (e.g. `MEAT`, `FISH`).
/// - Automatic multi-category splitting: if given `"VEGETABLES, FISH"`, renders
///   separate pills `[ VEGETABLES ]` `[ FISH ]` each with its own color.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.category,
    this.uppercase = true,
    this.fontSize = 10.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  final String category;
  final bool uppercase;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // Handle multi-category comma or slash separated lists
    if (category.contains(',') || category.contains('/')) {
      final parts = category
          .split(RegExp(r'[,/]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (parts.length > 1) {
        return Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: parts
              .map(
                (part) => CategoryBadge(
                  category: part,
                  uppercase: uppercase,
                  fontSize: fontSize,
                  padding: padding,
                ),
              )
              .toList(),
        );
      }
    }

    final style = CategoryColors.get(category);
    final text = uppercase ? category.trim().toUpperCase() : category.trim();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.border, width: 1),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: style.text,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// A small colored indicator circle used in dropdowns, menus, and legends.
class CategoryDot extends StatelessWidget {
  const CategoryDot({
    super.key,
    required this.category,
    this.size = 8.0,
  });

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = CategoryColors.get(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.accent,
        shape: BoxShape.circle,
        border: Border.all(color: style.border, width: 1),
      ),
    );
  }
}
