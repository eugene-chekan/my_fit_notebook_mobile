import 'package:flutter/foundation.dart';

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

  Future<void> load() async {
    final profile = await _repository.getProfile();
    _themeId = ThemeId.fromName(profile.theme);
    notifyListeners();
  }

  Future<void> setTheme(ThemeId id) async {
    if (_themeId == id) return;
    _themeId = id;
    notifyListeners();
    await _repository.setTheme(id.name);
  }
}
