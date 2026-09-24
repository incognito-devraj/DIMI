# DIMI Supabase/RLS Architecture Plan

Status: read-only architecture plan. No Supabase objects, policies, code, or
configuration are created by this document.

This plan is based on the current local Drift v9 implementation, the v9 local
schema documentation, and the current auth/notification/YouTube code. The
current product model is local-first. Finance uses `money_transactions` with
`expense`, `income`, `lent`, and `borrowed`; there is no cloud `loans`
entity or repayment lifecycle.

## Current local architecture

- `AppDatabase` is one local SQLite/Drift database, schema version 9.
- `local_accounts.id` is the local integer account key. Authenticated accounts
  are identified locally by `(auth_provider, auth_user_id)`; Supabase Auth owns
  the authoritative user UUID.
- User-owned local rows are scoped by `local_account_id`. YouTube videos are
  owned through their account-owned playlist.
- Providers and DAOs read/write locally. There is currently no sync queue,
  server ID, cloud cursor, tombstone, or Supabase data repository.
- Supabase is currently used only for authentication and the YouTube Edge
  Function call. The publishable key is supplied with `--dart-define`.
- Android notification events are collected locally, parsed locally, and may
  produce a confirmed `money_transactions` row. Raw event/candidate records
  contain notification text, package names, references, account hints, and
  balance information.

## 1. Sync scope

| Local table/data | Cloud sync | Reason and boundary |
|---|---:|---|
| `local_accounts` | Partial | Sync the authenticated identity mapping and display/avatar fields through a cloud account/profile row. Offline-only accounts remain local and isolated from Google accounts. `is_active` is device-local and never syncs. |
| `profile_data` | Yes, for authenticated users | User profile fields are durable user data and should follow the authenticated account. `points` syncs only if it remains a user-owned product field. |
| `tasks` | Yes | To-Dos and Planner events are primary user data, including completed history and heatmap inputs. |
| `reminders` | Yes, excluding device fields | Reminder intent, schedule, enabled state, and optional Planner relationship sync. `notification_id` is a local OS handle and stays local. |
| `notes` | Yes | Notes are durable user content. |
| `money_transactions` | Yes, authenticated users | Finance history is explicit user data. Store minor units and currency exactly. No loan table is introduced. `detection_candidate_id` must not become a cloud link to local detection data. |
| `youtube_playlists` | Yes, selectively | Sync the user’s saved playlist identity and local cache metadata so the list can restore across devices. The YouTube API remains the source for refreshable metadata. |
| `youtube_videos` | Yes, selectively | Sync durable watch/progress state and enough metadata for offline display. Refreshable metadata may be re-fetched and must never overwrite progress. |
| `merchant_category_rules` | Yes | These are durable user preferences and are already account-scoped. |
| `transaction_detection_events` | No | Raw notification payloads and source package data are sensitive, device-specific, transient, and unnecessary after local processing. |
| `transaction_candidates` | No | Candidates contain raw financial-detection context, confidence, bank/reference details, balance-after data, and retention-only workflow state. Keep them local. |
| Android notification schedules and `notification_id` | No | OS/device state cannot be meaningfully shared between devices. Recreate local notifications from synced reminders after pull. |
| Heatmap cells, totals, charts | No | Derived from synced/local tasks and transactions. Never store as authoritative cloud data. |
| Deleted/removed legacy feature tables | No | `class_sessions`, `study_sessions`, `courses`, and `document_meta` are not active v9 product data. |

Only confirmed financial rows are eligible for sync. Automatic detection is a
local acquisition path, not a cloud data source.

## 2. Proposed Supabase schema

Cloud IDs are UUIDs. Local integer IDs remain local and are never used as
cross-device identity.

### Identity and profile

`dim_accounts`

- `user_id uuid primary key references auth.users(id) on delete cascade`
- `display_name text not null default ''`
- `avatar_url text null`
- `created_at timestamptz not null`
- `last_login_at timestamptz null`
- `updated_at timestamptz not null`

`dim_profile_data`

- `user_id uuid primary key references dim_accounts(user_id) on delete cascade`
- `role text not null default ''`
- `phone text not null default ''`
- `college text not null default ''`
- `semester text not null default ''`
- `points integer not null default 0`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`

The local authenticated `local_accounts.auth_user_id` maps to
`dim_accounts.user_id`, which is the same UUID as `auth.users.id`. Email should
be read from `auth.users`/trusted auth views rather than treated as editable
profile data.

### User-owned entities

Each table below has:

- `id uuid primary key default gen_random_uuid()`;
- `user_id uuid not null references auth.users(id) on delete cascade`;
- `created_at timestamptz not null`;
- `updated_at timestamptz not null`;
- optional `deleted_at timestamptz` for tombstones.

Each syncable local table receives a nullable `server_id UUID`. Once assigned,
that value is the cloud row's UUID primary key and is the only cross-system
record identity. Local integer primary keys remain unchanged and continue to
serve local SQLite joins. `server_id` is never derived from array position,
timestamps, hashes, or mutable content. A future local sync migration must
also make `server_id` unique within each local table.

`dim_tasks`

- `user_id`, `id` (the local row's `server_id`)
- `title`, `description`, `category`
- `is_planner_entry`, `local_date date`, `due_time_hhmm text null`
- `is_completed`, `completed_at`
- timestamps and `deleted_at`

`dim_reminders`

- `user_id`, `id` (the local row's `server_id`)
- `task_id uuid null references dim_tasks(id) on delete set null`
- `title`, `due_at timestamptz`, `is_enabled`
- timestamps and `deleted_at`
- no `notification_id`

`dim_notes`

- `user_id`, `id` (the local row's `server_id`)
- `title`, `content`, `category`
- timestamps and `deleted_at`

`dim_money_transactions`

- `user_id`, `id` (the local row's `server_id`)
- `type text` constrained to `expense`, `income`, `lent`, `borrowed`
- `amount_minor bigint`, `currency char(3)`
- `category`, `note`, `counterparty`
- `occurred_on timestamptz`, `source`
- timestamps and `deleted_at`
- no `loan_id`, loans table, repayment status, or repayment balance
- no raw detection payload and no foreign key to local candidates

`dim_merchant_category_rules`

- `user_id`, `id` (the local row's `server_id`)
- `merchant_identity`, `category`
- unique `(user_id, merchant_identity)`
- timestamps and `deleted_at`

`dim_youtube_playlists`

- `user_id`, `id` (the local row's `server_id`)
- `youtube_playlist_id`
- cached title/description/channel/thumbnail and aggregate metadata
- `last_synced_at`
- timestamps and `deleted_at`
- unique `(user_id, youtube_playlist_id)`

`dim_youtube_videos`

- `user_id`, `id` (the local row's `server_id`)
- `playlist_id uuid not null references dim_youtube_playlists(id) on delete cascade`
- `youtube_video_id`, title/thumbnail/position/duration metadata
- `completed`, `watched_at`, `last_position_seconds`, `progress_updated_at`
- timestamps and `deleted_at`
- unique `(playlist_id, youtube_video_id)`

The direct `user_id` on videos is deliberate: it makes RLS simple and avoids
an ownership-policy gap through a playlist join. A database constraint or
trigger should ensure the video user matches the playlist user.

## 3. Entity relationships

```text
auth.users (user_id)
  ├── dim_accounts (1:1)
  ├── dim_profile_data (1:1)
  ├── dim_tasks (1:N)
  │     └── dim_reminders.task_id (0:1 or 0:N by product rule)
  ├── dim_notes (1:N)
  ├── dim_money_transactions (1:N)
  ├── dim_merchant_category_rules (1:N)
  └── dim_youtube_playlists (1:N)
          └── dim_youtube_videos (1:N)
```

Planner and To-Do rows remain one local `tasks` concept, distinguished by
`is_planner_entry`. Reminders may be standalone or linked to a Planner task.
The local application currently expects at most one Planner reminder per task;
the cloud schema should enforce that with a partial unique constraint if that
behavior is confirmed.

## 4. RLS policy design

RLS must be enabled on every `dim_*` table before any client access is
allowed. The baseline policy for every directly user-owned table is:

```sql
using (user_id = auth.uid())
with check (user_id = auth.uid())
```

Required policies:

| Table | Ownership condition |
|---|---|
| `dim_accounts` | `user_id = auth.uid()` for select/insert/update; users cannot change `user_id`. |
| `dim_profile_data` | `user_id = auth.uid()`; account row must belong to the same authenticated UUID. |
| `dim_tasks` | `user_id = auth.uid()` for select/insert/update/delete. |
| `dim_reminders` | `user_id = auth.uid()`; linked `task_id`, when non-null, must reference a task with the same `user_id`. |
| `dim_notes` | `user_id = auth.uid()`. |
| `dim_money_transactions` | `user_id = auth.uid()`; type/amount/currency checks are database constraints in addition to RLS. |
| `dim_merchant_category_rules` | `user_id = auth.uid()`. |
| `dim_youtube_playlists` | `user_id = auth.uid()`. |
| `dim_youtube_videos` | `user_id = auth.uid()` and playlist ownership must match. |

RLS must not rely on a client-supplied local account ID, email, display name,
or playlist ID. A client may send `user_id` only if `with check` validates it
against `auth.uid()`; safer RPCs can populate it server-side.

RLS failure behavior is fail-closed: no authenticated session means no rows;
wrong-user IDs return no rows and cannot be updated/deleted; cross-user foreign
key attempts fail. Service-role operations, if ever needed for maintenance,
must be server-side only and must never be embedded in the app.

## 5. Sync lifecycle

### Local to Supabase

1. A local write commits first and remains immediately usable offline.
2. A future local sync layer records the changed entity, operation, stable
   `server_id`, account UUID, and version/timestamp in an outbox or
   equivalent durable sync metadata.
3. When authenticated and online, the sync worker pushes idempotently using
   the stable entity ID. It must never infer ownership from mutable profile
   fields.
4. The server validates RLS, constraints, ownership, and foreign-key order.
5. Successful acknowledgement records the server UUID/version locally.

Push order for related data is: account/profile, tasks, reminders, playlists,
videos, then independent notes/finance/rules. A Planner task and linked
reminder should be pushed as a dependency-aware pair; a failed reminder push
must not make the task disappear.

### Supabase to local

1. Pull only rows for the authenticated `auth.uid()` using a server cursor or
   `updated_at` window.
2. Upsert by stable server/client ID into the active local account.
3. Rebuild local notification schedules from synced reminders; never import a
   remote notification ID.
4. Refresh YouTube metadata without overwriting progress fields.
5. Advance the pull cursor only after the local transaction succeeds.

### Offline and conflict rules

- Local writes always win for immediate UI state; synchronization is deferred.
- Tasks, reminders, notes, profile fields, merchant rules, and playlist
  metadata can use per-row last-write-wins with server timestamps, provided the
  client clock is not treated as authoritative for security.
- YouTube progress uses `progress_updated_at`; the newest progress event wins,
  while metadata and progress are merged by field group.
- Money transactions are permanent user-owned records until explicitly
  deleted. Creates are idempotent by `server_id`; edits update the same row
  using `updated_at`; deletes propagate through tombstones/outbox entries.
  There is no separate loan lifecycle.
- Equal timestamps require a deterministic server-side tie-breaker, not random
  client behavior.

### Deletion strategy

Hard local deletes cannot synchronize safely by timestamp alone. Before sync is
implemented, every syncable local table needs either a tombstone/deleted-at
field or a durable outbox entry that survives the local row deletion.

Cloud rows should use `deleted_at` tombstones initially. Pulls apply tombstones
locally, cancel local notifications when a reminder is deleted, and preserve
the approved finance edit/delete semantics. Cloud
tombstones may be compacted only after all supported clients have passed the
retention/cursor boundary.

An outbox is not to be added in this phase, but reliable offline create/update/
delete sync will require one or an equivalent durable change log. Timestamps
alone cannot represent a delete that removes the only local row.

## 6. Feature-specific rules

### Planner

Sync task fields and completion timestamps. Heatmap cells remain derived.
Preserve the future-only delete rule locally. Linked reminder synchronization
must follow the task dependency and preserve `task_id` ownership.

### To-Dos

Sync incomplete and completed rows, including historical completed rows. The
active UI visibility window is local query behavior; it is not a deletion
rule.

### Reminders

Sync title, due time, enabled state, timestamps, and optional task relation.
Keep notification IDs and OS scheduling local. A pull/update/delete must
reschedule or cancel the current device notification after local commit.

### Finance

Sync only canonical `money_transactions` rows. Preserve integer
`amount_minor`, ISO currency, category, note, counterparty, type, occurred
time, source, and timestamps. Lent/Borrowed remain ordinary transaction types;
do not add a cloud loans table or repayment lifecycle.

### Notes

Sync full note content under the authenticated owner. Notes remain permanent
until explicit deletion; no derived note counts are synced.

### YouTube

Sync saved playlist ownership and durable progress. Playlist/video metadata is
cacheable and may be refreshed from YouTube. Never upload API keys, raw Edge
Function secrets, or device-specific notification state. Progress fields must
not be overwritten by metadata refresh.

### Profile

Sync authenticated identity-linked profile fields. Auth identity, email, and
session ownership come from Supabase Auth; mutable profile fields come from
the profile table. Offline profile data remains isolated and is not uploaded
or merged into a Google account.

### Transaction detection

Keep `transaction_detection_events` and `transaction_candidates` local-only.
Do not upload notification title/body/big-text, source package, raw event ID,
account hint, reference ID, balance-after amount, confidence, or candidate
workflow status. If the user confirms or the local auto-add rule creates a
canonical finance row, only that resulting row may sync, with its source marked
appropriately. The cloud must not be able to reconstruct the original bank
notification from synced data.

## 7. Security model

- Only the Supabase URL and publishable/anon key may be present in the client.
- Never ship the service-role key, database password, JWT signing secret,
  YouTube API key, or privileged Edge Function secret in Flutter assets,
  `--dart-define` values distributed to users, or logs.
- Keep YouTube retrieval/secrets in the Edge Function or another server-side
  boundary. The client receives validated playlist data only.
- Require a valid Supabase session for cloud sync. Refresh tokens remain under
  the Supabase Flutter auth client; sync must stop on sign-out or token failure.
- Never use email, local integer IDs, `display_name`, or a client-provided
  account selector as an RLS ownership check.
- Test missing-session, expired-session, wrong-user ID, cross-user foreign-key,
  and attempted `user_id` reassignment cases before enabling production sync.

## 8. Migration strategy for existing local v9 users

1. Add sync metadata only in a separately tested local migration; do not alter
   current v9 behavior during the architecture phase.
2. On authenticated login, resolve `local_accounts.auth_user_id` to
   `auth.users.id` and create the one cloud account/profile row idempotently.
3. If the local account is already linked, use that mapping and pull/push by
   stable IDs.
4. If the device has an offline account with existing data and the user signs
   in for the first time, keep that offline account isolated. Do not upload,
   merge, or silently attach its rows to the Google account.
5. A later explicit account-migration feature may copy approved data, but it is
   outside this synchronization implementation.
6. Pull first only when the authenticated cloud account is known to be empty;
   otherwise use stable IDs and conflict rules to avoid duplicate rows.
7. Detection events/candidates and notification IDs are not migrated to cloud.
   Recreate enabled notifications locally from synced reminders.
8. Validate counts, ownership, and representative hashes/content before
   marking migration complete. Keep a resumable migration marker; do not
   delete local data as part of cloud linking.

The current local integer IDs remain valid for local joins. They must never be
used as cloud primary keys. The nullable `server_id` UUID must be introduced
consistently across every syncable entity, including task references from
reminders and playlist references from videos.

## 9. Performance and offline behavior

- Keep Drift as the UI source of truth. Cloud sync runs outside screen build
  paths and never blocks local reads/writes.
- Use indexed local outbox/change queries and a single serialized sync worker,
  not one network request per widget/provider event.
- Batch pushes/pulls, use `updated_at` cursors, and paginate large YouTube or
  finance histories.
- Apply each pull batch in a local transaction, then notify providers once.
- Exponential backoff transient failures; do not retry authentication or RLS
  failures indefinitely.
- Keep notification scheduling, detection processing, heatmap derivation, and
  currency display local.
- Sync only the active authenticated account. On account switch, finish or
  pause the previous account’s queue before activating the new account.

## Resolved decisions and implementation risks

1. Stable identity is the nullable local `server_id UUID`. Supabase row UUIDs
   map directly to it; local integer primary keys remain local-only.
2. Offline accounts never automatically merge into Google accounts. Existing
   offline data stays isolated unless a separately approved migration feature
   is introduced.
3. Finance rows are permanent user-owned records until explicit deletion.
   Edits update the same record using `updated_at`; deletions use safe cloud
   tombstones/change records. Finance remains ordinary `money_transactions`
   with `lent` and `borrowed`, without a Loans entity.
4. `profile_data.points` is treated as synced user-owned profile data.
5. The existing v9 relationships remain: Planner tasks may own reminders via
   `task_id`, videos belong to playlists, profile data belongs to the local
   account mapping, and every synced row belongs to the authenticated user.
6. YouTube metadata remains refreshable cache data while watched/progress fields
   remain durable user data; both may sync under the existing relationship.
7. Tombstone retention, retry/repair behavior, server-clock handling, and
   cursor recovery are implementation safeguards, not product-model changes.

## Exact implementation order

1. Add nullable local `server_id` fields and sync metadata in a separately
   tested local migration; preserve local integer IDs and offline isolation.
2. Define Supabase migrations, UUID primary keys, foreign keys, constraints,
   indexes, tombstones, and server timestamp/version behavior.
3. Define and test RLS policies with two users and anonymous/expired sessions.
4. Implement authenticated account mapping without importing offline-account
   data into Google accounts.
5. Implement one-way local-to-cloud sync for a low-risk entity such as Notes.
6. Implement cloud-to-local pull, cursor recovery, and local transactionality.
7. Add Tasks/Planner/Reminders with dependency-aware synchronization.
8. Add Profile, Merchant Rules, YouTube, and then Finance.
9. Keep detection data local and verify that only confirmed finance rows cross
    the boundary.
10. Add offline, retry, conflict, deletion, account-switch, and RLS tests.
11. Enable production sync only after migration rollback and data-preservation
    tests pass.

**READY FOR IMPLEMENTATION** — the stable-ID, account-isolation, finance,
relationship, and local-first product decisions are resolved. Implementation
must still follow the staged order and security tests in this document.
