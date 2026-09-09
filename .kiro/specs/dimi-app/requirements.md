# Requirements: DIMI App

Reference visuals for every requirement below live in `assets/screens/`
(one PNG per screen, named to match section headers here).

## 1. Onboarding
- WHEN the app is launched for the first time THE SYSTEM SHALL show an
  onboarding screen with the DIMI logo, tagline, and a "Get Started" button.
- WHEN the user taps "Get Started" THE SYSTEM SHALL navigate to Home and
  SHALL NOT show onboarding again on subsequent launches.

## 2. Home Dashboard
- WHEN the user opens Home THE SYSTEM SHALL display: a welcome header with
  the user's name, a profile card (photo, name, role, DIMI points), today's
  progress %, tasks completed count, weekly goal %, a quick-action row
  (Task / Expense / Note / Reminder / Notice), and a Study Progress card
  with a weekly bar chart and total hours.
- WHEN any underlying data changes (a task is completed, a study session is
  logged, an expense is added) THE SYSTEM SHALL update the relevant Home
  card automatically without requiring app restart.

## 3. Planner
- WHEN the user opens Planner THE SYSTEM SHALL show a day/week/month
  segmented control (default: Day) and a chronological list of that day's
  schedule items (classes, tasks, breaks) grouped by time slot.
- WHEN the user taps the date arrows THE SYSTEM SHALL move the view to the
  previous/next day and refresh the schedule list.
- WHEN the user taps the "+" button THE SYSTEM SHALL open a form to add a
  new planner item with time, title, and category.

## 4. Tasks
- WHEN the user opens Tasks THE SYSTEM SHALL show filter tabs (All / Today /
  Upcoming / Completed), a completion progress bar (e.g. "6/10"), and a
  checklist of tasks with title and due date/time.
- WHEN the user taps a task's checkbox THE SYSTEM SHALL toggle its completed
  state and persist it immediately.
- WHEN the user taps "Add Task" THE SYSTEM SHALL open the Add Task modal
  (see section 12) pre-filled with today's date.

## 5. Classes
- WHEN the user opens Classes THE SYSTEM SHALL show a semester selector, a
  day-of-week strip (Mon–Fri, currently selected day highlighted), and a
  list of that day's classes with time, room, and status (e.g. "Ongoing").
- WHEN the user selects a different day on the strip THE SYSTEM SHALL update
  the class list for that day.

## 6. Study
- WHEN the user opens Study THE SYSTEM SHALL show total study time this
  week with a daily bar chart, a "Study Courses" list with per-course
  progress bars, and a "Start Study Session" button.
- WHEN the user taps "Start Study Session" THE SYSTEM SHALL begin timing a
  session and, once ended, SHALL add the elapsed time to that course's
  logged hours and to the weekly chart.

## 7. Money
- WHEN the user opens Money THE SYSTEM SHALL show tabs (Overview / Expenses
  / Income / Loans), weekly spend vs. lent-money summary cards, a bar chart
  of spending by day, and a "Recent Transactions" list with category icons.
- WHEN the user taps "+" THE SYSTEM SHALL open the Add Expense modal (see
  section 12).
- WHEN a transaction is added THE SYSTEM SHALL update the weekly summary
  cards and chart immediately.

## 8. Notes
- WHEN the user opens Notes THE SYSTEM SHALL show filter tabs (All /
  Lecture / Personal / Ideas) and a list of notes with title, snippet, and
  timestamp.
- WHEN the user taps "Add Note" THE SYSTEM SHALL open the Add Note modal
  (see section 12).

## 9. Reminders
- WHEN the user opens Reminders THE SYSTEM SHALL show filter tabs (All /
  Today / Upcoming) and a list of reminders each with a title, due
  date/time, and an enabled/disabled toggle.
- WHEN the user toggles a reminder THE SYSTEM SHALL persist the enabled
  state immediately.

## 10. Documents
- WHEN the user opens Documents THE SYSTEM SHALL show filter tabs (All /
  Notes / PDFs / Images / Others) and a list of documents with an icon,
  name, file type, size, and date.
- WHEN the user taps "Upload Document" THE SYSTEM SHALL let them pick a
  local file and SHALL store its metadata (name, type, size, path, date) in
  the local database.

## 11. Settings & Profile
- WHEN the user opens Settings THE SYSTEM SHALL show account info and
  grouped settings rows (Appearance, Notifications, Data & Backup,
  Security, About) and a Logout action.
- WHEN the user opens Profile THE SYSTEM SHALL show photo, name, role, key
  stats (tasks, classes, goal %, points), contact info, college, semester,
  and an editable personal quote.
- WHEN the user taps "Edit" on Profile THE SYSTEM SHALL allow editing of
  name, email, phone, college, semester, and quote, and SHALL persist
  changes on save.

## 12. Add/Edit Modals
- WHEN the user opens "Add Task" THE SYSTEM SHALL show fields: title,
  description (optional), date, time, category, reminder lead time, and a
  submit button that saves the task and closes the modal.
- WHEN the user opens "Add Expense" THE SYSTEM SHALL show fields: amount,
  category, note (optional), date, and a submit button that saves the
  transaction and closes the modal.
- WHEN the user opens "Add Note" THE SYSTEM SHALL show fields: title,
  content, category, and a submit button that saves the note and closes the
  modal.
- WHEN any modal's required fields are empty AND the user taps submit THE
  SYSTEM SHALL show inline validation errors and SHALL NOT save.

## 13. Data persistence (cross-cutting)
- WHEN the app is closed and reopened THE SYSTEM SHALL restore all
  previously entered data (tasks, notes, expenses, classes, reminders,
  documents, study sessions, profile) from the local database with no
  network dependency.
- WHEN the device has no internet connection THE SYSTEM SHALL remain fully
  functional for all features in sections 1–12.
