import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/profile.dart';
import '../data/repositories/profile_repository.dart';
import '../l10n/app_localizations.dart';
import '../state/locale_provider.dart';
import '../state/theme_provider.dart';
import '../theme/notebook_theme.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';

/// The single home for app *preferences* — Theme, Language, and Units — kept
/// out of Profile (which holds personal data only). Theme and Language rebuild
/// the whole app live via their root providers; Units persists to the profile
/// row and is reflected by Profile/Stats the next time they load.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repository = ProfileRepository();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _units = Units.metric;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final profile = await _repository.getProfile();
    if (mounted) setState(() => _units = profile.units);
  }

  Future<void> _setUnits(String next) async {
    if (_units == next) return;
    setState(() => _units = next);
    await _repository.setUnits(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: const NotebookDrawer(),
      body: SafeArea(
        child: NotebookPage(
          marginChild: GlyphButton(
            glyph: '≡',
            size: 26,
            semanticLabel: t.menu,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NotebookHeader(title: t.navSettings, leading: const BackGlyph()),
              const SizedBox(height: 12),
              _themeLine(),
              const SizedBox(height: 14),
              _languageLine(),
              const SizedBox(height: 14),
              _unitsLine(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Theme -----------------------------------------------------------

  Widget _themeLine() {
    final t = AppLocalizations.of(context);
    final current = context.watch<ThemeProvider>().themeId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(t.themeLabel),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final id in ThemeId.values)
              _ThemeSwatch(
                id: id,
                label: _themeName(t, id),
                active: id == current,
                onTap: () => context.read<ThemeProvider>().setTheme(id),
              ),
          ],
        ),
      ],
    );
  }

  String _themeName(AppLocalizations t, ThemeId id) {
    switch (id) {
      case ThemeId.paper:
        return t.themePaper;
      case ThemeId.blueprint:
        return t.themeBlueprint;
    }
  }

  // --- Language --------------------------------------------------------

  Widget _languageLine() {
    final t = AppLocalizations.of(context);
    final active = context.watch<LocaleProvider>().effectiveLanguage;
    final enActive = active == AppLanguage.en;
    TextStyle style(bool on) => TextStyle(
      fontFamily: 'Caveat',
      fontSize: 20,
      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
      color: on ? context.notebook.ink : context.notebook.sec,
    );
    return Row(
      children: [
        _label(t.languageLabel),
        const SizedBox(width: 8),
        InkWell(
          onTap: enActive
              ? null
              : () => context.read<LocaleProvider>().setLanguage(AppLanguage.en),
          child: Text('EN', style: style(enActive)),
        ),
        Text('   /   ', style: style(false)),
        InkWell(
          onTap: enActive
              ? () => context.read<LocaleProvider>().setLanguage(AppLanguage.ru)
              : null,
          child: Text('RU', style: style(!enActive)),
        ),
      ],
    );
  }

  // --- Units -----------------------------------------------------------

  Widget _unitsLine() {
    final t = AppLocalizations.of(context);
    final metricActive = _units == Units.metric;
    TextStyle style(bool active) => TextStyle(
      fontFamily: 'Caveat',
      fontSize: 20,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      color: active ? context.notebook.ink : context.notebook.sec,
    );
    return Row(
      children: [
        _label(t.unitsLabel),
        const SizedBox(width: 8),
        InkWell(
          onTap: metricActive ? null : () => _setUnits(Units.metric),
          child: Text('kg · cm', style: style(metricActive)),
        ),
        Text('   /   ', style: style(false)),
        InkWell(
          onTap: metricActive ? () => _setUnits(Units.imperial) : null,
          child: Text('lb · in', style: style(!metricActive)),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontFamily: 'Caveat',
      fontSize: 18,
      fontStyle: FontStyle.italic,
      color: context.notebook.sec,
    ),
  );
}

/// A notebook-cover swatch: the theme's own paper ground with a faint ink
/// rule and an accent dot, ringed in accent when it's the active theme. Draws
/// the *target* theme's colours (not the current one) so each preview reads true.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.id,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final ThemeId id;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = NotebookTheme.paletteFor(id);
    final ring = context.notebook.accent;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 38,
              decoration: BoxDecoration(
                color: p.bg,
                border: Border.all(
                  color: active ? ring : p.ink,
                  width: active ? 3 : 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 7,
                    right: 7,
                    top: 14,
                    child: Container(height: 1.5, color: p.ink.withValues(alpha: 0.5)),
                  ),
                  Positioned(
                    left: 7,
                    right: 18,
                    top: 21,
                    child: Container(height: 1.5, color: p.ink.withValues(alpha: 0.5)),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: p.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 16,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? context.notebook.ink : context.notebook.sec,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
