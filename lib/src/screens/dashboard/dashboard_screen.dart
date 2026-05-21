import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/dashboard_models.dart';
import '../../models/exercise_models.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/exercise_providers.dart';
import '../../widgets/appbar_seance_indicator.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NOTE: Dashboard tab bar height matches Diet tab via PreferredSize(kToolbarHeight)
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            elevation: 0,
            title: const SizedBox.shrink(),
            actions: const [SeanceAppBarAction()],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Goals'),
              ],
            ),
          ),
        ),
        body: TabBarView(children: [_OverviewTab(), const _GoalsTab()]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview tab — nutrition, charts, no goals card
// ---------------------------------------------------------------------------

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          DailyNutritionCard(),
          SizedBox(height: 16),
          StrengthTrendChart(),
          SizedBox(height: 16),
          BodyweightTrendChart(),
          SizedBox(height: 96),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily nutrition card — reads computed macros
// ---------------------------------------------------------------------------

class DailyNutritionCard extends ConsumerWidget {
  const DailyNutritionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyNutrition = ref.watch(dailyNutritionProvider);
    final macros = ref.watch(computedMacrosProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildMacroRow(
              context,
              'Calories',
              '${dailyNutrition.calories.toStringAsFixed(0)} kcal',
              '${macros.dailyCalories.toStringAsFixed(0)} kcal',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              context,
              'Protein',
              '${dailyNutrition.protein.toStringAsFixed(1)}g',
              '${macros.dailyProtein.toStringAsFixed(0)}g',
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              context,
              'Carbs',
              '${dailyNutrition.carbs.toStringAsFixed(1)}g',
              '${macros.dailyCarbs.toStringAsFixed(0)}g',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              context,
              'Fat',
              '${dailyNutrition.fat.toStringAsFixed(1)}g',
              '${macros.dailyFat.toStringAsFixed(0)}g',
              Colors.green,
            ),
            const SizedBox(height: 8),
            if (macros == ComputedMacros.zero)
              Text(
                'Set a bodyweight goal and your profile to see daily targets.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(
    BuildContext context,
    String label,
    String value,
    String target,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
        Text('$value / $target'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Goals tab — manage bodyweight goal + N strength goals
// ---------------------------------------------------------------------------

class _GoalsTab extends ConsumerWidget {
  const _GoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsData = ref.watch(goalsProvider);
    final hasProfile = ref.watch(userProfileProvider) != null;
    final hasAnyGoal =
        goalsData.bodyWeightGoal != null || goalsData.strengthGoals.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bodyweight goal section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Body Weight Goal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (goalsData.bodyWeightGoal != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editBodyWeightGoal(
                              context,
                              ref,
                              goalsData.bodyWeightGoal!,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () =>
                                _confirmDeleteBodyWeight(context, ref),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (goalsData.bodyWeightGoal == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          'No bodyweight goal set.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Body Weight Goal'),
                          onPressed: () => hasProfile
                              ? _createBodyWeightGoal(context, ref)
                              : _promptProfileFirst(context, ref),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Chip(
                    label: Text(
                      '${goalsData.bodyWeightGoal!.direction.label} Weight',
                    ),
                    avatar: const Icon(Icons.monitor_weight, size: 18),
                  ),
                  const SizedBox(height: 8),
                  _goalDetailRow(
                    'Target',
                    '${goalsData.bodyWeightGoal!.targetWeightKg.toStringAsFixed(1)} kg',
                  ),
                  if (goalsData.bodyWeightGoal!.targetDate != null)
                    _goalDetailRow(
                      'By',
                      DateFormat(
                        'MMM d, yyyy',
                      ).format(goalsData.bodyWeightGoal!.targetDate!),
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Strength goals section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Strength Goals',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add strength goal',
                      onPressed: () => hasProfile
                          ? _createStrengthGoal(context, ref)
                          : _promptProfileFirst(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (goalsData.strengthGoals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No strength goals yet. Tap + to add (one per exercise).',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final sg in goalsData.strengthGoals) ...[
                    _strengthGoalTile(context, ref, sg),
                    const Divider(height: 1),
                  ],
              ],
            ),
          ),
        ),
        if (!hasProfile && !hasAnyGoal)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Set up your profile first',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _promptProfileFirst(context, ref),
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            ),
          )
        else if (hasProfile)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Profile'),
                onPressed: () => _promptProfileFirst(context, ref),
              ),
            ),
          ),
      ],
    );
  }

  Widget _goalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _strengthGoalTile(
    BuildContext context,
    WidgetRef ref,
    StrengthGoal goal,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.fitness_center),
      title: Text(
        '${goal.exerciseName} → ${goal.targetWeightKg.toStringAsFixed(0)} kg',
      ),
      subtitle: goal.targetDate != null
          ? Text('By ${DateFormat('MMM d, yyyy').format(goal.targetDate!)}')
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editStrengthGoal(context, ref, goal),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: () =>
                _confirmDeleteStrength(context, ref, goal.exerciseName),
          ),
        ],
      ),
    );
  }

  void _promptProfileFirst(BuildContext context, WidgetRef ref) {
    final existing = ref.read(userProfileProvider);
    showDialog(
      context: context,
      builder: (_) => ProfileSetupDialog(initial: existing),
    ).then((profile) {
      if (profile != null && context.mounted) {
        ref
            .read(userProfileProvider.notifier)
            .setProfile(profile as UserProfile);
      }
    });
  }

  void _createBodyWeightGoal(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => const BodyWeightGoalDialog());
  }

  void _editBodyWeightGoal(
    BuildContext context,
    WidgetRef ref,
    BodyWeightGoal existing,
  ) {
    showDialog(
      context: context,
      builder: (_) => BodyWeightGoalDialog(existing: existing),
    );
  }

  void _confirmDeleteBodyWeight(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bodyweight goal?'),
        content: const Text(
          'This will clear your weight target and macro targets.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        ref.read(goalsProvider.notifier).clearBodyWeightGoal();
      }
    });
  }

  void _createStrengthGoal(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => const StrengthGoalDialog());
  }

  void _editStrengthGoal(
    BuildContext context,
    WidgetRef ref,
    StrengthGoal existing,
  ) {
    showDialog(
      context: context,
      builder: (_) => StrengthGoalDialog(existing: existing),
    );
  }

  void _confirmDeleteStrength(
    BuildContext context,
    WidgetRef ref,
    String exerciseName,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete strength goal for $exerciseName?'),
        content: const Text('This will remove the goal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        ref.read(goalsProvider.notifier).removeStrengthGoal(exerciseName);
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Profile setup dialog
// ---------------------------------------------------------------------------

class ProfileSetupDialog extends ConsumerStatefulWidget {
  const ProfileSetupDialog({super.key, this.initial});

  final UserProfile? initial;

  @override
  ConsumerState<ProfileSetupDialog> createState() => _ProfileSetupDialogState();
}

class _ProfileSetupDialogState extends ConsumerState<ProfileSetupDialog> {
  DateTime _birthDate = DateTime(1990);
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.moderate;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _birthDate = init.birthDate;
      _heightController.text = init.heightCm.toString();
      _weightController.text = init.weightKg.toString();
      _sex = init.sex;
      _activity = init.activityLevel;
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Your Profile' : 'Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Birthdate picker — calendar-only, consistent with other inputs
            InputDecorator(
              decoration: InputDecoration(
                label: const Text('Birthdate'),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _birthDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                      switchToInputEntryModeIcon: null,
                    );
                    if (picked != null) setState(() => _birthDate = picked);
                  },
                ),
              ),
              child: Text(
                '${DateFormat('dd/MM/yyyy').format(_birthDate)}  (age ${_computeAge(_birthDate)})',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Sex>(
              initialValue: _sex,
              decoration: const InputDecoration(
                label: Text('Sex'),
                border: OutlineInputBorder(),
              ),
              items: Sex.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _sex = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                label: Text('Height (cm)'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                label: Text('Weight (kg)'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ActivityLevel>(
              initialValue: _activity,
              decoration: const InputDecoration(
                label: Text('Activity Level'),
                border: OutlineInputBorder(),
              ),
              items: ActivityLevel.values
                  .map((a) => DropdownMenuItem(value: a, child: Text(a.label)))
                  .toList(),
              onChanged: (v) => setState(() => _activity = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final height = double.tryParse(_heightController.text);
            final weight = double.tryParse(_weightController.text);
            if (height == null || weight == null) return;
            Navigator.pop(
              context,
              UserProfile(
                birthDate: _birthDate,
                sex: _sex,
                heightCm: height,
                weightKg: weight,
                activityLevel: _activity,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  int _computeAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

// ---------------------------------------------------------------------------
// Body weight goal dialog
// ---------------------------------------------------------------------------

class BodyWeightGoalDialog extends ConsumerStatefulWidget {
  const BodyWeightGoalDialog({super.key, this.existing});

  final BodyWeightGoal? existing;

  @override
  ConsumerState<BodyWeightGoalDialog> createState() =>
      _BodyWeightGoalDialogState();
}

class _BodyWeightGoalDialogState extends ConsumerState<BodyWeightGoalDialog> {
  final _weightController = TextEditingController();
  BodyWeightDirection _direction = BodyWeightDirection.lose;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _weightController.text = e.targetWeightKg.toString();
      _direction = e.direction;
      _targetDate = e.targetDate;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Add Body Weight Goal'
            : 'Edit Body Weight Goal',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<BodyWeightDirection>(
            initialValue: _direction,
            decoration: const InputDecoration(
              label: Text('Direction'),
              border: OutlineInputBorder(),
            ),
            items: BodyWeightDirection.values
                .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                .toList(),
            onChanged: (v) => setState(() => _direction = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              label: Text('Target Weight (kg)'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _buildDatePicker(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  Widget _buildDatePicker() {
    final initial = _targetDate ?? DateTime.now().add(const Duration(days: 1));
    return InputDecorator(
      decoration: InputDecoration(
        label: const Text('Target date'),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              switchToInputEntryModeIcon: null,
            );
            if (picked != null) setState(() => _targetDate = picked);
          },
        ),
      ),
      child: Text(
        _targetDate != null
            ? DateFormat('dd/MM/yyyy').format(_targetDate!)
            : 'Not set',
      ),
    );
  }

  void _save() {
    final target = double.tryParse(_weightController.text);
    if (target == null) return;
    final goal = BodyWeightGoal(
      targetWeightKg: target,
      direction: _direction,
      targetDate: _targetDate,
    );
    ref.read(goalsProvider.notifier).setBodyWeightGoal(goal);
    Navigator.pop(context);
  }
}

// ---------------------------------------------------------------------------
// Strength goal dialog
// ---------------------------------------------------------------------------

class StrengthGoalDialog extends ConsumerStatefulWidget {
  const StrengthGoalDialog({super.key, this.existing});

  final StrengthGoal? existing;

  @override
  ConsumerState<StrengthGoalDialog> createState() => _StrengthGoalDialogState();
}

class _StrengthGoalDialogState extends ConsumerState<StrengthGoalDialog> {
  final _exerciseController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _exerciseController.text = e.exerciseName;
      _weightController.text = e.targetWeightKg.toString();
      _targetDate = e.targetDate;
    }
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allExercises = ref.watch(exerciseListProvider);
    final goalsData = ref.watch(goalsProvider);
    final existingStrengthNames = goalsData.strengthGoals
        .map((g) => g.exerciseName)
        .toSet();

    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add Strength Goal' : 'Edit Strength Goal',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Autocomplete<ExerciseDefinition>(
            optionsBuilder: (textEditingValue) {
              final text = textEditingValue.text.toLowerCase();
              if (text.isEmpty) return Iterable.empty();
              return allExercises.where(
                (e) =>
                    e.name.toLowerCase().contains(text) &&
                    !existingStrengthNames.contains(e.name),
              );
            },
            displayStringForOption: (e) => e.name,
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              // Sync external controller when Autocomplete controller changes
              controller.addListener(() {
                if (_exerciseController.text != controller.text) {
                  _exerciseController.text = controller.text;
                }
              });
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  label: Text('Exercise'),
                  hintText: 'Search or type custom name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  final match = allExercises.where(
                    (e) => e.name.toLowerCase() == value.toLowerCase(),
                  );
                  if (match.isNotEmpty) {
                    _exerciseController.text = match.first.name;
                    onSubmitted();
                  }
                },
              );
            },
            onSelected: (exercise) {
              _exerciseController.text = exercise.name;
              _exerciseController.selection = TextSelection.collapsed(
                offset: exercise.name.length,
              );
              // Also update the TextField if it's visible
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              label: Text('Target Weight (kg)'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _buildDatePicker(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  Widget _buildDatePicker() {
    final initial = _targetDate ?? DateTime.now().add(const Duration(days: 1));
    return InputDecorator(
      decoration: InputDecoration(
        label: const Text('Target date'),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              switchToInputEntryModeIcon: null,
            );
            if (picked != null) setState(() => _targetDate = picked);
          },
        ),
      ),
      child: Text(
        _targetDate != null
            ? DateFormat('dd/MM/yyyy').format(_targetDate!)
            : 'Not set',
      ),
    );
  }

  void _save() {
    final exercise = _exerciseController.text.trim();
    final target = double.tryParse(_weightController.text);
    if (exercise.isEmpty || target == null) return;
    final goal = StrengthGoal(
      exerciseName: exercise,
      targetWeightKg: target,
      targetDate: _targetDate,
    );
    ref.read(goalsProvider.notifier).addStrengthGoal(goal);
    Navigator.pop(context);
  }
}

// ---------------------------------------------------------------------------
// Strength trend chart — fl_chart LineChart + goal progress bar
// ---------------------------------------------------------------------------

const _chartColors = [Colors.blue, Colors.orange, Colors.green];

class StrengthTrendChart extends ConsumerWidget {
  const StrengthTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(chartPeriodProvider);
    final strengthData = ref.watch(strengthTrendProvider);
    final goalsData = ref.watch(goalsProvider);

    final days = periodDays(period);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final filteredData = strengthData
        .where((d) => d.date.isAfter(cutoffDate))
        .toList();

    final exercises = ['Bench Press', 'Deadlift', 'Squat'];
    final exerciseLines = <LineChartBarData>[];

    for (var i = 0; i < exercises.length; i++) {
      final exerciseData = filteredData
          .where((d) => d.exercise == exercises[i])
          .toList();
      if (exerciseData.isEmpty) continue;

      exerciseLines.add(
        LineChartBarData(
          spots: List.generate(
            exerciseData.length,
            (j) => FlSpot(j.toDouble(), exerciseData[j].maxWeight),
          ),
          isCurved: true,
          preventCurveOverShooting: true,
          color: _chartColors[i],
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: _chartColors[i].withAlpha(30),
          ),
        ),
      );
    }

    // Build Y-axis labels from all data
    final allWeights = filteredData.map((d) => d.maxWeight);
    final minY = (allWeights.reduce((a, b) => a < b ? a : b) * 0.95)
        .floorToDouble();
    final maxY = (allWeights.reduce((a, b) => a > b ? a : b) * 1.05)
        .ceilToDouble();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Strength Trend',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DropdownButton<ChartPeriod>(
                  value: period,
                  items: ChartPeriod.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(periodLabel(p)),
                    );
                  }).toList(),
                  onChanged: (newPeriod) {
                    if (newPeriod != null) {
                      ref
                          .read(chartPeriodProvider.notifier)
                          .updatePeriod(newPeriod);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: exerciseLines.isEmpty
                  ? const Center(child: Text('No strength data'))
                  : LineChart(
                      LineChartData(
                        minX: 0,
                        maxX:
                            (exerciseLines.isNotEmpty
                                    ? exerciseLines.first.spots.length - 1
                                    : 0)
                                .toDouble(),
                        minY: minY,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: ((maxY - minY) / 4).clamp(
                            1,
                            double.infinity,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: exerciseLines,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: List.generate(exercises.length, (i) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _chartColors[i],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(exercises[i], style: const TextStyle(fontSize: 12)),
                  ],
                );
              }),
            ),
            // Goal progress bar: find matching strength goal
            if (goalsData.strengthGoals.isNotEmpty)
              for (final sg in goalsData.strengthGoals)
                _buildStrengthProgress(context, filteredData, sg),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthProgress(
    BuildContext context,
    List<StrengthDataPoint> data,
    StrengthGoal goal,
  ) {
    final exerciseData = data
        .where((d) => d.exercise == goal.exerciseName)
        .toList();
    final currentMax = exerciseData.isNotEmpty
        ? exerciseData.map((d) => d.maxWeight).reduce((a, b) => a > b ? a : b)
        : 0.0;

    final progress = goal.targetWeightKg > 0
        ? (currentMax / goal.targetWeightKg).clamp(0.0, 1.0)
        : 0.0;
    final remaining = goal.targetWeightKg - currentMax;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal: ${goal.exerciseName} → ${goal.targetWeightKg.toStringAsFixed(0)} kg',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              color: progress >= 1.0 ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progress >= 1.0
                ? 'Goal reached! (${currentMax.toStringAsFixed(0)} kg)'
                : '${currentMax.toStringAsFixed(0)} kg / ${goal.targetWeightKg.toStringAsFixed(0)} kg '
                      '(${(progress * 100).toStringAsFixed(0)}%) — '
                      '${remaining.toStringAsFixed(0)} kg to go',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bodyweight trend chart (unchanged)
// ---------------------------------------------------------------------------

class BodyweightTrendChart extends ConsumerWidget {
  const BodyweightTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightData = ref.watch(weightTrendProvider);

    final now = DateTime.now();
    final minDate = now.subtract(const Duration(days: 90));
    final filteredData = weightData
        .where((d) => d.date.isAfter(minDate))
        .toList();

    if (filteredData.isEmpty) {
      return const SizedBox.shrink();
    }

    final minWeight = filteredData
        .map((d) => d.weight)
        .reduce((a, b) => a < b ? a : b);
    final maxWeight = filteredData
        .map((d) => d.weight)
        .reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bodyweight Trend (90 days)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(filteredData.length, (i) {
                  final data = filteredData[i];
                  final normalizedHeight = range > 0
                      ? (data.weight - minWeight) / range
                      : 0.5;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: normalizedHeight * 100,
                          width: 4,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${minWeight.toStringAsFixed(1)}kg'),
                Text('${maxWeight.toStringAsFixed(1)}kg'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
