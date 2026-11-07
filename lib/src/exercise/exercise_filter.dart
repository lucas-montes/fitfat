import '../models/exercise.dart';

/// Splits a comma-separated catalog value (e.g. "Quadriceps, Thighs") into
/// distinct, trimmed tags. Combined values are split so each real category is
/// its own filter option and chip.
List<String> splitTags(String? value) {
  if (value == null) return const [];
  final tags = <String>{
    for (final tag in value.split(','))
      if (tag.trim().isNotEmpty) tag.trim(),
  };
  return tags.toList();
}

/// Canonical label for an equipment tag, mirroring the build script's map so
/// combined values like "Assisted, Band" display and filter consistently with
/// the standalone "Resistance Band".
String canonicalEquipmentTag(String tag) {
  if (tag == 'Band') return 'Resistance Band';
  if (tag == 'Olympic barbell') return 'Barbell';
  return tag;
}

/// Distinct, sorted filter options derived from a loaded exercise list.
final class ExerciseFilterOptions {
  final List<String> types;
  final List<String> bodyParts;
  final List<String> equipments;
  final List<String> muscles;

  const ExerciseFilterOptions({
    required this.types,
    required this.bodyParts,
    required this.equipments,
    required this.muscles,
  });

  bool get isEmpty =>
      types.isEmpty &&
      bodyParts.isEmpty &&
      equipments.isEmpty &&
      muscles.isEmpty;
}

/// Builds the filter options from [exercises]: distinct types, body-part tags,
/// canonical equipment tags, and primary+secondary muscle tags.
ExerciseFilterOptions exerciseFilterOptions(List<Exercise> exercises) {
  final types = <String>{};
  final bodyParts = <String>{};
  final equipments = <String>{};
  final muscles = <String>{};
  for (final exercise in exercises) {
    types.add(exercise.exerciseType);
    bodyParts.addAll(splitTags(exercise.bodyPart));
    equipments.addAll(splitTags(exercise.equipment).map(canonicalEquipmentTag));
    muscles.addAll(splitTags(exercise.primaryMuscle));
    muscles.addAll(splitTags(exercise.secondaryMuscle));
  }
  int sort(String a, String b) => a.compareTo(b);
  return ExerciseFilterOptions(
    types: (types.toList()..sort(sort)),
    bodyParts: (bodyParts.toList()..sort(sort)),
    equipments: (equipments.toList()..sort(sort)),
    muscles: (muscles.toList()..sort(sort)),
  );
}

/// Match type for search ranking.
enum MatchType {
  /// Exact match: query == exercise name
  exact,

  /// Prefix match: exercise name starts with query
  prefix,

  /// Keyword match: query matches a keyword
  keyword,

  /// Word boundary match: query matches a whole word in name
  wordBoundary,

  /// Substring match: query appears anywhere in name
  substring,

  /// Muscle match: query matches primary or secondary muscle
  muscle,

  /// Fuzzy match: levenshtein distance (for typos)
  fuzzy,
}

/// Scored exercise result with match details for ranking.
final class ScoredExercise {
  final Exercise exercise;
  final int score;
  final MatchType matchType;
  final String matchedField;

  const ScoredExercise({
    required this.exercise,
    required this.score,
    required this.matchType,
    required this.matchedField,
  });
}

/// Interface for search ranking algorithms.
abstract class SearchRanker {
  /// Rank exercises by relevance to [query].
  /// Returns list sorted by score descending.
  List<ScoredExercise> rank(String query, List<Exercise> exercises);
}

/// Default search ranker implementing weighted relevance algorithm.
/// Scores: exact=1000, prefix=800, keyword=600, wordBoundary=400,
/// substring=200, muscle=100, fuzzy=10-30.
/// Bonuses: +50 for canonical, +20 for recently used, +10 for in workout.
/// Penalty: -100 for tagged as duplicate.
final class DefaultSearchRanker implements SearchRanker {
  const DefaultSearchRanker();

  @override
  List<ScoredExercise> rank(String query, List<Exercise> exercises) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return exercises
          .map(
            (e) => ScoredExercise(
              exercise: e,
              score: e.isCanonical ? 50 : 0,
              matchType: MatchType.fuzzy,
              matchedField: '',
            ),
          )
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));
    }

    final results = <ScoredExercise>[];
    for (final exercise in exercises) {
      final score = _scoreExercise(exercise, q);
      if (score > 0) {
        results.add(
          ScoredExercise(
            exercise: exercise,
            score: score,
            matchType: _matchType(exercise, q),
            matchedField: _matchedField(exercise, q),
          ),
        );
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  int _scoreExercise(Exercise exercise, String q) {
    int score = 0;
    final name = exercise.name.toLowerCase();
    final keywords = exercise.keywords ?? const <String>[];
    final primaryMuscle = exercise.primaryMuscle?.toLowerCase() ?? '';
    final secondaryMuscle = exercise.secondaryMuscle?.toLowerCase() ?? '';

    // Exact name match
    if (name == q) {
      score += 1000;
    }
    // Prefix match (name starts with query)
    else if (name.startsWith(q)) {
      score += 800;
    }
    // Keyword match
    else if (keywords.any((k) => k.toLowerCase() == q)) {
      score += 600;
    }
    // Word boundary match (query is a whole word in name)
    else if (RegExp(r'\b' + RegExp.escape(q) + r'\b').hasMatch(name)) {
      score += 400;
    }
    // Substring match
    else if (name.contains(q)) {
      score += 200;
    }
    // Muscle match
    else if (primaryMuscle.contains(q) || secondaryMuscle.contains(q)) {
      score += 100;
    }
    // Fuzzy match (simple levenshtein-like check for short queries)
    else if (q.length >= 3 && _levenshtein(name, q) <= 2) {
      score += 30 - _levenshtein(name, q) * 10;
    }

    // Bonuses
    if (exercise.isCanonical) score += 50;
    // TODO: Add recently used bonus when available
    // TODO: Add in-workout bonus when available

    // Penalty for variants tagged as duplicate
    if (exercise.similarTo != null) score -= 100;

    return score;
  }

  MatchType _matchType(Exercise exercise, String q) {
    final name = exercise.name.toLowerCase();
    final keywords = exercise.keywords ?? const <String>[];
    final primaryMuscle = exercise.primaryMuscle?.toLowerCase() ?? '';
    final secondaryMuscle = exercise.secondaryMuscle?.toLowerCase() ?? '';

    if (name == q) return MatchType.exact;
    if (name.startsWith(q)) return MatchType.prefix;
    if (keywords.any((k) => k.toLowerCase() == q)) return MatchType.keyword;
    if (RegExp(r'\b' + RegExp.escape(q) + r'\b').hasMatch(name)) {
      return MatchType.wordBoundary;
    }
    if (name.contains(q)) return MatchType.substring;
    if (primaryMuscle.contains(q) || secondaryMuscle.contains(q)) {
      return MatchType.muscle;
    }
    return MatchType.fuzzy;
  }

  String _matchedField(Exercise exercise, String q) {
    final name = exercise.name.toLowerCase();
    final keywords = exercise.keywords ?? const <String>[];
    final primaryMuscle = exercise.primaryMuscle?.toLowerCase() ?? '';
    final secondaryMuscle = exercise.secondaryMuscle?.toLowerCase() ?? '';

    if (name == q ||
        name.startsWith(q) ||
        RegExp(r'\b' + RegExp.escape(q) + r'\b').hasMatch(name) ||
        name.contains(q)) {
      return 'name';
    }
    if (keywords.any((k) => k.toLowerCase() == q)) return 'keywords';
    if (primaryMuscle.contains(q) || secondaryMuscle.contains(q)) {
      return 'muscle';
    }
    return 'fuzzy';
  }

  /// Simple Levenshtein distance for fuzzy matching.
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );
    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[a.length][b.length];
  }
}

/// Applies the search query and tag filters to [exercises]. An empty filter
/// set means "any"; filters are AND-ed together.
///
/// [query] matches the exercise name, any keyword, or any primary/secondary
/// muscle (case-insensitive). [types]/[bodyParts]/[equipments]/[muscles] match
/// on the corresponding tags.
///
/// [includeVariants] - if false (default), only canonical exercises are returned.
/// If true, variants (exercises with similarTo set) are also included.
List<Exercise> filterExercises(
  List<Exercise> exercises, {
  String query = '',
  Set<String> types = const {},
  Set<String> bodyParts = const {},
  Set<String> equipments = const {},
  Set<String> muscles = const {},
  bool includeVariants = false,
}) {
  final q = query.trim().toLowerCase();
  return exercises.where((exercise) {
    // By default, only show canonical exercises
    if (!includeVariants && !exercise.isCanonical) {
      return false;
    }
    if (types.isNotEmpty && !types.contains(exercise.exerciseType)) {
      return false;
    }
    if (bodyParts.isNotEmpty &&
        splitTags(exercise.bodyPart).toSet().intersection(bodyParts).isEmpty) {
      return false;
    }
    if (equipments.isNotEmpty &&
        splitTags(
          exercise.equipment,
        ).map(canonicalEquipmentTag).toSet().intersection(equipments).isEmpty) {
      return false;
    }
    if (muscles.isNotEmpty) {
      final muscleTags = {
        ...splitTags(exercise.primaryMuscle),
        ...splitTags(exercise.secondaryMuscle),
      };
      if (muscleTags.intersection(muscles).isEmpty) return false;
    }
    if (q.isNotEmpty) {
      final nameMatch = exercise.name.toLowerCase().contains(q);
      final keywordMatch = (exercise.keywords ?? const []).any(
        (k) => k.toLowerCase().contains(q),
      );
      final muscleMatch =
          (exercise.primaryMuscle ?? '').toLowerCase().contains(q) ||
          (exercise.secondaryMuscle ?? '').toLowerCase().contains(q);
      if (!nameMatch && !keywordMatch && !muscleMatch) return false;
    }
    return true;
  }).toList();
}
