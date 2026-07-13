import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models/completion.dart' as models;
import '../data/models/exercise.dart';
import '../state/routine_detail_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../widgets/glyph_button.dart';
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
    final stats = await _provider.finishWorkout();
    if (!mounted) return;
    await showPaperDialog<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Workout complete',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: NotebookColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          _statRow('Exercises completed', '${stats.exercisesCompleted}'),
          _statRow('Total duration', formatDuration(stats.durationSeconds)),
          _statRow('Time paused', formatDuration(stats.pausedSeconds)),
          const SizedBox(height: 12),
          PenButton(label: 'Got it', onPressed: () => Navigator.pop(context)),
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
    final confirmed = await showPaperConfirm(
      context,
      title: 'Remove session?',
      message: 'Remove this session from the log?',
      confirmLabel: 'Remove',
    );
    if (confirmed) await _provider.deleteCompletion(completion.id);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        body: SafeArea(
          child: Consumer<RoutineDetailProvider>(
            builder: (context, provider, _) {
              final routine = provider.routine;
              final active = routine != null && routine.isStarted;
              return Stack(
                children: [
                  Positioned.fill(
                    child: NotebookPage(
                      // Leave room at the bottom for the overlapping workout
                      // strip so the last logged session isn't hidden.
                      padding: EdgeInsets.fromLTRB(64, 4, 18, active ? 124 : 28),
                      child: routine == null
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const BackLine(label: '← back to notebook'),
                                NotebookHeader(
                                  title: routine.name,
                                  trailing: GlyphButton(
                                    glyph: '✐',
                                    semanticLabel: 'Manage routine',
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
                                        label: 'Start workout',
                                        onPressed: provider.startWorkout,
                                      ),
                                    ),
                                  ),
                                const HeadingLine('Exercises'),
                                if (provider.exercises.isEmpty)
                                  const MutedLine('No exercises yet — add one via ✐ above.')
                                else
                                  ...provider.exercises.map(
                                    (ex) => _ExerciseRow(
                                      exercise: ex,
                                      onToggle: () {
                                        HapticFeedback.lightImpact();
                                        provider.toggleExercise(ex.id);
                                      },
                                    ),
                                  ),
                                const HeadingLine('Logged sessions'),
                                if (provider.completions.isEmpty)
                                  const MutedLine('No sessions logged yet.')
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
    return Row(
        children: [
          if (!paused) const _PulsingDot(),
          if (!paused) const SizedBox(width: 8),
          Text(
            paused ? 'paused' : formatClock(provider.liveElapsedSeconds),
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
            tooltip: paused ? 'Resume' : 'Pause',
            onPressed: paused ? provider.resumeWorkout : provider.pauseWorkout,
          ),
          const SizedBox(width: 10),
          PenButtonFilled(label: 'Finish', onPressed: onFinish),
      ],
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
                      if (formatPrescription(exercise.sets, exercise.repsMin, exercise.repsMax)
                          .isNotEmpty)
                        TextSpan(
                          text:
                              '  ${formatPrescription(exercise.sets, exercise.repsMin, exercise.repsMax)}',
                          style: TextStyle(
                            color: exercise.isDone
                                ? NotebookColors.inkSoft
                                : NotebookColors.inkSoft,
                          ),
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

class _InkCheckbox extends StatelessWidget {
  const _InkCheckbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
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
          ? const Center(
              child: Text(
                '✓',
                style: TextStyle(
                  fontSize: 14,
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
