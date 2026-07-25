import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class PalengkeGoApp extends ConsumerWidget {
  const PalengkeGoApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'PalengkeGo Admin',
    debugShowCheckedModeBanner: false,
    theme: buildLightTheme(),
    darkTheme: buildDarkTheme(),
    themeMode: ref.watch(themeModeProvider),
    routerConfig: ref.watch(appRouterProvider),
    themeAnimationDuration: const Duration(milliseconds: 220),
    themeAnimationCurve: Curves.easeOutCubic,
  );
}
