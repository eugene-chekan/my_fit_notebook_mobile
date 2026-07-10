# 04 — App architecture

This app is deliberately laid out to mirror the Flask backend's layering, so
if you already understand `my_fit_notebook`'s structure, this is mostly
relabeling:

| Flask (`my_fit_notebook`)          | Flutter (`my_fit_notebook_mobile`)          | Job |
|---|---|---|
| `models.py`                        | `lib/data/models/*.dart`                    | Plain data shapes, no behavior |
| `repositories/*.py`                | `lib/data/repositories/*.dart`              | Raw SQL, one table each |
| `services/*.py`                    | `lib/data/services/workout_service.dart`    | Business logic that spans repositories |
| `routes/*.py` (Flask blueprints)   | `lib/screens/*.dart`                        | The user-facing surface |
| `templates/*.html` + `notebook.css`| `lib/widgets/*.dart` + `lib/theme/`         | Reusable presentation |
| Flask `g`/session (per-request)    | `lib/state/*.dart` (`ChangeNotifier`s)      | Holds data across interactions |
| — (Flask has no client state)      | `lib/main.dart`                             | App entry point + global theme |

## Why this split, specifically

**Models are dumb on purpose.** `Routine`, `Exercise`, `Completion` in
`lib/data/models/` hold data and know how to convert to/from a database row
(`fromMap`/`toMap`) — nothing else. No widget code, no SQL, no business
rules. This mirrors `models.py`'s frozen dataclasses exactly. Keeping models
dumb means you can reason about "what shape is a Routine" without also
holding "how do I fetch/save one" or "what happens when I finish a workout"
in your head at the same time.

**Repositories are the only code that writes SQL.** Every table gets exactly
one repository class (`RoutineRepository`, `ExerciseRepository`,
`CompletionRepository`), each just a set of async methods that take/return
models. If the on-disk schema ever needs to change, these three files are
the only place that needs to know about column names. Nothing above this
layer ever writes a raw SQL string.

**Services hold logic that needs more than one repository.**
`WorkoutService.finishWorkout()` needs to read the routine, read its
exercises, write a completion, reset the exercises, and clear the routine's
timer — five operations across three tables. That doesn't belong inside any
single repository (which one would own it?), so it lives in
`lib/data/services/workout_service.dart`, exactly where `finish_workout()`
lives in the Python `services/workout_service.py`. The pure-math functions in
there (`calculatePausedSeconds`, `calculateDurationMinutes`) are `static`
because they don't touch the database at all — they're unit-testable in
isolation, same as their Python counterparts.

**State providers are the layer Flask doesn't need.** A Flask view function
runs once per HTTP request and throws its local state away when the response
is sent — the database is the only thing that persists. A mobile screen
stays alive for as long as the user is looking at it, re-rendering many
times without a "request" boundary. `lib/state/*.dart` exists to hold data
across that entire lifetime and announce changes to the UI (see doc 03) —
there's no equivalent file in the Flask app because Flask never needs one.

**Screens are the thin layer, same as Flask routes.** `routes/workout.py`'s
view functions are short: parse the request, call a service function, render
a template. `lib/screens/routine_screen.dart` follows the same shape: read
from a provider, call a provider method on a button press, describe a widget
tree. Neither layer should contain business logic — if you find yourself
writing a calculation inline in a screen's `build` method, it probably
belongs in a service instead.

## Where the two apps read the *same* rules from *different* files

Because there's no shared server between the web app and this mobile app
(by design — see the top-level README's local-first decision), every rule
that must behave identically on both — "a workout's paused time keeps
accumulating across multiple pause/resume cycles," "duration is truncated to
whole minutes," "a routine can only have one completion per calendar day" —
is implemented **twice**: once in Python, once in Dart. This is the real
cost of local-first without a shared backend, and it's worth knowing about
explicitly:

- `services/workout_service.py` ↔ `lib/data/services/workout_service.dart`
- `repositories/*.py` ↔ `lib/data/repositories/*.dart` (same SQL, same schema)
- `filters.py` (date/duration formatting) ↔ `lib/utils/formatters.dart`

If you ever change one of these rules on the Flask side, search for its
Dart twin and update it too — nothing will warn you if they drift apart,
since there's no shared code path between the two apps.

## Import direction — a rule worth keeping

Data flows one way through the layers:

```
models  ←  repositories  ←  services  ←  state (providers)  ←  screens
```

A model never imports a repository. A repository never imports a service.
A screen can import a provider, a provider can import a service or
repository, but nothing "below" ever reaches back "up" to import something
above it. This is what makes each layer independently testable and
replaceable — e.g. swapping `sqflite` for a synced backend later only
touches the repository layer, and nothing above it needs to change, because
services/providers/screens only ever talk to repositories through their
method signatures (`Future<List<Routine>>`, etc.), never their SQL
internals.
