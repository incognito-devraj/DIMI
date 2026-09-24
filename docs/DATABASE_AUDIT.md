# DIMI Database Audit

Audit scope: current repository state, local Drift schema, DAOs, providers, feature repositories/services, Android notification bridge, UI write paths, and startup/lifecycle behavior. No production code, schema, data, or Supabase objects were changed for this audit.

## 1. Current Architecture

DIMI uses one eagerly-created local Drift `AppDatabase` backed by SQLite at `getApplicationDocumentsDirectory()/dimi.sqlite`. `main()` creates it before `runApp`, then injects the same instance through Riverpod. `databaseProvider` closes the database when its provider scope is disposed. Drift streams are the principal read model; screens call DAOs directly for writes. There is no general repository layer, sync queue, owner-aware data model, or account-scoped database lifecycle.

The app also uses:

- Supabase Auth for Google authentication and Edge Functions for YouTube fetching.
- Android `SharedPreferences` for transaction-notification inbox/history and detector settings.
- `flutter_local_notifications` for scheduled reminder notifications; the authoritative reminder row is local Drift data.
- In-memory Riverpod/provider state and widget controllers for transient UI state.
- JSON only at the Android notification bridge and YouTube Edge Function boundary. No general local JSON export/import exists.

Startup currently performs: database open, legacy-demo cleanup, deletion of completed non-planner todos older than seven days, notification-event sync, Google profile sync, and reminder rescheduling. A 15-second foreground timer repeatedly calls transaction-event sync while the app is active.

## 2. Current Drift Schema

Database schema version is 8. Migrations exist only for task completion/planner columns, transaction-detection tables/columns, and YouTube tables. `database.g.dart` is generated output and is not the design source of truth.

### ProfileTable (`profile`)

Purpose: one local profile row, identified by hard-coded `id = 1`.

| Field | Type | Null/default | Key/notes |
|---|---|---|---|
| id | integer | required | primary key, not auto-increment |
| name | text | required | user display name |
| role | text | required | occupation/role in current UI |
| email | text | required | copied from authenticated Google user |
| phone | text | required | local editable field |
| college | text | required | currently also used for school name in UI |
| semester | text | required | currently used for class/semester |
| photoPath | text | nullable | Google avatar URL; not a local upload path in current flow |
| quote | text | nullable | legacy field; current UI clears it |
| points | integer | default 0 | derived/achievement-like value, no ledger |

No foreign keys, created/updated timestamps, owner ID, or soft-delete marker. Auth sync overwrites identity fields and preserves some local fields. Profile updates are hard upserts.

### Tasks (`tasks`)

Purpose: both To-Do records and Planner event records, separated by `isPlannerEntry`.

| Field | Type | Null/default | Key/notes |
|---|---|---|---|
| id | integer | required | auto-increment primary key |
| title | text | required | task/event title |
| description | text | nullable | optional description |
| category | text | required | free-form string |
| isPlannerEntry | boolean | default false | false = To-Do, true = Planner |
| dueDate | datetime | required | date/time storage; Planner normalizes date portion |
| dueTime | text | nullable | string in `HH:mm`; no database validation |
| plannedMinutes | integer | default 60 | legacy/planner metric; current heatmap is task-count based |
| completedMinutes | integer | default 0 | legacy/derived metric |
| reminderMinutesBefore | integer | nullable | metadata only; no FK to reminder |
| isCompleted | boolean | default false | completion state |
| completedAt | datetime | nullable | completion timestamp |
| createdAt | datetime | required | creation timestamp; no updatedAt |

No recurrence, timezone, notification ID, owner ID, archived/deleted state, or task-to-reminder relationship. Updates are hard replacement; deletes are hard deletes.

### MoneyTransactions (`money_transactions`)

Purpose: expenses, income, and loans/lent money in one table.

| Field | Type | Null/default | Key/notes |
|---|---|---|---|
| id | integer | required | auto-increment primary key |
| type | text | required | convention: `expense`, `income`, `loan`; no enum/check constraint |
| amount | real/double | required | floating-point money; precision risk |
| category | text | required | free-form |
| note | text | nullable | free-form; auto-detection writes marker text |
| date | datetime | required | transaction date; no timezone/currency column |

No owner ID, currency, counterparty, repayment status, due date, source, external ID, createdAt, updatedAt, or soft delete. Updates/deletes are hard.

### Reminders (`reminders`)

Purpose: user-created scheduled reminders.

| Field | Type | Null/default | Key/notes |
|---|---|---|---|
| id | integer | required | auto-increment primary key; also used as notification ID |
| title | text | required | reminder title |
| dueAt | datetime | required | local DateTime; timezone policy is not stored |
| isEnabled | boolean | default true | controls rescheduling |

No owner ID, completed state, created/updated timestamps, recurrence, notification payload/version, or source task FK. Deletes are hard. Planner-created reminders are separate rows inserted from the Planner add-event flow; the task only stores reminder offset metadata.

### TransactionDetectionEvents (`transaction_detection_events`)

Purpose: deduplicated raw/normalized notification events waiting to be parsed or used for enrichment.

Fields: `id` integer auto-increment PK; `eventKey` required unique text; `sourcePackage` required text; `sourceType` required text; `title`, `body`, `bigText` nullable text; `occurredAt` and `receivedAt` required datetimes.

No owner ID, processing status, processedAt, retention policy, or FK to candidate. DAO insertion is `insertOrIgnore`. The Android SharedPreferences inbox is the actual pre-Drift staging source; event persistence here is not a complete authoritative event log.

### TransactionCandidates (`transaction_candidates`)

Purpose: parsed financial candidates requiring auto-add, confirmation, enrichment, or rejection.

Fields: `id` integer auto-increment PK; `candidateId` required unique text; `amountMinor` required integer; `currency` text default `INR`; `merchantName` text default `Unknown`; `merchantIdentity` text default `unknown`; `direction` required text; `transactionType` required text; `source` required text; `bankConfirmationStatus` text default `NOT_RECEIVED`; `sourcePackage` nullable text; `occurredAt` required datetime; `referenceId`, `accountHint`, `paymentMethod`, `balanceAfterMinor`, `rawEventId` nullable; `confidenceScore` required real; `status` required text; `duplicateStatus` required text; `category` text default `Other`; `createdAt` required datetime.

No FK from `rawEventId` to `TransactionDetectionEvents.eventKey`, no owner ID, no resolved money-transaction FK, no updatedAt, and no check constraints for states/direction/currency. Candidate-to-transaction traceability is therefore text/convention based.

### MerchantCategoryRules (`merchant_category_rules`)

Fields: `id` integer auto-increment PK; `merchantIdentity` required unique text; `category` required text; `updatedAt` required datetime. It stores learned category preferences but has no owner ID, source, createdAt, or deletion DAO/UI.

### YouTubePlaylists (`youtube_playlists`)

Fields: `id` integer auto-increment PK; `userId` required text; `youtubePlaylistId` required text; `title`, `description`, `channelTitle`, `thumbnailUrl`; `totalVideos`, `totalDurationSeconds`; `createdAt`, `updatedAt`; nullable `lastSyncedAt`. Unique key is `{userId, youtubePlaylistId}`. This is the only principal user-owned Drift table. There is no foreign-key enforcement to an auth user table, sync status/error, deleted flag, or canonical URL.

### YouTubeVideos (`youtube_videos`)

Fields: `id` integer auto-increment PK; `playlistLocalId` required integer FK to `YoutubePlaylists.id`; `youtubeVideoId` required text; `title`, `thumbnailUrl`; `position` required integer; `durationSeconds` default 0; `durationIso` default empty string; `completed` default false; nullable `watchedAt`; `lastPositionSeconds` default 0; `createdAt`, `updatedAt`. Unique key is `{playlistLocalId, youtubeVideoId}`. User ownership is indirect through playlistLocalId. The DAO replaces all videos during playlist save, which can destroy local progress if the replacement payload is stale or incomplete.

### ClassSessions, StudySessions, Courses, Notes, DocumentMeta

These tables are registered in Drift but have no DAO/provider/screen flow found in the current codebase beyond `NoteDao`/`note_providers` for Notes.

- `ClassSessions`: id auto PK; courseName, dayOfWeek, startTime, endTime, nullable room, semester, colorTag. No timestamps, owner, FK, or observed UI lifecycle.
- `StudySessions`: id auto PK; courseName, startedAt, durationMinutes. No owner or updatedAt. No observed UI lifecycle.
- `Courses`: id auto PK; name; totalLoggedMinutes default 0. No owner or timestamps. No observed UI lifecycle.
- `Notes`: id auto PK; title, content, category, createdAt, updatedAt. `NoteDao` supports stream/insert/count/update/delete, but no screen usage was found in the current screen inventory. Hard-delete.
- `DocumentMeta`: id auto PK; fileName, fileType, filePath, sizeBytes, addedAt. No DAO/provider/screen usage found. It stores metadata only; no file lifecycle or cleanup is implemented.

## 3. Entity-by-Entity Data Inventory

### Profile/account

Created/updated by `AuthService.syncLocalProfile` and Profile edit UI. Read by Profile screen and auth/profile providers. Google email and avatar metadata come from Supabase Auth user metadata. Profile is permanent local data by intent, but only one global row exists. There is no account deletion flow and no logout cleanup. It survives restart/force-close/reboot/update and normally survives logout because the SQLite file is not cleared. It does not safely support multiple users.

### To-Dos

Created by the To-Dos UI using `TaskDao.insertTask` with `isPlannerEntry=false`; read through all/home/today/completed/upcoming task providers; updated through task edit/toggle paths; hard-deleted by task actions. Completed To-Dos older than seven days are purged at every startup, which conflicts with the requested permanent/history behavior. They survive restart and logout, and are not user-specific.

### Planner

Created by Add Task Sheet with `isPlannerEntry=true` and a normalized selected `dueDate`; read by date/week/all-planner queries and the Planner heatmap. Completion uses `isCompleted`/`completedAt`; current UI imposes past immutability, future restrictions, and today actions, but the DAO itself does not enforce them. Planner tasks are not included in To-Do purge. They have no recurrence or timezone model and no owner ID. Historical rows survive locally unless explicitly deleted.

### Expenses and lent/borrowed money

Created/edited/deleted through Money screen and `MoneyDao`; read by all/type/week providers. `loan` is a type convention, not a loan entity; “lent” is represented by category/note. Totals are derived in UI from rows rather than stored. Amount uses `REAL`, so binary floating-point rounding is possible. No currency or counterparty/status/repayment relationship exists. Rows persist across restart/logout and leak across accounts.

### Reminders

Created by Reminder Sheet and also automatically by Planner Add Event; read by reminder providers; updated for enable/disable/edit; hard-deleted by Reminder UI. Notification scheduling is separate from the row and recreated at startup from enabled future rows. There is no recurrence, completion, notification UUID, timezone, or task FK. Old reminders remain in the table but ordinary streams hide due dates before today. They persist across restart/reboot/update/logout; notifications can survive logout unless explicitly cancelled.

### Habits

No habit table, model, provider, DAO, screen lifecycle, or persistent storage was found. Any habit-like streak is derived from completed task dates, not a Habit entity. Status: NOT IMPLEMENTED / UNKNOWN requirements.

### Heatmap/activity history

No heatmap table exists. Both heatmap implementations derive cells from task due dates and `isCompleted`; current visible heatmap uses completion ratio `completed / total` and explicit six-color mapping. The old `_MonthView`/`_CompletionHeatmap` code remains in Planner as legacy/dead UI code. Heatmaps are derived data and should not be stored as rendered colors. Because completed tasks or old To-Dos can be deleted, derived history can change or disappear.

### YouTube

API/Edge Function response is parsed into immutable Dart models, then mapped into Drift playlist/video companions. Playlist metadata is refreshable/cache-like; user selection and video completion/progress are authoritative user data. No YouTube OAuth token is stored in DIMI tables; Supabase manages auth/session state. Playlist rows are filtered by current Supabase user ID, with unauthenticated fallback user ID `local`. Logout switches the provider to `local` but does not delete the prior account’s rows.

### Settings/auth/notification state

Detector mode and migration flag live in Android SharedPreferences file `dimi_settings`. Notification pending/history event JSON lives in `dimi_transaction_events`, with string-set indexes and individual `event_<id>` keys. The feed is capped at 50, but set iteration is not chronological, so “oldest” eviction is not reliable. `clearNotificationFeed` clears only the history index, not necessarily all event payload keys. `acknowledgeTransactionEvent` removes pending and one event payload but does not remove the history index entry. Auth session persistence is delegated to Supabase Flutter; exact storage/retention is vendor-managed and not audited as a local DIMI table.

## 4. Data Relationships

The only declared FK is `YouTubeVideos.playlistLocalId -> YoutubePlaylists.id`. Profile has no relationship to any record. Tasks and reminders are connected only by title/date/creation convention; `reminderMinutesBefore` is not a FK. Transaction candidates and raw events are connected by text (`rawEventId`/candidate IDs), and candidates that become money transactions have no durable transaction FK. All other tables are standalone. This prevents reliable cascade behavior, user-account deletion, conflict resolution, and audit history.

## 5. Data Lifecycle & Retention

| Entity/value | Classification | Current behavior | Recommended retention |
|---|---|---|---|
| Profile fields | PERMANENT | Local row; overwritten by auth identity sync | Until user/account deletion |
| To-Dos | PERMANENT | Completed non-planner rows purged after 7 days at startup | Remove automatic purge; explicit user/account delete only |
| Planner tasks/history | PERMANENT | Hard delete only | Until explicit delete/account delete |
| Money transactions | PERMANENT | Hard delete only | Until explicit delete/account delete; preserve audit if syncing |
| Reminders | PERMANENT | Past rows hidden but retained | User choice; optionally archive after notification policy is defined |
| Notification raw inbox/history | TEMPORARY/CACHE | Android cap nominally 50; Drift copy has no retention | 7–30 days after processing, or bounded 50–200 events; document user-visible history policy |
| Transaction candidates | TEMPORARY until resolved, then audit record | No cleanup/status lifecycle complete | Keep unresolved; archive resolved/rejected after 90 days if product permits |
| Merchant rules | PERMANENT user preference | No deletion flow | Until user/account delete |
| YouTube playlist metadata | CACHE | Replaced on refresh | Refresh on open; retain offline copy with lastSyncedAt; evict unreferenced playlists after explicit policy |
| YouTube video metadata | CACHE | Replaced wholesale | Re-fetch; never lose progress during refresh |
| YouTube completed/progress state | PERMANENT | Local video fields | Until user removes playlist/account |
| Notification permission/settings | PERMANENT preference | SharedPreferences | Until user changes/uninstalls |
| In-memory controllers/provider values | TEMPORARY | Recreated with widgets/provider scope | No retention needed |
| Document file metadata | UNKNOWN | No file lifecycle found | Define ownership and cleanup before enabling |

No SYNC INFRASTRUCTURE entity currently exists. A future sync design needs an outbox/pending operation table, server IDs, sync timestamps, tombstones, retry state, and conflict metadata.

## 6. User Ownership / Multi-User Analysis

The current local database does not properly separate users. Every table except `YoutubePlaylists` has no owner/account ID. Queries for profile, tasks, money, reminders, notes, detection data, and rules are global. Profile is explicitly singleton `id=1`. Riverpod providers cache streams against the single database, not an account key. Logging out does not clear local rows or cancel all scheduled notifications. Logging in with another account therefore exposes the previous local data.

YouTube is better but incomplete: playlists filter by `userId`; videos inherit ownership through the playlist FK; however the `watchById`, `watchVideos`, `getVideos`, `setCompleted`, and playlist deletion/update paths accept local IDs and do not independently validate the current user. A stale local ID or cross-account caller could access/modify another user’s playlist if the caller can obtain the ID. The special `'local'` identity is also a shared bucket for all unauthenticated users on the device.

### Lifecycle verification

- App restart: SQLite and SharedPreferences survive; scheduled notifications are rescheduled from enabled reminder rows.
- Force-close: local files survive. Android notification listener may continue staging events independently; pending events are drained next startup.
- Device reboot: SQLite/SharedPreferences survive; boot receiver asks the notification plugin to reschedule, and app startup also reschedules.
- Logout: no local data purge, account switch, database rotation, or notification cancellation found. Data survives and can leak.
- Same-account login: local rows remain, but there is no owner check for most tables.
- Different-account login: prior global rows remain visible; confirmed critical leak.
- App update: Drift migrations cover only versioned schema changes; ordinary app update preserves app data. `clearLegacyDemoContent` can delete all major local data if profile matches demo conditions.
- App reinstall: normally removes app-private SQLite/SharedPreferences and scheduled notifications, but Android backup/restore behavior is not explicitly controlled; exact result is UNKNOWN by device/backup policy. Supabase cloud data is not a local restore mechanism in this code.

## 7. YouTube Data Analysis

The Edge Function supplies playlist ID, title, description, channel, thumbnail, counts, durations, and video metadata. DIMI needs the playlist identity, refreshable metadata, ordered video identity/metadata, and user progress. It does not need to permanently store raw API responses, OAuth credentials, or duplicate duration representations except where display/parser compatibility requires `durationIso`.

Current risks: whole-video replacement deletes and recreates rows on every save, potentially resetting progress; `createdAt` is reset for an existing playlist because the mapper always supplies `now`; there is no deletion cascade policy exposed; `totalVideos` can differ from fetched video count and progress divides by the former; no sync error/ETag/version exists; mock data remains as a compatibility export (`mock_youtube_playlist`) although production reads Drift.

## 8. Financial Data Analysis

Manual money rows use `REAL` amount and no currency. Automatic detection uses integer minor units in candidates, then writes money transactions through conversion logic; this is safer at the candidate boundary but the final table loses minor-unit precision semantics. Use integer minor units plus ISO currency for authoritative storage. Direction/type/category are strings without constraints. `loan` is insufficient for lent/borrowed lifecycle, counterparty, repayment, or outstanding balance. Derived dashboard totals should be calculated from canonical rows, not stored independently.

Detection reads only allowlisted/potential financial notification sources before extracting text. Android still receives the system listener callback for every posted notification, but unrelated packages are rejected before text parsing. SharedPreferences staging is capped nominally at 50 pending/history entries. The listener has no per-user ownership and can run while the UI is logged out; captured financial content may remain on the device until acknowledged/cleared.

## 9. Planner / To-Do / Reminder Analysis

Planner date storage is a DateTime date boundary plus a separate nullable `HH:mm` string. The current add-event flow normalizes the selected date and creates the reminder using the selected date plus selected time/offset. DAO date queries now use half-open ranges for Planner date/week queries. However there is no timezone ID, DST policy, recurrence, reminder FK, or update/delete synchronization between an edited task and its previously-created reminder. Editing a Planner event can leave an old reminder row/notification behind. The DAO allows mutation regardless of past/future policy; UI restrictions are not a data-integrity boundary.

To-Dos intentionally have a seven-day completed purge in startup, which directly conflicts with lifetime heatmap/history expectations. Planner history is not purged, but hard deletion removes the underlying source for heatmap cells. Completion timestamps are local wall-clock DateTimes and can be inconsistent if device time changes.

## 10. Heatmap Analysis

Cells are derived by grouping Planner/all task rows by local calendar date. For each day: total = all tasks assigned to that date; completed = tasks with `isCompleted=true`; ratio = completed/total. No tasks and zero-completed tasks both map to the empty color. The six explicit colors are in `lib/widgets/dimi_activity_heatmap.dart`: `F5F0E6`, `F8E8C5`, `F9C85B`, `F5A623`, `D96A0B`, `9C3D0A` for 0%, 1–24%, 25–49%, 50–74%, 75–99%, and 100% respectively. The visible Home/Planner heatmap shares this calculation; legacy Planner heatmap code remains and should be removed or made to call one implementation.

Heatmap values should remain derived. Store underlying events/completions and calculate cells; do not store only color/index. A durable activity-history product may need immutable completion events or an archive policy, because deleting tasks or purging To-Dos changes historical results.

## 11. Persistence & Data-Loss Risks

1. Critical cross-user leak: global tables and queries have no owner ID; logout/login with another user exposes local records.
2. Critical To-Do loss: startup deletes completed non-planner tasks older than seven days.
3. High reminder integrity risk: Planner task and reminder are separate; edit/delete does not reliably update/cancel the paired reminder/notification.
4. High financial precision risk: final money amount uses floating point and currency is absent.
5. High YouTube progress risk: refresh deletes all child video rows before reinserting API results.
6. High detection privacy risk: notification payloads are stored in Android SharedPreferences and have no owner, encryption, robust deletion, or reliable oldest ordering.
7. High deletion/audit risk: financial, planner, and reminder records are hard-deleted with no tombstones or audit trail.
8. Medium date correctness risk: local DateTime/time-string split has no timezone/DST contract.
9. Medium migration risk: schema generation/versioning is manual and there are no migration tests found.
10. Medium legacy/demo risk: `clearLegacyDemoContent()` performs multi-table destructive cleanup based on profile name/email heuristics.
11. Medium incomplete-data risk: several registered tables are orphaned from the UI/DAO layer and their intended lifecycle is unknown.

## 12. Duplicate / Redundant Data

- `Tasks.plannedMinutes`/`completedMinutes` are legacy metrics while visible heatmaps/stats use task counts/completion ratios.
- `Tasks.reminderMinutesBefore` duplicates reminder timing without identifying the reminder row.
- `dueDate` carries a date (and potentially time) while `dueTime` separately carries time.
- YouTube duration is stored both as seconds and ISO text.
- YouTube playlist totals are stored alongside the fetched video list and can diverge.
- Notification event content exists in Android SharedPreferences and may also be copied into Drift events.
- `YouTubeVideo` model getters (`id`, `subtitle`, `thumbnailLabel`, `completion`) duplicate/abstract persisted fields; `mock_youtube_playlist` is obsolete compatibility data.
- Profile `quote` remains schema/storage baggage after the UI removed it.

## 13. Missing Constraints

Missing owner/account IDs on all user data; missing currency and integer money units; missing enums/check constraints; missing created/updated timestamps on several mutable tables; missing task-reminder FK; missing candidate-event and candidate-money FK; missing cascade policy; missing unique constraints for financial external IDs; missing recurrence/timezone model; missing soft-delete/tombstones; missing optimistic version; missing validation for due times, categories, status, and directions; missing account-delete transaction; missing migration tests and restore/export tests.

## 14. Recommended Local Database Architecture

Use a canonical local model with an authenticated `accounts` row and `ownerId` on every user-owned table. Keep repositories between screens and DAOs. Separate permanent user records from refreshable metadata and sync infrastructure. Use integer minor units for money. Use a canonical instant plus IANA timezone/offset policy for reminders, and an explicit `taskReminder` relationship. Prefer immutable completion/activity events or a well-defined archived task policy for history. Add soft-delete/tombstones for syncable records, transactionally update related rows, and centralize account switching by changing the active owner/database scope.

## 15. Proposed Improved Drift Schema

This is a proposal only; it has not been implemented.

- `accounts`: localId, authProvider, authUserId unique, email, displayName, avatarUrl, createdAt, updatedAt, lastLoginAt, deletedAt.
- `profiles`: accountId PK/FK, phone, occupation, educationType, institutionName, educationLevel, points, createdAt, updatedAt.
- `tasks`: id, accountId FK, title, description, category, planner flag, localDate, dueAt nullable, timezone, status, completedAt, createdAt, updatedAt, deletedAt, syncVersion.
- `task_reminders`: id, accountId, taskId FK, dueAt, minutesBefore, enabled, notificationId, timezone, createdAt, updatedAt, deletedAt.
- `money_transactions`: id, accountId, amountMinor, currency, type, category, note, occurredAt, counterparty, source, externalId, createdAt, updatedAt, deletedAt.
- `loans`: id, accountId, direction, counterparty, principalMinor, currency, lentAt, dueAt, status, repaidMinor, note, timestamps, deletedAt.
- `youtube_playlists`: accountId, provider ID, refreshable metadata, sync timestamps/errors, created/updated/deleted fields.
- `youtube_videos`: playlist FK, provider ID, refreshable metadata, position, user progress, progressUpdatedAt, timestamps; upsert metadata without deleting progress.
- `activity_events`: accountId, sourceType, sourceId, activityDate, eventType, occurredAt, metadata, immutable ID; used to derive heatmaps.
- `notification_events`: accountId/device scope, event key, redacted/raw policy, received/occurred/processed timestamps, retention state.
- `transaction_candidates`: accountId, raw event FK, amountMinor/currency, parser confidence, lifecycle status, resolved money FK, timestamps.
- `merchant_category_rules`: accountId, merchant key, category, timestamps, deletedAt.
- `sync_outbox`: accountId, entity, local ID, operation, payload/version, retry count, nextRetryAt, lastError, createdAt.
- `sync_state`: accountId/entity, cursor, lastPulledAt, lastPushedAt, serverVersion.

## 16. Data Migration Requirements

Before implementation: back up existing SQLite; map current `profile.id=1` to the signed-in account only after explicit identity verification; add owner IDs to global rows with a documented one-user migration; preserve old `completedAt`; stop the seven-day purge before migration; convert REAL money values to minor units with an explicit rounding policy; split `loan` rows only when semantics are known; pair Planner reminders by a migration heuristic and flag uncertain pairs; preserve YouTube progress by matching provider video IDs before replacing metadata; retain legacy columns until verified; test upgrades from every supported schema version.

## 17. Supabase Mapping Plan

Map `accounts` to `auth.users` plus a public `profiles` table; map permanent entities to `profiles`-owned tables with UUID `user_id`; use server-generated UUIDs and `created_at`/`updated_at`; use integer minor units and ISO currency; use soft deletes/tombstones for sync; keep YouTube API metadata either as user-owned cache rows or refetchable Edge Function output; never send raw notification text to Supabase unless the privacy policy explicitly permits it; map detection candidates/events only if required for user-visible audit/reconciliation. Local outbox pushes mutations; pull uses cursors/version fields; conflict policy must be defined per entity.

## 18. Security/RLS Requirements for Later

Every user-owned Supabase table must have `user_id NOT NULL`, RLS enabled, and policies restricting SELECT/INSERT/UPDATE/DELETE to `auth.uid() = user_id`. Never trust a client-supplied user ID. YouTube child access must be protected through policies/joins to the owner playlist. Storage URLs should be validated and preferably signed where private. Do not store OAuth access/refresh tokens in Drift or ordinary SharedPreferences. Notification payloads and financial data need explicit minimization, encryption-at-rest assumptions, retention, and account deletion handling. Logout must clear/rotate active local scope and cancel account-owned notifications.

## 19. Open Questions / Decisions Required

1. Is DIMI strictly single-account per installation, or must multiple accounts coexist locally?
2. Should logout preserve local data for the same account, or require an encrypted account-scoped store?
3. Are Planner events permanent history, or can users explicitly archive them?
4. Are To-Do histories required for heatmaps? If yes, the seven-day purge must be removed.
5. Is a reminder a standalone item, a task child, or both?
6. Are loans expected to track repayment and counterparty?
7. Which currencies and rounding rules are supported?
8. Should raw notification bodies ever be persisted, and for how long?
9. Are Classes, StudySessions, Courses, Notes, and Documents active roadmap features or dead schema?
10. Which YouTube data must be available offline, and what is the progress conflict rule?
11. What is the canonical timezone and behavior after device timezone changes?
12. What does account deletion mean for local files, notifications, cloud rows, and backups?

## 20. Recommended Implementation Order

1. Decide account ownership, logout, retention, history, money, and reminder semantics.
2. Add regression tests for migrations, restart, logout/account switch, date boundaries, reminders, money precision, and YouTube progress.
3. Stop destructive To-Do purge and define archival behavior.
4. Introduce account context/repositories and owner-scoped reads/writes.
5. Redesign canonical local schema and write a tested migration/backup path.
6. Repair reminder/task relationship and timezone handling.
7. Convert money to minor units/currency and model loans explicitly.
8. Make YouTube metadata refresh non-destructive to progress.
9. Add sync infrastructure and conflict/tombstone rules.
10. Map to Supabase with RLS and test account deletion/data isolation.

## REQUIRED CHANGES BEFORE IMPLEMENTATION

### Must Fix

- Prevent cross-user data leaks by adding account ownership and account-scoped queries.
- Remove the automatic seven-day deletion of completed To-Dos if history/heatmaps are lifetime data.
- Define and enforce money precision/currency; do not make REAL the authoritative money representation.
- Link Planner tasks to reminders and cancel/update notifications transactionally.
- Define notification payload retention and clear all related SharedPreferences keys on deletion/account removal.
- Add tested migration, backup, restore, logout, and different-user isolation scenarios.

### Should Fix

- Add repositories/account context instead of direct screen-to-DAO writes.
- Remove or formally retire orphan tables and legacy heatmap/field code.
- Add timestamps, validation constraints, soft-delete/tombstone policy, and explicit status enums.
- Preserve YouTube progress during metadata refresh and add sync/error state.
- Add timezone/recurrence design for reminders and Planner.

### Optional

- Add export/import, encrypted local storage, activity-event analytics, richer loan repayment history, and cache eviction telemetry.

## Proposed Single Source-of-Truth Data Model

The proposed source of truth is an account-owned local domain model: `Account/Profile`, `Task`, `TaskReminder`, `MoneyTransaction`, `Loan`, `YouTubePlaylist`, `YouTubeVideoProgress`, and immutable `ActivityEvent`. Rendered heatmap cells, dashboard totals, streaks, and progress percentages are derived projections, never authoritative stored values. Refreshable YouTube metadata and notification inbox payloads are cache/temporary records. Every permanent record carries an account owner, stable local/server identity, created/updated timestamps, and deletion/sync metadata. This model should be reviewed and approved before any schema or production-code changes are made.
