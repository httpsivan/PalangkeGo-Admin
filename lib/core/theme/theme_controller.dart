import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);
final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(
    ref.watch(sharedPreferencesProvider),
    ref.watch(initialThemeModeProvider),
  ),
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._preferences, ThemeMode initial) : super(initial);
  final SharedPreferences _preferences;
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _preferences.setString('theme_mode', mode.name);
  }

  Future<void> toggleResolved(Brightness brightness) =>
      setMode(brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}

ThemeMode themeModeFromPreference(String? value) => switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
