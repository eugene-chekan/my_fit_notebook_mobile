# Learning Flutter with this codebase

This folder is a companion course to the app in `lib/`. Each file explains a
chunk of Dart/Flutter theory and immediately points at the real code in this
repo that uses it, so you're never learning an abstract example — you're
learning the thing three directories away from the doc.

You don't need to read these front-to-back before touching code. The
suggested order below builds concepts on top of each other, but if you're
about to change a specific screen, jump straight to the relevant doc instead.

## Reading order

1. **[01-dart-fundamentals.md](01-dart-fundamentals.md)** — the language
   itself: null safety, classes, `async`/`await`, `Future`. Read this first if
   you've never written Dart.
2. **[02-widgets-and-the-tree.md](02-widgets-and-the-tree.md)** — what a
   "widget" actually is, `StatelessWidget` vs `StatefulWidget`, `BuildContext`,
   why Flutter rebuilds what it rebuilds.
3. **[03-state-management.md](03-state-management.md)** — `setState`,
   `ChangeNotifier`, and the `provider` package this app uses to share state
   between screens.
4. **[04-app-architecture.md](04-app-architecture.md)** — how `lib/` is
   organized (models → repositories → services → state → screens) and why,
   with a direct comparison to the Flask app's `repositories/`/`services/`/
   `routes/` split.
5. **[05-navigation.md](05-navigation.md)** — how screens push/pop, and how
   data flows to and back from a pushed screen.
6. **[06-local-persistence.md](06-local-persistence.md)** — SQLite on-device,
   the `sqflite` package, and why everything touching the database is `async`.
7. **[07-theming-and-custom-widgets.md](07-theming-and-custom-widgets.md)** —
   `ThemeData`, building your own reusable widgets, `CustomPainter`, and how
   the "ruled paper" background and pen-stroke buttons are actually drawn.
8. **[08-tooling-and-testing.md](08-tooling-and-testing.md)** — `pubspec.yaml`,
   `flutter analyze`, `flutter test`, hot reload vs hot restart, and the
   day-to-day commands you'll run.

## How to actually learn this

Reading is passive. For each doc, the fastest way to make it stick is:

1. Open the real file it points to.
2. Change one small thing (a color, a string, a number).
3. Run `flutter run` and watch hot reload apply it in under a second.
4. Break something on purpose, read the error, fix it.

Flutter's error messages and `flutter analyze` are unusually good teachers —
they tell you almost exactly what's wrong and where.
