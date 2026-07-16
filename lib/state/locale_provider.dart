import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../data/models/profile.dart';
import '../data/repositories/profile_repository.dart';

/// App-wide UI-language state, held above [MaterialApp] so changing it rebuilds
/// the whole app. Persists the choice on the profile row (the one preference
/// that can't be screen-local). `'system'` follows the device; `'en'`/`'ru'` pin it.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider({ProfileRepository? repository})
    : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;

  static const _supported = {AppLanguage.en, AppLanguage.ru};

  String _language = AppLanguage.system;
  String get language => _language;

  /// The locale for `MaterialApp.locale`: null when following the device (Flutter
  /// resolves it against `supportedLocales`), else the pinned choice.
  Locale? get locale {
    switch (_language) {
      case AppLanguage.en:
        return const Locale('en');
      case AppLanguage.ru:
        return const Locale('ru');
      default:
        return null;
    }
  }

  /// The language actually on screen (for the Profile toggle highlight): the
  /// explicit pick, or the device language resolved to a supported one (else en).
  String get effectiveLanguage {
    if (_supported.contains(_language)) return _language;
    final device = PlatformDispatcher.instance.locale.languageCode;
    return _supported.contains(device) ? device : AppLanguage.en;
  }

  Future<void> load() async {
    final profile = await _repository.getProfile();
    _language = profile.language;
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    await _repository.setLanguage(language);
  }
}
