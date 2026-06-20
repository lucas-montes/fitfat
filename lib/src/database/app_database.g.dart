// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('weightlifting'),
  );
  static const VerificationMeta _metMeta = const VerificationMeta('met');
  @override
  late final GeneratedColumn<double> met = GeneratedColumn<double>(
    'met',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(5.0),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creatorIdMeta = const VerificationMeta(
    'creatorId',
  );
  @override
  late final GeneratedColumn<String> creatorId = GeneratedColumn<String>(
    'creator_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    met,
    description,
    imageUrl,
    creatorId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('met')) {
      context.handle(
        _metMeta,
        met.isAcceptableOrUnknown(data['met']!, _metMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('creator_id')) {
      context.handle(
        _creatorIdMeta,
        creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      met: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}met'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      creatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_id'],
      ),
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final String id;
  final String name;
  final String type;
  final double met;
  final String description;
  final String? imageUrl;
  final String? creatorId;
  const Exercise({
    required this.id,
    required this.name,
    required this.type,
    required this.met,
    required this.description,
    this.imageUrl,
    this.creatorId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['met'] = Variable<double>(met);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || creatorId != null) {
      map['creator_id'] = Variable<String>(creatorId);
    }
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      met: Value(met),
      description: Value(description),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      creatorId: creatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorId),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      met: serializer.fromJson<double>(json['met']),
      description: serializer.fromJson<String>(json['description']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      creatorId: serializer.fromJson<String?>(json['creatorId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'met': serializer.toJson<double>(met),
      'description': serializer.toJson<String>(description),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'creatorId': serializer.toJson<String?>(creatorId),
    };
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? type,
    double? met,
    String? description,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> creatorId = const Value.absent(),
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    met: met ?? this.met,
    description: description ?? this.description,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    creatorId: creatorId.present ? creatorId.value : this.creatorId,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      met: data.met.present ? data.met.value : this.met,
      description: data.description.present
          ? data.description.value
          : this.description,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('met: $met, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('creatorId: $creatorId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, met, description, imageUrl, creatorId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.met == this.met &&
          other.description == this.description &&
          other.imageUrl == this.imageUrl &&
          other.creatorId == this.creatorId);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<double> met;
  final Value<String> description;
  final Value<String?> imageUrl;
  final Value<String?> creatorId;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.met = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String name,
    this.type = const Value.absent(),
    this.met = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<double>? met,
    Expression<String>? description,
    Expression<String>? imageUrl,
    Expression<String>? creatorId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (met != null) 'met': met,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (creatorId != null) 'creator_id': creatorId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<double>? met,
    Value<String>? description,
    Value<String?>? imageUrl,
    Value<String?>? creatorId,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      met: met ?? this.met,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      creatorId: creatorId ?? this.creatorId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (met.present) {
      map['met'] = Variable<double>(met.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('met: $met, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('creatorId: $creatorId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseBodyPartsTable extends ExerciseBodyParts
    with TableInfo<$ExerciseBodyPartsTable, ExerciseBodyPart> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseBodyPartsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _bodyPartMeta = const VerificationMeta(
    'bodyPart',
  );
  @override
  late final GeneratedColumn<String> bodyPart = GeneratedColumn<String>(
    'body_part',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [exerciseId, bodyPart];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_body_parts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseBodyPart> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('body_part')) {
      context.handle(
        _bodyPartMeta,
        bodyPart.isAcceptableOrUnknown(data['body_part']!, _bodyPartMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyPartMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseId, bodyPart};
  @override
  ExerciseBodyPart map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseBodyPart(
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      bodyPart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_part'],
      )!,
    );
  }

  @override
  $ExerciseBodyPartsTable createAlias(String alias) {
    return $ExerciseBodyPartsTable(attachedDatabase, alias);
  }
}

class ExerciseBodyPart extends DataClass
    implements Insertable<ExerciseBodyPart> {
  final String exerciseId;
  final String bodyPart;
  const ExerciseBodyPart({required this.exerciseId, required this.bodyPart});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<String>(exerciseId);
    map['body_part'] = Variable<String>(bodyPart);
    return map;
  }

  ExerciseBodyPartsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseBodyPartsCompanion(
      exerciseId: Value(exerciseId),
      bodyPart: Value(bodyPart),
    );
  }

  factory ExerciseBodyPart.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseBodyPart(
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      bodyPart: serializer.fromJson<String>(json['bodyPart']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<String>(exerciseId),
      'bodyPart': serializer.toJson<String>(bodyPart),
    };
  }

  ExerciseBodyPart copyWith({String? exerciseId, String? bodyPart}) =>
      ExerciseBodyPart(
        exerciseId: exerciseId ?? this.exerciseId,
        bodyPart: bodyPart ?? this.bodyPart,
      );
  ExerciseBodyPart copyWithCompanion(ExerciseBodyPartsCompanion data) {
    return ExerciseBodyPart(
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      bodyPart: data.bodyPart.present ? data.bodyPart.value : this.bodyPart,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseBodyPart(')
          ..write('exerciseId: $exerciseId, ')
          ..write('bodyPart: $bodyPart')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exerciseId, bodyPart);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseBodyPart &&
          other.exerciseId == this.exerciseId &&
          other.bodyPart == this.bodyPart);
}

class ExerciseBodyPartsCompanion extends UpdateCompanion<ExerciseBodyPart> {
  final Value<String> exerciseId;
  final Value<String> bodyPart;
  final Value<int> rowid;
  const ExerciseBodyPartsCompanion({
    this.exerciseId = const Value.absent(),
    this.bodyPart = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseBodyPartsCompanion.insert({
    required String exerciseId,
    required String bodyPart,
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       bodyPart = Value(bodyPart);
  static Insertable<ExerciseBodyPart> custom({
    Expression<String>? exerciseId,
    Expression<String>? bodyPart,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (bodyPart != null) 'body_part': bodyPart,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseBodyPartsCompanion copyWith({
    Value<String>? exerciseId,
    Value<String>? bodyPart,
    Value<int>? rowid,
  }) {
    return ExerciseBodyPartsCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      bodyPart: bodyPart ?? this.bodyPart,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (bodyPart.present) {
      map['body_part'] = Variable<String>(bodyPart.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseBodyPartsCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('bodyPart: $bodyPart, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutsTable extends Workouts
    with TableInfo<$WorkoutsTable, WorkoutRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    scheduledDate,
    startedAt,
    completedAt,
    notes,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }
}

class WorkoutRow extends DataClass implements Insertable<WorkoutRow> {
  final String id;
  final String name;
  final DateTime? scheduledDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final String source;
  const WorkoutRow({
    required this.id,
    required this.name,
    this.scheduledDate,
    this.startedAt,
    this.completedAt,
    this.notes,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || scheduledDate != null) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['source'] = Variable<String>(source);
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      name: Value(name),
      scheduledDate: scheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDate),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      source: Value(source),
    );
  }

  factory WorkoutRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      scheduledDate: serializer.fromJson<DateTime?>(json['scheduledDate']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'scheduledDate': serializer.toJson<DateTime?>(scheduledDate),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'notes': serializer.toJson<String?>(notes),
      'source': serializer.toJson<String>(source),
    };
  }

  WorkoutRow copyWith({
    String? id,
    String? name,
    Value<DateTime?> scheduledDate = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? source,
  }) => WorkoutRow(
    id: id ?? this.id,
    name: name ?? this.name,
    scheduledDate: scheduledDate.present
        ? scheduledDate.value
        : this.scheduledDate,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    notes: notes.present ? notes.value : this.notes,
    source: source ?? this.source,
  );
  WorkoutRow copyWithCompanion(WorkoutsCompanion data) {
    return WorkoutRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('notes: $notes, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    scheduledDate,
    startedAt,
    completedAt,
    notes,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.scheduledDate == this.scheduledDate &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.notes == this.notes &&
          other.source == this.source);
}

class WorkoutsCompanion extends UpdateCompanion<WorkoutRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime?> scheduledDate;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> notes;
  final Value<String> source;
  final Value<int> rowid;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    required String id,
    required String name,
    this.scheduledDate = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<WorkoutRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? scheduledDate,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? notes,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (notes != null) 'notes': notes,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime?>? scheduledDate,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? completedAt,
    Value<String?>? notes,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeightSetsTable extends WeightSets
    with TableInfo<$WeightSetsTable, WeightSetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workouts (id)',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedRepsMeta = const VerificationMeta(
    'plannedReps',
  );
  @override
  late final GeneratedColumn<int> plannedReps = GeneratedColumn<int>(
    'planned_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedWeightKgMeta = const VerificationMeta(
    'plannedWeightKg',
  );
  @override
  late final GeneratedColumn<double> plannedWeightKg = GeneratedColumn<double>(
    'planned_weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedRestSecondsMeta =
      const VerificationMeta('plannedRestSeconds');
  @override
  late final GeneratedColumn<int> plannedRestSeconds = GeneratedColumn<int>(
    'planned_rest_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualRepsMeta = const VerificationMeta(
    'actualReps',
  );
  @override
  late final GeneratedColumn<int> actualReps = GeneratedColumn<int>(
    'actual_reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualWeightKgMeta = const VerificationMeta(
    'actualWeightKg',
  );
  @override
  late final GeneratedColumn<double> actualWeightKg = GeneratedColumn<double>(
    'actual_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutId,
    exerciseId,
    sortOrder,
    plannedReps,
    plannedWeightKg,
    plannedRestSeconds,
    actualReps,
    actualWeightKg,
    completedAt,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightSetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('planned_reps')) {
      context.handle(
        _plannedRepsMeta,
        plannedReps.isAcceptableOrUnknown(
          data['planned_reps']!,
          _plannedRepsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedRepsMeta);
    }
    if (data.containsKey('planned_weight_kg')) {
      context.handle(
        _plannedWeightKgMeta,
        plannedWeightKg.isAcceptableOrUnknown(
          data['planned_weight_kg']!,
          _plannedWeightKgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedWeightKgMeta);
    }
    if (data.containsKey('planned_rest_seconds')) {
      context.handle(
        _plannedRestSecondsMeta,
        plannedRestSeconds.isAcceptableOrUnknown(
          data['planned_rest_seconds']!,
          _plannedRestSecondsMeta,
        ),
      );
    }
    if (data.containsKey('actual_reps')) {
      context.handle(
        _actualRepsMeta,
        actualReps.isAcceptableOrUnknown(data['actual_reps']!, _actualRepsMeta),
      );
    }
    if (data.containsKey('actual_weight_kg')) {
      context.handle(
        _actualWeightKgMeta,
        actualWeightKg.isAcceptableOrUnknown(
          data['actual_weight_kg']!,
          _actualWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeightSetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightSetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      plannedReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_reps'],
      )!,
      plannedWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}planned_weight_kg'],
      )!,
      plannedRestSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_rest_seconds'],
      ),
      actualReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_reps'],
      ),
      actualWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}actual_weight_kg'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $WeightSetsTable createAlias(String alias) {
    return $WeightSetsTable(attachedDatabase, alias);
  }
}

class WeightSetRow extends DataClass implements Insertable<WeightSetRow> {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int sortOrder;
  final int plannedReps;
  final double plannedWeightKg;
  final int? plannedRestSeconds;
  final int? actualReps;
  final double? actualWeightKg;
  final DateTime? completedAt;
  final String? notes;
  const WeightSetRow({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.sortOrder,
    required this.plannedReps,
    required this.plannedWeightKg,
    this.plannedRestSeconds,
    this.actualReps,
    this.actualWeightKg,
    this.completedAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_id'] = Variable<String>(workoutId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['planned_reps'] = Variable<int>(plannedReps);
    map['planned_weight_kg'] = Variable<double>(plannedWeightKg);
    if (!nullToAbsent || plannedRestSeconds != null) {
      map['planned_rest_seconds'] = Variable<int>(plannedRestSeconds);
    }
    if (!nullToAbsent || actualReps != null) {
      map['actual_reps'] = Variable<int>(actualReps);
    }
    if (!nullToAbsent || actualWeightKg != null) {
      map['actual_weight_kg'] = Variable<double>(actualWeightKg);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  WeightSetsCompanion toCompanion(bool nullToAbsent) {
    return WeightSetsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      exerciseId: Value(exerciseId),
      sortOrder: Value(sortOrder),
      plannedReps: Value(plannedReps),
      plannedWeightKg: Value(plannedWeightKg),
      plannedRestSeconds: plannedRestSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedRestSeconds),
      actualReps: actualReps == null && nullToAbsent
          ? const Value.absent()
          : Value(actualReps),
      actualWeightKg: actualWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(actualWeightKg),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory WeightSetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightSetRow(
      id: serializer.fromJson<String>(json['id']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      plannedReps: serializer.fromJson<int>(json['plannedReps']),
      plannedWeightKg: serializer.fromJson<double>(json['plannedWeightKg']),
      plannedRestSeconds: serializer.fromJson<int?>(json['plannedRestSeconds']),
      actualReps: serializer.fromJson<int?>(json['actualReps']),
      actualWeightKg: serializer.fromJson<double?>(json['actualWeightKg']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutId': serializer.toJson<String>(workoutId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'plannedReps': serializer.toJson<int>(plannedReps),
      'plannedWeightKg': serializer.toJson<double>(plannedWeightKg),
      'plannedRestSeconds': serializer.toJson<int?>(plannedRestSeconds),
      'actualReps': serializer.toJson<int?>(actualReps),
      'actualWeightKg': serializer.toJson<double?>(actualWeightKg),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  WeightSetRow copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    int? sortOrder,
    int? plannedReps,
    double? plannedWeightKg,
    Value<int?> plannedRestSeconds = const Value.absent(),
    Value<int?> actualReps = const Value.absent(),
    Value<double?> actualWeightKg = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => WeightSetRow(
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    exerciseId: exerciseId ?? this.exerciseId,
    sortOrder: sortOrder ?? this.sortOrder,
    plannedReps: plannedReps ?? this.plannedReps,
    plannedWeightKg: plannedWeightKg ?? this.plannedWeightKg,
    plannedRestSeconds: plannedRestSeconds.present
        ? plannedRestSeconds.value
        : this.plannedRestSeconds,
    actualReps: actualReps.present ? actualReps.value : this.actualReps,
    actualWeightKg: actualWeightKg.present
        ? actualWeightKg.value
        : this.actualWeightKg,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    notes: notes.present ? notes.value : this.notes,
  );
  WeightSetRow copyWithCompanion(WeightSetsCompanion data) {
    return WeightSetRow(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      plannedReps: data.plannedReps.present
          ? data.plannedReps.value
          : this.plannedReps,
      plannedWeightKg: data.plannedWeightKg.present
          ? data.plannedWeightKg.value
          : this.plannedWeightKg,
      plannedRestSeconds: data.plannedRestSeconds.present
          ? data.plannedRestSeconds.value
          : this.plannedRestSeconds,
      actualReps: data.actualReps.present
          ? data.actualReps.value
          : this.actualReps,
      actualWeightKg: data.actualWeightKg.present
          ? data.actualWeightKg.value
          : this.actualWeightKg,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightSetRow(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('plannedReps: $plannedReps, ')
          ..write('plannedWeightKg: $plannedWeightKg, ')
          ..write('plannedRestSeconds: $plannedRestSeconds, ')
          ..write('actualReps: $actualReps, ')
          ..write('actualWeightKg: $actualWeightKg, ')
          ..write('completedAt: $completedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutId,
    exerciseId,
    sortOrder,
    plannedReps,
    plannedWeightKg,
    plannedRestSeconds,
    actualReps,
    actualWeightKg,
    completedAt,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightSetRow &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.exerciseId == this.exerciseId &&
          other.sortOrder == this.sortOrder &&
          other.plannedReps == this.plannedReps &&
          other.plannedWeightKg == this.plannedWeightKg &&
          other.plannedRestSeconds == this.plannedRestSeconds &&
          other.actualReps == this.actualReps &&
          other.actualWeightKg == this.actualWeightKg &&
          other.completedAt == this.completedAt &&
          other.notes == this.notes);
}

class WeightSetsCompanion extends UpdateCompanion<WeightSetRow> {
  final Value<String> id;
  final Value<String> workoutId;
  final Value<String> exerciseId;
  final Value<int> sortOrder;
  final Value<int> plannedReps;
  final Value<double> plannedWeightKg;
  final Value<int?> plannedRestSeconds;
  final Value<int?> actualReps;
  final Value<double?> actualWeightKg;
  final Value<DateTime?> completedAt;
  final Value<String?> notes;
  final Value<int> rowid;
  const WeightSetsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.plannedReps = const Value.absent(),
    this.plannedWeightKg = const Value.absent(),
    this.plannedRestSeconds = const Value.absent(),
    this.actualReps = const Value.absent(),
    this.actualWeightKg = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightSetsCompanion.insert({
    required String id,
    required String workoutId,
    required String exerciseId,
    required int sortOrder,
    required int plannedReps,
    required double plannedWeightKg,
    this.plannedRestSeconds = const Value.absent(),
    this.actualReps = const Value.absent(),
    this.actualWeightKg = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workoutId = Value(workoutId),
       exerciseId = Value(exerciseId),
       sortOrder = Value(sortOrder),
       plannedReps = Value(plannedReps),
       plannedWeightKg = Value(plannedWeightKg);
  static Insertable<WeightSetRow> custom({
    Expression<String>? id,
    Expression<String>? workoutId,
    Expression<String>? exerciseId,
    Expression<int>? sortOrder,
    Expression<int>? plannedReps,
    Expression<double>? plannedWeightKg,
    Expression<int>? plannedRestSeconds,
    Expression<int>? actualReps,
    Expression<double>? actualWeightKg,
    Expression<DateTime>? completedAt,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (plannedReps != null) 'planned_reps': plannedReps,
      if (plannedWeightKg != null) 'planned_weight_kg': plannedWeightKg,
      if (plannedRestSeconds != null)
        'planned_rest_seconds': plannedRestSeconds,
      if (actualReps != null) 'actual_reps': actualReps,
      if (actualWeightKg != null) 'actual_weight_kg': actualWeightKg,
      if (completedAt != null) 'completed_at': completedAt,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightSetsCompanion copyWith({
    Value<String>? id,
    Value<String>? workoutId,
    Value<String>? exerciseId,
    Value<int>? sortOrder,
    Value<int>? plannedReps,
    Value<double>? plannedWeightKg,
    Value<int?>? plannedRestSeconds,
    Value<int?>? actualReps,
    Value<double?>? actualWeightKg,
    Value<DateTime?>? completedAt,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return WeightSetsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      sortOrder: sortOrder ?? this.sortOrder,
      plannedReps: plannedReps ?? this.plannedReps,
      plannedWeightKg: plannedWeightKg ?? this.plannedWeightKg,
      plannedRestSeconds: plannedRestSeconds ?? this.plannedRestSeconds,
      actualReps: actualReps ?? this.actualReps,
      actualWeightKg: actualWeightKg ?? this.actualWeightKg,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (plannedReps.present) {
      map['planned_reps'] = Variable<int>(plannedReps.value);
    }
    if (plannedWeightKg.present) {
      map['planned_weight_kg'] = Variable<double>(plannedWeightKg.value);
    }
    if (plannedRestSeconds.present) {
      map['planned_rest_seconds'] = Variable<int>(plannedRestSeconds.value);
    }
    if (actualReps.present) {
      map['actual_reps'] = Variable<int>(actualReps.value);
    }
    if (actualWeightKg.present) {
      map['actual_weight_kg'] = Variable<double>(actualWeightKg.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightSetsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('plannedReps: $plannedReps, ')
          ..write('plannedWeightKg: $plannedWeightKg, ')
          ..write('plannedRestSeconds: $plannedRestSeconds, ')
          ..write('actualReps: $actualReps, ')
          ..write('actualWeightKg: $actualWeightKg, ')
          ..write('completedAt: $completedAt, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardioSetsTable extends CardioSets
    with TableInfo<$CardioSetsTable, CardioSetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardioSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workouts (id)',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedDurationMinutesMeta =
      const VerificationMeta('plannedDurationMinutes');
  @override
  late final GeneratedColumn<int> plannedDurationMinutes = GeneratedColumn<int>(
    'planned_duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualDurationMinutesMeta =
      const VerificationMeta('actualDurationMinutes');
  @override
  late final GeneratedColumn<int> actualDurationMinutes = GeneratedColumn<int>(
    'actual_duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutId,
    exerciseId,
    sortOrder,
    plannedDurationMinutes,
    actualDurationMinutes,
    completedAt,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cardio_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardioSetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('planned_duration_minutes')) {
      context.handle(
        _plannedDurationMinutesMeta,
        plannedDurationMinutes.isAcceptableOrUnknown(
          data['planned_duration_minutes']!,
          _plannedDurationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedDurationMinutesMeta);
    }
    if (data.containsKey('actual_duration_minutes')) {
      context.handle(
        _actualDurationMinutesMeta,
        actualDurationMinutes.isAcceptableOrUnknown(
          data['actual_duration_minutes']!,
          _actualDurationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardioSetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardioSetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      plannedDurationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_duration_minutes'],
      )!,
      actualDurationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_duration_minutes'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $CardioSetsTable createAlias(String alias) {
    return $CardioSetsTable(attachedDatabase, alias);
  }
}

class CardioSetRow extends DataClass implements Insertable<CardioSetRow> {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int sortOrder;
  final int plannedDurationMinutes;
  final int? actualDurationMinutes;
  final DateTime? completedAt;
  final String? notes;
  const CardioSetRow({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.sortOrder,
    required this.plannedDurationMinutes,
    this.actualDurationMinutes,
    this.completedAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_id'] = Variable<String>(workoutId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['planned_duration_minutes'] = Variable<int>(plannedDurationMinutes);
    if (!nullToAbsent || actualDurationMinutes != null) {
      map['actual_duration_minutes'] = Variable<int>(actualDurationMinutes);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  CardioSetsCompanion toCompanion(bool nullToAbsent) {
    return CardioSetsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      exerciseId: Value(exerciseId),
      sortOrder: Value(sortOrder),
      plannedDurationMinutes: Value(plannedDurationMinutes),
      actualDurationMinutes: actualDurationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(actualDurationMinutes),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory CardioSetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardioSetRow(
      id: serializer.fromJson<String>(json['id']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      plannedDurationMinutes: serializer.fromJson<int>(
        json['plannedDurationMinutes'],
      ),
      actualDurationMinutes: serializer.fromJson<int?>(
        json['actualDurationMinutes'],
      ),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutId': serializer.toJson<String>(workoutId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'plannedDurationMinutes': serializer.toJson<int>(plannedDurationMinutes),
      'actualDurationMinutes': serializer.toJson<int?>(actualDurationMinutes),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  CardioSetRow copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    int? sortOrder,
    int? plannedDurationMinutes,
    Value<int?> actualDurationMinutes = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => CardioSetRow(
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    exerciseId: exerciseId ?? this.exerciseId,
    sortOrder: sortOrder ?? this.sortOrder,
    plannedDurationMinutes:
        plannedDurationMinutes ?? this.plannedDurationMinutes,
    actualDurationMinutes: actualDurationMinutes.present
        ? actualDurationMinutes.value
        : this.actualDurationMinutes,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    notes: notes.present ? notes.value : this.notes,
  );
  CardioSetRow copyWithCompanion(CardioSetsCompanion data) {
    return CardioSetRow(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      plannedDurationMinutes: data.plannedDurationMinutes.present
          ? data.plannedDurationMinutes.value
          : this.plannedDurationMinutes,
      actualDurationMinutes: data.actualDurationMinutes.present
          ? data.actualDurationMinutes.value
          : this.actualDurationMinutes,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardioSetRow(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('plannedDurationMinutes: $plannedDurationMinutes, ')
          ..write('actualDurationMinutes: $actualDurationMinutes, ')
          ..write('completedAt: $completedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutId,
    exerciseId,
    sortOrder,
    plannedDurationMinutes,
    actualDurationMinutes,
    completedAt,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardioSetRow &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.exerciseId == this.exerciseId &&
          other.sortOrder == this.sortOrder &&
          other.plannedDurationMinutes == this.plannedDurationMinutes &&
          other.actualDurationMinutes == this.actualDurationMinutes &&
          other.completedAt == this.completedAt &&
          other.notes == this.notes);
}

class CardioSetsCompanion extends UpdateCompanion<CardioSetRow> {
  final Value<String> id;
  final Value<String> workoutId;
  final Value<String> exerciseId;
  final Value<int> sortOrder;
  final Value<int> plannedDurationMinutes;
  final Value<int?> actualDurationMinutes;
  final Value<DateTime?> completedAt;
  final Value<String?> notes;
  final Value<int> rowid;
  const CardioSetsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.plannedDurationMinutes = const Value.absent(),
    this.actualDurationMinutes = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardioSetsCompanion.insert({
    required String id,
    required String workoutId,
    required String exerciseId,
    required int sortOrder,
    required int plannedDurationMinutes,
    this.actualDurationMinutes = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workoutId = Value(workoutId),
       exerciseId = Value(exerciseId),
       sortOrder = Value(sortOrder),
       plannedDurationMinutes = Value(plannedDurationMinutes);
  static Insertable<CardioSetRow> custom({
    Expression<String>? id,
    Expression<String>? workoutId,
    Expression<String>? exerciseId,
    Expression<int>? sortOrder,
    Expression<int>? plannedDurationMinutes,
    Expression<int>? actualDurationMinutes,
    Expression<DateTime>? completedAt,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (plannedDurationMinutes != null)
        'planned_duration_minutes': plannedDurationMinutes,
      if (actualDurationMinutes != null)
        'actual_duration_minutes': actualDurationMinutes,
      if (completedAt != null) 'completed_at': completedAt,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardioSetsCompanion copyWith({
    Value<String>? id,
    Value<String>? workoutId,
    Value<String>? exerciseId,
    Value<int>? sortOrder,
    Value<int>? plannedDurationMinutes,
    Value<int?>? actualDurationMinutes,
    Value<DateTime?>? completedAt,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return CardioSetsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      sortOrder: sortOrder ?? this.sortOrder,
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
      actualDurationMinutes:
          actualDurationMinutes ?? this.actualDurationMinutes,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (plannedDurationMinutes.present) {
      map['planned_duration_minutes'] = Variable<int>(
        plannedDurationMinutes.value,
      );
    }
    if (actualDurationMinutes.present) {
      map['actual_duration_minutes'] = Variable<int>(
        actualDurationMinutes.value,
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardioSetsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('plannedDurationMinutes: $plannedDurationMinutes, ')
          ..write('actualDurationMinutes: $actualDurationMinutes, ')
          ..write('completedAt: $completedAt, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IngredientsTable extends Ingredients
    with TableInfo<$IngredientsTable, Ingredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creatorIdMeta = const VerificationMeta(
    'creatorId',
  );
  @override
  late final GeneratedColumn<String> creatorId = GeneratedColumn<String>(
    'creator_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _caloriesPer100gMeta = const VerificationMeta(
    'caloriesPer100g',
  );
  @override
  late final GeneratedColumn<double> caloriesPer100g = GeneratedColumn<double>(
    'calories_per100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinPer100gMeta = const VerificationMeta(
    'proteinPer100g',
  );
  @override
  late final GeneratedColumn<double> proteinPer100g = GeneratedColumn<double>(
    'protein_per100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsPer100gMeta = const VerificationMeta(
    'carbsPer100g',
  );
  @override
  late final GeneratedColumn<double> carbsPer100g = GeneratedColumn<double>(
    'carbs_per100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatPer100gMeta = const VerificationMeta(
    'fatPer100g',
  );
  @override
  late final GeneratedColumn<double> fatPer100g = GeneratedColumn<double>(
    'fat_per100g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sodiumPer100gMeta = const VerificationMeta(
    'sodiumPer100g',
  );
  @override
  late final GeneratedColumn<double> sodiumPer100g = GeneratedColumn<double>(
    'sodium_per100g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiberPer100gMeta = const VerificationMeta(
    'fiberPer100g',
  );
  @override
  late final GeneratedColumn<double> fiberPer100g = GeneratedColumn<double>(
    'fiber_per100g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sugarsPer100gMeta = const VerificationMeta(
    'sugarsPer100g',
  );
  @override
  late final GeneratedColumn<double> sugarsPer100g = GeneratedColumn<double>(
    'sugars_per100g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _saturatedFatPer100gMeta =
      const VerificationMeta('saturatedFatPer100g');
  @override
  late final GeneratedColumn<double> saturatedFatPer100g =
      GeneratedColumn<double>(
        'saturated_fat_per100g',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cholesterolPer100gMeta =
      const VerificationMeta('cholesterolPer100g');
  @override
  late final GeneratedColumn<double> cholesterolPer100g =
      GeneratedColumn<double>(
        'cholesterol_per100g',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    creatorId,
    isArchived,
    caloriesPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
    sodiumPer100g,
    fiberPer100g,
    sugarsPer100g,
    saturatedFatPer100g,
    cholesterolPer100g,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ingredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('creator_id')) {
      context.handle(
        _creatorIdMeta,
        creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('calories_per100g')) {
      context.handle(
        _caloriesPer100gMeta,
        caloriesPer100g.isAcceptableOrUnknown(
          data['calories_per100g']!,
          _caloriesPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caloriesPer100gMeta);
    }
    if (data.containsKey('protein_per100g')) {
      context.handle(
        _proteinPer100gMeta,
        proteinPer100g.isAcceptableOrUnknown(
          data['protein_per100g']!,
          _proteinPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinPer100gMeta);
    }
    if (data.containsKey('carbs_per100g')) {
      context.handle(
        _carbsPer100gMeta,
        carbsPer100g.isAcceptableOrUnknown(
          data['carbs_per100g']!,
          _carbsPer100gMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carbsPer100gMeta);
    }
    if (data.containsKey('fat_per100g')) {
      context.handle(
        _fatPer100gMeta,
        fatPer100g.isAcceptableOrUnknown(data['fat_per100g']!, _fatPer100gMeta),
      );
    } else if (isInserting) {
      context.missing(_fatPer100gMeta);
    }
    if (data.containsKey('sodium_per100g')) {
      context.handle(
        _sodiumPer100gMeta,
        sodiumPer100g.isAcceptableOrUnknown(
          data['sodium_per100g']!,
          _sodiumPer100gMeta,
        ),
      );
    }
    if (data.containsKey('fiber_per100g')) {
      context.handle(
        _fiberPer100gMeta,
        fiberPer100g.isAcceptableOrUnknown(
          data['fiber_per100g']!,
          _fiberPer100gMeta,
        ),
      );
    }
    if (data.containsKey('sugars_per100g')) {
      context.handle(
        _sugarsPer100gMeta,
        sugarsPer100g.isAcceptableOrUnknown(
          data['sugars_per100g']!,
          _sugarsPer100gMeta,
        ),
      );
    }
    if (data.containsKey('saturated_fat_per100g')) {
      context.handle(
        _saturatedFatPer100gMeta,
        saturatedFatPer100g.isAcceptableOrUnknown(
          data['saturated_fat_per100g']!,
          _saturatedFatPer100gMeta,
        ),
      );
    }
    if (data.containsKey('cholesterol_per100g')) {
      context.handle(
        _cholesterolPer100gMeta,
        cholesterolPer100g.isAcceptableOrUnknown(
          data['cholesterol_per100g']!,
          _cholesterolPer100gMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ingredient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      creatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_id'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      caloriesPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories_per100g'],
      )!,
      proteinPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_per100g'],
      )!,
      carbsPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_per100g'],
      )!,
      fatPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_per100g'],
      )!,
      sodiumPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium_per100g'],
      ),
      fiberPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_per100g'],
      ),
      sugarsPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugars_per100g'],
      ),
      saturatedFatPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}saturated_fat_per100g'],
      ),
      cholesterolPer100g: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cholesterol_per100g'],
      ),
    );
  }

  @override
  $IngredientsTable createAlias(String alias) {
    return $IngredientsTable(attachedDatabase, alias);
  }
}

class Ingredient extends DataClass implements Insertable<Ingredient> {
  final String id;
  final String name;
  final String? creatorId;
  final bool isArchived;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? sodiumPer100g;
  final double? fiberPer100g;
  final double? sugarsPer100g;
  final double? saturatedFatPer100g;
  final double? cholesterolPer100g;
  const Ingredient({
    required this.id,
    required this.name,
    this.creatorId,
    required this.isArchived,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.sodiumPer100g,
    this.fiberPer100g,
    this.sugarsPer100g,
    this.saturatedFatPer100g,
    this.cholesterolPer100g,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || creatorId != null) {
      map['creator_id'] = Variable<String>(creatorId);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['calories_per100g'] = Variable<double>(caloriesPer100g);
    map['protein_per100g'] = Variable<double>(proteinPer100g);
    map['carbs_per100g'] = Variable<double>(carbsPer100g);
    map['fat_per100g'] = Variable<double>(fatPer100g);
    if (!nullToAbsent || sodiumPer100g != null) {
      map['sodium_per100g'] = Variable<double>(sodiumPer100g);
    }
    if (!nullToAbsent || fiberPer100g != null) {
      map['fiber_per100g'] = Variable<double>(fiberPer100g);
    }
    if (!nullToAbsent || sugarsPer100g != null) {
      map['sugars_per100g'] = Variable<double>(sugarsPer100g);
    }
    if (!nullToAbsent || saturatedFatPer100g != null) {
      map['saturated_fat_per100g'] = Variable<double>(saturatedFatPer100g);
    }
    if (!nullToAbsent || cholesterolPer100g != null) {
      map['cholesterol_per100g'] = Variable<double>(cholesterolPer100g);
    }
    return map;
  }

  IngredientsCompanion toCompanion(bool nullToAbsent) {
    return IngredientsCompanion(
      id: Value(id),
      name: Value(name),
      creatorId: creatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorId),
      isArchived: Value(isArchived),
      caloriesPer100g: Value(caloriesPer100g),
      proteinPer100g: Value(proteinPer100g),
      carbsPer100g: Value(carbsPer100g),
      fatPer100g: Value(fatPer100g),
      sodiumPer100g: sodiumPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(sodiumPer100g),
      fiberPer100g: fiberPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(fiberPer100g),
      sugarsPer100g: sugarsPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(sugarsPer100g),
      saturatedFatPer100g: saturatedFatPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(saturatedFatPer100g),
      cholesterolPer100g: cholesterolPer100g == null && nullToAbsent
          ? const Value.absent()
          : Value(cholesterolPer100g),
    );
  }

  factory Ingredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ingredient(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      creatorId: serializer.fromJson<String?>(json['creatorId']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      caloriesPer100g: serializer.fromJson<double>(json['caloriesPer100g']),
      proteinPer100g: serializer.fromJson<double>(json['proteinPer100g']),
      carbsPer100g: serializer.fromJson<double>(json['carbsPer100g']),
      fatPer100g: serializer.fromJson<double>(json['fatPer100g']),
      sodiumPer100g: serializer.fromJson<double?>(json['sodiumPer100g']),
      fiberPer100g: serializer.fromJson<double?>(json['fiberPer100g']),
      sugarsPer100g: serializer.fromJson<double?>(json['sugarsPer100g']),
      saturatedFatPer100g: serializer.fromJson<double?>(
        json['saturatedFatPer100g'],
      ),
      cholesterolPer100g: serializer.fromJson<double?>(
        json['cholesterolPer100g'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'creatorId': serializer.toJson<String?>(creatorId),
      'isArchived': serializer.toJson<bool>(isArchived),
      'caloriesPer100g': serializer.toJson<double>(caloriesPer100g),
      'proteinPer100g': serializer.toJson<double>(proteinPer100g),
      'carbsPer100g': serializer.toJson<double>(carbsPer100g),
      'fatPer100g': serializer.toJson<double>(fatPer100g),
      'sodiumPer100g': serializer.toJson<double?>(sodiumPer100g),
      'fiberPer100g': serializer.toJson<double?>(fiberPer100g),
      'sugarsPer100g': serializer.toJson<double?>(sugarsPer100g),
      'saturatedFatPer100g': serializer.toJson<double?>(saturatedFatPer100g),
      'cholesterolPer100g': serializer.toJson<double?>(cholesterolPer100g),
    };
  }

  Ingredient copyWith({
    String? id,
    String? name,
    Value<String?> creatorId = const Value.absent(),
    bool? isArchived,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    Value<double?> sodiumPer100g = const Value.absent(),
    Value<double?> fiberPer100g = const Value.absent(),
    Value<double?> sugarsPer100g = const Value.absent(),
    Value<double?> saturatedFatPer100g = const Value.absent(),
    Value<double?> cholesterolPer100g = const Value.absent(),
  }) => Ingredient(
    id: id ?? this.id,
    name: name ?? this.name,
    creatorId: creatorId.present ? creatorId.value : this.creatorId,
    isArchived: isArchived ?? this.isArchived,
    caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
    proteinPer100g: proteinPer100g ?? this.proteinPer100g,
    carbsPer100g: carbsPer100g ?? this.carbsPer100g,
    fatPer100g: fatPer100g ?? this.fatPer100g,
    sodiumPer100g: sodiumPer100g.present
        ? sodiumPer100g.value
        : this.sodiumPer100g,
    fiberPer100g: fiberPer100g.present ? fiberPer100g.value : this.fiberPer100g,
    sugarsPer100g: sugarsPer100g.present
        ? sugarsPer100g.value
        : this.sugarsPer100g,
    saturatedFatPer100g: saturatedFatPer100g.present
        ? saturatedFatPer100g.value
        : this.saturatedFatPer100g,
    cholesterolPer100g: cholesterolPer100g.present
        ? cholesterolPer100g.value
        : this.cholesterolPer100g,
  );
  Ingredient copyWithCompanion(IngredientsCompanion data) {
    return Ingredient(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      caloriesPer100g: data.caloriesPer100g.present
          ? data.caloriesPer100g.value
          : this.caloriesPer100g,
      proteinPer100g: data.proteinPer100g.present
          ? data.proteinPer100g.value
          : this.proteinPer100g,
      carbsPer100g: data.carbsPer100g.present
          ? data.carbsPer100g.value
          : this.carbsPer100g,
      fatPer100g: data.fatPer100g.present
          ? data.fatPer100g.value
          : this.fatPer100g,
      sodiumPer100g: data.sodiumPer100g.present
          ? data.sodiumPer100g.value
          : this.sodiumPer100g,
      fiberPer100g: data.fiberPer100g.present
          ? data.fiberPer100g.value
          : this.fiberPer100g,
      sugarsPer100g: data.sugarsPer100g.present
          ? data.sugarsPer100g.value
          : this.sugarsPer100g,
      saturatedFatPer100g: data.saturatedFatPer100g.present
          ? data.saturatedFatPer100g.value
          : this.saturatedFatPer100g,
      cholesterolPer100g: data.cholesterolPer100g.present
          ? data.cholesterolPer100g.value
          : this.cholesterolPer100g,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ingredient(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('creatorId: $creatorId, ')
          ..write('isArchived: $isArchived, ')
          ..write('caloriesPer100g: $caloriesPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('carbsPer100g: $carbsPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('sodiumPer100g: $sodiumPer100g, ')
          ..write('fiberPer100g: $fiberPer100g, ')
          ..write('sugarsPer100g: $sugarsPer100g, ')
          ..write('saturatedFatPer100g: $saturatedFatPer100g, ')
          ..write('cholesterolPer100g: $cholesterolPer100g')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    creatorId,
    isArchived,
    caloriesPer100g,
    proteinPer100g,
    carbsPer100g,
    fatPer100g,
    sodiumPer100g,
    fiberPer100g,
    sugarsPer100g,
    saturatedFatPer100g,
    cholesterolPer100g,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ingredient &&
          other.id == this.id &&
          other.name == this.name &&
          other.creatorId == this.creatorId &&
          other.isArchived == this.isArchived &&
          other.caloriesPer100g == this.caloriesPer100g &&
          other.proteinPer100g == this.proteinPer100g &&
          other.carbsPer100g == this.carbsPer100g &&
          other.fatPer100g == this.fatPer100g &&
          other.sodiumPer100g == this.sodiumPer100g &&
          other.fiberPer100g == this.fiberPer100g &&
          other.sugarsPer100g == this.sugarsPer100g &&
          other.saturatedFatPer100g == this.saturatedFatPer100g &&
          other.cholesterolPer100g == this.cholesterolPer100g);
}

class IngredientsCompanion extends UpdateCompanion<Ingredient> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> creatorId;
  final Value<bool> isArchived;
  final Value<double> caloriesPer100g;
  final Value<double> proteinPer100g;
  final Value<double> carbsPer100g;
  final Value<double> fatPer100g;
  final Value<double?> sodiumPer100g;
  final Value<double?> fiberPer100g;
  final Value<double?> sugarsPer100g;
  final Value<double?> saturatedFatPer100g;
  final Value<double?> cholesterolPer100g;
  final Value<int> rowid;
  const IngredientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.caloriesPer100g = const Value.absent(),
    this.proteinPer100g = const Value.absent(),
    this.carbsPer100g = const Value.absent(),
    this.fatPer100g = const Value.absent(),
    this.sodiumPer100g = const Value.absent(),
    this.fiberPer100g = const Value.absent(),
    this.sugarsPer100g = const Value.absent(),
    this.saturatedFatPer100g = const Value.absent(),
    this.cholesterolPer100g = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientsCompanion.insert({
    required String id,
    required String name,
    this.creatorId = const Value.absent(),
    this.isArchived = const Value.absent(),
    required double caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    this.sodiumPer100g = const Value.absent(),
    this.fiberPer100g = const Value.absent(),
    this.sugarsPer100g = const Value.absent(),
    this.saturatedFatPer100g = const Value.absent(),
    this.cholesterolPer100g = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       caloriesPer100g = Value(caloriesPer100g),
       proteinPer100g = Value(proteinPer100g),
       carbsPer100g = Value(carbsPer100g),
       fatPer100g = Value(fatPer100g);
  static Insertable<Ingredient> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? creatorId,
    Expression<bool>? isArchived,
    Expression<double>? caloriesPer100g,
    Expression<double>? proteinPer100g,
    Expression<double>? carbsPer100g,
    Expression<double>? fatPer100g,
    Expression<double>? sodiumPer100g,
    Expression<double>? fiberPer100g,
    Expression<double>? sugarsPer100g,
    Expression<double>? saturatedFatPer100g,
    Expression<double>? cholesterolPer100g,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (creatorId != null) 'creator_id': creatorId,
      if (isArchived != null) 'is_archived': isArchived,
      if (caloriesPer100g != null) 'calories_per100g': caloriesPer100g,
      if (proteinPer100g != null) 'protein_per100g': proteinPer100g,
      if (carbsPer100g != null) 'carbs_per100g': carbsPer100g,
      if (fatPer100g != null) 'fat_per100g': fatPer100g,
      if (sodiumPer100g != null) 'sodium_per100g': sodiumPer100g,
      if (fiberPer100g != null) 'fiber_per100g': fiberPer100g,
      if (sugarsPer100g != null) 'sugars_per100g': sugarsPer100g,
      if (saturatedFatPer100g != null)
        'saturated_fat_per100g': saturatedFatPer100g,
      if (cholesterolPer100g != null) 'cholesterol_per100g': cholesterolPer100g,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? creatorId,
    Value<bool>? isArchived,
    Value<double>? caloriesPer100g,
    Value<double>? proteinPer100g,
    Value<double>? carbsPer100g,
    Value<double>? fatPer100g,
    Value<double?>? sodiumPer100g,
    Value<double?>? fiberPer100g,
    Value<double?>? sugarsPer100g,
    Value<double?>? saturatedFatPer100g,
    Value<double?>? cholesterolPer100g,
    Value<int>? rowid,
  }) {
    return IngredientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      isArchived: isArchived ?? this.isArchived,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      sodiumPer100g: sodiumPer100g ?? this.sodiumPer100g,
      fiberPer100g: fiberPer100g ?? this.fiberPer100g,
      sugarsPer100g: sugarsPer100g ?? this.sugarsPer100g,
      saturatedFatPer100g: saturatedFatPer100g ?? this.saturatedFatPer100g,
      cholesterolPer100g: cholesterolPer100g ?? this.cholesterolPer100g,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (caloriesPer100g.present) {
      map['calories_per100g'] = Variable<double>(caloriesPer100g.value);
    }
    if (proteinPer100g.present) {
      map['protein_per100g'] = Variable<double>(proteinPer100g.value);
    }
    if (carbsPer100g.present) {
      map['carbs_per100g'] = Variable<double>(carbsPer100g.value);
    }
    if (fatPer100g.present) {
      map['fat_per100g'] = Variable<double>(fatPer100g.value);
    }
    if (sodiumPer100g.present) {
      map['sodium_per100g'] = Variable<double>(sodiumPer100g.value);
    }
    if (fiberPer100g.present) {
      map['fiber_per100g'] = Variable<double>(fiberPer100g.value);
    }
    if (sugarsPer100g.present) {
      map['sugars_per100g'] = Variable<double>(sugarsPer100g.value);
    }
    if (saturatedFatPer100g.present) {
      map['saturated_fat_per100g'] = Variable<double>(
        saturatedFatPer100g.value,
      );
    }
    if (cholesterolPer100g.present) {
      map['cholesterol_per100g'] = Variable<double>(cholesterolPer100g.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('creatorId: $creatorId, ')
          ..write('isArchived: $isArchived, ')
          ..write('caloriesPer100g: $caloriesPer100g, ')
          ..write('proteinPer100g: $proteinPer100g, ')
          ..write('carbsPer100g: $carbsPer100g, ')
          ..write('fatPer100g: $fatPer100g, ')
          ..write('sodiumPer100g: $sodiumPer100g, ')
          ..write('fiberPer100g: $fiberPer100g, ')
          ..write('sugarsPer100g: $sugarsPer100g, ')
          ..write('saturatedFatPer100g: $saturatedFatPer100g, ')
          ..write('cholesterolPer100g: $cholesterolPer100g, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IngredientComponentsTable extends IngredientComponents
    with TableInfo<$IngredientComponentsTable, IngredientComponent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientComponentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
    'ingredient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ingredients (id)',
    ),
  );
  static const VerificationMeta _componentIdMeta = const VerificationMeta(
    'componentId',
  );
  @override
  late final GeneratedColumn<String> componentId = GeneratedColumn<String>(
    'component_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ingredients (id)',
    ),
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [ingredientId, componentId, grams];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_components';
  @override
  VerificationContext validateIntegrity(
    Insertable<IngredientComponent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('component_id')) {
      context.handle(
        _componentIdMeta,
        componentId.isAcceptableOrUnknown(
          data['component_id']!,
          _componentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_componentIdMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ingredientId, componentId};
  @override
  IngredientComponent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientComponent(
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_id'],
      )!,
      componentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}component_id'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
    );
  }

  @override
  $IngredientComponentsTable createAlias(String alias) {
    return $IngredientComponentsTable(attachedDatabase, alias);
  }
}

class IngredientComponent extends DataClass
    implements Insertable<IngredientComponent> {
  final String ingredientId;
  final String componentId;
  final double grams;
  const IngredientComponent({
    required this.ingredientId,
    required this.componentId,
    required this.grams,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ingredient_id'] = Variable<String>(ingredientId);
    map['component_id'] = Variable<String>(componentId);
    map['grams'] = Variable<double>(grams);
    return map;
  }

  IngredientComponentsCompanion toCompanion(bool nullToAbsent) {
    return IngredientComponentsCompanion(
      ingredientId: Value(ingredientId),
      componentId: Value(componentId),
      grams: Value(grams),
    );
  }

  factory IngredientComponent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientComponent(
      ingredientId: serializer.fromJson<String>(json['ingredientId']),
      componentId: serializer.fromJson<String>(json['componentId']),
      grams: serializer.fromJson<double>(json['grams']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ingredientId': serializer.toJson<String>(ingredientId),
      'componentId': serializer.toJson<String>(componentId),
      'grams': serializer.toJson<double>(grams),
    };
  }

  IngredientComponent copyWith({
    String? ingredientId,
    String? componentId,
    double? grams,
  }) => IngredientComponent(
    ingredientId: ingredientId ?? this.ingredientId,
    componentId: componentId ?? this.componentId,
    grams: grams ?? this.grams,
  );
  IngredientComponent copyWithCompanion(IngredientComponentsCompanion data) {
    return IngredientComponent(
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      componentId: data.componentId.present
          ? data.componentId.value
          : this.componentId,
      grams: data.grams.present ? data.grams.value : this.grams,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientComponent(')
          ..write('ingredientId: $ingredientId, ')
          ..write('componentId: $componentId, ')
          ..write('grams: $grams')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ingredientId, componentId, grams);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientComponent &&
          other.ingredientId == this.ingredientId &&
          other.componentId == this.componentId &&
          other.grams == this.grams);
}

class IngredientComponentsCompanion
    extends UpdateCompanion<IngredientComponent> {
  final Value<String> ingredientId;
  final Value<String> componentId;
  final Value<double> grams;
  final Value<int> rowid;
  const IngredientComponentsCompanion({
    this.ingredientId = const Value.absent(),
    this.componentId = const Value.absent(),
    this.grams = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IngredientComponentsCompanion.insert({
    required String ingredientId,
    required String componentId,
    required double grams,
    this.rowid = const Value.absent(),
  }) : ingredientId = Value(ingredientId),
       componentId = Value(componentId),
       grams = Value(grams);
  static Insertable<IngredientComponent> custom({
    Expression<String>? ingredientId,
    Expression<String>? componentId,
    Expression<double>? grams,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (componentId != null) 'component_id': componentId,
      if (grams != null) 'grams': grams,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IngredientComponentsCompanion copyWith({
    Value<String>? ingredientId,
    Value<String>? componentId,
    Value<double>? grams,
    Value<int>? rowid,
  }) {
    return IngredientComponentsCompanion(
      ingredientId: ingredientId ?? this.ingredientId,
      componentId: componentId ?? this.componentId,
      grams: grams ?? this.grams,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (componentId.present) {
      map['component_id'] = Variable<String>(componentId.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientComponentsCompanion(')
          ..write('ingredientId: $ingredientId, ')
          ..write('componentId: $componentId, ')
          ..write('grams: $grams, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealsTable extends Meals with TableInfo<$MealsTable, Meal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eatenAtMeta = const VerificationMeta(
    'eatenAt',
  );
  @override
  late final GeneratedColumn<DateTime> eatenAt = GeneratedColumn<DateTime>(
    'eaten_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, eatenAt, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Meal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('eaten_at')) {
      context.handle(
        _eatenAtMeta,
        eatenAt.isAcceptableOrUnknown(data['eaten_at']!, _eatenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_eatenAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Meal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      eatenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}eaten_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $MealsTable createAlias(String alias) {
    return $MealsTable(attachedDatabase, alias);
  }
}

class Meal extends DataClass implements Insertable<Meal> {
  final String id;
  final String name;
  final DateTime eatenAt;
  final String? notes;
  const Meal({
    required this.id,
    required this.name,
    required this.eatenAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['eaten_at'] = Variable<DateTime>(eatenAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  MealsCompanion toCompanion(bool nullToAbsent) {
    return MealsCompanion(
      id: Value(id),
      name: Value(name),
      eatenAt: Value(eatenAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory Meal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meal(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      eatenAt: serializer.fromJson<DateTime>(json['eatenAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'eatenAt': serializer.toJson<DateTime>(eatenAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Meal copyWith({
    String? id,
    String? name,
    DateTime? eatenAt,
    Value<String?> notes = const Value.absent(),
  }) => Meal(
    id: id ?? this.id,
    name: name ?? this.name,
    eatenAt: eatenAt ?? this.eatenAt,
    notes: notes.present ? notes.value : this.notes,
  );
  Meal copyWithCompanion(MealsCompanion data) {
    return Meal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      eatenAt: data.eatenAt.present ? data.eatenAt.value : this.eatenAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, eatenAt, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meal &&
          other.id == this.id &&
          other.name == this.name &&
          other.eatenAt == this.eatenAt &&
          other.notes == this.notes);
}

class MealsCompanion extends UpdateCompanion<Meal> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> eatenAt;
  final Value<String?> notes;
  final Value<int> rowid;
  const MealsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.eatenAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealsCompanion.insert({
    required String id,
    required String name,
    required DateTime eatenAt,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       eatenAt = Value(eatenAt);
  static Insertable<Meal> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? eatenAt,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (eatenAt != null) 'eaten_at': eatenAt,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? eatenAt,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return MealsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      eatenAt: eatenAt ?? this.eatenAt,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (eatenAt.present) {
      map['eaten_at'] = Variable<DateTime>(eatenAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealIngredientsTable extends MealIngredients
    with TableInfo<$MealIngredientsTable, MealIngredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<String> mealId = GeneratedColumn<String>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meals (id)',
    ),
  );
  static const VerificationMeta _ingredientIdMeta = const VerificationMeta(
    'ingredientId',
  );
  @override
  late final GeneratedColumn<String> ingredientId = GeneratedColumn<String>(
    'ingredient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ingredients (id)',
    ),
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  @override
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, mealId, ingredientId, grams];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealIngredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
        _ingredientIdMeta,
        ingredientId.isAcceptableOrUnknown(
          data['ingredient_id']!,
          _ingredientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealIngredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealIngredient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_id'],
      )!,
      ingredientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredient_id'],
      )!,
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
    );
  }

  @override
  $MealIngredientsTable createAlias(String alias) {
    return $MealIngredientsTable(attachedDatabase, alias);
  }
}

class MealIngredient extends DataClass implements Insertable<MealIngredient> {
  final String id;
  final String mealId;
  final String ingredientId;
  final double grams;
  const MealIngredient({
    required this.id,
    required this.mealId,
    required this.ingredientId,
    required this.grams,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meal_id'] = Variable<String>(mealId);
    map['ingredient_id'] = Variable<String>(ingredientId);
    map['grams'] = Variable<double>(grams);
    return map;
  }

  MealIngredientsCompanion toCompanion(bool nullToAbsent) {
    return MealIngredientsCompanion(
      id: Value(id),
      mealId: Value(mealId),
      ingredientId: Value(ingredientId),
      grams: Value(grams),
    );
  }

  factory MealIngredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealIngredient(
      id: serializer.fromJson<String>(json['id']),
      mealId: serializer.fromJson<String>(json['mealId']),
      ingredientId: serializer.fromJson<String>(json['ingredientId']),
      grams: serializer.fromJson<double>(json['grams']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mealId': serializer.toJson<String>(mealId),
      'ingredientId': serializer.toJson<String>(ingredientId),
      'grams': serializer.toJson<double>(grams),
    };
  }

  MealIngredient copyWith({
    String? id,
    String? mealId,
    String? ingredientId,
    double? grams,
  }) => MealIngredient(
    id: id ?? this.id,
    mealId: mealId ?? this.mealId,
    ingredientId: ingredientId ?? this.ingredientId,
    grams: grams ?? this.grams,
  );
  MealIngredient copyWithCompanion(MealIngredientsCompanion data) {
    return MealIngredient(
      id: data.id.present ? data.id.value : this.id,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      grams: data.grams.present ? data.grams.value : this.grams,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealIngredient(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('grams: $grams')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mealId, ingredientId, grams);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealIngredient &&
          other.id == this.id &&
          other.mealId == this.mealId &&
          other.ingredientId == this.ingredientId &&
          other.grams == this.grams);
}

class MealIngredientsCompanion extends UpdateCompanion<MealIngredient> {
  final Value<String> id;
  final Value<String> mealId;
  final Value<String> ingredientId;
  final Value<double> grams;
  final Value<int> rowid;
  const MealIngredientsCompanion({
    this.id = const Value.absent(),
    this.mealId = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.grams = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealIngredientsCompanion.insert({
    required String id,
    required String mealId,
    required String ingredientId,
    required double grams,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mealId = Value(mealId),
       ingredientId = Value(ingredientId),
       grams = Value(grams);
  static Insertable<MealIngredient> custom({
    Expression<String>? id,
    Expression<String>? mealId,
    Expression<String>? ingredientId,
    Expression<double>? grams,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealId != null) 'meal_id': mealId,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (grams != null) 'grams': grams,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealIngredientsCompanion copyWith({
    Value<String>? id,
    Value<String>? mealId,
    Value<String>? ingredientId,
    Value<double>? grams,
    Value<int>? rowid,
  }) {
    return MealIngredientsCompanion(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      ingredientId: ingredientId ?? this.ingredientId,
      grams: grams ?? this.grams,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<String>(mealId.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<String>(ingredientId.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealIngredientsCompanion(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('grams: $grams, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseNameMeta = const VerificationMeta(
    'exerciseName',
  );
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
    'exercise_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetWeightKgMeta = const VerificationMeta(
    'targetWeightKg',
  );
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
    'target_weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    exerciseName,
    targetWeightKg,
    direction,
    targetDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('exercise_name')) {
      context.handle(
        _exerciseNameMeta,
        exerciseName.isAcceptableOrUnknown(
          data['exercise_name']!,
          _exerciseNameMeta,
        ),
      );
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
        _targetWeightKgMeta,
        targetWeightKg.isAcceptableOrUnknown(
          data['target_weight_kg']!,
          _targetWeightKgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetWeightKgMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      exerciseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name'],
      ),
      targetWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight_kg'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      ),
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      ),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final String type;
  final String? exerciseName;
  final double targetWeightKg;
  final String? direction;
  final DateTime? targetDate;
  const Goal({
    required this.id,
    required this.type,
    this.exerciseName,
    required this.targetWeightKg,
    this.direction,
    this.targetDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || exerciseName != null) {
      map['exercise_name'] = Variable<String>(exerciseName);
    }
    map['target_weight_kg'] = Variable<double>(targetWeightKg);
    if (!nullToAbsent || direction != null) {
      map['direction'] = Variable<String>(direction);
    }
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      type: Value(type),
      exerciseName: exerciseName == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseName),
      targetWeightKg: Value(targetWeightKg),
      direction: direction == null && nullToAbsent
          ? const Value.absent()
          : Value(direction),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      exerciseName: serializer.fromJson<String?>(json['exerciseName']),
      targetWeightKg: serializer.fromJson<double>(json['targetWeightKg']),
      direction: serializer.fromJson<String?>(json['direction']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'exerciseName': serializer.toJson<String?>(exerciseName),
      'targetWeightKg': serializer.toJson<double>(targetWeightKg),
      'direction': serializer.toJson<String?>(direction),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
    };
  }

  Goal copyWith({
    String? id,
    String? type,
    Value<String?> exerciseName = const Value.absent(),
    double? targetWeightKg,
    Value<String?> direction = const Value.absent(),
    Value<DateTime?> targetDate = const Value.absent(),
  }) => Goal(
    id: id ?? this.id,
    type: type ?? this.type,
    exerciseName: exerciseName.present ? exerciseName.value : this.exerciseName,
    targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    direction: direction.present ? direction.value : this.direction,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      targetWeightKg: data.targetWeightKg.present
          ? data.targetWeightKg.value
          : this.targetWeightKg,
      direction: data.direction.present ? data.direction.value : this.direction,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('direction: $direction, ')
          ..write('targetDate: $targetDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    exerciseName,
    targetWeightKg,
    direction,
    targetDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.type == this.type &&
          other.exerciseName == this.exerciseName &&
          other.targetWeightKg == this.targetWeightKg &&
          other.direction == this.direction &&
          other.targetDate == this.targetDate);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String> type;
  final Value<String?> exerciseName;
  final Value<double> targetWeightKg;
  final Value<String?> direction;
  final Value<DateTime?> targetDate;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.direction = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String type,
    this.exerciseName = const Value.absent(),
    required double targetWeightKg,
    this.direction = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       targetWeightKg = Value(targetWeightKg);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? exerciseName,
    Expression<double>? targetWeightKg,
    Expression<String>? direction,
    Expression<DateTime>? targetDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (direction != null) 'direction': direction,
      if (targetDate != null) 'target_date': targetDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String?>? exerciseName,
    Value<double>? targetWeightKg,
    Value<String?>? direction,
    Value<DateTime?>? targetDate,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      exerciseName: exerciseName ?? this.exerciseName,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      direction: direction ?? this.direction,
      targetDate: targetDate ?? this.targetDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('direction: $direction, ')
          ..write('targetDate: $targetDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfileTable extends UserProfile
    with TableInfo<$UserProfileTable, UserProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
    'birth_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Gender, String> gender =
      GeneratedColumn<String>(
        'gender',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Gender>($UserProfileTable.$convertergender);
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityLevelMeta = const VerificationMeta(
    'activityLevel',
  );
  @override
  late final GeneratedColumn<String> activityLevel = GeneratedColumn<String>(
    'activity_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    birthDate,
    gender,
    heightCm,
    activityLevel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    } else if (isInserting) {
      context.missing(_birthDateMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('activity_level')) {
      context.handle(
        _activityLevelMeta,
        activityLevel.isAcceptableOrUnknown(
          data['activity_level']!,
          _activityLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityLevelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birth_date'],
      )!,
      gender: $UserProfileTable.$convertergender.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}gender'],
        )!,
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      )!,
      activityLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_level'],
      )!,
    );
  }

  @override
  $UserProfileTable createAlias(String alias) {
    return $UserProfileTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Gender, String, String> $convertergender =
      const EnumNameConverter<Gender>(Gender.values);
}

class UserProfileData extends DataClass implements Insertable<UserProfileData> {
  final String id;
  final DateTime birthDate;
  final Gender gender;
  final double heightCm;
  final String activityLevel;
  const UserProfileData({
    required this.id,
    required this.birthDate,
    required this.gender,
    required this.heightCm,
    required this.activityLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['birth_date'] = Variable<DateTime>(birthDate);
    {
      map['gender'] = Variable<String>(
        $UserProfileTable.$convertergender.toSql(gender),
      );
    }
    map['height_cm'] = Variable<double>(heightCm);
    map['activity_level'] = Variable<String>(activityLevel);
    return map;
  }

  UserProfileCompanion toCompanion(bool nullToAbsent) {
    return UserProfileCompanion(
      id: Value(id),
      birthDate: Value(birthDate),
      gender: Value(gender),
      heightCm: Value(heightCm),
      activityLevel: Value(activityLevel),
    );
  }

  factory UserProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileData(
      id: serializer.fromJson<String>(json['id']),
      birthDate: serializer.fromJson<DateTime>(json['birthDate']),
      gender: $UserProfileTable.$convertergender.fromJson(
        serializer.fromJson<String>(json['gender']),
      ),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      activityLevel: serializer.fromJson<String>(json['activityLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'birthDate': serializer.toJson<DateTime>(birthDate),
      'gender': serializer.toJson<String>(
        $UserProfileTable.$convertergender.toJson(gender),
      ),
      'heightCm': serializer.toJson<double>(heightCm),
      'activityLevel': serializer.toJson<String>(activityLevel),
    };
  }

  UserProfileData copyWith({
    String? id,
    DateTime? birthDate,
    Gender? gender,
    double? heightCm,
    String? activityLevel,
  }) => UserProfileData(
    id: id ?? this.id,
    birthDate: birthDate ?? this.birthDate,
    gender: gender ?? this.gender,
    heightCm: heightCm ?? this.heightCm,
    activityLevel: activityLevel ?? this.activityLevel,
  );
  UserProfileData copyWithCompanion(UserProfileCompanion data) {
    return UserProfileData(
      id: data.id.present ? data.id.value : this.id,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      gender: data.gender.present ? data.gender.value : this.gender,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      activityLevel: data.activityLevel.present
          ? data.activityLevel.value
          : this.activityLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileData(')
          ..write('id: $id, ')
          ..write('birthDate: $birthDate, ')
          ..write('gender: $gender, ')
          ..write('heightCm: $heightCm, ')
          ..write('activityLevel: $activityLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, birthDate, gender, heightCm, activityLevel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileData &&
          other.id == this.id &&
          other.birthDate == this.birthDate &&
          other.gender == this.gender &&
          other.heightCm == this.heightCm &&
          other.activityLevel == this.activityLevel);
}

class UserProfileCompanion extends UpdateCompanion<UserProfileData> {
  final Value<String> id;
  final Value<DateTime> birthDate;
  final Value<Gender> gender;
  final Value<double> heightCm;
  final Value<String> activityLevel;
  final Value<int> rowid;
  const UserProfileCompanion({
    this.id = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.gender = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfileCompanion.insert({
    required String id,
    required DateTime birthDate,
    required Gender gender,
    required double heightCm,
    required String activityLevel,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       birthDate = Value(birthDate),
       gender = Value(gender),
       heightCm = Value(heightCm),
       activityLevel = Value(activityLevel);
  static Insertable<UserProfileData> custom({
    Expression<String>? id,
    Expression<DateTime>? birthDate,
    Expression<String>? gender,
    Expression<double>? heightCm,
    Expression<String>? activityLevel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (birthDate != null) 'birth_date': birthDate,
      if (gender != null) 'gender': gender,
      if (heightCm != null) 'height_cm': heightCm,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfileCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? birthDate,
    Value<Gender>? gender,
    Value<double>? heightCm,
    Value<String>? activityLevel,
    Value<int>? rowid,
  }) {
    return UserProfileCompanion(
      id: id ?? this.id,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(
        $UserProfileTable.$convertergender.toSql(gender.value),
      );
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(activityLevel.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileCompanion(')
          ..write('id: $id, ')
          ..write('birthDate: $birthDate, ')
          ..write('gender: $gender, ')
          ..write('heightCm: $heightCm, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BodyWeightEntriesTable extends BodyWeightEntries
    with TableInfo<$BodyWeightEntriesTable, BodyWeightEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyWeightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, weightKg];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_weight_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BodyWeightEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyWeightEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyWeightEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
    );
  }

  @override
  $BodyWeightEntriesTable createAlias(String alias) {
    return $BodyWeightEntriesTable(attachedDatabase, alias);
  }
}

class BodyWeightEntry extends DataClass implements Insertable<BodyWeightEntry> {
  final String id;
  final DateTime date;
  final double weightKg;
  const BodyWeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['weight_kg'] = Variable<double>(weightKg);
    return map;
  }

  BodyWeightEntriesCompanion toCompanion(bool nullToAbsent) {
    return BodyWeightEntriesCompanion(
      id: Value(id),
      date: Value(date),
      weightKg: Value(weightKg),
    );
  }

  factory BodyWeightEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyWeightEntry(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'weightKg': serializer.toJson<double>(weightKg),
    };
  }

  BodyWeightEntry copyWith({String? id, DateTime? date, double? weightKg}) =>
      BodyWeightEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        weightKg: weightKg ?? this.weightKg,
      );
  BodyWeightEntry copyWithCompanion(BodyWeightEntriesCompanion data) {
    return BodyWeightEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyWeightEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('weightKg: $weightKg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, weightKg);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyWeightEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.weightKg == this.weightKg);
}

class BodyWeightEntriesCompanion extends UpdateCompanion<BodyWeightEntry> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<double> weightKg;
  final Value<int> rowid;
  const BodyWeightEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BodyWeightEntriesCompanion.insert({
    required String id,
    required DateTime date,
    required double weightKg,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       weightKg = Value(weightKg);
  static Insertable<BodyWeightEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<double>? weightKg,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (weightKg != null) 'weight_kg': weightKg,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BodyWeightEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<double>? weightKg,
    Value<int>? rowid,
  }) {
    return BodyWeightEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyWeightEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('weightKg: $weightKg, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WaterConsumptionTable extends WaterConsumption
    with TableInfo<$WaterConsumptionTable, WaterConsumptionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterConsumptionTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _litersMeta = const VerificationMeta('liters');
  @override
  late final GeneratedColumn<double> liters = GeneratedColumn<double>(
    'liters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, liters];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_consumption';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterConsumptionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('liters')) {
      context.handle(
        _litersMeta,
        liters.isAcceptableOrUnknown(data['liters']!, _litersMeta),
      );
    } else if (isInserting) {
      context.missing(_litersMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaterConsumptionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterConsumptionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      liters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}liters'],
      )!,
    );
  }

  @override
  $WaterConsumptionTable createAlias(String alias) {
    return $WaterConsumptionTable(attachedDatabase, alias);
  }
}

class WaterConsumptionData extends DataClass
    implements Insertable<WaterConsumptionData> {
  final String id;
  final DateTime date;
  final double liters;
  const WaterConsumptionData({
    required this.id,
    required this.date,
    required this.liters,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['liters'] = Variable<double>(liters);
    return map;
  }

  WaterConsumptionCompanion toCompanion(bool nullToAbsent) {
    return WaterConsumptionCompanion(
      id: Value(id),
      date: Value(date),
      liters: Value(liters),
    );
  }

  factory WaterConsumptionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterConsumptionData(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      liters: serializer.fromJson<double>(json['liters']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'liters': serializer.toJson<double>(liters),
    };
  }

  WaterConsumptionData copyWith({String? id, DateTime? date, double? liters}) =>
      WaterConsumptionData(
        id: id ?? this.id,
        date: date ?? this.date,
        liters: liters ?? this.liters,
      );
  WaterConsumptionData copyWithCompanion(WaterConsumptionCompanion data) {
    return WaterConsumptionData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      liters: data.liters.present ? data.liters.value : this.liters,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterConsumptionData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('liters: $liters')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, liters);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterConsumptionData &&
          other.id == this.id &&
          other.date == this.date &&
          other.liters == this.liters);
}

class WaterConsumptionCompanion extends UpdateCompanion<WaterConsumptionData> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<double> liters;
  final Value<int> rowid;
  const WaterConsumptionCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.liters = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WaterConsumptionCompanion.insert({
    required String id,
    required DateTime date,
    required double liters,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       liters = Value(liters);
  static Insertable<WaterConsumptionData> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<double>? liters,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (liters != null) 'liters': liters,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WaterConsumptionCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<double>? liters,
    Value<int>? rowid,
  }) {
    return WaterConsumptionCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      liters: liters ?? this.liters,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (liters.present) {
      map['liters'] = Variable<double>(liters.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterConsumptionCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('liters: $liters, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $ExerciseBodyPartsTable exerciseBodyParts =
      $ExerciseBodyPartsTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $WeightSetsTable weightSets = $WeightSetsTable(this);
  late final $CardioSetsTable cardioSets = $CardioSetsTable(this);
  late final $IngredientsTable ingredients = $IngredientsTable(this);
  late final $IngredientComponentsTable ingredientComponents =
      $IngredientComponentsTable(this);
  late final $MealsTable meals = $MealsTable(this);
  late final $MealIngredientsTable mealIngredients = $MealIngredientsTable(
    this,
  );
  late final $GoalsTable goals = $GoalsTable(this);
  late final $UserProfileTable userProfile = $UserProfileTable(this);
  late final $BodyWeightEntriesTable bodyWeightEntries =
      $BodyWeightEntriesTable(this);
  late final $WaterConsumptionTable waterConsumption = $WaterConsumptionTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exercises,
    exerciseBodyParts,
    workouts,
    weightSets,
    cardioSets,
    ingredients,
    ingredientComponents,
    meals,
    mealIngredients,
    goals,
    userProfile,
    bodyWeightEntries,
    waterConsumption,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      required String id,
      required String name,
      Value<String> type,
      Value<double> met,
      Value<String> description,
      Value<String?> imageUrl,
      Value<String?> creatorId,
      Value<int> rowid,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<double> met,
      Value<String> description,
      Value<String?> imageUrl,
      Value<String?> creatorId,
      Value<int> rowid,
    });

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExerciseBodyPartsTable, List<ExerciseBodyPart>>
  _exerciseBodyPartsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exerciseBodyParts,
        aliasName: $_aliasNameGenerator(
          db.exercises.id,
          db.exerciseBodyParts.exerciseId,
        ),
      );

  $$ExerciseBodyPartsTableProcessedTableManager get exerciseBodyPartsRefs {
    final manager = $$ExerciseBodyPartsTableTableManager(
      $_db,
      $_db.exerciseBodyParts,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseBodyPartsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WeightSetsTable, List<WeightSetRow>>
  _weightSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.weightSets,
    aliasName: $_aliasNameGenerator(db.exercises.id, db.weightSets.exerciseId),
  );

  $$WeightSetsTableProcessedTableManager get weightSetsRefs {
    final manager = $$WeightSetsTableTableManager(
      $_db,
      $_db.weightSets,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_weightSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CardioSetsTable, List<CardioSetRow>>
  _cardioSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cardioSets,
    aliasName: $_aliasNameGenerator(db.exercises.id, db.cardioSets.exerciseId),
  );

  $$CardioSetsTableProcessedTableManager get cardioSetsRefs {
    final manager = $$CardioSetsTableTableManager(
      $_db,
      $_db.cardioSets,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardioSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get met => $composableBuilder(
    column: $table.met,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> exerciseBodyPartsRefs(
    Expression<bool> Function($$ExerciseBodyPartsTableFilterComposer f) f,
  ) {
    final $$ExerciseBodyPartsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseBodyParts,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseBodyPartsTableFilterComposer(
            $db: $db,
            $table: $db.exerciseBodyParts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> weightSetsRefs(
    Expression<bool> Function($$WeightSetsTableFilterComposer f) f,
  ) {
    final $$WeightSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weightSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeightSetsTableFilterComposer(
            $db: $db,
            $table: $db.weightSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cardioSetsRefs(
    Expression<bool> Function($$CardioSetsTableFilterComposer f) f,
  ) {
    final $$CardioSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardioSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardioSetsTableFilterComposer(
            $db: $db,
            $table: $db.cardioSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get met => $composableBuilder(
    column: $table.met,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get met =>
      $composableBuilder(column: $table.met, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get creatorId =>
      $composableBuilder(column: $table.creatorId, builder: (column) => column);

  Expression<T> exerciseBodyPartsRefs<T extends Object>(
    Expression<T> Function($$ExerciseBodyPartsTableAnnotationComposer a) f,
  ) {
    final $$ExerciseBodyPartsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseBodyParts,
          getReferencedColumn: (t) => t.exerciseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseBodyPartsTableAnnotationComposer(
                $db: $db,
                $table: $db.exerciseBodyParts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> weightSetsRefs<T extends Object>(
    Expression<T> Function($$WeightSetsTableAnnotationComposer a) f,
  ) {
    final $$WeightSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weightSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeightSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.weightSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cardioSetsRefs<T extends Object>(
    Expression<T> Function($$CardioSetsTableAnnotationComposer a) f,
  ) {
    final $$CardioSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardioSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardioSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.cardioSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, $$ExercisesTableReferences),
          Exercise,
          PrefetchHooks Function({
            bool exerciseBodyPartsRefs,
            bool weightSetsRefs,
            bool cardioSetsRefs,
          })
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> met = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                name: name,
                type: type,
                met: met,
                description: description,
                imageUrl: imageUrl,
                creatorId: creatorId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> type = const Value.absent(),
                Value<double> met = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                type: type,
                met: met,
                description: description,
                imageUrl: imageUrl,
                creatorId: creatorId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                exerciseBodyPartsRefs = false,
                weightSetsRefs = false,
                cardioSetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (exerciseBodyPartsRefs) db.exerciseBodyParts,
                    if (weightSetsRefs) db.weightSets,
                    if (cardioSetsRefs) db.cardioSets,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (exerciseBodyPartsRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          ExerciseBodyPart
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._exerciseBodyPartsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseBodyPartsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (weightSetsRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          WeightSetRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._weightSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).weightSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cardioSetsRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          CardioSetRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._cardioSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).cardioSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, $$ExercisesTableReferences),
      Exercise,
      PrefetchHooks Function({
        bool exerciseBodyPartsRefs,
        bool weightSetsRefs,
        bool cardioSetsRefs,
      })
    >;
typedef $$ExerciseBodyPartsTableCreateCompanionBuilder =
    ExerciseBodyPartsCompanion Function({
      required String exerciseId,
      required String bodyPart,
      Value<int> rowid,
    });
typedef $$ExerciseBodyPartsTableUpdateCompanionBuilder =
    ExerciseBodyPartsCompanion Function({
      Value<String> exerciseId,
      Value<String> bodyPart,
      Value<int> rowid,
    });

final class $$ExerciseBodyPartsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExerciseBodyPartsTable,
          ExerciseBodyPart
        > {
  $$ExerciseBodyPartsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(db.exerciseBodyParts.exerciseId, db.exercises.id),
      );

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExerciseBodyPartsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseBodyPartsTable> {
  $$ExerciseBodyPartsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bodyPart => $composableBuilder(
    column: $table.bodyPart,
    builder: (column) => ColumnFilters(column),
  );

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseBodyPartsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseBodyPartsTable> {
  $$ExerciseBodyPartsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bodyPart => $composableBuilder(
    column: $table.bodyPart,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseBodyPartsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseBodyPartsTable> {
  $$ExerciseBodyPartsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bodyPart =>
      $composableBuilder(column: $table.bodyPart, builder: (column) => column);

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseBodyPartsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseBodyPartsTable,
          ExerciseBodyPart,
          $$ExerciseBodyPartsTableFilterComposer,
          $$ExerciseBodyPartsTableOrderingComposer,
          $$ExerciseBodyPartsTableAnnotationComposer,
          $$ExerciseBodyPartsTableCreateCompanionBuilder,
          $$ExerciseBodyPartsTableUpdateCompanionBuilder,
          (ExerciseBodyPart, $$ExerciseBodyPartsTableReferences),
          ExerciseBodyPart,
          PrefetchHooks Function({bool exerciseId})
        > {
  $$ExerciseBodyPartsTableTableManager(
    _$AppDatabase db,
    $ExerciseBodyPartsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseBodyPartsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseBodyPartsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseBodyPartsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> exerciseId = const Value.absent(),
                Value<String> bodyPart = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseBodyPartsCompanion(
                exerciseId: exerciseId,
                bodyPart: bodyPart,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exerciseId,
                required String bodyPart,
                Value<int> rowid = const Value.absent(),
              }) => ExerciseBodyPartsCompanion.insert(
                exerciseId: exerciseId,
                bodyPart: bodyPart,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseBodyPartsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable:
                                    $$ExerciseBodyPartsTableReferences
                                        ._exerciseIdTable(db),
                                referencedColumn:
                                    $$ExerciseBodyPartsTableReferences
                                        ._exerciseIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExerciseBodyPartsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseBodyPartsTable,
      ExerciseBodyPart,
      $$ExerciseBodyPartsTableFilterComposer,
      $$ExerciseBodyPartsTableOrderingComposer,
      $$ExerciseBodyPartsTableAnnotationComposer,
      $$ExerciseBodyPartsTableCreateCompanionBuilder,
      $$ExerciseBodyPartsTableUpdateCompanionBuilder,
      (ExerciseBodyPart, $$ExerciseBodyPartsTableReferences),
      ExerciseBodyPart,
      PrefetchHooks Function({bool exerciseId})
    >;
typedef $$WorkoutsTableCreateCompanionBuilder =
    WorkoutsCompanion Function({
      required String id,
      required String name,
      Value<DateTime?> scheduledDate,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
      Value<String?> notes,
      Value<String> source,
      Value<int> rowid,
    });
typedef $$WorkoutsTableUpdateCompanionBuilder =
    WorkoutsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime?> scheduledDate,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
      Value<String?> notes,
      Value<String> source,
      Value<int> rowid,
    });

final class $$WorkoutsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutsTable, WorkoutRow> {
  $$WorkoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WeightSetsTable, List<WeightSetRow>>
  _weightSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.weightSets,
    aliasName: $_aliasNameGenerator(db.workouts.id, db.weightSets.workoutId),
  );

  $$WeightSetsTableProcessedTableManager get weightSetsRefs {
    final manager = $$WeightSetsTableTableManager(
      $_db,
      $_db.weightSets,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_weightSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CardioSetsTable, List<CardioSetRow>>
  _cardioSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cardioSets,
    aliasName: $_aliasNameGenerator(db.workouts.id, db.cardioSets.workoutId),
  );

  $$CardioSetsTableProcessedTableManager get cardioSetsRefs {
    final manager = $$CardioSetsTableTableManager(
      $_db,
      $_db.cardioSets,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardioSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> weightSetsRefs(
    Expression<bool> Function($$WeightSetsTableFilterComposer f) f,
  ) {
    final $$WeightSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weightSets,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeightSetsTableFilterComposer(
            $db: $db,
            $table: $db.weightSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cardioSetsRefs(
    Expression<bool> Function($$CardioSetsTableFilterComposer f) f,
  ) {
    final $$CardioSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardioSets,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardioSetsTableFilterComposer(
            $db: $db,
            $table: $db.cardioSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  Expression<T> weightSetsRefs<T extends Object>(
    Expression<T> Function($$WeightSetsTableAnnotationComposer a) f,
  ) {
    final $$WeightSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weightSets,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeightSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.weightSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cardioSetsRefs<T extends Object>(
    Expression<T> Function($$CardioSetsTableAnnotationComposer a) f,
  ) {
    final $$CardioSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardioSets,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardioSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.cardioSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutsTable,
          WorkoutRow,
          $$WorkoutsTableFilterComposer,
          $$WorkoutsTableOrderingComposer,
          $$WorkoutsTableAnnotationComposer,
          $$WorkoutsTableCreateCompanionBuilder,
          $$WorkoutsTableUpdateCompanionBuilder,
          (WorkoutRow, $$WorkoutsTableReferences),
          WorkoutRow,
          PrefetchHooks Function({bool weightSetsRefs, bool cardioSetsRefs})
        > {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutsCompanion(
                id: id,
                name: name,
                scheduledDate: scheduledDate,
                startedAt: startedAt,
                completedAt: completedAt,
                notes: notes,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutsCompanion.insert(
                id: id,
                name: name,
                scheduledDate: scheduledDate,
                startedAt: startedAt,
                completedAt: completedAt,
                notes: notes,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({weightSetsRefs = false, cardioSetsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (weightSetsRefs) db.weightSets,
                    if (cardioSetsRefs) db.cardioSets,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (weightSetsRefs)
                        await $_getPrefetchedData<
                          WorkoutRow,
                          $WorkoutsTable,
                          WeightSetRow
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutsTableReferences
                              ._weightSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).weightSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cardioSetsRefs)
                        await $_getPrefetchedData<
                          WorkoutRow,
                          $WorkoutsTable,
                          CardioSetRow
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutsTableReferences
                              ._cardioSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).cardioSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutsTable,
      WorkoutRow,
      $$WorkoutsTableFilterComposer,
      $$WorkoutsTableOrderingComposer,
      $$WorkoutsTableAnnotationComposer,
      $$WorkoutsTableCreateCompanionBuilder,
      $$WorkoutsTableUpdateCompanionBuilder,
      (WorkoutRow, $$WorkoutsTableReferences),
      WorkoutRow,
      PrefetchHooks Function({bool weightSetsRefs, bool cardioSetsRefs})
    >;
typedef $$WeightSetsTableCreateCompanionBuilder =
    WeightSetsCompanion Function({
      required String id,
      required String workoutId,
      required String exerciseId,
      required int sortOrder,
      required int plannedReps,
      required double plannedWeightKg,
      Value<int?> plannedRestSeconds,
      Value<int?> actualReps,
      Value<double?> actualWeightKg,
      Value<DateTime?> completedAt,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$WeightSetsTableUpdateCompanionBuilder =
    WeightSetsCompanion Function({
      Value<String> id,
      Value<String> workoutId,
      Value<String> exerciseId,
      Value<int> sortOrder,
      Value<int> plannedReps,
      Value<double> plannedWeightKg,
      Value<int?> plannedRestSeconds,
      Value<int?> actualReps,
      Value<double?> actualWeightKg,
      Value<DateTime?> completedAt,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$WeightSetsTableReferences
    extends BaseReferences<_$AppDatabase, $WeightSetsTable, WeightSetRow> {
  $$WeightSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
        $_aliasNameGenerator(db.weightSets.workoutId, db.workouts.id),
      );

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<String>('workout_id')!;

    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(db.weightSets.exerciseId, db.exercises.id),
      );

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WeightSetsTableFilterComposer
    extends Composer<_$AppDatabase, $WeightSetsTable> {
  $$WeightSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedReps => $composableBuilder(
    column: $table.plannedReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get plannedWeightKg => $composableBuilder(
    column: $table.plannedWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedRestSeconds => $composableBuilder(
    column: $table.plannedRestSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get actualWeightKg => $composableBuilder(
    column: $table.actualWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeightSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightSetsTable> {
  $$WeightSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedReps => $composableBuilder(
    column: $table.plannedReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get plannedWeightKg => $composableBuilder(
    column: $table.plannedWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedRestSeconds => $composableBuilder(
    column: $table.plannedRestSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get actualWeightKg => $composableBuilder(
    column: $table.actualWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeightSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightSetsTable> {
  $$WeightSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get plannedReps => $composableBuilder(
    column: $table.plannedReps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get plannedWeightKg => $composableBuilder(
    column: $table.plannedWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plannedRestSeconds => $composableBuilder(
    column: $table.plannedRestSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualReps => $composableBuilder(
    column: $table.actualReps,
    builder: (column) => column,
  );

  GeneratedColumn<double> get actualWeightKg => $composableBuilder(
    column: $table.actualWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeightSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightSetsTable,
          WeightSetRow,
          $$WeightSetsTableFilterComposer,
          $$WeightSetsTableOrderingComposer,
          $$WeightSetsTableAnnotationComposer,
          $$WeightSetsTableCreateCompanionBuilder,
          $$WeightSetsTableUpdateCompanionBuilder,
          (WeightSetRow, $$WeightSetsTableReferences),
          WeightSetRow,
          PrefetchHooks Function({bool workoutId, bool exerciseId})
        > {
  $$WeightSetsTableTableManager(_$AppDatabase db, $WeightSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workoutId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> plannedReps = const Value.absent(),
                Value<double> plannedWeightKg = const Value.absent(),
                Value<int?> plannedRestSeconds = const Value.absent(),
                Value<int?> actualReps = const Value.absent(),
                Value<double?> actualWeightKg = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightSetsCompanion(
                id: id,
                workoutId: workoutId,
                exerciseId: exerciseId,
                sortOrder: sortOrder,
                plannedReps: plannedReps,
                plannedWeightKg: plannedWeightKg,
                plannedRestSeconds: plannedRestSeconds,
                actualReps: actualReps,
                actualWeightKg: actualWeightKg,
                completedAt: completedAt,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workoutId,
                required String exerciseId,
                required int sortOrder,
                required int plannedReps,
                required double plannedWeightKg,
                Value<int?> plannedRestSeconds = const Value.absent(),
                Value<int?> actualReps = const Value.absent(),
                Value<double?> actualWeightKg = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightSetsCompanion.insert(
                id: id,
                workoutId: workoutId,
                exerciseId: exerciseId,
                sortOrder: sortOrder,
                plannedReps: plannedReps,
                plannedWeightKg: plannedWeightKg,
                plannedRestSeconds: plannedRestSeconds,
                actualReps: actualReps,
                actualWeightKg: actualWeightKg,
                completedAt: completedAt,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WeightSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workoutId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workoutId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workoutId,
                                referencedTable: $$WeightSetsTableReferences
                                    ._workoutIdTable(db),
                                referencedColumn: $$WeightSetsTableReferences
                                    ._workoutIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable: $$WeightSetsTableReferences
                                    ._exerciseIdTable(db),
                                referencedColumn: $$WeightSetsTableReferences
                                    ._exerciseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WeightSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightSetsTable,
      WeightSetRow,
      $$WeightSetsTableFilterComposer,
      $$WeightSetsTableOrderingComposer,
      $$WeightSetsTableAnnotationComposer,
      $$WeightSetsTableCreateCompanionBuilder,
      $$WeightSetsTableUpdateCompanionBuilder,
      (WeightSetRow, $$WeightSetsTableReferences),
      WeightSetRow,
      PrefetchHooks Function({bool workoutId, bool exerciseId})
    >;
typedef $$CardioSetsTableCreateCompanionBuilder =
    CardioSetsCompanion Function({
      required String id,
      required String workoutId,
      required String exerciseId,
      required int sortOrder,
      required int plannedDurationMinutes,
      Value<int?> actualDurationMinutes,
      Value<DateTime?> completedAt,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$CardioSetsTableUpdateCompanionBuilder =
    CardioSetsCompanion Function({
      Value<String> id,
      Value<String> workoutId,
      Value<String> exerciseId,
      Value<int> sortOrder,
      Value<int> plannedDurationMinutes,
      Value<int?> actualDurationMinutes,
      Value<DateTime?> completedAt,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$CardioSetsTableReferences
    extends BaseReferences<_$AppDatabase, $CardioSetsTable, CardioSetRow> {
  $$CardioSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
        $_aliasNameGenerator(db.cardioSets.workoutId, db.workouts.id),
      );

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<String>('workout_id')!;

    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(db.cardioSets.exerciseId, db.exercises.id),
      );

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CardioSetsTableFilterComposer
    extends Composer<_$AppDatabase, $CardioSetsTable> {
  $$CardioSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedDurationMinutes => $composableBuilder(
    column: $table.plannedDurationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualDurationMinutes => $composableBuilder(
    column: $table.actualDurationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardioSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardioSetsTable> {
  $$CardioSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedDurationMinutes => $composableBuilder(
    column: $table.plannedDurationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualDurationMinutes => $composableBuilder(
    column: $table.actualDurationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardioSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardioSetsTable> {
  $$CardioSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get plannedDurationMinutes => $composableBuilder(
    column: $table.plannedDurationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualDurationMinutes => $composableBuilder(
    column: $table.actualDurationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardioSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardioSetsTable,
          CardioSetRow,
          $$CardioSetsTableFilterComposer,
          $$CardioSetsTableOrderingComposer,
          $$CardioSetsTableAnnotationComposer,
          $$CardioSetsTableCreateCompanionBuilder,
          $$CardioSetsTableUpdateCompanionBuilder,
          (CardioSetRow, $$CardioSetsTableReferences),
          CardioSetRow,
          PrefetchHooks Function({bool workoutId, bool exerciseId})
        > {
  $$CardioSetsTableTableManager(_$AppDatabase db, $CardioSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardioSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardioSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardioSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workoutId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> plannedDurationMinutes = const Value.absent(),
                Value<int?> actualDurationMinutes = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardioSetsCompanion(
                id: id,
                workoutId: workoutId,
                exerciseId: exerciseId,
                sortOrder: sortOrder,
                plannedDurationMinutes: plannedDurationMinutes,
                actualDurationMinutes: actualDurationMinutes,
                completedAt: completedAt,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workoutId,
                required String exerciseId,
                required int sortOrder,
                required int plannedDurationMinutes,
                Value<int?> actualDurationMinutes = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardioSetsCompanion.insert(
                id: id,
                workoutId: workoutId,
                exerciseId: exerciseId,
                sortOrder: sortOrder,
                plannedDurationMinutes: plannedDurationMinutes,
                actualDurationMinutes: actualDurationMinutes,
                completedAt: completedAt,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CardioSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workoutId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workoutId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workoutId,
                                referencedTable: $$CardioSetsTableReferences
                                    ._workoutIdTable(db),
                                referencedColumn: $$CardioSetsTableReferences
                                    ._workoutIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (exerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exerciseId,
                                referencedTable: $$CardioSetsTableReferences
                                    ._exerciseIdTable(db),
                                referencedColumn: $$CardioSetsTableReferences
                                    ._exerciseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CardioSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardioSetsTable,
      CardioSetRow,
      $$CardioSetsTableFilterComposer,
      $$CardioSetsTableOrderingComposer,
      $$CardioSetsTableAnnotationComposer,
      $$CardioSetsTableCreateCompanionBuilder,
      $$CardioSetsTableUpdateCompanionBuilder,
      (CardioSetRow, $$CardioSetsTableReferences),
      CardioSetRow,
      PrefetchHooks Function({bool workoutId, bool exerciseId})
    >;
typedef $$IngredientsTableCreateCompanionBuilder =
    IngredientsCompanion Function({
      required String id,
      required String name,
      Value<String?> creatorId,
      Value<bool> isArchived,
      required double caloriesPer100g,
      required double proteinPer100g,
      required double carbsPer100g,
      required double fatPer100g,
      Value<double?> sodiumPer100g,
      Value<double?> fiberPer100g,
      Value<double?> sugarsPer100g,
      Value<double?> saturatedFatPer100g,
      Value<double?> cholesterolPer100g,
      Value<int> rowid,
    });
typedef $$IngredientsTableUpdateCompanionBuilder =
    IngredientsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> creatorId,
      Value<bool> isArchived,
      Value<double> caloriesPer100g,
      Value<double> proteinPer100g,
      Value<double> carbsPer100g,
      Value<double> fatPer100g,
      Value<double?> sodiumPer100g,
      Value<double?> fiberPer100g,
      Value<double?> sugarsPer100g,
      Value<double?> saturatedFatPer100g,
      Value<double?> cholesterolPer100g,
      Value<int> rowid,
    });

final class $$IngredientsTableReferences
    extends BaseReferences<_$AppDatabase, $IngredientsTable, Ingredient> {
  $$IngredientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MealIngredientsTable, List<MealIngredient>>
  _mealIngredientsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mealIngredients,
    aliasName: $_aliasNameGenerator(
      db.ingredients.id,
      db.mealIngredients.ingredientId,
    ),
  );

  $$MealIngredientsTableProcessedTableManager get mealIngredientsRefs {
    final manager = $$MealIngredientsTableTableManager(
      $_db,
      $_db.mealIngredients,
    ).filter((f) => f.ingredientId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _mealIngredientsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$IngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodiumPer100g => $composableBuilder(
    column: $table.sodiumPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberPer100g => $composableBuilder(
    column: $table.fiberPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarsPer100g => $composableBuilder(
    column: $table.sugarsPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get saturatedFatPer100g => $composableBuilder(
    column: $table.saturatedFatPer100g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cholesterolPer100g => $composableBuilder(
    column: $table.cholesterolPer100g,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mealIngredientsRefs(
    Expression<bool> Function($$MealIngredientsTableFilterComposer f) f,
  ) {
    final $$MealIngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealIngredients,
      getReferencedColumn: (t) => t.ingredientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealIngredientsTableFilterComposer(
            $db: $db,
            $table: $db.mealIngredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodiumPer100g => $composableBuilder(
    column: $table.sodiumPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberPer100g => $composableBuilder(
    column: $table.fiberPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarsPer100g => $composableBuilder(
    column: $table.sugarsPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get saturatedFatPer100g => $composableBuilder(
    column: $table.saturatedFatPer100g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cholesterolPer100g => $composableBuilder(
    column: $table.cholesterolPer100g,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get creatorId =>
      $composableBuilder(column: $table.creatorId, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<double> get caloriesPer100g => $composableBuilder(
    column: $table.caloriesPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinPer100g => $composableBuilder(
    column: $table.proteinPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carbsPer100g => $composableBuilder(
    column: $table.carbsPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatPer100g => $composableBuilder(
    column: $table.fatPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sodiumPer100g => $composableBuilder(
    column: $table.sodiumPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fiberPer100g => $composableBuilder(
    column: $table.fiberPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sugarsPer100g => $composableBuilder(
    column: $table.sugarsPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get saturatedFatPer100g => $composableBuilder(
    column: $table.saturatedFatPer100g,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cholesterolPer100g => $composableBuilder(
    column: $table.cholesterolPer100g,
    builder: (column) => column,
  );

  Expression<T> mealIngredientsRefs<T extends Object>(
    Expression<T> Function($$MealIngredientsTableAnnotationComposer a) f,
  ) {
    final $$MealIngredientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealIngredients,
      getReferencedColumn: (t) => t.ingredientId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealIngredientsTableAnnotationComposer(
            $db: $db,
            $table: $db.mealIngredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientsTable,
          Ingredient,
          $$IngredientsTableFilterComposer,
          $$IngredientsTableOrderingComposer,
          $$IngredientsTableAnnotationComposer,
          $$IngredientsTableCreateCompanionBuilder,
          $$IngredientsTableUpdateCompanionBuilder,
          (Ingredient, $$IngredientsTableReferences),
          Ingredient,
          PrefetchHooks Function({bool mealIngredientsRefs})
        > {
  $$IngredientsTableTableManager(_$AppDatabase db, $IngredientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<double> caloriesPer100g = const Value.absent(),
                Value<double> proteinPer100g = const Value.absent(),
                Value<double> carbsPer100g = const Value.absent(),
                Value<double> fatPer100g = const Value.absent(),
                Value<double?> sodiumPer100g = const Value.absent(),
                Value<double?> fiberPer100g = const Value.absent(),
                Value<double?> sugarsPer100g = const Value.absent(),
                Value<double?> saturatedFatPer100g = const Value.absent(),
                Value<double?> cholesterolPer100g = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientsCompanion(
                id: id,
                name: name,
                creatorId: creatorId,
                isArchived: isArchived,
                caloriesPer100g: caloriesPer100g,
                proteinPer100g: proteinPer100g,
                carbsPer100g: carbsPer100g,
                fatPer100g: fatPer100g,
                sodiumPer100g: sodiumPer100g,
                fiberPer100g: fiberPer100g,
                sugarsPer100g: sugarsPer100g,
                saturatedFatPer100g: saturatedFatPer100g,
                cholesterolPer100g: cholesterolPer100g,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> creatorId = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required double caloriesPer100g,
                required double proteinPer100g,
                required double carbsPer100g,
                required double fatPer100g,
                Value<double?> sodiumPer100g = const Value.absent(),
                Value<double?> fiberPer100g = const Value.absent(),
                Value<double?> sugarsPer100g = const Value.absent(),
                Value<double?> saturatedFatPer100g = const Value.absent(),
                Value<double?> cholesterolPer100g = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientsCompanion.insert(
                id: id,
                name: name,
                creatorId: creatorId,
                isArchived: isArchived,
                caloriesPer100g: caloriesPer100g,
                proteinPer100g: proteinPer100g,
                carbsPer100g: carbsPer100g,
                fatPer100g: fatPer100g,
                sodiumPer100g: sodiumPer100g,
                fiberPer100g: fiberPer100g,
                sugarsPer100g: sugarsPer100g,
                saturatedFatPer100g: saturatedFatPer100g,
                cholesterolPer100g: cholesterolPer100g,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IngredientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mealIngredientsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (mealIngredientsRefs) db.mealIngredients,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mealIngredientsRefs)
                    await $_getPrefetchedData<
                      Ingredient,
                      $IngredientsTable,
                      MealIngredient
                    >(
                      currentTable: table,
                      referencedTable: $$IngredientsTableReferences
                          ._mealIngredientsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$IngredientsTableReferences(
                            db,
                            table,
                            p0,
                          ).mealIngredientsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.ingredientId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$IngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientsTable,
      Ingredient,
      $$IngredientsTableFilterComposer,
      $$IngredientsTableOrderingComposer,
      $$IngredientsTableAnnotationComposer,
      $$IngredientsTableCreateCompanionBuilder,
      $$IngredientsTableUpdateCompanionBuilder,
      (Ingredient, $$IngredientsTableReferences),
      Ingredient,
      PrefetchHooks Function({bool mealIngredientsRefs})
    >;
typedef $$IngredientComponentsTableCreateCompanionBuilder =
    IngredientComponentsCompanion Function({
      required String ingredientId,
      required String componentId,
      required double grams,
      Value<int> rowid,
    });
typedef $$IngredientComponentsTableUpdateCompanionBuilder =
    IngredientComponentsCompanion Function({
      Value<String> ingredientId,
      Value<String> componentId,
      Value<double> grams,
      Value<int> rowid,
    });

final class $$IngredientComponentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $IngredientComponentsTable,
          IngredientComponent
        > {
  $$IngredientComponentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $IngredientsTable _ingredientIdTable(_$AppDatabase db) =>
      db.ingredients.createAlias(
        $_aliasNameGenerator(
          db.ingredientComponents.ingredientId,
          db.ingredients.id,
        ),
      );

  $$IngredientsTableProcessedTableManager get ingredientId {
    final $_column = $_itemColumn<String>('ingredient_id')!;

    final manager = $$IngredientsTableTableManager(
      $_db,
      $_db.ingredients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $IngredientsTable _componentIdTable(_$AppDatabase db) =>
      db.ingredients.createAlias(
        $_aliasNameGenerator(
          db.ingredientComponents.componentId,
          db.ingredients.id,
        ),
      );

  $$IngredientsTableProcessedTableManager get componentId {
    final $_column = $_itemColumn<String>('component_id')!;

    final manager = $$IngredientsTableTableManager(
      $_db,
      $_db.ingredients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_componentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IngredientComponentsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientComponentsTable> {
  $$IngredientComponentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  $$IngredientsTableFilterComposer get ingredientId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingredientId,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableFilterComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$IngredientsTableFilterComposer get componentId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableFilterComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientComponentsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientComponentsTable> {
  $$IngredientComponentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  $$IngredientsTableOrderingComposer get ingredientId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingredientId,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableOrderingComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$IngredientsTableOrderingComposer get componentId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableOrderingComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientComponentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientComponentsTable> {
  $$IngredientComponentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  $$IngredientsTableAnnotationComposer get ingredientId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingredientId,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableAnnotationComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$IngredientsTableAnnotationComposer get componentId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.componentId,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableAnnotationComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IngredientComponentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IngredientComponentsTable,
          IngredientComponent,
          $$IngredientComponentsTableFilterComposer,
          $$IngredientComponentsTableOrderingComposer,
          $$IngredientComponentsTableAnnotationComposer,
          $$IngredientComponentsTableCreateCompanionBuilder,
          $$IngredientComponentsTableUpdateCompanionBuilder,
          (IngredientComponent, $$IngredientComponentsTableReferences),
          IngredientComponent,
          PrefetchHooks Function({bool ingredientId, bool componentId})
        > {
  $$IngredientComponentsTableTableManager(
    _$AppDatabase db,
    $IngredientComponentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientComponentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientComponentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$IngredientComponentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ingredientId = const Value.absent(),
                Value<String> componentId = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IngredientComponentsCompanion(
                ingredientId: ingredientId,
                componentId: componentId,
                grams: grams,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ingredientId,
                required String componentId,
                required double grams,
                Value<int> rowid = const Value.absent(),
              }) => IngredientComponentsCompanion.insert(
                ingredientId: ingredientId,
                componentId: componentId,
                grams: grams,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IngredientComponentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ingredientId = false, componentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ingredientId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ingredientId,
                                referencedTable:
                                    $$IngredientComponentsTableReferences
                                        ._ingredientIdTable(db),
                                referencedColumn:
                                    $$IngredientComponentsTableReferences
                                        ._ingredientIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (componentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.componentId,
                                referencedTable:
                                    $$IngredientComponentsTableReferences
                                        ._componentIdTable(db),
                                referencedColumn:
                                    $$IngredientComponentsTableReferences
                                        ._componentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IngredientComponentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IngredientComponentsTable,
      IngredientComponent,
      $$IngredientComponentsTableFilterComposer,
      $$IngredientComponentsTableOrderingComposer,
      $$IngredientComponentsTableAnnotationComposer,
      $$IngredientComponentsTableCreateCompanionBuilder,
      $$IngredientComponentsTableUpdateCompanionBuilder,
      (IngredientComponent, $$IngredientComponentsTableReferences),
      IngredientComponent,
      PrefetchHooks Function({bool ingredientId, bool componentId})
    >;
typedef $$MealsTableCreateCompanionBuilder =
    MealsCompanion Function({
      required String id,
      required String name,
      required DateTime eatenAt,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$MealsTableUpdateCompanionBuilder =
    MealsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> eatenAt,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$MealsTableReferences
    extends BaseReferences<_$AppDatabase, $MealsTable, Meal> {
  $$MealsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MealIngredientsTable, List<MealIngredient>>
  _mealIngredientsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mealIngredients,
    aliasName: $_aliasNameGenerator(db.meals.id, db.mealIngredients.mealId),
  );

  $$MealIngredientsTableProcessedTableManager get mealIngredientsRefs {
    final manager = $$MealIngredientsTableTableManager(
      $_db,
      $_db.mealIngredients,
    ).filter((f) => f.mealId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _mealIngredientsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MealsTableFilterComposer extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eatenAt => $composableBuilder(
    column: $table.eatenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mealIngredientsRefs(
    Expression<bool> Function($$MealIngredientsTableFilterComposer f) f,
  ) {
    final $$MealIngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealIngredients,
      getReferencedColumn: (t) => t.mealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealIngredientsTableFilterComposer(
            $db: $db,
            $table: $db.mealIngredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eatenAt => $composableBuilder(
    column: $table.eatenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get eatenAt =>
      $composableBuilder(column: $table.eatenAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> mealIngredientsRefs<T extends Object>(
    Expression<T> Function($$MealIngredientsTableAnnotationComposer a) f,
  ) {
    final $$MealIngredientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealIngredients,
      getReferencedColumn: (t) => t.mealId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealIngredientsTableAnnotationComposer(
            $db: $db,
            $table: $db.mealIngredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealsTable,
          Meal,
          $$MealsTableFilterComposer,
          $$MealsTableOrderingComposer,
          $$MealsTableAnnotationComposer,
          $$MealsTableCreateCompanionBuilder,
          $$MealsTableUpdateCompanionBuilder,
          (Meal, $$MealsTableReferences),
          Meal,
          PrefetchHooks Function({bool mealIngredientsRefs})
        > {
  $$MealsTableTableManager(_$AppDatabase db, $MealsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> eatenAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealsCompanion(
                id: id,
                name: name,
                eatenAt: eatenAt,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime eatenAt,
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealsCompanion.insert(
                id: id,
                name: name,
                eatenAt: eatenAt,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MealsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({mealIngredientsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (mealIngredientsRefs) db.mealIngredients,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mealIngredientsRefs)
                    await $_getPrefetchedData<
                      Meal,
                      $MealsTable,
                      MealIngredient
                    >(
                      currentTable: table,
                      referencedTable: $$MealsTableReferences
                          ._mealIngredientsRefsTable(db),
                      managerFromTypedResult: (p0) => $$MealsTableReferences(
                        db,
                        table,
                        p0,
                      ).mealIngredientsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.mealId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MealsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealsTable,
      Meal,
      $$MealsTableFilterComposer,
      $$MealsTableOrderingComposer,
      $$MealsTableAnnotationComposer,
      $$MealsTableCreateCompanionBuilder,
      $$MealsTableUpdateCompanionBuilder,
      (Meal, $$MealsTableReferences),
      Meal,
      PrefetchHooks Function({bool mealIngredientsRefs})
    >;
typedef $$MealIngredientsTableCreateCompanionBuilder =
    MealIngredientsCompanion Function({
      required String id,
      required String mealId,
      required String ingredientId,
      required double grams,
      Value<int> rowid,
    });
typedef $$MealIngredientsTableUpdateCompanionBuilder =
    MealIngredientsCompanion Function({
      Value<String> id,
      Value<String> mealId,
      Value<String> ingredientId,
      Value<double> grams,
      Value<int> rowid,
    });

final class $$MealIngredientsTableReferences
    extends
        BaseReferences<_$AppDatabase, $MealIngredientsTable, MealIngredient> {
  $$MealIngredientsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MealsTable _mealIdTable(_$AppDatabase db) => db.meals.createAlias(
    $_aliasNameGenerator(db.mealIngredients.mealId, db.meals.id),
  );

  $$MealsTableProcessedTableManager get mealId {
    final $_column = $_itemColumn<String>('meal_id')!;

    final manager = $$MealsTableTableManager(
      $_db,
      $_db.meals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mealIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $IngredientsTable _ingredientIdTable(_$AppDatabase db) =>
      db.ingredients.createAlias(
        $_aliasNameGenerator(
          db.mealIngredients.ingredientId,
          db.ingredients.id,
        ),
      );

  $$IngredientsTableProcessedTableManager get ingredientId {
    final $_column = $_itemColumn<String>('ingredient_id')!;

    final manager = $$IngredientsTableTableManager(
      $_db,
      $_db.ingredients,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MealIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $MealIngredientsTable> {
  $$MealIngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  $$MealsTableFilterComposer get mealId {
    final $$MealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableFilterComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$IngredientsTableFilterComposer get ingredientId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingredientId,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableFilterComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealIngredientsTable> {
  $$MealIngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  $$MealsTableOrderingComposer get mealId {
    final $$MealsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableOrderingComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$IngredientsTableOrderingComposer get ingredientId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingredientId,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableOrderingComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealIngredientsTable> {
  $$MealIngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  $$MealsTableAnnotationComposer get mealId {
    final $$MealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mealId,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealsTableAnnotationComposer(
            $db: $db,
            $table: $db.meals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$IngredientsTableAnnotationComposer get ingredientId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ingredientId,
      referencedTable: $db.ingredients,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IngredientsTableAnnotationComposer(
            $db: $db,
            $table: $db.ingredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealIngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealIngredientsTable,
          MealIngredient,
          $$MealIngredientsTableFilterComposer,
          $$MealIngredientsTableOrderingComposer,
          $$MealIngredientsTableAnnotationComposer,
          $$MealIngredientsTableCreateCompanionBuilder,
          $$MealIngredientsTableUpdateCompanionBuilder,
          (MealIngredient, $$MealIngredientsTableReferences),
          MealIngredient,
          PrefetchHooks Function({bool mealId, bool ingredientId})
        > {
  $$MealIngredientsTableTableManager(
    _$AppDatabase db,
    $MealIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealIngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mealId = const Value.absent(),
                Value<String> ingredientId = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealIngredientsCompanion(
                id: id,
                mealId: mealId,
                ingredientId: ingredientId,
                grams: grams,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mealId,
                required String ingredientId,
                required double grams,
                Value<int> rowid = const Value.absent(),
              }) => MealIngredientsCompanion.insert(
                id: id,
                mealId: mealId,
                ingredientId: ingredientId,
                grams: grams,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MealIngredientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mealId = false, ingredientId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mealId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mealId,
                                referencedTable:
                                    $$MealIngredientsTableReferences
                                        ._mealIdTable(db),
                                referencedColumn:
                                    $$MealIngredientsTableReferences
                                        ._mealIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (ingredientId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ingredientId,
                                referencedTable:
                                    $$MealIngredientsTableReferences
                                        ._ingredientIdTable(db),
                                referencedColumn:
                                    $$MealIngredientsTableReferences
                                        ._ingredientIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MealIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealIngredientsTable,
      MealIngredient,
      $$MealIngredientsTableFilterComposer,
      $$MealIngredientsTableOrderingComposer,
      $$MealIngredientsTableAnnotationComposer,
      $$MealIngredientsTableCreateCompanionBuilder,
      $$MealIngredientsTableUpdateCompanionBuilder,
      (MealIngredient, $$MealIngredientsTableReferences),
      MealIngredient,
      PrefetchHooks Function({bool mealId, bool ingredientId})
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      required String id,
      required String type,
      Value<String?> exerciseName,
      required double targetWeightKg,
      Value<String?> direction,
      Value<DateTime?> targetDate,
      Value<int> rowid,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String?> exerciseName,
      Value<double> targetWeightKg,
      Value<String?> direction,
      Value<DateTime?> targetDate,
      Value<int> rowid,
    });

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> exerciseName = const Value.absent(),
                Value<double> targetWeightKg = const Value.absent(),
                Value<String?> direction = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                type: type,
                exerciseName: exerciseName,
                targetWeightKg: targetWeightKg,
                direction: direction,
                targetDate: targetDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                Value<String?> exerciseName = const Value.absent(),
                required double targetWeightKg,
                Value<String?> direction = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                type: type,
                exerciseName: exerciseName,
                targetWeightKg: targetWeightKg,
                direction: direction,
                targetDate: targetDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;
typedef $$UserProfileTableCreateCompanionBuilder =
    UserProfileCompanion Function({
      required String id,
      required DateTime birthDate,
      required Gender gender,
      required double heightCm,
      required String activityLevel,
      Value<int> rowid,
    });
typedef $$UserProfileTableUpdateCompanionBuilder =
    UserProfileCompanion Function({
      Value<String> id,
      Value<DateTime> birthDate,
      Value<Gender> gender,
      Value<double> heightCm,
      Value<String> activityLevel,
      Value<int> rowid,
    });

class $$UserProfileTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Gender, Gender, String> get gender =>
      $composableBuilder(
        column: $table.gender,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Gender, String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<String> get activityLevel => $composableBuilder(
    column: $table.activityLevel,
    builder: (column) => column,
  );
}

class $$UserProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfileTable,
          UserProfileData,
          $$UserProfileTableFilterComposer,
          $$UserProfileTableOrderingComposer,
          $$UserProfileTableAnnotationComposer,
          $$UserProfileTableCreateCompanionBuilder,
          $$UserProfileTableUpdateCompanionBuilder,
          (
            UserProfileData,
            BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileData>,
          ),
          UserProfileData,
          PrefetchHooks Function()
        > {
  $$UserProfileTableTableManager(_$AppDatabase db, $UserProfileTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> birthDate = const Value.absent(),
                Value<Gender> gender = const Value.absent(),
                Value<double> heightCm = const Value.absent(),
                Value<String> activityLevel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfileCompanion(
                id: id,
                birthDate: birthDate,
                gender: gender,
                heightCm: heightCm,
                activityLevel: activityLevel,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime birthDate,
                required Gender gender,
                required double heightCm,
                required String activityLevel,
                Value<int> rowid = const Value.absent(),
              }) => UserProfileCompanion.insert(
                id: id,
                birthDate: birthDate,
                gender: gender,
                heightCm: heightCm,
                activityLevel: activityLevel,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfileTable,
      UserProfileData,
      $$UserProfileTableFilterComposer,
      $$UserProfileTableOrderingComposer,
      $$UserProfileTableAnnotationComposer,
      $$UserProfileTableCreateCompanionBuilder,
      $$UserProfileTableUpdateCompanionBuilder,
      (
        UserProfileData,
        BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileData>,
      ),
      UserProfileData,
      PrefetchHooks Function()
    >;
typedef $$BodyWeightEntriesTableCreateCompanionBuilder =
    BodyWeightEntriesCompanion Function({
      required String id,
      required DateTime date,
      required double weightKg,
      Value<int> rowid,
    });
typedef $$BodyWeightEntriesTableUpdateCompanionBuilder =
    BodyWeightEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<double> weightKg,
      Value<int> rowid,
    });

class $$BodyWeightEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BodyWeightEntriesTable> {
  $$BodyWeightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BodyWeightEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyWeightEntriesTable> {
  $$BodyWeightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BodyWeightEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyWeightEntriesTable> {
  $$BodyWeightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);
}

class $$BodyWeightEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BodyWeightEntriesTable,
          BodyWeightEntry,
          $$BodyWeightEntriesTableFilterComposer,
          $$BodyWeightEntriesTableOrderingComposer,
          $$BodyWeightEntriesTableAnnotationComposer,
          $$BodyWeightEntriesTableCreateCompanionBuilder,
          $$BodyWeightEntriesTableUpdateCompanionBuilder,
          (
            BodyWeightEntry,
            BaseReferences<
              _$AppDatabase,
              $BodyWeightEntriesTable,
              BodyWeightEntry
            >,
          ),
          BodyWeightEntry,
          PrefetchHooks Function()
        > {
  $$BodyWeightEntriesTableTableManager(
    _$AppDatabase db,
    $BodyWeightEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyWeightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyWeightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyWeightEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BodyWeightEntriesCompanion(
                id: id,
                date: date,
                weightKg: weightKg,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                required double weightKg,
                Value<int> rowid = const Value.absent(),
              }) => BodyWeightEntriesCompanion.insert(
                id: id,
                date: date,
                weightKg: weightKg,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BodyWeightEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BodyWeightEntriesTable,
      BodyWeightEntry,
      $$BodyWeightEntriesTableFilterComposer,
      $$BodyWeightEntriesTableOrderingComposer,
      $$BodyWeightEntriesTableAnnotationComposer,
      $$BodyWeightEntriesTableCreateCompanionBuilder,
      $$BodyWeightEntriesTableUpdateCompanionBuilder,
      (
        BodyWeightEntry,
        BaseReferences<_$AppDatabase, $BodyWeightEntriesTable, BodyWeightEntry>,
      ),
      BodyWeightEntry,
      PrefetchHooks Function()
    >;
typedef $$WaterConsumptionTableCreateCompanionBuilder =
    WaterConsumptionCompanion Function({
      required String id,
      required DateTime date,
      required double liters,
      Value<int> rowid,
    });
typedef $$WaterConsumptionTableUpdateCompanionBuilder =
    WaterConsumptionCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<double> liters,
      Value<int> rowid,
    });

class $$WaterConsumptionTableFilterComposer
    extends Composer<_$AppDatabase, $WaterConsumptionTable> {
  $$WaterConsumptionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get liters => $composableBuilder(
    column: $table.liters,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WaterConsumptionTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterConsumptionTable> {
  $$WaterConsumptionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get liters => $composableBuilder(
    column: $table.liters,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WaterConsumptionTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterConsumptionTable> {
  $$WaterConsumptionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get liters =>
      $composableBuilder(column: $table.liters, builder: (column) => column);
}

class $$WaterConsumptionTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterConsumptionTable,
          WaterConsumptionData,
          $$WaterConsumptionTableFilterComposer,
          $$WaterConsumptionTableOrderingComposer,
          $$WaterConsumptionTableAnnotationComposer,
          $$WaterConsumptionTableCreateCompanionBuilder,
          $$WaterConsumptionTableUpdateCompanionBuilder,
          (
            WaterConsumptionData,
            BaseReferences<
              _$AppDatabase,
              $WaterConsumptionTable,
              WaterConsumptionData
            >,
          ),
          WaterConsumptionData,
          PrefetchHooks Function()
        > {
  $$WaterConsumptionTableTableManager(
    _$AppDatabase db,
    $WaterConsumptionTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaterConsumptionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaterConsumptionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaterConsumptionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> liters = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaterConsumptionCompanion(
                id: id,
                date: date,
                liters: liters,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                required double liters,
                Value<int> rowid = const Value.absent(),
              }) => WaterConsumptionCompanion.insert(
                id: id,
                date: date,
                liters: liters,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WaterConsumptionTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterConsumptionTable,
      WaterConsumptionData,
      $$WaterConsumptionTableFilterComposer,
      $$WaterConsumptionTableOrderingComposer,
      $$WaterConsumptionTableAnnotationComposer,
      $$WaterConsumptionTableCreateCompanionBuilder,
      $$WaterConsumptionTableUpdateCompanionBuilder,
      (
        WaterConsumptionData,
        BaseReferences<
          _$AppDatabase,
          $WaterConsumptionTable,
          WaterConsumptionData
        >,
      ),
      WaterConsumptionData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$ExerciseBodyPartsTableTableManager get exerciseBodyParts =>
      $$ExerciseBodyPartsTableTableManager(_db, _db.exerciseBodyParts);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$WeightSetsTableTableManager get weightSets =>
      $$WeightSetsTableTableManager(_db, _db.weightSets);
  $$CardioSetsTableTableManager get cardioSets =>
      $$CardioSetsTableTableManager(_db, _db.cardioSets);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db, _db.ingredients);
  $$IngredientComponentsTableTableManager get ingredientComponents =>
      $$IngredientComponentsTableTableManager(_db, _db.ingredientComponents);
  $$MealsTableTableManager get meals =>
      $$MealsTableTableManager(_db, _db.meals);
  $$MealIngredientsTableTableManager get mealIngredients =>
      $$MealIngredientsTableTableManager(_db, _db.mealIngredients);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db, _db.userProfile);
  $$BodyWeightEntriesTableTableManager get bodyWeightEntries =>
      $$BodyWeightEntriesTableTableManager(_db, _db.bodyWeightEntries);
  $$WaterConsumptionTableTableManager get waterConsumption =>
      $$WaterConsumptionTableTableManager(_db, _db.waterConsumption);
}
