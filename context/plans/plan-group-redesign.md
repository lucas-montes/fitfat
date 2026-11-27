# Plan: Tasks & goals redesign — Today, goals that track themselves (Phase PG)

**Status:** in progress (2026-11-27)

## Change Summary

Rebuild the Plan tab on the design system (proposals:
https://claude.ai/artifact/SjcVZMs4L9oVqCTm9sSTmm, rounds 16–17):

1. **Today** — Tasks / Goals tabs; the day as a time list (start and end on the
   left, a red line at the current time), anytime tasks in their own card;
   ‹ › and swipe change day. Ready for Outlook events (read-only) later.
2. **Quick add** — + opens a sheet: title and chips (day, time, repeat, goal,
   workout); Add keeps it open; More options opens the full form.
3. **Goals list** — cards with a progress bar (value / target inside, % at the
   end), end date, where the number comes from, linked tasks done and the next
   one; Planned and Done below.
4. **Goals track themselves** — a goal reads its progress from workouts, body
   weight, an account balance, meals or linked tasks; Manual only when needed.
5. **Manual progress** — a step button on the card (long-press for an exact
   value) and a reply field in the evening reminder notification.
6. **Goal detail** — value, bar and chart (when there are 2+ points), then
   Progress / Tasks tabs.

## Direction (user, 2026-11-27)

- Mostly looks at **today's list**; uses **start and end times** (Outlook calendar
  events will be parsed in later).
- Goal progress **as automatic as possible**; some goals need manual entry and a
  fast way to record it.

## Decisions

| # | Question | Status |
|---|---|---|
| D1 | Today | **decided: round 17 A** — time list with a now line; anytime card |
| D2 | Choosing the source | **decided: round 17 A** — a Track row in the goal form opens the source list (Manual last); each source asks only what it needs |
| D3 | Manual progress | **decided: round 17 A + C** — step button on the goal card (long-press = exact value) and a reply field in the reminder notification |
| D4 | Goals list | **decided: round 16 A** — cards with progress and tasks |
| D5 | Goal detail | **decided: round 16 A's chart + B's Progress / Tasks toggle** |
| D6 | Quick add | **decided: round 16 A** — sheet with title + chips |
| D7 | Week / month | not redesigned this phase: kept, reached from a calendar icon |

## Data

Schema v42: `goals.track_source` (TEXT, null = manual) and `goals.track_param`
(TEXT, e.g. an exercise or account id). Sources:

| Source | Value | Param |
|---|---|---|
| `exercise_best` | heaviest completed set (kg) of an exercise | exercise id |
| `exercise_distance` | longest completed distance (km) of an exercise | exercise id |
| `workouts_count` | finished workouts since the goal's start | — |
| `body_weight` | latest weight (kg) | — |
| `account_balance` | account balance (base currency) | account id |
| `meals_protein` | average daily protein, last 7 days (g) | — |
| `tasks_done` | linked tasks done | — |

Each source yields a dated series; the current value is its last point. Manual
goals keep using `goal_progress_entries`. The columns travel in the goal push
(row JSON); the pull leaves them untouched until the server stores them
(**server follow-up**: add the two columns to `goals` and to the pull payload).

## Tasks

- [ ] T01 — Schema v42, model, repository, pull/push.
- [ ] T02 — `goal_tracking.dart`: series per source; `goalStatusProvider`.
- [ ] T03 — Today view + Tasks / Goals tabs; week/month behind a calendar icon.
- [ ] T04 — Quick add sheet.
- [ ] T05 — Goals list cards; step button; long-press exact value.
- [ ] T06 — Goal detail (header, chart, Progress / Tasks).
- [ ] T07 — Track picker in the goal form.
- [ ] T08 — Reminder reply: input action, queued in preferences, recorded on start/resume.
- [ ] T09 — Tests, l10n, docs.

## Acceptance

- Analyzer clean, all tests pass.
- A goal tracking a source shows its current value without manual entry.
- A manual goal can be stepped from its card and from the notification.
