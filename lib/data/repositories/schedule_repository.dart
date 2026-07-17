import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/scheduled_workout.dart';

/// SQL access for planned workouts (`scheduled_workouts`). Rows always join the
/// routine name for display.
class ScheduleRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  static const _select = '''
    SELECT s.id, s.routine_id, s.scheduled_date, s.scheduled_time, s.status,
           s.completion_id, r.name AS routine_name
    FROM scheduled_workouts s
    JOIN routines r ON s.routine_id = r.id
  ''';

  /// yyyy-MM-dd for a date (time dropped).
  static String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Pencils in [routineId] on [date], with an optional [time] (HH:mm) that
  /// enables a reminder. Returns false if that routine is already booked that
  /// day (the UNIQUE constraint).
  Future<bool> addSchedule(int routineId, String date, {String? time}) async {
    final db = await _db;
    try {
      await db.insert('scheduled_workouts', {
        'routine_id': routineId,
        'scheduled_date': date,
        'scheduled_time': time,
        'status': ScheduleStatus.planned,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return false;
      rethrow;
    }
  }

  Future<void> deleteSchedule(int id) async {
    final db = await _db;
    await db.delete('scheduled_workouts', where: 'id = ?', whereArgs: [id]);
  }

  /// Moves a plan to a new date. Returns false on a UNIQUE clash with an
  /// existing plan for the same routine on that day.
  Future<bool> reschedule(int id, String date) async {
    final db = await _db;
    try {
      await db.update(
        'scheduled_workouts',
        {'scheduled_date': date},
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return false;
      rethrow;
    }
  }

  /// Planned entries on/after [fromDate], soonest first — the Schedule screen's
  /// "upcoming".
  Future<List<ScheduledWorkout>> listUpcoming(String fromDate) async {
    final db = await _db;
    final rows = await db.rawQuery(
      "$_select WHERE s.status = 'planned' AND s.scheduled_date >= ? "
      'ORDER BY s.scheduled_date ASC, r.name ASC',
      [fromDate],
    );
    return rows.map(ScheduledWorkout.fromMap).toList();
  }

  /// Planned entries before [fromDate] that were never fulfilled — "missed",
  /// most recent first.
  Future<List<ScheduledWorkout>> listMissed(String fromDate) async {
    final db = await _db;
    final rows = await db.rawQuery(
      "$_select WHERE s.status = 'planned' AND s.scheduled_date < ? "
      'ORDER BY s.scheduled_date DESC, r.name ASC',
      [fromDate],
    );
    return rows.map(ScheduledWorkout.fromMap).toList();
  }

  /// Planned entries on a single date.
  Future<List<ScheduledWorkout>> listForDate(String date) async {
    final db = await _db;
    final rows = await db.rawQuery(
      "$_select WHERE s.status = 'planned' AND s.scheduled_date = ? "
      'ORDER BY r.name ASC',
      [date],
    );
    return rows.map(ScheduledWorkout.fromMap).toList();
  }

  /// {iso-date: [routine names]} for planned entries in the given month — backs
  /// the calendar's pencilled-in markers.
  Future<Map<String, List<String>>> plannedForMonth(int year, int month) async {
    final db = await _db;
    final ym = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final rows = await db.rawQuery(
      "$_select WHERE s.status = 'planned' "
      "AND strftime('%Y-%m', s.scheduled_date) = ? ORDER BY s.scheduled_date",
      [ym],
    );
    final result = <String, List<String>>{};
    for (final row in rows) {
      final d = row['scheduled_date'] as String;
      result.putIfAbsent(d, () => []).add(row['routine_name'] as String);
    }
    return result;
  }

  /// Planned entries on/after [fromDate] that have a time set — the ones that
  /// warrant a reminder.
  Future<List<ScheduledWorkout>> listRemindable(String fromDate) async {
    final db = await _db;
    final rows = await db.rawQuery(
      "$_select WHERE s.status = 'planned' AND s.scheduled_time IS NOT NULL "
      'AND s.scheduled_date >= ? ORDER BY s.scheduled_date ASC',
      [fromDate],
    );
    return rows.map(ScheduledWorkout.fromMap).toList();
  }

  /// The soonest planned entry on/after [fromDate], or null — dashboard "next up".
  Future<ScheduledWorkout?> nextUpcoming(String fromDate) async {
    final db = await _db;
    final rows = await db.rawQuery(
      "$_select WHERE s.status = 'planned' AND s.scheduled_date >= ? "
      'ORDER BY s.scheduled_date ASC, r.name ASC LIMIT 1',
      [fromDate],
    );
    if (rows.isEmpty) return null;
    return ScheduledWorkout.fromMap(rows.first);
  }

  /// Marks the plan for [routineId] on [date] fulfilled, linking [completionId].
  /// A no-op when nothing was planned that day.
  Future<void> markFulfilled(int routineId, String date, int completionId) async {
    final db = await _db;
    await db.update(
      'scheduled_workouts',
      {'status': ScheduleStatus.done, 'completion_id': completionId},
      where: "routine_id = ? AND scheduled_date = ? AND status = 'planned'",
      whereArgs: [routineId, date],
    );
  }
}
