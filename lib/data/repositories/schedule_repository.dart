import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/schedule_rule.dart';
import '../models/scheduled_workout.dart';
import '../../utils/recurrence.dart';

/// SQL access for planned workouts (`scheduled_workouts`) and their repeating
/// rules (`schedule_rules`). Rows always join the routine name for display.
class ScheduleRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  /// How far ahead recurring rules are materialised into concrete occurrences.
  static const horizonDays = 56;

  static const _select = '''
    SELECT s.id, s.routine_id, s.scheduled_date, s.scheduled_time, s.status,
           s.completion_id, s.rule_id, r.name AS routine_name
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
  Future<bool> addSchedule(
    int routineId,
    String date, {
    String? time,
    int? ruleId,
  }) async {
    final db = await _db;
    try {
      await db.insert('scheduled_workouts', {
        'routine_id': routineId,
        'scheduled_date': date,
        'scheduled_time': time,
        'status': ScheduleStatus.planned,
        'rule_id': ruleId,
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

  // ── Repeating rules ──────────────────────────────────────────────────────

  static const _ruleSelect = '''
    SELECT rl.id, rl.routine_id, rl.freq, rl.weekdays, rl.scheduled_time,
           rl.start_date, rl.generated_through, rl.active, r.name AS routine_name
    FROM schedule_rules rl
    JOIN routines r ON rl.routine_id = r.id
  ''';

  /// Creates a weekly recurrence and immediately materialises its occurrences
  /// out to the horizon. Returns the new rule's id.
  Future<int> addRule(
    int routineId,
    Set<int> weekdays, {
    String? time,
    DateTime? startFrom,
  }) async {
    final db = await _db;
    final start = startFrom ?? DateTime.now();
    final id = await db.insert('schedule_rules', {
      'routine_id': routineId,
      'freq': 'weekly',
      'weekdays': encodeWeekdays(weekdays),
      'scheduled_time': time,
      'start_date': isoDate(start),
      'generated_through': null,
      'active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
    await topUpOccurrences();
    return id;
  }

  Future<List<ScheduleRule>> listActiveRules() async {
    final db = await _db;
    final rows = await db.rawQuery('$_ruleSelect WHERE rl.active = 1');
    return rows.map(ScheduleRule.fromMap).toList();
  }

  /// Drops a rule and, by the ON DELETE CASCADE, every occurrence it generated
  /// — including past ones. Prefer [deleteSeriesFuture] to keep history.
  Future<void> deleteRule(int ruleId) async {
    final db = await _db;
    await db.delete('schedule_rules', where: 'id = ?', whereArgs: [ruleId]);
  }

  /// Ends a series without touching its past: deletes only the still-planned
  /// occurrences on/after [fromDate], then deactivates the rule so the rolling
  /// top-up stops regenerating it. Completed/missed occurrences stay in place.
  Future<void> deleteSeriesFuture(int ruleId, String fromDate) async {
    final db = await _db;
    await db.delete(
      'scheduled_workouts',
      where: "rule_id = ? AND status = 'planned' AND scheduled_date >= ?",
      whereArgs: [ruleId, fromDate],
    );
    await db.update(
      'schedule_rules',
      {'active': 0},
      where: 'id = ?',
      whereArgs: [ruleId],
    );
  }

  /// Materialise each active rule's occurrences up to today+[horizonDays].
  ///
  /// Only dates strictly after a rule's `generated_through` watermark (or its
  /// start date on first run) are generated, so a manually deleted occurrence
  /// inside the already-covered range is never resurrected. Each insert uses
  /// [addSchedule], which no-ops on the UNIQUE(routine_id, date) clash — so a
  /// day already booked (by hand or another rule) is left untouched. Idempotent
  /// and safe to call on every load / launch.
  Future<void> topUpOccurrences() async {
    final db = await _db;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final horizonEnd = today.add(const Duration(days: horizonDays));
    final horizonIso = isoDate(horizonEnd);

    final rules = await listActiveRules();
    for (final rule in rules) {
      if (rule.weekdays.isEmpty) continue;
      // Start the day after the watermark; never before the rule's start or
      // today (past occurrences that never got generated aren't back-filled).
      final startCandidates = <DateTime>[
        DateTime.parse(rule.startDate),
        today,
      ];
      if (rule.generatedThrough != null) {
        startCandidates.add(
          DateTime.parse(rule.generatedThrough!).add(const Duration(days: 1)),
        );
      }
      final from = startCandidates.reduce((a, b) => a.isAfter(b) ? a : b);
      final dates = weeklyOccurrences(
        weekdays: rule.weekdays,
        from: from,
        to: horizonEnd,
      );
      for (final d in dates) {
        await addSchedule(
          rule.routineId,
          isoDate(d),
          time: rule.scheduledTime,
          ruleId: rule.id,
        );
      }
      await db.update(
        'schedule_rules',
        {'generated_through': horizonIso},
        where: 'id = ?',
        whereArgs: [rule.id],
      );
    }
  }
}
