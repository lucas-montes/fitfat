import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../database/app_database.dart'
    hide Seance, ExerciseEntry, ExerciseSet, Exercise;
import '../../../models/exercise.dart';
import '../../../database/providers.dart';
import '../../../services/logger.dart';

final _log = logger('exercise_seance');

final seanceHistoryProvider =
    NotifierProvider<SeanceHistoryNotifier, List<Seance>>(
      SeanceHistoryNotifier.new,
    );


class SeanceHistoryNotifier extends Notifier<List<Seance>> {
  @override
  List<Seance> build() {
    _loadFromDb();
    return [];
  }

  Future<void> _loadFromDb() async {
    try {
      final db = ref.read(databaseProvider);
      final seanceRows = await (db.select(
        db.seances,
      )..where((table) => table.completedAt.isNotNull())).get();
      final result = <Seance>[];
      for (final seanceRow in seanceRows) {
        final entryRows = await (db.select(
          db.exerciseEntries,
        )..where((table) => table.seanceId.equals(seanceRow.id))).get();
        final exercises = <ExerciseEntry>[];
        for (final entryRow in entryRows) {
          final exerciseRow =
              await (db.select(db.exercises)
                    ..where((table) => table.id.equals(entryRow.exerciseId)))
                  .getSingleOrNull();
          final setRows = await (db.select(
            db.exerciseSets,
          )..where((table) => table.entryId.equals(entryRow.id))).get();
          exercises.add(
            ExerciseEntry(
              id: entryRow.id,
              exercise: ExerciseDefinition(
                id: entryRow.exerciseId,
                name: exerciseRow?.name ?? entryRow.exerciseId,
                category: exerciseRow?.category ?? 'General',
              ),
              sets: setRows
                  .map(
                    (setRow) => ExerciseSet(
                      reps: setRow.reps,
                      weight: setRow.weight,
                      completedAt: setRow.completedAt,
                    ),
                  )
                  .toList(),
              startedAt: entryRow.startedAt,
              completedAt: entryRow.completedAt,
            ),
          );
        }
        result.add(
          Seance(
            id: seanceRow.id,
            name: seanceRow.name,
            startedAt: seanceRow.startedAt,
            exercises: exercises,
            completedAt: seanceRow.completedAt,
            restBetweenSets: Duration(
              milliseconds: seanceRow.restBetweenSetsMillis,
            ),
          ),
        );
      }
      result.sort((a, b) {
        final aCompleted = a.completedAt ?? a.startedAt;
        final bCompleted = b.completedAt ?? b.startedAt;
        return bCompleted.compareTo(aCompleted);
      });
      state = result;
    } catch (e, stack) {
      _log.severe('Failed to load seance history', e, stack);
    }
  }

  Future<void> _saveToDb(Seance seance) async {
    try {
      final db = ref.read(databaseProvider);
      await db.transaction(() async {
        await db
            .into(db.seances)
            .insert(
              SeancesCompanion(
                id: Value(seance.id),
                name: Value(seance.name),
                startedAt: Value(seance.startedAt),
                completedAt: Value(seance.completedAt!),
                restBetweenSetsMillis: Value(
                  seance.restBetweenSets.inMilliseconds,
                ),
              ),
              mode: InsertMode.insertOrReplace,
            );

        for (final entry in seance.exercises) {
          final exerciseId = entry.exercise.id.isNotEmpty
              ? entry.exercise.id
              : const Uuid().v7();

          await db
              .into(db.exercises)
              .insert(
                ExercisesCompanion.insert(
                  id: exerciseId,
                  name: entry.exercise.name,
                  category: entry.exercise.category,
                ),
                mode: InsertMode.insertOrReplace,
              );

          await db
              .into(db.exerciseEntries)
              .insert(
                ExerciseEntriesCompanion(
                  id: Value(entry.id),
                  seanceId: Value(seance.id),
                  exerciseId: Value(exerciseId),
                  startedAt: Value(entry.startedAt),
                  completedAt: Value(entry.completedAt ?? seance.completedAt!),
                ),
                mode: InsertMode.insertOrReplace,
              );

          await db.deleteExerciseSetsByEntry(entry.id);
          final completedSets = entry.sets
              .where((set) => set.isCompleted)
              .toList();
          for (final set in completedSets) {
            await db
                .into(db.exerciseSets)
                .insert(
                  ExerciseSetsCompanion.insert(
                    id: const Uuid().v7(),
                    entryId: entry.id,
                    reps: set.reps,
                    weight: set.weight,
                    completedAt: Value(set.completedAt),
                  ),
                );
          }
        }
      });
    } catch (e, stack) {
      _log.severe('Failed to save seance', e, stack);
    }
  }

  Future<void> addSeance(Seance seance) async {
    // Save to DB first so any racing _loadFromDb() from build() will find it
    await _saveToDb(seance);
    state = [seance, ...state];
  }
}
