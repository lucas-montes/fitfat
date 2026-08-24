/// Plain domain model for an exercise definition.
final class Exercise {
  final String id;
  final String name;
  final String exerciseType; // 'weightlifting' | 'cardio'

  // Catalog metadata (schema v8), populated for seeded exercises.
  final String? bodyPart;
  final String? equipment;
  final String? primaryMuscle;
  final String? secondaryMuscle;
  final List<String>? instructions;
  final List<String>? tips;
  final String? faqs;
  final List<String>? keywords;
  final String? imagePath; // local downloaded file (sync); null = none yet
  final String? videoPath; // local downloaded file (sync); null = none yet
  // Canonicalization fields (schema v10): mark one exercise as canonical per
  // group, link variants via similarTo, and allow user tags.
  final String? similarTo; // ID of canonical exercise this is a variant of
  final List<String>? tags; // User-defined tags
  final bool isCanonical; // True if this is the canonical exercise
  final DateTime createdAt;

  const Exercise({
    required this.id,
    required this.name,
    required this.exerciseType,
    this.bodyPart,
    this.equipment,
    this.primaryMuscle,
    this.secondaryMuscle,
    this.instructions,
    this.tips,
    this.faqs,
    this.keywords,
    this.imagePath,
    this.videoPath,
    this.similarTo,
    this.tags,
    this.isCanonical = true,
    required this.createdAt,
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? exerciseType,
    Object? bodyPart = _unset,
    Object? equipment = _unset,
    Object? primaryMuscle = _unset,
    Object? secondaryMuscle = _unset,
    Object? instructions = _unset,
    Object? tips = _unset,
    Object? faqs = _unset,
    Object? keywords = _unset,
    Object? imagePath = _unset,
    Object? videoPath = _unset,
    Object? similarTo = _unset,
    Object? tags = _unset,
    bool? isCanonical,
    DateTime? createdAt,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    exerciseType: exerciseType ?? this.exerciseType,
    bodyPart: identical(bodyPart, _unset) ? this.bodyPart : bodyPart as String?,
    equipment: identical(equipment, _unset)
        ? this.equipment
        : equipment as String?,
    primaryMuscle: identical(primaryMuscle, _unset)
        ? this.primaryMuscle
        : primaryMuscle as String?,
    secondaryMuscle: identical(secondaryMuscle, _unset)
        ? this.secondaryMuscle
        : secondaryMuscle as String?,
    instructions: identical(instructions, _unset)
        ? this.instructions
        : instructions as List<String>?,
    tips: identical(tips, _unset) ? this.tips : tips as List<String>?,
    faqs: identical(faqs, _unset) ? this.faqs : faqs as String?,
    keywords: identical(keywords, _unset)
        ? this.keywords
        : keywords as List<String>?,
    imagePath: identical(imagePath, _unset)
        ? this.imagePath
        : imagePath as String?,
    videoPath: identical(videoPath, _unset)
        ? this.videoPath
        : videoPath as String?,
    similarTo: identical(similarTo, _unset)
        ? this.similarTo
        : similarTo as String?,
    tags: identical(tags, _unset) ? this.tags : tags as List<String>?,
    isCanonical: isCanonical ?? this.isCanonical,
    createdAt: createdAt ?? this.createdAt,
  );

  static const _unset = Object();

  bool get isWeightlifting => exerciseType == 'weightlifting';
  bool get isCardio => exerciseType == 'cardio';
}
