# DIMI Sync Engine Architecture Review

Review target: `docs/SYNC_ENGINE_ARCHITECTURE.md`

Compared against:

- `docs/SYNC_READINESS_AUDIT.md`
- Current Drift tables, migration strategy, and generated outputs
- `supabase/migrations/20260919000100_dimi_phase1_schema_rls.sql`
- Current Supabase/Auth integration
- Current DAOs, providers, repositories, and services
- Finalized DIMI v9 product decisions

This review is read-only. No application code, Drift schema, Supabase object,
migration, or RLS policy was changed.

## EXECUTIVE RESULT

Status: **NOT READY FOR SYNC IMPLEMENTATION**

The proposed architecture is directionally consistent with the finalized DIMI
design and correctly preserves SQLite as the immediate source of truth. It
cannot safely be implemented yet because several runtime prerequisites and
protocol decisions are unresolved. The most important blockers are account
activation gating, replacement of hard deletes with durable tombstones, a
concrete local outbox design, and a safe remote conflict/version protocol.

## FINDINGS

### 1. Source of truth and local-first behavior — NO ISSUE

**Components:** `SYNC_ENGINE_ARCHITECTURE.md` §1; `lib/data/database.dart`;
all current Drift DAOs/providers.

The design explicitly commits local writes first, keeps SQLite as the immediate
UI source, and treats Supabase as the remote backend. This matches the current
code and the readiness audit. The architecture does not authorize remote data
to replace local UI state before a local transaction succeeds.

### 2. Stable `server_id` mapping — NO ISSUE

**Components:** all nine synced Drift tables; `lib/data/database.dart` v10
migration; Phase 1 `dim_*` tables.

The design correctly keeps integer SQLite IDs local and maps nullable local
`server_id` values to Supabase UUID primary keys. It correctly requires a UUID
to be generated once and reused for retries. Drift declares each local
`server_id` unique and the v10 migration adds unique indexes. Supabase uses UUID
primary keys and direct authenticated ownership.

The implementation must still ensure the UUID assignment and outbox creation
are one local transaction; no current code does this yet.

### 3. Create idempotency — REQUIRED BEFORE IMPLEMENTATION

**Components:** architecture §3 and §6; all current create methods in
`TaskDao`, `ReminderDao`, `NoteDao`, `MoneyDao`, `TransactionDetectionDao`,
and `YoutubePlaylistDao`.

The design correctly requires client-generated UUIDs and retries by the same
`server_id`. However, current DAOs create rows without assigning `server_id`
or recording a pending operation. A sync implementation cannot safely begin
until every synced create path uses a shared transactional mutation boundary.

Required before implementation:

- Assign `server_id` before the local create commits.
- Record the create operation in durable local pending state in the same
  transaction.
- Treat a remote response/retry for the same UUID as the same record.
- Never deduplicate by title, amount, timestamp, playlist position, or array
  position.

### 4. Hard deletes versus tombstones — BLOCKER

**Components:** `TaskDao.deleteTask`, `TaskDao.deleteTaskWithReminder`,
`ReminderDao.deleteReminder`, `ReminderDao.deleteByTaskId`,
`NoteDao.deleteNote`, `MoneyDao.deleteTransaction`,
`YoutubePlaylistDao.deletePlaylist`; local `deleted_at` columns.

The architecture requires setting `deleted_at`, retaining the row, and queuing
a delete. Current DAOs physically delete rows. This can cause remote deletes to
be lost and older cloud rows to be pulled back into SQLite. It also prevents a
delete from being represented if the row is gone before connectivity returns.

The architecture is correct, but implementation is blocked until all synced
delete paths become account-scoped tombstone operations. Planner's existing
future/past deletion rule must remain unchanged: tombstoning must be allowed
only where current product behavior permits deletion.

### 5. Outbox design — REQUIRED BEFORE IMPLEMENTATION

**Components:** architecture §6 and Phase B; `lib/data/database.dart` schema
version 10; no current outbox component.

The design identifies the required logical fields and states, but leaves the
physical representation open. The current database has no outbox, mutation
journal, retry cursor, or sync checkpoint. Since reliable deletion and crash
recovery depend on durable pending state, implementation cannot begin until the
local storage shape is selected and migrated.

The chosen design must specify:

- local table/record identity and account ownership;
- operation coalescing rules;
- crash recovery from `in_flight`;
- pull cursor persistence;
- whether payload snapshots or row re-reads are used;
- cleanup/retention for completed entries;
- migration behavior for existing rows with null `server_id`.

This is a local-only schema decision and does not require a Supabase table.

### 6. Update timestamp coverage — REQUIRED BEFORE IMPLEMENTATION

**Components:** `TaskDao`, `ReminderDao`, `NoteDao`, `MoneyDao`,
`YoutubePlaylistDao`; local `updated_at` fields.

The architecture correctly requires every user-visible mutation to update
`updated_at`. Current implementation does not consistently do so:

- `TaskDao.toggleCompleted` writes completion fields without `updatedAt`.
- `ReminderDao.toggleEnabled` does not write `updatedAt`.
- `NoteDao.updateNote` replaces the row without explicitly refreshing
  `updatedAt`.
- `MoneyDao.updateTransaction` relies on the supplied companion and does not
  enforce a fresh timestamp.
- Playlist refresh/update paths must distinguish metadata refresh from user
  progress and must consistently timestamp the intended mutation.

Before sync, timestamp ownership and mutation coverage must be centralized or
verified for every write path. Otherwise incremental pull and conflict logic
can miss local changes.

### 7. Conflict protocol is underspecified — BLOCKER

**Components:** architecture §8; Phase 1 schema columns
`updated_at`/`deleted_at`; `supabase/migrations/20260919000100_dimi_phase1_schema_rls.sql`.

The document proposes per-row last-write-wins but also states that client clocks
must not be trusted. The deployed schema has timestamps and an update trigger,
but no revision number, compare-and-swap token, server version, or conditional
update RPC. A client cannot safely determine from timestamp comparison alone
whether its base remote row changed, especially under clock skew or equal-time
updates.

Before implementation, choose and document one concrete mechanism, for example:

- a server-authoritative version/conditional update mechanism added by a
  reviewed schema migration; or
- a precisely bounded server-timestamp protocol with defined read-before-write
  and conflict responses.

No schema change is being made in this review, but the current Phase 1 schema
does not by itself provide a complete safe optimistic-concurrency protocol.

### 8. Account isolation and synchronization gate — BLOCKER

**Components:** `lib/main.dart`; `AuthService`; `LocalAccountDao`;
`AppDatabase.activeAccountId`; `lib/providers/*`; `lib/routing/app_router.dart`.

The architecture requires awaited account activation, session capture, and
protection against completion callbacks after logout. Current behavior does not
fully provide that gate:

- Startup activates the offline account before authenticated profile sync.
- Auth-state callbacks call account activation/profile sync with `unawaited`.
- `AppDatabase._activeAccountId` starts at `1` before explicit activation.
- Existing provider streams are not centrally invalidated on account switch.
- Logout switches to offline asynchronously while other reads/background work
  may still be in flight.

The architecture identifies these requirements, but the current code cannot
yet guarantee that a sync result is applied only to the account/session that
started the request. A sync worker must not be implemented until this gate is
made explicit and testable.

### 9. Cross-account remote protection — NO ISSUE in design; REQUIRED locally

**Components:** Phase 1 RLS policies; architecture §§2, 7, and 9;
`supabase/tests/dimi_rls_isolation_test.sql`.

The deployed RLS policies enforce `user_id = auth.uid()`, and the completed
two-user test passed 82/82. The architecture correctly relies on RLS and never
uses a service-role key. It also requires local account/user matching.

The remaining requirement is application-side sequencing: every local pull,
push, and apply transaction must verify the captured `auth.uid()` and active
local account again before commit. RLS alone cannot prevent a stale local
completion callback from writing into the wrong SQLite account.

### 10. Pull/push relationship order — NO ISSUE

**Components:** architecture §7 and §9; Phase 1 foreign keys.

The proposed order is consistent with the schema:

```text
account → profile
account → tasks → reminders
account → notes
account → money transactions
account → merchant rules
account → playlists → videos
```

Tasks precede reminders, and playlists precede videos. The cloud composite
foreign keys preserve same-user task/reminder and playlist/video relationships.
The implementation must resolve local integer relationships to parent
`server_id` UUIDs before pushing children.

### 11. Planner history — NO ISSUE in design; BLOCKER if delete behavior is wrong

**Components:** architecture §§5, 9, 10; `TaskDao`; planner providers and
screens; `tasks.deleted_at`.

The architecture explicitly keeps Planner history permanent and treats UI
visibility/date rules as non-destructive. This matches the agreed behavior.
However, synchronization must not convert past/future filtering or heatmap
windows into deletes. It must also preserve the current rule that certain past
Planner tasks cannot be deleted. Tombstone implementation must be added only to
the permitted delete paths.

### 12. To-Do lifecycle — NO ISSUE in design

**Components:** architecture §10; `TaskDao.watchAllTodos`, completion fields,
and To-Do providers.

The architecture correctly says completed history and the seven-day UI
visibility behavior are not synchronization deletion rules. Pull must restore
completed rows even when they are outside the current UI window. No change to
the product lifecycle is proposed.

### 13. Finance identity and deletion — REQUIRED BEFORE IMPLEMENTATION

**Components:** `MoneyDao`; `money_transactions` local/cloud tables; architecture
§§8–10.

The design correctly preserves permanent user-owned records, `amount_minor`,
and ordinary `expense`, `income`, `lent`, and `borrowed` types. It correctly
excludes detection payloads and Loans.

Implementation must ensure:

- creates retry by `server_id` and never duplicate transactions;
- edits update the same row, not create a replacement;
- explicit deletes become tombstones;
- tombstoned transactions cannot be re-pulled as live rows;
- `detectionCandidateId` is never uploaded as a cloud relationship;
- the suspicious-detection query is account-scoped before sync/background
  cleanup is introduced.

No product contradiction exists, but the current hard-delete and unscoped
suspicious-read paths are not safe for synchronization.

### 14. YouTube progress protection — NO ISSUE in design; REQUIRED in implementation

**Components:** `YoutubePlaylistDao.savePlaylist`, `setCompleted`,
`deletePlaylist`; `youtube_playlists`/`youtube_videos`; YouTube providers and
repository.

The architecture correctly separates refreshable metadata from durable progress
and uses `progress_updated_at` for progress conflict resolution. Current local
`savePlaylist()` already preserves completion, watched time, position, and
progress timestamp during API refresh.

The future sync apply path must preserve that same behavior. It must not apply a
remote metadata row by replacing the entire local video row. It must merge
metadata and progress field groups separately.

The current playlist deletion hard-deletes child videos and parent playlists.
Those operations must become transactional tombstones for sync, while preserving
playlist/video ownership and preventing a stale pull from recreating children.

### 15. Remote schema compatibility — REQUIRED BEFORE IMPLEMENTATION

**Components:** Phase 1 migration; local Drift tables; architecture §§3–9.

The nine cloud tables cover the approved entities and RLS/foreign keys are
consistent. The local-to-cloud field mapping is generally sufficient. However,
the architecture assumes safe conditional conflict handling and durable pull
cursors that are not represented by the current Phase 1 schema. The deployed
schema has `updated_at` and `deleted_at`, but no server revision or sync cursor
contract.

This does not mean the Phase 1 schema is invalid; it means the sync protocol
must either be constrained to what timestamp/RLS operations can safely provide
or receive a reviewed additive schema/API design before implementation.

### 16. Retry and idempotency — NO ISSUE in design; REQUIRED in implementation

**Components:** architecture §6 and §11; no current retry/outbox code;
YouTube repository retry logic.

The architecture correctly reuses the same UUID on retry, coalesces updates,
keeps failed local state, and distinguishes retryable from permanent failures.
This prevents duplicate creates in principle. The current app has no sync retry
worker, so the rules remain unimplemented. In-flight lease/recovery behavior
after process death should be specified before coding.

### 17. Local-only data boundary — NO ISSUE

**Components:** `TransactionDetectionEvents`, `TransactionCandidates`, local
notification state, architecture §10, Phase 1 migration.

The design does not upload raw notification text, source package data,
candidates, notification IDs, schedules, heatmaps, totals, or charts. Confirmed
finance rows remain ordinary money transactions. This matches the finalized
privacy and product decisions.

### 18. Existing sync infrastructure — NO ISSUE

**Components:** `lib/` repositories/services/providers; architecture §6.

There is no existing sync engine, outbox, sync repository, pull cursor,
conflict resolver, or remote CRUD layer to duplicate. Supabase client/auth and
the YouTube Edge Function are not generic synchronization infrastructure.

### 19. Generated Drift/schema consistency — NO ISSUE

**Components:** `lib/data/database.dart`, `lib/data/database.g.dart`, all table
definitions.

The current schema version is 10. The generated database output contains
`server_id`, `updated_at`, and `deleted_at` for the nine approved synced local
tables. The v9-to-v10 migration adds the fields and unique server-ID indexes.
No sync engine should be implemented against generated output without
regenerating it after any future table change.

### 20. Implementation phases — REQUIRED BEFORE IMPLEMENTATION

**Components:** architecture §13; current codebase.

The phase order is sensible and technically implementable, but Phase A must be
completed before Phase B, and Phase B requires an approved local migration for
the outbox/change representation. Phase C cannot safely start while the account
gate and conflict/version protocol remain unresolved.

The phases should therefore be treated as gated milestones, not parallel work:

1. Account activation and local mutation safety.
2. Tombstones, complete timestamp coverage, and durable outbox/cursor design.
3. Authenticated incremental transport with idempotent simple entities.
4. Relationship synchronization.
5. Conflict/deletion hardening.
6. Offline/account-switch/RLS integration verification.

## FINAL CHECKLIST

| Review question | Result |
|---|---|
| Contradicts finalized DIMI decisions? | No direct contradiction found |
| Can sync overwrite SQLite immediately? | Design says no; apply transaction/gating still required |
| Cross-account leakage possible? | RLS is verified; local async account switching remains a blocker |
| Is `server_id` mapping sufficient? | Yes for identity; assignment/transactional persistence missing |
| Are outbox/tombstones specified? | Conceptually yes; physical outbox/crash recovery/retention unresolved |
| Are create/update/delete idempotent? | Design is sound; current DAOs do not implement it |
| Is conflict resolution safe? | Not yet; timestamp-only remote protocol is unresolved |
| Is relationship order correct? | Yes, with dependency mapping required |
| Can Planner history be lost? | Not by design; hard-delete/tombstone implementation must preserve it |
| Can To-Do lifecycle change? | Not by design; pull must not apply UI pruning as deletion |
| Can Finance duplicate/resurrect/delete incorrectly? | Current hard deletes and missing outbox make this possible before implementation |
| Are lent/borrowed ordinary transactions? | Yes |
| Can YouTube progress be overwritten? | Design prevents it; sync apply must merge field groups |
| Are playlist/video deletes safe? | Not currently; tombstone implementation required |
| Is login/logout switching gated? | Not currently; required before sync |
| Can offline rows sync without duplicates? | Yes in design with UUIDs; no current implementation |
| Can retry duplicate writes? | Design prevents this with stable UUIDs; no worker exists |
| Are unlisted schema changes required? | Conflict/version protocol and local outbox need approval/design |
| Are phases implementable? | Yes sequentially, after blockers are resolved |

## STATUS

**NOT READY FOR SYNC IMPLEMENTATION**

Reason: the design is product-consistent, but implementation must first resolve
the account synchronization gate, hard-delete-to-tombstone conversion, durable
outbox/cursor representation, and the safe conflict/version protocol for the
current Supabase schema.
