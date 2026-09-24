# DIMI Local Outbox Implementation Report

## Scope

Implemented only the durable local Drift outbox. No Supabase push, pull,
conflict resolution, remote outbox, RLS, or sync worker was added.

## Table/schema added

Added local Drift table `sync_outbox` and advanced the local database schema
from version 10 to version 11.

Each entry stores:

- local account ID and optional authenticated user ID;
- entity/table name and local row ID;
- nullable `server_id`;
- `create`, `update`, or `delete` operation;
- `pending`, `processing`, `retryable_error`, or `completed` state;
- dependency rank for parent-before-child ordering;
- queued/updated/next-attempt timestamps;
- attempt count and last error;
- optional base remote update timestamp.

Indexes cover ready-queue queries and `server_id` lookup. A unique local
account/entity/row identity coalesces equivalent pending work.

## State and operation model

`SyncOutboxDao` supports:

- enqueue/coalesce;
- ready ordered reads;
- processing transition;
- retryable failure with incremented attempt count and next-attempt time;
- completed marking;
- completed-row removal.

When a row already has a pending create, later updates retain `create`. A
delete supersedes create/update work for that local entity and retains the
same outbox identity.

Dependency ranks are account, profile, task, reminder, note, finance,
merchant rule, playlist, and video. This preserves the required task/reminder
and playlist/video ordering for the future worker.

## Mutation paths integrated

Outbox entries are generated for local mutations in:

- authenticated local accounts and profiles;
- tasks, including completion changes and tombstones;
- reminders, including enable/disable changes and tombstones;
- notes;
- money transactions, including `lent` and `borrowed` records;
- merchant category rules;
- YouTube playlists and videos, including playlist/video tombstones and
  progress updates.

Transaction-detection events and candidates remain local-only and are not
queued. No raw detection payload is added to the outbox.

## Idempotency and local-first behavior

The outbox is SQLite/Drift data, so it survives app restarts, process
termination, and offline periods. It does not perform network work. Existing
local writes and reactive reads remain the immediate UI source of truth.

The future sync worker will use the outbox's stable local identity and
`server_id` to perform idempotent remote operations. This phase does not
assign missing server UUIDs or push rows.

## Tests added

`test/local_database_v9_test.dart` now covers:

- create enqueue;
- update coalescing with an existing create;
- delete/tombstone superseding earlier work;
- authenticated account/profile representation;
- task-before-reminder dependency rank;
- retry state, error, and attempt count;
- completed marking and safe removal;
- persistence after closing and reopening a file-backed database.

## Verification results

- Build runner: completed successfully and generated the updated Drift output,
  including `lib/data/database.g.dart` and
  `lib/data/daos/sync_outbox_dao.g.dart`.
- Narrow Dart analysis: passed with no errors for the outbox, database, DAOs,
  and focused tests.
- Full Dart analysis: no errors; existing warnings/infos remain.
- Flutter focused tests: attempted once with `--no-pub` and suppressed
  analytics, but the Flutter command produced no output or completion within
  the wait window. It appears to be the existing environment/tooling hang,
  not a reported test failure.

## Remaining blockers

- Flutter test execution still needs to run successfully in a working Flutter
  environment.
- Server UUID assignment, outbox payload serialization, remote push/pull,
  account/session gating, conflict handling, and cursors remain intentionally
  unimplemented for later phases.
- The outbox is local infrastructure only; no Supabase objects were changed.
