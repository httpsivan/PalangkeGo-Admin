import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/core/theme/theme_controller.dart';

void main() {
  test('theme defaults to light when no preference exists', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = ThemeModeController(preferences,
        themeModeFromPreference(preferences.getString('theme_mode')));
    expect(controller.state, ThemeMode.light);
  });

  test('theme mode changes persist locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = ThemeModeController(preferences, ThemeMode.light);
    await controller.setMode(ThemeMode.dark);
    expect(controller.state, ThemeMode.dark);
    expect(preferences.getString('theme_mode'), 'dark');
  });
}
