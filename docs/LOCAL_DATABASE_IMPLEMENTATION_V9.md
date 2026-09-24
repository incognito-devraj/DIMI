# DIMI Local Database v9 Implementation

Status: implemented locally; cloud sync and Supabase integration remain out of scope.

## Schema and migration

`AppDatabase.schemaVersion` is 9. Drift's `MigrationStrategy` performs a v8 → v9
upgrade in place. Existing profile, task, reminder, note, finance, playlist,
video, detection, candidate, and merchant-rule rows are retained and receive
the new ownership/timestamp columns with deterministic defaults. The obsolete
`class_sessions`, `study_sessions`, `courses`, and `document_meta` tables are
dropped intentionally; no replacement tables are created.

The old singleton profile is split into `local_accounts` and `profile_data`:
identity fields are stored on the account, while role, phone, college,
semester, and points remain profile data. The unused quote is not migrated.

## Implemented local behavior

- Active local account resolution is provided by `LocalAccountDao` and its
  Riverpod provider; user-owned DAOs scope reads and writes by active account.
- Tasks use `local_date`, `due_time_hhmm`, and update timestamps. Completed To-Dos
  remain stored; active queries show incomplete items and items completed today.
- Planner/reminder records include account ownership, nullable `task_id`, and a
  separate notification identifier.
- Finance stores integer minor units in `amount_minor`, uses `INR` by default,
  and supports exactly `expense`, `income`, `lent`, and `borrowed`. Notes remain
  permanent transaction context.
- YouTube playlist refreshes upsert metadata while preserving video progress;
  missing API videos are retained and explicit playlist deletion removes child
  videos.
- Detection events/candidates have account ownership, expiration timestamps,
  and indexed retention paths.
- Merchant rules are unique per `(local_account_id, merchant_identity)`.
- The seven-day To-Do purge and legacy demo cleanup startup behavior were
  removed.

## Verification

Drift generation was run with the project's `build_runner` command. Static
analysis was run against `lib` and `test`; there are no analyzer errors, though
existing warnings/info diagnostics remain. Full Flutter tests and debug APK
build still need to be run after the remaining application-level migration
coverage is added.

## Known limitations

The migration currently uses the existing local account as the deterministic
backfill account (`id = 1`) and preserves legacy columns where SQLite requires
an in-place compatibility step. Additional multi-account migration fixtures
and UI-level aggregate queries should be expanded in the next validation pass.
