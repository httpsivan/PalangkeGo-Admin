# PalengkeGo Admin

PalengkeGo Admin is a Flutter Web dashboard for managing a local market marketplace. It includes a responsive overview, vendor/customer accounts, KYC verification, renewals, reports, notifications, sales reporting, and an administrator audit log.

> **Two modes.** Demo mode (default) is a front-end demo with seeded data.
Firebase mode (`--dart-define=FIREBASE_ENABLED=true`) connects to the real
backend: Firebase Auth admin sign-in (role-checked), live Firestore reads,
and the trusted admin callables (`approveKyc`, `approveRenewal`,
`setAccountBlocked`) from the main repo's `functions/` — audited to
`adminActions`. Panels without a live backend source (reports, suspensions,
notification delivery) show honest empty states in Firebase mode.

## Running

```bash
flutter run                                   # demo mode (seeded data)
flutter run --dart-define=FIREBASE_ENABLED=true   # live backend
flutter run -d windows --dart-define=FIREBASE_ENABLED=true  # desktop
```

Before Firebase mode works once: run `flutterfire configure` here to generate
`lib/firebase_options.dart` (a placeholder ships committed; startup fails
closed with instructions while it is still a placeholder), and create an
admin account: a Firebase Auth user whose `users/{uid}.role` is `admin`.

## Windows desktop

The `windows/` runner is scaffolded (`flutter create --platforms=windows .`).
Build with `flutter build windows`. The xlsx/pdf export paths already have
desktop implementations (`platform_file_saver_desktop.dart`).

## Local features

- Admin login with locally persisted demo credentials and profile settings.
- Overview metrics computed from the seeded vendors, customers, applications, and orders.
- Vendor and customer account status changes, blocking, and timed suspension records.
- KYC document previews, approval, rejection reasons, and audit entries.
- Renewal and customer/vendor report review workflows.
- Sales filters for date range, category, stall holder, order/payment status, payment method, amount, and search.
- Computed sales summaries, readable PDF export, and a true `.xlsx` workbook export.
- Local notification/announcement UI and an immutable local admin audit log.
- Light/dark theme support and responsive table layouts.

## Demo credentials

```text
Email:    admin@palengkego.gov.ph
Password: Admin123!
```

These credentials are for the local mock app only. Do not use them in production.

## Run

Requirements: Flutter with Dart `>=3.4.0 <4.0.0` and Chrome.

```bash
flutter pub get
flutter run -d chrome
flutter test
flutter build web --release
```

## Main routes

| Route | Purpose |
| --- | --- |
| `/login` | Administrator sign-in |
| `/overview` | Dashboard summary |
| `/accounts` | Vendors and customers |
| `/applications` | KYC applications |
| `/renewal` | Renewal requests |
| `/reports` | Customer/vendor reports |
| `/sales-reports` | Filtered marketplace sales and exports |
| `/audit-log` | Administrator activity history |
| `/notifications` | Notification center |
| `/admin-settings` | Profile and theme settings |

## Project structure

```text
lib/
├── core/       routing, theme, formatting, exports, shared widgets
├── data/       seeded data and local repository
├── features/   pages and feature dialogs
└── models/     application, sales, suspension, and audit models
```

The current repository uses `shared_preferences` for local demo persistence. For production, replace the mock repository and auth controller with server-side authentication, role-based authorization, encrypted persistence, API-backed order/KYC/report data, real notification delivery, and server-generated audit records. PDF/XLSX downloads are generated in the browser from locally available data.
