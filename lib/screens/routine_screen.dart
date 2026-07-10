import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/completion.dart' as models;
import '../data/models/exercise.dart';
import '../state/routine_detail_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
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

  Future<void> _finish() async {
    final stats = await _provider.finishWorkout();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NotebookColors.paper,
        title: const Text(
          'Workout complete',
          style: TextStyle(fontFamily: 'Caveat', fontSize: 26, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statRow('Exercises completed', '${stats.exercisesCompleted}'),
            _statRow('Total duration', formatDuration(stats.durationSeconds)),
            _statRow('Time paused', formatDuration(stats.pausedSeconds)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Caveat', fontSize: 19, color: NotebookColors.inkSoft)),
          Text(value, style: const TextStyle(fontFamily: 'Caveat', fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        body: SafeArea(
          child: NotebookPage(
            child: Consumer<RoutineDetailProvider>(
              builder: (context, provider, _) {
                if (provider.loading || provider.routine == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final routine = provider.routine!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NotebookHeader(
                      title: routine.name,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: NotebookColors.inkSoft),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_note, color: NotebookColors.inkSoft),
                        tooltip: 'Manage routine',
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ManageRoutineScreen(routineId: widget.routineId),
                            ),
                          );
                          provider.load();
                        },
                      ),
                    ),
                    if (routine.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          routine.description,
                          style: const TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 18,
                            color: NotebookColors.inkSoft,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    _PlayerControls(provider: provider, onFinish: _finish),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: [
                          const Text(
                            'Exercises',
                            style: TextStyle(
                              fontFamily: 'Caveat',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: NotebookColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (provider.exercises.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'No exercises yet — add one from Manage.',
                                style: TextStyle(fontFamily: 'Caveat', fontSize: 19, color: NotebookColors.inkSoft),
                              ),
                            )
                          else
                            ...provider.exercises.map(
                              (ex) => _ExerciseRow(
                                exercise: ex,
                                onToggle: () => provider.toggleExercise(ex.id),
                              ),
                            ),
                          const SizedBox(height: 22),
                          const Text(
                            'Logged sessions',
                            style: TextStyle(
                              fontFamily: 'Caveat',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: NotebookColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (provider.completions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'No sessions logged for this routine yet.',
                                style: TextStyle(fontFamily: 'Caveat', fontSize: 19, color: NotebookColors.inkSoft),
                              ),
                            )
                          else
                            ...provider.completions.map(
                              (c) => _CompletionRow(
                                completion: c,
                                onDelete: () => provider.deleteCompletion(c.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({required this.provider, required this.onFinish});

  final RoutineDetailProvider provider;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final routine = provider.routine!;
    if (!routine.isStarted) {
      return Row(
        children: [
          PlayerButton(
            icon: Icons.play_arrow,
            tooltip: 'Start workout',
            onPressed: provider.startWorkout,
          ),
        ],
      );
    }
    if (routine.isPaused) {
      return Row(
        children: [
          const _PulsingLabel(text: 'paused', icon: Icons.pause),
          const SizedBox(width: 8),
          PlayerButton(icon: Icons.play_arrow, tooltip: 'Resume', onPressed: provider.resumeWorkout),
          const SizedBox(width: 6),
          PlayerButton(icon: Icons.stop, tooltip: 'Finish workout', soft: true, onPressed: onFinish),
        ],
      );
    }
    return Row(
      children: [
        _PulsingLabel(text: 'started at ${formatStartedAt(routine.startedAt!)}'),
        const SizedBox(width: 8),
        PlayerButton(icon: Icons.pause, tooltip: 'Pause', onPressed: provider.pauseWorkout),
        const SizedBox(width: 6),
        PlayerButton(icon: Icons.stop, tooltip: 'Finish workout', soft: true, onPressed: onFinish),
      ],
    );
  }
}

class _PulsingLabel extends StatefulWidget {
  const _PulsingLabel({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  State<_PulsingLabel> createState() => _PulsingLabelState();
}

class _PulsingLabelState extends State<_PulsingLabel> with SingleTickerProviderStateMixin {
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
    return Expanded(
      child: Row(
        children: [
          FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.3).animate(_controller),
            child: widget.icon != null
                ? Icon(widget.icon, size: 12, color: NotebookColors.inkSoft)
                : const Icon(Icons.fiber_manual_record, size: 10, color: NotebookColors.ink),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              widget.text,
              style: const TextStyle(
                fontFamily: 'Caveat',
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: NotebookColors.inkSoft,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.onToggle});

  final Exercise exercise;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          exercise.name,
          style: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 21,
            color: exercise.isDone ? NotebookColors.inkSoft : NotebookColors.ink,
            decoration: exercise.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}

class _CompletionRow extends StatelessWidget {
  const _CompletionRow({required this.completion, required this.onDelete});

  final models.Completion completion;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Caveat', fontSize: 17, color: NotebookColors.ink),
                children: [
                  TextSpan(text: formatCompletionDt(completion.completedOn)),
                  if (completion.durationMinutes != null && completion.durationMinutes! >= 0)
                    TextSpan(
                      text: '  (${formatDurationMinutes(completion.durationMinutes!)})',
                      style: const TextStyle(color: NotebookColors.inkSoft),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: NotebookColors.inkSoft, size: 20),
            tooltip: 'Remove session',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
