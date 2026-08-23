# Performance Audit: PalengkeGo Admin (Tauri Desktop Target)

**Date:** 2026-08-02
**Target:** Flutter web app being wrapped in Tauri as a desktop app

---

## 🔴 CRITICAL — Tauri Blockers

### 1. `dart:html` imports (will NOT compile for desktop)

- **`lib/features/accounts/accounts_page.dart:2`** — `import 'dart:html' as html;` used for CSV download via `html.AnchorElement`
- **`lib/core/utils/csv_exporter.dart:2`** — `import 'dart:html' as html;` used for `html.AnchorElement` download
- **`lib/core/utils/report_exporter.dart:4`** — `import 'dart:html' as html;` used for `html.Blob`, `html.Url.createObjectUrlFromBlob`

These are **web-only APIs**. Tauri runs Flutter as a native desktop app — these imports will fail to compile. You need a cross-platform file-save approach (e.g., `file_picker`'s `saveFile`, or `dart:io`'s `File`).

### 2. `SharedPreferences` as the persistence layer

- **`lib/data/repositories/mock_repository.dart`** — Stores audit logs, suspensions, blocked accounts, application states, report states, and admin profile as JSON strings in SharedPreferences. Every mutation serializes the **entire** collection to JSON and writes it (e.g., `recordAudit` at line 1030 serializes ALL audit logs on every audit).
- **`lib/data/repositories/notification_repository.dart`** — Same pattern for notification read/dismissed state.

SharedPreferences is designed for small key-value pairs, not as a database. In a desktop app this will cause:
- **UI jank** on every write (synchronous disk I/O on the main thread)
- **Slow startup** as `_restore()` (mock_repository.dart:220) decodes all stored JSON
- **Memory bloat** as audit logs grow unbounded

**Recommendation:** Use a proper local database (e.g., `sqflite` or `drift`) or at minimum `path_provider` + JSON files written asynchronously.

---

## 🟠 HIGH — Performance Issues

### 3. `buildLightTheme()` called on every LoginPage build

- **`lib/features/authentication/login_page.dart:72`** — `data: buildLightTheme()` runs the full `ThemeData` construction (including `GoogleFonts.interTextTheme()`) on **every rebuild** of the login page. This is expensive.

### 4. GoogleFonts used inline everywhere

- **`lib/core/widgets/admin_widgets.dart`** — `GoogleFonts.inter()`, `GoogleFonts.plusJakartaSans()`, `GoogleFonts.montserrat()` called inline in dozens of build methods
- **`lib/features/overview/overview_page.dart`** — Same pattern
- **`lib/features/authentication/login_page.dart`** — `GoogleFonts.radley()`, `GoogleFonts.plusJakartaSans()`

Each call creates a new `TextStyle` and may trigger font loading. In a desktop app, fonts should be **bundled locally** (via `assets/fonts/`) and referenced via `TextStyle(fontFamily: ...)` to avoid network font fetching and repeated style object creation.

### 5. `_LoginSlideshow` Timer.periodic + AnimatedSwitcher

- **`lib/features/authentication/login_page.dart:385`** — `Timer.periodic` calls `setState` every 5 seconds, rebuilding the slideshow. Combined with `AnimatedSwitcher` + `Image.asset` (line 402-426), this causes continuous image decoding and widget rebuilds.

### 6. `_wait()` 500ms artificial delay on every mutation

- **`lib/data/repositories/mock_repository.dart:1226`** — `Future<void> _wait() => Future<void>.delayed(const Duration(milliseconds: 500));` — Every mutation method (`setVendorStatus`, `updateApplication`, `updateReport`, etc.) calls this. In a desktop app this will feel sluggish.

### 7. `recordAudit` serializes ALL audit logs on every audit

- **`lib/data/repositories/mock_repository.dart:1030-1033`** — `state.auditLogs.map((item) => jsonEncode(_auditToMap(item))).toList()` — O(n) serialization + full write on every audit action.

### 8. `_persistBlockedDetails` / `_persistSuspensions` / `_persistReport`

- **`lib/data/repositories/mock_repository.dart:1053, 1219, 1151`** — Each serializes entire collections to JSON on every change.

### 9. `_restore()` on startup

- **`lib/data/repositories/mock_repository.dart:220-287`** — Runs multiple `.map().toList()` operations over all data, plus `_readAuditLogs()`, `_readSuspensions()`, `_readBlockedDetails()` — all doing JSON decode on the main thread.

---

## 🟡 MEDIUM — Rebuild & Rendering Issues

### 10. Every page watches the entire `appDataProvider`

All feature pages watch `appDataProvider` (the whole `AppDataState`), so **any** data change (e.g., blocking one vendor) rebuilds **every** page's entire widget tree:

- `overview_page.dart:84`
- `accounts_page.dart:72`
- `audit_log_page.dart:34`
- `sales_reports_page.dart:44`
- `reports_page.dart:56`
- `renewals_page.dart:55`
- `vendor_applications_page.dart:77`

**Recommendation:** Use `select` on Riverpod providers to watch only the specific slices each page needs (e.g., `ref.watch(appDataProvider.select((s) => s.vendors))`).

### 11. `_OverviewHero` watches two providers

- **`lib/features/overview/overview_page.dart:482-483`** — Watches both `adminProfileProvider` and `appDataProvider`, rebuilding the entire hero (including all metric cards) on any change.

### 12. `SalesSummary.fromOrders` computed on every build

- **`lib/features/sales_reports/sales_reports_page.dart:54`** — `SalesSummary.fromOrders(values)` iterates all orders multiple times (`.where()`, `.fold()` × 5) on every build.
- **`lib/features/overview/overview_page.dart:485`** — Same in `_OverviewHero`.

### 13. `_filtered()` re-filters and re-sorts on every build

- **`lib/features/sales_reports/sales_reports_page.dart:218-249`** — Filters all 48 orders and sorts them on every build.

### 14. `DataTable` renders all rows eagerly

- **`lib/core/widgets/admin_widgets.dart:868`** — `ScrollableDataTable` uses `DataTable` which builds all rows at once. With pagination (10/page) this is manageable, but `DataTable` itself is expensive to construct (creates `DataRow` widgets for all cells).

### 15. `_NotificationPanel` uses non-lazy `ListView`

- **`lib/core/widgets/notification_panel.dart:264`** — `ListView(children: _groupedItems(...))` builds all notification widgets at once instead of using `ListView.builder`.

### 16. `BackdropFilter` with blur

- **`lib/core/widgets/admin_shell.dart:597`** — `showBlurredDialog` uses `ImageFilter.blur(sigmaX: 5, sigmaY: 5)` — expensive on large desktop screens.
- **`lib/features/accounts/accounts_page.dart:649`** — Same in `showAccountDialog`.

### 17. `AnimatedPageSwitcher` keeps previous children in Stack

- **`lib/core/animations/animated_widgets.dart:24-31`** — The `layoutBuilder` keeps `previousChildren` in a `Stack`, which can accumulate during rapid navigation.

### 18. `AnimatedCounter` creates a controller per counter

- **`lib/core/animations/animated_widgets.dart:238`** — Each `AnimatedCounter` creates its own `AnimationController`. The overview page has 5+ counters, each with its own controller and `AnimatedBuilder`.

### 19. `enumLabel` uses regex on every call

- **`lib/models/app_models.dart:27-34`** — `replaceAllMapped(RegExp(...))` on every call. Called frequently in build methods (e.g., `StatusBadge`, table rows).

### 20. `_viewedApplicationIds` reads SharedPreferences on every build

- **`lib/features/vendor_applications/vendor_applications_page.dart:28-33`** — The getter reads from SharedPreferences on every build.

### 21. `_newestId` O(n) scan on every build

- **`lib/features/vendor_applications/vendor_applications_page.dart:252-259`** — Linear scan through all applications on every build.

### 22. `_suspensionForAccount` linear scan

- **`lib/features/accounts/accounts_page.dart:590-598`** — Linear scan through suspensions for each account dialog.

### 23. `_reportedAccount` linear scans

- **`lib/features/reports/reports_page.dart:492-529`** — Linear scans through vendors/customers on every dialog build.
- **`lib/data/repositories/mock_repository.dart:789-832`** — Same pattern in `_findReportedAccount`.

### 24. `_openSelectedAccount()` called in build

- **`lib/features/accounts/accounts_page.dart:73`** — Called on every build (though guarded by `selectedAccountOpened`).

### 25. `_relativeTime` / `relativeTime` computed in build

- **`lib/core/widgets/notification_panel.dart:651`** and **`lib/core/utils/formatters.dart:5`** — `DateTime.now().difference()` computed on every build.

---

## 🟢 LOW — Minor Issues

### 26. `Image.asset` without explicit caching

- `admin_widgets.dart:37` (AppLogo), `login_page.dart:417` (slideshow), `login_page.dart:543` (footer seal), `verification_dialog.dart:303` (documents), `reports_page.dart` (evidence images)

### 27. `Image.memory` for picked images

- `announcement_dialog.dart:196` — Decodes full-resolution image bytes.

### 28. `MemoryImage` for avatar

- `admin_widgets.dart:157` — Creates a new `MemoryImage` on every build.

### 29. `_AccountSettingsDialog` / `_AdminSettingsPageState` — `setState` on every text change

- `admin_settings_page.dart:152` — `onChanged: (_) => setState(() {})` rebuilds the entire settings page on every keystroke.

### 30. `_filterTab` uses `AnimatedContainer` with `setState`

- `notification_panel.dart:372` — Rebuilds on filter change.

### 31. `_HoverCard` uses `setState` on hover

- `notification_panel.dart:693-695` — Rebuilds on every mouse enter/exit.

### 32. `_ProfileMenuItem` uses `setState` on hover

- `admin_profile_menu.dart:309-310` — Same pattern.

### 33. `_NavItem` uses `setState` on press

- `admin_shell.dart:175-177` — Rebuilds on tap down/up.

### 34. `_ResizablePanel` uses `setState` on drag

- `overview_page.dart:354-390` — Rebuilds on every drag update.

### 35. `_CounterParts.tryParse` uses regex

- `animated_widgets.dart:338` — `RegExp(r'^([^\d-]*)(-?[\d,]+(?:\.\d+)?)(.*)$')` on every counter value change.

### 36. `_seedNotifications` creates `DateTime.now()` on provider creation

- `notification_repository.dart:73` — Not a performance issue per se, but the timestamps are relative to provider creation, not app start.

---

## 📋 Recommended Action Plan

### Phase 1 — Tauri Compatibility (Blockers)

1. **Replace `dart:html` imports** in `csv_exporter.dart`, `report_exporter.dart`, and `accounts_page.dart` with a cross-platform file-save utility using `file_picker`'s `saveFile` or `dart:io`.
2. **Replace `SharedPreferences` persistence** with a proper local database (`sqflite`/`drift`) or `path_provider` + async JSON file writes.

### Phase 2 — Startup & Mutation Performance

3. **Remove the 500ms `_wait()` delay** from all mutation methods in `mock_repository.dart`.
4. **Optimize `recordAudit`** to append only the new audit entry instead of re-serializing the entire list.
5. **Optimize `_restore()`** to batch SharedPreferences reads and avoid redundant `.map().toList()` operations.

### Phase 3 — Rebuild Reduction

6. **Use Riverpod `select`** in all feature pages to watch only the specific data slices needed.
7. **Memoize `SalesSummary`** and filtered/sorted lists using `Provider` or `select`.
8. **Hoist `buildLightTheme()`** in `login_page.dart` to a static/const value.
9. **Replace `GoogleFonts.*()` inline calls** with bundled font assets and a single `TextTheme`.

### Phase 4 — Rendering Optimizations

10. **Replace `DataTable`** with a custom lazy `ListView.builder`-based table or use `DataTable2` with virtualization.
11. **Use `ListView.builder`** in `_NotificationPanel`.
12. **Remove `BackdropFilter`** or make it conditional on platform (skip on desktop).
13. **Bundle fonts locally** to avoid network font loading.

### Phase 5 — Micro-optimizations

14. **Cache `enumLabel` results** or use a lookup map.
15. **Remove `setState` on every keystroke** in settings pages.
16. **Use `RepaintBoundary`** around expensive widgets (tables, charts, slideshow).
17. **Precache images** at app startup for known assets.