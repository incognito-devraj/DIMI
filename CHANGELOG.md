# Changelog

All notable DIMI releases are documented here.

## [1.0.2] — 2026-10-14

### Improved

- Refined the Home dashboard playlist card, progress details, category icons,
  reminders, finance summary, and responsive card layout.
- Improved To-Do and Notes presentation, task checkbox sizing, task deletion
  confirmation, title typography, and Tasks/Notes switching.
- Added smoother press feedback across actions and settings controls.
- Improved Finance transaction filtering, search layout, keyboard handling,
  result transitions, and transaction action buttons.
- Stabilized card backgrounds and content clipping during loading and route
  transitions.
- Notes now trigger an immediate background sync after create, edit, or delete,
  preventing recent edits from being lost when app storage is cleared or the
  account is opened on another device.
- Refined the splash handoff and removed startup route fades that could expose
  a blank platform frame.
- Added compact, official GitHub, Instagram, LinkedIn, and X footer logos with
  working profile links.
- Updated reminder defaults, the end-of-day moon asset, and Rhythm heatmap
  labels.

### Update delivery

- The in-app updater now downloads the exact APK asset returned by the GitHub
  release API instead of resolving a second moving `latest` URL.
- Release documentation and APK naming are aligned with the `DIMI.apk` asset
  used by the Android build.

## [1.0.1] — 2026-10-04

- Previous public release.
