import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palengkego_admin/core/theme/app_theme.dart';
import 'package:palengkego_admin/core/theme/theme_controller.dart';
import 'package:palengkego_admin/models/app_models.dart';
import 'package:palengkego_admin/features/accounts/accounts_page.dart';
import 'package:palengkego_admin/features/announcements/announcement_dialog.dart';
import 'package:palengkego_admin/features/announcements/announcement_history_page.dart';
import 'package:palengkego_admin/features/audit_log/audit_log_page.dart';
import 'package:palengkego_admin/features/authentication/login_page.dart';
import 'package:palengkego_admin/features/notifications/notifications_page.dart';
import 'package:palengkego_admin/features/overview/overview_page.dart';
import 'package:palengkego_admin/features/renewals/renewals_page.dart';
import 'package:palengkego_admin/features/reports/reports_page.dart';
import 'package:palengkego_admin/features/sales_reports/sales_reports_page.dart';
import 'package:palengkego_admin/features/vendor_applications/vendor_applications_page.dart';
import 'package:palengkego_admin/features/vendor_applications/verification_dialog.dart';

void main() {
  const viewports = <String, Size>{
    'Phone (360x780)': Size(360, 780),
    'Tablet (768x1024)': Size(768, 1024),
    'Laptop (1280x800)': Size(1280, 800),
    'Computer (1920x1080)': Size(1920, 1080),
  };

  for (final entry in viewports.entries) {
    final viewportName = entry.key;
    final size = entry.value;

    testWidgets('Zero overflow in LoginPage on $viewportName', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: LoginPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('overflowed by'))
          .toList();
      expect(overflowErrors, isEmpty,
          reason: 'Expected 0 overflow errors on $viewportName');
    });

    testWidgets('Zero overflow in OverviewPage on $viewportName',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: OverviewPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('overflowed by'))
          .toList();
      expect(overflowErrors, isEmpty,
          reason: 'Expected 0 overflow errors on $viewportName');
    });

    testWidgets('Zero overflow in AccountsPage on $viewportName',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: AccountsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('overflowed by'))
          .toList();
      expect(overflowErrors, isEmpty,
          reason: 'Expected 0 overflow errors on $viewportName');
    });

    testWidgets('Zero overflow in VendorApplicationsPage on $viewportName',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: VendorApplicationsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('overflowed by'))
          .toList();
      expect(overflowErrors, isEmpty,
          reason: 'Expected 0 overflow errors on $viewportName');
    });

    testWidgets('Zero overflow in RenewalsPage on $viewportName',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: RenewalsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('overflowed by'))
          .toList();
      expect(overflowErrors, isEmpty,
          reason: 'Expected 0 overflow errors on $viewportName');
    });

    testWidgets('Zero overflow in ReportsPage on $viewportName',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: ReportsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('overflowed by'))
          .toList();
      expect(overflowErrors, isEmpty,
          reason: 'Expected 0 overflow errors on $viewportName');
    });

    testWidgets('Zero overflow in SalesReportsPage on $viewportName',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: SalesReportsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('overflowed by'))
          .toList();
      expect(overflowErrors, isEmpty,
          reason: 'Expected 0 overflow errors on $viewportName');
    });

    testWidgets('Zero overflow in AnnouncementHistoryPage on $viewportName',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: AnnouncementHistoryPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('overflowed by'))
          .toList();
      expect(overflowErrors, isEmpty,
          reason: 'Expected 0 overflow errors on $viewportName');
    });

    testWidgets('Zero overflow in NotificationsPage on $viewportName',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: NotificationsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('overflowed by'))
          .toList();
      expect(overflowErrors, isEmpty,
          reason: 'Expected 0 overflow errors on $viewportName');
    });

    testWidgets('Zero overflow in AuditLogPage on $viewportName',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(body: AuditLogPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('overflowed by'))
          .toList();
      expect(overflowErrors, isEmpty,
          reason: 'Expected 0 overflow errors on $viewportName');
    });

    testWidgets('Zero overflow in VerificationDialog on $viewportName',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: Scaffold(
              body: VerificationDialog.application(
                VendorApplication(
                  id: 'APP-1001',
                  applicant: 'Juan Dela Cruz',
                  stallName: 'Fresh Veggies',
                  category: 'Vegetables',
                  location: 'Section A, Stall 12',
                  status: ApplicationStatus.reviewing,
                  submittedAt: DateTime.now(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('overflowed by'))
          .toList();
      expect(overflowErrors, isEmpty,
          reason: 'Expected 0 overflow errors on $viewportName');
    });

    testWidgets('Zero overflow in AnnouncementDialog on $viewportName',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

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
              body: AnnouncementDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('overflowed by'))
          .toList();
      expect(overflowErrors, isEmpty,
          reason: 'Expected 0 overflow errors on $viewportName');
    });
  }
}
