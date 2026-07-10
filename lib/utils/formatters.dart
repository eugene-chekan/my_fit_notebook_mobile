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

String _pad2(int n) => n.toString().padLeft(2, '0');
