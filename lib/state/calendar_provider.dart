import 'package:flutter/foundation.dart';

import '../data/repositories/completion_repository.dart';

/// Backs the calendar screen: which month is showing, and which days in it
/// have completed workouts (mirrors the `/api/completions` lookup the web
/// app's header calendar dropdown uses).
class CalendarProvider extends ChangeNotifier {
  CalendarProvider({CompletionRepository? repository}) : _repository = repository ?? CompletionRepository() {
    final now = DateTime.now();
    year = now.year;
    month = now.month;
  }

  final CompletionRepository _repository;

  late int year;
  late int month;
  Map<String, List<String>> routinesByDate = {};
  bool loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    routinesByDate = await _repository.completionRoutinesForMonth(year, month);
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
