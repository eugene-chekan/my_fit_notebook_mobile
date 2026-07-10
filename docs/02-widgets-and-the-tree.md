# 02 — Widgets and the tree

## Everything is a widget

In web development, HTML gives you the structure and CSS gives you the
style, as two separate languages. In Flutter, there's no separate markup or
stylesheet — the UI is a tree of Dart objects called **widgets**, and each
widget's `build` method returns more widgets. `Container`, `Row`, `Text`,
`Padding`, `Scaffold`, even invisible layout helpers — all widgets, all the
way down.

Look at `NotebookHeader` (`lib/widgets/notebook_header.dart`):

```dart
class NotebookHeader extends StatelessWidget {
  const NotebookHeader({super.key, required this.title, this.leading, this.trailing});

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(/* ... */),
      child: Row(
        children: [
          ?leading,
          Expanded(child: Text(title, /* ... */)),
          ?trailing,
        ],
      ),
    );
  }
}
```

`build` doesn't draw anything itself — it describes a tree (`Container` →
`Row` → `Text` + two optional widgets) and hands that description back to
Flutter, which does the actual drawing. This is the same mental model as a
React or Vue component's `render`: **describe the UI as a function of the
current data, and let the framework figure out what changed.**

Because `Widget` is just a description, not a live UI object, widgets are
normally cheap to create and throw away. Flutter rebuilds parts of this tree
constantly (every `setState`, every `notifyListeners()`) and that's fine —
it's comparing descriptions, not touching real pixels every time.

## `StatelessWidget` vs `StatefulWidget`

- **`StatelessWidget`** — has no memory of its own. Given the same
  constructor arguments, `build` always produces the same tree.
  `NotebookHeader` above is one: pass it the same `title`, get the same
  output, every time.
- **`StatefulWidget`** — pairs with a `State` object that *does* have memory
  across rebuilds. `DashboardScreen` is one, because it needs to remember a
  `TextEditingController` for the "new routine" input across rebuilds:

```dart
// lib/screens/dashboard_screen.dart
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final RoutinesProvider _provider;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = RoutinesProvider()..load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  // ...
}
```

The rule of thumb: if a widget needs to remember something across rebuilds
that isn't just derived from its constructor arguments — a controller, a
subscription, a value the user is actively editing — it needs a `State`
object, so it's a `StatefulWidget`. Everything else should be a
`StatelessWidget`; it's simpler and easier to reason about.

### The lifecycle methods you'll actually use

- `initState()` — runs once, when the widget is first inserted into the
  tree. Good place to kick off a `load()` call, as above.
- `dispose()` — runs once, when the widget is removed for good. Anything you
  opened in `initState` that needs closing (controllers, timers, streams)
  gets closed here. `RoutineDetailProvider.dispose()` cancels its `Timer` for
  exactly this reason.
- `build(context)` — runs every time Flutter thinks this widget might need
  to look different. Can run many times; keep it fast and free of side
  effects (no database calls directly inside `build`).

## `BuildContext`

Every `build` method receives a `BuildContext context` — a handle to *where
this widget sits in the tree*. It's how a widget finds things that were set
up above it: the current theme, the nearest `Navigator`, the nearest
`Provider`. You'll see calls like:

```dart
Theme.of(context)                 // the ThemeData set up in main.dart
Navigator.of(context).push(...)   // the navigator managing this screen
context.watch<RoutinesProvider>() // the nearest RoutinesProvider above this widget
```

All of these walk *up* the tree from the widget's position looking for the
nearest ancestor of the requested type. That's why a `BuildContext` from one
widget can't be reused inside a different widget lower or sideways in the
tree — it only knows about its own position.

## Composition, not inheritance

Flutter doesn't have a `RoutineCardWithDeleteButton` subclass of some base
`Card` widget. Instead you compose small widgets together:
`NotebookPage` wraps a `CustomPaint` wraps a `Padding` wraps your content.
When you want a new look, you build a new small widget and combine it with
existing ones, rather than extending a big class hierarchy. `PenButton`,
`PlayerButton`, and `PenButtonFilled` in `lib/widgets/pen_button.dart` are
three separate small widgets sharing a helper function
(`penBlobRadius()`) rather than one configurable mega-widget — composition
over configuration is the idiomatic Flutter way.

## `const` and why it matters

```dart
const SizedBox(height: 10)
```

`const` here does two things: it tells Dart this value is fixed at compile
time, and it lets Flutter skip rebuilding that particular widget instance
entirely when its parent rebuilds — Flutter just reuses the exact same
object. Sprinkle `const` on any widget whose constructor arguments are all
themselves constants (numbers, strings, other `const` widgets). `flutter
analyze` will actually suggest adding it (the `prefer_const_constructors`
lint) where you forgot.

## Try this

Open `lib/widgets/pen_button.dart`, change `fontSize: small ? 17 : 20` to
some other numbers, run `flutter run`, and press `r` in the terminal for hot
reload. Watch the button resize without the app restarting or losing its
current screen/state — that's Flutter re-running `build` on the existing
widget tree with your new source, not relaunching the app.
