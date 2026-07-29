import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const instant = Duration(milliseconds: 100);
  static const hover = Duration(milliseconds: 150);
  static const press = Duration(milliseconds: 120);
  static const component = Duration(milliseconds: 180);
  static const menu = Duration(milliseconds: 180);
  static const indicator = Duration(milliseconds: 220);
  static const dialog = Duration(milliseconds: 250);
  static const page = Duration(milliseconds: 280);
  static const panel = Duration(milliseconds: 320);
  static const chart = Duration(milliseconds: 500);

  static const easeOut = Curves.easeOutCubic;
  static const easeInOut = Curves.easeInOut;

  static bool reducedMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration duration(BuildContext context, Duration value) =>
      reducedMotion(context) ? Duration.zero : value;
}
