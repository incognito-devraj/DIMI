   # DIMI — Kiro Handoff Package

This folder is a ready-to-use Kiro workspace. It contains no code yet — it
contains the **spec** that Kiro will build the code from, plus your design
reference images.

## What's inside
```
.kiro/
  steering/
    product.md      — what DIMI is, tone, priorities (always-on context)
    tech.md          — locked stack: Flutter + drift + Riverpod + go_router
    structure.md      — folder/file conventions Kiro should follow
  specs/
    dimi-app/
      requirements.md — every feature, in WHEN/THEN acceptance-criteria form
      design.md        — architecture + full data model (drift tables)
      tasks.md          — ordered, checkable build checklist
assets/
  style-guide.md    — colors, type, spacing, component notes extracted from your mockup
  screens/           — your mockup cropped into 15 individual reference PNGs
```

## Exact steps

1. **Install Kiro** if you haven't (kiro.dev at time of writing — check
   current install instructions, Kiro ships fast).
2. **Copy this entire `dimi_handoff` folder** to where you want your project
   to live, then rename it to whatever you want your repo to be called
   (e.g. `dimi_app`).
3. **Open that folder in Kiro** (File → Open Folder). Kiro will detect the
   `.kiro/` directory automatically and load the steering files as
   always-on context and the spec as an available spec.
4. **Initialize the actual Flutter project inside this folder** — either:
   - ask Kiro directly: *"Set up a new Flutter project in this folder
     called dimi_app, following tech.md and structure.md"*, or
   - run `flutter create .` yourself in this folder first, then let Kiro
     work inside it.
5. **Open the spec**: in Kiro, go to `.kiro/specs/dimi-app/` — it should
   show requirements.md / design.md / tasks.md with the option to execute
   tasks one at a time.
6. **Execute tasks in order, phase by phase**, per `tasks.md`. Don't ask
   Kiro to "build the whole app" in one go — approve/review each phase
   (Phase 0 setup → Phase 1 data layer → Phase 2 Tasks+Home → ...) before
   moving to the next. This is the difference between a working app and a
   plausible-looking mess.
7. **At the start of each screen-building task**, explicitly point Kiro at
   its reference image, e.g.: *"Build the Tasks screen per
   assets/screens/tasks.png and requirements.md section 4."* Kiro can read
   image files directly — give it the path.
8. **After each phase**, run the app (`flutter run`) yourself and actually
   look at it next to the matching PNG before telling Kiro to continue.
   This is the one step you can't skip if you want the final look to
   actually match — catch drift early, not after 10 screens are built.
9. Once Phase 7 (Polish) is checked off, you have the full local-only app.
   Sync/backend is intentionally not in this spec — come back for a second
   spec (`.kiro/specs/dimi-sync/`) once the local app is solid.

## If you get stuck
- If a screen comes out visually wrong, don't describe the fix in words —
  say *"compare your output to assets/screens/<name>.png and fix the
  differences"*. Agents are much more accurate correcting against an image
  than against a text description of what's wrong.
- If Kiro suggests a different package or architecture than `tech.md`
  specifies, reject it and point it back at the steering file — that file
  exists specifically so decisions don't drift screen to screen.
