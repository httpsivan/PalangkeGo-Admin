# Design

Derived from the existing theme system (`lib/core/theme/`) plus the 2026-08
civic-professional pass. Register: **product** (see PRODUCT.md).

## Theme

Light and dark themes (`buildLightTheme` / `buildDarkTheme`), semantic colors
via the `AppSemanticColors` ThemeExtension. The login screen intentionally
locks to the light theme even when the dashboard preference is dark.

- **Personality**: civic-professional — calm, authoritative, institutional.
  The city market's operations console, not a startup dashboard.
- **Anti-references**: SaaS-template feel (glassmorphism, gradient accents,
  floating stat cards), toy-like playfulness. Tables and decisions are the
  product.
- **Accessibility**: body text targets WCAG AAA (7:1) contrast; no
  color-only status signals; keyboard-complete forms; reduced-motion
  respected via short, purposeful transitions only.

## Color

Restrained strategy: one accent for primary actions and current selection;
state vocabulary (success/danger/warning containers) carries status, never
decoration. Dark theme uses deep neutrals with `success = #42E6AA` for
confirmed states; light theme mirrors the same semantic roles.

## Typography

Google Fonts (`Plus Jakarta Sans` family per the dashboard's existing
`google_fonts` usage), one family across headings, labels, and data.
Fixed scale (no fluid sizing — desktop DPI is consistent): 10px badge/eyebrow,
11–12px labels and meta, 14–16px body, 18–24px screen titles. Weight — not
size or color — creates hierarchy in dense tables.

## Components

- Login: split layout — market imagery panel (51%) + focused form (49%),
  collapses to single column under 820px. Demo credential prefill is
  **demo-mode-only**; Firebase mode never pre-fills a password. Mode badge
  (`_ModeBadge`) states honestly: "Live · City of Naga market data" vs
  "Demo · seeded data".
- Buttons: `FilledButton` with `AnimatedButtonFeedback` (press feedback);
  44px height; loading swaps label for an inline spinner — never a blocking
  modal.
- Tables: dense, sortable, sticky headers where long; status shown as
  badge + text (never color alone).
- Motion: 150–250ms, ease-out curves (`app_motion.dart`); state change and
  feedback only — no orchestrated page-load sequences.

## Layout

Desktop-first shell with side navigation (collapsible), content max-width
constrained for prose, full-bleed for tables. Responsive behavior is
structural (column collapse), not typographic.
