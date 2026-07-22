import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app_navigator.dart';
import 'l10n/app_localizations.dart';
import 'route_observer.dart';
import 'screens/dashboard_screen.dart';
import 'services/reminder_service.dart';
import 'services/workout_notification_service.dart';
import 'state/locale_provider.dart';
import 'state/theme_provider.dart';
import 'theme/notebook_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load intl date symbols (en + ru) so DateFormat renders localized names.
  await initializeDateFormatting();
  // Resolve the persisted language + theme before the first frame to avoid a
  // flash of the defaults.
  final localeProvider = LocaleProvider();
  await localeProvider.load();
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  // Wire up the workout notification channel, then re-arm (or clear) the
  // ongoing notification from the DB — covers a workout left running when the
  // app was killed.
  WorkoutNotificationService.instance.bootstrap();
  await WorkoutNotificationService.instance.resync();
  // (Re)schedule workout reminders from the DB.
  await ReminderService.instance.init();
  await ReminderService.instance.resync();
  runApp(MyFitNotebookApp(
    localeProvider: localeProvider,
    themeProvider: themeProvider,
  ));
  // Navigate to the routine if a tapped reminder launched the app.
  await ReminderService.instance.handleAppLaunch();
}

class MyFitNotebookApp extends StatelessWidget {
  const MyFitNotebookApp({
    super.key,
    required this.localeProvider,
    required this.themeProvider,
  });

  final LocaleProvider localeProvider;
  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, locale, theme, _) => MaterialApp(
          title: 'My Fit Notebook',
          debugShowCheckedModeBanner: false,
          theme: NotebookTheme.forId(theme.themeId, graphGrid: theme.graphGrid),
          navigatorKey: navigatorKey,
          navigatorObservers: [appRouteObserver],
          locale: locale.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}
