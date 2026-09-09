# Tech Stack

These choices are fixed. Do not substitute alternatives (e.g. do not swap in
Firebase, Hive, sqflite raw, Provider, BLoC, etc.) unless the user explicitly
asks to change stack.

## Framework
- **Flutter** (stable channel), targeting iOS and Android from one codebase.
- Null-safety, Dart 3.x idioms throughout.

## Local database
- **drift** (https://drift.simonbinder.eu/) on top of SQLite. This is the
  single source of truth for all app data. Every screen reads/writes through
  drift, never through ad-hoc files or SharedPreferences (SharedPreferences
  is only acceptable for tiny UI-only settings like theme mode).
- Schema lives in `lib/data/database.dart` plus one table file per entity
  under `lib/data/tables/`.
- Use drift's generated type-safe queries and reactive `Stream` watchers so
  UI auto-updates when data changes (no manual refresh calls).

## State management
- **Riverpod** (flutter_riverpod). Providers wrap drift's reactive streams
  directly where possible (e.g. `StreamProvider` over a DAO watch query).

## Navigation
- **go_router**, with the 5-tab bottom navigation (Home, Planner, College/
  Classes, Study or context-relevant 4th tab, More) matching each screen's
  bottom bar in the mockups — note the active tab differs per section (e.g.
  Money screens show a Money tab, Study screens show a Study tab). Build one
  shared `AppScaffold` that takes the current tab as a parameter rather than
  duplicating the bottom bar per screen.

## No backend, initially
- No API calls, no auth, no cloud sync in the first build. Build the entire
  app against the local drift database only. A sync module may be added
  later behind an interface (see design.md) — do not pre-build it now.

## Design tokens
- Define all colors, spacing, radii, and text styles in
  `lib/theme/app_theme.dart` as a single `ThemeData`. Never hardcode hex
  colors or font sizes inside widgets — always reference the theme.
- See `assets/style-guide.md` for the extracted token values.

## Package list (starting point)
```
drift
sqlite3_flutter_libs
path_provider
path
flutter_riverpod
go_router
intl
fl_chart      # for the bar/progress charts on Home, Study, Money
```
