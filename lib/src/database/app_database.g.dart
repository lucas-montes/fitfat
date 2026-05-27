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
  @override
  List<GeneratedColumn> get $columns => [id, name, category];
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
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
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
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
    };
  }

  Exercise copyWith({String? id, String? name, String? category}) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String name,
    required String category,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
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
  final String? name;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int restBetweenSetsMillis;
  const Seance({
    required this.id,
    this.name,
    required this.startedAt,
    this.completedAt,
    required this.restBetweenSetsMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['rest_between_sets_millis'] = Variable<int>(restBetweenSetsMillis);
    return map;
  }

  SeancesCompanion toCompanion(bool nullToAbsent) {
    return SeancesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
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
      name: serializer.fromJson<String?>(json['name']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
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
      'name': serializer.toJson<String?>(name),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'restBetweenSetsMillis': serializer.toJson<int>(restBetweenSetsMillis),
    };
  }

  Seance copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    int? restBetweenSetsMillis,
  }) => Seance(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
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
  final Value<String?> name;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
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
    this.name = const Value.absent(),
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.restBetweenSetsMillis = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt);
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
    Value<String?>? name,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
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
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
      ),
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
  final DateTime? completedAt;
  const ExerciseEntry({
    required this.id,
    required this.seanceId,
    required this.exerciseId,
    required this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['seance_id'] = Variable<String>(seanceId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  ExerciseEntriesCompanion toCompanion(bool nullToAbsent) {
    return ExerciseEntriesCompanion(
      id: Value(id),
      seanceId: Value(seanceId),
      exerciseId: Value(exerciseId),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
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
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
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
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  ExerciseEntry copyWith({
    String? id,
    String? seanceId,
    String? exerciseId,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => ExerciseEntry(
    id: id ?? this.id,
    seanceId: seanceId ?? this.seanceId,
    exerciseId: exerciseId ?? this.exerciseId,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
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
  final Value<DateTime?> completedAt;
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
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seanceId = Value(seanceId),
       exerciseId = Value(exerciseId),
       startedAt = Value(startedAt);
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
    Value<DateTime?>? completedAt,
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
  @override
  List<GeneratedColumn> get $columns => [id, entryId, reps, weight];
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
  const ExerciseSet({
    required this.id,
    required this.entryId,
    required this.reps,
    required this.weight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['reps'] = Variable<int>(reps);
    map['weight'] = Variable<double>(weight);
    return map;
  }

  ExerciseSetsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseSetsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      reps: Value(reps),
      weight: Value(weight),
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
    };
  }

  ExerciseSet copyWith({
    String? id,
    String? entryId,
    int? reps,
    double? weight,
  }) => ExerciseSet(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    reps: reps ?? this.reps,
    weight: weight ?? this.weight,
  );
  ExerciseSet copyWithCompanion(ExerciseSetsCompanion data) {
    return ExerciseSet(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      reps: data.reps.present ? data.reps.value : this.reps,
      weight: data.weight.present ? data.weight.value : this.weight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSet(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, reps, weight);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseSet &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.reps == this.reps &&
          other.weight == this.weight);
}

class ExerciseSetsCompanion extends UpdateCompanion<ExerciseSet> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<int> reps;
  final Value<double> weight;
  final Value<int> rowid;
  const ExerciseSetsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseSetsCompanion.insert({
    required String id,
    required String entryId,
    required int reps,
    required double weight,
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
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseSetsCompanion copyWith({
    Value<String>? id,
    Value<String>? entryId,
    Value<int>? reps,
    Value<double>? weight,
    Value<int>? rowid,
  }) {
    return ExerciseSetsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
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
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
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
      ),
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
  final double? weightKg;
  final int restSeconds;
  const TemplateSet({
    required this.id,
    required this.templateExerciseId,
    required this.reps,
    this.weightKg,
    required this.restSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_exercise_id'] = Variable<String>(templateExerciseId);
    map['reps'] = Variable<int>(reps);
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    map['rest_seconds'] = Variable<int>(restSeconds);
    return map;
  }

  TemplateSetsCompanion toCompanion(bool nullToAbsent) {
    return TemplateSetsCompanion(
      id: Value(id),
      templateExerciseId: Value(templateExerciseId),
      reps: Value(reps),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
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
      weightKg: serializer.fromJson<double?>(json['weightKg']),
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
      'weightKg': serializer.toJson<double?>(weightKg),
      'restSeconds': serializer.toJson<int>(restSeconds),
    };
  }

  TemplateSet copyWith({
    String? id,
    String? templateExerciseId,
    int? reps,
    Value<double?> weightKg = const Value.absent(),
    int? restSeconds,
  }) => TemplateSet(
    id: id ?? this.id,
    templateExerciseId: templateExerciseId ?? this.templateExerciseId,
    reps: reps ?? this.reps,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
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
  final Value<double?> weightKg;
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
    this.weightKg = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateExerciseId = Value(templateExerciseId),
       reps = Value(reps);
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
    Value<double?>? weightKg,
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
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
    sex,
    heightCm,
    weightKg,
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
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
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
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      )!,
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
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
}

class UserProfileData extends DataClass implements Insertable<UserProfileData> {
  final String id;
  final DateTime birthDate;
  final String sex;
  final double heightCm;
  final double weightKg;
  final String activityLevel;
  const UserProfileData({
    required this.id,
    required this.birthDate,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['birth_date'] = Variable<DateTime>(birthDate);
    map['sex'] = Variable<String>(sex);
    map['height_cm'] = Variable<double>(heightCm);
    map['weight_kg'] = Variable<double>(weightKg);
    map['activity_level'] = Variable<String>(activityLevel);
    return map;
  }

  UserProfileCompanion toCompanion(bool nullToAbsent) {
    return UserProfileCompanion(
      id: Value(id),
      birthDate: Value(birthDate),
      sex: Value(sex),
      heightCm: Value(heightCm),
      weightKg: Value(weightKg),
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
      sex: serializer.fromJson<String>(json['sex']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      activityLevel: serializer.fromJson<String>(json['activityLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'birthDate': serializer.toJson<DateTime>(birthDate),
      'sex': serializer.toJson<String>(sex),
      'heightCm': serializer.toJson<double>(heightCm),
      'weightKg': serializer.toJson<double>(weightKg),
      'activityLevel': serializer.toJson<String>(activityLevel),
    };
  }

  UserProfileData copyWith({
    String? id,
    DateTime? birthDate,
    String? sex,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
  }) => UserProfileData(
    id: id ?? this.id,
    birthDate: birthDate ?? this.birthDate,
    sex: sex ?? this.sex,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    activityLevel: activityLevel ?? this.activityLevel,
  );
  UserProfileData copyWithCompanion(UserProfileCompanion data) {
    return UserProfileData(
      id: data.id.present ? data.id.value : this.id,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      sex: data.sex.present ? data.sex.value : this.sex,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
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
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('activityLevel: $activityLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, birthDate, sex, heightCm, weightKg, activityLevel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileData &&
          other.id == this.id &&
          other.birthDate == this.birthDate &&
          other.sex == this.sex &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.activityLevel == this.activityLevel);
}

class UserProfileCompanion extends UpdateCompanion<UserProfileData> {
  final Value<String> id;
  final Value<DateTime> birthDate;
  final Value<String> sex;
  final Value<double> heightCm;
  final Value<double> weightKg;
  final Value<String> activityLevel;
  final Value<int> rowid;
  const UserProfileCompanion({
    this.id = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.sex = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfileCompanion.insert({
    required String id,
    required DateTime birthDate,
    required String sex,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       birthDate = Value(birthDate),
       sex = Value(sex),
       heightCm = Value(heightCm),
       weightKg = Value(weightKg),
       activityLevel = Value(activityLevel);
  static Insertable<UserProfileData> custom({
    Expression<String>? id,
    Expression<DateTime>? birthDate,
    Expression<String>? sex,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<String>? activityLevel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (birthDate != null) 'birth_date': birthDate,
      if (sex != null) 'sex': sex,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfileCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? birthDate,
    Value<String>? sex,
    Value<double>? heightCm,
    Value<double>? weightKg,
    Value<String>? activityLevel,
    Value<int>? rowid,
  }) {
    return UserProfileCompanion(
      id: id ?? this.id,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
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
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
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
          ..write('sex: $sex, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
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
      Value<int> rowid,
    });
typedef $$ExercisesTableUpdateCompanionBuilder =
    ExercisesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
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
          PrefetchHooks Function({bool exerciseEntriesRefs})
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
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                name: name,
                category: category,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                name: name,
                category: category,
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
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.exerciseId == item.id),
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
      PrefetchHooks Function({bool exerciseEntriesRefs})
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
      Value<String?> name,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<int> restBetweenSetsMillis,
      Value<int> rowid,
    });
typedef $$SeancesTableUpdateCompanionBuilder =
    SeancesCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
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
                Value<String?> name = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
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
                Value<String?> name = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
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
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$ExerciseEntriesTableUpdateCompanionBuilder =
    ExerciseEntriesCompanion Function({
      Value<String> id,
      Value<String> seanceId,
      Value<String> exerciseId,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
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
                Value<DateTime?> completedAt = const Value.absent(),
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
                Value<DateTime?> completedAt = const Value.absent(),
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
      Value<int> rowid,
    });
typedef $$ExerciseSetsTableUpdateCompanionBuilder =
    ExerciseSetsCompanion Function({
      Value<String> id,
      Value<String> entryId,
      Value<int> reps,
      Value<double> weight,
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
                Value<int> rowid = const Value.absent(),
              }) => ExerciseSetsCompanion(
                id: id,
                entryId: entryId,
                reps: reps,
                weight: weight,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryId,
                required int reps,
                required double weight,
                Value<int> rowid = const Value.absent(),
              }) => ExerciseSetsCompanion.insert(
                id: id,
                entryId: entryId,
                reps: reps,
                weight: weight,
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
      Value<double?> weightKg,
      Value<int> restSeconds,
      Value<int> rowid,
    });
typedef $$TemplateSetsTableUpdateCompanionBuilder =
    TemplateSetsCompanion Function({
      Value<String> id,
      Value<String> templateExerciseId,
      Value<int> reps,
      Value<double?> weightKg,
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
                Value<double?> weightKg = const Value.absent(),
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
                Value<double?> weightKg = const Value.absent(),
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
      required String sex,
      required double heightCm,
      required double weightKg,
      required String activityLevel,
      Value<int> rowid,
    });
typedef $$UserProfileTableUpdateCompanionBuilder =
    UserProfileCompanion Function({
      Value<String> id,
      Value<DateTime> birthDate,
      Value<String> sex,
      Value<double> heightCm,
      Value<double> weightKg,
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

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
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

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
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

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

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
                Value<String> sex = const Value.absent(),
                Value<double> heightCm = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<String> activityLevel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfileCompanion(
                id: id,
                birthDate: birthDate,
                sex: sex,
                heightCm: heightCm,
                weightKg: weightKg,
                activityLevel: activityLevel,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime birthDate,
                required String sex,
                required double heightCm,
                required double weightKg,
                required String activityLevel,
                Value<int> rowid = const Value.absent(),
              }) => UserProfileCompanion.insert(
                id: id,
                birthDate: birthDate,
                sex: sex,
                heightCm: heightCm,
                weightKg: weightKg,
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
}
