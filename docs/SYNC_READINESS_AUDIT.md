# DIMI Sync Readiness Audit

Audit scope: current Flutter/Dart source, Drift schema and generated outputs,
Supabase client/auth integration, DAOs/providers/services, and the approved
Phase 1 cloud schema. This is a read-only readiness audit. No sync engine,
outbox, remote data operation, or database operation was added.

## CURRENT STATE

DIMI is still local-first. SQLite/Drift is the runtime source of truth. Supabase
is currently used for Auth/session state and the YouTube Edge Function only. No
application code reads or writes the nine `dim_*` tables through Supabase.

The local database reports schema version 10 in
`lib/data/database.dart`. The v9-to-v10 migration additively adds sync metadata
and unique `server_id` indexes. Generated Drift output in
`lib/data/database.g.dart` contains the current columns and companions.

## LOCAL DRIFT SYNC METADATA

The following tables contain all three sync fields:

| Local table | `server_id` | `updated_at` | `deleted_at` | Ownership/local relationship |
|---|---:|---:|---:|---|
| `local_accounts` | Yes | Yes | Yes | Root local account; `auth_user_id` maps to Supabase `auth.users.id` |
| `profile_data` | Yes | Yes | Yes | Primary key is `local_account_id` |
| `tasks` | Yes | Yes | Yes | `local_account_id` |
| `reminders` | Yes | Yes | Yes | `local_account_id`; optional local `task_id` |
| `notes` | Yes | Yes | Yes | `local_account_id` |
| `money_transactions` | Yes | Yes | Yes | `local_account_id` |
| `merchant_category_rules` | Yes | Yes | Yes | `local_account_id` |
| `youtube_playlists` | Yes | Yes | Yes | `local_account_id` |
| `youtube_videos` | Yes | Yes | Yes | Owned through `playlist_local_id` |

`server_id` is nullable SQLite text, which is appropriate for UUID storage in
SQLite. Each declaration uses Drift `.unique()`, and the v10 upgrade creates a
unique `idx_<table>_server_id` index. Null values remain allowed until a row is
uploaded and assigned a server UUID.

`transaction_detection_events` and `transaction_candidates` intentionally do
not have sync metadata. They remain local-only. `TransactionCandidates` has an
`updated_at` field for local workflow state, but it has no `server_id` or
`deleted_at` and is not a synced entity.

The metadata exists, but it is not operational sync metadata yet:

- No code assigns a Supabase UUID to `server_id`.
- No DAO writes `deleted_at` when a user deletes a row.
- Current delete methods hard-delete rows.
- No outbox, pending-change marker, sync cursor, or retry state exists.
- `updated_at` is not enforced centrally by database trigger or DAO base layer.
- Some mutation paths do not update it, including task completion toggles,
  reminder enable/disable toggles, and note updates.

Relevant definitions and migration:

- `lib/data/database.dart`
- `lib/data/tables/local_accounts.dart`
- `lib/data/tables/profile_data.dart`
- `lib/data/tables/tasks.dart`
- `lib/data/tables/reminders.dart`
- `lib/data/tables/notes.dart`
- `lib/data/tables/transactions.dart`
- `lib/data/tables/transaction_detection.dart`
- `lib/data/tables/youtube_playlists.dart`
- `lib/data/tables/youtube_videos.dart`
- `lib/data/database.g.dart`

## LOCAL ACCOUNT ↔ SUPABASE AUTH

`AuthService.syncLocalProfile()` reads the current Supabase user and calls
`LocalAccountDao.ensureAuthenticatedAccount()` with the Supabase user UUID,
email, display name, and avatar. The local mapping is:

```text
Supabase auth.users.id
        ↓
local_accounts.auth_user_id
        ↓
local_accounts.id = AppDatabase.activeAccountId
        ↓
all local account-scoped rows
```

Authenticated local accounts use `auth_provider = 'supabase'`. Offline accounts
use `auth_provider = 'offline'`. The current code does not merge an offline
account into an authenticated account.

Account lifecycle findings:

- `main()` calls `ensureOfflineAccount()` before checking/restoring the current
  Supabase session. This temporarily activates the offline account on every
  startup.
- Startup drains transaction-detection events before authenticated profile
  synchronization can activate the authenticated account.
- If a session is available, `syncLocalProfile()` then creates/activates the
  matching authenticated local account.
- Auth-state handling in `main.dart` uses unawaited account activation on login
  and logout. Providers can therefore read during the activation window.
- Logout calls Supabase `signOut()` and then `ensureOfflineAccount()`, which
  deactivates other local accounts through `activate()`. It does not delete
  local data.
- `AppDatabase._activeAccountId` starts at `1`; reads before explicit account
  activation can therefore use account 1 as a fallback.
- Existing streams/providers are not globally invalidated by local account
  activation. Long-lived streams created before a switch can retain the prior
  query scope until rebuilt.

This is sufficient for current local account isolation in normal DAO paths, but
it is not yet a synchronization-safe account gate. Sync must wait until the
authenticated local account is activated and must stop before logout completes.

Relevant files:

- `lib/services/auth_service.dart`
- `lib/data/daos/local_account_dao.dart`
- `lib/data/daos/profile_dao.dart`
- `lib/main.dart`
- `lib/config/supabase_config.dart`
- `lib/routing/app_router.dart`
- `lib/providers/database_provider.dart`
- `lib/providers/local_account_provider.dart`
- `lib/screens/settings/settings_screen.dart`

## EXISTING SUPABASE INTEGRATION

`supabase_flutter` is configured in `lib/config/supabase_config.dart` using:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Initialization uses PKCE and forwards `onAuthStateChange` through
`SupabaseBootstrap.authChanges`. Google OAuth is implemented in
`lib/services/auth_service.dart`. The only non-authenticated Supabase data call
found is the YouTube Edge Function invocation in
`lib/features/youtube_playlist/data/youtube_playlist_repository.dart`.

No `client.from(...)`, table repository, pull worker, push worker, outbox
consumer, conflict resolver, or server-side sync function exists in the app.

## WHAT IS READY

- The nine approved synced local entities exist in Drift.
- Local integer primary keys remain intact for SQLite joins.
- Nullable stable `server_id` fields exist and are unique per local table.
- `updated_at` and `deleted_at` exist on every approved synced local table.
- Local account ownership exists for all synced entities, directly or through
  the playlist/task relationship.
- The local account maps to Supabase Auth by `auth_user_id`.
- Finance stores integer `amount_minor` and approved transaction types.
- Planner reminders retain local `task_id`, which can later resolve through the
  task's `server_id`.
- YouTube videos retain playlist ownership and local watch/progress fields.
- The approved cloud schema and RLS are deployed and the two-user RLS test
  passed with 0 failures out of 82 tests.
- Generated Drift code is consistent with the current table definitions after
  code generation; schema version is 10.

## ENTITY AND RELATIONSHIP READINESS

| Entity/relationship | Current sync mapping readiness | Missing or required handling |
|---|---|---|
| Account → profile | Local account ID and profile server IDs exist | Resolve both rows by authenticated `user_id`; do not use profile display data as account identity |
| Account → tasks | Complete local ownership and cloud fields | Assign server ID; tombstone deletes; preserve planner fields |
| Task → reminder | Local `task_id` and cloud relationship are present | Push parent task before reminder; resolve `task_id` through task `server_id`; preserve/delete relationship safely |
| Account → notes | Complete fields and ownership | Update timestamps and tombstone deletes |
| Account → money transactions | Complete fields; detection provenance is local-only | Sync only confirmed transaction row; preserve `amount_minor`; tombstone deletes |
| Account → merchant rules | Complete fields and account uniqueness | Assign server ID; handle unique `(user_id, merchant_identity)` conflicts |
| Account → playlists | Complete local ownership and cloud fields | Map playlist server ID; do not treat API refresh metadata as user mutation blindly |
| Playlist → videos | Local parent FK and cloud parent UUID mapping are present | Sync playlist first; map `playlist_local_id` to playlist server ID; preserve progress fields |

## WHAT IS MISSING

### Sync infrastructure

- No sync repository or service exists.
- No create/update/delete mapping layer exists.
- No server ID allocation/assignment exists.
- No outbox or durable pending mutation queue exists.
- No pull cursor or per-entity sync checkpoint exists.
- No retry, backoff, network reachability, or auth-session gating exists.
- No conflict policy is implemented.
- No tombstone upload/pull handling exists.

### Local mutation readiness

Current DAO deletes are hard deletes in:

- `TaskDao`
- `ReminderDao`
- `NoteDao`
- `MoneyDao`
- `YoutubePlaylistDao`

Hard deletes can cause remote deletion loss or resurrection during a future pull.
They must become account-scoped tombstone operations before synchronization.

`updated_at` is set explicitly by some update methods but not all mutation paths.
The sync layer must either correct every DAO write path or introduce a single
local mutation boundary that always updates it.

## RISKS / BLOCKERS

### Account timing and isolation

Startup and auth-state callbacks can briefly leave the offline or previous local
account active while account-scoped reads or background work run. A sync worker
must not start until account activation completes and must be cancelled/blocked
on logout.

`YoutubePlaylistDao.watchForUser(String userId)` ignores its `userId` argument
and scopes only by `db.activeAccountId`. This is locally safer than trusting a
caller-provided user ID, but the unused parameter can mislead future sync code.

`youtube_playlist_mapper.dart` supplies `localAccountId: 1`; the DAO currently
overrides it with the active account. Future sync code must not reuse that
mapper as an ownership authority.

`MoneyDao.suspiciousDetectedTransactions()` does not filter by
`local_account_id` when reading suspicious rows. Its deletion path is scoped,
but the read itself can inspect another account's data. This is an account
isolation risk to resolve before adding background synchronization or cleanup.

### Deletion and conflict safety

Because current deletes are physical and no outbox exists, the app cannot
reliably tell Supabase that a local record was deleted. Pulling an older cloud
record could recreate a locally deleted row. `updated_at` alone cannot solve
this after the local row has been removed.

### YouTube progress

`YoutubePlaylistDao.savePlaylist()` explicitly preserves existing
`completed`, `watchedAt`, `lastPositionSeconds`, and `progressUpdatedAt` during
API refresh. This is ready for local refresh behavior. A future remote pull
must apply the same rule and must never replace newer local progress with
refreshable playlist metadata. Playlist/video deletion is currently hard
delete, so remote deletion handling is still missing.

### Duplicate and overwrite risk

Local YouTube refresh uses account-plus-YouTube-ID and playlist-plus-video-ID
uniqueness, which prevents ordinary local refresh duplication. A sync layer must
use `server_id` as identity and must not create a second row when a local row
already has a matching server UUID.

`ProfileDao.upsertProfile()` performs local auth/profile replacement and writes
fresh timestamps. It is not a remote sync operation and must not be reused as a
generic pull merge without preserving server IDs and conflict metadata.

### Documentation drift

`docs/TARGET_LOCAL_SCHEMA.md` and parts of older audit documents still describe
the superseded Loans table, `loan_id`, repayment lifecycle, and pre-v9 schema.
They are not current runtime behavior, but they can mislead sync implementation
unless the approved v9 architecture and Phase 1 migration remain the source of
truth.

## EXACT FILES INVOLVED

### Schema and generated Drift

- `lib/data/database.dart`
- `lib/data/database.g.dart`
- `lib/data/tables/local_accounts.dart`
- `lib/data/tables/profile_data.dart`
- `lib/data/tables/tasks.dart`
- `lib/data/tables/reminders.dart`
- `lib/data/tables/notes.dart`
- `lib/data/tables/transactions.dart`
- `lib/data/tables/transaction_detection.dart`
- `lib/data/tables/youtube_playlists.dart`
- `lib/data/tables/youtube_videos.dart`

### DAOs and local data access

- `lib/data/daos/local_account_dao.dart`
- `lib/data/daos/profile_dao.dart`
- `lib/data/daos/task_dao.dart`
- `lib/data/daos/reminder_dao.dart`
- `lib/data/daos/note_dao.dart`
- `lib/data/daos/money_dao.dart`
- `lib/data/daos/transaction_detection_dao.dart`
- `lib/data/daos/youtube_playlist_dao.dart`
- Corresponding generated `*.g.dart` DAO files

### Auth, providers, and services

- `lib/config/supabase_config.dart`
- `lib/services/auth_service.dart`
- `lib/main.dart`
- `lib/routing/app_router.dart`
- `lib/providers/database_provider.dart`
- `lib/providers/local_account_provider.dart`
- `lib/providers/task_providers.dart`
- `lib/providers/money_providers.dart`
- `lib/providers/reminder_providers.dart`
- `lib/providers/note_providers.dart`
- `lib/providers/profile_providers.dart`
- `lib/features/youtube_playlist/providers.dart`
- `lib/features/youtube_playlist/data/youtube_playlist_repository.dart`
- `lib/features/youtube_playlist/data/youtube_playlist_mapper.dart`

### Cloud reference and verification

- `supabase/migrations/20260919000100_dimi_phase1_schema_rls.sql`
- `supabase/tests/dimi_rls_isolation_test.sql`
- `docs/SUPABASE_RLS_ARCHITECTURE_PLAN.md`
- `docs/SUPABASE_PHASE1_IMPLEMENTATION.md`

## RECOMMENDED IMPLEMENTATION ORDER

1. Resolve account-scope prerequisites: make authenticated-account activation
   awaited before scoped startup reads, block/cancel sync on logout, and ensure
   provider streams rebuild on account changes.
2. Correct the unscoped suspicious-finance read and audit all remaining
   account-scoped DAO queries.
3. Add a single local mutation/tombstone boundary for synced entities. Ensure
   every create/update/delete updates `updated_at`, preserves `server_id`, and
   records deletion state without changing current UI behavior.
4. Define and implement the durable outbox/change representation required by
   the approved architecture. It must survive offline operation and row
   deletion.
5. Implement server-ID mapping and idempotent create/update/delete operations,
   starting with accounts/profile and simple entities.
6. Implement dependency-ordered relationship synchronization: account/profile,
   tasks, reminders, notes, finance/rules, playlists, then videos.
7. Add pull/apply logic with tombstone precedence, authenticated ownership,
   last-write/conflict rules, and YouTube progress protection.
8. Add offline/retry/session-switch tests, then integration tests against the
   live Supabase RLS project. Preserve the existing local-first behavior and
   keep detection data local-only.

## READINESS CONCLUSION

The local schema is metadata-ready but the application is not sync-engine-ready.
The next implementation phase requires the account timing fixes, tombstone and
mutation tracking design, server-ID mapping, and conflict/dependency handling
before any Supabase data synchronization is added.
