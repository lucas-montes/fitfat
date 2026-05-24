import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../adapters/drift/drift_seance_repository.dart';
import '../../database/app_database.dart'
		hide Seance, ExerciseEntry, ExerciseSet, Exercise;
import '../../models/exercise.dart';
import '../../models/seance.dart';
import '../../database/providers.dart';
import '../../services/logger.dart';
import '../../services/seance_foreground_service.dart';
import '../repository/seance.dart';

final _log = logger('exercise_seance');
const _activeSeanceKey = 'active_seance_json';

final exerciseListProvider =
		NotifierProvider<ExerciseListNotifier, List<ExerciseDefinition>>(
	ExerciseListNotifier.new,
);

class ExerciseListNotifier extends Notifier<List<ExerciseDefinition>> {
	@override
	List<ExerciseDefinition> build() {
		_loadFromDb();
		return [];
	}

	Future<void> _loadFromDb() async {
		try {
			final db = ref.read(databaseProvider);
			final rows = await db.getAllExercises();
			if (rows.isEmpty) return;
			state = rows
					.map(
						(exercise) => ExerciseDefinition(
							id: exercise.id,
							name: exercise.name,
							category: exercise.category,
						),
					)
					.toList();
		} catch (_) {}
	}
}

final activeSeanceProvider = NotifierProvider<ActiveSeanceNotifier, Seance?>(
	ActiveSeanceNotifier.new,
);

final seanceHistoryProvider =
		NotifierProvider<SeanceHistoryNotifier, List<Seance>>(
	SeanceHistoryNotifier.new,
);

final seanceRepositoryProvider = Provider<SeanceRepository>((ref) {
	final db = ref.watch(databaseProvider);
	return DriftSeanceRepository(db);
});

final templateListProvider =
		NotifierProvider<TemplateListNotifier, List<SeanceTemplate>>(
	TemplateListNotifier.new,
);

final activeSeancePlanProvider =
		NotifierProvider<ActiveSeancePlanNotifier, Map<String, ExerciseTemplate>>(
	ActiveSeancePlanNotifier.new,
);

class ActiveSeanceNotifier extends Notifier<Seance?> {
	@override
	Seance? build() {
		Future.microtask(restoreFromPrefs);
		return null;
	}

	Future<void> restoreFromPrefs() async {
		final prefs = await SharedPreferences.getInstance();
		final json = prefs.getString(_activeSeanceKey);
		if (json == null) return;
		try {
			state = Seance.fromJson(
				Map<String, dynamic>.from(const JsonDecoder().convert(json) as Map),
			);
			if (state != null && state!.isActive) {
				unawaited(SeanceForegroundService.instance.start(state!.startedAt));
			}
		} catch (e, stack) {
			_log.warning('Could not restore active seance', e, stack);
		}
	}

	Future<void> _persist() async {
		final prefs = await SharedPreferences.getInstance();
		if (state == null) {
			await prefs.remove(_activeSeanceKey);
			return;
		}
		await prefs.setString(
			_activeSeanceKey,
			const JsonEncoder().convert(state!.toJson()),
		);
	}

	void startSeanceFromTemplate(SeanceTemplate template) {
		state = Seance(
			id: const Uuid().v4(),
			name: template.name,
			startedAt: DateTime.now(),
			exercises: template.exercises
					.map(
						(exerciseTemplate) => ExerciseEntry(
							id: const Uuid().v4(),
							exercise: ExerciseDefinition(
								id: exerciseTemplate.id,
								name: exerciseTemplate.name,
							),
							sets: exerciseTemplate.plannedSets
									.map(
										(plannedSet) => ExerciseSet(
											reps: plannedSet.reps,
											weight: plannedSet.weightKg ?? 0,
										),
									)
									.toList(),
							startedAt: DateTime.now(),
						),
					)
					.toList(),
		);
		unawaited(
			SeanceForegroundService.instance.start(
				state!.startedAt,
				seanceName: template.name,
			),
		);
		unawaited(_persist());
	}

	void startSeance() {
		state = Seance(
			id: const Uuid().v4(),
			startedAt: DateTime.now(),
			exercises: [],
		);
		unawaited(SeanceForegroundService.instance.start(state!.startedAt));
		unawaited(_persist());
	}

	void addExercise(ExerciseDefinition exercise) {
		if (state == null) return;
		if (state!.exercises.any(
			(entry) => entry.exercise.name.toLowerCase() == exercise.name.toLowerCase(),
		)) {
			return;
		}
		state = Seance(
			id: state!.id,
			name: state!.name,
			startedAt: state!.startedAt,
			exercises: [
				...state!.exercises,
				ExerciseEntry(
					id: const Uuid().v4(),
					exercise: exercise,
					sets: [],
					startedAt: DateTime.now(),
				),
			],
			completedAt: state!.completedAt,
			restBetweenSets: state!.restBetweenSets,
		);
		unawaited(_persist());
	}

	void removeExercise(int index) {
		if (state == null || index >= state!.exercises.length) return;
		final exercises = List<ExerciseEntry>.from(state!.exercises)..removeAt(index);
		state = Seance(
			id: state!.id,
			name: state!.name,
			startedAt: state!.startedAt,
			exercises: exercises,
			completedAt: state!.completedAt,
			restBetweenSets: state!.restBetweenSets,
		);
		unawaited(_persist());
	}

	void addSet(int exerciseIndex, int reps, double weight) {
		if (state == null || exerciseIndex >= state!.exercises.length) return;
		final exercise = state!.exercises[exerciseIndex];
		final now = DateTime.now();
		final updatedSets = exercise.sets
				.map(
					(set) => set.isCompleted
							? set
							: ExerciseSet(reps: set.reps, weight: set.weight, completedAt: now),
				)
				.followedBy([ExerciseSet(reps: reps, weight: weight, completedAt: now)])
				.toList();
		state = Seance(
			id: state!.id,
			name: state!.name,
			startedAt: state!.startedAt,
			exercises: [
				...state!.exercises.sublist(0, exerciseIndex),
				ExerciseEntry(
					id: exercise.id,
					exercise: exercise.exercise,
					sets: updatedSets,
					startedAt: exercise.startedAt,
					completedAt: exercise.completedAt,
				),
				...state!.exercises.sublist(exerciseIndex + 1),
			],
			completedAt: state!.completedAt,
			restBetweenSets: state!.restBetweenSets,
		);
		unawaited(_persist());
		unawaited(SeanceForegroundService.instance.lastSetCompleted());
	}

	void toggleSetCompleted(int exerciseIndex, int setIndex) {
		if (state == null || exerciseIndex >= state!.exercises.length) return;
		final exercise = state!.exercises[exerciseIndex];
		final set = exercise.sets[setIndex];
		final updatedSets = [
			for (var i = 0; i < exercise.sets.length; i++)
				if (i == setIndex)
					ExerciseSet(
						reps: set.reps,
						weight: set.weight,
						completedAt: set.isCompleted ? null : DateTime.now(),
					)
				else
					exercise.sets[i],
		];
		state = Seance(
			id: state!.id,
			name: state!.name,
			startedAt: state!.startedAt,
			exercises: [
				...state!.exercises.sublist(0, exerciseIndex),
				ExerciseEntry(
					id: exercise.id,
					exercise: exercise.exercise,
					sets: updatedSets,
					startedAt: exercise.startedAt,
					completedAt: exercise.completedAt,
				),
				...state!.exercises.sublist(exerciseIndex + 1),
			],
			completedAt: state!.completedAt,
			restBetweenSets: state!.restBetweenSets,
		);
		unawaited(_persist());
	}

	void updateSet(int exerciseIndex, int setIndex, int reps, double weight) {
		if (state == null || exerciseIndex >= state!.exercises.length) return;
		final exercise = state!.exercises[exerciseIndex];
		final updatedSets = [
			for (var i = 0; i < exercise.sets.length; i++)
				if (i == setIndex)
					ExerciseSet(reps: reps, weight: weight)
				else
					exercise.sets[i],
		];
		state = Seance(
			id: state!.id,
			name: state!.name,
			startedAt: state!.startedAt,
			exercises: [
				...state!.exercises.sublist(0, exerciseIndex),
				ExerciseEntry(
					id: exercise.id,
					exercise: exercise.exercise,
					sets: updatedSets,
					startedAt: exercise.startedAt,
					completedAt: exercise.completedAt,
				),
				...state!.exercises.sublist(exerciseIndex + 1),
			],
			completedAt: state!.completedAt,
			restBetweenSets: state!.restBetweenSets,
		);
		unawaited(_persist());
	}

	void completeSeance() {
		if (state == null) return;
		final now = DateTime.now();
		final defaultName =
				'Seance - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
		final completed = Seance(
			id: state!.id,
			name: state!.name ?? defaultName,
			startedAt: state!.startedAt,
			exercises: state!.exercises,
			completedAt: now,
			restBetweenSets: state!.restBetweenSets,
		);
		ref.read(seanceHistoryProvider.notifier).addSeance(completed);
		state = null;
		unawaited(SeanceForegroundService.instance.stop());
		unawaited(_persist());
	}

	void cancelSeance() {
		if (state == null) return;
		state = null;
		unawaited(SeanceForegroundService.instance.stop());
		unawaited(_persist());
	}
}

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
					final exerciseRow = await (db.select(
						db.exercises,
					)..where((table) => table.id.equals(entryRow.exerciseId))).getSingleOrNull();
					final setRows = await (db.select(
						db.exerciseSets,
					)..where((table) => table.entryId.equals(entryRow.id))).get();
					exercises.add(
						ExerciseEntry(
							id: entryRow.id,
							exercise: ExerciseDefinition(
								id: entryRow.exerciseId,
								name: exerciseRow?.name ?? '',
							),
							sets: setRows
									.map((setRow) => ExerciseSet(reps: setRow.reps, weight: setRow.weight))
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
					),
				);
			}
			if (result.isNotEmpty) {
				state = result;
			}
		} catch (e, stack) {
			_log.severe('Failed to load seance history', e, stack);
		}
	}

	Future<void> _saveToDb(Seance seance) async {
		try {
			final db = ref.read(databaseProvider);
			await db.into(db.seances).insert(
				SeancesCompanion(
					id: Value(seance.id),
					name: Value(seance.name),
					startedAt: Value(seance.startedAt),
					completedAt: Value(seance.completedAt),
					restBetweenSetsMillis: Value(seance.restBetweenSets.inMilliseconds),
				),
				mode: InsertMode.insertOrReplace,
			);
			for (final entry in seance.exercises) {
				final existing = await (db.select(
					db.exercises,
				)..where((table) => table.name.equals(entry.exercise.name))).get();
				final exerciseId = existing.isNotEmpty ? existing.first.id : const Uuid().v4();
				if (existing.isEmpty) {
					await db.into(db.exercises).insert(
						ExercisesCompanion.insert(
							id: exerciseId,
							name: entry.exercise.name,
							category: entry.exercise.category,
						),
					);
				}
				await db.into(db.exerciseEntries).insert(
					ExerciseEntriesCompanion(
						id: Value(entry.id),
						seanceId: Value(seance.id),
						exerciseId: Value(exerciseId),
						startedAt: Value(entry.startedAt),
						completedAt: Value(entry.completedAt),
					),
					mode: InsertMode.insertOrReplace,
				);
				for (final set in entry.sets) {
					await db.into(db.exerciseSets).insert(
						ExerciseSetsCompanion.insert(
							id: const Uuid().v4(),
							entryId: entry.id,
							reps: set.reps,
							weight: set.weight,
						),
					);
				}
			}
		} catch (e, stack) {
			_log.severe('Failed to save seance', e, stack);
		}
	}

	void addSeance(Seance seance) {
		state = [...state, seance];
		unawaited(_saveToDb(seance));
	}
}

class TemplateListNotifier extends Notifier<List<SeanceTemplate>> {
	late final SeanceRepository _repo;

	@override
	List<SeanceTemplate> build() {
		_repo = ref.read(seanceRepositoryProvider);
		_loadFromDb();
		return [];
	}

	Future<void> _loadFromDb() async {
		try {
			final list = await _repo.listTemplates();
			if (list.isNotEmpty) {
				state = list;
			}
		} catch (_) {}
	}

	Future<void> loadTemplates() async {
		state = await _repo.listTemplates();
	}

	Future<void> createTemplate(SeanceTemplate template) async {
		final created = await _repo.createTemplate(template);
		state = [...state, created];
	}

	Future<void> updateTemplate(SeanceTemplate template) async {
		final updated = await _repo.updateTemplate(template);
		state = state.map((current) => current.id == updated.id ? updated : current).toList();
	}

	Future<void> deleteTemplate(String id) async {
		await _repo.deleteTemplate(id);
		state = state.where((template) => template.id != id).toList();
	}

	Future<SeanceTemplate> cloneTemplate(String id, {DateTime? scheduledFor}) async {
		final cloned = await _repo.cloneTemplate(id, scheduledFor: scheduledFor);
		state = [...state, cloned];
		return cloned;
	}
}

class ActiveSeancePlanNotifier extends Notifier<Map<String, ExerciseTemplate>> {
	@override
	Map<String, ExerciseTemplate> build() => {};

	void setPlanForEntry(String entryId, ExerciseTemplate plan) {
		state = {...state, entryId: plan};
	}

	void clear() {
		state = {};
	}

	void populateFromTemplate(SeanceTemplate template) {
		final seance = ref.read(activeSeanceProvider);
		if (seance == null) return;
		final map = <String, ExerciseTemplate>{};
		for (var i = 0; i < template.exercises.length && i < seance.exercises.length; i++) {
			map[seance.exercises[i].id] = template.exercises[i];
		}
		state = map;
	}
}
