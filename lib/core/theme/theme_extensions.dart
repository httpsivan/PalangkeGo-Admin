import 'package:flutter/material.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.pageBackground,
    required this.navigationBackground,
    required this.navigationHover,
    required this.navigationControl,
    required this.activeNavigation,
    required this.activeNavigationText,
    required this.borderOnHero,
    required this.cardBackground,
    required this.elevatedSurface,
    required this.inputSurface,
    required this.modalSurface,
    required this.tableHeader,
    required this.hoverSurface,
    required this.selectedSurface,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.disabledText,
    required this.accent,
    required this.accentStrong,
    required this.accentDark,
    required this.subtleBorder,
    required this.divider,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.info,
    required this.infoContainer,
    required this.overlayScrim,
    required this.heroBackground,
    required this.heroForeground,
    required this.heroMuted,
  });

  final Color pageBackground;
  final Color navigationBackground;
  final Color navigationHover;
  final Color navigationControl;
  final Color activeNavigation;
  final Color activeNavigationText;
  final Color borderOnHero;
  final Color cardBackground;
  final Color elevatedSurface;
  final Color inputSurface;
  final Color modalSurface;
  final Color tableHeader;
  final Color hoverSurface;
  final Color selectedSurface;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color disabledText;
  final Color accent;
  final Color accentStrong;
  final Color accentDark;
  final Color subtleBorder;
  final Color divider;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color info;
  final Color infoContainer;
  final Color overlayScrim;
  final Color heroBackground;
  final Color heroForeground;
  final Color heroMuted;

  @override
  AppSemanticColors copyWith({
    Color? pageBackground,
    Color? navigationBackground,
    Color? navigationHover,
    Color? navigationControl,
    Color? activeNavigation,
    Color? activeNavigationText,
    Color? borderOnHero,
    Color? cardBackground,
    Color? elevatedSurface,
    Color? inputSurface,
    Color? modalSurface,
    Color? tableHeader,
    Color? hoverSurface,
    Color? selectedSurface,
    Color? primaryText,
    Color? secondaryText,
    Color? mutedText,
    Color? disabledText,
    Color? accent,
    Color? accentStrong,
    Color? accentDark,
    Color? subtleBorder,
    Color? divider,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? danger,
    Color? dangerContainer,
    Color? info,
    Color? infoContainer,
    Color? overlayScrim,
    Color? heroBackground,
    Color? heroForeground,
    Color? heroMuted,
  }) {
    return AppSemanticColors(
      pageBackground: pageBackground ?? this.pageBackground,
      navigationBackground: navigationBackground ?? this.navigationBackground,
      navigationHover: navigationHover ?? this.navigationHover,
      navigationControl: navigationControl ?? this.navigationControl,
      activeNavigation: activeNavigation ?? this.activeNavigation,
      activeNavigationText: activeNavigationText ?? this.activeNavigationText,
      borderOnHero: borderOnHero ?? this.borderOnHero,
      cardBackground: cardBackground ?? this.cardBackground,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      inputSurface: inputSurface ?? this.inputSurface,
      modalSurface: modalSurface ?? this.modalSurface,
      tableHeader: tableHeader ?? this.tableHeader,
      hoverSurface: hoverSurface ?? this.hoverSurface,
      selectedSurface: selectedSurface ?? this.selectedSurface,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      mutedText: mutedText ?? this.mutedText,
      disabledText: disabledText ?? this.disabledText,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      accentDark: accentDark ?? this.accentDark,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      overlayScrim: overlayScrim ?? this.overlayScrim,
      heroBackground: heroBackground ?? this.heroBackground,
      heroForeground: heroForeground ?? this.heroForeground,
      heroMuted: heroMuted ?? this.heroMuted,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      navigationBackground:
          Color.lerp(navigationBackground, other.navigationBackground, t)!,
      navigationHover: Color.lerp(navigationHover, other.navigationHover, t)!,
      navigationControl:
          Color.lerp(navigationControl, other.navigationControl, t)!,
      activeNavigation:
          Color.lerp(activeNavigation, other.activeNavigation, t)!,
      activeNavigationText:
          Color.lerp(activeNavigationText, other.activeNavigationText, t)!,
      borderOnHero: Color.lerp(borderOnHero, other.borderOnHero, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      inputSurface: Color.lerp(inputSurface, other.inputSurface, t)!,
      modalSurface: Color.lerp(modalSurface, other.modalSurface, t)!,
      tableHeader: Color.lerp(tableHeader, other.tableHeader, t)!,
      hoverSurface: Color.lerp(hoverSurface, other.hoverSurface, t)!,
      selectedSurface: Color.lerp(selectedSurface, other.selectedSurface, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      disabledText: Color.lerp(disabledText, other.disabledText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      subtleBorder: Color.lerp(subtleBorder, other.subtleBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      overlayScrim: Color.lerp(overlayScrim, other.overlayScrim, t)!,
      heroBackground: Color.lerp(heroBackground, other.heroBackground, t)!,
      heroForeground: Color.lerp(heroForeground, other.heroForeground, t)!,
      heroMuted: Color.lerp(heroMuted, other.heroMuted, t)!,
    );
  }
}
