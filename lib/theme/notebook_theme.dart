/// The notebook design language — a ruled-paper grid, Caveat hand, and
/// hand-drawn shapes — expressed as a set of *runtime-switchable* palettes.
///
/// Colour used to be compile-time `const` (a single hardcoded "yellow paper +
/// blue ink" scheme). It now lives in [NotebookPalette], a
/// [ThemeExtension] carried on [ThemeData], so a widget reads its colours from
/// `context.notebook` and the whole app can repaint when the palette changes.
library;

import 'package:flutter/material.dart';

/// The selectable themes: the light default ([ThemeId.paper]) and four dark
/// "ink-on-paper" grounds — [blueprint], [chalkboard], [lamp], and [carbon]
/// (the last swaps the ruled lines for an engineering graph grid).
enum ThemeId {
  paper,
  blueprint,
  chalkboard,
  lamp,
  carbon;

  /// Parses a persisted id, falling back to [paper] for anything unknown
  /// (including the not-yet-shipped follow-up themes).
  static ThemeId fromName(String? name) {
    return ThemeId.values.firstWhere(
      (id) => id.name == name,
      orElse: () => ThemeId.paper,
    );
  }
}

/// The runtime colour tokens of a notebook theme. One `const` instance exists
/// per [ThemeId]; the active one is registered in [ThemeData.extensions] and
/// read via `context.notebook`.
@immutable
class NotebookPalette extends ThemeExtension<NotebookPalette> {
  const NotebookPalette({
    required this.bg,
    required this.ink,
    required this.sec,
    required this.accent,
    required this.ruleTint,
    required this.marginRule,
    required this.trainedFill,
    required this.cardFill,
    required this.shadow,
    required this.desk,
    required this.vignette,
    required this.isDark,
    this.graphGrid = false,
  });

  /// Page background — the paper (or ink-on-paper ground for dark themes).
  final Color bg;

  /// Primary ink: body text, borders, headings.
  final Color ink;

  /// Secondary/muted ink: labels, hints, inactive toggles.
  final Color sec;

  /// The single accent (brick). Doubles as the danger/error colour and is
  /// used *sparingly* — streak, calendar today ring, deltas, margin rule,
  /// the done checkbox.
  final Color accent;

  /// The faint horizontal hairlines of the ruled grid.
  final Color ruleTint;

  /// The vertical margin rule (painted as a brick double line).
  final Color marginRule;

  /// Fill for "trained"/active surfaces (calendar cells, chart bars).
  final Color trainedFill;

  /// Translucent card wash over the page.
  final Color cardFill;

  /// Drop-shadow colour under torn strips / floating panels.
  final Color shadow;

  /// The desk tone behind the page (outer background).
  final Color desk;

  /// Radial overlay tint at the page edges — a warm dab on light themes,
  /// a darkening on dark ones.
  final Color vignette;

  /// Whether this is a dark ground (drives [Brightness] and the vignette).
  final bool isDark;

  /// Reserved for the follow-up Carbon theme's 28px graph grid. Unused this
  /// pass; defaults false.
  final bool graphGrid;

  @override
  NotebookPalette copyWith({
    Color? bg,
    Color? ink,
    Color? sec,
    Color? accent,
    Color? ruleTint,
    Color? marginRule,
    Color? trainedFill,
    Color? cardFill,
    Color? shadow,
    Color? desk,
    Color? vignette,
    bool? isDark,
    bool? graphGrid,
  }) {
    return NotebookPalette(
      bg: bg ?? this.bg,
      ink: ink ?? this.ink,
      sec: sec ?? this.sec,
      accent: accent ?? this.accent,
      ruleTint: ruleTint ?? this.ruleTint,
      marginRule: marginRule ?? this.marginRule,
      trainedFill: trainedFill ?? this.trainedFill,
      cardFill: cardFill ?? this.cardFill,
      shadow: shadow ?? this.shadow,
      desk: desk ?? this.desk,
      vignette: vignette ?? this.vignette,
      isDark: isDark ?? this.isDark,
      graphGrid: graphGrid ?? this.graphGrid,
    );
  }

  @override
  NotebookPalette lerp(ThemeExtension<NotebookPalette>? other, double t) {
    if (other is! NotebookPalette) return this;
    return NotebookPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      sec: Color.lerp(sec, other.sec, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      ruleTint: Color.lerp(ruleTint, other.ruleTint, t)!,
      marginRule: Color.lerp(marginRule, other.marginRule, t)!,
      trainedFill: Color.lerp(trainedFill, other.trainedFill, t)!,
      cardFill: Color.lerp(cardFill, other.cardFill, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      desk: Color.lerp(desk, other.desk, t)!,
      vignette: Color.lerp(vignette, other.vignette, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
      graphGrid: t < 0.5 ? graphGrid : other.graphGrid,
    );
  }
}

/// Static registry of the built palettes and their [ThemeData] wrappers.
class NotebookTheme {
  NotebookTheme._();

  /// Light default — the refreshed "Accented Paper": warmer paper, a tighter
  /// brick promoted to a real (sparing) accent, and a brick double margin rule.
  static const paper = NotebookPalette(
    bg: Color(0xFFF8F2D6),
    ink: Color(0xFF1A3A6E),
    sec: Color(0xFF2C5282),
    accent: Color(0xFF8E352C),
    ruleTint: Color(0x211A3A6E), // rgba(26,58,110,.13)
    marginRule: Color(0xFF8E352C),
    trainedFill: Color(0x1F1A3A6E), // rgba(26,58,110,.12)
    cardFill: Color(0x26FFFFFF), // rgba(255,255,255,.15)
    shadow: Color(0x2E1A3A6E), // rgba(26,58,110,.18)
    desk: Color(0xFFC4B896),
    vignette: Color(0x1C5A441A), // rgba(90,68,26,.11)
    isDark: false,
  );

  /// Dark "blueprint" ground — cool ink lines on deep navy, brick accent,
  /// with rule/fill/vignette derived from ink & accent at low alpha.
  static const blueprint = NotebookPalette(
    bg: Color(0xFF1F2535),
    ink: Color(0xFFB6C3CC),
    sec: Color(0xFF7996AB),
    accent: Color(0xFFC24A3E),
    ruleTint: Color(0x1FB6C3CC), // ink @ ~.12
    marginRule: Color(0xFFC24A3E),
    trainedFill: Color(0x24B6C3CC), // ink @ ~.14
    cardFill: Color(0x0FFFFFFF), // white @ ~.06
    shadow: Color(0x66000000),
    desk: Color(0xFF141926),
    vignette: Color(0x66131722), // deep navy darkening at edges
    isDark: true,
  );

  /// Dark "chalkboard" ground — chalky grey on warm slate, a coral accent.
  static const chalkboard = NotebookPalette(
    bg: Color(0xFF1A1C18),
    ink: Color(0xFFC3C0B5),
    sec: Color(0xFF8C8A7B),
    accent: Color(0xFFD8776A),
    ruleTint: Color(0x1FC3C0B5), // ink @ ~.12
    marginRule: Color(0xFFD8776A),
    trainedFill: Color(0x24C3C0B5), // ink @ ~.14
    cardFill: Color(0x0FFFFFFF), // white @ ~.06
    shadow: Color(0x66000000),
    desk: Color(0xFF121410),
    vignette: Color(0x66121410), // slate darkening at edges
    isDark: true,
  );

  /// Dark "aged lamp" ground — warm sepia ink on deep brown, amber accent,
  /// like a page under lamplight.
  static const lamp = NotebookPalette(
    bg: Color(0xFF19150E),
    ink: Color(0xFFC3BAA3),
    sec: Color(0xFF927F5E),
    accent: Color(0xFFCE7A5A),
    ruleTint: Color(0x1FC3BAA3), // ink @ ~.12
    marginRule: Color(0xFFCE7A5A),
    trainedFill: Color(0x24C3BAA3), // ink @ ~.14
    cardFill: Color(0x0FFFFFFF), // white @ ~.06
    shadow: Color(0x66000000),
    desk: Color(0xFF120F08),
    vignette: Color(0x66120F08), // sepia darkening at edges
    isDark: true,
  );

  /// Dark "carbon" ground — cool grey on charcoal with a brick accent, drawn
  /// on a 28px engineering graph grid instead of ruled lines.
  static const carbon = NotebookPalette(
    bg: Color(0xFF202329),
    ink: Color(0xFF95999F),
    sec: Color(0xFF626A74),
    accent: Color(0xFFC24A3E),
    ruleTint: Color(0x1F95999F), // ink @ ~.12
    marginRule: Color(0xFFC24A3E),
    trainedFill: Color(0x2495999F), // ink @ ~.14
    cardFill: Color(0x0FFFFFFF), // white @ ~.06
    shadow: Color(0x66000000),
    desk: Color(0xFF17191E),
    vignette: Color(0x66141619), // charcoal darkening at edges
    isDark: true,
    graphGrid: true,
  );

  static NotebookPalette paletteFor(ThemeId id) {
    switch (id) {
      case ThemeId.paper:
        return paper;
      case ThemeId.blueprint:
        return blueprint;
      case ThemeId.chalkboard:
        return chalkboard;
      case ThemeId.lamp:
        return lamp;
      case ThemeId.carbon:
        return carbon;
    }
  }

  /// Builds the [ThemeData] for [id], registering its [NotebookPalette] so
  /// widgets can read tokens via `context.notebook`.
  static ThemeData forId(ThemeId id) => _build(paletteFor(id));

  static ThemeData _build(NotebookPalette p) {
    final brightness = p.isDark ? Brightness.dark : Brightness.light;
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: p.bg,
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        primary: p.ink,
        secondary: p.sec,
        surface: p.bg,
        error: p.accent,
        tertiary: p.accent,
        onSurface: p.ink,
        onPrimary: p.bg,
      ),
      textTheme: _textTheme(base.textTheme, p.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        centerTitle: false,
      ),
      splashFactory: NoSplash.splashFactory,
      dividerColor: p.ink,
      extensions: [p],
    );
  }

  static TextTheme _textTheme(TextTheme base, Color ink) {
    return base
        .copyWith(
          titleLarge: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 21,
            fontWeight: FontWeight.w500,
            color: ink,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: ink,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
        )
        .apply(fontFamily: 'Caveat');
  }
}

/// The single lookup every widget uses: `context.notebook.ink`, etc.
extension NotebookX on BuildContext {
  NotebookPalette get notebook => Theme.of(this).extension<NotebookPalette>()!;
}
