// Build script: reads data/parsed/*.json (git-ignored source) and writes the
// bundled SQLite catalog assets/exercises.db with a schema matching the live
// `exercises` table (v8). All rows are is_locked = 1 and use deterministic ids
// (the parsed-filename slug), so the import step (T08) can skip-by-name.
//
// Metadata is normalized here so the app gets consistent labels:
//   - equipment synonyms canonicalized (Band/Resistance Band, Olympic barbell)
//   - body_part / muscle values kept as authored but whitespace-collapsed
//   - exercise type from a widened cardio heuristic + body_part focus
//   - faqs parsed into a structured JSON array [{q,a}, ...] (raw fallback)
//   - videoPath set only for slugs in tool/video_allowlist.txt
//
// Usage: dart run tool/build_catalog.dart
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Deterministic createdAt for every catalog row so rebuilds are reproducible.
const int catalogEpochMillis = 1767225600000; // 2026-01-01T00:00:00Z

/// Cardio heuristic v2: if the exercise name matches any of these words/phrases
/// it is typed 'cardio'; body_part focus values (Cardio/Plyometrics) also mark
/// an exercise cardio. Everything else defaults to 'weightlifting'.
final RegExp cardioRe = RegExp(
  r'\b(run|runs|running|runner|jog|jogs|jogging|jogger|'
  r'sprint|sprints|sprinting|walk|walks|walking|walker|'
  r'hike|hikes|hiking|cycle|cycles|cycling|cyclist|bike|bikes|biking|'
  r'riding|rower|rowing|rowing machine|erg|ergometer|'
  r'jump rope|jump-rope|jumping rope|rope jumping|skipping|skip|'
  r'burpee|burpees|stair|stairs|staircase|stair climbing|stair climber|'
  r'climb|climbs|climbing|swim|swims|swimming|swimmer|'
  r'elliptical|treadmill|cardio|aerobic|aerobics|'
  r'hiit|jump jack|jumping jack|jacks|skater|skating|kayak|kayaking|canoe|'
  r'canoeing|boxing|kickboxing|spinning|spin bike|dance|dancing|'
  r'box jump|jump box|jump squat|squat jump|jumping|plyo|plyometric|'
  r'step up|step-up|stepper|high knee|mountain climber|stationary bike|'
  r'recumbent|skiing|snowboarding|sled|sledging|'
  r'rope)\b',
  caseSensitive: false,
);

/// Body-part "focus" values that classify an exercise as cardio regardless of
/// its name (the catalog uses these as pseudo body parts).
const Set<String> _cardioFocus = {'cardio', 'plyometrics'};

/// Canonical labels for equipment synonyms. Values absent here pass through
/// unchanged (whitespace-collapsed). Add a mapping when two labels mean the
/// same thing in the source data.
const Map<String, String> _equipmentCanonical = {
  'Band': 'Resistance Band',
  'Olympic barbell': 'Barbell',
};

String? _normalizeEquipment(Object? value) {
  final raw = _nullIfEmpty(value);
  if (raw == null) return null;
  final collapsed = _collapseWhitespace(raw);
  return _equipmentCanonical[collapsed] ?? collapsed;
}

String? _normalizeBodyPart(Object? value) {
  final raw = _nullIfEmpty(value);
  if (raw == null) return null;
  return _collapseWhitespace(raw);
}

String _classifyType(String name, String? bodyPart) {
  if (cardioRe.hasMatch(name.toLowerCase())) return 'cardio';
  final focus = bodyPart?.toLowerCase();
  if (focus != null && _cardioFocus.contains(focus)) return 'cardio';
  return 'weightlifting';
}

/// Best-effort split of a scraped FAQ blob into structured Q/A pairs.
///
/// The source blobs look like `NAME\nFAQs\nQ1...\n?\nA1...\nQ2...\n?\nA2...`.
/// Returns the raw [blob] when fewer than one pair can be parsed, so nothing is
/// lost (the app renders structured JSON when present, styled raw otherwise).
String? _parseFaqs(Object? value) {
  final raw = _nullIfEmpty(value);
  if (raw == null) return null;

  final lines = raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  // Skip the leading title + "FAQs" header lines.
  var start = 0;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].toLowerCase() == 'faqs') {
      start = i + 1;
      break;
    }
  }

  final starterRe = RegExp(
    r'^(can|what|is|are|how|why|do|does|should|when|which)\b',
    caseSensitive: false,
  );

  final pairs = <Map<String, String>>[];
  var question = <String>[];
  var answer = <String>[];
  var inAnswer = false;

  void flush() {
    if (question.isEmpty) return;
    final q = question
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\?+\s*$'), '');
    final a = answer.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (q.isNotEmpty && a.isNotEmpty) {
      pairs.add({'q': q, 'a': a});
    }
    question = [];
    answer = [];
    inAnswer = false;
  }

  for (final line in lines.skip(start)) {
    final terminator = line == '?' || line.endsWith('?');
    if (!inAnswer) {
      if (terminator) {
        question.add(
          line.endsWith('?') && line != '?'
              ? line.substring(0, line.length - 1)
              : '',
        );
        inAnswer = true;
      } else {
        question.add(line);
      }
    } else if (starterRe.hasMatch(line)) {
      flush();
      question.add(line);
    } else {
      answer.add(line);
    }
  }
  flush();

  if (pairs.isEmpty) return raw;
  return jsonEncode(pairs);
}

String _collapseWhitespace(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

void main() {
  final parsedDir = Directory('data/parsed');
  if (!parsedDir.existsSync()) {
    stderr.writeln('data/parsed not found — run from the project root.');
    exit(1);
  }

  final allowlistFile = File('tool/video_allowlist.txt');
  if (!allowlistFile.existsSync()) {
    stderr.writeln('tool/video_allowlist.txt not found.');
    exit(1);
  }
  final videoAllowlist = allowlistFile
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toSet();

  final imagesDir = Directory('data/images');
  final videosDir = Directory('data/videos');
  final outDir = Directory('assets');
  outDir.createSync(recursive: true);

  final exercises = Directory('assets/exercises');
  exercises.createSync(recursive: true);
  final imagesOut = Directory('assets/exercises/images');
  final videosOut = Directory('assets/exercises/videos');
  imagesOut.createSync(recursive: true);
  videosOut.createSync(recursive: true);

  final files =
      parsedDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final dbFile = File('assets/exercises.db');
  if (dbFile.existsSync()) dbFile.deleteSync();

  final db = sqlite3.open(dbFile.path);
  db.execute('PRAGMA journal_mode = OFF');
  db.execute('''
    CREATE TABLE exercises (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      exerciseType TEXT NOT NULL,
      isLocked INTEGER NOT NULL DEFAULT 0,
      bodyPart TEXT,
      equipment TEXT,
      primaryMuscle TEXT,
      secondaryMuscle TEXT,
      instructions TEXT,
      tips TEXT,
      faqs TEXT,
      keywords TEXT,
      imagePath TEXT,
      videoPath TEXT,
      createdAt INTEGER NOT NULL
    )
  ''');

  final insert = db.prepare('''
    INSERT INTO exercises (
      id, name, exerciseType, isLocked, bodyPart, equipment,
      primaryMuscle, secondaryMuscle, instructions, tips, faqs, keywords,
      imagePath, videoPath, createdAt
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''');

  var cardio = 0;
  var weightlifting = 0;
  var withImage = 0;
  var withVideo = 0;
  var faqParsed = 0;
  var skipped = 0;

  db.execute('BEGIN');
  try {
    for (final file in files) {
      final slug = file.path.split('/').last.replaceAll(RegExp(r'\.json$'), '');
      final Map<String, dynamic> json;
      try {
        final decoded = jsonDecode(file.readAsStringSync());
        if (decoded is! Map<String, dynamic>) {
          stderr.writeln('WARN $slug: not a JSON object, skipping');
          skipped++;
          continue;
        }
        json = decoded;
      } on FormatException catch (e) {
        stderr.writeln('WARN $slug: malformed JSON ($e), skipping');
        skipped++;
        continue;
      }

      final name = (json['name'] as String?)?.trim() ?? slug;
      final bodyPart = _normalizeBodyPart(json['body_part']);
      final exerciseType = _classifyType(name, bodyPart);

      final instructions = json['instructions'];
      final tips = json['tips'];
      final keywords = json['keywords'];
      final faqs = _parseFaqs(json['faqs']);

      final imagePath = _assetIfExists(imagesDir, slug, '.png', imagesOut);
      final videoPath = videoAllowlist.contains(slug)
          ? _assetIfExists(videosDir, slug, '.mp4', videosOut)
          : null;

      insert.execute([
        slug,
        name,
        exerciseType,
        1,
        bodyPart,
        _normalizeEquipment(json['equipment']),
        _nullIfEmpty(json['primary']),
        _nullIfEmpty(json['secondary']),
        _encode(instructions),
        _encode(tips),
        faqs,
        _encode(keywords),
        imagePath,
        videoPath,
        catalogEpochMillis,
      ]);

      if (exerciseType == 'cardio') {
        cardio++;
      } else {
        weightlifting++;
      }
      if (imagePath != null) withImage++;
      if (videoPath != null) withVideo++;
      if (faqs != null && faqs.startsWith('[')) faqParsed++;
    }
    db.execute('COMMIT');
  } catch (_) {
    db.execute('ROLLBACK');
    rethrow;
  } finally {
    insert.dispose();
  }

  final count = db.select('SELECT COUNT(*) AS c FROM exercises').first['c'];
  db.dispose();

  stdout.writeln(
    'Wrote $dbFile with $count exercises '
    '($cardio cardio / $weightlifting weightlifting, '
    '$withImage with image, $withVideo with video '
    '(${videoAllowlist.length} allowlisted), '
    '$faqParsed with parsed FAQs, $skipped skipped).',
  );
}

String? _assetIfExists(Directory dir, String slug, String ext, Directory _) {
  final file = File('${dir.path}/$slug$ext');
  return file.existsSync()
      ? 'assets/exercises/${dir.path.split('/').last}/$slug$ext'
      : null;
}

String? _encode(Object? value) {
  if (value is List && value.isNotEmpty) return jsonEncode(value);
  return null;
}

String? _nullIfEmpty(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}
