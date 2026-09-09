# Project Structure

Use this folder layout. Keep screens, data, and shared widgets clearly
separated so each spec task touches a predictable set of files.

```
lib/
  main.dart
  theme/
    app_theme.dart          # colors, text styles, spacing constants
  data/
    database.dart           # drift database class
    tables/
      tasks.dart
      classes.dart
      study_sessions.dart
      expenses.dart
      notes.dart
      reminders.dart
      documents.dart
      profile.dart
    daos/
      task_dao.dart
      class_dao.dart
      study_dao.dart
      money_dao.dart
      note_dao.dart
      reminder_dao.dart
      document_dao.dart
  providers/
    task_providers.dart
    class_providers.dart
    study_providers.dart
    money_providers.dart
    note_providers.dart
    reminder_providers.dart
    document_providers.dart
  routing/
    app_router.dart
  widgets/
    app_scaffold.dart        # shared bottom-nav + top bar shell
    section_card.dart        # reusable rounded card used across screens
    progress_ring.dart
    bar_chart_widget.dart
    empty_state.dart
  screens/
    onboarding/
    home/
    planner/
    tasks/
    classes/
    study/
    money/
    notes/
    reminders/
    documents/
    settings/
    profile/
  widgets_modals/
    add_task_sheet.dart
    add_expense_sheet.dart
    add_note_sheet.dart
```

## Conventions
- One screen = one folder under `screens/` containing the page widget plus
  any screen-only sub-widgets.
- Add/edit forms (Add Task, Add Expense, Add Note, etc.) are modal bottom
  sheets, not full routes — matches the mockup's overlay style.
- Every list-driven screen (Tasks, Notes, Reminders, Documents, Classes)
  must handle three states explicitly: loading, empty, populated. Use
  `widgets/empty_state.dart` for the empty case rather than inventing a new
  empty layout per screen.
- Bottom nav bar is shared via `AppScaffold` — do not copy-paste the nav bar
  markup into each screen.
