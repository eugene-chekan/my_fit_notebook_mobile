import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';

/// The bordered title row at the top of every page (`.page-header` in
/// notebook.css) — a bottom ink rule, a Caveat title, and optional trailing
/// controls (calendar toggle, menu button, etc).
class NotebookHeader extends StatelessWidget {
  const NotebookHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.large = false,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NotebookColors.ink, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ?leading,
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: large ? 34 : 26,
                fontWeight: FontWeight.w700,
                color: NotebookColors.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
