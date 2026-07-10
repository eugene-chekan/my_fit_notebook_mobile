import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';
import 'notebook_page.dart';

/// The bordered title row at the top of every page (`.page-header` in
/// notebook.css). Occupies exactly two ruled lines so its bottom ink rule
/// lands on the paper's grid, with the title resting on the line like
/// handwriting.
class NotebookHeader extends StatelessWidget {
  const NotebookHeader({super.key, required this.title, this.leading, this.trailing});

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2 * kNotebookLine,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NotebookColors.ink, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ?leading,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: NotebookColors.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The "← back" line that sits above a subpage's header, like the web
/// app's `.back-link`.
class BackLine extends StatelessWidget {
  const BackLine({super.key, this.label = '← back'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kNotebookLine,
      alignment: Alignment.bottomLeft,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3, right: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: NotebookColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
