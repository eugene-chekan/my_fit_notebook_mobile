import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/notebook_theme.dart';
import '../utils/exercise_suggestions.dart';
import 'glyph_button.dart';
import 'notebook_page.dart';

/// The "+ add exercise…" line: one ruled row holding an autocompleting name
/// field and a ✓ to commit it.
///
/// Shared by the manage-workout page, which uses it to build a routine, and a
/// freestyle session, which uses it to record one as it happens. The two
/// differ entirely in what they do with the name — [onSubmit] decides that —
/// so only the typing lives here.
class AddExerciseRow extends StatelessWidget {
  const AddExerciseRow({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.catalogNames,
    required this.existingNames,
    required this.onSubmit,
    this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// The suggestion pool — every name the exercise library knows.
  final List<String> catalogNames;

  /// Names already on this page, so the list does not suggest a duplicate.
  final Iterable<String> existingNames;

  /// Called with the typed or tapped name.
  final void Function(String name) onSubmit;

  /// Overrides the default "+ add exercise…" placeholder.
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SizedBox(
      height: notebookLine(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => RawAutocomplete<String>(
                textEditingController: controller,
                focusNode: focusNode,
                optionsBuilder: (value) => filterExerciseSuggestions(
                  query: value.text,
                  catalog: catalogNames,
                  existing: existingNames,
                ),
                onSelected: onSubmit,
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          maxLength: 200,
                          cursorColor: context.notebook.ink,
                          style: TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 19,
                            color: context.notebook.ink,
                          ),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            counterText: '',
                            hintText: hintText ?? t.addExerciseHint,
                            hintStyle: TextStyle(
                              fontFamily: 'Caveat',
                              fontSize: 19,
                              color: context.notebook.sec,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => onSubmit(controller.text),
                        ),
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) =>
                    _SuggestionsOverlay(
                      onSelected: onSelected,
                      options: options.toList(),
                      width: constraints.maxWidth,
                    ),
              ),
            ),
          ),
          GlyphButton(
            glyph: '✓',
            color: context.notebook.ink,
            semanticLabel: t.addExerciseSemantic,
            onTap: () => onSubmit(controller.text),
          ),
        ],
      ),
    );
  }
}

/// The floating suggestion list under the add-exercise field, styled as a
/// small paper note (paper fill, 2px ink border, slightly uneven corners).
class _SuggestionsOverlay extends StatelessWidget {
  const _SuggestionsOverlay({
    required this.onSelected,
    required this.options,
    required this.width,
  });

  final void Function(String) onSelected;
  final List<String> options;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          constraints: const BoxConstraints(maxHeight: 216),
          decoration: BoxDecoration(
            color: context.notebook.bg,
            border: Border.all(color: context.notebook.ink, width: 2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(5),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: context.notebook.shadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final name = options[index];
              return InkWell(
                onTap: () => onSelected(name),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 19,
                      color: context.notebook.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
