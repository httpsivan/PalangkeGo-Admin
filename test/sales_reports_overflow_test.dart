import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palengkego_admin/core/theme/app_theme.dart';
import 'package:palengkego_admin/core/theme/theme_controller.dart';
import 'package:palengkego_admin/features/sales_reports/sales_reports_page.dart';

void main() {
  testWidgets('pump SalesReportsPage and verify 0 overflows', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = (details) {
      errors.add(details);
    };

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: SalesReportsPage(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    debugPrint("Total errors: ${errors.length}");
    for (var i = 0; i < errors.length; i++) {
      debugPrint("ERR $i: ${errors[i].exceptionAsString()}");
    }
    expect(errors, isEmpty);
  });
}
