# DIMI — Target Local Drift/SQLite Schema

**Status:** Design document only. No code has been changed.  
**Based on:** `docs/LOCAL_DATABASE_AUDIT.md` · `docs/LOCAL_DATABASE_CHANGE_PLAN.md`  
**Target schema version:** 9 (current is 8)  
**Date:** 2026-09-18

---

## Table of Contents

- [A. Target Table List](#a-target-table-list)
- [B–G. Full Column Definitions per Table](#bg-full-column-definitions-per-table)
- [H. Ownership / Account Strategy](#h-ownership--account-strategy)
- [I. Lifecycle Strategy](#i-lifecycle-strategy)
- [J. YouTube Metadata / Progress Strategy](#j-youtube-metadata--progress-strategy)
- [K. To-Do Lifecycle Strategy](#k-to-do-lifecycle-strategy)
- [L. Planner / Reminder Relationship](#l-planner--reminder-relationship)
- [M. Finance Monetary Storage Strategy](#m-finance-monetary-storage-strategy)
- [N. Heatmap Query Strategy](#n-heatmap-query-strategy)
- [O. Sync-Readiness Considerations](#o-sync-readiness-considerations)
- [P. Tables to Remove](#p-tables-to-remove)
- [Q. Tables to Retain As-Is](#q-tables-to-retain-as-is)
- [R. Tables to Redesign](#r-tables-to-redesign)
- [S. Decisions Requiring Confirmation](#s-decisions-requiring-confirmation)

---

## A. Target Table List

| # | Dart class | SQLite table name | Status vs v8 |
|---|---|---|---|
| 1 | `LocalAccounts` | `local_accounts` | **NEW** |
| 2 | `Tasks` | `tasks` | **REDESIGNED** |
| 3 | `Reminders` | `reminders` | **REDESIGNED** |
| 4 | `Notes` | `notes` | **REDESIGNED** |
| 5 | `MoneyTransactions` | `money_transactions` | **REDESIGNED** |
| 6 | `Loans` | `loans` | **NEW** |
| 7 | `YoutubePlaylists` | `youtube_playlists` | **REDESIGNED** |
| 8 | `YoutubeVideos` | `youtube_videos` | **REDESIGNED** |
| 9 | `TransactionDetectionEvents` | `transaction_detection_events` | **REDESIGNED** |
| 10 | `TransactionCandidates` | `transaction_candidates` | **REDESIGNED** |
| 11 | `MerchantCategoryRules` | `merchant_category_rules` | **REDESIGNED** |
| 12 | `ProfileData` | `profile_data` | **REDESIGNED** (replaces `profile`) |
| 13 | `ClassSessions` | `class_sessions` | **RETAINED** (pending activation — see §S) |
| 14 | `StudySessions` | `study_sessions` | **RETAINED** (pending activation — see §S) |
| 15 | `Courses` | `courses` | **RETAINED** (pending activation — see §S) |
| 16 | `DocumentMeta` | `document_meta` | **RETAINED** (pending activation — see §S) |

**Removed from v8:** The old `profile` table (singleton `id=1`) is replaced by
`profile_data` + `local_accounts`. The old `profile` rows are migrated during
the v8→v9 upgrade.

---

## B–G. Full Column Definitions per Table

Each table section covers:
**B** Columns + types · **C** Primary key · **D** Foreign keys · **E** ON DELETE
· **F** Unique constraints · **G** Indexes

---

### Table 1 — `local_accounts`

**Purpose:** One row per distinct identity that has ever been used on this
device. Every other user-owned table carries a `local_account_id` FK to this
table instead of storing a raw auth UUID string. This is the single
authoritative account registry.

#### B. Columns

| Column | Drift type | SQLite type | Null | Default | Notes |
|---|---|---|---|---|---|
| `id` | `IntColumn autoIncrement` | INTEGER | NOT NULL | — | Local surrogate PK |
| `auth_provider` | `TextColumn` | TEXT | NOT NULL | — | `'google'` · `'offline'` · future providers |
| `auth_user_id` | `TextColumn` | TEXT | nullable | — | Supabase/Google UUID; null for offline accounts |
| `email` | `TextColumn` | TEXT | nullable | — | From auth provider; null for offline |
| `display_name` | `TextColumn` | TEXT | NOT NULL | `''` | User-editable display name |
| `avatar_url` | `TextColumn` | TEXT | nullable | — | Remote URL; updated on auth sync |
| `is_active` | `BoolColumn` | INTEGER | NOT NULL | 1 | Only one row has `is_active = 1` at a time |
| `created_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | When this account was first used |
| `last_login_at` | `DateTimeColumn` | INTEGER | nullable | — | Updated on each successful auth |

#### C. Primary key
`id` INTEGER PRIMARY KEY AUTOINCREMENT

#### D. Foreign keys
None. This is the root identity table.

#### E. ON DELETE
N/A — root table.

#### F. Unique constraints
- UNIQUE `(auth_provider, auth_user_id)` — prevents the same Google account
  being registered twice. The `(auth_provider, auth_user_id)` pair is the
  natural account identity key for deduplication on login.

#### G. Indexes
- PK (implicit)
- UNIQUE `(auth_provider, auth_user_id)` — used on login to find or create the
  account row; also covers `auth_user_id` lookups.
- Index on `(is_active)` — used on every app startup to resolve the active
  account with a single lookup; justified because this query runs before any
  other data load.

**Design note — why integer surrogate PK instead of UUID:**
All other tables carry `local_account_id INTEGER` as a FK. An integer FK is
4–8 bytes vs 36 bytes for a UUID string, and SQLite joins on integers are
faster than text equality. The Supabase UUID lives in `auth_user_id` and is
used only during auth sync, not in local FK chains. This keeps local reads
fast while remaining sync-ready (the `auth_user_id` is the cloud-side key).

---

### Table 2 — `tasks`

**Purpose:** Stores both To-Do items and Planner events, discriminated by
`is_planner_entry`. This dual-purpose design is retained because both entity
types share nearly identical fields and are managed by overlapping UI flows.
The separation is enforced at the query layer.

#### B. Columns

| Column | Drift type | SQLite type | Null | Default | Notes |
|---|---|---|---|---|---|
| `id` | `IntColumn autoIncrement` | INTEGER | NOT NULL | — | Local surrogate PK |
| `local_account_id` | `IntColumn` | INTEGER | NOT NULL | — | FK → `local_accounts.id` |
| `title` | `TextColumn` | TEXT | NOT NULL | — | — |
| `description` | `TextColumn` | TEXT | nullable | — | Short optional note |
| `category` | `TextColumn` | TEXT | NOT NULL | — | Free-form; validated in UI |
| `is_planner_entry` | `BoolColumn` | INTEGER | NOT NULL | 0 | `0` = To-Do · `1` = Planner |
| `local_date` | `DateTimeColumn` | INTEGER | NOT NULL | — | Date component only (midnight UTC); **replaces `due_date`** |
| `due_time_hhmm` | `TextColumn` | TEXT | nullable | — | `"HH:mm"` 24h format. Planner entries require non-null; validated in UI. Renamed from `due_time` for clarity. |
| `is_completed` | `BoolColumn` | INTEGER | NOT NULL | 0 | — |
| `completed_at` | `DateTimeColumn` | INTEGER | nullable | — | Local wall-clock time of completion |
| `created_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Immutable creation timestamp |
| `updated_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Updated on every write |

**Removed from v8:**
- `planned_minutes` — never meaningfully populated; heatmap uses task counts
- `completed_minutes` — same as above
- `reminder_minutes_before` — intent-only field with no FK; reminder is now
  linked via `reminders.task_id` (see Table 3)

#### C. Primary key
`id` INTEGER PRIMARY KEY AUTOINCREMENT

#### D. Foreign keys
- `local_account_id` → `local_accounts(id)`

#### E. ON DELETE
- `local_account_id`: **RESTRICT** — prevents deleting an account while it
  still owns tasks. Account deletion must be a deliberate transaction that
  removes tasks first.

#### F. Unique constraints
None beyond PK.

#### G. Indexes

| Index | Columns | Justification |
|---|---|---|
| PK | `(id)` | Implicit |
| idx_tasks_account_planner_date | `(local_account_id, is_planner_entry, local_date)` | Covers `watchTasksForDate`, `watchTasksForWeek`, `watchAllPlannerEntries(since)`, and the heatmap date-range query. Leading `local_account_id` scopes to active account first. |
| idx_tasks_account_todo_completed | `(local_account_id, is_planner_entry, is_completed, completed_at)` | Covers `watchAllTodos`, `watchHomeTodos`, `watchUpcomingTasks`, `watchTodaysTasks`. |
| idx_tasks_created_at | `(local_account_id, is_planner_entry, created_at)` | Covers `watchAllTasks` ORDER BY `created_at DESC` — the default To-Do list sort. |

Three indexes on one table is justified: `tasks` is the most-queried table in
the app with multiple distinct query shapes used by different screens
simultaneously. Each index serves a distinct, high-frequency access pattern.

---

### Table 3 — `reminders`

**Purpose:** User-created scheduled reminders. Planner events may own a
reminder via `task_id`. Standalone reminders (`task_id IS NULL`) remain fully
supported.

#### B. Columns

| Column | Drift type | SQLite type | Null | Default | Notes |
|---|---|---|---|---|---|
| `id` | `IntColumn autoIncrement` | INTEGER | NOT NULL | — | Local surrogate PK |
| `local_account_id` | `IntColumn` | INTEGER | NOT NULL | — | FK → `local_accounts.id` |
| `task_id` | `IntColumn` | INTEGER | nullable | — | FK → `tasks.id`; null for standalone reminders |
| `notification_id` | `IntColumn` | INTEGER | NOT NULL | — | **Separate from `id`**; stable handle for `flutter_local_notifications`. Decoupled so notification cancellation is not broken if the reminder row is deleted and another gets the same autoincrement `id`. |
| `title` | `TextColumn` | TEXT | NOT NULL | — | — |
| `due_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Local DateTime |
| `is_enabled` | `BoolColumn` | INTEGER | NOT NULL | 1 | — |
| `created_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | — |
| `updated_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | — |

#### C. Primary key
`id` INTEGER PRIMARY KEY AUTOINCREMENT

#### D. Foreign keys
- `local_account_id` → `local_accounts(id)`
- `task_id` → `tasks(id)` (nullable)

#### E. ON DELETE
- `local_account_id`: **RESTRICT**
- `task_id`: **SET NULL** — if a standalone reminder references a task that is
  deleted independently, it survives. For Planner event deletions the
  application layer explicitly deletes the reminder in the same transaction
  (see §L).

#### F. Unique constraints
- UNIQUE `(notification_id)` — each OS notification slot must be held by
  exactly one reminder row.

#### G. Indexes

| Index | Columns | Justification |
|---|---|---|
| PK | `(id)` | Implicit |
| idx_reminders_account_enabled_due | `(local_account_id, is_enabled, due_at)` | Covers `getAllEnabled()` (startup reschedule), `watchAllReminders`, `watchTodaysReminders`, `watchUpcomingReminders`. |
| idx_reminders_task_id | `(task_id)` | Covers the lookup `deleteReminderByTaskId(taskId)`. Without this, that delete is a full table scan. |

---

### Table 4 — `notes`

**Purpose:** Short-form saved notes, accessible from the To-Dos screen. The
15-note application cap is a UI/business rule, not enforced at the DB level.

#### B. Columns

| Column | Drift type | SQLite type | Null | Default | Notes |
|---|---|---|---|---|---|
| `id` | `IntColumn autoIncrement` | INTEGER | NOT NULL | — | — |
| `local_account_id` | `IntColumn` | INTEGER | NOT NULL | — | FK → `local_accounts.id` |
| `title` | `TextColumn` | TEXT | NOT NULL | — | — |
| `content` | `TextColumn` | TEXT | NOT NULL | — | — |
| `category` | `TextColumn` | TEXT | NOT NULL | `'General'` | Free-form tag |
| `created_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | — |
| `updated_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Default sort key |

#### C. Primary key
`id` INTEGER PRIMARY KEY AUTOINCREMENT

#### D. Foreign keys
`local_account_id` → `local_accounts(id)`

#### E. ON DELETE
`local_account_id`: **RESTRICT**

#### F. Unique constraints
None.

#### G. Indexes

| Index | Columns | Justification |
|---|---|---|
| PK | `(id)` | Implicit |
| idx_notes_account_updated | `(local_account_id, updated_at DESC)` | The only query pattern on notes is `watchAllNotes()` filtered by owner and sorted by `updated_at DESC`. One index covers both. |

---

### Table 5 — `money_transactions`

**Purpose:** Permanent record of all financial cash-flow activity: expenses,
income, loan disbursements/receipts, and repayments. See §M for monetary
storage rationale and the full loan model.

#### B. Columns

| Column | Drift type | SQLite type | Null | Default | Notes |
|---|---|---|---|---|---|
| `id` | `IntColumn autoIncrement` | INTEGER | NOT NULL | — | — |
| `local_account_id` | `IntColumn` | INTEGER | NOT NULL | — | FK → `local_accounts.id` |
| `type` | `TextColumn` | TEXT | NOT NULL | — | `'expense'` · `'income'` · `'lent_repayment_received'` · `'borrowed_repayment_made'`. Loan origination rows use `'expense'` or `'income'` with `loan_id` set. See §M. |
| `amount_minor` | `IntColumn` | INTEGER | NOT NULL | — | Amount in minor currency units (paise for INR). **Replaces `amount REAL`.** |
| `currency` | `TextColumn` | TEXT | NOT NULL | `'INR'` | ISO 4217 code. |
| `category` | `TextColumn` | TEXT | NOT NULL | — | Spending/income category |
| `note` | `TextColumn` | TEXT | nullable | — | Free-form description |
| `counterparty` | `TextColumn` | TEXT | nullable | — | Person/merchant name; populated for loan-linked rows |
| `occurred_on` | `DateTimeColumn` | INTEGER | NOT NULL | — | **Replaces `date`**. Stores local date of the transaction. |
| `source` | `TextColumn` | TEXT | NOT NULL | `'manual'` | `'manual'` · `'auto_detected'` |
| `loan_id` | `IntColumn` | INTEGER | nullable | — | **NEW** — FK → `loans.id`. Null for normal expenses/income. Set on loan origination rows and all repayment rows to link them to the originating loan. |
| `detection_candidate_id` | `TextColumn` | TEXT | nullable | — | Links back to `transaction_candidates.candidate_id`; text FK (no enforced constraint). |
| `created_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Immutable |
| `updated_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | — |

#### C. Primary key
`id` INTEGER PRIMARY KEY AUTOINCREMENT

#### D. Foreign keys
- `local_account_id` → `local_accounts(id)`
- `loan_id` → `loans(id)` (nullable)
- `detection_candidate_id`: text reference only — no enforced FK

#### E. ON DELETE
- `local_account_id`: **RESTRICT**
- `loan_id`: **SET NULL** — when a loan row is explicitly deleted, all
  money_transactions rows that referenced it have `loan_id` set to NULL. The
  cash-flow history is fully preserved; only the link to the originating loan
  is severed. See §M for full rationale.

#### F. Unique constraints
None beyond PK.

#### G. Indexes

| Index | Columns | Justification |
|---|---|---|
| PK | `(id)` | Implicit |
| idx_money_account_type_date | `(local_account_id, type, occurred_on DESC)` | Covers `watchByType` (type-filtered lists) and category-filtered screens. |
| idx_money_account_date | `(local_account_id, occurred_on DESC)` | Covers `watchAllTransactions()` and `watchThisWeeksTransactions()` (no type filter). Separate from the type index so these queries use the index efficiently. |
| idx_money_loan_id | `(loan_id)` | Covers `watchRepaymentsForLoan(loanId)` — the query that sums repayments to derive outstanding balance. Without this, every balance calculation is a full table scan. |

---

### Table 6 — `loans`

**Purpose:** Tracks the full lifecycle of a lent or borrowed money event:
the original principal, the counterparty, the due date, and the running
status. Repayment cash-flow is recorded in `money_transactions` with
`loan_id` pointing back here, so the outstanding balance is always derivable
from live data rather than stored as a duplicate.

This table is the authoritative record for loan origination. A loan row does
not itself move money — it declares that money was lent or borrowed on a given
date. The corresponding disbursement or receipt is a `money_transactions` row
with `type = 'expense'` (for lent — money left your pocket) or
`type = 'income'` (for borrowed — money entered your pocket), also linked by
`loan_id`.

#### B. Columns

| Column | Drift type | SQLite type | Null | Default | Notes |
|---|---|---|---|---|---|
| `id` | `IntColumn autoIncrement` | INTEGER | NOT NULL | — | Local surrogate PK |
| `local_account_id` | `IntColumn` | INTEGER | NOT NULL | — | FK → `local_accounts.id` |
| `direction` | `TextColumn` | TEXT | NOT NULL | — | `'lent'` — you gave money to someone · `'borrowed'` — you received money from someone |
| `amount_minor` | `IntColumn` | INTEGER | NOT NULL | — | Original principal in minor currency units. Never modified after creation. |
| `currency` | `TextColumn` | TEXT | NOT NULL | `'INR'` | ISO 4217 code |
| `counterparty` | `TextColumn` | TEXT | NOT NULL | — | Name of the person/entity. Required — a loan without a counterparty has no meaning. |
| `loan_date` | `DateTimeColumn` | INTEGER | NOT NULL | — | Date the money was lent or borrowed |
| `due_date` | `DateTimeColumn` | INTEGER | nullable | — | Optional expected repayment date; null means no deadline set |
| `status` | `TextColumn` | TEXT | NOT NULL | — | `'active'` — outstanding balance > 0 · `'settled'` — fully repaid · `'written_off'` — forgiven/cancelled |
| `note` | `TextColumn` | TEXT | nullable | — | Free-form description |
| `created_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Immutable creation timestamp |
| `updated_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Updated when status changes or note is edited |

#### C. Primary key
`id` INTEGER PRIMARY KEY AUTOINCREMENT

#### D. Foreign keys
- `local_account_id` → `local_accounts(id)`

#### E. ON DELETE
- `local_account_id`: **RESTRICT** — prevents deleting an account that still
  owns loans.
- Loan → money_transactions relationship: `money_transactions.loan_id` carries
  **ON DELETE SET NULL**. When a loan row is explicitly deleted, all repayment
  and origination transaction rows that referenced it have their `loan_id` set
  to NULL. The cash-flow history is preserved in `money_transactions`; only
  the link back to the originating loan is severed. The user's financial
  history must never be deleted as a side effect of removing a loan record.

#### F. Unique constraints
None beyond PK. The same counterparty may have multiple concurrent loans.

#### G. Indexes

| Index | Columns | Justification |
|---|---|---|
| PK | `(id)` | Implicit |
| idx_loans_account_status | `(local_account_id, status)` | Covers `watchLoans(accountId, status: 'active')` and the dashboard total-outstanding calculation. The loans screen shows active loans by default — this is the most frequent access pattern. |
| idx_loans_account_date | `(local_account_id, loan_date DESC)` | Covers `watchAllLoans(accountId)` ordered by date, and the history view that shows all loans regardless of status. Separate from the status index because the history view does not filter by status. |

---

### Table 7 — `youtube_playlists`

**Purpose:** Cache of playlist-level metadata fetched from the YouTube API.
User-owned: one playlist belongs to exactly one account.

#### B. Columns

| Column | Drift type | SQLite type | Null | Default | Notes |
|---|---|---|---|---|---|
| `id` | `IntColumn autoIncrement` | INTEGER | NOT NULL | — | Local surrogate PK |
| `local_account_id` | `IntColumn` | INTEGER | NOT NULL | — | FK → `local_accounts.id`. Replaces the `user_id TEXT` field. |
| `youtube_playlist_id` | `TextColumn` | TEXT | NOT NULL | — | YouTube API playlist ID |
| `title` | `TextColumn` | TEXT | NOT NULL | — | Cached metadata |
| `description` | `TextColumn` | TEXT | NOT NULL | `''` | Cached metadata |
| `channel_title` | `TextColumn` | TEXT | NOT NULL | `''` | Cached metadata |
| `thumbnail_url` | `TextColumn` | TEXT | NOT NULL | `''` | Cached URL; stored so offline display works without a network round-trip |
| `total_videos` | `IntColumn` | INTEGER | NOT NULL | 0 | Cached count from API; used for display only |
| `total_duration_seconds` | `IntColumn` | INTEGER | NOT NULL | 0 | Cached aggregate |
| `sync_status` | `TextColumn` | TEXT | NOT NULL | `'ok'` | `'ok'` · `'syncing'` · `'error'` |
| `sync_error` | `TextColumn` | TEXT | nullable | — | Last sync error message |
| `created_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Set once at first insert; **never overwritten on refresh** |
| `updated_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Updated on every metadata write |
| `last_synced_at` | `DateTimeColumn` | INTEGER | nullable | — | Last successful API sync |

**Removed from v8:** `user_id TEXT` — replaced by `local_account_id INTEGER`.

#### C. Primary key
`id` INTEGER PRIMARY KEY AUTOINCREMENT

#### D. Foreign keys
`local_account_id` → `local_accounts(id)`

#### E. ON DELETE
`local_account_id`: **RESTRICT**

#### F. Unique constraints
- UNIQUE `(local_account_id, youtube_playlist_id)` — replaces the old
  `(user_id, youtube_playlist_id)` constraint.

#### G. Indexes

| Index | Columns | Justification |
|---|---|---|
| PK | `(id)` | Implicit |
| UNIQUE `(local_account_id, youtube_playlist_id)` | Implicit B-tree | Covers `watchForUser`, `getByYoutubeId`, and the upsert lookup in `savePlaylist`. |

---

### Table 8 — `youtube_videos`

**Purpose:** Per-video metadata (refreshable) and per-video progress (permanent
user data). These two concerns live in one table because they are always queried
together and progress must survive metadata refreshes.

#### B. Columns

| Column | Drift type | SQLite type | Null | Default | Notes |
|---|---|---|---|---|---|
| `id` | `IntColumn autoIncrement` | INTEGER | NOT NULL | — | Local surrogate PK |
| `playlist_local_id` | `IntColumn` | INTEGER | NOT NULL | — | FK → `youtube_playlists.id` |
| `youtube_video_id` | `TextColumn` | TEXT | NOT NULL | — | YouTube API video ID |
| `title` | `TextColumn` | TEXT | NOT NULL | — | Refreshable metadata |
| `thumbnail_url` | `TextColumn` | TEXT | NOT NULL | `''` | Refreshable; stored for offline display |
| `position` | `IntColumn` | INTEGER | NOT NULL | — | Playlist position; refreshable |
| `duration_seconds` | `IntColumn` | INTEGER | NOT NULL | 0 | Refreshable |
| `duration_iso` | `TextColumn` | TEXT | NOT NULL | `''` | Refreshable; kept for display formatting compatibility |
| `completed` | `BoolColumn` | INTEGER | NOT NULL | 0 | **Permanent user data** — never overwritten by a metadata refresh |
| `watched_at` | `DateTimeColumn` | INTEGER | nullable | — | **Permanent user data** |
| `last_position_seconds` | `IntColumn` | INTEGER | NOT NULL | 0 | **Permanent user data** |
| `progress_updated_at` | `DateTimeColumn` | INTEGER | nullable | — | Timestamp of last progress write; used to resolve sync conflicts later |
| `created_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Set once at first insert; never overwritten |
| `updated_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Updated on every metadata write |

#### C. Primary key
`id` INTEGER PRIMARY KEY AUTOINCREMENT

#### D. Foreign keys
`playlist_local_id` → `youtube_playlists(id)`

#### E. ON DELETE
`playlist_local_id`: **CASCADE** — when a playlist is explicitly deleted by
the user, all its videos (including progress) are deleted. The
progress-preservation requirement applies only to metadata *refreshes*, not
to explicit user deletions.

#### F. Unique constraints
- UNIQUE `(playlist_local_id, youtube_video_id)` — enables upsert-on-refresh
  without duplicates.

#### G. Indexes

| Index | Columns | Justification |
|---|---|---|
| PK | `(id)` | Implicit |
| UNIQUE `(playlist_local_id, youtube_video_id)` | Implicit B-tree | Covers the upsert conflict target and `getByYoutubeId` lookup. |
| idx_videos_playlist_position | `(playlist_local_id, position ASC)` | Covers `watchVideos(playlistId)` and `getVideos(playlistId)` which both ORDER BY `position`. |
| idx_videos_playlist_completed | `(playlist_local_id, completed)` | Covers the Watched/Unwatched filter sort. |

---

### Table 9 — `transaction_detection_events`

**Purpose:** Deduplicated raw notification events from the Android
notification listener. Temporary/cache data with a bounded retention policy.

#### B. Columns

| Column | Drift type | SQLite type | Null | Default | Notes |
|---|---|---|---|---|---|
| `id` | `IntColumn autoIncrement` | INTEGER | NOT NULL | — | — |
| `local_account_id` | `IntColumn` | INTEGER | NOT NULL | — | FK → `local_accounts.id` |
| `event_key` | `TextColumn` | TEXT | NOT NULL | — | Deduplication key (UNIQUE) |
| `source_package` | `TextColumn` | TEXT | NOT NULL | — | Android app package |
| `source_type` | `TextColumn` | TEXT | NOT NULL | — | e.g. `'NOTIFICATION'` |
| `title` | `TextColumn` | TEXT | nullable | — | Raw notification title (may contain PII) |
| `body` | `TextColumn` | TEXT | nullable | — | Raw body |
| `big_text` | `TextColumn` | TEXT | nullable | — | Raw expanded text |
| `occurred_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Event timestamp |
| `received_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | When DIMI received it |
| `processed_at` | `DateTimeColumn` | INTEGER | nullable | — | Set when a candidate was derived from this event. Null = not yet processed. |
| `expires_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | `received_at + 30 days`. Rows deleted by retention job when `expires_at < now()`. |

#### C. Primary key
`id` INTEGER PRIMARY KEY AUTOINCREMENT

#### D. Foreign keys
`local_account_id` → `local_accounts(id)`

#### E. ON DELETE
`local_account_id`: **RESTRICT**

#### F. Unique constraints
- UNIQUE `(event_key)` — unchanged from v8.

#### G. Indexes

| Index | Columns | Justification |
|---|---|---|
| PK | `(id)` | Implicit |
| UNIQUE `(event_key)` | Implicit B-tree | Covers `insertOrIgnore` deduplication. |
| idx_tde_account_expires | `(local_account_id, expires_at)` | Covers the retention purge `DELETE WHERE local_account_id = ? AND expires_at < ?`. |

---

### Table 10 — `transaction_candidates`

**Purpose:** Parsed financial transaction candidates awaiting user confirmation,
auto-add, or rejection.

#### B. Columns

| Column | Drift type | SQLite type | Null | Default | Notes |
|---|---|---|---|---|---|
| `id` | `IntColumn autoIncrement` | INTEGER | NOT NULL | — | — |
| `local_account_id` | `IntColumn` | INTEGER | NOT NULL | — | FK → `local_accounts.id` |
| `candidate_id` | `TextColumn` | TEXT | NOT NULL | — | UNIQUE deduplication key |
| `amount_minor` | `IntColumn` | INTEGER | NOT NULL | — | Integer minor units |
| `currency` | `TextColumn` | TEXT | NOT NULL | `'INR'` | — |
| `merchant_name` | `TextColumn` | TEXT | NOT NULL | `'Unknown'` | — |
| `merchant_identity` | `TextColumn` | TEXT | NOT NULL | `'unknown'` | Normalized for matching |
| `direction` | `TextColumn` | TEXT | NOT NULL | — | `'DEBIT'` · `'CREDIT'` · `'UNKNOWN'` |
| `transaction_type` | `TextColumn` | TEXT | NOT NULL | — | `'EXPENSE'` · `'INCOME'` · `'REFUND'` · `'UNKNOWN'` |
| `source` | `TextColumn` | TEXT | NOT NULL | — | Notification source package tag |
| `bank_confirmation_status` | `TextColumn` | TEXT | NOT NULL | `'NOT_RECEIVED'` | — |
| `source_package` | `TextColumn` | TEXT | nullable | — | — |
| `occurred_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | — |
| `reference_id` | `TextColumn` | TEXT | nullable | — | UPI / bank reference |
| `account_hint` | `TextColumn` | TEXT | nullable | — | Masked account suffix |
| `payment_method` | `TextColumn` | TEXT | nullable | — | `'UPI'` · `'CARD'` · etc. |
| `balance_after_minor` | `IntColumn` | INTEGER | nullable | — | — |
| `raw_event_id` | `TextColumn` | TEXT | nullable | — | References `transaction_detection_events.event_key` — text only, event may expire before candidate is resolved |
| `confidence_score` | `RealColumn` | REAL | NOT NULL | — | Parse confidence 0–1; REAL is acceptable (not money) |
| `status` | `TextColumn` | TEXT | NOT NULL | — | `'PENDING_CONFIRMATION'` · `'AUTO_ADDED'` · `'CONFIRMED'` · `'IGNORED'` · `'DUPLICATE'` |
| `duplicate_status` | `TextColumn` | TEXT | NOT NULL | `'UNIQUE'` | — |
| `category` | `TextColumn` | TEXT | NOT NULL | `'Other'` | Suggested category |
| `resolved_money_transaction_id` | `IntColumn` | INTEGER | nullable | — | FK → `money_transactions.id`; set when this candidate becomes a confirmed transaction |
| `created_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | — |
| `updated_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | Updated on status transitions |
| `expires_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | `occurred_at + 90 days`; resolved/ignored candidates deleted after this date |

#### C. Primary key
`id` INTEGER PRIMARY KEY AUTOINCREMENT

#### D. Foreign keys
- `local_account_id` → `local_accounts(id)`
- `resolved_money_transaction_id` → `money_transactions(id)` (nullable)

#### E. ON DELETE
- `local_account_id`: **RESTRICT**
- `resolved_money_transaction_id`: **SET NULL** — if the money transaction is
  deleted, the candidate retains its record for audit purposes.

#### F. Unique constraints
- UNIQUE `(candidate_id)`

#### G. Indexes

| Index | Columns | Justification |
|---|---|---|
| PK | `(id)` | Implicit |
| UNIQUE `(candidate_id)` | Implicit B-tree | Covers deduplication insert and `findCandidate`. |
| idx_tc_account_status_occurred | `(local_account_id, status, occurred_at DESC)` | Covers `watchPending()`, `getPendingCandidates()`, and `recentCandidates(since)`. |
| idx_tc_account_expires | `(local_account_id, expires_at)` | Covers the retention purge. |

---

### Table 11 — `merchant_category_rules`

**Purpose:** Learned per-merchant category preferences. Permanent user
preference data.

#### B. Columns

| Column | Drift type | SQLite type | Null | Default | Notes |
|---|---|---|---|---|---|
| `id` | `IntColumn autoIncrement` | INTEGER | NOT NULL | — | — |
| `local_account_id` | `IntColumn` | INTEGER | NOT NULL | — | FK → `local_accounts.id` |
| `merchant_identity` | `TextColumn` | TEXT | NOT NULL | — | Normalized merchant key |
| `category` | `TextColumn` | TEXT | NOT NULL | — | User's preferred category |
| `created_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | — |
| `updated_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | — |

#### C. Primary key
`id` INTEGER PRIMARY KEY AUTOINCREMENT

#### D. Foreign keys
`local_account_id` → `local_accounts(id)`

#### E. ON DELETE
`local_account_id`: **RESTRICT**

#### F. Unique constraints
- UNIQUE `(local_account_id, merchant_identity)` — scoped per account.
  Changed from v8 where only `merchant_identity` was unique globally.

#### G. Indexes

| Index | Columns | Justification |
|---|---|---|
| PK | `(id)` | Implicit |
| UNIQUE `(local_account_id, merchant_identity)` | Implicit B-tree | Covers `preferredCategory` lookup and `saveCategory` upsert. |

---

### Table 12 — `profile_data`

**Purpose:** Editable user profile fields that are not part of the auth
identity (which lives in `local_accounts`). One row per account.

**Replaces:** The old `profile` table (singleton `id = 1`).

#### B. Columns

| Column | Drift type | SQLite type | Null | Default | Notes |
|---|---|---|---|---|---|
| `local_account_id` | `IntColumn` | INTEGER | NOT NULL | — | FK → `local_accounts.id`. Also the PK — one row per account. |
| `role` | `TextColumn` | TEXT | NOT NULL | `''` | User-editable occupation/role |
| `phone` | `TextColumn` | TEXT | NOT NULL | `''` | User-editable |
| `college` | `TextColumn` | TEXT | NOT NULL | `''` | Institution name |
| `semester` | `TextColumn` | TEXT | NOT NULL | `''` | Current semester/year |
| `points` | `IntColumn` | INTEGER | NOT NULL | 0 | Achievement points; no ledger yet |
| `created_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | — |
| `updated_at` | `DateTimeColumn` | INTEGER | NOT NULL | — | — |

**Removed from v8:**
- `id INTEGER` (old `id=1` singleton) — replaced by `local_account_id` as PK
- `name`, `email`, `photo_path` — moved to `local_accounts` as `display_name`,
  `email`, `avatar_url`
- `quote` — unused in UI; not migrated

#### C. Primary key
`local_account_id` (explicit PK, not autoincrement — 1:1 extension of
`local_accounts`)

#### D. Foreign keys
`local_account_id` → `local_accounts(id)`

#### E. ON DELETE
`local_account_id`: **CASCADE** — the only table using CASCADE on account
deletion. `profile_data` has no value without its owning account row.

#### F. Unique constraints
PK enforces uniqueness.

#### G. Indexes
PK index only. Always looked up by `local_account_id` directly.

---

### Tables 13–16 — Retained Pending Activation

`class_sessions`, `study_sessions`, `courses`, `document_meta` are retained
in the database unchanged from v8. They will not receive new columns in the
v9 migration until the feature team confirms the design for each. See §S for
the questions that must be answered before activating them.

---

## H. Ownership / Account Strategy

### Core principle

Every user-owned entity carries a `local_account_id INTEGER NOT NULL` column
that is a FK to `local_accounts.id`. All DAO queries are scoped by this
column as the leading filter. No data is ever visible to a different account.

### Account resolution at runtime

On app startup, the active account is resolved once:

```
SELECT id FROM local_accounts WHERE is_active = 1 LIMIT 1
```

The resulting `local_account_id` integer is stored in a Riverpod
`Provider<int>` (the `activeAccountProvider`). Every `StreamProvider` reads
this provider and passes the account ID as a parameter to its DAO query.

When the user logs in with Google, `local_accounts` is upserted by
`(auth_provider, auth_user_id)`. The matching row's `is_active` is set to 1;
all others are set to 0. The `activeAccountProvider` is invalidated, causing
all downstream stream providers to rebuild against the new account.

When the user logs out:
1. All scheduled notifications for the current account's reminders are
   cancelled.
2. `local_accounts.is_active` is set to 0 for the current account.
3. The app routes to the login screen. No local rows are deleted on logout —
   the data is preserved for when the user logs back in.

### Offline / unauthenticated accounts

An offline user gets a `local_accounts` row with `auth_provider = 'offline'`
and a device-generated `auth_user_id` (a UUID created once and stored in
`SharedPreferences`). This replaces the shared `'local'` string. Each device
gets exactly one offline account row, and it is never shared with any other
device or auth session.

### Multi-account on one device

Because all accounts have rows in `local_accounts`, switching accounts is an
`UPDATE local_accounts SET is_active = ...` operation followed by provider
invalidation. No data migration is needed on switch. Account B cannot see
Account A's data because all queries filter by `local_account_id`.

---

## I. Lifecycle Strategy

### Tasks (To-Dos)

- Incomplete To-Dos: **permanent** until explicit user delete.
- Completed To-Dos: **visible in the active UI until the end of the day they
  were completed**. The following day, the `watchAllTodos` query excludes them
  by filtering `completed_at < startOfToday`. Rows are **not deleted** — they
  remain in the database as historical data.
- **The `purgeExpiredCompletedTodos()` method is removed entirely.** No
  automatic background deletion of completed To-Do rows.
- The UI query `watchAllTodos()` returns all incomplete rows + rows completed
  on or after `startOfToday()`.

### Planner Events

- **Historical planner events are never automatically deleted.**
- Past planner events (`local_date < today`) cannot be deleted by the user
  (enforced in the UI/DAO layer).
- Past planner events cannot have their completion toggled (enforced in the
  UI/DAO layer).
- Future planner events may be deleted by the user. Deletion is transactional
  with reminder deletion (see §L).

### Reminders

- Active (future, enabled) reminders: permanently scheduled until the user
  disables or deletes them.
- Past reminders (`due_at < startOfToday`): hidden from the active UI by the
  `watchAllReminders` query filter, but rows are retained.
- No automatic deletion of past reminder rows.

### Notes

- Permanent until explicit user delete.
- The 15-note cap is a UI rule, not a DB rule.

### Money Transactions

- **Permanent** until explicit user delete. No automatic purge of any kind.

### Loans

- **Active** loans (`status = 'active'`): permanent until the user settles,
  writes off, or explicitly deletes the loan.
- **Settled / written-off** loans: permanent; kept as historical records.
- Deleting a loan sets `money_transactions.loan_id = NULL` on all linked rows
  via `ON DELETE SET NULL` — cash-flow history is preserved even after the
  loan record is removed.
- No automatic deletion of any loan row.

### Detection Events

- Deleted by a scheduled retention job when `expires_at < now()`.
- `expires_at` = `received_at + 30 days`.
- The job runs once per app startup as a single `DELETE WHERE expires_at < ?`.

### Detection Candidates

- Deleted by a scheduled retention job when `expires_at < now()`.
- `expires_at` = `occurred_at + 90 days` for resolved/ignored candidates.
  Pending candidates are retained until resolved.
- The job runs once per app startup.

### Merchant Rules

- Permanent until explicit user-triggered clear. No automatic purge.

### Profile Data

- Permanent. Updated on auth sync; never auto-deleted on logout.

### `clearLegacyDemoContent()`

- **Removed.** Replaced by a one-time migration flag in `SharedPreferences`
  (`dimi_demo_cleared_v1 = true`) that runs exactly once during the v8→v9
  migration step, if and only if `profile.name == 'Student' && profile.email == ''`.

---

## J. YouTube Metadata / Progress Strategy

### Two tiers of data

| Tier | Columns | Lifecycle | Can be overwritten by refresh? |
|---|---|---|---|
| Metadata | `title`, `thumbnail_url`, `position`, `duration_seconds`, `duration_iso` | Refreshable cache | **Yes** |
| Progress | `completed`, `watched_at`, `last_position_seconds`, `progress_updated_at` | Permanent user data | **Never** |

### Safe refresh via UPSERT

The `savePlaylist()` DAO method uses a single Drift upsert on the
`UNIQUE(playlist_local_id, youtube_video_id)` conflict target that only
updates metadata columns, never progress columns:

```sql
INSERT INTO youtube_videos
  (playlist_local_id, youtube_video_id, title, thumbnail_url,
   position, duration_seconds, duration_iso, created_at, updated_at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT (playlist_local_id, youtube_video_id)
DO UPDATE SET
  title             = excluded.title,
  thumbnail_url     = excluded.thumbnail_url,
  position          = excluded.position,
  duration_seconds  = excluded.duration_seconds,
  duration_iso      = excluded.duration_iso,
  updated_at        = excluded.updated_at
  -- completed, watched_at, last_position_seconds, progress_updated_at
  -- are intentionally excluded — never overwritten by a metadata refresh.
```

Videos absent from the new API response are **not deleted**. A separate
`removeVideosMissingFromApi(playlistId, currentApiIds)` method can be called
explicitly if the user wants to purge removed videos.

### `created_at` stability

The upsert explicitly omits `created_at` from the `DO UPDATE SET` clause.
`created_at` is written only at INSERT time and never changed by refreshes.

### Watched/Unwatched sort

`idx_videos_playlist_completed` on `(playlist_local_id, completed)` supports:
- All videos ordered by position
- Filtered to watched (`WHERE completed = 1`)
- Filtered to unwatched (`WHERE completed = 0`)

### Playlist `total_videos` divergence

`total_videos` is a cached display field only. Progress percentage in the UI
is always computed as indexed SQL counts, not Dart-side aggregations.

---

## K. To-Do Lifecycle Strategy

### Active vs. historical visibility

```sql
-- Active UI query:
WHERE local_account_id = :accountId
  AND is_planner_entry = 0
  AND (
    is_completed = 0
    OR completed_at >= :startOfToday   -- completed today: still visible
  )
ORDER BY created_at DESC
```

The following day, `startOfToday` rolls forward and yesterday's completed
tasks naturally disappear from the stream without any row deletion.

### Historical data

Completed To-Do rows remain in the database indefinitely, available for
future analytics, export, backup, and Supabase sync.

### To-Do notes (`tasks.description`)

Retained as-is. A short, nullable description field on the task row.

### `Notes` table

Unchanged in structure, now with `local_account_id` for ownership. The
15-note UI cap is not changed.

---

## L. Planner / Reminder Relationship

### Explicit FK

`reminders.task_id` is a nullable FK to `tasks.id`. A reminder with
`task_id IS NOT NULL` is a "planner reminder" created by the Add Event flow.

### Create path

1. `tasks` row inserted.
2. `reminders` row inserted with `task_id = newTaskId`.
3. Notification scheduled using `reminders.notification_id`.

Both inserts happen inside a single Drift `transaction()` block.

### Edit path

1. `tasks` row updated.
2. `reminders` row (looked up by `task_id`) updated with new `due_at`.
3. Old OS notification cancelled (by `notification_id`).
4. New OS notification scheduled.

All steps inside a single `transaction()`.

### Delete path (future events only)

1. Find `reminders` row by `task_id = deletedTaskId`.
2. Cancel OS notification by `reminders.notification_id`.
3. Delete the `reminders` row.
4. Delete the `tasks` row.

All steps inside a single `transaction()`.

### No orphan planner reminders

A planner event deletion always checks for and removes its reminder in the
same transaction. A standalone reminder (`task_id IS NULL`) is never affected.

### `notification_id` decoupled from `id`

`reminders.notification_id` is a separate column, not the PK. On insert,
`notification_id` = `reminders.id` (the autoincrement value after insert).
The UNIQUE `(notification_id)` constraint ensures no two active reminders
share a notification slot.

---

## M. Finance Monetary Storage Strategy

### Integer minor units

All monetary values are stored as `INTEGER` in the smallest indivisible unit
of the currency:
- INR: paise (1 INR = 100 paise)
- USD: cents (1 USD = 100 cents)
- Any currency: minor unit as defined by ISO 4217

**Rationale:** Floating-point arithmetic on financial values produces
systematic rounding errors. Integer arithmetic is exact. This applies to both
`money_transactions.amount_minor` and `loans.amount_minor`.

### Currency column

`currency TEXT NOT NULL DEFAULT 'INR'` on both `money_transactions` and
`loans`. ISO 4217 three-letter code. Supports future multi-currency use
without a schema change.

### Display conversion

All display formatting divides `amount_minor` by the currency's minor unit
factor (100 for INR/USD) at the presentation layer.

### Migration from REAL

During the v8→v9 migration, existing `amount REAL` values are converted:
```sql
UPDATE money_transactions SET amount_minor = ROUND(amount * 100)
```
The rounding error is at most ±1 paise — acceptable as a one-time migration
cost. After migration, all future writes use exact integer values.

### Expense and income types

Normal financial activity uses `type = 'expense'` or `type = 'income'` in
`money_transactions`. These are independent of loans.

### Loan model — two tables, one source of truth per concern

The `loans` table owns loan origination and lifecycle (direction, principal,
counterparty, due date, status). The `money_transactions` table owns every
cash-flow event. The two are joined by `money_transactions.loan_id`.

**How a lent loan works:**

| Step | Table | Row written | Key fields |
|---|---|---|---|
| User lends to Rahul | `loans` | New loan row | `direction='lent'`, `amount_minor=100000`, `counterparty='Rahul'`, `status='active'` |
| Same action | `money_transactions` | Disbursement row | `type='expense'`, `amount_minor=100000`, `loan_id=<loans.id>` |
| Rahul repays 600 | `money_transactions` | Repayment row | `type='lent_repayment_received'`, `amount_minor=60000`, `loan_id=<loans.id>` |
| Rahul repays 400 | `money_transactions` | Repayment row | `type='lent_repayment_received'`, `amount_minor=40000`, `loan_id=<loans.id>` |
| User marks settled | `loans` | Status update | `status='settled'` |

**How a borrowed loan works:**

| Step | Table | Row written | Key fields |
|---|---|---|---|
| User borrows from Priya | `loans` | New loan row | `direction='borrowed'`, `amount_minor=200000`, `counterparty='Priya'`, `status='active'` |
| Same action | `money_transactions` | Receipt row | `type='income'`, `amount_minor=200000`, `loan_id=<loans.id>` |
| User repays 2000 | `money_transactions` | Repayment row | `type='borrowed_repayment_made'`, `amount_minor=200000`, `loan_id=<loans.id>` |
| User marks settled | `loans` | Status update | `status='settled'` |

### Outstanding balance derivation

The outstanding balance is **always derived from live data** — never stored as
a duplicate field. The `idx_money_loan_id` index makes each SUM query
O(log n + k) where k is the number of repayment rows for that loan (typically
very small):

```sql
-- Lent loan outstanding:
SELECT loans.amount_minor - COALESCE(SUM(mt.amount_minor), 0) AS outstanding
FROM loans
LEFT JOIN money_transactions mt
  ON mt.loan_id = loans.id AND mt.type = 'lent_repayment_received'
WHERE loans.id = :loanId

-- Borrowed loan outstanding: same pattern, type = 'borrowed_repayment_made'
```

### Finance screen totals (SQL aggregation, not Dart fold)

```sql
-- Total lent outstanding across all active loans:
SELECT SUM(l.amount_minor) - COALESCE(SUM(r.amount_minor), 0) AS total_outstanding
FROM loans l
LEFT JOIN money_transactions r
  ON r.loan_id = l.id AND r.type = 'lent_repayment_received'
WHERE l.local_account_id = :accountId
  AND l.direction = 'lent'
  AND l.status = 'active'

-- Total borrowed outstanding: same pattern, direction='borrowed',
-- type='borrowed_repayment_made'
```

### When a loan is deleted

If the user explicitly deletes a `loans` row:

1. `money_transactions.loan_id` is set to `NULL` for all rows that referenced
   it via `ON DELETE SET NULL`.
2. Those transaction rows (disbursement + all repayments) remain fully intact
   in the finance history — the user's cash-flow record is never destroyed.
3. Only the link back to the loan origination record is severed.

This means the Finance screen will continue to show those transactions as
normal expenses/income. The Loans screen will no longer show the loan.

### `money_transactions.type` complete value set

| Value | Meaning | `loan_id` |
|---|---|---|
| `'expense'` | Normal outgoing payment | null (or set for loan disbursement) |
| `'income'` | Normal incoming payment | null (or set for loan receipt) |
| `'lent_repayment_received'` | Cash received repaying a loan you made | **required** |
| `'borrowed_repayment_made'` | Cash paid repaying a loan you received | **required** |

---

## N. Heatmap Query Strategy

### No heatmap table

Heatmap cells remain derived data — calculated from `tasks` rows, not stored.

### Bounded date-range query

The heatmap displays the last 12 months (~365 days). The DAO provides a
targeted query:

```sql
SELECT local_date, is_completed
FROM tasks
WHERE local_account_id = :accountId
  AND is_planner_entry = 1
  AND local_date >= :twelveMonthsAgo
  AND local_date <= :today
ORDER BY local_date ASC
```

This replaces `watchAllPlannerEntries()` which returned all historical rows.
The `idx_tasks_account_planner_date` index covers this query exactly.

### Why this is fast

- Old query: scans all planner rows ever created
- New query: scans only the ~365 rows in the date range via the index

### Heatmap data never purged

Planner events are never auto-deleted, so historical heatmap cells are always
accurate and complete.

### Separate heatmap provider

A new `plannerHeatmapProvider(DateTime from, DateTime to)` replaces
`allPlannerEntriesProvider`. The reactive stream only re-fires when rows in
the specified date range change.

---

## O. Sync-Readiness Considerations

### Integer PKs are local surrogate keys only

Local integer PKs are not exposed to Supabase. When sync is added, each
syncable table will receive a nullable `server_id UUID` column. The local
integer PK is used for all local joins; `server_id` is used only for
cloud-side correlation.

**Why not UUIDs as PKs now?**
SQLite integer PKs use the B-tree rowid directly, giving O(log n) lookups
with minimal overhead. UUID PKs are 36-byte strings requiring additional index
entries. For a local-first app with thousands of tasks, integer PKs give
better read performance. The tradeoff of needing `server_id` for sync is
explicitly acceptable.

### `created_at` / `updated_at` on every permanent table

These are the cursor fields a future Supabase sync pull/push strategy uses
for incremental replication.

### `local_account_id` maps to `auth_user_id` for cloud identity

When a record is pushed to Supabase, `local_account_id` is resolved to
`local_accounts.auth_user_id` (the Supabase UUID). The cloud table uses
`user_id UUID NOT NULL REFERENCES auth.users(id)`.

### No sync outbox yet

A sync outbox table is explicitly out of scope. `created_at`/`updated_at`
fields are sufficient for a last-write-wins or cursor-based pull strategy.

### Soft deletes deferred

Hard deletes are retained for all tables. Tables that require sync will need
`deleted_at` added in a future migration along with RLS policies.

### Detection data is local-only

`transaction_detection_events` and `transaction_candidates` are never synced
to Supabase. Only the resulting `money_transactions` row (if confirmed) is
synced. The `loans` table is syncable — it is permanent user data.

---

## P. Tables to Remove

| Table | Action | Migration step |
|---|---|---|
| `profile` (old) | **DROP** after migrating data | v9: INSERT into `local_accounts` from `profile.name/email/photo_path`, INSERT into `profile_data` from `profile.role/phone/college/semester/points`, DROP TABLE `profile` |

No other tables are removed. The orphaned tables (`class_sessions`,
`study_sessions`, `courses`, `document_meta`) are retained — they are empty
in most installations and removing them is not worth the migration risk until
their feature designs are confirmed.

---

## Q. Tables to Retain As-Is

These tables have no schema changes in the v9 migration:

| Table | Reason |
|---|---|
| `class_sessions` | Feature not yet activated; no DAO/provider/screen. Awaiting §S.1. |
| `study_sessions` | Feature not yet activated; no DAO/provider/screen. Awaiting §S.1. |
| `courses` | Feature not yet activated; no DAO/provider/screen. Awaiting §S.1. |
| `document_meta` | Feature not yet activated; no DAO/provider/screen. Awaiting §S.2. |

---

## R. Tables to Redesign

Summary of all schema changes per table in the v9 migration:

| Table | Changes |
|---|---|
| `tasks` | + `local_account_id` · + `updated_at` · rename `due_date` → `local_date` · rename `due_time` → `due_time_hhmm` · remove `planned_minutes` · remove `completed_minutes` · remove `reminder_minutes_before` · add 3 indexes |
| `reminders` | + `local_account_id` · + `task_id` FK nullable (SET NULL) · + `notification_id` (UNIQUE) · + `created_at` · + `updated_at` · add 2 indexes |
| `notes` | + `local_account_id` · add 1 index |
| `money_transactions` | + `local_account_id` · `amount REAL` → `amount_minor INTEGER` · + `currency` · rename `date` → `occurred_on` · update `type` values (add repayment types) · + nullable `counterparty` · + `source` · + nullable `loan_id` FK (SET NULL) · + `detection_candidate_id` · + `created_at` · + `updated_at` · add 3 indexes |
| `loans` | **NEW table** · `local_account_id` FK (RESTRICT) · `direction`, `amount_minor`, `currency`, `counterparty`, `loan_date`, `due_date`, `status`, `note`, `created_at`, `updated_at` · 2 indexes |
| `youtube_playlists` | `user_id TEXT` → `local_account_id INTEGER` FK · + `sync_status` · + `sync_error` · `created_at` stabilized (not reset on refresh) |
| `youtube_videos` | ON DELETE CASCADE on `playlist_local_id` FK · + `progress_updated_at` · add 2 indexes · refresh strategy changed to upsert |
| `transaction_detection_events` | + `local_account_id` · + `processed_at` · + `expires_at` · add 1 index |
| `transaction_candidates` | + `local_account_id` · + `resolved_money_transaction_id` FK · + `updated_at` · + `expires_at` · add 2 indexes |
| `merchant_category_rules` | + `local_account_id` · UNIQUE changed to `(local_account_id, merchant_identity)` · + `created_at` |
| `profile` (old) | **REPLACED** by `local_accounts` (new) + `profile_data` (new) |

---

## S. Decisions Requiring Confirmation Before Implementation

---

**S.1 — Orphaned tables: activate or drop?**

`class_sessions`, `study_sessions`, `courses`, `document_meta` have been in
the schema since v1 but have no DAO, provider, or screen.

*Options:*
- A) Keep them as-is in v9 (current design assumption — no risk, no benefit)
- B) Drop them in v9 migration (reduces schema noise)
- C) Activate with full `local_account_id`, DAO, and provider (requires
  separate design work)

*Decision required:* Which option? The default is A.

---

**S.2 — Document files: metadata-only or full lifecycle?**

`document_meta` stores file metadata but no file management lifecycle was
found. Before activating:
- What local path does `file_path` point to?
- Who deletes the actual file when the metadata row is deleted?
- Is there a file-size or total-storage cap?

*Decision required before activating DocumentMeta.*

---

**S.3 — To-Do completed-row visibility window**

This design hides completed To-Dos from the active UI from the following day
(`completed_at < startOfToday`). Rows are retained permanently.

*Alternative:* User-configurable window (e.g. 1, 3, 7 days).

*Decision required:* Is the "following day" rule correct, or should it be
configurable?

---

**S.4 — Offline account UUID storage**

Offline accounts use a device-generated UUID as `auth_user_id`, proposed to
be stored in `SharedPreferences` key `dimi_offline_device_id` on first
launch.

*Decision required:* Is `SharedPreferences` the right storage, or should it
use secure storage?

---

**S.5 — Notification ID strategy**

`notification_id` is set to `reminders.id` after insert. Existing v8
reminders are migrated via `UPDATE reminders SET notification_id = id`.

*Decision required:* Confirm this migration approach is acceptable.

---

**S.6 — Detection event retention window**

30 days for `transaction_detection_events`, 90 days for
`transaction_candidates`. These are constants, not user-configurable.

*Decision required:* Are these the correct retention windows?

---

**S.7 — Planner event past-delete enforcement**

"Past planner events cannot be deleted" is enforced at the application/DAO
layer only. The database has no CHECK constraint or trigger for this.

*Decision required:* Is application-layer enforcement sufficient, or is a
database-level guard required?

---

**S.8 — `profile_data.quote` field**

The old `profile.quote` field is not migrated to v9.

*Decision required:* Confirm `quote` is intentionally retired. If any screen
still references it, it must be retained.
