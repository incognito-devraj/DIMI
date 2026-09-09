# Tasks: DIMI App

Work through these in order. Each task should end in a runnable app —
don't move to the next phase until the current one builds and runs.

## Phase 0 — Project setup
- [ ] Create Flutter project, add packages from `tech.md`.
- [ ] Set up `lib/theme/app_theme.dart` using `assets/style-guide.md` tokens.
- [ ] Set up `go_router` skeleton with 10 empty placeholder screens and the
      shared `AppScaffold` bottom nav (5 visible tabs: Home, Planner,
      College, Study/Money [context-dependent 4th icon], More).

## Phase 1 — Data layer
- [ ] Implement all drift tables from `design.md` in `lib/data/tables/`.
- [ ] Implement `AppDatabase` in `lib/data/database.dart` with migrations
      starting at schema version 1.
- [ ] Implement one DAO per entity in `lib/data/daos/` with reactive
      `watch...()` stream methods and `insert/update/delete` methods.
- [ ] Write a small seed script (debug-only) that inserts sample data
      matching the mockup (e.g. "DBMS Assignment", "CN Lab", a few
      transactions) so screens have something to render while building.
- [ ] Verify: run the app, confirm seed data can be queried (temporary
      debug print or test screen is fine).

## Phase 2 — Core loop: Tasks + Home
- [ ] Build Tasks screen per `assets/screens/tasks.png`: filter tabs,
      progress bar, checklist, Add Task FAB.
- [ ] Build Add Task modal per `assets/screens/add_task.png`, wired to
      `TaskDao.insertTask`.
- [ ] Build Home screen per `assets/screens/home.png`, with Today's
      Progress, Tasks Completed, and quick actions wired to real data.
- [ ] Verify: adding/completing a task on the Tasks screen updates Home's
      progress numbers without restarting the app.

## Phase 3 — Planner + Classes
- [ ] Build Classes screen per `assets/screens/classes.png`.
- [ ] Build Planner screen per `assets/screens/planner.png`, merging
      ClassSession + Task entries into one time-sorted list for the
      selected day.

## Phase 4 — Study + Money
- [ ] Build Study screen per `assets/screens/study.png`, including the
      weekly bar chart (fl_chart) and Start Study Session flow.
- [ ] Build Money screen per `assets/screens/money.png` with Overview tab
      fully working (Expenses/Income/Loans tabs can filter the same list).
- [ ] Build Add Expense modal per `assets/screens/add_expense.png`.
- [ ] Verify: Home's Study Progress card reflects sessions logged from the
      Study screen.

## Phase 5 — Notes, Reminders, Documents
- [ ] Build Notes screen + Add Note modal per
      `assets/screens/notes.png` / `add_note.png`.
- [ ] Build Reminders screen per `assets/screens/reminders.png` with
      working enable/disable toggle persistence.
- [ ] Build Documents screen per `assets/screens/documents.png` using a
      file picker package to select and copy files into app storage.

## Phase 6 — Settings + Profile + Onboarding
- [ ] Build Onboarding screen per `assets/screens/onboarding.png`, gated by
      a "hasOnboarded" flag (SharedPreferences is fine here).
- [ ] Build Profile screen per `assets/screens/profile.png` with edit mode.
- [ ] Build Settings screen per `assets/screens/settings.png` (Logout can
      just clear the onboarding flag / return to onboarding for now — no
      real auth exists).

## Phase 7 — Polish pass
- [ ] Add empty states to every list screen (`widgets/empty_state.dart`).
- [ ] Confirm every screen matches its reference image: spacing, colors,
      corner radii, font weights — do a side-by-side diff against
      `assets/screens/*.png`.
- [ ] Test full offline flow: enable airplane mode, use every feature,
      confirm nothing breaks or shows loading spinners indefinitely.
- [ ] Test app restart: force-quit and reopen, confirm all data persisted.
