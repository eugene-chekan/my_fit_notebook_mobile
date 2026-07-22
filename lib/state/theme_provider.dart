import 'package:flutter/foundation.dart';

import '../data/models/profile.dart';
import '../data/repositories/profile_repository.dart';
import '../theme/notebook_theme.dart';

/// App-wide notebook-theme state, held above [MaterialApp] so switching it
/// repaints the whole app. Persists the choice on the profile row (mirroring
/// [LocaleProvider] / the `language` column). Resolved before the first frame
/// so there's no flash of the default theme.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({ProfileRepository? repository})
    : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;

  ThemeId _themeId = ThemeId.paper;
  ThemeId get themeId => _themeId;

  /// Per-theme paper-style overrides (ThemeId.name → 'ruled'/'grid'). Absent =
  /// use the theme's built-in default.
  Map<String, String> _paperStyles = const {};

  Future<void> load() async {
    final profile = await _repository.getProfile();
    _themeId = ThemeId.fromName(profile.theme);
    _paperStyles = profile.paperStyles;
    notifyListeners();
  }

  Future<void> setTheme(ThemeId id) async {
    if (_themeId == id) return;
    _themeId = id;
    notifyListeners();
    await _repository.setTheme(id.name);
  }

  /// Whether [id] draws a graph grid — the user's override if set, else the
  /// theme's built-in default (only Carbon defaults to a grid).
  bool graphGridFor(ThemeId id) {
    final override = _paperStyles[id.name];
    if (override != null) return override == PaperStyle.grid;
    return NotebookTheme.paletteFor(id).graphGrid;
  }

  /// The effective paper style for [id] as a [PaperStyle] value.
  String paperStyleFor(ThemeId id) =>
      graphGridFor(id) ? PaperStyle.grid : PaperStyle.ruled;

  Future<void> setPaperStyle(ThemeId id, String style) async {
    if (paperStyleFor(id) == style) return;
    _paperStyles = {..._paperStyles, id.name: style};
    notifyListeners();
    await _repository.setPaperStyle(id.name, style);
  }
}
