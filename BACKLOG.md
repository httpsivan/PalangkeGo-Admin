# PalengkeGo Admin — Backlog

Last updated: 2026-08-23 · Status baseline: Firebase mode wired (auth, live
reads, trusted callables), Windows scaffolded, analyze clean, 11/11 tests.

Legend: P1 = blocks real use · P2 = before handing to MEPO staff · P3 = polish.
"F" = needs work in the main app repo (`PalengkeGoAPP`), not here.

## 1. Go-live blockers (P1)

- [ ] **`flutterfire configure` in this project** — replace the committed
  placeholder `lib/firebase_options.dart`; until then Firebase mode fails
  closed by design. Web + Windows + Android configs as needed.
- [ ] **Provision the first admin account**: create a Firebase Auth user,
  set `users/{uid}.role = 'admin'` in Firestore (console or a seed script).
- [ ] **Real sign-in smoke test** against the actual project: login →
  role-check → dashboard loads live data → one KYC approval round-trip
  (`approveKyc` callable → both docs flip → audit entry appears).
- [ ] **Announcement publishing is read-only-mapped**: `addAnnouncement`
  still writes local demo state. Wire it to
  `FirebaseAdminService.publishAnnouncement` (rules already permit
  `isAdmin()` writes to `systemAnnouncements`).
- [ ] **Surface backend errors in the UI**: mutation failures currently
  `debugPrint` only. Show a snackbar/banner + keep state honest via reload.

## 2. Live-data completeness (P2)

- [ ] **KYC document viewer**: stored URLs are Supabase signed URLs that
  expire; viewing from the portal needs the edge-function signed-URL
  refresher (F: `kyc-document-url` function; service key stays server-side).
  Desktop: open in system viewer or embed.
- [ ] **Streaming reads**: screens currently load once + reload after
  mutations. Add Firestore `snapshots()` listeners so a second officer's
  approval appears without refresh.
- [ ] **Read limits/pagination**: reads are capped (orders 500, audit 200,
  announcements 100). Fine at launch; paginate before data grows.
- [ ] **Vendor metrics**: `orders`/`transactions` per vendor fold from the
  capped orders read; move to `salesSummary` rollups for accuracy (F).
- [ ] **Reports / suspensions / notification delivery** have no backend
  collections. Either design them (F: collections + rules/callables) or keep
  them demo-gated behind an explicit "demo data" tag — never seed-looking
  live data.

## 3. Trust & operations (P2)

- [ ] **Windows release build** (`flutter build windows`) — verify desktop
  export paths (`platform_file_saver_desktop.dart`), window min-size,
  app icon/branding, and an installer (MSIX or Inno Setup).
- [ ] **CI for this repo**: analyze + tests on PR (mirror the main repo's
  workflow); branch protection; PRs from fork → upstream
  (`httpsivan/PalangkeGo-Admin`) so the teammate reviews.
- [ ] **App Check for web** (F + here): reCAPTCHA v3 provider once the
  main repo flips `APP_CHECK_ENFORCED` — the callables will demand it.
- [ ] **Audit screen parity**: `adminActions` maps to the generic audit
  model; add renewal-specific action labels + actor emails when useful.
- [ ] **Auth hardening**: password reset flow for the real admin account
  (Firebase Auth handled, but link the flow in UI), session handling on
  desktop (token persistence), sign-out everywhere.

## 4. Design polish (P3)

- [ ] Shell/navigation polish pass (`$impeccable polish admin_shell`):
  active states, density, keyboard navigation.
- [ ] AAA contrast audit across light + dark themes (7:1 body text target
  per PRODUCT.md — verify every `mutedText` usage on tinted surfaces).
- [ ] Overview/sales-report screens were designed against seeded data —
  re-review layouts against real (sparser) data: empty states that teach.
- [ ] Login market-imagery carousel: preloading nine full-res assets on
  desktop is heavy; trim to 3–4 or lazy-load.

## 5. Explicitly not doing (Ponytail verdicts)

- No i18n — single-locale civic tool for MEPO staff.
- No theme engine beyond light/dark already present.
- No custom charting library — tables and the existing summary cards carry
  the revenue story until an actual reporting need arrives.

## Fork workflow (for whoever pushes next)

- `origin` = `MadCheshiren/PalengkeGo-Admin` (your fork),
  upstream = `httpsivan/PalangkeGo-Admin`.
- Push your work: `git push origin main`.
- Pull your teammate's work: add once
  `git remote add upstream https://github.com/httpsivan/PalengkeGo-Admin.git`,
  then `git fetch upstream && git merge upstream/main`.
- The GitHub "Sync fork" button only pulls upstream → fork; it never sends
  your work anywhere. To land your work in the team repo, open a PR
  fork → upstream.
