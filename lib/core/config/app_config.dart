import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compile-time backend switch, mirroring the main app's pattern.
///
///   flutter run                     → demo mode (seeded data, local login)
///   flutter run --dart-define=FIREBASE_ENABLED=true
///                                  → live Firebase Auth/Firestore/callables
class AppConfig {
  const AppConfig({this.firebaseEnabled = false});

  final bool firebaseEnabled;

  factory AppConfig.load() => AppConfig(
        firebaseEnabled: const bool.fromEnvironment(
          'FIREBASE_ENABLED',
          defaultValue: false,
        ),
      );
}

final firebaseEnabledProvider = Provider<bool>(
  (ref) => ref.watch(appConfigProvider).firebaseEnabled,
);

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.load());
