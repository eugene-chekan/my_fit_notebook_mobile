/// Dart port of filters.py so displayed dates/durations match the web app.
library;

String formatCompletionDt(String value) {
  try {
    if (value.contains('T')) {
      final dt = DateTime.parse(value);
      return '${_pad2(dt.day)}.${_pad2(dt.month)}.${dt.year} ${_pad2(dt.hour)}:${_pad2(dt.minute)}';
    }
    final d = DateTime.parse(value);
    return '${_pad2(d.day)}.${_pad2(d.month)}.${d.year}';
  } catch (_) {
    return value;
  }
}

String formatStartedAt(String value) {
  try {
    final dt = DateTime.parse(value);
    return '${_pad2(dt.hour)}:${_pad2(dt.minute)}';
  } catch (_) {
    return value;
  }
}

String formatDurationMinutes(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m != 0 ? '${h}h ${m}m' : '${h}h';
}

String formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  if (minutes < 60) {
    return secs == 0 ? '${minutes}m' : '${minutes}m ${secs}s';
  }
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (mins == 0 && secs == 0) return '${hours}h';
  if (secs == 0) return '${hours}h ${mins}m';
  return '${hours}h ${mins}m ${secs}s';
}

/// "Friday, July 10, 2026" — the handwritten date in the page header,
/// mirroring inject_notebook_date in the Flask app's app.py.
String notebookDateLabel(DateTime d) {
  const weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// Whole years since a yyyy-MM-dd birth date; null when unset/malformed.
int? ageFromBirthDate(String? birthIso) {
  if (birthIso == null) return null;
  try {
    final birth = DateTime.parse(birthIso);
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age < 0 ? null : age;
  } catch (_) {
    return null;
  }
}

/// Live workout clock: "mm:ss", growing to "h:mm:ss" past an hour.
String formatClock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '$h:${_pad2(m)}:${_pad2(s)}';
  return '${_pad2(m)}:${_pad2(s)}';
}

String _pad2(int n) => n.toString().padLeft(2, '0');
