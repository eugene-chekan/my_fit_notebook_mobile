import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models/completion.dart' as models;
import '../data/models/exercise.dart';
import '../data/models/exercise_set.dart';
import '../data/models/rep_unit.dart';
import '../l10n/app_localizations.dart';
import '../state/routine_detail_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../utils/set_progress.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/pen_button.dart';
import 'manage_routine_screen.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key, required this.routineId});

  final int routineId;

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  late final RoutineDetailProvider _provider;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _provider = RoutineDetailProvider(widget.routineId)..load();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _openManage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ManageRoutineScreen(routineId: widget.routineId)),
    );
    _provider.load();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final t = AppLocalizations.of(context);
    final stats = await _provider.finishWorkout();
    if (!mounted) return;
    await showPaperDialog<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.workoutComplete,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: NotebookColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          _statRow(t.exercisesCompletedLabel, '${stats.exercisesCompleted}'),
          if (stats.setsCompleted > 0) ...[
            _statRow(t.setsCompletedLabel, '${stats.setsCompleted}'),
            _statRow(t.repsLoggedLabel, '${stats.repsTotal}'),
          ],
          _statRow(t.totalDurationLabel, formatDuration(stats.durationSeconds)),
          _statRow(t.timePausedLabel, formatDuration(stats.pausedSeconds)),
          const SizedBox(height: 12),
          PenButton(label: t.gotIt, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 19,
              color: NotebookColors.inkSoft,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NotebookColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCompletion(models.Completion completion) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showPaperConfirm(
      context,
      title: t.removeSessionTitle,
      message: t.removeSessionMessage,
      confirmLabel: t.remove,
    );
    if (confirmed) await _provider.deleteCompletion(completion.id);
  }

  /// Tap a set's reps to type the actual count performed.
  Future<void> _editSetReps(Exercise exercise, ExerciseSet set) async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: set.actualReps?.toString() ?? '',
    );
    final unitWord = exercise.unit == RepUnit.reps ? 'reps' : exercise.unit;
    final reps = await showPaperDialog<int>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.setActual(set.setIndex, unitWord),
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: NotebookColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            cursorColor: NotebookColors.ink,
            style: const TextStyle(fontFamily: 'Caveat', fontSize: 22, color: NotebookColors.ink),
            decoration: InputDecoration(
              isDense: true,
              suffixText: unitWord,
              suffixStyle: const TextStyle(
                fontFamily: 'Caveat',
                fontSize: 18,
                color: NotebookColors.inkSoft,
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: NotebookColors.ink),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: NotebookColors.ink, width: 2),
              ),
            ),
            onSubmitted: (v) => Navigator.pop(context, int.tryParse(v.trim())),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PenButton(
                label: t.cancel,
                small: true,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              PenButton(
                label: t.save,
                small: true,
                onPressed: () => Navigator.pop(context, int.tryParse(controller.text.trim())),
              ),
            ],
          ),
        ],
      ),
    );
    // Cancel (or a non-number) returns null and leaves the reps untouched; a
    // valid number updates them, and 0 clears them back to unlogged.
    if (reps != null) {
      await _provider.setSetReps(set.id, reps <= 0 ? null : reps);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const NotebookDrawer(),
        body: SafeArea(
          child: Consumer<RoutineDetailProvider>(
            builder: (context, provider, _) {
              final t = AppLocalizations.of(context);
              final routine = provider.routine;
              final active = routine != null && routine.isStarted;
              return Stack(
                children: [
                  Positioned.fill(
                    child: NotebookPage(
                      marginChild: GlyphButton(
                        glyph: '≡',
                        size: 26,
                        semanticLabel: t.menu,
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      // Leave room at the bottom for the overlapping workout
                      // strip so the last logged session isn't hidden.
                      padding: EdgeInsets.fromLTRB(64, 4, 18, active ? 124 : 28),
                      child: routine == null
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                NotebookHeader(
                                  title: routine.name,
                                  leading: const BackGlyph(),
                                  trailing: GlyphButton(
                                    glyph: '✐',
                                    semanticLabel: t.manageRoutineSemantic,
                                    onTap: _openManage,
                                  ),
                                ),
                                if (routine.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      routine.description,
                                      style: const TextStyle(
                                        fontFamily: 'Caveat',
                                        fontSize: 17,
                                        color: NotebookColors.inkSoft,
                                      ),
                                    ),
                                  ),
                                if (!routine.isStarted)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: PenButton(
                                        label: t.startWorkout,
                                        onPressed: provider.startWorkout,
                                      ),
                                    ),
                                  ),
                                HeadingLine(t.navExercises),
                                if (provider.exercises.isEmpty)
                                  MutedLine(t.noExercisesWorkout)
                                else
                                  ...provider.exercises.map(
                                    (ex) => provider.isPrescribed(ex)
                                        ? _PrescribedExerciseRow(
                                            exercise: ex,
                                            sets: provider.setsFor(ex.id),
                                            expanded: provider.isExpanded(ex.id),
                                            onToggleExpand: () =>
                                                provider.toggleExpanded(ex.id),
                                            onToggleAll: (allDone) {
                                              HapticFeedback.lightImpact();
                                              provider.markAllSets(ex.id, !allDone);
                                            },
                                            onToggleSet: (setId) {
                                              HapticFeedback.lightImpact();
                                              provider.toggleSet(setId, ex.id);
                                            },
                                            onEditReps: (set) => _editSetReps(ex, set),
                                          )
                                        : _ExerciseRow(
                                            exercise: ex,
                                            onToggle: () {
                                              HapticFeedback.lightImpact();
                                              provider.toggleExercise(ex.id);
                                            },
                                          ),
                                  ),
                                HeadingLine(t.loggedSessions),
                                if (provider.completions.isEmpty)
                                  MutedLine(t.noSessions)
                                else
                                  ...provider.completions.map(
                                    (c) => _CompletionRow(
                                      completion: c,
                                      onDelete: () => _deleteCompletion(c),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  if (active)
                    // Over-wide and pushed past the bottom so the visible
                    // tilt never exposes a gap at the screen edges; the
                    // Stack clips the overflow.
                    Positioned(
                      left: -20,
                      right: -20,
                      bottom: -12,
                      child: _WorkoutStrip(provider: provider, onFinish: _finish),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A torn strip of paper laid visibly askew over the bottom of the page
/// during an active workout: pulsing dot, live elapsed clock, pause/resume,
/// and a prominent Finish. The tear is a jagged path with its own painted
/// shadow (a BoxShadow can't follow a clipped edge), on a slightly brighter
/// paper tone so it reads as a separate sheet, and it carries one fragment
/// of ruling from whatever page it was torn out of.
class _WorkoutStrip extends StatelessWidget {
  const _WorkoutStrip({required this.provider, required this.onFinish});

  final RoutineDetailProvider provider;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final paused = provider.routine!.isPaused;
    return Transform.rotate(
      angle: -0.022, // ~1.3° — clearly hand-placed
      child: CustomPaint(
        painter: const _TornPaperPainter(),
        child: Padding(
          // Generous insets: the top clears the tear's jag band, the sides
          // clear the off-screen bleed, the bottom clears the tilt.
          padding: const EdgeInsets.fromLTRB(36, 28, 36, 24),
          child: _stripContent(paused),
        ),
      ),
    );
  }

  Widget _stripContent(bool paused) {
    return Builder(
      builder: (context) {
        final t = AppLocalizations.of(context);
        return Row(
          children: [
            if (!paused) const _PulsingDot(),
            if (!paused) const SizedBox(width: 8),
            Text(
              paused ? t.paused : formatClock(provider.liveElapsedSeconds),
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontStyle: paused ? FontStyle.italic : FontStyle.normal,
                color: paused ? NotebookColors.inkSoft : NotebookColors.ink,
              ),
            ),
            const Spacer(),
            PlayerButton(
              icon: paused ? Icons.play_arrow : Icons.pause,
              tooltip: paused ? t.resume : t.pause,
              onPressed: paused ? provider.resumeWorkout : provider.pauseWorkout,
            ),
            const SizedBox(width: 10),
            PenButtonFilled(label: t.finish, onPressed: onFinish),
          ],
        );
      },
    );
  }
}

/// Paints the torn strip: an upward shadow along the jagged tear, the strip
/// fill in a slightly brighter paper tone, and one carried-over rule line.
class _TornPaperPainter extends CustomPainter {
  const _TornPaperPainter();

  /// A touch brighter than the page so the strip reads as a separate sheet.
  static const _stripPaper = Color(0xFFFDF9E9);

  @override
  void paint(Canvas canvas, Size size) {
    final path = _tornPath(size);
    canvas.drawPath(
      path.shift(const Offset(0, -5)),
      Paint()
        ..color = NotebookColors.shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(path, Paint()..color = _stripPaper);

    final linePaint = Paint()
      ..color = NotebookColors.paperLine
      ..strokeWidth = 1;
    final y = size.height * 0.62;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
  }

  /// Jagged-top outline. The fixed seed keeps the tear identical across
  /// repaints — it's one specific torn strip, not a shimmering one.
  Path _tornPath(Size size) {
    final rnd = math.Random(1974);
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, 10 + rnd.nextDouble() * 8);
    var x = 0.0;
    while (x < size.width) {
      x = math.min(x + 12 + rnd.nextDouble() * 22, size.width);
      path.lineTo(x, 3 + rnd.nextDouble() * 14);
    }
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _TornPaperPainter oldDelegate) => false;
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.3).animate(_controller),
      child: const Icon(Icons.fiber_manual_record, size: 10, color: NotebookColors.ink),
    );
  }
}

/// An exercise line: hand-drawn ink checkbox that gets a ✓ scribble,
/// name struck through when done. The whole line is the tap target.
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.onToggle});

  final Exercise exercise;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kNotebookLine,
      child: InkWell(
        onTap: onToggle,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _InkCheckbox(checked: exercise.isDone),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 20,
                      color: exercise.isDone ? NotebookColors.inkSoft : NotebookColors.ink,
                      decoration: exercise.isDone ? TextDecoration.lineThrough : null,
                    ),
                    children: [
                      TextSpan(text: exercise.name),
                      if (formatPrescription(
                        exercise.sets,
                        exercise.repsMin,
                        exercise.repsMax,
                        exercise.unit,
                      ).isNotEmpty)
                        TextSpan(
                          text:
                              '  ${formatPrescription(exercise.sets, exercise.repsMin, exercise.repsMax, exercise.unit)}',
                          style: const TextStyle(color: NotebookColors.inkSoft),
                        ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A prescribed exercise (has sets): a ▸/▾ header with a derived checkbox
/// (checked when every set is done), the name + prescription + n/N progress.
/// Tapping the arrow or name expands an indented list of individually-checkable
/// sets, each with a tap-to-edit actual-reps value.
class _PrescribedExerciseRow extends StatelessWidget {
  const _PrescribedExerciseRow({
    required this.exercise,
    required this.sets,
    required this.expanded,
    required this.onToggleExpand,
    required this.onToggleAll,
    required this.onToggleSet,
    required this.onEditReps,
  });

  final Exercise exercise;
  final List<ExerciseSet> sets;
  final bool expanded;
  final VoidCallback onToggleExpand;
  /// Passed the current all-done state so the handler can flip it.
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<int> onToggleSet; // set id
  final ValueChanged<ExerciseSet> onEditReps;

  @override
  Widget build(BuildContext context) {
    final progress = setProgress(sets);
    final allDone = allSetsDone(sets);
    final prescription = formatPrescription(
      exercise.sets,
      exercise.repsMin,
      exercise.repsMax,
      exercise.unit,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: kNotebookLine,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: onToggleExpand,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    expanded ? '▾' : '▸',
                    style: const TextStyle(fontSize: 15, color: NotebookColors.inkSoft),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => onToggleAll(allDone),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _InkCheckbox(checked: allDone),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onToggleExpand,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: 'Caveat',
                          fontSize: 20,
                          color: allDone ? NotebookColors.inkSoft : NotebookColors.ink,
                          decoration: allDone ? TextDecoration.lineThrough : null,
                        ),
                        children: [
                          TextSpan(text: exercise.name),
                          if (prescription.isNotEmpty)
                            TextSpan(
                              text: '  $prescription',
                              style: const TextStyle(color: NotebookColors.inkSoft),
                            ),
                          TextSpan(
                            text: '   ${progress.done}/${progress.total}',
                            style: const TextStyle(color: NotebookColors.inkSoft),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (expanded)
          ...sets.map(
            (s) => _SetRow(
              set: s,
              unit: exercise.unit,
              onToggle: () => onToggleSet(s.id),
              onEditReps: () => onEditReps(s),
            ),
          ),
      ],
    );
  }
}

/// One indented set line under an expanded exercise: a small checkbox, its
/// index, and the tappable actual-reps value (with a ✐ edit hint).
class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.set,
    required this.unit,
    required this.onToggle,
    required this.onEditReps,
  });

  final ExerciseSet set;
  final String unit;
  final VoidCallback onToggle;
  final VoidCallback onEditReps;

  @override
  Widget build(BuildContext context) {
    final suffix = RepUnit.suffix(unit);
    final repsText = set.actualReps == null ? '—' : '${set.actualReps}$suffix';
    return SizedBox(
      height: kNotebookLine,
      child: Padding(
        padding: const EdgeInsets.only(left: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _InkCheckbox(checked: set.isDone, size: 16, fontSize: 11),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                'Set ${set.setIndex}',
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 18,
                  color: set.isDone ? NotebookColors.inkSoft : NotebookColors.ink,
                  decoration: set.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: onEditReps,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: repsText,
                        style: const TextStyle(
                          fontFamily: 'Caveat',
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: NotebookColors.ink,
                          decoration: TextDecoration.underline,
                          decorationColor: NotebookColors.inkSoft,
                        ),
                      ),
                      const TextSpan(
                        text: '  ✐',
                        style: TextStyle(fontSize: 15, color: NotebookColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InkCheckbox extends StatelessWidget {
  const _InkCheckbox({required this.checked, this.size = 20, this.fontSize = 14});

  final bool checked;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: NotebookColors.ink, width: 2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(3),
          topRight: Radius.circular(5),
          bottomRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: checked
          ? Center(
              child: Text(
                '✓',
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: NotebookColors.ink,
                ),
              ),
            )
          : null,
    );
  }
}

class _CompletionRow extends StatelessWidget {
  const _CompletionRow({required this.completion, required this.onDelete});

  final models.Completion completion;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kNotebookLine,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Caveat',
                    fontSize: 18,
                    color: NotebookColors.ink,
                  ),
                  children: [
                    TextSpan(text: formatCompletionDt(completion.completedOn)),
                    if (completion.durationMinutes != null && completion.durationMinutes! >= 0)
                      TextSpan(
                        text: '  (${formatDurationMinutes(completion.durationMinutes!)})',
                        style: const TextStyle(color: NotebookColors.inkSoft),
                      ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GlyphButton(
            glyph: '×',
            size: 24,
            semanticLabel: 'Remove session',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
