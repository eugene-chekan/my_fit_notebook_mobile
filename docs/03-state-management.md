# 03 — State management

"State management" is just: *when data changes, how does the screen find
out and redraw itself?* Flutter has several answers, and this app uses two
of them at different scales.

## The smallest scale: `setState`

A `StatefulWidget`'s own `State` object can hold local, throwaway data —
things nothing outside that one widget cares about. `_PulsingLabelState` in
`lib/screens/routine_screen.dart` uses an `AnimationController` this way; it
has no reason to exist outside that one label widget.

For simpler cases, the classic pattern is:

```dart
int _counter = 0;

void _increment() {
  setState(() {
    _counter++;
  });
}
```

`setState` does two things: mutates the field, and tells Flutter "this
widget's `build` output may have changed — call `build` again." Skip
`setState` and mutate `_counter` directly, and the field changes but the
screen never redraws — a very common first-timer bug.

This app barely uses raw `setState` because almost all real data (routines,
exercises, completions) needs to be shared *across* widgets, not owned by
one. That's what the next two tools are for.

## `ChangeNotifier` — an object that announces its own changes

A `ChangeNotifier` is a plain Dart class (no widget, no UI) that keeps a list
of listeners and calls `notifyListeners()` whenever something they'd care
about changes. `RoutinesProvider` (`lib/state/routines_provider.dart`) is
one:

```dart
class RoutinesProvider extends ChangeNotifier {
  List<Routine> _routines = [];
  bool _loading = true;

  List<Routine> get routines => _routines;
  bool get loading => _loading;

  Future<void> load() async {
    _routines = await _repository.listRoutines();
    _loading = false;
    notifyListeners();          // <- "hey widgets, re-check your build"
  }
}
```

Notice the fields are private (`_routines`) with public getters
(`routines`) — this is a very common Dart pattern: expose read access freely,
but force all writes to go through a method (`load`, `addRoutine`,
`deleteRoutine`) so the object can always call `notifyListeners()` at the
right moment. A widget that just did `provider.routines.add(x)` from outside
would silently break the UI, because nothing would tell Flutter to rebuild.

`RoutineDetailProvider` (`lib/state/routine_detail_provider.dart`) is the
bigger example — it owns the currently-viewed routine, its exercises, its
completions, and the pause/resume timer, and every mutating method (
`toggleExercise`, `startWorkout`, `finishWorkout`, ...) ends by calling
`await load()`, which re-reads from the database and calls
`notifyListeners()`.

## `provider` — getting a `ChangeNotifier` down to the widgets that need it

Creating a `ChangeNotifier` is only half the job — widgets need a way to find
it and to be told to rebuild when it changes. That's the `provider` package
(a thin, official wrapper around Flutter's lower-level `InheritedWidget`).

Each screen creates its provider once and hands it down with
`ChangeNotifierProvider.value`:

```dart
// lib/screens/dashboard_screen.dart
return ChangeNotifierProvider.value(
  value: _provider,
  child: Scaffold(/* ... everything below can now find _provider ... */),
);
```

Anything nested inside that `child` can then reach it two ways:

```dart
context.watch<RoutinesProvider>()   // "read it, AND rebuild me when it changes"
context.read<RoutinesProvider>()    // "read it once, don't rebuild me on change"
```

`_RoutineList` uses `watch` because it displays the list and must redraw
when routines change. The delete-button callback uses `read` because it's
inside an `onPressed` closure — calling `notifyListeners()` there shouldn't
also try to rebuild the button mid-tap.

`Consumer<T>` is the same idea spelled as a widget instead of a method call,
useful when you want to `watch` inside a `build` method that doesn't have
easy access to `context.watch` (e.g. because it's a nested builder):

```dart
// lib/screens/routine_screen.dart
Consumer<RoutineDetailProvider>(
  builder: (context, provider, _) {
    if (provider.loading) return const CircularProgressIndicator();
    // ...
  },
)
```

## Why this app doesn't use `setState` for routines/exercises

If `DashboardScreen`'s `State` object owned the routine list directly with
`setState`, only that one screen could see or update it. The moment you
navigate to `RoutineScreen` and toggle an exercise, the dashboard has no way
to know the routine was started — you'd have to manually pass data back and
forth on every navigation. A `ChangeNotifier` handed to each screen via its
own `ChangeNotifierProvider` sidesteps that: each screen builds its own
provider scoped to what it needs (`RoutinesProvider` for the list,
`RoutineDetailProvider` for one routine), and reloads from the single source
of truth (SQLite) whenever it regains focus (see how `ManageRoutineScreen`'s
caller calls `provider.load()` after popping back, in
`lib/screens/routine_screen.dart`).

## Where Flask readers will feel at home

This whole layer plays the role Flask's request/response cycle plays on the
server: a `ChangeNotifier` is stateful and long-lived (like an in-memory
cache), while the repositories underneath it are stateless data access,
identical in spirit to `repositories/routines.py`. The difference is that a
mobile app has no "new request" boundary to reset state between — the
provider stays alive as long as its screen is on the navigation stack, which
is why `dispose()` (closing timers, releasing controllers) matters so much
more here than it would in a web request handler.

## Try this

In `lib/state/routines_provider.dart`, add a `print('routines reloaded:
${_routines.length}')` right after `notifyListeners()` in `load()`. Run the
app, add and delete a routine, and watch the terminal to see exactly when
the provider decides to reload and notify.
