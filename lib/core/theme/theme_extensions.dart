import 'package:flutter/material.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.info,
    required this.infoContainer,
    required this.mutedText,
    required this.subtleBorder,
    required this.tableHeader,
    required this.hoverSurface,
    required this.overlayScrim,
    required this.heroBackground,
    required this.elevatedSurface,
  });

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color info;
  final Color infoContainer;
  final Color mutedText;
  final Color subtleBorder;
  final Color tableHeader;
  final Color hoverSurface;
  final Color overlayScrim;
  final Color heroBackground;
  final Color elevatedSurface;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? danger,
    Color? dangerContainer,
    Color? info,
    Color? infoContainer,
    Color? mutedText,
    Color? subtleBorder,
    Color? tableHeader,
    Color? hoverSurface,
    Color? overlayScrim,
    Color? heroBackground,
    Color? elevatedSurface,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      mutedText: mutedText ?? this.mutedText,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      tableHeader: tableHeader ?? this.tableHeader,
      hoverSurface: hoverSurface ?? this.hoverSurface,
      overlayScrim: overlayScrim ?? this.overlayScrim,
      heroBackground: heroBackground ?? this.heroBackground,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      subtleBorder: Color.lerp(subtleBorder, other.subtleBorder, t)!,
      tableHeader: Color.lerp(tableHeader, other.tableHeader, t)!,
      hoverSurface: Color.lerp(hoverSurface, other.hoverSurface, t)!,
      overlayScrim: Color.lerp(overlayScrim, other.overlayScrim, t)!,
      heroBackground: Color.lerp(heroBackground, other.heroBackground, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
    );
  }
}
