# DIMI Tombstone Implementation Report

## Scope

This step implements only local tombstone/deletion handling for the existing
Supabase-synced entities. It does not add an outbox, pull cursor, conflict
resolver, sync service, migration, Supabase schema change, or RLS change.

## Files changed

- `lib/data/daos/task_dao.dart`
- `lib/data/daos/reminder_dao.dart`
- `lib/data/daos/note_dao.dart`
- `lib/data/daos/money_dao.dart`
- `lib/data/daos/transaction_detection_dao.dart`
- `lib/data/daos/youtube_playlist_dao.dart`
- `test/local_database_v9_test.dart`

## Tables/entities affected

- `tasks`: future deletions now set `deleted_at` and `updated_at`; past Planner
  entries remain protected; active task reads exclude tombstones.
- `reminders`: direct deletion and task-linked deletion now tombstone rows;
  notification scheduling and active reads exclude tombstones; linked reminder
  tombstoning is transactional with task tombstoning.
- `notes`: deletion now updates the existing row instead of physically
  deleting it; note counts and normal reads exclude tombstones.
- `money_transactions`: existing explicit deletion remains a tombstone and
  SQL totals now exclude tombstoned rows.
- `merchant_category_rules`: active category lookup excludes tombstones.
- `youtube_playlists` and `youtube_videos`: playlist deletion tombstones the
  playlist and all active child videos in one transaction; normal playlist and
  video reads exclude tombstones; watched/progress fields are not changed.

`local_accounts` and `profile_data` had no user-facing hard-delete path to
convert in this step. Transaction-detection events/candidates remain
local-only and retain their existing expiry cleanup behavior.

## Delete paths audited

- Planner/To-Do task deletion and task deletion with linked reminder.
- Reminder deletion by ID and by task ID.
- Note deletion.
- Explicit finance transaction deletion and suspicious detected-transaction
  cleanup through the finance tombstone path.
- YouTube playlist deletion and its child-video relationship.
- Merchant rule reads used by transaction detection.
- Normal reads/providers represented by the audited DAOs.

## Tests added/updated

`test/local_database_v9_test.dart` now verifies:

- task and linked reminder rows remain present after deletion;
- `deleted_at` is set;
- `server_id` is preserved;
- `updated_at` advances;
- normal task/reminder queries hide tombstoned rows;
- playlist and video rows remain present after playlist deletion;
- playlist/video `server_id` values are preserved;
- YouTube completion/progress fields remain unchanged;
- normal YouTube queries hide tombstoned rows.

## Verification

- `build_runner`: not required; no Drift table definition or schema version was
  changed.
- Targeted Dart analysis: the modified tombstone paths and test have no
  tombstone-related type errors. The repository still has the pre-existing
  `Future<int>` versus `Future<bool>` errors in
  `MoneyDao.updateTransaction` and `NoteDao.updateNote`.
- `flutter test test/local_database_v9_test.dart`: could not complete in the
  current environment because the Flutter command produced no output or
  completion after repeated 30-second waits, including with `--no-pub` and
  analytics disabled.
- `flutter analyze`: the repository remains blocked by the two pre-existing
  DAO return-type errors above, plus existing warnings/infos. No new
  tombstone-specific analyzer error remains.

## Remaining blocker

The tombstone implementation is complete for this step. Full green test and
analyze results remain blocked by the pre-existing Flutter command hang and
the unrelated `Future<bool>` DAO signatures noted above. The outbox, pull
cursor, conflict protocol, and sync service blockers remain intentionally
unimplemented for later phases.
