import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';
import 'pen_button.dart';

/// A modal dialog styled as a paper note: paper fill, 2px ink border with
/// slightly uneven corners — the same look as the web app's `.stats-dropdown`
/// panels, instead of Material's default white surface.
Future<T?> showPaperDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: NotebookColors.paper,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: NotebookColors.ink, width: 2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(5),
          bottomLeft: Radius.circular(4),
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Builder(builder: builder),
      ),
    ),
  );
}

/// Confirmation note with Cancel / confirm pen buttons. Returns true only
/// on explicit confirmation.
Future<bool> showPaperConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final result = await showPaperDialog<bool>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: NotebookColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 18,
            color: NotebookColors.inkSoft,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PenButton(
              label: 'Cancel',
              small: true,
              onPressed: () => Navigator.pop(context, false),
            ),
            const SizedBox(width: 8),
            PenButton(
              label: confirmLabel,
              small: true,
              danger: true,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}
