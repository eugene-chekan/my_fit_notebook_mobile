/// Pure filtering for the add-exercise autocomplete, kept out of the widget
/// so it's unit-testable without a database or emulator.
library;

/// Suggestions for [query] drawn from [catalog], excluding names already in
/// the current routine ([existing]) and — when it matches exactly — the
/// query itself (no point suggesting what's already typed in full).
///
/// Matching is case-insensitive substring. Prefix matches are surfaced
/// before mid-string matches; ties keep catalog order. An empty/blank query
/// yields nothing (autocomplete stays hidden until the user types).
List<String> filterExerciseSuggestions({
  required String query,
  required List<String> catalog,
  required Iterable<String> existing,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final taken = existing.map((e) => e.trim().toLowerCase()).toSet();

  final prefix = <String>[];
  final contains = <String>[];
  for (final name in catalog) {
    final lower = name.toLowerCase();
    if (taken.contains(lower)) continue;
    final idx = lower.indexOf(q);
    if (idx < 0) continue;
    if (lower == q) continue; // already fully typed
    (idx == 0 ? prefix : contains).add(name);
  }
  return [...prefix, ...contains];
}
