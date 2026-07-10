# 05 — Navigation

## The stack, not the URL bar

The web app navigates by URL: `routes/workout.py` maps
`/routines/<id>` to a view function, and the browser's back button walks
browser history. Flutter (in this app) uses the simpler **imperative**
model: a stack of screens, where "navigating" means pushing a new screen on
top, and "going back" means popping it off. There's no URL, no route table
to register up front — you literally construct the screen widget you want
and hand it to the `Navigator`.

```dart
// lib/screens/dashboard_screen.dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => RoutineScreen(routineId: routine.id)),
);
```

Read this as: "build a `RoutineScreen`, wrap it in a standard
platform-appropriate transition (`MaterialPageRoute` — slide-in on Android,
matches Cupertino conventions automatically on iOS), and push it onto this
navigator's stack." The `builder` is a function rather than a plain widget
because the `Navigator` needs to build it lazily, with its *own*
`BuildContext`, at the moment it actually animates onto screen.

Going back is just:

```dart
Navigator.of(context).pop();
```

which is exactly what the back arrow `IconButton` in `NotebookHeader` calls,
and what the platform's OS back button/gesture does automatically for the
top-most screen.

## Passing data down: constructor arguments

There's no route table, so there's no route *parameters* either — you pass
data the same way you'd pass data to any other widget: constructor
arguments.

```dart
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key, required this.routineId});
  final int routineId;
  // ...
}
```

`routineId` is all `RoutineScreen` needs; it loads everything else itself
via `RoutineDetailProvider(widget.routineId)..load()` in `initState`. This
mirrors Flask's `routine_detail(routine_id)` view function taking
`routine_id` from the URL and doing its own lookup — the difference is
purely mechanical (constructor argument vs. URL segment), not conceptual.

## Getting data back: `await`ing the push

`Navigator.push` returns a `Future` that resolves with whatever value the
pushed screen `pop`s with (or `null`/nothing, if it just pops normally). This
app uses that to know when to refresh after visiting the Manage screen:

```dart
// lib/screens/routine_screen.dart
trailing: IconButton(
  onPressed: () async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ManageRoutineScreen(routineId: widget.routineId)),
    );
    provider.load();   // runs once ManageRoutineScreen has been popped
  },
),
```

The `await` here means "pause this callback until the pushed screen is gone
(popped), then reload." It doesn't matter *why* the user left Manage
(explicit back button, Android back gesture, anything) — as soon as it's
off the stack, this line runs. `ManageRoutineScreen` doesn't need to pass
anything back explicitly; the pattern here is "reload from the database
after coming back," not "receive a specific returned value."

Where a screen *does* need to hand back a concrete value, `pop` takes an
argument and the caller's `await` captures it — see how
`ManageRoutineScreen._renameExercise` uses a dialog this way:

```dart
final name = await showDialog<String>(
  context: context,
  builder: (context) => AlertDialog(
    // ...
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
    ],
  ),
);
if (name != null && name.trim().isNotEmpty) {
  await _provider.renameExercise(exercise.id, name);
}
```

`showDialog<String>` is really the same push/pop mechanism as
`Navigator.push`, just for a modal overlay instead of a full screen — it
returns a `Future<String?>` that resolves with whatever `Navigator.pop(context,
value)` was called with, or `null` if the dialog was dismissed by tapping
outside it.

## Drawers, bottom sheets, dialogs — all the same idea

`Scaffold.of(context).openDrawer()` (dashboard's hamburger menu),
`showModalBottomSheet` (calendar's tap-a-day routine list), and `showDialog`
(the finish-workout stats popup, the delete-routine confirmation) are all
variations on "temporarily show something on top of the current screen, and
optionally get a value back when it closes." Once `Navigator.push`/`pop`
clicks, these all feel like the same tool with a different presentation.

## Why no named routes / router package here

Bigger Flutter apps often switch to declarative routing (the `Navigator 2.0`
API, or a package like `go_router`) so that deep links, web URLs, and
back-button behavior can all be driven by one source of truth. That's
overkill for an app with four screens and no deep-linking requirement — the
imperative `push`/`pop` shown here is simpler to read and is exactly what
Flutter's own docs recommend for apps this size. If this app ever grows deep
links (e.g. a push notification opening a specific routine) or a
tab-based navigation shell, that's the point to revisit this decision.
