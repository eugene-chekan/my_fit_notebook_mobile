import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fit_notebook_mobile/data/models/profile.dart';
import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';

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

    test('only carbon uses the graph grid', () {
      for (final id in ThemeId.values) {
        expect(
          NotebookTheme.paletteFor(id).graphGrid,
          id == ThemeId.carbon,
          reason: '$id graphGrid',
        );
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

  group('Profile.decodePaperStyles', () {
    test('parses a valid JSON map', () {
      final map = Profile.decodePaperStyles('{"carbon":"ruled","paper":"grid"}');
      expect(map, {'carbon': 'ruled', 'paper': 'grid'});
    });

    test('tolerates null, empty, and malformed input', () {
      expect(Profile.decodePaperStyles(null), isEmpty);
      expect(Profile.decodePaperStyles(''), isEmpty);
      expect(Profile.decodePaperStyles('not json'), isEmpty);
      expect(Profile.decodePaperStyles('[1,2,3]'), isEmpty);
    });
  });
}
