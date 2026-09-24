# DIMI — Local Database Change Plan

**Purpose:** Safety baseline captured before any schema or lifecycle modifications.  
**Captured:** 2026-09-18  
**All commands run against:** `c:\Users\darks\OneDrive\Desktop\dimi_handoff`  
**Nothing was modified to produce this document.**

---

## Table of Contents

1. [Current Schema Version](#1-current-schema-version)
2. [Current Migration Versions](#2-current-migration-versions)
3. [Current Database Files](#3-current-database-files)
4. [Current Test Status](#4-current-test-status)
5. [Current Analyze Status](#5-current-analyze-status)
6. [Current Database-Related Warnings and Errors](#6-current-database-related-warnings-and-errors)
7. [Files That Must Be Modified in the Upcoming Redesign](#7-files-that-must-be-modified-in-the-upcoming-redesign)

---

## 1. Current Schema Version

**`schemaVersion = 8`**

Defined in `lib/data/database.dart`:

```dart
@override
int get schemaVersion => 8;
```

The in-memory test constructor that allows the database to be instantiated
without disk access is also confirmed present in the same file:

```dart
/// Allow injecting a custom executor (e.g. in-memory DB for tests).
AppDatabase.forTesting(super.executor);
```

This constructor is used by `test/widget_test.dart` and is verified working
(see Section 4).

---

## 2. Current Migration Versions

All migrations live inside the single `MigrationStrategy` block in
`lib/data/database.dart`. There are no external migration files.

### `onCreate`

```dart
onCreate: (m) => m.createAll(),
```

Creates all 14 tables in one pass on a fresh install.

### `onUpgrade` — cumulative guards

| Guard | Version reached | Operations |
|---|---|---|
| `if (from < 2)` | v1 → v2 | `addColumn(tasks, tasks.completedAt)` |
| `if (from < 3)` | v2 → v3 | `addColumn(tasks, tasks.isPlannerEntry)` |
| `if (from < 4)` | v3 → v4 | `addColumn(tasks, tasks.plannedMinutes)` · `addColumn(tasks, tasks.completedMinutes)` |
| `if (from < 5)` | v4 → v5 | `createTable(transactionDetectionEvents)` · `createTable(transactionCandidates)` · `createTable(merchantCategoryRules)` |
| `if (from < 6)` | v5 → v6 | `addColumn(transactionCandidates, .accountHint)` · `addColumn(transactionCandidates, .paymentMethod)` · `addColumn(transactionCandidates, .balanceAfterMinor)` |
| `if (from < 7)` | v6 → v7 | `addColumn(transactionCandidates, .bankConfirmationStatus)` |
| `if (from < 8)` | v7 → v8 | `createTable(youtubePlaylists)` · `createTable(youtubeVideos)` |

**Notes on the existing migration design:**
- Guards use `from < N`, not `from == N-1`. A device upgrading from any
  version below N will correctly apply all intermediate steps in a single
  upgrade run.
- `youtube_playlists` and `youtube_videos` were added at v8 and are therefore
  absent from devices that have never been upgraded to v8.
- There are no rollback paths and no migration tests. This is a known gap
  documented in `docs/LOCAL_DATABASE_AUDIT.md`.
- The next migration block to be written must use `if (from < 9)` and the
  `schemaVersion` must be incremented to `9`.

---

## 3. Current Database Files

### Schema-defining source files (design source of truth)

| File | Role |
|---|---|
| `lib/data/database.dart` | `AppDatabase` class, `schemaVersion`, `MigrationStrategy`, table/DAO registration |
| `lib/data/tables/tasks.dart` | `Tasks` table definition |
| `lib/data/tables/class_sessions.dart` | `ClassSessions` table definition |
| `lib/data/tables/study_sessions.dart` | `StudySessions` table definition |
| `lib/data/tables/courses.dart` | `Courses` table definition |
| `lib/data/tables/transactions.dart` | `MoneyTransactions` table definition |
| `lib/data/tables/notes.dart` | `Notes` table definition |
| `lib/data/tables/reminders.dart` | `Reminders` table definition |
| `lib/data/tables/document_meta.dart` | `DocumentMeta` table definition |
| `lib/data/tables/profile.dart` | `ProfileTable` table definition |
| `lib/data/tables/transaction_detection.dart` | `TransactionDetectionEvents`, `TransactionCandidates`, `MerchantCategoryRules` table definitions |
| `lib/data/tables/youtube_playlists.dart` | `YoutubePlaylists` table definition |
| `lib/data/tables/youtube_videos.dart` | `YoutubeVideos` table definition |

### Generated files (DO NOT hand-edit)

| File | Generated from |
|---|---|
| `lib/data/database.g.dart` | `lib/data/database.dart` + all table files |
| `lib/data/daos/task_dao.g.dart` | `lib/data/daos/task_dao.dart` |
| `lib/data/daos/money_dao.g.dart` | `lib/data/daos/money_dao.dart` |
| `lib/data/daos/reminder_dao.g.dart` | `lib/data/daos/reminder_dao.dart` |
| `lib/data/daos/profile_dao.g.dart` | `lib/data/daos/profile_dao.dart` |
| `lib/data/daos/transaction_detection_dao.g.dart` | `lib/data/daos/transaction_detection_dao.dart` |
| `lib/data/daos/youtube_playlist_dao.g.dart` | `lib/data/daos/youtube_playlist_dao.dart` |

Regenerate all `.g.dart` files with:

```
dart run build_runner build --delete-conflicting-outputs
```

### DAO source files

| File | Tables covered |
|---|---|
| `lib/data/daos/task_dao.dart` | `tasks` |
| `lib/data/daos/money_dao.dart` | `money_transactions` |
| `lib/data/daos/note_dao.dart` | `notes` (no `@DriftAccessor` — manual pattern) |
| `lib/data/daos/reminder_dao.dart` | `reminders` |
| `lib/data/daos/profile_dao.dart` | `profile` |
| `lib/data/daos/transaction_detection_dao.dart` | `transaction_detection_events`, `transaction_candidates`, `merchant_category_rules` |
| `lib/data/daos/youtube_playlist_dao.dart` | `youtube_playlists`, `youtube_videos` |

**No DAO exists for:** `class_sessions`, `study_sessions`, `courses`, `document_meta`.

### Database provider

| File | Role |
|---|---|
| `lib/providers/database_provider.dart` | Single `Provider<AppDatabase>` — sole injection point for the entire app |

### All Riverpod data providers

| File | Providers |
|---|---|
| `lib/providers/task_providers.dart` | `taskDaoProvider`, `allTasksProvider`, `allTodosProvider`, `homeTodosProvider`, `allPlannerEntriesProvider`, `todaysTasksProvider`, `upcomingTasksProvider`, `completedTasksProvider`, `tasksForDateProvider`, `tasksForWeekProvider` |
| `lib/providers/money_providers.dart` | `moneyDaoProvider`, `allTransactionsProvider`, `thisWeeksTransactionsProvider`, `transactionsByTypeProvider` |
| `lib/providers/note_providers.dart` | `noteDaoProvider`, `allNotesProvider` |
| `lib/providers/profile_providers.dart` | `profileDaoProvider`, `profileProvider` |
| `lib/providers/reminder_providers.dart` | `reminderDaoProvider`, `allRemindersProvider`, `todaysRemindersProvider`, `upcomingRemindersProvider` |
| `lib/providers/transaction_detection_providers.dart` | `pendingTransactionCandidatesProvider` |
| `lib/features/youtube_playlist/providers.dart` | `youtubePlaylistRepositoryProvider`, `_currentUserIdProvider`, `youtubePlaylistsProvider`, `youtubePlaylistDaoProvider` |

### Existing test files

| File | What it covers |
|---|---|
| `test/widget_test.dart` | App smoke test — `AppDatabase.forTesting(NativeDatabase.memory())`, full widget tree render, `DimiApp` instantiation |
| `test/transaction_detection_test.dart` | `TransactionParser` unit tests — parsing, deduplication, source filtering (no Drift involvement) |

### On-device SQLite file (runtime, not in source control)

```
{getApplicationDocumentsDirectory()}/dimi.sqlite
```

---

## 4. Current Test Status

**All 8 tests pass. Exit code: 0.**

Command run: `flutter test --reporter expanded`

```
00:00 +1: transaction_detection_test.dart: parses debit, income, requests, failures, refunds and amounts
00:00 +2: transaction_detection_test.dart: supports the real rupee sign and treats refunds as credits
00:00 +3: transaction_detection_test.dart: does not guess when a notification contains both directions
00:00 +4: transaction_detection_test.dart: normalizes merchants and identifies sources
00:00 +5: transaction_detection_test.dart: classifies incoming Google Pay and extracts bank fields
00:00 +6: transaction_detection_test.dart: deduplicates close cross-source transactions but keeps distant ones unique
00:00 +7: transaction_detection_test.dart: rejects financial-looking WhatsApp and unknown notifications before parsing
00:00 +1: widget_test.dart: App smoke test
00:01 +8: All tests passed!
```

### `AppDatabase.forTesting(executor)` verified working

`test/widget_test.dart` exercises this constructor:

```dart
final db = AppDatabase.forTesting(NativeDatabase.memory());
```

The widget tree renders, the in-memory database opens, and the test disposes
cleanly (`await db.close()`). This constructor is the hook that all future
migration and DAO tests must use.

### Build verified

Command run: `flutter build apk --debug`

Result: **`✓ Built build\app\outputs\flutter-apk\app-debug.apk`**

The Gradle output contained three JVM native-access warnings
(`java.lang.System::load`) from the Gradle wrapper itself. These are
infrastructure-level warnings and have no effect on the Flutter application
binary. Exit code from Gradle was surfaced as 1 by PowerShell redirection
despite a successful APK, which is a known behavior of `2>&1` on some Windows
shells; the APK file is confirmed present.

---

## 5. Current Analyze Status

**41 issues found (0 errors, 16 warnings, 25 infos). Exit code: 1.**

Command run: `flutter analyze`

### Warnings (16)

| File | Line | Rule | Message |
|---|---|---|---|
| `lib/screens/home/home_screen.dart` | 890:51 | `unnecessary_non_null_assertion` | `!` has no effect — receiver can't be null |
| `lib/screens/home/home_screen.dart` | 1555:11 | `unused_local_variable` | Variable `loans` declared but never used |
| `lib/screens/home/home_screen.dart` | 1872:7 | `unused_element` | `_BalanceCard` is never referenced |
| `lib/screens/home/home_screen.dart` | 1873:56 | `unused_element_parameter` | Parameter `compact` on `_BalanceCard` never supplied |
| `lib/screens/home/home_screen.dart` | 2031:7 | `unused_element` | `_SpendingCard` is never referenced |
| `lib/screens/home/home_screen.dart` | 2032:57 | `unused_element_parameter` | Parameter `compact` on `_SpendingCard` never supplied |
| `lib/screens/home/home_screen.dart` | 2412:7 | `unused_element` | `_HomeHeaderButton` is never referenced |
| `lib/screens/money/money_screen.dart` | 542:7 | `unused_element` | `_CategorySpendGrid` is never referenced |
| `lib/screens/planner/planner_screen.dart` | 1432:8 | `unused_element` | `_minutesLabel` is never referenced |
| `lib/screens/profile/profile_screen.dart` | 406:38 | `unnecessary_non_null_assertion` | `!` has no effect — receiver can't be null |
| `lib/screens/profile/profile_screen.dart` | 427:7 | `unused_element` | `_PersonalInfoCard` is never referenced |
| `lib/screens/profile/profile_screen.dart` | 705:7 | `unused_element` | `_GoPremiumCard` is never referenced |
| `lib/screens/profile/profile_screen.dart` | 726:7 | `unused_element` | `_SyncStatusCard` is never referenced |
| `lib/screens/profile/profile_screen.dart` | 767:7 | `unused_element` | `_ProfileActionCard` is never referenced |
| `lib/screens/profile/profile_screen.dart` | 930:7 | `unused_element` | `_CompactLogoutButton` is never referenced |
| `lib/screens/profile/profile_screen.dart` | 1307:10 | `unused_element_parameter` | Parameter `maxLines` never supplied |
| `lib/screens/settings/settings_screen.dart` | 364:10 | `unused_element_parameter` | Parameter `trailing` never supplied |
| `lib/widgets/youtube_playlist_card.dart` | 961:7 | `unused_element` | `_ThumbnailImage` is never referenced |

### Infos (25)

| File | Line | Rule | Message |
|---|---|---|---|
| `lib/features/youtube_playlist/screens/add_youtube_playlist_sheet.dart` | 46:9 | `curly_braces_in_flow_control_structures` | `if` body missing braces |
| `lib/features/youtube_playlist/screens/add_youtube_playlist_sheet.dart` | 59:9 | `curly_braces_in_flow_control_structures` | `if` body missing braces |
| `lib/features/youtube_playlist/screens/add_youtube_playlist_sheet.dart` | 75:9 | `curly_braces_in_flow_control_structures` | `if` body missing braces |
| `lib/features/youtube_playlist/screens/playlist_details_screen.dart` | 32:18 | `unnecessary_underscores` | Replace `__` with `_` |
| `lib/features/youtube_playlist/screens/playlist_details_screen.dart` | 58:24 | `unnecessary_underscores` | Replace `__` with `_` |
| `lib/features/youtube_playlist/screens/playlist_details_screen.dart` | 131:8 | `deprecated_member_use` | `activeColor` deprecated — use `activeThumbColor`/`activeTrackColor` |
| `lib/screens/home/home_screen.dart` | 1155:22 | `unnecessary_underscores` | Replace `__` with `_` |
| `lib/screens/home/home_screen.dart` | 1155:26 | `unnecessary_underscores` | Replace `__` with `_` |
| `lib/screens/profile/profile_screen.dart` | 1200:23 | `deprecated_member_use` | `value` deprecated — use `initialValue` |
| `lib/screens/profile/profile_screen.dart` | 1236:27 | `curly_braces_in_flow_control_structures` | `if` body missing braces |
| `lib/screens/todos/todos_screen.dart` | 378:19 | `curly_braces_in_flow_control_structures` | `if` body missing braces |
| `lib/screens/todos/todos_screen.dart` | 385:23 | `use_build_context_synchronously` | `BuildContext` used across async gap |
| `lib/screens/todos/todos_screen.dart` | 412:25 | `use_build_context_synchronously` | `BuildContext` used across async gap |
| `lib/screens/todos/todos_screen.dart` | 720:29 | `curly_braces_in_flow_control_structures` | `if` body missing braces |
| `lib/screens/todos/todos_screen.dart` | 830:7 | `curly_braces_in_flow_control_structures` | `if` body missing braces |
| `lib/widgets/dimi_hero.dart` | 65:25 | `use_null_aware_elements` | Use `?` rather than null check via `if` |
| `lib/widgets/dimi_hero.dart` | 77:25 | `use_null_aware_elements` | Use `?` rather than null check via `if` |
| `lib/widgets/dimi_hero.dart` | 195:9 | `use_key_in_widget_constructors` | Public widget constructor missing `key` parameter |
| `lib/widgets_modals/add_expense_sheet.dart` | 21:39 | `unnecessary_underscores` | Replace `__` with `_` |
| `lib/widgets_modals/add_reminder_sheet.dart` | 23:39 | `unnecessary_underscores` | Replace `__` with `_` |
| `lib/widgets_modals/add_task_sheet.dart` | 39:39 | `unnecessary_underscores` | Replace `__` with `_` |
| `lib/widgets_modals/add_task_sheet.dart` | 193:16 | `use_build_context_synchronously` | `BuildContext` used across async gap |
| `lib/widgets_modals/add_task_sheet.dart` | 231:16 | `use_build_context_synchronously` | `BuildContext` used across async gap |

> **None of these issues are in database, DAO, table, or provider files.**  
> All 41 issues are in UI/widget/modal/screen files.  
> The analyzer exits with code 1 because warnings are present; this does not
> indicate a compile failure.

---

## 6. Current Database-Related Warnings and Errors

**`flutter analyze` produced zero issues in any database, DAO, table, or provider file.**

The following files were clean (no issues of any kind):

- `lib/data/database.dart`
- `lib/data/database.g.dart`
- `lib/data/tables/*.dart` (all 12 files)
- `lib/data/daos/*.dart` (all 7 source + 6 generated files)
- `lib/providers/database_provider.dart`
- `lib/providers/task_providers.dart`
- `lib/providers/money_providers.dart`
- `lib/providers/note_providers.dart`
- `lib/providers/profile_providers.dart`
- `lib/providers/reminder_providers.dart`
- `lib/providers/transaction_detection_providers.dart`
- `lib/features/youtube_playlist/providers.dart`

### Known structural issues (from audit — NOT reported by `flutter analyze`)

These are logic/design issues that the static analyser cannot detect. They are
recorded here as the baseline state so they are not mistaken for regressions
introduced by the upcoming redesign.

| # | File | Issue |
|---|---|---|
| DB-1 | `lib/data/daos/note_dao.dart` | `NoteDao` has no `@DriftAccessor` annotation and no generated mixin. It accesses `attachedDatabase.notes` directly rather than through Drift's typed accessor pattern. |
| DB-2 | `lib/data/daos/task_dao.dart` (line ~84) | `watchTodaysTasks()` uses `DateTime.now()` as the lower bound instead of `DateTime(y,m,d)` (start of today), causing tasks due earlier in the day to be excluded. |
| DB-3 | `lib/data/daos/task_dao.dart` | `purgeExpiredCompletedTodos()` hard-deletes completed non-planner tasks older than 7 days. This runs at startup (`lib/main.dart`) and again in `TodosScreen.initState()`. |
| DB-4 | `lib/data/database.dart` | `clearLegacyDemoContent()` performs destructive multi-table deletion on every startup if `profile.name == 'Student' && profile.email.isEmpty`. |
| DB-5 | `lib/data/daos/youtube_playlist_dao.dart` | `savePlaylist()` deletes all `youtube_videos` rows before reinserting — video progress is lost if the new API response omits a previously known video. |
| DB-6 | `lib/data/tables/transactions.dart` | `amount` is `REAL` (IEEE 754 double-precision float) — binary rounding errors are possible for monetary values. |
| DB-7 | All table files except `youtube_playlists` | No `owner_id` / `account_id` column — all data is globally visible regardless of which user is signed in. |
| DB-8 | `lib/data/daos/money_dao.dart` | `deleteSuspiciousDetectedTransactions()` fetches all suspicious rows then deletes them one-at-a-time in a loop instead of using a single `DELETE … WHERE`. |
| DB-9 | No table file | No indexes declared on any non-primary, non-unique column. All DAO queries that filter or sort by `due_date`, `is_planner_entry`, `type`, `date`, `is_enabled`, `due_at`, `status`, or `occurred_at` perform full table scans. |
| DB-10 | `lib/data/daos/youtube_playlist_dao.dart` | The mapper always supplies `createdAt: DateTime.now()`, resetting the playlist creation timestamp on every metadata refresh. |

---

## 7. Files That Must Be Modified in the Upcoming Redesign

The table below captures every file that will need to change. The "change
category" column uses these codes:

| Code | Meaning |
|---|---|
| **SCHEMA** | Table definition changes (add/remove/rename columns, add indexes) |
| **MIGRATION** | New `onUpgrade` block + `schemaVersion` increment |
| **DAO** | Query or write-method changes |
| **PROVIDER** | Provider scoping or query changes |
| **APP-LOGIC** | Non-DB code that must adapt to schema/DAO changes |
| **TEST** | New or updated test files |
| **CODEGEN** | Regenerated automatically — do not hand-edit |

### Schema / table files

| File | Change category | Why it must change |
|---|---|---|
| `lib/data/tables/tasks.dart` | SCHEMA | Add `owner_id`; add index annotations; remove dead columns (`planned_minutes`, `completed_minutes`) pending UI confirmation; add `updated_at`; formalize `due_time` as a validated type |
| `lib/data/tables/transactions.dart` | SCHEMA | Change `amount REAL` → `amount_minor INTEGER`; add `currency TEXT NOT NULL DEFAULT 'INR'`; add `owner_id`; add `created_at`; add `updated_at` |
| `lib/data/tables/reminders.dart` | SCHEMA | Add `owner_id`; add nullable `task_id` FK; add `created_at`; add `updated_at`; add `timezone_id` (nullable) |
| `lib/data/tables/notes.dart` | SCHEMA | Add `owner_id` |
| `lib/data/tables/profile.dart` | SCHEMA | Add `updated_at`; rename `photo_path` → `avatar_url`; remove `quote` (post-confirm); add `auth_user_id` for account linkage |
| `lib/data/tables/transaction_detection.dart` | SCHEMA | Add `processed_at` and `expires_at` to `TransactionDetectionEvents`; add `updated_at` and `resolved_money_transaction_id` to `TransactionCandidates`; add `owner_id` to both; add `created_at` to `MerchantCategoryRules` and `owner_id` |
| `lib/data/tables/youtube_playlists.dart` | SCHEMA | Fix `createdAt` mapping; no structural owner change needed (has `user_id`) |
| `lib/data/tables/youtube_videos.dart` | SCHEMA | Add `ON DELETE CASCADE` to `playlistLocalId` FK declaration |
| `lib/data/tables/class_sessions.dart` | SCHEMA | Add `owner_id`; add `created_at` / `updated_at` (if feature is activated) |
| `lib/data/tables/study_sessions.dart` | SCHEMA | Add `owner_id`; add `updated_at` (if feature is activated) |
| `lib/data/tables/courses.dart` | SCHEMA | Add `owner_id`; add `created_at` / `updated_at` (if feature is activated) |
| `lib/data/tables/document_meta.dart` | SCHEMA | Add `owner_id`; add `updated_at` (if feature is activated) |

### New table files (to be created)

| File | Change category | Why it must be created |
|---|---|---|
| `lib/data/tables/accounts.dart` | SCHEMA | Central account/identity row to replace the global `profile` singleton |
| `lib/data/tables/loans.dart` | SCHEMA | Separate loan entity with counterparty, direction, repayment status |

### Database class

| File | Change category | Why it must change |
|---|---|---|
| `lib/data/database.dart` | MIGRATION + SCHEMA | Increment `schemaVersion` to 9; add `if (from < 9)` migration block for all new columns, new tables, and dropped columns; register new table classes and DAOs; replace `clearLegacyDemoContent()` with a one-time versioned flag |

### Generated files (regenerated by build_runner — no manual edits)

| File | Change category |
|---|---|
| `lib/data/database.g.dart` | CODEGEN |
| `lib/data/daos/task_dao.g.dart` | CODEGEN |
| `lib/data/daos/money_dao.g.dart` | CODEGEN |
| `lib/data/daos/reminder_dao.g.dart` | CODEGEN |
| `lib/data/daos/profile_dao.g.dart` | CODEGEN |
| `lib/data/daos/transaction_detection_dao.g.dart` | CODEGEN |
| `lib/data/daos/youtube_playlist_dao.g.dart` | CODEGEN |
| `lib/data/daos/loan_dao.g.dart` _(new)_ | CODEGEN |

### DAO files

| File | Change category | Why it must change |
|---|---|---|
| `lib/data/daos/task_dao.dart` | DAO | Scope all queries by `owner_id`; fix `watchTodaysTasks()` lower bound to midnight; add date-range filter to `watchAllPlannerEntries()`; remove `purgeExpiredCompletedTodos()` or replace with explicit archive flow |
| `lib/data/daos/money_dao.dart` | DAO | Scope by `owner_id`; update all amount field references from `amount` to `amount_minor`; add SQL `SUM`/`GROUP BY` aggregate queries; fix `deleteSuspiciousDetectedTransactions()` to single `DELETE … WHERE` |
| `lib/data/daos/note_dao.dart` | DAO | Add `@DriftAccessor` annotation and `part` directive; scope by `owner_id`; regenerate mixin |
| `lib/data/daos/reminder_dao.dart` | DAO | Scope by `owner_id`; add `deleteByTaskId(int taskId)` method for cleanup when a paired task is deleted |
| `lib/data/daos/profile_dao.dart` | DAO | Update field references if `photo_path` → `avatar_url` rename proceeds; add `auth_user_id` query |
| `lib/data/daos/transaction_detection_dao.dart` | DAO | Scope by `owner_id`; add `deleteExpiredEvents()` and `deleteResolvedCandidates()` for retention policy |
| `lib/data/daos/youtube_playlist_dao.dart` | DAO | Fix `savePlaylist()` to upsert videos instead of delete+reinsert; fix `createdAt` not being reset on update for existing playlists |
| `lib/data/daos/loan_dao.dart` _(new)_ | DAO | CRUD for new `loans` table |

### Provider files

| File | Change category | Why it must change |
|---|---|---|
| `lib/providers/database_provider.dart` | PROVIDER | Add account-context initialization; expose active `owner_id` |
| `lib/providers/task_providers.dart` | PROVIDER | Scope all `StreamProvider`s to active `owner_id` |
| `lib/providers/money_providers.dart` | PROVIDER | Scope all `StreamProvider`s to active `owner_id`; update amount field references |
| `lib/providers/note_providers.dart` | PROVIDER | Scope to active `owner_id` |
| `lib/providers/reminder_providers.dart` | PROVIDER | Scope to active `owner_id` |
| `lib/providers/transaction_detection_providers.dart` | PROVIDER | Scope to active `owner_id` |
| `lib/features/youtube_playlist/providers.dart` | PROVIDER | Minor: ensure `'local'` bucket is not shared between distinct unauthenticated users |

### Application logic files

| File | Change category | Why it must change |
|---|---|---|
| `lib/main.dart` | APP-LOGIC | Remove startup `purgeExpiredCompletedTodos()` call; replace `clearLegacyDemoContent()` with one-time versioned flag; add account context initialization |
| `lib/screens/todos/todos_screen.dart` | APP-LOGIC | Remove `purgeExpiredCompletedTodos()` from `initState()` |
| `lib/widgets_modals/add_task_sheet.dart` | APP-LOGIC | Transactionally create/update/cancel the paired `reminders` row and notification when a planner event is saved or edited |
| `lib/widgets/dimi_activity_heatmap.dart` | APP-LOGIC | Accept a date-bounded task list (not all-time) to prevent unbounded memory growth |
| `lib/screens/money/money_screen.dart` | APP-LOGIC | Replace Dart-side `fold` aggregations with DAO-level `SUM`/`GROUP BY` queries; update amount display from `REAL` to minor-unit conversion |
| `lib/services/auth_service.dart` | APP-LOGIC | Add logout cleanup: clear local user-scoped rows, cancel scheduled notifications, reset account context |
| `lib/services/notification_service.dart` | APP-LOGIC | Decouple notification ID from `reminders.id` PK; use a dedicated stable notification ID column |

### Test files (new — to be created)

| File | Change category | What it must cover |
|---|---|---|
| `test/data/migration_test.dart` | TEST | Schema upgrade from every version (v1→v9, v2→v9, …, v8→v9) using `AppDatabase.forTesting(NativeDatabase.memory())` |
| `test/data/dao/task_dao_test.dart` | TEST | Date boundaries, `is_planner_entry` filter, `purge` behavior change, `watchTodaysTasks` midnight fix |
| `test/data/dao/money_dao_test.dart` | TEST | Minor-unit storage/retrieval, type filtering, aggregate query correctness |
| `test/data/dao/reminder_dao_test.dart` | TEST | Enable/disable, task_id cascade, `getAllEnabled` boundary |
| `test/data/dao/youtube_playlist_dao_test.dart` | TEST | Progress preservation during metadata refresh, `createdAt` stability |
| `test/data/account_isolation_test.dart` | TEST | Confirm rows for `owner_id = 'user_a'` are not visible to queries for `owner_id = 'user_b'` |

---

## Baseline Summary

| Item | Status |
|---|---|
| `schemaVersion` | **8** |
| Latest migration block | **`if (from < 8)`** — creates `youtube_playlists` and `youtube_videos` |
| Next migration block must be | **`if (from < 9)`** with `schemaVersion` incremented to **9** |
| Tests | **8 / 8 passing** |
| Build | **Successful** (`app-debug.apk` produced) |
| `flutter analyze` issues | **41 total** — 0 errors, 16 warnings, 25 infos; **0 issues in any DB/DAO/provider/table file** |
| `AppDatabase.forTesting(executor)` | **Confirmed working** (used by `widget_test.dart`) |
| On-device DB file | `{documentsDir}/dimi.sqlite` |
| Drift code generation command | `dart run build_runner build --delete-conflicting-outputs` |
