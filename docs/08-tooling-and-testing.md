# 08 — Tooling and testing

## `pubspec.yaml` — Flutter's `pyproject.toml`

Every Flutter project has a `pubspec.yaml` at its root — the direct
equivalent of the web app's `pyproject.toml`. It declares the package name,
the Dart SDK version constraint, dependencies, and (Flutter-specific) assets
and fonts:

```yaml
environment:
  sdk: ^3.12.2

dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.4.3
  provider: ^6.1.5+1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

`dependencies` ships inside the built app; `dev_dependencies` (tests, lint
rules) never does — same split as `pyproject.toml`'s main vs. dev
dependency groups.

`pubspec.lock` is the equivalent of `uv.lock`: exact resolved versions,
committed to the repo so every machine building this app gets identical
dependency versions.

### The commands you'll actually run

```bash
flutter pub get              # install dependencies from pubspec.yaml (like `uv sync`)
flutter pub add <package>    # add a new dependency and fetch it in one step
flutter pub remove <package> # remove one
flutter analyze              # static analysis — the Dart/Flutter equivalent of `ruff check`
flutter test                 # run everything in test/
flutter run                  # launch on a connected device/emulator, with hot reload
```

## `analysis_options.yaml` — the linter config

This is `ruff`'s config file, Dart-flavored. It's set up (by `flutter
create`, unmodified here) to include `package:flutter_lints/flutter.yaml`,
a curated rule set the Flutter team maintains. `flutter analyze` is what
enforces it — it's worth running before every commit, the same habit as
`ruff check .` on the Python side. This project currently analyzes clean
(zero issues); keep it that way as you add code, since a growing pile of
ignored lints is much harder to clean up later than fixing them as they
appear.

## Hot reload vs. hot restart vs. a full rebuild

This is the single biggest day-to-day productivity difference from web
development with a template-based backend (where "reload" just means
refreshing the browser):

- **Hot reload** (press `r` in the terminal running `flutter run`, or your
  IDE's lightning-bolt button) — injects your changed Dart code into the
  *already-running* app, and re-runs `build` on the existing widget tree.
  State is preserved: if you're mid-workout on the routine screen, you stay
  there. This works for almost all UI/logic changes and takes well under a
  second.
- **Hot restart** (press `R`) — throws away all app state and reruns `main()`
  from scratch, but keeps the same compiled process, so it's still much
  faster than a full rebuild. Needed when you change something hot reload
  can't handle — most commonly, changing a `State` object's field
  declarations, or top-level/`static` initializers.
- **Full rebuild** (`flutter run` again, or stopping and restarting) —
  needed when you change native code (`android/`, `ios/`), add a new plugin
  dependency, or change `pubspec.yaml`'s assets/fonts.

If a hot reload doesn't seem to take effect, hot restart first before
assuming something is broken — it very often is just that category of
change.

## Widget tests

`test/widget_test.dart` is a small example of Flutter's widget testing
tool, `flutter_test`. Unlike a typical Python unit test that calls a
function and asserts on a return value, a widget test builds a *fake,
in-memory app* and interacts with it:

```dart
testWidgets('PenButton renders its label and responds to taps', (tester) async {
  var tapped = false;
  await tester.pumpWidget(
    MaterialApp(
      theme: NotebookTheme.light,
      home: Scaffold(body: PenButton(label: 'Start workout', onPressed: () => tapped = true)),
    ),
  );

  expect(find.text('Start workout'), findsOneWidget);

  await tester.tap(find.text('Start workout'));
  await tester.pump();

  expect(tapped, isTrue);
});
```

- `tester.pumpWidget(...)` — builds the given widget tree in a simulated
  environment (no real device needed, runs on your dev machine or CI).
- `find.text(...)` / `find.byIcon(...)` / `find.byType(...)` — locate
  widgets in that tree by what they show, similar in spirit to a
  browser-testing tool's element selectors.
- `tester.tap(...)` then `tester.pump()` — simulates a tap, then tells the
  test to process one more frame so any resulting `setState`/rebuild takes
  effect (widget tests don't run a real animation clock automatically; you
  drive frames explicitly).

### Why this project's test avoids the database

You'll notice the test only exercises `PenButton`, a pure UI widget with no
database access, rather than pumping the full `DashboardScreen`. That's
deliberate: `sqflite` talks to a real native SQLite library through a
platform channel, which doesn't exist in the plain widget-test environment
(there's no real Android/iOS runtime backing it). Widgets that touch the
database directly in `initState` — like every screen in this app — aren't
easily testable this way without extra setup (an in-memory fake database, or
the `sqflite_common_ffi` package configured for tests specifically). For
now, this app leans on `flutter analyze` catching type errors and a manual
run-on-device pass (see the project README) for anything database-backed;
if you want proper coverage there later, injecting a fake repository into
each provider (instead of always constructing the real one) is the
standard way to make that testable.

## `flutter doctor`

Run this any time something environment-related seems wrong (`flutter run`
can't find a device, a build fails mysteriously). It checks your Flutter
install, connected devices/emulators, and each platform's toolchain
(Android SDK, Xcode, etc.), and tells you exactly what's missing — the
Flutter equivalent of a `doctor`/`preflight` script, and usually the first
thing to run when debugging "why won't this build."
