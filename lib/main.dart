import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'theme/notebook_theme.dart';

void main() {
  runApp(const MyFitNotebookApp());
}

class MyFitNotebookApp extends StatelessWidget {
  const MyFitNotebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Fit Notebook',
      debugShowCheckedModeBanner: false,
      theme: NotebookTheme.light,
      home: const DashboardScreen(),
    );
  }
}
