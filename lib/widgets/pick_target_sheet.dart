import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';
import 'notebook_page.dart';

/// One row offered by [showPickTarget].
class PickOption {
  const PickOption({
    required this.id,
    required this.label,
    this.detail,
    this.alreadyHas = false,
  });

  final int id;
  final String label;

  /// Muted trailing note — a member count, a prescription, whatever the caller
  /// wants to show alongside the name.
  final String? detail;

  /// Marks a target the item is already filed under. Still tappable, so the
  /// caller can answer with "already in …" rather than leaving a dead row.
  final bool alreadyHas;
}

/// The shared "file this somewhere" sheet: pick a program for a workout, or a
/// workout for an exercise. Optionally offers a "+ new …" line at the bottom,
/// which returns [newTargetId].
///
/// Returns the chosen option's id, [newTargetId] for the create line, or null
/// when dismissed.
const int newTargetId = -1;

Future<int?> showPickTarget(
  BuildContext context, {
  required String title,
  required List<PickOption> options,
  String? emptyMessage,
  String? createLabel,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.notebook.bg,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: context.notebook.ink, width: 2),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
    ),
    builder: (sheetContext) {
      final n = sheetContext.notebook;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: n.ink,
                ),
              ),
              const SizedBox(height: 8),
              if (options.isEmpty && emptyMessage != null)
                Text(
                  emptyMessage,
                  style: TextStyle(fontFamily: 'Caveat', fontSize: 18, color: n.sec),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final option in options)
                        InkWell(
                          onTap: () => Navigator.pop(sheetContext, option.id),
                          child: SizedBox(
                            height: kNotebookLine,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      option.label,
                                      style: TextStyle(
                                        fontFamily: 'Caveat',
                                        fontSize: 21,
                                        color: option.alreadyHas ? n.sec : n.ink,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (option.alreadyHas)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6, bottom: 7),
                                    child: Icon(Icons.check, size: 16, color: n.sec),
                                  ),
                                if (option.detail != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8, bottom: 5),
                                    child: Text(
                                      option.detail!,
                                      style: TextStyle(
                                        fontFamily: 'Caveat',
                                        fontSize: 16,
                                        color: n.sec,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (createLabel != null) ...[
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => Navigator.pop(sheetContext, newTargetId),
                  child: SizedBox(
                    height: kNotebookLine,
                    child: Container(
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        createLabel,
                        style: TextStyle(
                          fontFamily: 'Caveat',
                          fontSize: 20,
                          color: n.sec,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
