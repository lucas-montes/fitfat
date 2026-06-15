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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
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
    category,
    type,
    met,
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
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
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
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      met: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}met'],
      )!,
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
  final String category;
  final String type;
  final double met;
  final String? creatorId;
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.met,
    this.creatorId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['type'] = Variable<String>(type);
    map['met'] = Variable<double>(met);
    if (!nullToAbsent || creatorId != null) {
      map['creator_id'] = Variable<String>(creatorId);
    }
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      type: Value(type),
      met: Value(met),
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
      category: serializer.fromJson<String>(json['category']),
      type: serializer.fromJson<String>(json['type']),
      met: serializer.fromJson<double>(json['met']),
      creatorId: serializer.fromJson<String?>(json['creatorId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'type': serializer.toJson<String>(type),
      'met': serializer.toJson<double>(met),
      'creatorId': serializer.toJson<String?>(creatorId),
    };
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? category,
    String? type,
    double? met,
    Value<String?> creatorId = const Value.absent(),
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    type: type ?? this.type,
    met: met ?? this.met,
    creatorId: creatorId.present ? creatorId.value : this.creatorId,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      type: data.type.present ? data.type.value : this.type,
      met: data.met.present ? data.met.value : this.met,
      creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('met: $met, ')
          ..write('creatorId: $creatorId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, category, type, met, creatorId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.type == this.type &&
          other.met == this.met &&
          other.creatorId == this.creatorId);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<String> type;
  final Value<double> met;
  final Value<String?> creatorId;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.type = const Value.absent(),
    this.met = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String name,
    required String category,
    this.type = const Value.absent(),
    this.met = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? type,
    Expression<double>? met,
    Expression<String>? creatorId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (type != null) 'type': type,
      if (met != null) 'met': met,
      if (creatorId != null) 'creator_id': creatorId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<String>? type,
    Value<double>? met,
    Value<String?>? creatorId,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      met: met ?? this.met,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (met.present) {
      map['met'] = Variable<double>(met.value);
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
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('met: $met, ')
          ..write('creatorId: $creatorId, ')
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

class $SeancesTable extends Seances with TableInfo<$SeancesTable, Seance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeancesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restBetweenSetsMillisMeta =
      const VerificationMeta('restBetweenSetsMillis');
  @override
  late final GeneratedColumn<int> restBetweenSetsMillis = GeneratedColumn<int>(
    'rest_between_sets_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60000),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    startedAt,
    completedAt,
    restBetweenSetsMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seances';
  @override
  VerificationContext validateIntegrity(
    Insertable<Seance> instance, {
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
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('rest_between_sets_millis')) {
      context.handle(
        _restBetweenSetsMillisMeta,
        restBetweenSetsMillis.isAcceptableOrUnknown(
          data['rest_between_sets_millis']!,
          _restBetweenSetsMillisMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Seance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Seance(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      restBetweenSetsMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_between_sets_millis'],
      )!,
    );
  }

  @override
  $SeancesTable createAlias(String alias) {
    return $SeancesTable(attachedDatabase, alias);
  }
}

class Seance extends DataClass implements Insertable<Seance> {
  final String id;
  final String name;
  final DateTime startedAt;
  final DateTime completedAt;
  final int restBetweenSetsMillis;
  const Seance({
    required this.id,
    required this.name,
    required this.startedAt,
    required this.completedAt,
    required this.restBetweenSetsMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['rest_between_sets_millis'] = Variable<int>(restBetweenSetsMillis);
    return map;
  }

  SeancesCompanion toCompanion(bool nullToAbsent) {
    return SeancesCompanion(
      id: Value(id),
      name: Value(name),
      startedAt: Value(startedAt),
      completedAt: Value(completedAt),
      restBetweenSetsMillis: Value(restBetweenSetsMillis),
    );
  }

  factory Seance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Seance(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      restBetweenSetsMillis: serializer.fromJson<int>(
        json['restBetweenSetsMillis'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'restBetweenSetsMillis': serializer.toJson<int>(restBetweenSetsMillis),
    };
  }

  Seance copyWith({
    String? id,
    String? name,
    DateTime? startedAt,
    DateTime? completedAt,
    int? restBetweenSetsMillis,
  }) => Seance(
    id: id ?? this.id,
    name: name ?? this.name,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    restBetweenSetsMillis: restBetweenSetsMillis ?? this.restBetweenSetsMillis,
  );
  Seance copyWithCompanion(SeancesCompanion data) {
    return Seance(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      restBetweenSetsMillis: data.restBetweenSetsMillis.present
          ? data.restBetweenSetsMillis.value
          : this.restBetweenSetsMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Seance(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('restBetweenSetsMillis: $restBetweenSetsMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, startedAt, completedAt, restBetweenSetsMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Seance &&
          other.id == this.id &&
          other.name == this.name &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.restBetweenSetsMillis == this.restBetweenSetsMillis);
}

class SeancesCompanion extends UpdateCompanion<Seance> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> startedAt;
  final Value<DateTime> completedAt;
  final Value<int> restBetweenSetsMillis;
  final Value<int> rowid;
  const SeancesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.restBetweenSetsMillis = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeancesCompanion.insert({
    required String id,
    required String name,
    required DateTime startedAt,
    required DateTime completedAt,
    this.restBetweenSetsMillis = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       startedAt = Value(startedAt),
       completedAt = Value(completedAt);
  static Insertable<Seance> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? restBetweenSetsMillis,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (restBetweenSetsMillis != null)
        'rest_between_sets_millis': restBetweenSetsMillis,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeancesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? startedAt,
    Value<DateTime>? completedAt,
    Value<int>? restBetweenSetsMillis,
    Value<int>? rowid,
  }) {
    return SeancesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      restBetweenSetsMillis:
          restBetweenSetsMillis ?? this.restBetweenSetsMillis,
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
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (restBetweenSetsMillis.present) {
      map['rest_between_sets_millis'] = Variable<int>(
        restBetweenSetsMillis.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeancesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('restBetweenSetsMillis: $restBetweenSetsMillis, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseEntriesTable extends ExerciseEntries
    with TableInfo<$ExerciseEntriesTable, ExerciseEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seanceIdMeta = const VerificationMeta(
    'seanceId',
  );
  @override
  late final GeneratedColumn<String> seanceId = GeneratedColumn<String>(
    'seance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES seances (id)',
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seanceId,
    exerciseId,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('seance_id')) {
      context.handle(
        _seanceIdMeta,
        seanceId.isAcceptableOrUnknown(data['seance_id']!, _seanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seanceIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      seanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seance_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $ExerciseEntriesTable createAlias(String alias) {
    return $ExerciseEntriesTable(attachedDatabase, alias);
  }
}

class ExerciseEntry extends DataClass implements Insertable<ExerciseEntry> {
  final String id;
  final String seanceId;
  final String exerciseId;
  final DateTime startedAt;
  final DateTime completedAt;
  const ExerciseEntry({
    required this.id,
    required this.seanceId,
    required this.exerciseId,
    required this.startedAt,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['seance_id'] = Variable<String>(seanceId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  ExerciseEntriesCompanion toCompanion(bool nullToAbsent) {
    return ExerciseEntriesCompanion(
      id: Value(id),
      seanceId: Value(seanceId),
      exerciseId: Value(exerciseId),
      startedAt: Value(startedAt),
      completedAt: Value(completedAt),
    );
  }

  factory ExerciseEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseEntry(
      id: serializer.fromJson<String>(json['id']),
      seanceId: serializer.fromJson<String>(json['seanceId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'seanceId': serializer.toJson<String>(seanceId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  ExerciseEntry copyWith({
    String? id,
    String? seanceId,
    String? exerciseId,
    DateTime? startedAt,
    DateTime? completedAt,
  }) => ExerciseEntry(
    id: id ?? this.id,
    seanceId: seanceId ?? this.seanceId,
    exerciseId: exerciseId ?? this.exerciseId,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
  );
  ExerciseEntry copyWithCompanion(ExerciseEntriesCompanion data) {
    return ExerciseEntry(
      id: data.id.present ? data.id.value : this.id,
      seanceId: data.seanceId.present ? data.seanceId.value : this.seanceId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseEntry(')
          ..write('id: $id, ')
          ..write('seanceId: $seanceId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, seanceId, exerciseId, startedAt, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseEntry &&
          other.id == this.id &&
          other.seanceId == this.seanceId &&
          other.exerciseId == this.exerciseId &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class ExerciseEntriesCompanion extends UpdateCompanion<ExerciseEntry> {
  final Value<String> id;
  final Value<String> seanceId;
  final Value<String> exerciseId;
  final Value<DateTime> startedAt;
  final Value<DateTime> completedAt;
  final Value<int> rowid;
  const ExerciseEntriesCompanion({
    this.id = const Value.absent(),
    this.seanceId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseEntriesCompanion.insert({
    required String id,
    required String seanceId,
    required String exerciseId,
    required DateTime startedAt,
    required DateTime completedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seanceId = Value(seanceId),
       exerciseId = Value(exerciseId),
       startedAt = Value(startedAt),
       completedAt = Value(completedAt);
  static Insertable<ExerciseEntry> custom({
    Expression<String>? id,
    Expression<String>? seanceId,
    Expression<String>? exerciseId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seanceId != null) 'seance_id': seanceId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? seanceId,
    Value<String>? exerciseId,
    Value<DateTime>? startedAt,
    Value<DateTime>? completedAt,
    Value<int>? rowid,
  }) {
    return ExerciseEntriesCompanion(
      id: id ?? this.id,
      seanceId: seanceId ?? this.seanceId,
      exerciseId: exerciseId ?? this.exerciseId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seanceId.present) {
      map['seance_id'] = Variable<String>(seanceId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseEntriesCompanion(')
          ..write('id: $id, ')
          ..write('seanceId: $seanceId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseSetsTable extends ExerciseSets
    with TableInfo<$ExerciseSetsTable, ExerciseSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercise_entries (id)',
    ),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    reps,
    weight,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    } else if (isInserting) {
      context.missing(_weightMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $ExerciseSetsTable createAlias(String alias) {
    return $ExerciseSetsTable(attachedDatabase, alias);
  }
}

class ExerciseSet extends DataClass implements Insertable<ExerciseSet> {
  final String id;
  final String entryId;
  final int reps;
  final double weight;
  final DateTime? completedAt;
  const ExerciseSet({
    required this.id,
    required this.entryId,
    required this.reps,
    required this.weight,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['reps'] = Variable<int>(reps);
    map['weight'] = Variable<double>(weight);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  ExerciseSetsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseSetsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      reps: Value(reps),
      weight: Value(weight),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory ExerciseSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseSet(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      reps: serializer.fromJson<int>(json['reps']),
      weight: serializer.fromJson<double>(json['weight']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'reps': serializer.toJson<int>(reps),
      'weight': serializer.toJson<double>(weight),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  ExerciseSet copyWith({
    String? id,
    String? entryId,
    int? reps,
    double? weight,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => ExerciseSet(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    reps: reps ?? this.reps,
    weight: weight ?? this.weight,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  ExerciseSet copyWithCompanion(ExerciseSetsCompanion data) {
    return ExerciseSet(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      reps: data.reps.present ? data.reps.value : this.reps,
      weight: data.weight.present ? data.weight.value : this.weight,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSet(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, reps, weight, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseSet &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.reps == this.reps &&
          other.weight == this.weight &&
          other.completedAt == this.completedAt);
}

class ExerciseSetsCompanion extends UpdateCompanion<ExerciseSet> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<int> reps;
  final Value<double> weight;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const ExerciseSetsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseSetsCompanion.insert({
    required String id,
    required String entryId,
    required int reps,
    required double weight,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       reps = Value(reps),
       weight = Value(weight);
  static Insertable<ExerciseSet> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<int>? reps,
    Expression<double>? weight,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseSetsCompanion copyWith({
    Value<String>? id,
    Value<String>? entryId,
    Value<int>? reps,
    Value<double>? weight,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return ExerciseSetsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSetsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, Template> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<Template> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Template map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Template(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class Template extends DataClass implements Insertable<Template> {
  final String id;
  final String name;
  const Template({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(id: Value(id), name: Value(name));
  }

  factory Template.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Template(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Template copyWith({String? id, String? name}) =>
      Template(id: id ?? this.id, name: name ?? this.name);
  Template copyWithCompanion(TemplatesCompanion data) {
    return Template(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Template(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Template && other.id == this.id && other.name == this.name);
}

class TemplatesCompanion extends UpdateCompanion<Template> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    required String id,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Template> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplateExercisesTable extends TemplateExercises
    with TableInfo<$TemplateExercisesTable, TemplateExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES templates (id)',
    ),
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
  @override
  List<GeneratedColumn> get $columns => [id, templateId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TemplateExercisesTable createAlias(String alias) {
    return $TemplateExercisesTable(attachedDatabase, alias);
  }
}

class TemplateExercise extends DataClass
    implements Insertable<TemplateExercise> {
  final String id;
  final String templateId;
  final String name;
  const TemplateExercise({
    required this.id,
    required this.templateId,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['name'] = Variable<String>(name);
    return map;
  }

  TemplateExercisesCompanion toCompanion(bool nullToAbsent) {
    return TemplateExercisesCompanion(
      id: Value(id),
      templateId: Value(templateId),
      name: Value(name),
    );
  }

  factory TemplateExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateExercise(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String>(templateId),
      'name': serializer.toJson<String>(name),
    };
  }

  TemplateExercise copyWith({String? id, String? templateId, String? name}) =>
      TemplateExercise(
        id: id ?? this.id,
        templateId: templateId ?? this.templateId,
        name: name ?? this.name,
      );
  TemplateExercise copyWithCompanion(TemplateExercisesCompanion data) {
    return TemplateExercise(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercise(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, templateId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateExercise &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.name == this.name);
}

class TemplateExercisesCompanion extends UpdateCompanion<TemplateExercise> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<String> name;
  final Value<int> rowid;
  const TemplateExercisesCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateExercisesCompanion.insert({
    required String id,
    required String templateId,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateId = Value(templateId),
       name = Value(name);
  static Insertable<TemplateExercise> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? templateId,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return TemplateExercisesCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercisesCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplateSetsTable extends TemplateSets
    with TableInfo<$TemplateSetsTable, TemplateSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateExerciseIdMeta =
      const VerificationMeta('templateExerciseId');
  @override
  late final GeneratedColumn<String> templateExerciseId =
      GeneratedColumn<String>(
        'template_exercise_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES template_exercises (id)',
        ),
      );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _restSecondsMeta = const VerificationMeta(
    'restSeconds',
  );
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
    'rest_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateExerciseId,
    reps,
    weightKg,
    restSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_exercise_id')) {
      context.handle(
        _templateExerciseIdMeta,
        templateExerciseId.isAcceptableOrUnknown(
          data['template_exercise_id']!,
          _templateExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateExerciseIdMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
        _restSecondsMeta,
        restSeconds.isAcceptableOrUnknown(
          data['rest_seconds']!,
          _restSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_exercise_id'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      restSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_seconds'],
      )!,
    );
  }

  @override
  $TemplateSetsTable createAlias(String alias) {
    return $TemplateSetsTable(attachedDatabase, alias);
  }
}

class TemplateSet extends DataClass implements Insertable<TemplateSet> {
  final String id;
  final String templateExerciseId;
  final int reps;
  final double weightKg;
  final int restSeconds;
  const TemplateSet({
    required this.id,
    required this.templateExerciseId,
    required this.reps,
    required this.weightKg,
    required this.restSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_exercise_id'] = Variable<String>(templateExerciseId);
    map['reps'] = Variable<int>(reps);
    map['weight_kg'] = Variable<double>(weightKg);
    map['rest_seconds'] = Variable<int>(restSeconds);
    return map;
  }

  TemplateSetsCompanion toCompanion(bool nullToAbsent) {
    return TemplateSetsCompanion(
      id: Value(id),
      templateExerciseId: Value(templateExerciseId),
      reps: Value(reps),
      weightKg: Value(weightKg),
      restSeconds: Value(restSeconds),
    );
  }

  factory TemplateSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateSet(
      id: serializer.fromJson<String>(json['id']),
      templateExerciseId: serializer.fromJson<String>(
        json['templateExerciseId'],
      ),
      reps: serializer.fromJson<int>(json['reps']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      restSeconds: serializer.fromJson<int>(json['restSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateExerciseId': serializer.toJson<String>(templateExerciseId),
      'reps': serializer.toJson<int>(reps),
      'weightKg': serializer.toJson<double>(weightKg),
      'restSeconds': serializer.toJson<int>(restSeconds),
    };
  }

  TemplateSet copyWith({
    String? id,
    String? templateExerciseId,
    int? reps,
    double? weightKg,
    int? restSeconds,
  }) => TemplateSet(
    id: id ?? this.id,
    templateExerciseId: templateExerciseId ?? this.templateExerciseId,
    reps: reps ?? this.reps,
    weightKg: weightKg ?? this.weightKg,
    restSeconds: restSeconds ?? this.restSeconds,
  );
  TemplateSet copyWithCompanion(TemplateSetsCompanion data) {
    return TemplateSet(
      id: data.id.present ? data.id.value : this.id,
      templateExerciseId: data.templateExerciseId.present
          ? data.templateExerciseId.value
          : this.templateExerciseId,
      reps: data.reps.present ? data.reps.value : this.reps,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      restSeconds: data.restSeconds.present
          ? data.restSeconds.value
          : this.restSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateSet(')
          ..write('id: $id, ')
          ..write('templateExerciseId: $templateExerciseId, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('restSeconds: $restSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, templateExerciseId, reps, weightKg, restSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateSet &&
          other.id == this.id &&
          other.templateExerciseId == this.templateExerciseId &&
          other.reps == this.reps &&
          other.weightKg == this.weightKg &&
          other.restSeconds == this.restSeconds);
}

class TemplateSetsCompanion extends UpdateCompanion<TemplateSet> {
  final Value<String> id;
  final Value<String> templateExerciseId;
  final Value<int> reps;
  final Value<double> weightKg;
  final Value<int> restSeconds;
  final Value<int> rowid;
  const TemplateSetsCompanion({
    this.id = const Value.absent(),
    this.templateExerciseId = const Value.absent(),
    this.reps = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateSetsCompanion.insert({
    required String id,
    required String templateExerciseId,
    required int reps,
    required double weightKg,
    this.restSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateExerciseId = Value(templateExerciseId),
       reps = Value(reps),
       weightKg = Value(weightKg);
  static Insertable<TemplateSet> custom({
    Expression<String>? id,
    Expression<String>? templateExerciseId,
    Expression<int>? reps,
    Expression<double>? weightKg,
    Expression<int>? restSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateExerciseId != null)
        'template_exercise_id': templateExerciseId,
      if (reps != null) 'reps': reps,
      if (weightKg != null) 'weight_kg': weightKg,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateSetsCompanion copyWith({
    Value<String>? id,
    Value<String>? templateExerciseId,
    Value<int>? reps,
    Value<double>? weightKg,
    Value<int>? restSeconds,
    Value<int>? rowid,
  }) {
    return TemplateSetsCompanion(
      id: id ?? this.id,
      templateExerciseId: templateExerciseId ?? this.templateExerciseId,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      restSeconds: restSeconds ?? this.restSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateExerciseId.present) {
      map['template_exercise_id'] = Variable<String>(templateExerciseId.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateSetsCompanion(')
          ..write('id: $id, ')
          ..write('templateExerciseId: $templateExerciseId, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('restSeconds: $restSeconds, ')
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

class $WorkoutsTable extends Workouts with TableInfo<$WorkoutsTable, Workout> {
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
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
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
  static const VerificationMeta _plannedWorkoutIdMeta = const VerificationMeta(
    'plannedWorkoutId',
  );
  @override
  late final GeneratedColumn<String> plannedWorkoutId = GeneratedColumn<String>(
    'planned_workout_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isGuidedMeta = const VerificationMeta(
    'isGuided',
  );
  @override
  late final GeneratedColumn<bool> isGuided = GeneratedColumn<bool>(
    'is_guided',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_guided" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    startTime,
    endTime,
    notes,
    source,
    plannedWorkoutId,
    isGuided,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Workout> instance, {
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
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
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
    if (data.containsKey('planned_workout_id')) {
      context.handle(
        _plannedWorkoutIdMeta,
        plannedWorkoutId.isAcceptableOrUnknown(
          data['planned_workout_id']!,
          _plannedWorkoutIdMeta,
        ),
      );
    }
    if (data.containsKey('is_guided')) {
      context.handle(
        _isGuidedMeta,
        isGuided.isAcceptableOrUnknown(data['is_guided']!, _isGuidedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      plannedWorkoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_workout_id'],
      ),
      isGuided: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_guided'],
      )!,
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }
}

class Workout extends DataClass implements Insertable<Workout> {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final String source;
  final String? plannedWorkoutId;
  final bool isGuided;
  const Workout({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.notes,
    required this.source,
    this.plannedWorkoutId,
    required this.isGuided,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || plannedWorkoutId != null) {
      map['planned_workout_id'] = Variable<String>(plannedWorkoutId);
    }
    map['is_guided'] = Variable<bool>(isGuided);
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      name: Value(name),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      source: Value(source),
      plannedWorkoutId: plannedWorkoutId == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedWorkoutId),
      isGuided: Value(isGuided),
    );
  }

  factory Workout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workout(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      notes: serializer.fromJson<String?>(json['notes']),
      source: serializer.fromJson<String>(json['source']),
      plannedWorkoutId: serializer.fromJson<String?>(json['plannedWorkoutId']),
      isGuided: serializer.fromJson<bool>(json['isGuided']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'notes': serializer.toJson<String?>(notes),
      'source': serializer.toJson<String>(source),
      'plannedWorkoutId': serializer.toJson<String?>(plannedWorkoutId),
      'isGuided': serializer.toJson<bool>(isGuided),
    };
  }

  Workout copyWith({
    String? id,
    String? name,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? source,
    Value<String?> plannedWorkoutId = const Value.absent(),
    bool? isGuided,
  }) => Workout(
    id: id ?? this.id,
    name: name ?? this.name,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    notes: notes.present ? notes.value : this.notes,
    source: source ?? this.source,
    plannedWorkoutId: plannedWorkoutId.present
        ? plannedWorkoutId.value
        : this.plannedWorkoutId,
    isGuided: isGuided ?? this.isGuided,
  );
  Workout copyWithCompanion(WorkoutsCompanion data) {
    return Workout(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      notes: data.notes.present ? data.notes.value : this.notes,
      source: data.source.present ? data.source.value : this.source,
      plannedWorkoutId: data.plannedWorkoutId.present
          ? data.plannedWorkoutId.value
          : this.plannedWorkoutId,
      isGuided: data.isGuided.present ? data.isGuided.value : this.isGuided,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workout(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('plannedWorkoutId: $plannedWorkoutId, ')
          ..write('isGuided: $isGuided')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    startTime,
    endTime,
    notes,
    source,
    plannedWorkoutId,
    isGuided,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workout &&
          other.id == this.id &&
          other.name == this.name &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.notes == this.notes &&
          other.source == this.source &&
          other.plannedWorkoutId == this.plannedWorkoutId &&
          other.isGuided == this.isGuided);
}

class WorkoutsCompanion extends UpdateCompanion<Workout> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<String?> notes;
  final Value<String> source;
  final Value<String?> plannedWorkoutId;
  final Value<bool> isGuided;
  final Value<int> rowid;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.plannedWorkoutId = const Value.absent(),
    this.isGuided = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    required String id,
    required String name,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.plannedWorkoutId = const Value.absent(),
    this.isGuided = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       startTime = Value(startTime);
  static Insertable<Workout> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? notes,
    Expression<String>? source,
    Expression<String>? plannedWorkoutId,
    Expression<bool>? isGuided,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (notes != null) 'notes': notes,
      if (source != null) 'source': source,
      if (plannedWorkoutId != null) 'planned_workout_id': plannedWorkoutId,
      if (isGuided != null) 'is_guided': isGuided,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<String?>? notes,
    Value<String>? source,
    Value<String?>? plannedWorkoutId,
    Value<bool>? isGuided,
    Value<int>? rowid,
  }) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      plannedWorkoutId: plannedWorkoutId ?? this.plannedWorkoutId,
      isGuided: isGuided ?? this.isGuided,
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
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (plannedWorkoutId.present) {
      map['planned_workout_id'] = Variable<String>(plannedWorkoutId.value);
    }
    if (isGuided.present) {
      map['is_guided'] = Variable<bool>(isGuided.value);
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
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('plannedWorkoutId: $plannedWorkoutId, ')
          ..write('isGuided: $isGuided, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutEntriesTable extends WorkoutEntries
    with TableInfo<$WorkoutEntriesTable, WorkoutEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _effortMeta = const VerificationMeta('effort');
  @override
  late final GeneratedColumn<int> effort = GeneratedColumn<int>(
    'effort',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sortOrder,
    exerciseId,
    workoutId,
    note,
    effort,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('effort')) {
      context.handle(
        _effortMeta,
        effort.isAcceptableOrUnknown(data['effort']!, _effortMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      effort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effort'],
      ),
    );
  }

  @override
  $WorkoutEntriesTable createAlias(String alias) {
    return $WorkoutEntriesTable(attachedDatabase, alias);
  }
}

class WorkoutEntry extends DataClass implements Insertable<WorkoutEntry> {
  final String id;
  final int sortOrder;
  final String exerciseId;
  final String workoutId;
  final String? note;
  final int? effort;
  const WorkoutEntry({
    required this.id,
    required this.sortOrder,
    required this.exerciseId,
    required this.workoutId,
    this.note,
    this.effort,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sort_order'] = Variable<int>(sortOrder);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['workout_id'] = Variable<String>(workoutId);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || effort != null) {
      map['effort'] = Variable<int>(effort);
    }
    return map;
  }

  WorkoutEntriesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutEntriesCompanion(
      id: Value(id),
      sortOrder: Value(sortOrder),
      exerciseId: Value(exerciseId),
      workoutId: Value(workoutId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      effort: effort == null && nullToAbsent
          ? const Value.absent()
          : Value(effort),
    );
  }

  factory WorkoutEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutEntry(
      id: serializer.fromJson<String>(json['id']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      note: serializer.fromJson<String?>(json['note']),
      effort: serializer.fromJson<int?>(json['effort']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'workoutId': serializer.toJson<String>(workoutId),
      'note': serializer.toJson<String?>(note),
      'effort': serializer.toJson<int?>(effort),
    };
  }

  WorkoutEntry copyWith({
    String? id,
    int? sortOrder,
    String? exerciseId,
    String? workoutId,
    Value<String?> note = const Value.absent(),
    Value<int?> effort = const Value.absent(),
  }) => WorkoutEntry(
    id: id ?? this.id,
    sortOrder: sortOrder ?? this.sortOrder,
    exerciseId: exerciseId ?? this.exerciseId,
    workoutId: workoutId ?? this.workoutId,
    note: note.present ? note.value : this.note,
    effort: effort.present ? effort.value : this.effort,
  );
  WorkoutEntry copyWithCompanion(WorkoutEntriesCompanion data) {
    return WorkoutEntry(
      id: data.id.present ? data.id.value : this.id,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      note: data.note.present ? data.note.value : this.note,
      effort: data.effort.present ? data.effort.value : this.effort,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutEntry(')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('workoutId: $workoutId, ')
          ..write('note: $note, ')
          ..write('effort: $effort')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sortOrder, exerciseId, workoutId, note, effort);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutEntry &&
          other.id == this.id &&
          other.sortOrder == this.sortOrder &&
          other.exerciseId == this.exerciseId &&
          other.workoutId == this.workoutId &&
          other.note == this.note &&
          other.effort == this.effort);
}

class WorkoutEntriesCompanion extends UpdateCompanion<WorkoutEntry> {
  final Value<String> id;
  final Value<int> sortOrder;
  final Value<String> exerciseId;
  final Value<String> workoutId;
  final Value<String?> note;
  final Value<int?> effort;
  final Value<int> rowid;
  const WorkoutEntriesCompanion({
    this.id = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.note = const Value.absent(),
    this.effort = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutEntriesCompanion.insert({
    required String id,
    required int sortOrder,
    required String exerciseId,
    required String workoutId,
    this.note = const Value.absent(),
    this.effort = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sortOrder = Value(sortOrder),
       exerciseId = Value(exerciseId),
       workoutId = Value(workoutId);
  static Insertable<WorkoutEntry> custom({
    Expression<String>? id,
    Expression<int>? sortOrder,
    Expression<String>? exerciseId,
    Expression<String>? workoutId,
    Expression<String>? note,
    Expression<int>? effort,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (workoutId != null) 'workout_id': workoutId,
      if (note != null) 'note': note,
      if (effort != null) 'effort': effort,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutEntriesCompanion copyWith({
    Value<String>? id,
    Value<int>? sortOrder,
    Value<String>? exerciseId,
    Value<String>? workoutId,
    Value<String?>? note,
    Value<int?>? effort,
    Value<int>? rowid,
  }) {
    return WorkoutEntriesCompanion(
      id: id ?? this.id,
      sortOrder: sortOrder ?? this.sortOrder,
      exerciseId: exerciseId ?? this.exerciseId,
      workoutId: workoutId ?? this.workoutId,
      note: note ?? this.note,
      effort: effort ?? this.effort,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (effort.present) {
      map['effort'] = Variable<int>(effort.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('workoutId: $workoutId, ')
          ..write('note: $note, ')
          ..write('effort: $effort, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSetsTable extends WorkoutSets
    with TableInfo<$WorkoutSetsTable, WorkoutSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_entries (id)',
    ),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    reps,
    weightKg,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $WorkoutSetsTable createAlias(String alias) {
    return $WorkoutSetsTable(attachedDatabase, alias);
  }
}

class WorkoutSet extends DataClass implements Insertable<WorkoutSet> {
  final String id;
  final String entryId;
  final int reps;
  final double weightKg;
  final DateTime? completedAt;
  const WorkoutSet({
    required this.id,
    required this.entryId,
    required this.reps,
    required this.weightKg,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['reps'] = Variable<int>(reps);
    map['weight_kg'] = Variable<double>(weightKg);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  WorkoutSetsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      reps: Value(reps),
      weightKg: Value(weightKg),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory WorkoutSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSet(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      reps: serializer.fromJson<int>(json['reps']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'reps': serializer.toJson<int>(reps),
      'weightKg': serializer.toJson<double>(weightKg),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  WorkoutSet copyWith({
    String? id,
    String? entryId,
    int? reps,
    double? weightKg,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => WorkoutSet(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    reps: reps ?? this.reps,
    weightKg: weightKg ?? this.weightKg,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  WorkoutSet copyWithCompanion(WorkoutSetsCompanion data) {
    return WorkoutSet(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      reps: data.reps.present ? data.reps.value : this.reps,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSet(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, reps, weightKg, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSet &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.reps == this.reps &&
          other.weightKg == this.weightKg &&
          other.completedAt == this.completedAt);
}

class WorkoutSetsCompanion extends UpdateCompanion<WorkoutSet> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<int> reps;
  final Value<double> weightKg;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const WorkoutSetsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.reps = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSetsCompanion.insert({
    required String id,
    required String entryId,
    required int reps,
    required double weightKg,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       reps = Value(reps),
       weightKg = Value(weightKg);
  static Insertable<WorkoutSet> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<int>? reps,
    Expression<double>? weightKg,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (reps != null) 'reps': reps,
      if (weightKg != null) 'weight_kg': weightKg,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSetsCompanion copyWith({
    Value<String>? id,
    Value<String>? entryId,
    Value<int>? reps,
    Value<double>? weightKg,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return WorkoutSetsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardioDetailsTable extends CardioDetails
    with TableInfo<$CardioDetailsTable, CardioDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardioDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES workout_entries (id)',
    ),
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, entryId, durationMinutes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cardio_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardioDetail> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardioDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardioDetail(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
    );
  }

  @override
  $CardioDetailsTable createAlias(String alias) {
    return $CardioDetailsTable(attachedDatabase, alias);
  }
}

class CardioDetail extends DataClass implements Insertable<CardioDetail> {
  final String id;
  final String entryId;
  final int durationMinutes;
  const CardioDetail({
    required this.id,
    required this.entryId,
    required this.durationMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    return map;
  }

  CardioDetailsCompanion toCompanion(bool nullToAbsent) {
    return CardioDetailsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      durationMinutes: Value(durationMinutes),
    );
  }

  factory CardioDetail.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardioDetail(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
    };
  }

  CardioDetail copyWith({String? id, String? entryId, int? durationMinutes}) =>
      CardioDetail(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        durationMinutes: durationMinutes ?? this.durationMinutes,
      );
  CardioDetail copyWithCompanion(CardioDetailsCompanion data) {
    return CardioDetail(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardioDetail(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('durationMinutes: $durationMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, durationMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardioDetail &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.durationMinutes == this.durationMinutes);
}

class CardioDetailsCompanion extends UpdateCompanion<CardioDetail> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<int> durationMinutes;
  final Value<int> rowid;
  const CardioDetailsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardioDetailsCompanion.insert({
    required String id,
    required String entryId,
    required int durationMinutes,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       durationMinutes = Value(durationMinutes);
  static Insertable<CardioDetail> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<int>? durationMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardioDetailsCompanion copyWith({
    Value<String>? id,
    Value<String>? entryId,
    Value<int>? durationMinutes,
    Value<int>? rowid,
  }) {
    return CardioDetailsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardioDetailsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannedWorkoutsTable extends PlannedWorkouts
    with TableInfo<$PlannedWorkoutsTable, PlannedWorkout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedWorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
        false,
        type: DriftSqlType.dateTime,
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
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedWorkoutIdMeta =
      const VerificationMeta('completedWorkoutId');
  @override
  late final GeneratedColumn<String> completedWorkoutId =
      GeneratedColumn<String>(
        'completed_workout_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workouts (id)',
        ),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scheduledDate,
    name,
    notes,
    source,
    templateId,
    isCompleted,
    completedWorkoutId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedWorkout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('completed_workout_id')) {
      context.handle(
        _completedWorkoutIdMeta,
        completedWorkoutId.isAcceptableOrUnknown(
          data['completed_workout_id']!,
          _completedWorkoutIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedWorkout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedWorkout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedWorkoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_workout_id'],
      ),
    );
  }

  @override
  $PlannedWorkoutsTable createAlias(String alias) {
    return $PlannedWorkoutsTable(attachedDatabase, alias);
  }
}

class PlannedWorkout extends DataClass implements Insertable<PlannedWorkout> {
  final String id;
  final DateTime scheduledDate;
  final String name;
  final String? notes;
  final String source;
  final String? templateId;
  final bool isCompleted;
  final String? completedWorkoutId;
  const PlannedWorkout({
    required this.id,
    required this.scheduledDate,
    required this.name,
    this.notes,
    required this.source,
    this.templateId,
    required this.isCompleted,
    this.completedWorkoutId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedWorkoutId != null) {
      map['completed_workout_id'] = Variable<String>(completedWorkoutId);
    }
    return map;
  }

  PlannedWorkoutsCompanion toCompanion(bool nullToAbsent) {
    return PlannedWorkoutsCompanion(
      id: Value(id),
      scheduledDate: Value(scheduledDate),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      source: Value(source),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      isCompleted: Value(isCompleted),
      completedWorkoutId: completedWorkoutId == null && nullToAbsent
          ? const Value.absent()
          : Value(completedWorkoutId),
    );
  }

  factory PlannedWorkout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedWorkout(
      id: serializer.fromJson<String>(json['id']),
      scheduledDate: serializer.fromJson<DateTime>(json['scheduledDate']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      source: serializer.fromJson<String>(json['source']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedWorkoutId: serializer.fromJson<String?>(
        json['completedWorkoutId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scheduledDate': serializer.toJson<DateTime>(scheduledDate),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'source': serializer.toJson<String>(source),
      'templateId': serializer.toJson<String?>(templateId),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedWorkoutId': serializer.toJson<String?>(completedWorkoutId),
    };
  }

  PlannedWorkout copyWith({
    String? id,
    DateTime? scheduledDate,
    String? name,
    Value<String?> notes = const Value.absent(),
    String? source,
    Value<String?> templateId = const Value.absent(),
    bool? isCompleted,
    Value<String?> completedWorkoutId = const Value.absent(),
  }) => PlannedWorkout(
    id: id ?? this.id,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    source: source ?? this.source,
    templateId: templateId.present ? templateId.value : this.templateId,
    isCompleted: isCompleted ?? this.isCompleted,
    completedWorkoutId: completedWorkoutId.present
        ? completedWorkoutId.value
        : this.completedWorkoutId,
  );
  PlannedWorkout copyWithCompanion(PlannedWorkoutsCompanion data) {
    return PlannedWorkout(
      id: data.id.present ? data.id.value : this.id,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      source: data.source.present ? data.source.value : this.source,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedWorkoutId: data.completedWorkoutId.present
          ? data.completedWorkoutId.value
          : this.completedWorkoutId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedWorkout(')
          ..write('id: $id, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('templateId: $templateId, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedWorkoutId: $completedWorkoutId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scheduledDate,
    name,
    notes,
    source,
    templateId,
    isCompleted,
    completedWorkoutId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedWorkout &&
          other.id == this.id &&
          other.scheduledDate == this.scheduledDate &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.source == this.source &&
          other.templateId == this.templateId &&
          other.isCompleted == this.isCompleted &&
          other.completedWorkoutId == this.completedWorkoutId);
}

class PlannedWorkoutsCompanion extends UpdateCompanion<PlannedWorkout> {
  final Value<String> id;
  final Value<DateTime> scheduledDate;
  final Value<String> name;
  final Value<String?> notes;
  final Value<String> source;
  final Value<String?> templateId;
  final Value<bool> isCompleted;
  final Value<String?> completedWorkoutId;
  final Value<int> rowid;
  const PlannedWorkoutsCompanion({
    this.id = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.templateId = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedWorkoutId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannedWorkoutsCompanion.insert({
    required String id,
    required DateTime scheduledDate,
    required String name,
    this.notes = const Value.absent(),
    this.source = const Value.absent(),
    this.templateId = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedWorkoutId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scheduledDate = Value(scheduledDate),
       name = Value(name);
  static Insertable<PlannedWorkout> custom({
    Expression<String>? id,
    Expression<DateTime>? scheduledDate,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<String>? source,
    Expression<String>? templateId,
    Expression<bool>? isCompleted,
    Expression<String>? completedWorkoutId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (source != null) 'source': source,
      if (templateId != null) 'template_id': templateId,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedWorkoutId != null)
        'completed_workout_id': completedWorkoutId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannedWorkoutsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? scheduledDate,
    Value<String>? name,
    Value<String?>? notes,
    Value<String>? source,
    Value<String?>? templateId,
    Value<bool>? isCompleted,
    Value<String?>? completedWorkoutId,
    Value<int>? rowid,
  }) {
    return PlannedWorkoutsCompanion(
      id: id ?? this.id,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      templateId: templateId ?? this.templateId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedWorkoutId: completedWorkoutId ?? this.completedWorkoutId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedWorkoutId.present) {
      map['completed_workout_id'] = Variable<String>(completedWorkoutId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedWorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('source: $source, ')
          ..write('templateId: $templateId, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedWorkoutId: $completedWorkoutId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannedEntriesTable extends PlannedEntries
    with TableInfo<$PlannedEntriesTable, PlannedEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedWorkoutIdMeta = const VerificationMeta(
    'plannedWorkoutId',
  );
  @override
  late final GeneratedColumn<String> plannedWorkoutId = GeneratedColumn<String>(
    'planned_workout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES planned_workouts (id)',
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _effortTargetMeta = const VerificationMeta(
    'effortTarget',
  );
  @override
  late final GeneratedColumn<int> effortTarget = GeneratedColumn<int>(
    'effort_target',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    plannedWorkoutId,
    exerciseId,
    sortOrder,
    plannedReps,
    plannedWeightKg,
    plannedRestSeconds,
    note,
    effortTarget,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('planned_workout_id')) {
      context.handle(
        _plannedWorkoutIdMeta,
        plannedWorkoutId.isAcceptableOrUnknown(
          data['planned_workout_id']!,
          _plannedWorkoutIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedWorkoutIdMeta);
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
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('effort_target')) {
      context.handle(
        _effortTargetMeta,
        effortTarget.isAcceptableOrUnknown(
          data['effort_target']!,
          _effortTargetMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plannedWorkoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_workout_id'],
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
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      effortTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effort_target'],
      ),
    );
  }

  @override
  $PlannedEntriesTable createAlias(String alias) {
    return $PlannedEntriesTable(attachedDatabase, alias);
  }
}

class PlannedEntry extends DataClass implements Insertable<PlannedEntry> {
  final String id;
  final String plannedWorkoutId;
  final String exerciseId;
  final int sortOrder;
  final int plannedReps;
  final double plannedWeightKg;
  final int? plannedRestSeconds;
  final String? note;
  final int? effortTarget;
  const PlannedEntry({
    required this.id,
    required this.plannedWorkoutId,
    required this.exerciseId,
    required this.sortOrder,
    required this.plannedReps,
    required this.plannedWeightKg,
    this.plannedRestSeconds,
    this.note,
    this.effortTarget,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['planned_workout_id'] = Variable<String>(plannedWorkoutId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['planned_reps'] = Variable<int>(plannedReps);
    map['planned_weight_kg'] = Variable<double>(plannedWeightKg);
    if (!nullToAbsent || plannedRestSeconds != null) {
      map['planned_rest_seconds'] = Variable<int>(plannedRestSeconds);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || effortTarget != null) {
      map['effort_target'] = Variable<int>(effortTarget);
    }
    return map;
  }

  PlannedEntriesCompanion toCompanion(bool nullToAbsent) {
    return PlannedEntriesCompanion(
      id: Value(id),
      plannedWorkoutId: Value(plannedWorkoutId),
      exerciseId: Value(exerciseId),
      sortOrder: Value(sortOrder),
      plannedReps: Value(plannedReps),
      plannedWeightKg: Value(plannedWeightKg),
      plannedRestSeconds: plannedRestSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedRestSeconds),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      effortTarget: effortTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(effortTarget),
    );
  }

  factory PlannedEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedEntry(
      id: serializer.fromJson<String>(json['id']),
      plannedWorkoutId: serializer.fromJson<String>(json['plannedWorkoutId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      plannedReps: serializer.fromJson<int>(json['plannedReps']),
      plannedWeightKg: serializer.fromJson<double>(json['plannedWeightKg']),
      plannedRestSeconds: serializer.fromJson<int?>(json['plannedRestSeconds']),
      note: serializer.fromJson<String?>(json['note']),
      effortTarget: serializer.fromJson<int?>(json['effortTarget']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plannedWorkoutId': serializer.toJson<String>(plannedWorkoutId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'plannedReps': serializer.toJson<int>(plannedReps),
      'plannedWeightKg': serializer.toJson<double>(plannedWeightKg),
      'plannedRestSeconds': serializer.toJson<int?>(plannedRestSeconds),
      'note': serializer.toJson<String?>(note),
      'effortTarget': serializer.toJson<int?>(effortTarget),
    };
  }

  PlannedEntry copyWith({
    String? id,
    String? plannedWorkoutId,
    String? exerciseId,
    int? sortOrder,
    int? plannedReps,
    double? plannedWeightKg,
    Value<int?> plannedRestSeconds = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<int?> effortTarget = const Value.absent(),
  }) => PlannedEntry(
    id: id ?? this.id,
    plannedWorkoutId: plannedWorkoutId ?? this.plannedWorkoutId,
    exerciseId: exerciseId ?? this.exerciseId,
    sortOrder: sortOrder ?? this.sortOrder,
    plannedReps: plannedReps ?? this.plannedReps,
    plannedWeightKg: plannedWeightKg ?? this.plannedWeightKg,
    plannedRestSeconds: plannedRestSeconds.present
        ? plannedRestSeconds.value
        : this.plannedRestSeconds,
    note: note.present ? note.value : this.note,
    effortTarget: effortTarget.present ? effortTarget.value : this.effortTarget,
  );
  PlannedEntry copyWithCompanion(PlannedEntriesCompanion data) {
    return PlannedEntry(
      id: data.id.present ? data.id.value : this.id,
      plannedWorkoutId: data.plannedWorkoutId.present
          ? data.plannedWorkoutId.value
          : this.plannedWorkoutId,
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
      note: data.note.present ? data.note.value : this.note,
      effortTarget: data.effortTarget.present
          ? data.effortTarget.value
          : this.effortTarget,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedEntry(')
          ..write('id: $id, ')
          ..write('plannedWorkoutId: $plannedWorkoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('plannedReps: $plannedReps, ')
          ..write('plannedWeightKg: $plannedWeightKg, ')
          ..write('plannedRestSeconds: $plannedRestSeconds, ')
          ..write('note: $note, ')
          ..write('effortTarget: $effortTarget')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    plannedWorkoutId,
    exerciseId,
    sortOrder,
    plannedReps,
    plannedWeightKg,
    plannedRestSeconds,
    note,
    effortTarget,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedEntry &&
          other.id == this.id &&
          other.plannedWorkoutId == this.plannedWorkoutId &&
          other.exerciseId == this.exerciseId &&
          other.sortOrder == this.sortOrder &&
          other.plannedReps == this.plannedReps &&
          other.plannedWeightKg == this.plannedWeightKg &&
          other.plannedRestSeconds == this.plannedRestSeconds &&
          other.note == this.note &&
          other.effortTarget == this.effortTarget);
}

class PlannedEntriesCompanion extends UpdateCompanion<PlannedEntry> {
  final Value<String> id;
  final Value<String> plannedWorkoutId;
  final Value<String> exerciseId;
  final Value<int> sortOrder;
  final Value<int> plannedReps;
  final Value<double> plannedWeightKg;
  final Value<int?> plannedRestSeconds;
  final Value<String?> note;
  final Value<int?> effortTarget;
  final Value<int> rowid;
  const PlannedEntriesCompanion({
    this.id = const Value.absent(),
    this.plannedWorkoutId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.plannedReps = const Value.absent(),
    this.plannedWeightKg = const Value.absent(),
    this.plannedRestSeconds = const Value.absent(),
    this.note = const Value.absent(),
    this.effortTarget = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannedEntriesCompanion.insert({
    required String id,
    required String plannedWorkoutId,
    required String exerciseId,
    required int sortOrder,
    required int plannedReps,
    required double plannedWeightKg,
    this.plannedRestSeconds = const Value.absent(),
    this.note = const Value.absent(),
    this.effortTarget = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plannedWorkoutId = Value(plannedWorkoutId),
       exerciseId = Value(exerciseId),
       sortOrder = Value(sortOrder),
       plannedReps = Value(plannedReps),
       plannedWeightKg = Value(plannedWeightKg);
  static Insertable<PlannedEntry> custom({
    Expression<String>? id,
    Expression<String>? plannedWorkoutId,
    Expression<String>? exerciseId,
    Expression<int>? sortOrder,
    Expression<int>? plannedReps,
    Expression<double>? plannedWeightKg,
    Expression<int>? plannedRestSeconds,
    Expression<String>? note,
    Expression<int>? effortTarget,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plannedWorkoutId != null) 'planned_workout_id': plannedWorkoutId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (plannedReps != null) 'planned_reps': plannedReps,
      if (plannedWeightKg != null) 'planned_weight_kg': plannedWeightKg,
      if (plannedRestSeconds != null)
        'planned_rest_seconds': plannedRestSeconds,
      if (note != null) 'note': note,
      if (effortTarget != null) 'effort_target': effortTarget,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannedEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? plannedWorkoutId,
    Value<String>? exerciseId,
    Value<int>? sortOrder,
    Value<int>? plannedReps,
    Value<double>? plannedWeightKg,
    Value<int?>? plannedRestSeconds,
    Value<String?>? note,
    Value<int?>? effortTarget,
    Value<int>? rowid,
  }) {
    return PlannedEntriesCompanion(
      id: id ?? this.id,
      plannedWorkoutId: plannedWorkoutId ?? this.plannedWorkoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      sortOrder: sortOrder ?? this.sortOrder,
      plannedReps: plannedReps ?? this.plannedReps,
      plannedWeightKg: plannedWeightKg ?? this.plannedWeightKg,
      plannedRestSeconds: plannedRestSeconds ?? this.plannedRestSeconds,
      note: note ?? this.note,
      effortTarget: effortTarget ?? this.effortTarget,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (plannedWorkoutId.present) {
      map['planned_workout_id'] = Variable<String>(plannedWorkoutId.value);
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
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (effortTarget.present) {
      map['effort_target'] = Variable<int>(effortTarget.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedEntriesCompanion(')
          ..write('id: $id, ')
          ..write('plannedWorkoutId: $plannedWorkoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('plannedReps: $plannedReps, ')
          ..write('plannedWeightKg: $plannedWeightKg, ')
          ..write('plannedRestSeconds: $plannedRestSeconds, ')
          ..write('note: $note, ')
          ..write('effortTarget: $effortTarget, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannedCardioTable extends PlannedCardio
    with TableInfo<$PlannedCardioTable, PlannedCardioData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedCardioTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedEntryIdMeta = const VerificationMeta(
    'plannedEntryId',
  );
  @override
  late final GeneratedColumn<String> plannedEntryId = GeneratedColumn<String>(
    'planned_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES planned_entries (id)',
    ),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    plannedEntryId,
    plannedDurationMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_cardio';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedCardioData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('planned_entry_id')) {
      context.handle(
        _plannedEntryIdMeta,
        plannedEntryId.isAcceptableOrUnknown(
          data['planned_entry_id']!,
          _plannedEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedEntryIdMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedCardioData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedCardioData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      plannedEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_entry_id'],
      )!,
      plannedDurationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_duration_minutes'],
      )!,
    );
  }

  @override
  $PlannedCardioTable createAlias(String alias) {
    return $PlannedCardioTable(attachedDatabase, alias);
  }
}

class PlannedCardioData extends DataClass
    implements Insertable<PlannedCardioData> {
  final String id;
  final String plannedEntryId;
  final int plannedDurationMinutes;
  const PlannedCardioData({
    required this.id,
    required this.plannedEntryId,
    required this.plannedDurationMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['planned_entry_id'] = Variable<String>(plannedEntryId);
    map['planned_duration_minutes'] = Variable<int>(plannedDurationMinutes);
    return map;
  }

  PlannedCardioCompanion toCompanion(bool nullToAbsent) {
    return PlannedCardioCompanion(
      id: Value(id),
      plannedEntryId: Value(plannedEntryId),
      plannedDurationMinutes: Value(plannedDurationMinutes),
    );
  }

  factory PlannedCardioData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedCardioData(
      id: serializer.fromJson<String>(json['id']),
      plannedEntryId: serializer.fromJson<String>(json['plannedEntryId']),
      plannedDurationMinutes: serializer.fromJson<int>(
        json['plannedDurationMinutes'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'plannedEntryId': serializer.toJson<String>(plannedEntryId),
      'plannedDurationMinutes': serializer.toJson<int>(plannedDurationMinutes),
    };
  }

  PlannedCardioData copyWith({
    String? id,
    String? plannedEntryId,
    int? plannedDurationMinutes,
  }) => PlannedCardioData(
    id: id ?? this.id,
    plannedEntryId: plannedEntryId ?? this.plannedEntryId,
    plannedDurationMinutes:
        plannedDurationMinutes ?? this.plannedDurationMinutes,
  );
  PlannedCardioData copyWithCompanion(PlannedCardioCompanion data) {
    return PlannedCardioData(
      id: data.id.present ? data.id.value : this.id,
      plannedEntryId: data.plannedEntryId.present
          ? data.plannedEntryId.value
          : this.plannedEntryId,
      plannedDurationMinutes: data.plannedDurationMinutes.present
          ? data.plannedDurationMinutes.value
          : this.plannedDurationMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedCardioData(')
          ..write('id: $id, ')
          ..write('plannedEntryId: $plannedEntryId, ')
          ..write('plannedDurationMinutes: $plannedDurationMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, plannedEntryId, plannedDurationMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedCardioData &&
          other.id == this.id &&
          other.plannedEntryId == this.plannedEntryId &&
          other.plannedDurationMinutes == this.plannedDurationMinutes);
}

class PlannedCardioCompanion extends UpdateCompanion<PlannedCardioData> {
  final Value<String> id;
  final Value<String> plannedEntryId;
  final Value<int> plannedDurationMinutes;
  final Value<int> rowid;
  const PlannedCardioCompanion({
    this.id = const Value.absent(),
    this.plannedEntryId = const Value.absent(),
    this.plannedDurationMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannedCardioCompanion.insert({
    required String id,
    required String plannedEntryId,
    required int plannedDurationMinutes,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       plannedEntryId = Value(plannedEntryId),
       plannedDurationMinutes = Value(plannedDurationMinutes);
  static Insertable<PlannedCardioData> custom({
    Expression<String>? id,
    Expression<String>? plannedEntryId,
    Expression<int>? plannedDurationMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plannedEntryId != null) 'planned_entry_id': plannedEntryId,
      if (plannedDurationMinutes != null)
        'planned_duration_minutes': plannedDurationMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannedCardioCompanion copyWith({
    Value<String>? id,
    Value<String>? plannedEntryId,
    Value<int>? plannedDurationMinutes,
    Value<int>? rowid,
  }) {
    return PlannedCardioCompanion(
      id: id ?? this.id,
      plannedEntryId: plannedEntryId ?? this.plannedEntryId,
      plannedDurationMinutes:
          plannedDurationMinutes ?? this.plannedDurationMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (plannedEntryId.present) {
      map['planned_entry_id'] = Variable<String>(plannedEntryId.value);
    }
    if (plannedDurationMinutes.present) {
      map['planned_duration_minutes'] = Variable<int>(
        plannedDurationMinutes.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedCardioCompanion(')
          ..write('id: $id, ')
          ..write('plannedEntryId: $plannedEntryId, ')
          ..write('plannedDurationMinutes: $plannedDurationMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $IngredientsTable ingredients = $IngredientsTable(this);
  late final $IngredientComponentsTable ingredientComponents =
      $IngredientComponentsTable(this);
  late final $MealsTable meals = $MealsTable(this);
  late final $MealIngredientsTable mealIngredients = $MealIngredientsTable(
    this,
  );
  late final $SeancesTable seances = $SeancesTable(this);
  late final $ExerciseEntriesTable exerciseEntries = $ExerciseEntriesTable(
    this,
  );
  late final $ExerciseSetsTable exerciseSets = $ExerciseSetsTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $TemplateExercisesTable templateExercises =
      $TemplateExercisesTable(this);
  late final $TemplateSetsTable templateSets = $TemplateSetsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $UserProfileTable userProfile = $UserProfileTable(this);
  late final $BodyWeightEntriesTable bodyWeightEntries =
      $BodyWeightEntriesTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $WorkoutEntriesTable workoutEntries = $WorkoutEntriesTable(this);
  late final $WorkoutSetsTable workoutSets = $WorkoutSetsTable(this);
  late final $CardioDetailsTable cardioDetails = $CardioDetailsTable(this);
  late final $PlannedWorkoutsTable plannedWorkouts = $PlannedWorkoutsTable(
    this,
  );
  late final $PlannedEntriesTable plannedEntries = $PlannedEntriesTable(this);
  late final $PlannedCardioTable plannedCardio = $PlannedCardioTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exercises,
    ingredients,
    ingredientComponents,
    meals,
    mealIngredients,
    seances,
    exerciseEntries,
    exerciseSets,
    templates,
    templateExercises,
    templateSets,
    goals,
    userProfile,
    bodyWeightEntries,
    workouts,
    workoutEntries,
    workoutSets,
    cardioDetails,
    plannedWorkouts,
    plannedEntries,
    plannedCardio,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ExercisesTableCreateCompanionBuilder =
    ExercisesCompanion Function({
      required String id,
      required String name,
      required String category,
      Value<String> type,
      Value<double> met,
      Value<String?> creatorId,
      Value<int> rowid,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
      Value<String> type,
      Value<double> met,
      Value<String?> creatorId,
      Value<int> rowid,
    });

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExerciseEntriesTable, List<ExerciseEntry>>
  _exerciseEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exerciseEntries,
    aliasName: $_aliasNameGenerator(
      db.exercises.id,
      db.exerciseEntries.exerciseId,
    ),
  );

  $$ExerciseEntriesTableProcessedTableManager get exerciseEntriesRefs {
    final manager = $$ExerciseEntriesTableTableManager(
      $_db,
      $_db.exerciseEntries,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WorkoutEntriesTable, List<WorkoutEntry>>
  _workoutEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutEntries,
    aliasName: $_aliasNameGenerator(
      db.exercises.id,
      db.workoutEntries.exerciseId,
    ),
  );

  $$WorkoutEntriesTableProcessedTableManager get workoutEntriesRefs {
    final manager = $$WorkoutEntriesTableTableManager(
      $_db,
      $_db.workoutEntries,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlannedEntriesTable, List<PlannedEntry>>
  _plannedEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plannedEntries,
    aliasName: $_aliasNameGenerator(
      db.exercises.id,
      db.plannedEntries.exerciseId,
    ),
  );

  $$PlannedEntriesTableProcessedTableManager get plannedEntriesRefs {
    final manager = $$PlannedEntriesTableTableManager(
      $_db,
      $_db.plannedEntries,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_plannedEntriesRefsTable($_db));
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
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

  ColumnFilters<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> exerciseEntriesRefs(
    Expression<bool> Function($$ExerciseEntriesTableFilterComposer f) f,
  ) {
    final $$ExerciseEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseEntries,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseEntriesTableFilterComposer(
            $db: $db,
            $table: $db.exerciseEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutEntriesRefs(
    Expression<bool> Function($$WorkoutEntriesTableFilterComposer f) f,
  ) {
    final $$WorkoutEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutEntries,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutEntriesTableFilterComposer(
            $db: $db,
            $table: $db.workoutEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> plannedEntriesRefs(
    Expression<bool> Function($$PlannedEntriesTableFilterComposer f) f,
  ) {
    final $$PlannedEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedEntries,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedEntriesTableFilterComposer(
            $db: $db,
            $table: $db.plannedEntries,
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
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

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get met =>
      $composableBuilder(column: $table.met, builder: (column) => column);

  GeneratedColumn<String> get creatorId =>
      $composableBuilder(column: $table.creatorId, builder: (column) => column);

  Expression<T> exerciseEntriesRefs<T extends Object>(
    Expression<T> Function($$ExerciseEntriesTableAnnotationComposer a) f,
  ) {
    final $$ExerciseEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseEntries,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.exerciseEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workoutEntriesRefs<T extends Object>(
    Expression<T> Function($$WorkoutEntriesTableAnnotationComposer a) f,
  ) {
    final $$WorkoutEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutEntries,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> plannedEntriesRefs<T extends Object>(
    Expression<T> Function($$PlannedEntriesTableAnnotationComposer a) f,
  ) {
    final $$PlannedEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedEntries,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedEntries,
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
            bool exerciseEntriesRefs,
            bool workoutEntriesRefs,
            bool plannedEntriesRefs,
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
                Value<String> category = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> met = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                name: name,
                category: category,
                type: type,
                met: met,
                creatorId: creatorId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                Value<String> type = const Value.absent(),
                Value<double> met = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                category: category,
                type: type,
                met: met,
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
                exerciseEntriesRefs = false,
                workoutEntriesRefs = false,
                plannedEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (exerciseEntriesRefs) db.exerciseEntries,
                    if (workoutEntriesRefs) db.workoutEntries,
                    if (plannedEntriesRefs) db.plannedEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (exerciseEntriesRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          ExerciseEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._exerciseEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workoutEntriesRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          WorkoutEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._workoutEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (plannedEntriesRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          PlannedEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._plannedEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).plannedEntriesRefs,
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
        bool exerciseEntriesRefs,
        bool workoutEntriesRefs,
        bool plannedEntriesRefs,
      })
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
typedef $$SeancesTableCreateCompanionBuilder =
    SeancesCompanion Function({
      required String id,
      required String name,
      required DateTime startedAt,
      required DateTime completedAt,
      Value<int> restBetweenSetsMillis,
      Value<int> rowid,
    });
typedef $$SeancesTableUpdateCompanionBuilder =
    SeancesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> startedAt,
      Value<DateTime> completedAt,
      Value<int> restBetweenSetsMillis,
      Value<int> rowid,
    });

final class $$SeancesTableReferences
    extends BaseReferences<_$AppDatabase, $SeancesTable, Seance> {
  $$SeancesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExerciseEntriesTable, List<ExerciseEntry>>
  _exerciseEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exerciseEntries,
    aliasName: $_aliasNameGenerator(db.seances.id, db.exerciseEntries.seanceId),
  );

  $$ExerciseEntriesTableProcessedTableManager get exerciseEntriesRefs {
    final manager = $$ExerciseEntriesTableTableManager(
      $_db,
      $_db.exerciseEntries,
    ).filter((f) => f.seanceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SeancesTableFilterComposer
    extends Composer<_$AppDatabase, $SeancesTable> {
  $$SeancesTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restBetweenSetsMillis => $composableBuilder(
    column: $table.restBetweenSetsMillis,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> exerciseEntriesRefs(
    Expression<bool> Function($$ExerciseEntriesTableFilterComposer f) f,
  ) {
    final $$ExerciseEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseEntries,
      getReferencedColumn: (t) => t.seanceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseEntriesTableFilterComposer(
            $db: $db,
            $table: $db.exerciseEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SeancesTableOrderingComposer
    extends Composer<_$AppDatabase, $SeancesTable> {
  $$SeancesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restBetweenSetsMillis => $composableBuilder(
    column: $table.restBetweenSetsMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeancesTable> {
  $$SeancesTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restBetweenSetsMillis => $composableBuilder(
    column: $table.restBetweenSetsMillis,
    builder: (column) => column,
  );

  Expression<T> exerciseEntriesRefs<T extends Object>(
    Expression<T> Function($$ExerciseEntriesTableAnnotationComposer a) f,
  ) {
    final $$ExerciseEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseEntries,
      getReferencedColumn: (t) => t.seanceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.exerciseEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SeancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeancesTable,
          Seance,
          $$SeancesTableFilterComposer,
          $$SeancesTableOrderingComposer,
          $$SeancesTableAnnotationComposer,
          $$SeancesTableCreateCompanionBuilder,
          $$SeancesTableUpdateCompanionBuilder,
          (Seance, $$SeancesTableReferences),
          Seance,
          PrefetchHooks Function({bool exerciseEntriesRefs})
        > {
  $$SeancesTableTableManager(_$AppDatabase db, $SeancesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> restBetweenSetsMillis = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeancesCompanion(
                id: id,
                name: name,
                startedAt: startedAt,
                completedAt: completedAt,
                restBetweenSetsMillis: restBetweenSetsMillis,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime startedAt,
                required DateTime completedAt,
                Value<int> restBetweenSetsMillis = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeancesCompanion.insert(
                id: id,
                name: name,
                startedAt: startedAt,
                completedAt: completedAt,
                restBetweenSetsMillis: restBetweenSetsMillis,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SeancesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exerciseEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (exerciseEntriesRefs) db.exerciseEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exerciseEntriesRefs)
                    await $_getPrefetchedData<
                      Seance,
                      $SeancesTable,
                      ExerciseEntry
                    >(
                      currentTable: table,
                      referencedTable: $$SeancesTableReferences
                          ._exerciseEntriesRefsTable(db),
                      managerFromTypedResult: (p0) => $$SeancesTableReferences(
                        db,
                        table,
                        p0,
                      ).exerciseEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.seanceId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SeancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeancesTable,
      Seance,
      $$SeancesTableFilterComposer,
      $$SeancesTableOrderingComposer,
      $$SeancesTableAnnotationComposer,
      $$SeancesTableCreateCompanionBuilder,
      $$SeancesTableUpdateCompanionBuilder,
      (Seance, $$SeancesTableReferences),
      Seance,
      PrefetchHooks Function({bool exerciseEntriesRefs})
    >;
typedef $$ExerciseEntriesTableCreateCompanionBuilder =
    ExerciseEntriesCompanion Function({
      required String id,
      required String seanceId,
      required String exerciseId,
      required DateTime startedAt,
      required DateTime completedAt,
      Value<int> rowid,
    });
typedef $$ExerciseEntriesTableUpdateCompanionBuilder =
    ExerciseEntriesCompanion Function({
      Value<String> id,
      Value<String> seanceId,
      Value<String> exerciseId,
      Value<DateTime> startedAt,
      Value<DateTime> completedAt,
      Value<int> rowid,
    });

final class $$ExerciseEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExerciseEntriesTable, ExerciseEntry> {
  $$ExerciseEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SeancesTable _seanceIdTable(_$AppDatabase db) =>
      db.seances.createAlias(
        $_aliasNameGenerator(db.exerciseEntries.seanceId, db.seances.id),
      );

  $$SeancesTableProcessedTableManager get seanceId {
    final $_column = $_itemColumn<String>('seance_id')!;

    final manager = $$SeancesTableTableManager(
      $_db,
      $_db.seances,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seanceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(db.exerciseEntries.exerciseId, db.exercises.id),
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

  static MultiTypedResultKey<$ExerciseSetsTable, List<ExerciseSet>>
  _exerciseSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exerciseSets,
    aliasName: $_aliasNameGenerator(
      db.exerciseEntries.id,
      db.exerciseSets.entryId,
    ),
  );

  $$ExerciseSetsTableProcessedTableManager get exerciseSetsRefs {
    final manager = $$ExerciseSetsTableTableManager(
      $_db,
      $_db.exerciseSets,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_exerciseSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExerciseEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseEntriesTable> {
  $$ExerciseEntriesTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SeancesTableFilterComposer get seanceId {
    final $$SeancesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seanceId,
      referencedTable: $db.seances,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeancesTableFilterComposer(
            $db: $db,
            $table: $db.seances,
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

  Expression<bool> exerciseSetsRefs(
    Expression<bool> Function($$ExerciseSetsTableFilterComposer f) f,
  ) {
    final $$ExerciseSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseSets,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseSetsTableFilterComposer(
            $db: $db,
            $table: $db.exerciseSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExerciseEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseEntriesTable> {
  $$ExerciseEntriesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SeancesTableOrderingComposer get seanceId {
    final $$SeancesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seanceId,
      referencedTable: $db.seances,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeancesTableOrderingComposer(
            $db: $db,
            $table: $db.seances,
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

class $$ExerciseEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseEntriesTable> {
  $$ExerciseEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$SeancesTableAnnotationComposer get seanceId {
    final $$SeancesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seanceId,
      referencedTable: $db.seances,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeancesTableAnnotationComposer(
            $db: $db,
            $table: $db.seances,
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

  Expression<T> exerciseSetsRefs<T extends Object>(
    Expression<T> Function($$ExerciseSetsTableAnnotationComposer a) f,
  ) {
    final $$ExerciseSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseSets,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.exerciseSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExerciseEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseEntriesTable,
          ExerciseEntry,
          $$ExerciseEntriesTableFilterComposer,
          $$ExerciseEntriesTableOrderingComposer,
          $$ExerciseEntriesTableAnnotationComposer,
          $$ExerciseEntriesTableCreateCompanionBuilder,
          $$ExerciseEntriesTableUpdateCompanionBuilder,
          (ExerciseEntry, $$ExerciseEntriesTableReferences),
          ExerciseEntry,
          PrefetchHooks Function({
            bool seanceId,
            bool exerciseId,
            bool exerciseSetsRefs,
          })
        > {
  $$ExerciseEntriesTableTableManager(
    _$AppDatabase db,
    $ExerciseEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> seanceId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseEntriesCompanion(
                id: id,
                seanceId: seanceId,
                exerciseId: exerciseId,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String seanceId,
                required String exerciseId,
                required DateTime startedAt,
                required DateTime completedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExerciseEntriesCompanion.insert(
                id: id,
                seanceId: seanceId,
                exerciseId: exerciseId,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                seanceId = false,
                exerciseId = false,
                exerciseSetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (exerciseSetsRefs) db.exerciseSets,
                  ],
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
                        if (seanceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.seanceId,
                                    referencedTable:
                                        $$ExerciseEntriesTableReferences
                                            ._seanceIdTable(db),
                                    referencedColumn:
                                        $$ExerciseEntriesTableReferences
                                            ._seanceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (exerciseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.exerciseId,
                                    referencedTable:
                                        $$ExerciseEntriesTableReferences
                                            ._exerciseIdTable(db),
                                    referencedColumn:
                                        $$ExerciseEntriesTableReferences
                                            ._exerciseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (exerciseSetsRefs)
                        await $_getPrefetchedData<
                          ExerciseEntry,
                          $ExerciseEntriesTable,
                          ExerciseSet
                        >(
                          currentTable: table,
                          referencedTable: $$ExerciseEntriesTableReferences
                              ._exerciseSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExerciseEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
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

typedef $$ExerciseEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseEntriesTable,
      ExerciseEntry,
      $$ExerciseEntriesTableFilterComposer,
      $$ExerciseEntriesTableOrderingComposer,
      $$ExerciseEntriesTableAnnotationComposer,
      $$ExerciseEntriesTableCreateCompanionBuilder,
      $$ExerciseEntriesTableUpdateCompanionBuilder,
      (ExerciseEntry, $$ExerciseEntriesTableReferences),
      ExerciseEntry,
      PrefetchHooks Function({
        bool seanceId,
        bool exerciseId,
        bool exerciseSetsRefs,
      })
    >;
typedef $$ExerciseSetsTableCreateCompanionBuilder =
    ExerciseSetsCompanion Function({
      required String id,
      required String entryId,
      required int reps,
      required double weight,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$ExerciseSetsTableUpdateCompanionBuilder =
    ExerciseSetsCompanion Function({
      Value<String> id,
      Value<String> entryId,
      Value<int> reps,
      Value<double> weight,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

final class $$ExerciseSetsTableReferences
    extends BaseReferences<_$AppDatabase, $ExerciseSetsTable, ExerciseSet> {
  $$ExerciseSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExerciseEntriesTable _entryIdTable(_$AppDatabase db) =>
      db.exerciseEntries.createAlias(
        $_aliasNameGenerator(db.exerciseSets.entryId, db.exerciseEntries.id),
      );

  $$ExerciseEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$ExerciseEntriesTableTableManager(
      $_db,
      $_db.exerciseEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExerciseSetsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseSetsTable> {
  $$ExerciseSetsTableFilterComposer({
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

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ExerciseEntriesTableFilterComposer get entryId {
    final $$ExerciseEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.exerciseEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseEntriesTableFilterComposer(
            $db: $db,
            $table: $db.exerciseEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseSetsTable> {
  $$ExerciseSetsTableOrderingComposer({
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

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExerciseEntriesTableOrderingComposer get entryId {
    final $$ExerciseEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.exerciseEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.exerciseEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseSetsTable> {
  $$ExerciseSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$ExerciseEntriesTableAnnotationComposer get entryId {
    final $$ExerciseEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.exerciseEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.exerciseEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseSetsTable,
          ExerciseSet,
          $$ExerciseSetsTableFilterComposer,
          $$ExerciseSetsTableOrderingComposer,
          $$ExerciseSetsTableAnnotationComposer,
          $$ExerciseSetsTableCreateCompanionBuilder,
          $$ExerciseSetsTableUpdateCompanionBuilder,
          (ExerciseSet, $$ExerciseSetsTableReferences),
          ExerciseSet,
          PrefetchHooks Function({bool entryId})
        > {
  $$ExerciseSetsTableTableManager(_$AppDatabase db, $ExerciseSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseSetsCompanion(
                id: id,
                entryId: entryId,
                reps: reps,
                weight: weight,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryId,
                required int reps,
                required double weight,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseSetsCompanion.insert(
                id: id,
                entryId: entryId,
                reps: reps,
                weight: weight,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
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
                    if (entryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entryId,
                                referencedTable: $$ExerciseSetsTableReferences
                                    ._entryIdTable(db),
                                referencedColumn: $$ExerciseSetsTableReferences
                                    ._entryIdTable(db)
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

typedef $$ExerciseSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseSetsTable,
      ExerciseSet,
      $$ExerciseSetsTableFilterComposer,
      $$ExerciseSetsTableOrderingComposer,
      $$ExerciseSetsTableAnnotationComposer,
      $$ExerciseSetsTableCreateCompanionBuilder,
      $$ExerciseSetsTableUpdateCompanionBuilder,
      (ExerciseSet, $$ExerciseSetsTableReferences),
      ExerciseSet,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$TemplatesTableCreateCompanionBuilder =
    TemplatesCompanion Function({
      required String id,
      required String name,
      Value<int> rowid,
    });
typedef $$TemplatesTableUpdateCompanionBuilder =
    TemplatesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> rowid,
    });

final class $$TemplatesTableReferences
    extends BaseReferences<_$AppDatabase, $TemplatesTable, Template> {
  $$TemplatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TemplateExercisesTable, List<TemplateExercise>>
  _templateExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.templateExercises,
        aliasName: $_aliasNameGenerator(
          db.templates.id,
          db.templateExercises.templateId,
        ),
      );

  $$TemplateExercisesTableProcessedTableManager get templateExercisesRefs {
    final manager = $$TemplateExercisesTableTableManager(
      $_db,
      $_db.templateExercises,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _templateExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
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

  Expression<bool> templateExercisesRefs(
    Expression<bool> Function($$TemplateExercisesTableFilterComposer f) f,
  ) {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableFilterComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
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
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
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

  Expression<T> templateExercisesRefs<T extends Object>(
    Expression<T> Function($$TemplateExercisesTableAnnotationComposer a) f,
  ) {
    final $$TemplateExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.templateExercises,
          getReferencedColumn: (t) => t.templateId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TemplateExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.templateExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplatesTable,
          Template,
          $$TemplatesTableFilterComposer,
          $$TemplatesTableOrderingComposer,
          $$TemplatesTableAnnotationComposer,
          $$TemplatesTableCreateCompanionBuilder,
          $$TemplatesTableUpdateCompanionBuilder,
          (Template, $$TemplatesTableReferences),
          Template,
          PrefetchHooks Function({bool templateExercisesRefs})
        > {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion(id: id, name: name, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion.insert(id: id, name: name, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (templateExercisesRefs) db.templateExercises,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (templateExercisesRefs)
                    await $_getPrefetchedData<
                      Template,
                      $TemplatesTable,
                      TemplateExercise
                    >(
                      currentTable: table,
                      referencedTable: $$TemplatesTableReferences
                          ._templateExercisesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).templateExercisesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplatesTable,
      Template,
      $$TemplatesTableFilterComposer,
      $$TemplatesTableOrderingComposer,
      $$TemplatesTableAnnotationComposer,
      $$TemplatesTableCreateCompanionBuilder,
      $$TemplatesTableUpdateCompanionBuilder,
      (Template, $$TemplatesTableReferences),
      Template,
      PrefetchHooks Function({bool templateExercisesRefs})
    >;
typedef $$TemplateExercisesTableCreateCompanionBuilder =
    TemplateExercisesCompanion Function({
      required String id,
      required String templateId,
      required String name,
      Value<int> rowid,
    });
typedef $$TemplateExercisesTableUpdateCompanionBuilder =
    TemplateExercisesCompanion Function({
      Value<String> id,
      Value<String> templateId,
      Value<String> name,
      Value<int> rowid,
    });

final class $$TemplateExercisesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TemplateExercisesTable,
          TemplateExercise
        > {
  $$TemplateExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.templates.createAlias(
        $_aliasNameGenerator(db.templateExercises.templateId, db.templates.id),
      );

  $$TemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager = $$TemplatesTableTableManager(
      $_db,
      $_db.templates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TemplateSetsTable, List<TemplateSet>>
  _templateSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.templateSets,
    aliasName: $_aliasNameGenerator(
      db.templateExercises.id,
      db.templateSets.templateExerciseId,
    ),
  );

  $$TemplateSetsTableProcessedTableManager get templateSetsRefs {
    final manager = $$TemplateSetsTableTableManager($_db, $_db.templateSets)
        .filter(
          (f) => f.templateExerciseId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_templateSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TemplateExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableFilterComposer({
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

  $$TemplatesTableFilterComposer get templateId {
    final $$TemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableFilterComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> templateSetsRefs(
    Expression<bool> Function($$TemplateSetsTableFilterComposer f) f,
  ) {
    final $$TemplateSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateSets,
      getReferencedColumn: (t) => t.templateExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateSetsTableFilterComposer(
            $db: $db,
            $table: $db.templateSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplateExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableOrderingComposer({
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

  $$TemplatesTableOrderingComposer get templateId {
    final $$TemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableAnnotationComposer({
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

  $$TemplatesTableAnnotationComposer get templateId {
    final $$TemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> templateSetsRefs<T extends Object>(
    Expression<T> Function($$TemplateSetsTableAnnotationComposer a) f,
  ) {
    final $$TemplateSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateSets,
      getReferencedColumn: (t) => t.templateExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.templateSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplateExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateExercisesTable,
          TemplateExercise,
          $$TemplateExercisesTableFilterComposer,
          $$TemplateExercisesTableOrderingComposer,
          $$TemplateExercisesTableAnnotationComposer,
          $$TemplateExercisesTableCreateCompanionBuilder,
          $$TemplateExercisesTableUpdateCompanionBuilder,
          (TemplateExercise, $$TemplateExercisesTableReferences),
          TemplateExercise,
          PrefetchHooks Function({bool templateId, bool templateSetsRefs})
        > {
  $$TemplateExercisesTableTableManager(
    _$AppDatabase db,
    $TemplateExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateExercisesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateExercisesCompanion(
                id: id,
                templateId: templateId,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateId,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => TemplateExercisesCompanion.insert(
                id: id,
                templateId: templateId,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TemplateExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({templateId = false, templateSetsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (templateSetsRefs) db.templateSets,
                  ],
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
                        if (templateId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.templateId,
                                    referencedTable:
                                        $$TemplateExercisesTableReferences
                                            ._templateIdTable(db),
                                    referencedColumn:
                                        $$TemplateExercisesTableReferences
                                            ._templateIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (templateSetsRefs)
                        await $_getPrefetchedData<
                          TemplateExercise,
                          $TemplateExercisesTable,
                          TemplateSet
                        >(
                          currentTable: table,
                          referencedTable: $$TemplateExercisesTableReferences
                              ._templateSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TemplateExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).templateSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateExerciseId == item.id,
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

typedef $$TemplateExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateExercisesTable,
      TemplateExercise,
      $$TemplateExercisesTableFilterComposer,
      $$TemplateExercisesTableOrderingComposer,
      $$TemplateExercisesTableAnnotationComposer,
      $$TemplateExercisesTableCreateCompanionBuilder,
      $$TemplateExercisesTableUpdateCompanionBuilder,
      (TemplateExercise, $$TemplateExercisesTableReferences),
      TemplateExercise,
      PrefetchHooks Function({bool templateId, bool templateSetsRefs})
    >;
typedef $$TemplateSetsTableCreateCompanionBuilder =
    TemplateSetsCompanion Function({
      required String id,
      required String templateExerciseId,
      required int reps,
      required double weightKg,
      Value<int> restSeconds,
      Value<int> rowid,
    });
typedef $$TemplateSetsTableUpdateCompanionBuilder =
    TemplateSetsCompanion Function({
      Value<String> id,
      Value<String> templateExerciseId,
      Value<int> reps,
      Value<double> weightKg,
      Value<int> restSeconds,
      Value<int> rowid,
    });

final class $$TemplateSetsTableReferences
    extends BaseReferences<_$AppDatabase, $TemplateSetsTable, TemplateSet> {
  $$TemplateSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TemplateExercisesTable _templateExerciseIdTable(_$AppDatabase db) =>
      db.templateExercises.createAlias(
        $_aliasNameGenerator(
          db.templateSets.templateExerciseId,
          db.templateExercises.id,
        ),
      );

  $$TemplateExercisesTableProcessedTableManager get templateExerciseId {
    final $_column = $_itemColumn<String>('template_exercise_id')!;

    final manager = $$TemplateExercisesTableTableManager(
      $_db,
      $_db.templateExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TemplateSetsTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateSetsTable> {
  $$TemplateSetsTableFilterComposer({
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

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnFilters(column),
  );

  $$TemplateExercisesTableFilterComposer get templateExerciseId {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateExerciseId,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableFilterComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateSetsTable> {
  $$TemplateSetsTableOrderingComposer({
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

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  $$TemplateExercisesTableOrderingComposer get templateExerciseId {
    final $$TemplateExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateExerciseId,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateSetsTable> {
  $$TemplateSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(
    column: $table.restSeconds,
    builder: (column) => column,
  );

  $$TemplateExercisesTableAnnotationComposer get templateExerciseId {
    final $$TemplateExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.templateExerciseId,
          referencedTable: $db.templateExercises,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TemplateExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.templateExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$TemplateSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateSetsTable,
          TemplateSet,
          $$TemplateSetsTableFilterComposer,
          $$TemplateSetsTableOrderingComposer,
          $$TemplateSetsTableAnnotationComposer,
          $$TemplateSetsTableCreateCompanionBuilder,
          $$TemplateSetsTableUpdateCompanionBuilder,
          (TemplateSet, $$TemplateSetsTableReferences),
          TemplateSet,
          PrefetchHooks Function({bool templateExerciseId})
        > {
  $$TemplateSetsTableTableManager(_$AppDatabase db, $TemplateSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateExerciseId = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<int> restSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateSetsCompanion(
                id: id,
                templateExerciseId: templateExerciseId,
                reps: reps,
                weightKg: weightKg,
                restSeconds: restSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateExerciseId,
                required int reps,
                required double weightKg,
                Value<int> restSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateSetsCompanion.insert(
                id: id,
                templateExerciseId: templateExerciseId,
                reps: reps,
                weightKg: weightKg,
                restSeconds: restSeconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TemplateSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateExerciseId = false}) {
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
                    if (templateExerciseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.templateExerciseId,
                                referencedTable: $$TemplateSetsTableReferences
                                    ._templateExerciseIdTable(db),
                                referencedColumn: $$TemplateSetsTableReferences
                                    ._templateExerciseIdTable(db)
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

typedef $$TemplateSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateSetsTable,
      TemplateSet,
      $$TemplateSetsTableFilterComposer,
      $$TemplateSetsTableOrderingComposer,
      $$TemplateSetsTableAnnotationComposer,
      $$TemplateSetsTableCreateCompanionBuilder,
      $$TemplateSetsTableUpdateCompanionBuilder,
      (TemplateSet, $$TemplateSetsTableReferences),
      TemplateSet,
      PrefetchHooks Function({bool templateExerciseId})
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
typedef $$WorkoutsTableCreateCompanionBuilder =
    WorkoutsCompanion Function({
      required String id,
      required String name,
      required DateTime startTime,
      Value<DateTime?> endTime,
      Value<String?> notes,
      Value<String> source,
      Value<String?> plannedWorkoutId,
      Value<bool> isGuided,
      Value<int> rowid,
    });
typedef $$WorkoutsTableUpdateCompanionBuilder =
    WorkoutsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<String?> notes,
      Value<String> source,
      Value<String?> plannedWorkoutId,
      Value<bool> isGuided,
      Value<int> rowid,
    });

final class $$WorkoutsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutsTable, Workout> {
  $$WorkoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutEntriesTable, List<WorkoutEntry>>
  _workoutEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutEntries,
    aliasName: $_aliasNameGenerator(
      db.workouts.id,
      db.workoutEntries.workoutId,
    ),
  );

  $$WorkoutEntriesTableProcessedTableManager get workoutEntriesRefs {
    final manager = $$WorkoutEntriesTableTableManager(
      $_db,
      $_db.workoutEntries,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlannedWorkoutsTable, List<PlannedWorkout>>
  _plannedWorkoutsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plannedWorkouts,
    aliasName: $_aliasNameGenerator(
      db.workouts.id,
      db.plannedWorkouts.completedWorkoutId,
    ),
  );

  $$PlannedWorkoutsTableProcessedTableManager get plannedWorkoutsRefs {
    final manager =
        $$PlannedWorkoutsTableTableManager($_db, $_db.plannedWorkouts).filter(
          (f) => f.completedWorkoutId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _plannedWorkoutsRefsTable($_db),
    );
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

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
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

  ColumnFilters<String> get plannedWorkoutId => $composableBuilder(
    column: $table.plannedWorkoutId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGuided => $composableBuilder(
    column: $table.isGuided,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> workoutEntriesRefs(
    Expression<bool> Function($$WorkoutEntriesTableFilterComposer f) f,
  ) {
    final $$WorkoutEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutEntries,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutEntriesTableFilterComposer(
            $db: $db,
            $table: $db.workoutEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> plannedWorkoutsRefs(
    Expression<bool> Function($$PlannedWorkoutsTableFilterComposer f) f,
  ) {
    final $$PlannedWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedWorkouts,
      getReferencedColumn: (t) => t.completedWorkoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.plannedWorkouts,
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

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
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

  ColumnOrderings<String> get plannedWorkoutId => $composableBuilder(
    column: $table.plannedWorkoutId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGuided => $composableBuilder(
    column: $table.isGuided,
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

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get plannedWorkoutId => $composableBuilder(
    column: $table.plannedWorkoutId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isGuided =>
      $composableBuilder(column: $table.isGuided, builder: (column) => column);

  Expression<T> workoutEntriesRefs<T extends Object>(
    Expression<T> Function($$WorkoutEntriesTableAnnotationComposer a) f,
  ) {
    final $$WorkoutEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutEntries,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> plannedWorkoutsRefs<T extends Object>(
    Expression<T> Function($$PlannedWorkoutsTableAnnotationComposer a) f,
  ) {
    final $$PlannedWorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedWorkouts,
      getReferencedColumn: (t) => t.completedWorkoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedWorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedWorkouts,
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
          Workout,
          $$WorkoutsTableFilterComposer,
          $$WorkoutsTableOrderingComposer,
          $$WorkoutsTableAnnotationComposer,
          $$WorkoutsTableCreateCompanionBuilder,
          $$WorkoutsTableUpdateCompanionBuilder,
          (Workout, $$WorkoutsTableReferences),
          Workout,
          PrefetchHooks Function({
            bool workoutEntriesRefs,
            bool plannedWorkoutsRefs,
          })
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
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> plannedWorkoutId = const Value.absent(),
                Value<bool> isGuided = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutsCompanion(
                id: id,
                name: name,
                startTime: startTime,
                endTime: endTime,
                notes: notes,
                source: source,
                plannedWorkoutId: plannedWorkoutId,
                isGuided: isGuided,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> plannedWorkoutId = const Value.absent(),
                Value<bool> isGuided = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutsCompanion.insert(
                id: id,
                name: name,
                startTime: startTime,
                endTime: endTime,
                notes: notes,
                source: source,
                plannedWorkoutId: plannedWorkoutId,
                isGuided: isGuided,
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
              ({workoutEntriesRefs = false, plannedWorkoutsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workoutEntriesRefs) db.workoutEntries,
                    if (plannedWorkoutsRefs) db.plannedWorkouts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workoutEntriesRefs)
                        await $_getPrefetchedData<
                          Workout,
                          $WorkoutsTable,
                          WorkoutEntry
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutsTableReferences
                              ._workoutEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workoutId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (plannedWorkoutsRefs)
                        await $_getPrefetchedData<
                          Workout,
                          $WorkoutsTable,
                          PlannedWorkout
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutsTableReferences
                              ._plannedWorkoutsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).plannedWorkoutsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.completedWorkoutId == item.id,
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
      Workout,
      $$WorkoutsTableFilterComposer,
      $$WorkoutsTableOrderingComposer,
      $$WorkoutsTableAnnotationComposer,
      $$WorkoutsTableCreateCompanionBuilder,
      $$WorkoutsTableUpdateCompanionBuilder,
      (Workout, $$WorkoutsTableReferences),
      Workout,
      PrefetchHooks Function({
        bool workoutEntriesRefs,
        bool plannedWorkoutsRefs,
      })
    >;
typedef $$WorkoutEntriesTableCreateCompanionBuilder =
    WorkoutEntriesCompanion Function({
      required String id,
      required int sortOrder,
      required String exerciseId,
      required String workoutId,
      Value<String?> note,
      Value<int?> effort,
      Value<int> rowid,
    });
typedef $$WorkoutEntriesTableUpdateCompanionBuilder =
    WorkoutEntriesCompanion Function({
      Value<String> id,
      Value<int> sortOrder,
      Value<String> exerciseId,
      Value<String> workoutId,
      Value<String?> note,
      Value<int?> effort,
      Value<int> rowid,
    });

final class $$WorkoutEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutEntriesTable, WorkoutEntry> {
  $$WorkoutEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(db.workoutEntries.exerciseId, db.exercises.id),
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

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
        $_aliasNameGenerator(db.workoutEntries.workoutId, db.workouts.id),
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

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>>
  _workoutSetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutSets,
    aliasName: $_aliasNameGenerator(
      db.workoutEntries.id,
      db.workoutSets.entryId,
    ),
  );

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager(
      $_db,
      $_db.workoutSets,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CardioDetailsTable, List<CardioDetail>>
  _cardioDetailsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cardioDetails,
    aliasName: $_aliasNameGenerator(
      db.workoutEntries.id,
      db.cardioDetails.entryId,
    ),
  );

  $$CardioDetailsTableProcessedTableManager get cardioDetailsRefs {
    final manager = $$CardioDetailsTableTableManager(
      $_db,
      $_db.cardioDetails,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardioDetailsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutEntriesTable> {
  $$WorkoutEntriesTableFilterComposer({
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

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effort => $composableBuilder(
    column: $table.effort,
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

  Expression<bool> workoutSetsRefs(
    Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f,
  ) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cardioDetailsRefs(
    Expression<bool> Function($$CardioDetailsTableFilterComposer f) f,
  ) {
    final $$CardioDetailsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardioDetails,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardioDetailsTableFilterComposer(
            $db: $db,
            $table: $db.cardioDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutEntriesTable> {
  $$WorkoutEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effort => $composableBuilder(
    column: $table.effort,
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
}

class $$WorkoutEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutEntriesTable> {
  $$WorkoutEntriesTableAnnotationComposer({
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

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get effort =>
      $composableBuilder(column: $table.effort, builder: (column) => column);

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

  Expression<T> workoutSetsRefs<T extends Object>(
    Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cardioDetailsRefs<T extends Object>(
    Expression<T> Function($$CardioDetailsTableAnnotationComposer a) f,
  ) {
    final $$CardioDetailsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardioDetails,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardioDetailsTableAnnotationComposer(
            $db: $db,
            $table: $db.cardioDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutEntriesTable,
          WorkoutEntry,
          $$WorkoutEntriesTableFilterComposer,
          $$WorkoutEntriesTableOrderingComposer,
          $$WorkoutEntriesTableAnnotationComposer,
          $$WorkoutEntriesTableCreateCompanionBuilder,
          $$WorkoutEntriesTableUpdateCompanionBuilder,
          (WorkoutEntry, $$WorkoutEntriesTableReferences),
          WorkoutEntry,
          PrefetchHooks Function({
            bool exerciseId,
            bool workoutId,
            bool workoutSetsRefs,
            bool cardioDetailsRefs,
          })
        > {
  $$WorkoutEntriesTableTableManager(
    _$AppDatabase db,
    $WorkoutEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String> workoutId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> effort = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutEntriesCompanion(
                id: id,
                sortOrder: sortOrder,
                exerciseId: exerciseId,
                workoutId: workoutId,
                note: note,
                effort: effort,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int sortOrder,
                required String exerciseId,
                required String workoutId,
                Value<String?> note = const Value.absent(),
                Value<int?> effort = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutEntriesCompanion.insert(
                id: id,
                sortOrder: sortOrder,
                exerciseId: exerciseId,
                workoutId: workoutId,
                note: note,
                effort: effort,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                exerciseId = false,
                workoutId = false,
                workoutSetsRefs = false,
                cardioDetailsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workoutSetsRefs) db.workoutSets,
                    if (cardioDetailsRefs) db.cardioDetails,
                  ],
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
                                        $$WorkoutEntriesTableReferences
                                            ._exerciseIdTable(db),
                                    referencedColumn:
                                        $$WorkoutEntriesTableReferences
                                            ._exerciseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (workoutId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workoutId,
                                    referencedTable:
                                        $$WorkoutEntriesTableReferences
                                            ._workoutIdTable(db),
                                    referencedColumn:
                                        $$WorkoutEntriesTableReferences
                                            ._workoutIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workoutSetsRefs)
                        await $_getPrefetchedData<
                          WorkoutEntry,
                          $WorkoutEntriesTable,
                          WorkoutSet
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutEntriesTableReferences
                              ._workoutSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).workoutSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cardioDetailsRefs)
                        await $_getPrefetchedData<
                          WorkoutEntry,
                          $WorkoutEntriesTable,
                          CardioDetail
                        >(
                          currentTable: table,
                          referencedTable: $$WorkoutEntriesTableReferences
                              ._cardioDetailsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkoutEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).cardioDetailsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
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

typedef $$WorkoutEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutEntriesTable,
      WorkoutEntry,
      $$WorkoutEntriesTableFilterComposer,
      $$WorkoutEntriesTableOrderingComposer,
      $$WorkoutEntriesTableAnnotationComposer,
      $$WorkoutEntriesTableCreateCompanionBuilder,
      $$WorkoutEntriesTableUpdateCompanionBuilder,
      (WorkoutEntry, $$WorkoutEntriesTableReferences),
      WorkoutEntry,
      PrefetchHooks Function({
        bool exerciseId,
        bool workoutId,
        bool workoutSetsRefs,
        bool cardioDetailsRefs,
      })
    >;
typedef $$WorkoutSetsTableCreateCompanionBuilder =
    WorkoutSetsCompanion Function({
      required String id,
      required String entryId,
      required int reps,
      required double weightKg,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$WorkoutSetsTableUpdateCompanionBuilder =
    WorkoutSetsCompanion Function({
      Value<String> id,
      Value<String> entryId,
      Value<int> reps,
      Value<double> weightKg,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

final class $$WorkoutSetsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutSetsTable, WorkoutSet> {
  $$WorkoutSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutEntriesTable _entryIdTable(_$AppDatabase db) =>
      db.workoutEntries.createAlias(
        $_aliasNameGenerator(db.workoutSets.entryId, db.workoutEntries.id),
      );

  $$WorkoutEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$WorkoutEntriesTableTableManager(
      $_db,
      $_db.workoutEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkoutSetsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableFilterComposer({
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

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutEntriesTableFilterComposer get entryId {
    final $$WorkoutEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.workoutEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutEntriesTableFilterComposer(
            $db: $db,
            $table: $db.workoutEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableOrderingComposer({
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

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutEntriesTableOrderingComposer get entryId {
    final $$WorkoutEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.workoutEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.workoutEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$WorkoutEntriesTableAnnotationComposer get entryId {
    final $$WorkoutEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.workoutEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSetsTable,
          WorkoutSet,
          $$WorkoutSetsTableFilterComposer,
          $$WorkoutSetsTableOrderingComposer,
          $$WorkoutSetsTableAnnotationComposer,
          $$WorkoutSetsTableCreateCompanionBuilder,
          $$WorkoutSetsTableUpdateCompanionBuilder,
          (WorkoutSet, $$WorkoutSetsTableReferences),
          WorkoutSet,
          PrefetchHooks Function({bool entryId})
        > {
  $$WorkoutSetsTableTableManager(_$AppDatabase db, $WorkoutSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSetsCompanion(
                id: id,
                entryId: entryId,
                reps: reps,
                weightKg: weightKg,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryId,
                required int reps,
                required double weightKg,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSetsCompanion.insert(
                id: id,
                entryId: entryId,
                reps: reps,
                weightKg: weightKg,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkoutSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
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
                    if (entryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entryId,
                                referencedTable: $$WorkoutSetsTableReferences
                                    ._entryIdTable(db),
                                referencedColumn: $$WorkoutSetsTableReferences
                                    ._entryIdTable(db)
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

typedef $$WorkoutSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSetsTable,
      WorkoutSet,
      $$WorkoutSetsTableFilterComposer,
      $$WorkoutSetsTableOrderingComposer,
      $$WorkoutSetsTableAnnotationComposer,
      $$WorkoutSetsTableCreateCompanionBuilder,
      $$WorkoutSetsTableUpdateCompanionBuilder,
      (WorkoutSet, $$WorkoutSetsTableReferences),
      WorkoutSet,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$CardioDetailsTableCreateCompanionBuilder =
    CardioDetailsCompanion Function({
      required String id,
      required String entryId,
      required int durationMinutes,
      Value<int> rowid,
    });
typedef $$CardioDetailsTableUpdateCompanionBuilder =
    CardioDetailsCompanion Function({
      Value<String> id,
      Value<String> entryId,
      Value<int> durationMinutes,
      Value<int> rowid,
    });

final class $$CardioDetailsTableReferences
    extends BaseReferences<_$AppDatabase, $CardioDetailsTable, CardioDetail> {
  $$CardioDetailsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutEntriesTable _entryIdTable(_$AppDatabase db) =>
      db.workoutEntries.createAlias(
        $_aliasNameGenerator(db.cardioDetails.entryId, db.workoutEntries.id),
      );

  $$WorkoutEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$WorkoutEntriesTableTableManager(
      $_db,
      $_db.workoutEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CardioDetailsTableFilterComposer
    extends Composer<_$AppDatabase, $CardioDetailsTable> {
  $$CardioDetailsTableFilterComposer({
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

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutEntriesTableFilterComposer get entryId {
    final $$WorkoutEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.workoutEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutEntriesTableFilterComposer(
            $db: $db,
            $table: $db.workoutEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardioDetailsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardioDetailsTable> {
  $$CardioDetailsTableOrderingComposer({
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

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutEntriesTableOrderingComposer get entryId {
    final $$WorkoutEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.workoutEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.workoutEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardioDetailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardioDetailsTable> {
  $$CardioDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  $$WorkoutEntriesTableAnnotationComposer get entryId {
    final $$WorkoutEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.workoutEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardioDetailsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardioDetailsTable,
          CardioDetail,
          $$CardioDetailsTableFilterComposer,
          $$CardioDetailsTableOrderingComposer,
          $$CardioDetailsTableAnnotationComposer,
          $$CardioDetailsTableCreateCompanionBuilder,
          $$CardioDetailsTableUpdateCompanionBuilder,
          (CardioDetail, $$CardioDetailsTableReferences),
          CardioDetail,
          PrefetchHooks Function({bool entryId})
        > {
  $$CardioDetailsTableTableManager(_$AppDatabase db, $CardioDetailsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardioDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardioDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardioDetailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardioDetailsCompanion(
                id: id,
                entryId: entryId,
                durationMinutes: durationMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryId,
                required int durationMinutes,
                Value<int> rowid = const Value.absent(),
              }) => CardioDetailsCompanion.insert(
                id: id,
                entryId: entryId,
                durationMinutes: durationMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CardioDetailsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
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
                    if (entryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entryId,
                                referencedTable: $$CardioDetailsTableReferences
                                    ._entryIdTable(db),
                                referencedColumn: $$CardioDetailsTableReferences
                                    ._entryIdTable(db)
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

typedef $$CardioDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardioDetailsTable,
      CardioDetail,
      $$CardioDetailsTableFilterComposer,
      $$CardioDetailsTableOrderingComposer,
      $$CardioDetailsTableAnnotationComposer,
      $$CardioDetailsTableCreateCompanionBuilder,
      $$CardioDetailsTableUpdateCompanionBuilder,
      (CardioDetail, $$CardioDetailsTableReferences),
      CardioDetail,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$PlannedWorkoutsTableCreateCompanionBuilder =
    PlannedWorkoutsCompanion Function({
      required String id,
      required DateTime scheduledDate,
      required String name,
      Value<String?> notes,
      Value<String> source,
      Value<String?> templateId,
      Value<bool> isCompleted,
      Value<String?> completedWorkoutId,
      Value<int> rowid,
    });
typedef $$PlannedWorkoutsTableUpdateCompanionBuilder =
    PlannedWorkoutsCompanion Function({
      Value<String> id,
      Value<DateTime> scheduledDate,
      Value<String> name,
      Value<String?> notes,
      Value<String> source,
      Value<String?> templateId,
      Value<bool> isCompleted,
      Value<String?> completedWorkoutId,
      Value<int> rowid,
    });

final class $$PlannedWorkoutsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlannedWorkoutsTable, PlannedWorkout> {
  $$PlannedWorkoutsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutsTable _completedWorkoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias(
        $_aliasNameGenerator(
          db.plannedWorkouts.completedWorkoutId,
          db.workouts.id,
        ),
      );

  $$WorkoutsTableProcessedTableManager? get completedWorkoutId {
    final $_column = $_itemColumn<String>('completed_workout_id');
    if ($_column == null) return null;
    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_completedWorkoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlannedEntriesTable, List<PlannedEntry>>
  _plannedEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plannedEntries,
    aliasName: $_aliasNameGenerator(
      db.plannedWorkouts.id,
      db.plannedEntries.plannedWorkoutId,
    ),
  );

  $$PlannedEntriesTableProcessedTableManager get plannedEntriesRefs {
    final manager = $$PlannedEntriesTableTableManager($_db, $_db.plannedEntries)
        .filter(
          (f) => f.plannedWorkoutId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_plannedEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlannedWorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedWorkoutsTable> {
  $$PlannedWorkoutsTableFilterComposer({
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

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
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

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutsTableFilterComposer get completedWorkoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedWorkoutId,
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

  Expression<bool> plannedEntriesRefs(
    Expression<bool> Function($$PlannedEntriesTableFilterComposer f) f,
  ) {
    final $$PlannedEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedEntries,
      getReferencedColumn: (t) => t.plannedWorkoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedEntriesTableFilterComposer(
            $db: $db,
            $table: $db.plannedEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlannedWorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedWorkoutsTable> {
  $$PlannedWorkoutsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
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

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutsTableOrderingComposer get completedWorkoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedWorkoutId,
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
}

class $$PlannedWorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedWorkoutsTable> {
  $$PlannedWorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  $$WorkoutsTableAnnotationComposer get completedWorkoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedWorkoutId,
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

  Expression<T> plannedEntriesRefs<T extends Object>(
    Expression<T> Function($$PlannedEntriesTableAnnotationComposer a) f,
  ) {
    final $$PlannedEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedEntries,
      getReferencedColumn: (t) => t.plannedWorkoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlannedWorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannedWorkoutsTable,
          PlannedWorkout,
          $$PlannedWorkoutsTableFilterComposer,
          $$PlannedWorkoutsTableOrderingComposer,
          $$PlannedWorkoutsTableAnnotationComposer,
          $$PlannedWorkoutsTableCreateCompanionBuilder,
          $$PlannedWorkoutsTableUpdateCompanionBuilder,
          (PlannedWorkout, $$PlannedWorkoutsTableReferences),
          PlannedWorkout,
          PrefetchHooks Function({
            bool completedWorkoutId,
            bool plannedEntriesRefs,
          })
        > {
  $$PlannedWorkoutsTableTableManager(
    _$AppDatabase db,
    $PlannedWorkoutsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedWorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedWorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedWorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> scheduledDate = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> completedWorkoutId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannedWorkoutsCompanion(
                id: id,
                scheduledDate: scheduledDate,
                name: name,
                notes: notes,
                source: source,
                templateId: templateId,
                isCompleted: isCompleted,
                completedWorkoutId: completedWorkoutId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime scheduledDate,
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> completedWorkoutId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannedWorkoutsCompanion.insert(
                id: id,
                scheduledDate: scheduledDate,
                name: name,
                notes: notes,
                source: source,
                templateId: templateId,
                isCompleted: isCompleted,
                completedWorkoutId: completedWorkoutId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlannedWorkoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({completedWorkoutId = false, plannedEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (plannedEntriesRefs) db.plannedEntries,
                  ],
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
                        if (completedWorkoutId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.completedWorkoutId,
                                    referencedTable:
                                        $$PlannedWorkoutsTableReferences
                                            ._completedWorkoutIdTable(db),
                                    referencedColumn:
                                        $$PlannedWorkoutsTableReferences
                                            ._completedWorkoutIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (plannedEntriesRefs)
                        await $_getPrefetchedData<
                          PlannedWorkout,
                          $PlannedWorkoutsTable,
                          PlannedEntry
                        >(
                          currentTable: table,
                          referencedTable: $$PlannedWorkoutsTableReferences
                              ._plannedEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlannedWorkoutsTableReferences(
                                db,
                                table,
                                p0,
                              ).plannedEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.plannedWorkoutId == item.id,
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

typedef $$PlannedWorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannedWorkoutsTable,
      PlannedWorkout,
      $$PlannedWorkoutsTableFilterComposer,
      $$PlannedWorkoutsTableOrderingComposer,
      $$PlannedWorkoutsTableAnnotationComposer,
      $$PlannedWorkoutsTableCreateCompanionBuilder,
      $$PlannedWorkoutsTableUpdateCompanionBuilder,
      (PlannedWorkout, $$PlannedWorkoutsTableReferences),
      PlannedWorkout,
      PrefetchHooks Function({bool completedWorkoutId, bool plannedEntriesRefs})
    >;
typedef $$PlannedEntriesTableCreateCompanionBuilder =
    PlannedEntriesCompanion Function({
      required String id,
      required String plannedWorkoutId,
      required String exerciseId,
      required int sortOrder,
      required int plannedReps,
      required double plannedWeightKg,
      Value<int?> plannedRestSeconds,
      Value<String?> note,
      Value<int?> effortTarget,
      Value<int> rowid,
    });
typedef $$PlannedEntriesTableUpdateCompanionBuilder =
    PlannedEntriesCompanion Function({
      Value<String> id,
      Value<String> plannedWorkoutId,
      Value<String> exerciseId,
      Value<int> sortOrder,
      Value<int> plannedReps,
      Value<double> plannedWeightKg,
      Value<int?> plannedRestSeconds,
      Value<String?> note,
      Value<int?> effortTarget,
      Value<int> rowid,
    });

final class $$PlannedEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $PlannedEntriesTable, PlannedEntry> {
  $$PlannedEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlannedWorkoutsTable _plannedWorkoutIdTable(_$AppDatabase db) =>
      db.plannedWorkouts.createAlias(
        $_aliasNameGenerator(
          db.plannedEntries.plannedWorkoutId,
          db.plannedWorkouts.id,
        ),
      );

  $$PlannedWorkoutsTableProcessedTableManager get plannedWorkoutId {
    final $_column = $_itemColumn<String>('planned_workout_id')!;

    final manager = $$PlannedWorkoutsTableTableManager(
      $_db,
      $_db.plannedWorkouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plannedWorkoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
        $_aliasNameGenerator(db.plannedEntries.exerciseId, db.exercises.id),
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

  static MultiTypedResultKey<$PlannedCardioTable, List<PlannedCardioData>>
  _plannedCardioRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.plannedCardio,
    aliasName: $_aliasNameGenerator(
      db.plannedEntries.id,
      db.plannedCardio.plannedEntryId,
    ),
  );

  $$PlannedCardioTableProcessedTableManager get plannedCardioRefs {
    final manager = $$PlannedCardioTableTableManager(
      $_db,
      $_db.plannedCardio,
    ).filter((f) => f.plannedEntryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_plannedCardioRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlannedEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedEntriesTable> {
  $$PlannedEntriesTableFilterComposer({
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

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effortTarget => $composableBuilder(
    column: $table.effortTarget,
    builder: (column) => ColumnFilters(column),
  );

  $$PlannedWorkoutsTableFilterComposer get plannedWorkoutId {
    final $$PlannedWorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedWorkoutId,
      referencedTable: $db.plannedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedWorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.plannedWorkouts,
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

  Expression<bool> plannedCardioRefs(
    Expression<bool> Function($$PlannedCardioTableFilterComposer f) f,
  ) {
    final $$PlannedCardioTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedCardio,
      getReferencedColumn: (t) => t.plannedEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedCardioTableFilterComposer(
            $db: $db,
            $table: $db.plannedCardio,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlannedEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedEntriesTable> {
  $$PlannedEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effortTarget => $composableBuilder(
    column: $table.effortTarget,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlannedWorkoutsTableOrderingComposer get plannedWorkoutId {
    final $$PlannedWorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedWorkoutId,
      referencedTable: $db.plannedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedWorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.plannedWorkouts,
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

class $$PlannedEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedEntriesTable> {
  $$PlannedEntriesTableAnnotationComposer({
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

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get effortTarget => $composableBuilder(
    column: $table.effortTarget,
    builder: (column) => column,
  );

  $$PlannedWorkoutsTableAnnotationComposer get plannedWorkoutId {
    final $$PlannedWorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedWorkoutId,
      referencedTable: $db.plannedWorkouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedWorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedWorkouts,
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

  Expression<T> plannedCardioRefs<T extends Object>(
    Expression<T> Function($$PlannedCardioTableAnnotationComposer a) f,
  ) {
    final $$PlannedCardioTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedCardio,
      getReferencedColumn: (t) => t.plannedEntryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedCardioTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedCardio,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlannedEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannedEntriesTable,
          PlannedEntry,
          $$PlannedEntriesTableFilterComposer,
          $$PlannedEntriesTableOrderingComposer,
          $$PlannedEntriesTableAnnotationComposer,
          $$PlannedEntriesTableCreateCompanionBuilder,
          $$PlannedEntriesTableUpdateCompanionBuilder,
          (PlannedEntry, $$PlannedEntriesTableReferences),
          PlannedEntry,
          PrefetchHooks Function({
            bool plannedWorkoutId,
            bool exerciseId,
            bool plannedCardioRefs,
          })
        > {
  $$PlannedEntriesTableTableManager(
    _$AppDatabase db,
    $PlannedEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plannedWorkoutId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> plannedReps = const Value.absent(),
                Value<double> plannedWeightKg = const Value.absent(),
                Value<int?> plannedRestSeconds = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> effortTarget = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannedEntriesCompanion(
                id: id,
                plannedWorkoutId: plannedWorkoutId,
                exerciseId: exerciseId,
                sortOrder: sortOrder,
                plannedReps: plannedReps,
                plannedWeightKg: plannedWeightKg,
                plannedRestSeconds: plannedRestSeconds,
                note: note,
                effortTarget: effortTarget,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plannedWorkoutId,
                required String exerciseId,
                required int sortOrder,
                required int plannedReps,
                required double plannedWeightKg,
                Value<int?> plannedRestSeconds = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> effortTarget = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannedEntriesCompanion.insert(
                id: id,
                plannedWorkoutId: plannedWorkoutId,
                exerciseId: exerciseId,
                sortOrder: sortOrder,
                plannedReps: plannedReps,
                plannedWeightKg: plannedWeightKg,
                plannedRestSeconds: plannedRestSeconds,
                note: note,
                effortTarget: effortTarget,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlannedEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                plannedWorkoutId = false,
                exerciseId = false,
                plannedCardioRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (plannedCardioRefs) db.plannedCardio,
                  ],
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
                        if (plannedWorkoutId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.plannedWorkoutId,
                                    referencedTable:
                                        $$PlannedEntriesTableReferences
                                            ._plannedWorkoutIdTable(db),
                                    referencedColumn:
                                        $$PlannedEntriesTableReferences
                                            ._plannedWorkoutIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (exerciseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.exerciseId,
                                    referencedTable:
                                        $$PlannedEntriesTableReferences
                                            ._exerciseIdTable(db),
                                    referencedColumn:
                                        $$PlannedEntriesTableReferences
                                            ._exerciseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (plannedCardioRefs)
                        await $_getPrefetchedData<
                          PlannedEntry,
                          $PlannedEntriesTable,
                          PlannedCardioData
                        >(
                          currentTable: table,
                          referencedTable: $$PlannedEntriesTableReferences
                              ._plannedCardioRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlannedEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).plannedCardioRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.plannedEntryId == item.id,
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

typedef $$PlannedEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannedEntriesTable,
      PlannedEntry,
      $$PlannedEntriesTableFilterComposer,
      $$PlannedEntriesTableOrderingComposer,
      $$PlannedEntriesTableAnnotationComposer,
      $$PlannedEntriesTableCreateCompanionBuilder,
      $$PlannedEntriesTableUpdateCompanionBuilder,
      (PlannedEntry, $$PlannedEntriesTableReferences),
      PlannedEntry,
      PrefetchHooks Function({
        bool plannedWorkoutId,
        bool exerciseId,
        bool plannedCardioRefs,
      })
    >;
typedef $$PlannedCardioTableCreateCompanionBuilder =
    PlannedCardioCompanion Function({
      required String id,
      required String plannedEntryId,
      required int plannedDurationMinutes,
      Value<int> rowid,
    });
typedef $$PlannedCardioTableUpdateCompanionBuilder =
    PlannedCardioCompanion Function({
      Value<String> id,
      Value<String> plannedEntryId,
      Value<int> plannedDurationMinutes,
      Value<int> rowid,
    });

final class $$PlannedCardioTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlannedCardioTable, PlannedCardioData> {
  $$PlannedCardioTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlannedEntriesTable _plannedEntryIdTable(_$AppDatabase db) =>
      db.plannedEntries.createAlias(
        $_aliasNameGenerator(
          db.plannedCardio.plannedEntryId,
          db.plannedEntries.id,
        ),
      );

  $$PlannedEntriesTableProcessedTableManager get plannedEntryId {
    final $_column = $_itemColumn<String>('planned_entry_id')!;

    final manager = $$PlannedEntriesTableTableManager(
      $_db,
      $_db.plannedEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_plannedEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlannedCardioTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedCardioTable> {
  $$PlannedCardioTableFilterComposer({
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

  ColumnFilters<int> get plannedDurationMinutes => $composableBuilder(
    column: $table.plannedDurationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$PlannedEntriesTableFilterComposer get plannedEntryId {
    final $$PlannedEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedEntryId,
      referencedTable: $db.plannedEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedEntriesTableFilterComposer(
            $db: $db,
            $table: $db.plannedEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlannedCardioTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedCardioTable> {
  $$PlannedCardioTableOrderingComposer({
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

  ColumnOrderings<int> get plannedDurationMinutes => $composableBuilder(
    column: $table.plannedDurationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlannedEntriesTableOrderingComposer get plannedEntryId {
    final $$PlannedEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedEntryId,
      referencedTable: $db.plannedEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.plannedEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlannedCardioTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedCardioTable> {
  $$PlannedCardioTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get plannedDurationMinutes => $composableBuilder(
    column: $table.plannedDurationMinutes,
    builder: (column) => column,
  );

  $$PlannedEntriesTableAnnotationComposer get plannedEntryId {
    final $$PlannedEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.plannedEntryId,
      referencedTable: $db.plannedEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.plannedEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlannedCardioTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannedCardioTable,
          PlannedCardioData,
          $$PlannedCardioTableFilterComposer,
          $$PlannedCardioTableOrderingComposer,
          $$PlannedCardioTableAnnotationComposer,
          $$PlannedCardioTableCreateCompanionBuilder,
          $$PlannedCardioTableUpdateCompanionBuilder,
          (PlannedCardioData, $$PlannedCardioTableReferences),
          PlannedCardioData,
          PrefetchHooks Function({bool plannedEntryId})
        > {
  $$PlannedCardioTableTableManager(_$AppDatabase db, $PlannedCardioTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedCardioTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedCardioTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedCardioTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> plannedEntryId = const Value.absent(),
                Value<int> plannedDurationMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannedCardioCompanion(
                id: id,
                plannedEntryId: plannedEntryId,
                plannedDurationMinutes: plannedDurationMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String plannedEntryId,
                required int plannedDurationMinutes,
                Value<int> rowid = const Value.absent(),
              }) => PlannedCardioCompanion.insert(
                id: id,
                plannedEntryId: plannedEntryId,
                plannedDurationMinutes: plannedDurationMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlannedCardioTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({plannedEntryId = false}) {
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
                    if (plannedEntryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.plannedEntryId,
                                referencedTable: $$PlannedCardioTableReferences
                                    ._plannedEntryIdTable(db),
                                referencedColumn: $$PlannedCardioTableReferences
                                    ._plannedEntryIdTable(db)
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

typedef $$PlannedCardioTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannedCardioTable,
      PlannedCardioData,
      $$PlannedCardioTableFilterComposer,
      $$PlannedCardioTableOrderingComposer,
      $$PlannedCardioTableAnnotationComposer,
      $$PlannedCardioTableCreateCompanionBuilder,
      $$PlannedCardioTableUpdateCompanionBuilder,
      (PlannedCardioData, $$PlannedCardioTableReferences),
      PlannedCardioData,
      PrefetchHooks Function({bool plannedEntryId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db, _db.ingredients);
  $$IngredientComponentsTableTableManager get ingredientComponents =>
      $$IngredientComponentsTableTableManager(_db, _db.ingredientComponents);
  $$MealsTableTableManager get meals =>
      $$MealsTableTableManager(_db, _db.meals);
  $$MealIngredientsTableTableManager get mealIngredients =>
      $$MealIngredientsTableTableManager(_db, _db.mealIngredients);
  $$SeancesTableTableManager get seances =>
      $$SeancesTableTableManager(_db, _db.seances);
  $$ExerciseEntriesTableTableManager get exerciseEntries =>
      $$ExerciseEntriesTableTableManager(_db, _db.exerciseEntries);
  $$ExerciseSetsTableTableManager get exerciseSets =>
      $$ExerciseSetsTableTableManager(_db, _db.exerciseSets);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
  $$TemplateExercisesTableTableManager get templateExercises =>
      $$TemplateExercisesTableTableManager(_db, _db.templateExercises);
  $$TemplateSetsTableTableManager get templateSets =>
      $$TemplateSetsTableTableManager(_db, _db.templateSets);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db, _db.userProfile);
  $$BodyWeightEntriesTableTableManager get bodyWeightEntries =>
      $$BodyWeightEntriesTableTableManager(_db, _db.bodyWeightEntries);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$WorkoutEntriesTableTableManager get workoutEntries =>
      $$WorkoutEntriesTableTableManager(_db, _db.workoutEntries);
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db, _db.workoutSets);
  $$CardioDetailsTableTableManager get cardioDetails =>
      $$CardioDetailsTableTableManager(_db, _db.cardioDetails);
  $$PlannedWorkoutsTableTableManager get plannedWorkouts =>
      $$PlannedWorkoutsTableTableManager(_db, _db.plannedWorkouts);
  $$PlannedEntriesTableTableManager get plannedEntries =>
      $$PlannedEntriesTableTableManager(_db, _db.plannedEntries);
  $$PlannedCardioTableTableManager get plannedCardio =>
      $$PlannedCardioTableTableManager(_db, _db.plannedCardio);
}
