# 07 — Theming and building your own widgets

This is the doc most directly about *why the app looks like the web app*.
The web version gets its look from `static/css/notebook.css` — custom
properties, a background gradient for ruled paper, elliptical
`border-radius` shorthand for the hand-drawn button shapes. Flutter has no
CSS, so every one of those effects had to be re-expressed as Dart code. This
doc walks through how.

## `ThemeData` — the app's one shared stylesheet

`lib/theme/notebook_theme.dart` builds a single `ThemeData` object, handed
to `MaterialApp` once in `lib/main.dart`:

```dart
MaterialApp(
  theme: NotebookTheme.light,
  home: const DashboardScreen(),
)
```

Every widget below `MaterialApp` can read this theme via
`Theme.of(context)` without it being passed down manually — this is
`InheritedWidget` at work again (see doc 03's mention of it), just
Flutter-provided instead of from the `provider` package. Centralizing colors
and fonts here is the direct equivalent of `:root { --ink: #1a3a6e; ... }`
in `notebook.css` — one place to change a color, and everything using the
theme picks it up.

`NotebookColors` (a class of `static const Color` fields, never
instantiated — note the private `NotebookColors._()` constructor that
exists purely to prevent anyone from writing `NotebookColors()`) is the
direct Dart port of the CSS custom properties:

```css
/* notebook.css */
--ink: #1a3a6e;
--paper: #f9f4d9;
```

```dart
// lib/theme/notebook_theme.dart
static const ink = Color(0xFF1A3A6E);
static const paper = Color(0xFFF9F4D9);
```

`Color(0xFFAARRGGBB)` — the `0xFF` prefix is full opacity (alpha channel);
`rgba(26, 58, 110, 0.12)` from the CSS becomes `Color(0x1F1A3A6E)`, where
`0x1F` (31/255 ≈ 12%) is that same alpha baked into the hex.

## `TextTheme` — replacing `font-family` + a dozen font-size rules

CSS sets `font-family: "Caveat", cursive` once on `body` and lets every
element inherit it. Flutter's `Text` widgets don't inherit a font by
default — instead, `_textTheme` in `notebook_theme.dart` predefines named
text styles (`titleLarge`, `bodyMedium`, ...) with `fontFamily: 'Caveat'`
baked in, and widgets ask for one by name via `Theme.of(context).textTheme`.
In practice, most widgets in this app just set `fontFamily: 'Caveat'`
directly on their own `TextStyle` rather than going through the theme's
named styles — a pragmatic shortcut for a small app, but the theme-based
approach is what you'd lean on more as the app grows, so you don't have to
repeat `fontFamily: 'Caveat'` in every single `Text`.

## Registering a custom font

Unlike CSS's `@font-face` + a URL, Flutter fonts are bundled into the app at
build time. Three things had to line up:

1. The `.ttf` file lives in `assets/fonts/Caveat.ttf`.
2. `pubspec.yaml` declares it under `flutter: fonts:`, mapping weights to
   that one file (it's a *variable* font — one file that can render multiple
   weights):

   ```yaml
   fonts:
     - family: Caveat
       fonts:
         - asset: assets/fonts/Caveat.ttf
           weight: 400
         - asset: assets/fonts/Caveat.ttf
           weight: 700
   ```
3. Any `TextStyle` refers to it by the family name string: `fontFamily:
   'Caveat'`.

If you ever add a new font, all three steps are required — a missing
`pubspec.yaml` entry is the most common reason "I added the file but it's
still showing the default font."

## `CustomPainter` — drawing the ruled paper lines by hand

CSS achieves the ruled-paper background with a repeating linear gradient —
there's no equivalent single Flutter property for "repeating horizontal
lines," so `lib/widgets/notebook_page.dart` draws them directly with a
`Canvas`:

```dart
class _RuledPaperPainter extends CustomPainter {
  static const lineSpacing = 27.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = NotebookColors.paper;
    canvas.drawRect(Offset.zero & size, paint);

    final linePaint = Paint()..color = NotebookColors.paperLine..strokeWidth = 1;
    for (double y = 4; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RuledPaperPainter oldDelegate) => false;
}
```

This is about as low-level as Flutter UI code gets: `Canvas` is a raw
drawing surface (fill a rect, stroke a line), the same primitive that
underlies every higher-level widget. `shouldRepaint` returning `false`
tells Flutter "my output never changes once drawn, don't bother re-running
`paint` on every rebuild" — a small performance detail worth knowing:
`CustomPainter`s decide for themselves when they need to redraw, unlike
regular widgets which redraw whenever `build` reruns.

`MarginNote`'s dashed border (`lib/widgets/notebook_card.dart` — since
removed once it turned out to be unused, but worth knowing the technique
exists) works the same way: Flutter's `Border` has no "dashed" style at
all, so a dashed line has to be manually chopped into short strokes with
gaps along a computed path.

## The elliptical `border-radius` trick

The CSS pen-stroke buttons use a shorthand most people have never
memorized:

```css
border-radius: 255px 25px 225px 25px / 25px 225px 25px 255px;
```

Read as two four-number lists separated by `/`: the first four are
horizontal radii for each corner (top-left, top-right, bottom-right,
bottom-left), the second four are vertical radii for the same corners in
the same order. Flutter's `BorderRadius.only` lets you set all four corners
independently too, using `Radius.elliptical(x, y)` for a non-circular
corner:

```dart
// lib/widgets/pen_button.dart
BorderRadius penBlobRadius() => const BorderRadius.only(
  topLeft: Radius.elliptical(255, 25),
  topRight: Radius.elliptical(25, 225),
  bottomRight: Radius.elliptical(225, 25),
  bottomLeft: Radius.elliptical(25, 255),
);
```

The numbers are absurdly large on purpose — both the CSS and the Flutter
renderer clamp oversized radii down to fit the element's actual size, which
is precisely what turns a normal rectangle into a wobbly, hand-drawn-looking
blob at button scale. Same trick, same numbers, two different rendering
engines.

## Composing widgets instead of subclassing

There's no `PenButton extends RoundedButton extends Button` hierarchy here.
`PenButton`, `PenButtonFilled`, and `PlayerButton` in
`lib/widgets/pen_button.dart` are three independent `StatelessWidget`s that
each build a standard Flutter button (`OutlinedButton`/`ElevatedButton`) and
override its `style` — reusing the shared `penBlobRadius()`/
`playerBlobRadius()` functions rather than a shared base class. See doc 02's
"composition, not inheritance" section for why this is the idiomatic
Flutter approach.

## Try this

In `lib/theme/notebook_theme.dart`, change `NotebookColors.ink` to a
different color and hot-reload. Because every screen reads its ink color
either from this constant directly or via the theme, you should see the
whole app's borders, text, and button outlines change color at once — a
quick way to confirm the "one place to change a color" design is actually
working.
