# DIMI Sync Engine Architecture

Status: design only. No sync engine, outbox, database table, Supabase schema,
RLS policy, or application code is implemented by this document.

This design follows [SYNC_READINESS_AUDIT.md](SYNC_READINESS_AUDIT.md), the
approved v9 local-first behavior, and the deployed Phase 1 Supabase schema/RLS.

## 1. SOURCE OF TRUTH

Drift/SQLite remains the immediate source of truth for the running app:

- UI reads come from local Drift providers.
- Local writes commit before any network operation.
- The app remains fully usable offline.
- Supabase is the authenticated remote synchronization backend, not the
  runtime database.
- A failed or unavailable sync operation must never block or roll back an
  already-committed local user action.

Supabase is authoritative for the remote copy and ownership boundary. RLS is
always relied on for remote access; the client never uses a service-role key.

## 2. IDENTITY AND ACCOUNT BOUNDARY

Local integer primary keys remain local-only. Every synced local row uses:

```text
local integer id       = SQLite identity
local server_id UUID   = Supabase row id
Supabase user_id       = authenticated auth.uid()
```

For legacy local rows whose `server_id` is null, the sync layer generates a
cryptographically random UUID once, stores it locally, and uses that same UUID
for all future operations. It never derives identity from array position,
timestamps, hashes, content, or row order.

The local account mapping is:

```text
auth.uid()
  → local_accounts.auth_user_id
  → local_accounts.id
  → local_account_id on local rows
```

Offline accounts remain isolated. Signing into Google never automatically
merges or reassigns offline rows. A sync run is allowed only when:

1. Supabase has a valid authenticated session.
2. The matching local account has been activated and is the current
   `AppDatabase.activeAccountId`.
3. The sync request captures that local account ID and Supabase user ID and
   verifies they still match before applying results.

Logout cancels/blocks in-flight synchronization, switches the local active
account to the offline account, and prevents completion callbacks from applying
rows to the former account.

## 3. CREATE FLOW

Every local create follows this order:

1. Validate the current active account and create the row in SQLite.
2. Generate and persist `server_id` in the same local transaction if it is
   absent.
3. Update `updated_at` in UTC and leave `deleted_at` null.
4. Add an outbox entry in the same SQLite transaction.
5. Return immediately to the UI.
6. When an authenticated network is available, push the outbox item using the
   stored `server_id` as the remote UUID.
7. Insert/upsert the Supabase row with `user_id = auth.uid()`.
8. On success, record the acknowledged remote timestamp and mark the outbox
   item complete. The local integer ID remains unchanged.

Client-generated UUIDs are required for offline idempotency. A retry therefore
uses the same remote primary key and cannot create a duplicate row.

For existing local data during first sync, UUID assignment and outbox creation
must happen in bounded account-scoped batches. No content-based deduplication or
automatic account merge is allowed.

## 4. UPDATE FLOW

1. Read and validate the row under the active local account.
2. Apply the local mutation in SQLite.
3. Set `updated_at` to the current UTC time and preserve `server_id`.
4. Add or coalesce an outbox update for that row, retaining the earliest
   required base remote version and the latest local payload.
5. Push by `server_id` only after account/session validation.
6. Apply the remote update with the authenticated user ownership supplied by
   RLS; never accept a caller-provided foreign `user_id`.
7. Store the remote acknowledgement/version locally and remove the completed
   outbox state.

The sync layer must not use `created_at` as an update marker. Every user-visible
mutation, including completion toggles and reminder enable/disable changes,
must update `updated_at` before it can be synchronized.

## 5. DELETE FLOW AND TOMBSTONES

Synced rows must not be physically deleted as the first local operation.

1. Verify ownership using the active local account.
2. Set `deleted_at` and `updated_at` locally in the same transaction.
3. Create an outbox delete/tombstone operation in that transaction.
4. Hide tombstoned rows from normal UI queries while retaining the row for
   synchronization.
5. Push the tombstone to Supabase by `server_id`.
6. Pulls apply a remote tombstone locally and never replace it with an older
   live row.
7. Remove local dependent notification state when a reminder tombstone is
   applied.

Remote deletion propagation uses the deployed nullable `deleted_at` field. A
remote tombstone is not physically compacted until every supported client has
passed the relevant pull cursor/retention boundary. The retention period is an
open operational decision.

If a user intentionally recreates content after deletion, it receives a new
local row and new `server_id`; the old tombstoned identity is never resurrected.

## 6. OUTBOX / PENDING SYNC

The current app has no outbox. The eventual implementation needs a local-only,
durable change queue. It must not be a Supabase table or expose detection data.

Minimum logical outbox fields:

| Field | Purpose |
|---|---|
| local integer ID | Local row lookup; never remote identity |
| entity/table name | Routes serialization and dependency handling |
| `server_id` | Idempotent remote identity |
| local account ID | Prevents cross-account processing |
| Supabase user ID | Session/account assertion |
| operation | `create`, `update`, or `delete` |
| base remote `updated_at` | Detects an edit made remotely after the local base |
| attempt count | Retry control |
| next attempt time | Backoff scheduling |
| state | Pending lifecycle state |
| last error | Diagnostics without blocking UI |
| created/updated times | Queue ordering and cleanup |

Required states:

- `pending`: local mutation waiting to push.
- `in_flight`: currently being attempted by the serialized worker.
- `blocked_dependency`: parent row must be pushed first.
- `conflict`: remote changed after the local base; requires conflict policy.
- `retryable_error`: network/temporary server failure.
- `permanent_error`: invalid payload or constraint failure requiring repair.
- `complete`: acknowledged and eligible for removal after diagnostics/retention.

Multiple local edits to the same row should coalesce into one pending payload,
while retaining the original base remote version. A delete supersedes earlier
pending create/update operations for that row but retains the row tombstone.

Retry rules:

- Retry network timeouts, 5xx responses, rate limits, and temporary auth/session
  availability failures with bounded exponential backoff and jitter.
- Refresh the session before retrying an expired access token.
- Do not retry malformed payloads indefinitely; mark them `permanent_error` and
  keep the local row usable.
- Retry creates with the same `server_id` and use upsert/idempotent handling.
- Never retry under a different active account.

## 7. PUSH / PULL ORDER

Sync is serialized per authenticated local account. Each run uses incremental
queries by `updated_at`/cursor and never scans the entire database by default.

### Pull order

1. `dim_accounts`
2. `dim_profile_data`
3. `dim_tasks`
4. `dim_reminders`
5. `dim_notes`
6. `dim_money_transactions`
7. `dim_merchant_category_rules`
8. `dim_youtube_playlists`
9. `dim_youtube_videos`

Apply each batch inside a local SQLite transaction, and advance the pull cursor
only after the transaction commits. All rows must be filtered to the current
authenticated owner. Pull tombstones before/alongside live rows according to
the same cursor so an older live row cannot resurrect a deleted row.

### Push order

1. Account identity mapping.
2. Profile data.
3. Tasks, including Planner entries.
4. Reminders after their task `server_id` is available.
5. Notes.
6. Money transactions.
7. Merchant category rules.
8. YouTube playlists.
9. YouTube videos after their playlist `server_id` is available.

Independent entities may be batched, but parent/child dependencies must be
serialized. A failed child push does not delete or hide a successfully pushed
parent.

## 8. CONFLICT STRATEGY

Use a simple per-row optimistic last-write-wins policy; do not introduce CRDTs,
event sourcing, or an event log.

1. The outbox records the remote `updated_at` observed when the local edit was
   based.
2. Before applying a remote update, compare the remote row with the local base.
3. If the remote row has not changed, push the local row.
4. If both sides changed, compare UTC `updated_at` values.
5. The newer mutation wins. Equal timestamps use deterministic remote-wins
   behavior.
6. Record the conflict outcome for diagnostics and remove/replace the outbox
   item only after the local row reflects the selected winner.

Remote timestamps returned by Supabase are authoritative for remote versions;
client clocks must not be trusted for ownership or security. Clock skew and the
exact conditional-update mechanism are implementation decisions to validate
against the deployed schema before coding.

Deletion conflict rule:

- A tombstone wins over an older live row.
- A live edit made after a known tombstone is a new record, not a resurrection
  of the deleted `server_id`.
- Equal-time delete/live conflicts resolve to delete.

### YouTube conflict rule

YouTube data is merged by field group:

- Playlist/video title, thumbnail, duration, position, and refresh metadata are
  refreshable metadata.
- `completed`, `watched_at`, `last_position_seconds`, and
  `progress_updated_at` are durable user progress.
- The newest `progress_updated_at` wins for progress fields.
- A metadata refresh must never clear or replace newer progress.
- Playlist/video parent identity always remains authoritative over refresh order.

## 9. RELATIONSHIPS

### Account → profile

Create/pull the account mapping before profile data. Resolve profile ownership
from the authenticated Supabase user and local account, not display name/email.
Profile fields merge independently from Auth identity fields.

### Account → tasks

Tasks map by `server_id` and local account. Planner history remains permanent;
the UI's future/past visibility rules are not sync deletion rules.

### Task → reminder

Push the task first. Resolve the reminder's cloud `task_id` from the local
task's `server_id`. Pull tasks before reminders. If a task is tombstoned, its
linked reminder is tombstoned/cancelled according to the approved Planner rule;
the local notification ID is never uploaded.

### Account → notes

Notes sync as independent account-owned rows by `server_id`. Content edits use
the common timestamp/conflict rules.

### Account → money transactions

Only confirmed `money_transactions` rows sync. `amount_minor`, currency, type,
category, note, counterparty, occurred time, and source are preserved.
`expense`, `income`, `lent`, and `borrowed` remain ordinary transaction types.
There is no Loans entity or repayment lifecycle. Detection payloads,
notification text, candidates, and candidate IDs remain local-only.

### Account → merchant rules

Rules sync after account mapping. The unique `(user_id, merchant_identity)`
constraint is handled as an idempotent update of the same rule, not a duplicate.

### Account → playlists → videos

Push/pull playlists before videos. A video always resolves its playlist through
the playlist's `server_id`; direct user ownership is still supplied for RLS.
Remote metadata application must preserve local watch/progress state.

## 10. FEATURE-SPECIFIC RULES

- Planner history is permanent. Past/future display behavior remains local UI
  behavior and must not cause historical rows to be deleted.
- To-Do lifecycle remains intact, including completed-row history and the
  existing visibility window. Visibility pruning is not synchronization delete.
- Reminders sync intent, schedule, enabled state, and optional `task_id` only.
  Device notification IDs and schedules remain local and are rebuilt after a
  successful local pull/apply.
- Finance records remain permanent until explicit user deletion. Edits update
  the same `server_id`. Lent/borrowed are ordinary money transactions.
- Raw transaction detection events and candidates never upload. A confirmed
  transaction may sync without detection payload or candidate foreign key.
- Notes sync as durable user content.
- YouTube API refresh metadata is not a replacement for user watch progress.
- Heatmap cells, totals, charts, and other derived data are never synced.

## 11. OFFLINE BEHAVIOR

### Create offline

Commit the row, assign a stable UUID, and enqueue a pending create locally.
The UI immediately reads the row from SQLite.

### Edit offline

Update SQLite, refresh `updated_at`, and coalesce/update the existing outbox
entry. The latest local edit remains visible immediately.

### Delete offline

Set `deleted_at`, update `updated_at`, enqueue a delete, and hide the row from
normal queries. Do not physically remove the row until safe tombstone cleanup.

### Internet returns

After a valid authenticated session and active-account check, pull the bounded
remote window, apply dependencies/tombstones locally, then push pending local
changes in dependency order. The worker is serialized per account.

### Sync fails

Keep local state and the pending outbox entry. Retry only retryable failures.
Show a non-blocking sync status; do not replace local data with an empty or
partial remote response. Permanent errors remain diagnosable and require a
repair path rather than infinite retries.

## 12. PERFORMANCE

- Use per-account incremental pulls by cursor/`updated_at`.
- Push only pending outbox rows, coalesced by entity and `server_id`.
- Batch independent rows while preserving relationship order.
- Process large first-sync datasets in bounded pages and local transactions.
- Avoid full-database scans on app startup or every foreground event.
- Keep notifications, detection processing, heatmaps, totals, and charts local.
- Never block first-frame UI rendering on a complete cloud synchronization.

## 13. IMPLEMENTATION PHASES

### Phase A — local safety prerequisites

- Fix account activation timing and provider invalidation on auth/account switch.
- Scope the suspicious-finance read to the active account.
- Ensure every synced mutation updates `updated_at`.
- Define tombstone visibility in local queries without changing product rules.

### Phase B — local sync metadata/outbox

- Add the approved local outbox/change representation through a migration.
- Add transactional mutation helpers for create/update/tombstone operations.
- Add server-ID assignment for new and legacy rows.
- Add unit tests for coalescing, retries, account ownership, and tombstones.

### Phase C — authenticated sync foundation

- Add session/account gating and a serialized per-account worker.
- Add incremental pull cursor storage and authenticated Supabase table access.
- Implement idempotent account/profile and simple entity create/update/pull.

### Phase D — relationship synchronization

- Add tasks and reminders with dependency resolution.
- Add notes, money transactions, and merchant rules.
- Add playlists and videos with parent mapping and progress protection.

### Phase E — conflict/deletion hardening

- Implement conditional conflict detection and deterministic winner rules.
- Implement tombstone pull/push, notification cancellation, and retention.
- Add retry/error telemetry without uploading local-only sensitive data.

### Phase F — verification and rollout

- Test offline create/edit/delete and reconnect behavior.
- Test account switching/logout during active sync.
- Test duplicate retry/idempotency and remote conflict cases.
- Run live two-user RLS regression tests.
- Roll out behind a controlled sync feature flag while SQLite remains primary.

## 14. OPEN QUESTIONS

These items are not fully determined by the current codebase or completed audit:

1. Should the outbox be a dedicated local Drift table, or should an equivalent
   per-row change journal be used? A durable mechanism is required, but its exact
   local schema is not approved yet.
2. What tombstone retention period and cursor guarantee allow safe compaction
   across all supported app versions/devices?
3. Should sync use direct authenticated Supabase table calls, a dedicated Edge
   Function, or a combination for batching? Direct RLS-protected calls are the
   default design; no service-role client is permitted.
4. What exact server-side conditional update/version mechanism should be used
   with the current timestamp-only schema to avoid client-clock skew?
5. Should conflict outcomes be silently resolved by last-write-wins or shown in
   a user-visible sync status for finance/profile edits?
6. What is the approved behavior for a task deletion when multiple reminders
   exist, if future product behavior permits more than the current local
   one-reminder lookup?
7. Should legacy local rows be uploaded automatically on first authenticated
   sync, or require an explicit user-approved backup/sync action? This must not
   merge offline and Google accounts silently.
8. What remote pagination/window size and foreground/background scheduling are
   appropriate for the target device population?

## FINAL DESIGN POSITION

DIMI should implement a serialized, account-scoped, incremental outbox-based
sync worker that treats SQLite as the immediate source of truth, uses stable
UUID `server_id` values for idempotency, propagates tombstones, synchronizes
relationships in dependency order, and protects YouTube progress by field-group
merging. The implementation must wait for the open decisions above and the
local account/tombstone prerequisites; this document does not authorize sync
implementation by itself.
