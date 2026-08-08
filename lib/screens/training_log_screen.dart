import 'package:flutter/material.dart';

import '../data/models/completion.dart';
import '../data/models/profile.dart';
import '../data/repositories/completion_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/session_log.dart';

/// The whole training history, one page back from the workouts themselves.
///
/// A workout screen shows only its last few sessions — the page is for
/// *training*, not for reading. Everything logged lives here instead: pick a
/// workout, then a session, then read its full report.
class TrainingLogScreen extends StatefulWidget {
  const TrainingLogScreen({super.key});

  @override
  State<TrainingLogScreen> createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends State<TrainingLogScreen> {
  final _completions = CompletionRepository();
  List<LoggedRoutine>? _logged;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logged = await _completions.loggedRoutines();
    if (mounted) setState(() => _logged = logged);
  }

  Future<void> _open(LoggedRoutine entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutLogScreen(
          routineId: entry.routineId,
          routineName: entry.isAdhoc
              ? AppLocalizations.of(context).adhocWorkout
              : entry.name,
        ),
      ),
    );
    // Sessions can be deleted in there, which can empty a workout out of the
    // list entirely.
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final logged = _logged;
    return Scaffold(
      body: SafeArea(
        child: NotebookPage(
          marginChild: GlyphButton(
            glyph: '≡',
            size: 26,
            semanticLabel: t.menu,
            onTap: () => openMarginMenu(context),
          ),
          child: logged == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NotebookHeader(
                      title: t.navTrainingLog,
                      leading: const BackGlyph(),
                    ),
                    const SizedBox(height: 4),
                    if (logged.isEmpty)
                      MutedLine(t.noTrainingLog)
                    else
                      for (final entry in logged) _routineRow(t, entry),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _routineRow(AppLocalizations t, LoggedRoutine entry) {
    final n = context.notebook;
    return InkWell(
      onTap: () => _open(entry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: notebookLine(context),
            child: Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                entry.isAdhoc ? t.adhocWorkout : entry.name,
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 21,
                  color: n.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            height: notebookLine(context),
            child: Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(left: 2, bottom: 3),
              child: Text(
                '${t.sessionsCount(entry.sessionCount)} · '
                '${t.lastTrainedOn(formatCompletionDt(entry.lastCompletedOn))}',
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 16,
                  color: n.sec,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every session logged for one workout, newest first. Tapping a session opens
/// the same full report the workout screen shows; swiping left deletes it.
class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({
    super.key,
    required this.routineId,
    required this.routineName,
  });

  final int routineId;
  final String routineName;

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  final _completions = CompletionRepository();
  final _profile = ProfileRepository();
  List<Completion>? _sessions;
  String _units = Units.metric;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await _completions.listForRoutine(widget.routineId);
    final profile = await _profile.getProfile();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _units = profile.units;
    });
  }

  Future<void> _delete(Completion completion) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showPaperConfirm(
      context,
      title: t.removeSessionTitle,
      message: t.removeSessionMessage,
      confirmLabel: t.remove,
    );
    if (!confirmed) return;
    await _completions.deleteCompletion(completion.id, widget.routineId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final sessions = _sessions;
    return Scaffold(
      body: SafeArea(
        child: NotebookPage(
          marginChild: GlyphButton(
            glyph: '≡',
            size: 26,
            semanticLabel: t.menu,
            onTap: () => openMarginMenu(context),
          ),
          child: sessions == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NotebookHeader(
                      title: widget.routineName,
                      leading: const BackGlyph(),
                    ),
                    const SizedBox(height: 4),
                    if (sessions.isEmpty)
                      MutedLine(t.noSessions)
                    else
                      for (final session in sessions)
                        CompletionRow(
                          key: ValueKey('log-${session.id}'),
                          completion: session,
                          onTap: () => showCompletionDetail(
                            context,
                            completion: session,
                            sets: _completions.setsFor(session.id),
                            units: _units,
                          ),
                          onDelete: () => _delete(session),
                        ),
                  ],
                ),
        ),
      ),
    );
  }
}
