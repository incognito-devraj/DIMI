# DIMI — Local Database Audit

**Scope:** Read-only analysis of the local Drift/SQLite persistence layer.  
**Schema version audited:** 8  
**Database file:** `getApplicationDocumentsDirectory()/dimi.sqlite`  
**Date:** 2026-09-18  
**No code was modified.** This document is analysis only.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Complete Current Schema](#2-complete-current-schema)
3. [Entity-by-Entity Analysis](#3-entity-by-entity-analysis)
4. [Relationships](#4-relationships)
5. [Index Analysis](#5-index-analysis)
6. [Query & Performance Analysis](#6-query--performance-analysis)
7. [Persistence & Deletion Analysis](#7-persistence--deletion-analysis)
8. [Multi-Account & Local Ownership Analysis](#8-multi-account--local-ownership-analysis)
9. [Migration & Schema Version Analysis](#9-migration--schema-version-analysis)
10. [Problems Found](#10-problems-found)
11. [Recommended Changes](#11-recommended-changes)
12. [Files That Would Need to Change](#12-files-that-would-need-to-change)

---

## 1. Architecture Overview

DIMI uses one eagerly-created `AppDatabase` (Drift on SQLite) as its sole local persistence layer. It is opened at app startup before `runApp`, injected into Riverpod via `databaseProvider`, and closed when the `ProviderScope` disposes. The database lives at a platform-private path and is never shared across users at the OS level.

**Runtime data flow:**
- `main()` opens the DB, runs `clearLegacyDemoContent()`, purges 7-day-old completed non-planner To-Dos, drains pending Android notification events, syncs the Supabase profile, and reschedules all enabled future reminders.
- A 15-second foreground `Timer` re-calls `TransactionDetectionService.syncPendingEvents()` while the app is active.
- All screens subscribe to Drift reactive `Stream` queries via Riverpod `StreamProvider`s. There are no manual refresh calls.
- Writes go directly from screens/sheets → DAOs → Drift. There is no repository layer and no write queue.

**Additional persistence outside Drift:**
- `SharedPreferences` (`dimi_settings`): notification-detector mode, migration flags, per-reminder sound preferences (keys `dimi_reminder_sound_<id>`).
- `SharedPreferences` (`dimi_transaction_events`): Android notification inbox/history; string-set indexes (`pending_events`, `notification_history`) and per-event payload keys (`event_<id>`). Nominally capped at 50 pending entries; eviction order is not chronological.
- `flutter_local_notifications`: OS-level scheduled alarm state. Authoritative source of notification delivery; rebuilt from Drift reminder rows on every startup.
- Supabase auth session: managed by `supabase_flutter`; exact local storage location is vendor-controlled.

---

## 2. Complete Current Schema

### 2.1 Tables registered in `AppDatabase` (`schemaVersion = 8`)

| # | Dart class | SQLite table name |
|---|---|---|
| 1 | `Tasks` | `tasks` |
| 2 | `ClassSessions` | `class_sessions` |
| 3 | `StudySessions` | `study_sessions` |
| 4 | `Courses` | `courses` |
| 5 | `MoneyTransactions` | `money_transactions` |
| 6 | `Notes` | `notes` |
| 7 | `Reminders` | `reminders` |
| 8 | `DocumentMeta` | `document_meta` |
| 9 | `ProfileTable` | `profile` |
| 10 | `TransactionDetectionEvents` | `transaction_detection_events` |
| 11 | `TransactionCandidates` | `transaction_candidates` |
| 12 | `MerchantCategoryRules` | `merchant_category_rules` |
| 13 | `YoutubePlaylists` | `youtube_playlists` |
| 14 | `YoutubeVideos` | `youtube_videos` |

### 2.2 Column-level schema

#### `tasks`

| Column | SQLite type | Null | Default | Constraint |
|---|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement | PRIMARY KEY AUTOINCREMENT |
| `title` | TEXT | NOT NULL | — | — |
| `description` | TEXT | nullable | — | — |
| `category` | TEXT | NOT NULL | — | — |
| `is_planner_entry` | INTEGER (bool) | NOT NULL | 0 | CHECK IN (0,1) |
| `due_date` | INTEGER (datetime) | NOT NULL | — | — |
| `due_time` | TEXT | nullable | — | — |
| `planned_minutes` | INTEGER | NOT NULL | 60 | — |
| `completed_minutes` | INTEGER | NOT NULL | 0 | — |
| `reminder_minutes_before` | INTEGER | nullable | — | — |
| `is_completed` | INTEGER (bool) | NOT NULL | 0 | CHECK IN (0,1) |
| `completed_at` | INTEGER (datetime) | nullable | — | — |
| `created_at` | INTEGER (datetime) | NOT NULL | — | — |

**Indexes:** none declared beyond PK.  
**Foreign keys:** none.  
**Notes:** `is_planner_entry` doubles as a discriminator — `false` = To-Do, `true` = Planner event. No `updated_at`. `due_time` is stored as `"HH:mm"` text with no database-level format validation. `reminder_minutes_before` stores intent only — it has no FK to the `reminders` table.

---

#### `class_sessions`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement PK |
| `course_name` | TEXT | NOT NULL | — |
| `day_of_week` | INTEGER | NOT NULL | — |
| `start_time` | TEXT | NOT NULL | — |
| `end_time` | TEXT | NOT NULL | — |
| `room` | TEXT | nullable | — |
| `semester` | TEXT | NOT NULL | — |
| `color_tag` | TEXT | NOT NULL | — |

**Indexes:** none.  **Foreign keys:** none.  **DAO:** none found.  **Providers:** none found.

---

#### `study_sessions`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement PK |
| `course_name` | TEXT | NOT NULL | — |
| `started_at` | INTEGER (datetime) | NOT NULL | — |
| `duration_minutes` | INTEGER | NOT NULL | — |

**Indexes:** none.  **Foreign keys:** none.  **DAO:** none found.  **Providers:** none found.

---

#### `courses`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement PK |
| `name` | TEXT | NOT NULL | — |
| `total_logged_minutes` | INTEGER | NOT NULL | 0 |

**Indexes:** none.  **Foreign keys:** none.  **DAO:** none found.  **Providers:** none found.

---

#### `money_transactions`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement PK |
| `type` | TEXT | NOT NULL | — |
| `amount` | REAL | NOT NULL | — |
| `category` | TEXT | NOT NULL | — |
| `note` | TEXT | nullable | — |
| `date` | INTEGER (datetime) | NOT NULL | — |

**Indexes:** none beyond PK.  **Foreign keys:** none.  
**Notes:** `type` is a free-text convention (`"expense"`, `"income"`, `"loan"`). No CHECK constraint. `amount` is `REAL` (IEEE 754 double) — binary floating-point precision risk for monetary values. No currency column, no counterparty, no external transaction ID, no `created_at` / `updated_at`.

---

#### `notes`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement PK |
| `title` | TEXT | NOT NULL | — |
| `content` | TEXT | NOT NULL | — |
| `category` | TEXT | NOT NULL | — |
| `created_at` | INTEGER (datetime) | NOT NULL | — |
| `updated_at` | INTEGER (datetime) | NOT NULL | — |

**Indexes:** none.  **Foreign keys:** none.  **DAO:** `NoteDao` (no `@DriftAccessor` mixin — `NoteDao` does not extend `DatabaseAccessor` correctly; it instantiates `attachedDatabase` fields directly).

---

#### `reminders`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement PK |
| `title` | TEXT | NOT NULL | — |
| `due_at` | INTEGER (datetime) | NOT NULL | — |
| `is_enabled` | INTEGER (bool) | NOT NULL | 1 |

**Indexes:** none.  **Foreign keys:** none.  
**Notes:** `id` is reused as the `flutter_local_notifications` notification ID — coupling schema identity to the notification subsystem. No `task_id` FK, no recurrence, no completed/archived state, no timezone ID, no `created_at`.

---

#### `document_meta`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement PK |
| `file_name` | TEXT | NOT NULL | — |
| `file_type` | TEXT | NOT NULL | — |
| `file_path` | TEXT | NOT NULL | — |
| `size_bytes` | INTEGER | NOT NULL | — |
| `added_at` | INTEGER (datetime) | NOT NULL | — |

**Indexes:** none.  **Foreign keys:** none.  **DAO:** none found.  **Providers:** none found.

---

#### `profile`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | — | 
| `name` | TEXT | NOT NULL | — |
| `role` | TEXT | NOT NULL | — |
| `email` | TEXT | NOT NULL | — |
| `phone` | TEXT | NOT NULL | — |
| `college` | TEXT | NOT NULL | — |
| `semester` | TEXT | NOT NULL | — |
| `photo_path` | TEXT | nullable | — |
| `quote` | TEXT | nullable | — |
| `points` | INTEGER | NOT NULL | 0 |

**PK:** `{id}` (explicit, NOT autoincrement). Always `id = 1`.  
**Indexes:** none beyond PK.  **Foreign keys:** none.  
**Notes:** Hard-coded singleton row. `photo_path` stores a Google avatar URL, not a local file path, despite the name. `quote` is no longer used in the UI but remains in the schema. `points` has no accumulation ledger. No `created_at`, `updated_at`, or `deleted_at`. No account/auth FK.

---

#### `transaction_detection_events`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement PK |
| `event_key` | TEXT | NOT NULL | — |
| `source_package` | TEXT | NOT NULL | — |
| `source_type` | TEXT | NOT NULL | — |
| `title` | TEXT | nullable | — |
| `body` | TEXT | nullable | — |
| `big_text` | TEXT | nullable | — |
| `occurred_at` | INTEGER (datetime) | NOT NULL | — |
| `received_at` | INTEGER (datetime) | NOT NULL | — |

**Indexes:** `event_key` UNIQUE (implicit from `.unique()` call).  
**Foreign keys:** none.  
**Notes:** No FK to `transaction_candidates`. No processing-status column. No retention/deletion policy. Raw notification payloads stored indefinitely (title, body, bigText may contain financial PII).

---

#### `transaction_candidates`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement PK |
| `candidate_id` | TEXT | NOT NULL | — |
| `amount_minor` | INTEGER | NOT NULL | — |
| `currency` | TEXT | NOT NULL | `'INR'` |
| `merchant_name` | TEXT | NOT NULL | `'Unknown'` |
| `merchant_identity` | TEXT | NOT NULL | `'unknown'` |
| `direction` | TEXT | NOT NULL | — |
| `transaction_type` | TEXT | NOT NULL | — |
| `source` | TEXT | NOT NULL | — |
| `bank_confirmation_status` | TEXT | NOT NULL | `'NOT_RECEIVED'` |
| `source_package` | TEXT | nullable | — |
| `occurred_at` | INTEGER (datetime) | NOT NULL | — |
| `reference_id` | TEXT | nullable | — |
| `account_hint` | TEXT | nullable | — |
| `payment_method` | TEXT | nullable | — |
| `balance_after_minor` | INTEGER | nullable | — |
| `raw_event_id` | TEXT | nullable | — |
| `confidence_score` | REAL | NOT NULL | — |
| `status` | TEXT | NOT NULL | — |
| `duplicate_status` | TEXT | NOT NULL | — |
| `category` | TEXT | NOT NULL | `'Other'` |
| `created_at` | INTEGER (datetime) | NOT NULL | — |

**Indexes:** `candidate_id` UNIQUE. `occurred_at` — none (used in range queries).  
**Foreign keys:** `raw_event_id` references `transaction_detection_events.event_key` by text convention only — no actual FK constraint.  
**Notes:** No FK to `money_transactions` once a candidate is confirmed/auto-added. `status` values used in code: `'DETECTED'`, `'PENDING_CONFIRMATION'`, `'CONFIRMED'`, `'AUTO_ADDED'`, `'IGNORED'`, `'DUPLICATE'` — no CHECK constraint. No `updated_at`.

---

#### `merchant_category_rules`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement PK |
| `merchant_identity` | TEXT | NOT NULL | — |
| `category` | TEXT | NOT NULL | — |
| `updated_at` | INTEGER (datetime) | NOT NULL | — |

**Indexes:** `merchant_identity` UNIQUE.  
**Foreign keys:** none.  
**Notes:** No `created_at`. No account owner. No deletion DAO/UI found.

---

#### `youtube_playlists`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement PK |
| `user_id` | TEXT | NOT NULL | — |
| `youtube_playlist_id` | TEXT | NOT NULL | — |
| `title` | TEXT | NOT NULL | — |
| `description` | TEXT | NOT NULL | `''` |
| `channel_title` | TEXT | NOT NULL | `''` |
| `thumbnail_url` | TEXT | NOT NULL | `''` |
| `total_videos` | INTEGER | NOT NULL | 0 |
| `total_duration_seconds` | INTEGER | NOT NULL | 0 |
| `created_at` | INTEGER (datetime) | NOT NULL | — |
| `updated_at` | INTEGER (datetime) | NOT NULL | — |
| `last_synced_at` | INTEGER (datetime) | nullable | — |

**Indexes:** UNIQUE `{user_id, youtube_playlist_id}`.  
**Foreign keys:** none (no FK to an `accounts` table).  
**Notes:** Only table with a user-ownership field (`user_id`). Uses Supabase user UUID or the literal string `'local'` for unauthenticated users. `total_videos` can diverge from actual child count. `created_at` is reset to `now()` on every playlist save because the mapper always supplies a new value.

---

#### `youtube_videos`

| Column | SQLite type | Null | Default |
|---|---|---|---|
| `id` | INTEGER | NOT NULL | autoincrement PK |
| `playlist_local_id` | INTEGER | NOT NULL | — |
| `youtube_video_id` | TEXT | NOT NULL | — |
| `title` | TEXT | NOT NULL | — |
| `thumbnail_url` | TEXT | NOT NULL | `''` |
| `position` | INTEGER | NOT NULL | — |
| `duration_seconds` | INTEGER | NOT NULL | 0 |
| `duration_iso` | TEXT | NOT NULL | `''` |
| `completed` | INTEGER (bool) | NOT NULL | 0 |
| `watched_at` | INTEGER (datetime) | nullable | — |
| `last_position_seconds` | INTEGER | NOT NULL | 0 |
| `created_at` | INTEGER (datetime) | NOT NULL | — |
| `updated_at` | INTEGER (datetime) | NOT NULL | — |

**Indexes:** UNIQUE `{playlist_local_id, youtube_video_id}`.  
**Foreign keys:** `playlist_local_id` → `youtube_playlists(id)`. This is the **only declared FK** in the entire schema. There is no `ON DELETE CASCADE` clause.  
**Notes:** User ownership is indirect (through `playlist_local_id`). `savePlaylist()` deletes **all** child rows then re-inserts them on every refresh; progress fields (`completed`, `watched_at`, `last_position_seconds`) are preserved by looking up the old row before deletion — but only if the `youtubeVideoId` is still present in the new API response. Videos removed from the API response silently lose their progress.

---

### 2.3 DAOs

| DAO | Tables | Missing mixin? |
|---|---|---|
| `TaskDao` | `tasks` | No |
| `MoneyDao` | `money_transactions` | No |
| `ReminderDao` | `reminders` | No |
| `ProfileDao` | `profile` | No |
| `TransactionDetectionDao` | `transaction_detection_events`, `transaction_candidates`, `merchant_category_rules` | No |
| `YoutubePlaylistDao` | `youtube_playlists`, `youtube_videos` | No |
| `NoteDao` | `notes` | **Yes** — no `@DriftAccessor` and no generated mixin; accesses tables via `attachedDatabase.*` directly |

**No DAO exists for:** `class_sessions`, `study_sessions`, `courses`, `document_meta`.

---

## 3. Entity-by-Entity Analysis

### 3.1 YouTube Playlists (`youtube_playlists`)

| Attribute | Value |
|---|---|
| Primary key | `id` (local autoincrement) |
| User ID | `user_id` TEXT — Supabase UUID or `'local'` |
| Persistent? | Yes — survives restart, force-close, reboot, and app update |
| When deleted | Only via `YoutubePlaylistDao.deletePlaylist()` (explicit user action) |
| Depends on | Nothing — no FK to an accounts table |
| Depended on by | `youtube_videos.playlist_local_id` |
| Indexes | UNIQUE `{user_id, youtube_playlist_id}` |
| Missing indexes | Index on `user_id` alone (for `watchForUser` scans) |
| UI query path | `YoutubePlaylistDao.watchForUser(userId)` → `youtubePlaylistsProvider` |
| Scale risk | Low at expected dataset size; `user_id` scan is full-table if no index |

### 3.2 YouTube Videos (`youtube_videos`)

| Attribute | Value |
|---|---|
| Primary key | `id` (local autoincrement) |
| User ID | Indirect — via `playlist_local_id` |
| Persistent? | Progress fields (`completed`, `watched_at`, `last_position_seconds`) are permanent user data. Metadata is refreshable. |
| When deleted | On playlist delete (manual) or wholesale during `savePlaylist()` refresh |
| Depends on | `youtube_playlists.id` (FK declared, no cascade) |
| Depended on by | Nothing |
| Indexes | UNIQUE `{playlist_local_id, youtube_video_id}`; PK |
| Missing indexes | None critical at current scale |
| UI query path | `YoutubePlaylistDao.watchVideos(playlistId)` → `PlaylistDetailsScreen` |
| Scale risk | Low unless a playlist contains thousands of videos |
| Critical risk | `savePlaylist()` deletes all child rows and re-inserts — if API response is incomplete, progress is permanently lost |

### 3.3 To-Dos (`tasks` where `is_planner_entry = 0`)

| Attribute | Value |
|---|---|
| Primary key | `id` (autoincrement) |
| User ID | **None** |
| Persistent? | Incomplete tasks: yes. **Completed tasks are auto-deleted after 7 days at every startup** (`purgeExpiredCompletedTodos()`). Also called in `TodosScreen.initState()`. |
| When deleted | Hard delete via `TaskDao.deleteTask()` or `purgeExpiredCompletedTodos()` |
| Depends on | Nothing |
| Depended on by | Nothing (no FK from reminders) |
| Indexes | None beyond PK |
| Missing indexes | `(is_planner_entry, is_completed, completed_at)` — used in purge and filter queries |
| UI query path | `watchAllTodos()`, `watchHomeTodos()`, `watchUpcomingTasks()`, `watchCompletedTasks()`, `watchTodaysTasks()` |
| Scale risk | Bounded by 7-day purge; no scale risk unless purge is removed |

### 3.4 To-Do Notes (`tasks.description` field, `notes` table)

Two separate "note" systems exist:
- `tasks.description`: a short nullable text on individual tasks.
- `Notes` table: a separate long-form note entity shown in the To-Dos screen under the "Notes" tab. Capped at 15 notes via application logic in `_showNoteAddDialog()`.

| Attribute | Value |
|---|---|
| Primary key (`notes`) | `id` (autoincrement) |
| User ID | **None** |
| Persistent? | Yes — no automatic purge |
| When deleted | Hard delete via `NoteDao.deleteNote()` |
| Depends on / depended on by | Nothing |
| Indexes | None |
| Missing indexes | `updated_at` (used in `watchAllNotes()` ORDER BY) |
| Scale risk | Hard cap of 15 notes; no performance concern |

### 3.5 Planner Events (`tasks` where `is_planner_entry = 1`)

| Attribute | Value |
|---|---|
| Primary key | `id` (autoincrement) |
| User ID | **None** |
| Persistent? | Yes — not subject to 7-day purge |
| When deleted | Hard delete only |
| Depends on | Nothing (reminder FK missing) |
| Depended on by | Heatmap calculation in `DimiActivityHeatmap` |
| Indexes | None beyond PK |
| Missing indexes | `(is_planner_entry, due_date)` — heavily used in date-range queries |
| UI query path | `watchTasksForDate(date)`, `watchTasksForWeek(monday)`, `watchAllPlannerEntries()` |
| Scale risk | Medium — `watchAllPlannerEntries()` returns ALL planner rows ever created; heatmap consumes all rows. After several years this query grows unbounded. |

### 3.6 Reminders (`reminders`)

| Attribute | Value |
|---|---|
| Primary key | `id` (autoincrement), also used as notification ID |
| User ID | **None** |
| Persistent? | Yes — rows are never auto-deleted |
| When deleted | Hard delete via `ReminderDao.deleteReminder()` + `NotificationService.cancelReminder()` |
| Depends on | Nothing |
| Depended on by | Nothing (no FK from tasks) |
| Indexes | None |
| Missing indexes | `(is_enabled, due_at)` — used in `getAllEnabled()`, `watchAllReminders()`, `watchTodaysReminders()` |
| UI query path | Three separate providers watch all/today/upcoming; streams filter by `dueAt >= today` |
| Scale risk | Low — typical user has tens of reminders |
| Orphan risk | Planner add-event creates both a `tasks` row and a `reminders` row. Editing or deleting the task does NOT update or delete the reminder. The reminder row and its scheduled notification can become permanently orphaned. |

### 3.7 Expenses (`money_transactions` where `type = 'expense'`)

| Attribute | Value |
|---|---|
| Primary key | `id` (autoincrement) |
| User ID | **None** |
| Persistent? | Yes |
| When deleted | Hard delete via `MoneyDao.deleteTransaction()` or `deleteSuspiciousDetectedTransactions()` |
| Depends on | Nothing |
| Depended on by | Nothing |
| Indexes | None |
| Missing indexes | `(type, date)` — all list/filter queries scan full table |
| Scale risk | Medium — `watchAllTransactions()` loads everything into memory. Category aggregations in the UI are done in Dart by iterating the full list, not in SQL. |

### 3.8 Income (`money_transactions` where `type = 'income'`)

Same table and structure as expenses. Same risks. No separation of income sources, no employer/payer field.

### 3.9 Lent/Borrowed Money (`money_transactions` where `type = 'loan'`)

Same table as expenses/income. "Lent" and "Borrowed" are expressed only through the `category` field (`'Lent'` or `'Borrowed'`). There is no:
- Counterparty name column
- Repayment status
- Due date for repayment
- Outstanding balance tracking
- Partial repayment history

The Finance screen derives lent/borrowed totals by filtering all transactions in Dart — if there are hundreds of loan records, this is done in a full scan every rebuild.

### 3.10 Transaction Detection Data (`transaction_detection_events`, `transaction_candidates`)

| Attribute | Value |
|---|---|
| User ID | **None** |
| Persistent? | Events: indefinitely (no deletion logic in DAO). Candidates: indefinitely after status change — no cleanup. |
| When deleted | Only via `clearLegacyDemoContent()` (all rows) or individual candidate status updates (no actual row deletion) |
| Raw notification PII | `title`, `body`, `big_text` on `transaction_detection_events` may contain account numbers, balances, transaction amounts — stored indefinitely |
| FK correctness | `raw_event_id` is text only — no FK to `transaction_detection_events.event_key` |
| Indexes | `event_key` UNIQUE; `candidate_id` UNIQUE. No index on `occurred_at` or `status`. |
| Missing indexes | `(status)` on candidates for `watchPending()`; `(occurred_at)` for `recentCandidates()` |
| Scale risk | High — events and candidates grow unbounded with no retention policy |

### 3.11 Merchant/Category Rules (`merchant_category_rules`)

| Attribute | Value |
|---|---|
| User ID | **None** |
| Persistent? | Yes — no deletion flow |
| When deleted | Never (no DAO delete method, no UI) |
| Indexes | `merchant_identity` UNIQUE |
| Scale risk | Low — one row per unique merchant |

### 3.12 Profile/User Data (`profile`)

| Attribute | Value |
|---|---|
| Primary key | `id = 1` (hard-coded singleton) |
| User ID | The row IS the user; no external account ID stored |
| Persistent? | Yes — survives all app lifecycle events except reinstall |
| When deleted | `clearLegacyDemoContent()` when profile name is `'Student'` and email is empty |
| Auth sync | `AuthService.syncLocalProfile()` overwrites `name`, `email`, `photo_path`, and `quote` from Supabase user metadata on every auth state change. Local fields (`role`, `phone`, `college`, `semester`, `points`) are preserved. |
| Multi-account risk | Only one profile row can exist. Different Google accounts will overwrite the same row. |

### 3.13 Heatmap-Related Data

There is **no heatmap table**. Heatmap cells are computed entirely at render time:

1. `allPlannerEntriesProvider` streams **all** `tasks` rows where `is_planner_entry = 1`.
2. `DimiActivityHeatmap` builds `totals` and `completed` maps by grouping on `dateOnly(task.dueDate)`.
3. For each calendar cell: `ratio = completed[day] / totals[day]`; color is determined by ratio bucket.
4. The widget covers the last 12 months (~365 cells), iterating all planner tasks on every rebuild.

**Consequence:** Deleting planner tasks or purging To-Dos directly changes the historical heatmap. There is no immutable event log. The heatmap must not be stored as color/index values — it must remain a derived projection — but the underlying task rows must not be destructively deleted if history is a product requirement.

---

## 4. Relationships

```
youtube_playlists (1) ──── (N) youtube_videos
                            FK: playlist_local_id → youtube_playlists.id
                            (no ON DELETE CASCADE)

All other tables are standalone — no FK relationships declared.
```

**Implicit/convention relationships (no FK enforcement):**

| "Parent" | "Child" | Link | Risk |
|---|---|---|---|
| `tasks` | `reminders` | Same `title` + proximity in time — no FK | Orphaned reminders on task edit/delete |
| `transaction_detection_events` | `transaction_candidates` | `raw_event_id` ≈ `event_key` — text only, no FK | Cannot rely on referential integrity |
| `transaction_candidates` | `money_transactions` | No link at all once confirmed | No traceability from money row to detection source |
| `profile` | All other tables | None — no `owner_id` anywhere | Full cross-user data leakage on logout/relogin |

---

## 5. Index Analysis

### 5.1 Indexes that exist

| Table | Index | Type |
|---|---|---|
| All tables | `id` | PRIMARY KEY (implicit B-tree) |
| `transaction_detection_events` | `event_key` | UNIQUE |
| `transaction_candidates` | `candidate_id` | UNIQUE |
| `merchant_category_rules` | `merchant_identity` | UNIQUE |
| `youtube_playlists` | `{user_id, youtube_playlist_id}` | UNIQUE composite |
| `youtube_videos` | `{playlist_local_id, youtube_video_id}` | UNIQUE composite |

### 5.2 Missing indexes (by query impact)

| Table | Missing index | Query / pattern affected | Impact |
|---|---|---|---|
| `tasks` | `(is_planner_entry, due_date)` | `watchTasksForDate`, `watchTasksForWeek`, `watchAllPlannerEntries` | Full table scan on every date navigation |
| `tasks` | `(is_planner_entry, is_completed, completed_at)` | `watchAllTodos`, `purgeExpiredCompletedTodos` | Full table scan on startup and every stream refresh |
| `tasks` | `(is_planner_entry, is_completed, due_date)` | `watchUpcomingTasks`, `watchTodaysTasks` | Full table scan |
| `money_transactions` | `(type, date)` | All three `watchBy*` queries | Full table scan; category aggregation in Dart |
| `money_transactions` | `(date)` | `watchThisWeeksTransactions` | Full table scan |
| `reminders` | `(is_enabled, due_at)` | `getAllEnabled`, `watchAllReminders`, `watchTodaysReminders`, `watchUpcomingReminders` | Full table scan on startup + every stream |
| `notes` | `(updated_at)` | `watchAllNotes` ORDER BY | Full table scan |
| `transaction_candidates` | `(status)` | `watchPending`, `getPendingCandidates` | Full table scan |
| `transaction_candidates` | `(occurred_at)` | `recentCandidates` | Full table scan |
| `youtube_playlists` | `(user_id)` | `watchForUser` — already partially covered by composite UNIQUE | Single-column index would help if composite is not used by planner |

---

## 6. Query & Performance Analysis

### 6.1 Reactive stream queries

All UI data comes from Drift reactive streams. Each `StreamProvider` creates a persistent SQL subscription. Whenever any row in the watched table changes, Drift re-executes the full query and emits a new list. There are no partial/incremental updates.

### 6.2 N+1 and per-row patterns

| Location | Pattern | Risk |
|---|---|---|
| `TransactionDetectionService.syncPendingEvents()` | For each incoming event: `insertEvent`, parse, `recentCandidates` (range query), conditional `enrichCandidate` + `insertCandidate` + `insertTransaction` + `updateStatus` | Sequential DB calls inside a loop — not batched. With many events, this is O(n) round-trips. |
| `MoneyDao.deleteSuspiciousDetectedTransactions()` | `SELECT` all suspicious rows, then `DELETE` row by row | Should be a single `DELETE … WHERE` |
| `NotificationService.rescheduleAll()` | `cancelAll()` + `scheduleReminder()` for each row | O(n) notification scheduling; acceptable at typical scale |
| `_WeekView` | Merges `upcomingTasksProvider` + `allTasksProvider`, deduplicates in Dart | Subscribes to two streams, loads all tasks into memory, filters by date in Dart — not a targeted query |

### 6.3 In-memory aggregations (potential scale issues)

| Screen / widget | Pattern | Scale risk |
|---|---|---|
| `MoneyScreen` — Overview | All transactions loaded, filtered + summed in Dart (`fold`) | Medium — degrades linearly with transaction count |
| `MoneyScreen` — Categories tab | Iterates all transactions to build category totals | Medium — no SQL `GROUP BY` |
| `DimiActivityHeatmap` | Iterates **all** planner tasks to build date maps for the last 12 months | Medium → High — `watchAllPlannerEntriesProvider` grows unbounded over lifetime |
| `_PremiumMonthView` — stats | Re-iterates all planner tasks for month/streak calculation | Same as above |

### 6.4 `watchTodaysTasks()` time boundary bug

```dart
// From TaskDao:
t.dueDate.isBetweenValues(
  DateTime.now(),       // ← evaluated at query build time, not midnight
  DateTime.now().add(const Duration(days: 1)),
)
```

The lower bound is `DateTime.now()` (current instant), not `DateTime(y, m, d)` (start of today). Tasks created earlier today with a `due_date` before the current moment are excluded from "today's tasks" in the Home screen's `homeTodosProvider` indirectly. (`watchHomeTodos` uses a correct `startOfToday` boundary; `watchTodaysTasks` does not.)

### 6.5 `allPlannerEntriesProvider` unbounded growth

`watchAllPlannerEntries()` returns every planner task ever created with no date filter. Used as the input to the heatmap (Home + Planner Month view). After several years of use, this query will return thousands of rows. The heatmap only displays the last 12 months, so the excess rows are loaded into memory and silently discarded.

---

## 7. Persistence & Deletion Analysis

### 7.1 Startup lifecycle (what runs before first frame)

```
main()
  ├── SupabaseBootstrap.initialize()          // auth session restore
  ├── NotificationService.init()              // permission + plugin init
  ├── AppDatabase()                           // SQLite open
  ├── db.clearLegacyDemoContent()             // DESTRUCTIVE if profile.name == 'Student' && email == ''
  ├── db.taskDao.purgeExpiredCompletedTodos() // DESTRUCTIVE — deletes completed non-planner tasks > 7 days old
  ├── TransactionDetectionService.syncPendingEvents() // reads Android SharedPreferences, writes to Drift
  ├── AuthService.syncLocalProfile(db)        // overwrites profile row from Supabase user
  └── db.reminderDao.getAllEnabled()          // reads → NotificationService.rescheduleAll()
```

### 7.2 Per-entity retention summary

| Entity | Retention classification | Current behavior | Correct behavior |
|---|---|---|---|
| Profile | PERMANENT | Single row; overwritten by auth sync; deleted by `clearLegacyDemoContent` heuristic | Permanent until explicit account deletion |
| To-Dos (incomplete) | PERMANENT | Kept until user deletes or purge fires | Permanent until user deletes |
| To-Dos (completed) | PERMANENT by product intent | **Auto-deleted after 7 days at startup and in `TodosScreen.initState()`** | Retain permanently OR explicit archive — not silent background delete |
| Planner events | PERMANENT | Hard delete only | Permanent; consider archiving past events for heatmap stability |
| Money transactions | PERMANENT | Hard delete only | Permanent until explicit user delete |
| Reminders | PERMANENT | Never deleted automatically; past rows hidden in UI by `dueAt` filter | Permanent; archive past reminders rather than silently accumulating |
| Notes | PERMANENT | Hard delete only; UI cap at 15 | Permanent until user delete |
| Detection events | TEMPORARY/CACHE | **No deletion logic** — rows accumulate indefinitely | Delete after 30–90 days or after processing |
| Detection candidates | TEMPORARY→AUDIT | Status updated but rows never deleted | Delete IGNORED/DUPLICATE after 30 days; retain CONFIRMED for audit |
| Merchant rules | PERMANENT preference | Never deleted | Permanent until user/account delete |
| YouTube playlist metadata | CACHE | Refreshable; entire metadata replaced on sync | Refresh on open; retain with `lastSyncedAt` |
| YouTube video progress | PERMANENT | Preserved during refresh only if video still in API response | Preserve unconditionally; never delete with metadata refresh |
| Document metadata | UNKNOWN | No lifecycle found | Define before enabling feature |
| ClassSessions / StudySessions / Courses | UNKNOWN | No DAO/provider/UI lifecycle | Define before enabling feature |

### 7.3 Hard deletes — no soft delete / tombstone anywhere

All deletes in the current codebase are hard `DELETE FROM` statements. There are no:
- `deleted_at` columns
- tombstone / outbox tables
- audit log entries

This means:
- Deleted records are irrecoverable by the user.
- A future Supabase sync layer has no way to propagate deletions without tombstones.

---

## 8. Multi-Account & Local Ownership Analysis

### 8.1 Owner ID coverage

| Table | Has owner/account ID? |
|---|---|
| `tasks` | ❌ No |
| `class_sessions` | ❌ No |
| `study_sessions` | ❌ No |
| `courses` | ❌ No |
| `money_transactions` | ❌ No |
| `notes` | ❌ No |
| `reminders` | ❌ No |
| `document_meta` | ❌ No |
| `profile` | ❌ No (the row IS id=1) |
| `transaction_detection_events` | ❌ No |
| `transaction_candidates` | ❌ No |
| `merchant_category_rules` | ❌ No |
| `youtube_playlists` | ✅ `user_id` (Supabase UUID or `'local'`) |
| `youtube_videos` | ⚠️ Indirect only — through `playlist_local_id` |

### 8.2 Logout behavior

Logout calls `SupabaseBootstrap.client.auth.signOut()`. **There is no code that:**
- Clears any Drift table rows
- Cancels scheduled notifications
- Purges SharedPreferences (beyond what the Supabase SDK manages internally)
- Resets the `databaseProvider`

All local data (tasks, money, reminders, notes, profile, detection events/candidates, merchant rules) **survives logout** and is immediately visible to the next user who logs in on the same device.

### 8.3 Account switch scenario

**User A logs in → creates tasks, expenses, reminders → logs out → User B logs in:**

- User B sees User A's tasks, money, reminders, notes, and detection data. ← **Critical data leak**
- `youtube_playlists` correctly filters by `user_id` — User B sees their own playlists.
- However, `watchById`, `watchVideos`, `setCompleted`, and `deletePlaylist` on `YoutubePlaylistDao` accept raw local IDs and do **not** re-validate the current user — a caller with a stale ID could access User A's playlist.
- The `'local'` user ID is a shared bucket for **all** unauthenticated users on the same device.

### 8.4 `clearLegacyDemoContent()` — destructive heuristic

```dart
if (profile?.name != 'Student' || profile?.email.isNotEmpty == true) {
  return; // safe
}
// Otherwise: DELETE tasks, money_transactions, reminders,
//            transaction_detection_events, transaction_candidates,
//            merchant_category_rules, profile rows.
```

This runs at **every app startup**. Any real user whose profile name happens to be `'Student'` and whose email is empty (e.g. offline-mode user who hasn't typed their name yet) will have all major data silently deleted on every launch.

---

## 9. Migration & Schema Version Analysis

### 9.1 Migration history

| Version | Change |
|---|---|
| 1 (onCreate) | All tables created via `m.createAll()` |
| v1 → v2 | `addColumn(tasks, tasks.completedAt)` |
| v2 → v3 | `addColumn(tasks, tasks.isPlannerEntry)` |
| v3 → v4 | `addColumn(tasks, tasks.plannedMinutes)` + `addColumn(tasks, tasks.completedMinutes)` |
| v4 → v5 | `createTable(transactionDetectionEvents)` + `createTable(transactionCandidates)` + `createTable(merchantCategoryRules)` |
| v5 → v6 | `addColumn(transactionCandidates, .accountHint)` + `.paymentMethod` + `.balanceAfterMinor` |
| v6 → v7 | `addColumn(transactionCandidates, .bankConfirmationStatus)` |
| v7 → v8 | `createTable(youtubePlaylists)` + `createTable(youtubeVideos)` |

### 9.2 Migration gaps

- Migrations use **cumulative guards** (`if (from < N)`). A device that is two versions behind will run multiple migration blocks in one upgrade — this is correct.
- There are **no migration tests**. A user upgrading from v1 to v8 in one step has not been tested.
- Newly added columns that have `NOT NULL` defaults (e.g. `is_planner_entry DEFAULT 0`, `planned_minutes DEFAULT 60`) are safe for `addColumn` because Drift emits `ALTER TABLE … ADD COLUMN … DEFAULT …`. However this is not verified by a test.
- `notes.category` and `notes.content` are `NOT NULL` but the table was created in `onCreate` — safe.
- **There is no rollback mechanism.** A migration that partially succeeds leaves the database in an inconsistent state.
- The `database.g.dart` generated file is the implementation source; the schema definitions in `lib/data/tables/*.dart` are the design source of truth.

### 9.3 `AppDatabase.forTesting(executor)` constructor

An in-memory test constructor exists. No test files were found that use it.

---

## 10. Problems Found

Problems are ranked by severity.

### 🔴 Critical

**C1. Cross-user data leak on logout/re-login**  
Every table except `youtube_playlists` has no owner ID. All user data (tasks, money, reminders, notes, detection data, merchant rules, profile) persists through logout and is visible to any subsequent user on the same device.  
*Affects:* all screens.

**C2. Silent destruction of completed To-Dos every startup**  
`purgeExpiredCompletedTodos()` is called in `main()` AND in `TodosScreen.initState()`. Any completed non-planner task older than 7 days is permanently and silently deleted. This makes heatmap history inconsistent and loses user data without consent.  
*Affects:* `lib/main.dart`, `lib/screens/todos/todos_screen.dart`, `lib/data/daos/task_dao.dart`.

**C3. `clearLegacyDemoContent()` destroys real user data**  
The heuristic (`name == 'Student' && email.isEmpty`) can match real offline users. All their tasks, money, reminders, and detection data are deleted at every startup.  
*Affects:* `lib/data/database.dart`.

**C4. YouTube progress destroyed on playlist refresh**  
`savePlaylist()` deletes all `youtube_videos` rows for a playlist, then re-inserts from the API response. If any video is missing from the new API response (deleted from playlist, API error, partial response), its `completed`, `watched_at`, and `last_position_seconds` values are **permanently lost**.  
*Affects:* `lib/data/daos/youtube_playlist_dao.dart`.

### 🟠 High

**H1. Task ↔ Reminder coupling is broken**  
Planner add-event creates both a `tasks` row and a `reminders` row with `tasks.reminder_minutes_before` storing metadata. Editing or deleting a task does NOT update or delete the paired reminder row or cancel the scheduled notification. Orphaned reminders accumulate.  
*Affects:* `lib/widgets_modals/add_task_sheet.dart`, `lib/data/daos/task_dao.dart`, `lib/data/daos/reminder_dao.dart`.

**H2. Floating-point money storage**  
`money_transactions.amount` is `REAL` (IEEE 754 double). Repeated addition/subtraction of financial amounts can produce rounding errors (e.g. `0.1 + 0.2 ≠ 0.3`). `transaction_candidates` correctly uses integer minor units; the final persisted row loses this precision.  
*Affects:* `lib/data/tables/transactions.dart`, all money write paths.

**H3. Raw financial notification PII stored indefinitely**  
`transaction_detection_events` stores raw notification `title`, `body`, and `big_text` with no retention policy. These may contain account numbers, balances, and transaction details. No deletion DAO or scheduled cleanup exists.  
*Affects:* `lib/data/tables/transaction_detection.dart`, `lib/data/daos/transaction_detection_dao.dart`.

**H4. No indexes on high-traffic query columns**  
Key queries (`watchTasksForDate`, `watchTasksForWeek`, `watchAllPlannerEntries`, `watchThisWeeksTransactions`, `getAllEnabled`) perform full table scans. As data grows, these will cause visible jank on stream refresh.  
*Affects:* all DAO files.

**H5. `watchAllPlannerEntriesProvider` is unbounded**  
The heatmap widget subscribes to all planner tasks ever created with no date window. After years of use this stream will grow into thousands of rows and be loaded into memory on every rebuild.  
*Affects:* `lib/data/daos/task_dao.dart`, `lib/widgets/dimi_activity_heatmap.dart`.

**H6. In-memory financial aggregations on full dataset**  
Category totals, balance, lent/borrowed summaries are computed by iterating all `money_transactions` rows in Dart on every `allTransactionsProvider` emission. No SQL `SUM` or `GROUP BY` is used.  
*Affects:* `lib/screens/money/money_screen.dart`.

### 🟡 Medium

**M1. No soft delete / tombstones**  
Hard deletes everywhere make future Supabase sync impossible without separate tombstone tables. All deletes are irreversible.

**M2. No migration tests**  
Upgrades from any schema version to v8 are untested.

**M3. `watchTodaysTasks()` lower bound is current instant, not midnight**  
Tasks due earlier today are excluded from "today" query. (`watchHomeTodos` is correct; `watchTodaysTasks` is not.)  
*Affects:* `lib/data/daos/task_dao.dart`.

**M4. `NoteDao` does not use `@DriftAccessor`**  
`NoteDao` has no generated mixin. It manually accesses `attachedDatabase.notes`. Drift's manager API and type checking are unavailable for this DAO.  
*Affects:* `lib/data/daos/note_dao.dart`.

**M5. Reminder `id` reused as notification ID**  
If a reminder is deleted and a new one gets the same autoincrement `id`, a stale scheduled notification from the old reminder may be incorrectly cancelled or replaced.

**M6. `'local'` userId is a shared multi-user bucket**  
All unauthenticated users on the same device share the `'local'` YouTube playlist namespace.

**M7. No timezone or DST model**  
`due_at` (reminders) and `due_date` (tasks) are stored as local `DateTime` values with no IANA timezone ID. Daylight saving time transitions or device timezone changes can cause reminders to fire at the wrong time.

**M8. Loan data model is insufficient**  
`type = 'loan'` with `category = 'Lent'/'Borrowed'` has no counterparty, repayment status, due date, or partial repayment history. The "Available Balance" card calculation mixes loans into income/expense arithmetic.

**M9. Orphaned tables with no DAO/UI lifecycle**  
`class_sessions`, `study_sessions`, `courses`, `document_meta` are registered in `AppDatabase` and will have empty tables created at `onCreate`, but there is no DAO, provider, screen, or migration path for them. Their intended lifecycle is unknown.

**M10. `tasks.planned_minutes` and `completed_minutes` are dead fields**  
These were presumably intended for a study-time tracker but the current heatmap and stats use task count / completion ratio, not minutes. Both fields default to fixed values and are never meaningfully populated.

**M11. `profile.photo_path` stores a URL, not a path**  
The field name implies a local file path, but it stores Google avatar URLs (`https://...`). Misleading for future developers.

**M12. `profile.quote` is dead schema**  
The UI no longer displays or edits this field, but it remains in every profile upsert path.

**M13. `deleteSuspiciousDetectedTransactions()` loops row-by-row**  
Fetches all suspicious rows then deletes them one at a time. Should be a single `DELETE … WHERE`.

**M14. YouTube `created_at` reset on every sync**  
The repository/mapper always passes `createdAt: DateTime.now()` in the companion, resetting the creation timestamp on every metadata refresh for existing playlists.

**M15. `transaction_candidates.occurred_at` has no index for range queries**  
`recentCandidates(since)` performs a full table scan on every event sync cycle (every 15 seconds while the app is foregrounded).

---

## 11. Recommended Changes

These are recommendations only — no code has been changed.

### Immediate (before any feature work)

1. **Add account ownership.** Add an `accounts` table (or reuse Supabase user ID directly) and an `owner_id` column to every user-owned table. All DAO queries must filter by the active owner. Logout must switch the active account context, not silently leave data accessible.

2. **Remove or gate `purgeExpiredCompletedTodos()`.** If completed task history is a product requirement (for heatmaps or lifetime productivity stats), this purge must be removed. If it is intentional, it must be made explicit and user-controlled, and not run at startup without consent.

3. **Replace `clearLegacyDemoContent()` with a one-time versioned flag.** Use a `SharedPreferences` boolean `demo_cleared_v1` so this cleanup runs exactly once, not on every startup.

4. **Add critical indexes.** At minimum: `(is_planner_entry, due_date)` on `tasks`; `(type, date)` on `money_transactions`; `(is_enabled, due_at)` on `reminders`; `(status)` and `(occurred_at)` on `transaction_candidates`.

5. **Fix YouTube refresh to use UPSERT, not delete+reinsert.** Use `insertOnConflictUpdate` for video rows keyed on `{playlist_local_id, youtube_video_id}` so progress fields are never lost.

6. **Add a retention/deletion DAO for `transaction_detection_events`.** Delete events older than 30–90 days. Delete processed (`CONFIRMED`, `AUTO_ADDED`, `IGNORED`) candidates after 90 days.

### Near-term

7. **Convert `money_transactions.amount` to integer minor units.** Add a `currency` column. Migrate existing `REAL` values by rounding to nearest minor unit with a documented policy.

8. **Link tasks and reminders with a FK.** Add `task_id` (nullable FK) to `reminders`. Update task edit/delete paths to transactionally update or cancel the paired reminder and notification.

9. **Add soft-delete columns (`deleted_at`) to all tables that will sync to Supabase.** Required for proper tombstone propagation.

10. **Add a date-range filter to `watchAllPlannerEntries`.** Limit to the last N months (e.g. 18 months) to bound heatmap query size. Archive older rows rather than deleting them.

11. **Move financial aggregations to SQL.** Use `SUM` / `GROUP BY` in DAO queries instead of iterating full lists in Dart widgets.

12. **Fix `watchTodaysTasks()` lower bound** to `DateTime(y, m, d)` (midnight today).

13. **Give `NoteDao` a proper `@DriftAccessor` annotation and generated mixin.**

14. **Model loans as a separate entity** with counterparty, direction, repayment status, due date, and repayment history.

15. **Add a timezone ID column** to `reminders.due_at` and `tasks.due_date` / `due_time` for correct DST handling.

### Long-term / pre-Supabase sync

16. **Introduce a repository layer** between screens and DAOs so sync, account switching, and caching logic have a single place to live.

17. **Add migration tests** for every supported upgrade path (v1→v8, v2→v8, …, v7→v8) using `AppDatabase.forTesting(inMemoryExecutor)`.

18. **Implement account deletion** as a single Drift transaction that hard-deletes all owner-scoped rows, cancels all notifications, and clears the Supabase session.

19. **Remove dead schema.** Drop `profile.quote`, `tasks.planned_minutes`, `tasks.completed_minutes` (after verifying no screen relies on them), and retire the orphaned tables (`class_sessions`, `study_sessions`, `courses`, `document_meta`) or fully implement their DAO/screen lifecycle.

---

## 12. Files That Would Need to Change

### Schema changes

| File | Change needed |
|---|---|
| `lib/data/tables/tasks.dart` | Add `owner_id`; add index annotations; remove `planned_minutes` / `completed_minutes` if confirmed dead; add `updated_at`; `due_time` validation |
| `lib/data/tables/transactions.dart` | Change `amount REAL` → `amount_minor INTEGER`; add `currency TEXT`; add `owner_id`; add `created_at`; add `updated_at` |
| `lib/data/tables/reminders.dart` | Add `owner_id`; add `task_id` FK (nullable); add `created_at`; add `updated_at`; add `timezone_id` |
| `lib/data/tables/notes.dart` | Add `owner_id` |
| `lib/data/tables/profile.dart` | Add `updated_at`; rename `photo_path` → `avatar_url`; remove `quote` |
| `lib/data/tables/transaction_detection.dart` | Add retention/expiry columns; add FK annotation on `raw_event_id` |
| `lib/data/tables/youtube_playlists.dart` | No owner change needed — `user_id` exists; fix `created_at` mapping |
| `lib/data/tables/youtube_videos.dart` | Add `ON DELETE CASCADE` to FK declaration |
| New: `lib/data/tables/loans.dart` | Separate loan entity |
| Retire/implement: `class_sessions.dart`, `study_sessions.dart`, `courses.dart`, `document_meta.dart` | Decide fate |

### DAO changes

| File | Change needed |
|---|---|
| `lib/data/daos/task_dao.dart` | Scope all queries by `owner_id`; fix `watchTodaysTasks` lower bound; add date-range filter to `watchAllPlannerEntries`; remove or replace `purgeExpiredCompletedTodos` |
| `lib/data/daos/money_dao.dart` | Scope by `owner_id`; convert to integer minor units; add SQL aggregation queries; fix `deleteSuspiciousDetectedTransactions` to single DELETE |
| `lib/data/daos/reminder_dao.dart` | Scope by `owner_id`; link to task_id |
| `lib/data/daos/note_dao.dart` | Add `@DriftAccessor`; scope by `owner_id` |
| `lib/data/daos/profile_dao.dart` | No major change — already singleton; add `updated_at` |
| `lib/data/daos/transaction_detection_dao.dart` | Add delete-by-age methods; fix `recentCandidates` after adding index |
| `lib/data/daos/youtube_playlist_dao.dart` | Fix `savePlaylist` to UPSERT videos instead of delete+insert; fix `created_at` not being reset on update |
| New: `lib/data/daos/loan_dao.dart` | Loan entity CRUD |

### Database / migration

| File | Change needed |
|---|---|
| `lib/data/database.dart` | Increment `schemaVersion`; write migrations for all new columns/tables/indexes; remove `clearLegacyDemoContent` or replace with one-time flag; register new DAO |

### Application logic

| File | Change needed |
|---|---|
| `lib/main.dart` | Remove startup `purgeExpiredCompletedTodos` call; replace `clearLegacyDemoContent` with versioned flag; add account context initialization |
| `lib/screens/todos/todos_screen.dart` | Remove `purgeExpiredCompletedTodos` from `initState` |
| `lib/widgets_modals/add_task_sheet.dart` | Transactionally link new planner task to reminder; update/cancel reminder on task edit |
| `lib/widgets/dimi_activity_heatmap.dart` | Accept date-bounded task list instead of all-time list |
| `lib/screens/money/money_screen.dart` | Replace Dart-side aggregation with DAO queries |
| `lib/services/auth_service.dart` | Add logout cleanup: clear local user data, cancel notifications, reset account context |
| `lib/providers/task_providers.dart` | Scope all providers by active account |
| `lib/providers/money_providers.dart` | Scope all providers by active account |
| `lib/providers/reminder_providers.dart` | Scope all providers by active account |
| `lib/providers/note_providers.dart` | Scope all providers by active account |
| `lib/features/transaction_detection/transaction_detection_service.dart` | Batch insertions; add owner scoping |

### Tests (new files)

| File | Purpose |
|---|---|
| `test/data/migration_test.dart` | Test every schema upgrade path using `AppDatabase.forTesting` |
| `test/data/dao/task_dao_test.dart` | Test date boundaries, purge logic, planner/todo separation |
| `test/data/dao/money_dao_test.dart` | Test amount precision, type filtering, aggregations |
| `test/data/dao/reminder_dao_test.dart` | Test enable/disable, scheduling, orphan cleanup |
| `test/data/dao/youtube_playlist_dao_test.dart` | Test progress preservation during refresh |
| `test/data/account_isolation_test.dart` | Verify no data leaks between two different `owner_id` values |
