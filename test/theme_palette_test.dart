import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fit_notebook_mobile/data/models/profile.dart';
import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('NotebookTheme', () {
    test('forId resolves a NotebookPalette for every ThemeId', () {
      for (final id in ThemeId.values) {
        final theme = NotebookTheme.forId(id);
        final palette = theme.extension<NotebookPalette>();
        expect(palette, isNotNull, reason: 'missing palette for $id');
      }
    });

    test('paletteFor matches the palette registered on forId', () {
      for (final id in ThemeId.values) {
        final registered = NotebookTheme.forId(id).extension<NotebookPalette>();
        expect(registered, same(NotebookTheme.paletteFor(id)));
      }
    });

    test('paper is the default and is light', () {
      expect(ThemeId.fromName(null), ThemeId.paper);
      expect(ThemeId.fromName('nonsense'), ThemeId.paper);
      expect(NotebookTheme.paper.isDark, isFalse);
      expect(NotebookTheme.forId(ThemeId.paper).brightness, Brightness.light);
    });

    test('blueprint is dark', () {
      expect(NotebookTheme.blueprint.isDark, isTrue);
      expect(NotebookTheme.forId(ThemeId.blueprint).brightness, Brightness.dark);
    });

    test('all four dark grounds are dark', () {
      for (final id in [
        ThemeId.blueprint,
        ThemeId.chalkboard,
        ThemeId.lamp,
        ThemeId.carbon,
      ]) {
        expect(NotebookTheme.paletteFor(id).isDark, isTrue, reason: '$id');
      }
    });

    test('all three light grounds are light', () {
      for (final id in [ThemeId.paper, ThemeId.pencil, ThemeId.manuscript]) {
        expect(NotebookTheme.paletteFor(id).isDark, isFalse, reason: '$id');
        expect(
          NotebookTheme.forId(id).brightness,
          Brightness.light,
          reason: '$id',
        );
      }
    });

    test('every ink and secondary ink clears the contrast floor', () {
      // Caveat is a light handwriting face, so muted text goes illegible
      // earlier than a normal UI font would — sec is the pinch point, and on
      // the toned light grounds in particular.
      for (final id in ThemeId.values) {
        final p = NotebookTheme.paletteFor(id);
        expect(_contrast(p.ink, p.bg), greaterThan(4.5), reason: '$id ink');
        expect(_contrast(p.sec, p.bg), greaterThan(4.5), reason: '$id sec');
      }
    });

    test('the accent separates from both the page and its ink', () {
      // The accent carries the streak, the today ring, deltas and delete. On
      // manuscript it has to fight a warm brown ink, which is why it is the
      // most saturated red in the family rather than the most muted.
      for (final id in ThemeId.values) {
        final p = NotebookTheme.paletteFor(id);
        expect(_contrast(p.accent, p.bg), greaterThan(3.0), reason: '$id page');
        expect(
          (p.accent.computeLuminance() - p.ink.computeLuminance()).abs(),
          greaterThan(0.03),
          reason: '$id ink',
        );
      }
    });

    test('the light grounds are told apart by their paper, not just by name',
        () {
      // Three light swatches sit side by side in Settings at 52×38pt; if two
      // share a cast the row stops reading as a choice.
      // Separation can come from either axis: paper and manuscript are both
      // warm (0.133 vs 0.145 red-over-blue) and tell themselves apart by depth
      // instead, while pencil is the one that differs in cast.
      final papers = [
        ('paper', NotebookTheme.paper.bg),
        ('pencil', NotebookTheme.pencil.bg),
        ('manuscript', NotebookTheme.manuscript.bg),
      ];
      for (var i = 0; i < papers.length; i++) {
        for (var j = i + 1; j < papers.length; j++) {
          final (aName, a) = papers[i];
          final (bName, b) = papers[j];
          final warmth = ((a.r - a.b) - (b.r - b.b)).abs();
          final depth =
              (a.computeLuminance() - b.computeLuminance()).abs();
          expect(
            warmth > 0.05 || depth > 0.05,
            isTrue,
            reason: '$aName and $bName are too close to tell apart',
          );
        }
      }
    });

    test('pencil reads as graphite: softer than ink, and colourless', () {
      final p = NotebookTheme.pencil;
      // Graphite is never black — it lands below the contrast a real ink hits,
      // which is the whole reason the page reads as pencil.
      expect(
        _contrast(p.ink, p.bg),
        lessThan(
          _contrast(NotebookTheme.manuscript.ink, NotebookTheme.manuscript.bg),
        ),
      );
      // …and it carries no hue of its own; the col-erase accent does that.
      expect((p.ink.r - p.ink.b).abs(), lessThan(0.05));
      expect(p.accent.r, greaterThan(p.accent.b));
    });

    test('no palette hardcodes a graph grid (paper style is global)', () {
      for (final id in ThemeId.values) {
        expect(NotebookTheme.paletteFor(id).graphGrid, isFalse, reason: '$id');
      }
    });

    test('fromName round-trips every ThemeId name', () {
      for (final id in ThemeId.values) {
        expect(ThemeId.fromName(id.name), id);
      }
    });

    test('forId honours a graphGrid override', () {
      // Force a ruled Carbon and a gridded Paper.
      final ruledCarbon =
          NotebookTheme.forId(ThemeId.carbon, graphGrid: false)
              .extension<NotebookPalette>()!;
      final gridPaper = NotebookTheme.forId(ThemeId.paper, graphGrid: true)
          .extension<NotebookPalette>()!;
      expect(ruledCarbon.graphGrid, isFalse);
      expect(gridPaper.graphGrid, isTrue);
      // Overriding grid alone keeps every other token intact.
      expect(gridPaper.bg, NotebookTheme.paper.bg);
    });
  });

  group('Profile paper style (global)', () {
    test('decodes the stored grid value', () {
      expect(Profile.decodePaperStyle('{"style":"grid"}'), PaperStyle.grid);
    });

    test('defaults to ruled for null, empty, malformed, or unset', () {
      expect(Profile.decodePaperStyle(null), PaperStyle.ruled);
      expect(Profile.decodePaperStyle(''), PaperStyle.ruled);
      expect(Profile.decodePaperStyle('{}'), PaperStyle.ruled);
      expect(Profile.decodePaperStyle('not json'), PaperStyle.ruled);
      expect(Profile.decodePaperStyle('{"style":"ruled"}'), PaperStyle.ruled);
    });

    test('encode/decode round-trips', () {
      for (final style in [PaperStyle.ruled, PaperStyle.grid]) {
        expect(Profile.decodePaperStyle(Profile.encodePaperStyle(style)), style);
      }
    });
  });
}
