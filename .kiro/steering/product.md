# Product: DIMI — Plan · Track · Improve

DIMI is a personal student productivity app. It helps a college student
(archetype: "Devraj", CS engineering student) manage their daily life in one
place: tasks, class timetable, study sessions, notes, money, reminders, and
documents.

## Core principle: local-first
DIMI must work fully offline. All user data lives in a local SQLite database
on-device. There is no login wall and no required network connection for any
core feature. A cloud sync layer may be added later, but it is strictly
optional and the app must never block on it.

## Target user
- College/university students tracking coursework, study time, small
  personal expenses, and daily tasks.
- Wants a single home dashboard that summarizes everything (today's tasks,
  study progress, weekly goal) without digging into sub-screens.

## Tone / visual identity
- Warm, calm, "personal notebook" feel — not corporate.
- Cream/off-white backgrounds, warm amber/gold as the single accent color,
  near-black for primary buttons and headers, soft rounded cards.
- Serif italic used only for the tagline ("A better you, One day at a
  time."); everything else uses a clean rounded sans-serif.
- Reference screenshots for every screen are in `assets/screens/`. These are
  the literal visual target — match layout, spacing rhythm, card style,
  colors, and iconography as closely as possible pixel-for-pixel, don't
  reinterpret them.

## Feature areas (in priority order for build-out)
1. Home dashboard
2. Tasks
3. Planner (day/week/month schedule)
4. Classes (timetable)
5. Study (sessions + course progress)
6. Money (expenses/income)
7. Notes
8. Reminders
9. Documents (local file attachments, metadata only)
10. Settings / Profile
