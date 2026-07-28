import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/notebook_theme.dart';

/// The one place a list row learns to swipe: right to copy, left to delete.
///
/// Every swipeable list in the app goes through this — routines, catalog
/// exercises, a routine's exercises, logged sessions, planned workouts,
/// measurements — so the direction, the reveal and the haptic are identical
/// everywhere and a change to any of them lands in a single file.
class SwipeableRow extends StatelessWidget {
  /// [itemKey] becomes this widget's own key as well as the [Dismissible]'s.
  /// A reorderable list requires a key on the child it is handed, and passing
  /// it only to the Dismissible inside leaves the outer widget unkeyed — which
  /// fails at runtime, not compile time. Deriving both from one argument means
  /// a call site cannot get it half-right.
  const SwipeableRow({
    required this.itemKey,
    required this.onDelete,
    this.onCopy,
    required this.child,
  }) : super(key: itemKey);

  /// Identity of the row, for both this widget and its [Dismissible]; unique
  /// within its list.
  final Key itemKey;

  /// Performs the delete, including any confirmation prompt. Return true to let
  /// the row animate away — only when the caller has already dropped it from
  /// the list — or false to snap it back, which is right whenever the caller
  /// reloads from the database instead and lets the rebuilt list be the truth.
  final Future<bool> Function() onDelete;

  /// Duplicates the row. Null (the default) disables the copy swipe entirely,
  /// leaving the row delete-only.
  final Future<void> Function()? onCopy;

  final Widget child;

  bool get _canCopy => onCopy != null;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: itemKey,
      direction:
          _canCopy ? DismissDirection.horizontal : DismissDirection.endToStart,
      // A delete-only row shows the same reveal whichever slot Flutter reaches
      // for, so a stray rightward drag can never flash a copy affordance.
      background:
          _canCopy ? const SwipeCopyBackground() : const SwipeDeleteBackground(),
      secondaryBackground: const SwipeDeleteBackground(),
      confirmDismiss: (direction) async {
        HapticFeedback.lightImpact();
        if (direction == DismissDirection.startToEnd) {
          await onCopy!();
          return false; // the copy arrives as a new row; this one stays put
        }
        return onDelete();
      },
      child: child,
    );
  }
}

/// Reveal shown behind a row while swiping right (startToEnd) — copy.
class SwipeCopyBackground extends StatelessWidget {
  const SwipeCopyBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.notebook.trainedFill,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        '${AppLocalizations.of(context).swipeCopy} ⟶',
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: context.notebook.ink,
        ),
      ),
    );
  }
}

/// Reveal shown behind a row while swiping left (endToStart) — delete.
class SwipeDeleteBackground extends StatelessWidget {
  const SwipeDeleteBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.notebook.accent.withValues(alpha: 0.12),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 10),
      child: Text(
        '⟵ ${AppLocalizations.of(context).swipeDelete}',
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: context.notebook.accent,
        ),
      ),
    );
  }
}
