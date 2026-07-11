/// "Squared yellow paper + blue ballpoint ink" design language,
/// ported 1:1 from the web app's static/css/notebook.css custom properties.
library;

import 'package:flutter/material.dart';

class NotebookColors {
  NotebookColors._();

  static const ink = Color(0xFF1A3A6E);
  static const inkSoft = Color(0xFF2C5282);
  static const paper = Color(0xFFF9F4D9);
  static const paperLine = Color(0x1F1A3A6E); // rgba(26,58,110,0.12)
  static const marginLine = Color(0x592C5282); // rgba(44,82,130,0.35)
  static const trainedFill = Color(0x1F1A3A6E); // rgba(26,58,110,0.12)
  static const shadow = Color(0x2E1A3A6E); // rgba(26,58,110,0.18)
  static const desk = Color(0xFFC4B896); // outer background behind the page
  static const cardFill = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
  static const danger = Color(0xFF8B2F2F);
}

class NotebookTheme {
  NotebookTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: NotebookColors.paper,
      colorScheme: base.colorScheme.copyWith(
        primary: NotebookColors.ink,
        secondary: NotebookColors.inkSoft,
        surface: NotebookColors.paper,
        error: NotebookColors.danger,
      ),
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: NotebookColors.paper,
        foregroundColor: NotebookColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      splashFactory: NoSplash.splashFactory,
      dividerColor: NotebookColors.ink,
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base
        .copyWith(
          titleLarge: const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: NotebookColors.ink,
          ),
          titleMedium: const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: NotebookColors.ink,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 21,
            fontWeight: FontWeight.w500,
            color: NotebookColors.ink,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: NotebookColors.ink,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: NotebookColors.ink,
          ),
        )
        .apply(fontFamily: 'Caveat');
  }
}
