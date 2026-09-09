# Design: DIMI App

## Architecture overview
Flutter app, local-first, single-process, no backend calls. Data flows one
direction: `drift database → DAO stream → Riverpod StreamProvider → widget`.
Writes go the other direction through DAO methods called from screen/modal
event handlers. No screen talks to the database directly — always through a
DAO.

```
UI (screens/, widgets_modals/)
   ↕ Riverpod providers (providers/)
   ↕ DAOs (data/daos/)
   ↕ drift AppDatabase (data/database.dart)
   ↕ SQLite file (app documents directory, via path_provider)
```

## Data model (drift tables)

### Task
| field | type | notes |
|---|---|---|
| id | int, PK autoincrement | |
| title | text | required |
| description | text, nullable | |
| category | text | e.g. Study, Personal |
| dueDate | dateTime | |
| dueTime | text, nullable | |
| reminderMinutesBefore | int, nullable | |
| isCompleted | bool, default false | |
| createdAt | dateTime | |

### ClassSession
| field | type | notes |
|---|---|---|
| id | int PK | |
| courseName | text | e.g. "DBMS" |
| dayOfWeek | int | 1=Mon..7=Sun |
| startTime | text | |
| endTime | text | |
| room | text, nullable | |
| semester | text | |
| colorTag | text | hex, for the left color bar |

### StudySession
| field | type | notes |
|---|---|---|
| id | int PK | |
| courseName | text | links to a course/label, not necessarily ClassSession FK |
| startedAt | dateTime | |
| durationMinutes | int | |

### Course (for Study screen progress bars)
| field | type | notes |
|---|---|---|
| id | int PK | |
| name | text | |
| totalLoggedMinutes | int, default 0 | denormalized, updated when a StudySession is saved |

### Transaction (Money)
| field | type | notes |
|---|---|---|
| id | int PK | |
| type | text | "expense" \| "income" \| "loan" |
| amount | real | |
| category | text | e.g. Food & Dining, Transport, Shopping |
| note | text, nullable | |
| date | dateTime | |

### Note
| field | type | notes |
|---|---|---|
| id | int PK | |
| title | text | |
| content | text | |
| category | text | Lecture \| Personal \| Ideas |
| createdAt | dateTime | |
| updatedAt | dateTime | |

### Reminder
| field | type | notes |
|---|---|---|
| id | int PK | |
| title | text | |
| dueAt | dateTime | |
| isEnabled | bool, default true | |

### DocumentMeta
| field | type | notes |
|---|---|---|
| id | int PK | |
| fileName | text | |
| fileType | text | pdf \| image \| doc \| other |
| filePath | text | local path where file is copied to app storage |
| sizeBytes | int | |
| addedAt | dateTime | |

### Profile (single row)
| field | type | notes |
|---|---|---|
| id | int PK, always 1 | |
| name | text | |
| role | text | |
| email | text | |
| phone | text | |
| college | text | |
| semester | text | |
| photoPath | text, nullable | |
| quote | text, nullable | |
| points | int, default 0 | |

## Navigation
`go_router` with a `ShellRoute` wrapping `AppScaffold` (bottom nav) for the
10 main sections, plus modal routes (`showModalBottomSheet`) for Add
Task/Expense/Note rather than pushed routes — matches the mockup's overlay
presentation.

## Derived/computed values (don't store, compute on read)
- Home "Today's Progress %" = completed tasks due today / total tasks due
  today.
- Home "Weekly Goal %" and Study weekly bar chart = aggregate of
  StudySession rows grouped by day for the current week.
- Money weekly summary cards = aggregate of Transaction rows for the
  current week, grouped by type.

## Future extension point (not built now)
Add a `sync/` module with a `SyncService` interface
(`Future<void> pushLocalChanges()`, `Future<void> pullRemoteChanges()`) that
DAOs can optionally call after a local write. Leave unimplemented — local
writes must never depend on this succeeding.
