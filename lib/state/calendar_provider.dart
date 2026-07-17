import 'package:flutter/foundation.dart';

import '../data/repositories/completion_repository.dart';
import '../data/repositories/schedule_repository.dart';

/// Backs the calendar screen: which month is showing, which days have completed
/// workouts (trained-day dots), and which have planned ones (pencilled-in
/// rings).
class CalendarProvider extends ChangeNotifier {
  CalendarProvider({
    CompletionRepository? repository,
    ScheduleRepository? scheduleRepository,
  }) : _repository = repository ?? CompletionRepository(),
       _schedules = scheduleRepository ?? ScheduleRepository() {
    final now = DateTime.now();
    year = now.year;
    month = now.month;
  }

  final CompletionRepository _repository;
  final ScheduleRepository _schedules;

  late int year;
  late int month;
  Map<String, List<String>> routinesByDate = {};
  Map<String, List<String>> plannedByDate = {};
  bool loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    routinesByDate = await _repository.completionRoutinesForMonth(year, month);
    plannedByDate = await _schedules.plannedForMonth(year, month);
    loading = false;
    notifyListeners();
  }

  Future<void> nextMonth() async {
    month++;
    if (month > 12) {
      month = 1;
      year++;
    }
    await load();
  }

  Future<void> previousMonth() async {
    month--;
    if (month < 1) {
      month = 12;
      year--;
    }
    await load();
  }
}
