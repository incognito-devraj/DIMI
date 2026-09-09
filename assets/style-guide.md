# DIMI Style Guide (extracted from mockups)

These are approximate values read off the design — treat as the starting
point, adjust by eye against `assets/screens/*.png` while building.

## Colors
| Token | Hex | Usage |
|---|---|---|
| `background` | `#F4EFE3` | App background (warm cream) |
| `surface` | `#FFFFFF` | Cards |
| `surfaceDark` | `#1C1C1E` | Dark cards (e.g. onboarding hero, active states) |
| `accent` | `#F5A623` | Primary accent — active tab icon, highlights, chart bars, buttons like "Add Task" |
| `accentSoft` | `#FCE6BE` | Accent tints, progress bar tracks |
| `textPrimary` | `#1C1C1E` | Headings, primary text |
| `textSecondary` | `#8A8A8E` | Sub-labels, timestamps, metadata |
| `divider` | `#EAE4D6` | Card borders / separators |
| `success` | `#34C759` | Completed states, positive deltas |
| `danger` | `#E0483E` | Expenses, delete/logout, alerts |
| `info` | `#4A90D9` | Secondary category tags (e.g. CN Lab blue) |

## Typography
- Display/serif italic — tagline only ("A better you, One day at a time.")
  → use a serif font (e.g. `PlayfairDisplay-Italic` or system serif).
- Everything else: rounded sans-serif, e.g. `Poppins` or `Inter`.
  - Screen titles: 24–28px, semibold
  - Card titles: 15–16px, semibold
  - Body/labels: 13–14px, regular
  - Captions/timestamps: 11–12px, textSecondary

## Shape & spacing
- Card corner radius: ~20px (large, soft)
- Button corner radius: ~28px (pill-shaped)
- Screen horizontal padding: 20px
- Card internal padding: 16px
- Standard gap between stacked cards: 12–16px

## Components observed
- **Pill segmented control** (e.g. "Day / Week / Month", "All / Today /
  Upcoming / Completed") — dark active pill on light track.
- **Bottom nav**: 5 icons, active icon in a filled amber circle.
- **Primary CTA button**: full-width, black background, white text, pill
  shape (e.g. "Get Started", "Add Task").
- **Progress bar**: thin track in `accentSoft`, filled in `accent` or
  `surfaceDark` depending on context.
- **Bar chart** (Study Progress, Money): vertical rounded bars, one taller
  bar highlighted in `accent` with a value bubble above it.
- **List row with left color bar**: Planner and Classes use a thin colored
  vertical bar to color-code entries by subject.
