import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/profile.dart';
import '../l10n/app_localizations.dart';
import '../screens/exercises_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/routines_screen.dart';
import '../screens/stats_screen.dart';
import '../state/locale_provider.dart';
import '../theme/notebook_theme.dart';
import 'notebook_page.dart';

/// The side menu, reachable from every screen. Self-contained — no
/// callbacks to wire up per screen. Each item pops the navigation stack
/// back to the dashboard (the app's single root route), then pushes the
/// chosen section, so the sidebar always jumps to a top-level destination
/// rather than stacking on top of wherever the user happened to be.
class NotebookDrawer extends StatelessWidget {
  const NotebookDrawer({super.key});

  void _go(BuildContext context, WidgetBuilder? builder) {
    final navigator = Navigator.of(context);
    Scaffold.of(context).closeDrawer();
    navigator.popUntil((route) => route.isFirst);
    if (builder != null) {
      navigator.push(MaterialPageRoute(builder: builder));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Drawer(
      backgroundColor: NotebookColors.paper,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: NotebookColors.ink, width: 2),
      ),
      child: CustomPaint(
        painter: const RuledPaperPainter(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(64, 4, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => _go(context, null),
                  child: Container(
                    height: 2 * kNotebookLine,
                    alignment: Alignment.bottomLeft,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: NotebookColors.ink, width: 2),
                      ),
                    ),
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      t.appName,
                      style: const TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: NotebookColors.ink,
                      ),
                    ),
                  ),
                ),
                _line(context, t.navRoutines, (_) => const RoutinesScreen()),
                _line(context, t.navExercises, (_) => const ExercisesScreen()),
                _line(context, t.navStats, (_) => const StatsScreen()),
                _line(context, t.navProfile, (_) => const ProfileScreen()),
                const Spacer(),
                _languageFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "language:  EN / RU" pinned to the drawer's foot — the active language in
  /// ink, tap to switch. Backed by the app-wide [LocaleProvider], so a tap
  /// re-localizes every screen (including the nav lines above) live, without
  /// leaving the menu. Language is app chrome, so it lives on the app's chrome.
  Widget _languageFooter(BuildContext context) {
    final t = AppLocalizations.of(context);
    final active = context.watch<LocaleProvider>().effectiveLanguage;
    final enActive = active == AppLanguage.en;
    TextStyle style(bool on) => TextStyle(
      fontFamily: 'Caveat',
      fontSize: 20,
      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
      color: on ? NotebookColors.ink : NotebookColors.inkSoft,
    );
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: NotebookColors.ink, width: 2)),
      ),
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(
            '${t.languageLabel}  ',
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 17,
              fontStyle: FontStyle.italic,
              color: NotebookColors.inkSoft,
            ),
          ),
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
      ),
    );
  }

  Widget _line(BuildContext context, String label, WidgetBuilder builder) {
    return SizedBox(
      height: kNotebookLine,
      child: InkWell(
        onTap: () => _go(context, builder),
        child: Container(
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: NotebookColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
