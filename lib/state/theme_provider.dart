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

  /// Global paper style (ruled/grid), applied to every theme.
  String _paperStyle = PaperStyle.ruled;
  String get paperStyle => _paperStyle;

  /// Whether the app draws a graph grid instead of horizontal ruling.
  bool get graphGrid => _paperStyle == PaperStyle.grid;

  Future<void> load() async {
    final profile = await _repository.getProfile();
    _themeId = ThemeId.fromName(profile.theme);
    _paperStyle = profile.paperStyle;
    notifyListeners();
  }

  Future<void> setTheme(ThemeId id) async {
    if (_themeId == id) return;
    _themeId = id;
    notifyListeners();
    await _repository.setTheme(id.name);
  }

  Future<void> setPaperStyle(String style) async {
    if (_paperStyle == style) return;
    _paperStyle = style;
    notifyListeners();
    await _repository.setPaperStyle(style);
  }
}
