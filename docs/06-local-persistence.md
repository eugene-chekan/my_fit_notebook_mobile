# 06 — Local persistence (SQLite on-device)

## Same database engine, different door

Both apps use SQLite — the Flask app via Python's built-in `sqlite3` module,
this app via the `sqflite` Flutter plugin. It's genuinely the same file
format and SQL dialect; only the door you walk through to reach it differs.
The schema in `lib/data/db/app_database.dart` is a deliberate byte-for-byte
copy of `database.py`'s `init_schema`, table names and column names included
— see doc 04 for why that matters (there's no shared code between the two
apps, so keeping them textually identical is what keeps them compatible).

## Where the file lives

On the web app, `DATABASE_PATH` points at a file you chose (`instance/
fitness.db` by default). On mobile, apps don't get to pick arbitrary
filesystem paths — each app is sandboxed to its own private storage area,
and you ask the OS where that is:

```dart
// lib/data/db/app_database.dart
final dir = await getApplicationDocumentsDirectory();   // from path_provider
final path = p.join(dir.path, 'fitness.db');
```

`path_provider` is a plugin (code that calls into real iOS/Android APIs
under the hood) that answers "where is this app allowed to write files?" —
on Android that's typically `/data/data/<package>/app_flutter/`, on iOS
somewhere inside the app's sandboxed container. You never hardcode it,
because it's different per OS and per install.

## Everything is `async`

Opening a database, running a query, inserting a row — all of these touch
disk, so all of them are `async` in `sqflite` (see doc 01 for what that
means). Compare the shape of a repository method to its Python twin:

```python
# repositories/routines.py
def list_routines(conn: sqlite3.Connection) -> list[Routine]:
    return crud.fetch_all(conn, "SELECT ... FROM routines ORDER BY sort_order ASC, id ASC", (), mapper=_to_routine)
```

```dart
// lib/data/repositories/routine_repository.dart
Future<List<Routine>> listRoutines() async {
  final db = await _db;
  final rows = await db.rawQuery(
    'SELECT $_routineColumns FROM routines ORDER BY sort_order ASC, id ASC',
  );
  return rows.map(Routine.fromMap).toList();
}
```

The Python version is synchronous because Flask's per-request model doesn't
need it to be anything else. The Dart version has to be `async` because
blocking the UI thread on disk I/O would freeze the whole app — even for a
query that returns in five milliseconds, Flutter wants that thread free to
keep animating.

## `?` placeholders — always, never string-interpolate a value in

```dart
await db.rawQuery(
  'SELECT $_routineColumns FROM routines WHERE id = ?',
  [routineId],
);
```

`$_routineColumns` is safe to interpolate because it's a constant string of
column names we wrote ourselves. `routineId` is passed as a `?` placeholder
with the value in a separate list, never interpolated into the SQL string
directly — this is exactly the same parameterized-query discipline as the
Python repositories using `?` with a tuple, and for the same reason: it's
what prevents SQL injection, and it's also just correct escaping for any
value (dates, names with quotes in them, etc.).

## `insert`/`update`/`delete` helpers vs. raw SQL

`sqflite` gives you two ways to write: helper methods that build the SQL for
you, and `rawQuery`/`rawUpdate`/`execute` for anything a helper can't
express.

```dart
// helper — good for simple, single-table writes
await db.insert('routines', {
  'name': name.trim(),
  'sort_order': nextOrder,
  'created_at': now,
});

await db.update(
  'routines',
  {'name': trimmed, 'description': description.trim()},
  where: 'id = ?',
  whereArgs: [routineId],
);

// raw — needed for anything the helpers can't express, like a CASE expression
await db.rawUpdate(
  'UPDATE exercises SET is_done = CASE is_done WHEN 0 THEN 1 ELSE 0 END '
  'WHERE id = ? AND routine_id = ?',
  [exerciseId, routineId],
);
```

Both end up sending real SQL to SQLite; the helpers just save you from
typing `UPDATE table SET ... WHERE ...` by hand for the common case.

## Transactions: `batch()`

`ExerciseRepository.reorderExercises` needs to update every exercise's
`sort_order` in one go. Doing this as N separate `await db.update(...)`
calls would work, but each one is its own round trip; `batch()` groups them
into a single atomic unit:

```dart
final batch = db.batch();
for (var i = 0; i < orderedIds.length; i++) {
  batch.update('exercises', {'sort_order': i},
      where: 'id = ? AND routine_id = ?', whereArgs: [orderedIds[i], routineId]);
}
await batch.commit(noResult: true);
```

This is the Dart equivalent of the Python version looping with
`conn.execute(...)` and a single `conn.commit()` at the end.

## Handling constraint violations

The `completions` table has `UNIQUE(routine_id, completed_on)` — you can't
log two completions for the same routine on the same day. SQLite raises an
error on a duplicate insert; `sqflite` surfaces it as a `DatabaseException`,
which `CompletionRepository` catches and turns into a clean boolean instead
of letting the exception escape:

```dart
try {
  await db.insert('completions', {/* ... */});
  return true;
} on DatabaseException catch (e) {
  if (e.isUniqueConstraintError()) return false;
  rethrow;   // anything else is a real bug — don't swallow it
}
```

`rethrow` (not `throw e`) preserves the original stack trace — always
prefer it when you're deciding "this specific error is expected, everything
else should propagate as a genuine crash."

## Try this

Open `lib/data/db/app_database.dart` and add a `print` inside `onCreate`
right after each `CREATE TABLE` statement. Delete the app from your
device/emulator (a fresh install re-triggers `onCreate`) and watch the log
to see the schema get created exactly once, on first launch.
