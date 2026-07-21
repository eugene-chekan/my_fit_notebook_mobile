import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';
import 'glyph_button.dart';
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
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.notebook.ink, width: 2)),
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
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: context.notebook.ink,
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

/// A compact back arrow for [NotebookHeader.leading] — the icon-sized
/// counterpart to Android's own back gesture/button, which already
/// provides "back" for free. This replaces a standalone "← back to
/// notebook" text line so subpages don't spend a whole ruled line on
/// something the OS already offers.
class BackGlyph extends StatelessWidget {
  const BackGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    return GlyphButton(
      glyph: '←',
      size: 24,
      semanticLabel: 'Back',
      onTap: () => Navigator.of(context).pop(),
    );
  }
}
