import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'route_observer.dart';
import 'screens/dashboard_screen.dart';
import 'state/locale_provider.dart';
import 'theme/notebook_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load intl date symbols (en + ru) so DateFormat renders localized names.
  await initializeDateFormatting();
  // Resolve the persisted language before the first frame to avoid a flash.
  final localeProvider = LocaleProvider();
  await localeProvider.load();
  runApp(MyFitNotebookApp(localeProvider: localeProvider));
}

class MyFitNotebookApp extends StatelessWidget {
  const MyFitNotebookApp({super.key, required this.localeProvider});

  final LocaleProvider localeProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: localeProvider,
      child: Consumer<LocaleProvider>(
        builder: (context, provider, _) => MaterialApp(
          title: 'My Fit Notebook',
          debugShowCheckedModeBanner: false,
          theme: NotebookTheme.light,
          navigatorObservers: [appRouteObserver],
          locale: provider.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}
