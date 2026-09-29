import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palengkego_admin/core/config/app_config.dart';
import 'package:palengkego_admin/core/theme/app_theme.dart';
import 'package:palengkego_admin/core/theme/theme_controller.dart';
import 'package:palengkego_admin/features/authentication/login_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createLoginTestWidget({required SharedPreferences prefs}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseEnabledProvider.overrideWithValue(false),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        home: const LoginPage(),
      ),
    );
  }

  testWidgets('renders login page with two-column layout, branding, and inputs',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(createLoginTestWidget(prefs: prefs));
    await tester.pumpAndSettle();

    // Verify promotional text and branding
    expect(find.text('NAGA CITY PEOPLE’S MALL'), findsOneWidget);
    expect(find.text('Skip the Roam,\nOrder from Home.'), findsOneWidget);

    // The admin login screen has no public navigation.
    expect(find.text('Home'), findsNothing);
    expect(find.text('About'), findsNothing);
    expect(find.text('Contact'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Install App'), findsNothing);

    // Verify login form heading
    expect(find.text('Welcome Back, Admin!'), findsOneWidget);
    expect(find.text('Authorized personnel only'), findsOneWidget);

    // Verify fields
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Verify Keep me signed in
    expect(find.text('Keep me signed in'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    // Verify Log In button
    expect(find.widgetWithText(FilledButton, 'Log In'), findsOneWidget);

    // The login screen has no footer.
    expect(
      find.text(
        'Naga City People’s Mall — Market Enterprise and Promotions Office (MEPO)',
      ),
      findsNothing,
    );
    expect(find.text('Privacy Policy'), findsNothing);
    expect(find.text('Terms of Service'), findsNothing);
    expect(find.text('Support'), findsNothing);
  });

  testWidgets('clicking Keep me signed in label toggles the checkbox',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(createLoginTestWidget(prefs: prefs));
    await tester.pumpAndSettle();

    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsOneWidget);
    Checkbox checkbox = tester.widget(checkboxFinder);
    expect(checkbox.value, isFalse);

    // Tap on the text label "Keep me signed in"
    await tester.tap(find.text('Keep me signed in'));
    await tester.pumpAndSettle();

    checkbox = tester.widget(checkboxFinder);
    expect(checkbox.value, isTrue);

    // Tap again to toggle off
    await tester.tap(find.text('Keep me signed in'));
    await tester.pumpAndSettle();

    checkbox = tester.widget(checkboxFinder);
    expect(checkbox.value, isFalse);
  });

  testWidgets('password visibility icon toggles obscureText', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(createLoginTestWidget(prefs: prefs));
    await tester.pumpAndSettle();

    // Find password field
    final passwordFieldFinder = find.byWidgetPredicate(
      (widget) => widget is EditableText && widget.obscureText == true,
    );
    expect(passwordFieldFinder, findsOneWidget);

    // Tap toggle icon button
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    // Now password should not be obscured
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is EditableText && widget.obscureText == true,
      ),
      findsNothing,
    );
  });

  testWidgets('Forgot password opens dialog with reset input and action',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(createLoginTestWidget(prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsNothing);
  });

}
