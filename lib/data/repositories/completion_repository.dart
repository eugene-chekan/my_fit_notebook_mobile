import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/completion.dart';

const _completionColumns =
    'id, routine_id, completed_on, duration_minutes, started_at, paused_seconds, '
    'exercises_completed, sets_completed, reps_total';

/// SQL access for workout completions — a Dart port of repositories/completions.py.
class CompletionRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  /// {ISO-date: [routine_name, ...]} for every completion in the given month —
  /// backs the calendar screen's trained-day dots.
  Future<Map<String, List<String>>> completionRoutinesForMonth(int year, int month) async {
    final db = await _db;
    final ym = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final rows = await db.rawQuery(
      '''
      SELECT date(c.completed_on) AS d, r.name AS name
      FROM completions c
      JOIN routines r ON c.routine_id = r.id
      WHERE strftime('%Y-%m', c.completed_on) = ?
      ORDER BY c.completed_on
      ''',
      [ym],
    );
    final result = <String, List<String>>{};
    for (final row in rows) {
      final day = row['d'] as String;
      result.putIfAbsent(day, () => []).add(row['name'] as String);
    }
    return result;
  }

  /// (workout count, total minutes) for completions on/after [fromIsoDate]
  /// (yyyy-MM-dd) — backs the dashboard's "this week" stats.
  Future<(int, int)> totalsSince(String fromIsoDate) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c, COALESCE(SUM(duration_minutes), 0) AS m '
      'FROM completions WHERE date(completed_on) >= ?',
      [fromIsoDate],
    );
    return (rows.first['c'] as int, rows.first['m'] as int);
  }

  /// Every distinct trained date (yyyy-MM-dd), newest first — used for the
  /// dashboard streak calculation.
  Future<List<String>> distinctTrainedDates() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT DISTINCT date(completed_on) AS d FROM completions ORDER BY d DESC',
    );
    return rows.map((r) => r['d'] as String).toList();
  }

  /// Every completion on/after [fromIsoDate] (yyyy-MM-dd), across all
  /// routines, oldest first — feeds the Stats screen's client-side
  /// bucketing (weekly minutes, monthly totals, averages).
  Future<List<Completion>> completionsSince(String fromIsoDate) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT $_completionColumns FROM completions WHERE date(completed_on) >= ? '
      'ORDER BY completed_on',
      [fromIsoDate],
    );
    return rows.map(Completion.fromMap).toList();
  }

  Future<List<Completion>> listForRoutine(int routineId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT $_completionColumns FROM completions WHERE routine_id = ? '
      'ORDER BY completed_on DESC, id DESC',
      [routineId],
    );
    return rows.map(Completion.fromMap).toList();
  }

  /// Inserts a completion. Returns false if one already exists for that
  /// routine + date (the UNIQUE(routine_id, completed_on) constraint).
  Future<bool> addCompletion(
    int routineId,
    DateTime completedOn, {
    int? durationMinutes,
    String? startedAt,
    int? pausedSeconds,
  }) async {
    final db = await _db;
    try {
      await db.insert('completions', {
        'routine_id': routineId,
        'completed_on': _iso(completedOn),
        'duration_minutes': durationMinutes,
        'started_at': startedAt,
        'paused_seconds': pausedSeconds,
      });
      return true;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return false;
      rethrow;
    }
  }

  /// Like [addCompletion] but returns the new completion's id (needed to link
  /// per-set history rows), or null on the UNIQUE(routine_id, completed_on)
  /// collision.
  Future<int?> addCompletionReturningId(
    int routineId,
    DateTime completedOn, {
    int? durationMinutes,
    String? startedAt,
    int? pausedSeconds,
    int? exercisesCompleted,
    int? setsCompleted,
    int? repsTotal,
  }) async {
    final db = await _db;
    try {
      return await db.insert('completions', {
        'routine_id': routineId,
        'completed_on': _iso(completedOn),
        'duration_minutes': durationMinutes,
        'started_at': startedAt,
        'paused_seconds': pausedSeconds,
        'exercises_completed': exercisesCompleted,
        'sets_completed': setsCompleted,
        'reps_total': repsTotal,
      });
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return null;
      rethrow;
    }
  }

  Future<bool> updateCompletionDate(
    int completionId,
    int routineId,
    DateTime newCompletedOn, {
    int? durationMinutes,
  }) async {
    final db = await _db;
    final values = <String, Object?>{'completed_on': _iso(newCompletedOn)};
    if (durationMinutes != null) values['duration_minutes'] = durationMinutes;
    try {
      final count = await db.update(
        'completions',
        values,
        where: 'id = ? AND routine_id = ?',
        whereArgs: [completionId, routineId],
      );
      return count > 0;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return false;
      rethrow;
    }
  }

  Future<void> deleteCompletion(int completionId, int routineId) async {
    final db = await _db;
    await db.delete(
      'completions',
      where: 'id = ? AND routine_id = ?',
      whereArgs: [completionId, routineId],
    );
  }

  String _iso(DateTime dt) {
    final hasTime = dt.hour != 0 || dt.minute != 0 || dt.second != 0;
    if (!hasTime) {
      return '${dt.year.toString().padLeft(4, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';
    }
    return dt.toIso8601String().substring(0, 16); // yyyy-MM-ddTHH:mm
  }
}
