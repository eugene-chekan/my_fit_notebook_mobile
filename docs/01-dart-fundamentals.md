# 01 — Dart fundamentals

Dart is the language; Flutter is the UI framework built on top of it (same
relationship as Python and Flask in the web app). This doc covers the Dart
features the codebase already leans on, using real snippets from `lib/`.

## Null safety

Every type in Dart is non-nullable by default. `String name` can never hold
`null` — the compiler rejects it at analysis time, not at runtime. If a value
really can be absent, you say so explicitly with `?`:

```dart
// lib/data/models/routine.dart
final String? startedAt;   // can be null: workout not started yet
final String createdAt;    // can never be null
```

This is the single biggest difference from Python, where `None` can sneak
into any variable. In Dart, if `routine.startedAt` compiles, the analyzer has
already proven it's either a real `String` or explicitly `null` — you can't
forget a null check the way you can in Python or JavaScript, because the type
system won't let you call `.length` on a `String?` without narrowing it
first:

```dart
String? startedAt = routine.startedAt;
// startedAt.length;        // compile error: startedAt might be null
if (startedAt != null) {
  startedAt.length;         // fine — Dart "promotes" it to String here
}
```

Two operators you'll see constantly:

- `??` — "or else": `map['description'] as String? ?? ''` means "use the
  value, or `''` if it's null." See `Routine.fromMap` in
  `lib/data/models/routine.dart`.
- `!` — "trust me, it's not null": a manual override you use only when you
  are certain. `routine.startedAt!` appears in `routine_screen.dart` inside a
  branch that already checked `routine.isStarted`, so the null check has
  already happened logically, just not in a way the analyzer can see through.
  Use `!` sparingly — it's the one place you can still crash on a null value.

## Classes and constructors

A Dart class looks like this (from `lib/data/models/exercise.dart`):

```dart
class Exercise {
  const Exercise({
    required this.id,
    required this.routineId,
    required this.name,
    required this.sortOrder,
    required this.isDone,
  });

  final int id;
  final int routineId;
  final String name;
  final int sortOrder;
  final bool isDone;
  // ...
}
```

A few things happening at once:

- `final` fields are set once at construction and never reassigned — this
  class is **immutable**. Instead of mutating an `Exercise`, code creates a
  new one (see `copyWith` a few lines below it).
- The constructor uses **named parameters** (`{required this.id, ...}`)
  instead of positional ones. Callers must write `Exercise(id: 1, name: ...)`
  — this is the Dart convention for any constructor with more than one or two
  arguments, because it's self-documenting at the call site.
- `const Exercise({...})` marks this as a **const constructor**: if every
  field passed in is itself a compile-time constant, Dart can build the
  object once and reuse the same instance everywhere, which is a real
  performance win for widgets (more on this in doc 02).

### Factory constructors

`Exercise.fromMap` is a **factory constructor** — a named constructor that
runs code before deciding what to return, instead of just assigning fields:

```dart
factory Exercise.fromMap(Map<String, Object?> map) {
  return Exercise(
    id: map['id'] as int,
    routineId: map['routine_id'] as int,
    name: map['name'] as String,
    sortOrder: map['sort_order'] as int,
    isDone: (map['is_done'] as int) != 0,
  );
}
```

This is the Dart equivalent of the Python repository's `_to_exercise(row)`
helper — it converts a raw database row (`Map<String, Object?>`, the shape
`sqflite` hands back) into a typed model. `is_done` is stored as SQLite
`INTEGER` (0/1), so the factory does the `!= 0` conversion to `bool` in one
place, the same way the Python version does `bool(d["is_done"])`.

## Collections

`List<Routine>`, `Map<String, List<String>>` — Dart generics look just like
Python type hints but are enforced, not advisory. `CalendarProvider` builds a
`Map<String, List<String>>` (ISO date → routine names) exactly the way the
Flask `completion_routines_for_month` builds a `dict[str, list[str]]`:

```dart
// lib/data/repositories/completion_repository.dart
final result = <String, List<String>>{};
for (final row in rows) {
  final day = row['d'] as String;
  result.putIfAbsent(day, () => []).add(row['name'] as String);
}
```

`putIfAbsent(key, () => [])` reads as "get the list at `key`, creating an
empty one first if it's not there yet" — the same job as Python's
`result.setdefault(day, []).append(...)`.

## `async`/`await` and `Future`

Any operation that takes real time — reading the database, waiting a second
— is `async` in Dart. An `async` function always returns a `Future<T>`
instead of a `T` directly:

```dart
// lib/data/repositories/routine_repository.dart
Future<List<Routine>> listRoutines() async {
  final db = await _db;
  final rows = await db.rawQuery('SELECT ... FROM routines ...');
  return rows.map(Routine.fromMap).toList();
}
```

Read `Future<List<Routine>>` as "a promise to eventually hand you a
`List<Routine>`." `await` pauses this function (not the whole app) until that
promise resolves. Calling code has to `await` it too, or explicitly handle
the `Future`:

```dart
// lib/state/routines_provider.dart
Future<void> load() async {
  _routines = await _repository.listRoutines();
  _loading = false;
  notifyListeners();
}
```

This is the same shape as Python's `async def` / `await`, with one Dart-only
wrinkle: **`async` is contagious but not automatic**. If a function calls an
`async` function, it usually needs to be `async` itself and `await` the
call, or the `Future` just gets returned unresolved. The analyzer will warn
you (`unawaited_futures`) if you forget.

`Timer.periodic`, used in `RoutineDetailProvider` to tick the pulsing-dot
label once a second, is a lower-level building block than `Future` — it's a
callback that fires repeatedly rather than a value that resolves once:

```dart
// lib/state/routine_detail_provider.dart
_ticker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
```

## `try`/`catch` for the flaky stuff

Parsing a possibly-malformed timestamp is wrapped defensively, matching the
Python service's `contextlib.suppress(ValueError)`:

```dart
// lib/data/services/workout_service.dart
try {
  paused += DateTime.now().difference(DateTime.parse(pausedAt)).inSeconds;
} catch (_) {
  // ignore malformed timestamp, mirrors the Python contextlib.suppress
}
```

`catch (_)` means "catch it, but I don't need the exception object" — same
wildcard convention as an unused function parameter.

## String interpolation

`'${routine.name}'` embeds an expression directly in a string, same idea as
Python f-strings:

```dart
'Delete "${routine.name}"?'          // full expression needs braces
'${minutes}m'                        // simple identifier can drop them: '$minutes'
```

## Where to see all of this together

`lib/data/services/workout_service.dart` is the single file that uses the
most of the above at once: null-safe fields, `static` pure functions,
`try`/`catch`, and `async`/`await` orchestration. It's a good file to re-read
once the rest of this doc feels familiar.
