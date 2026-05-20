import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/dashboard_models.dart';
import '../../providers/dashboard_providers.dart';
import '../../widgets/appbar_seance_indicator.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const SizedBox.shrink(),
        actions: const [SeanceAppBarAction()],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const DailyNutritionCard(),
            const SizedBox(height: 16),
            const GoalsCard(),
            const SizedBox(height: 16),
            const StrengthTrendChart(),
            const SizedBox(height: 16),
            const BodyweightTrendChart(),
            const SizedBox(height: 96),
          ],
        ),
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
                'Set a goal and your profile to see daily targets',
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
// Goals card — shows current goal type and computed macros
// ---------------------------------------------------------------------------

class GoalsCard extends ConsumerWidget {
  const GoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalProvider);
    final macros = ref.watch(computedMacrosProvider);

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
                Text('Goals', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showGoalSetup(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (goal == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      'No goal set yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Set Your Goal'),
                      onPressed: () => _showGoalSetup(context, ref),
                    ),
                  ],
                ),
              )
            else ...[
              _buildGoalTypeHeader(context, goal),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Daily Targets (computed)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildGoalRow(
                'Calories',
                '${macros.dailyCalories.toStringAsFixed(0)} kcal',
              ),
              const SizedBox(height: 4),
              _buildGoalRow(
                'Protein',
                '${macros.dailyProtein.toStringAsFixed(0)}g',
              ),
              const SizedBox(height: 4),
              _buildGoalRow(
                'Carbs',
                '${macros.dailyCarbs.toStringAsFixed(0)}g',
              ),
              const SizedBox(height: 4),
              _buildGoalRow('Fat', '${macros.dailyFat.toStringAsFixed(0)}g'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTypeHeader(BuildContext context, Goal goal) {
    return switch (goal) {
      StrengthGoal(:final exerciseName, :final targetWeightKg) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            label: const Text('Gain Strength'),
            avatar: const Icon(Icons.fitness_center, size: 18),
          ),
          const SizedBox(height: 8),
          Text('$exerciseName → ${targetWeightKg.toStringAsFixed(1)} kg'),
        ],
      ),
      BodyWeightGoal(
        :final targetWeightKg,
        :final direction,
        :final targetDate,
      ) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text('${direction.label} Weight'),
              avatar: const Icon(Icons.monitor_weight, size: 18),
            ),
            const SizedBox(height: 8),
            Text('Target: ${targetWeightKg.toStringAsFixed(1)} kg'),
            if (targetDate != null)
              Text('By: ${DateFormat('MMM d, yyyy').format(targetDate)}'),
          ],
        ),
    };
  }

  Widget _buildGoalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  void _showGoalSetup(BuildContext context, WidgetRef ref) {
    final profile = ref.read(userProfileProvider);
    if (profile == null) {
      _showProfileSetup(context, ref);
    } else {
      showDialog(
        context: context,
        builder: (_) => const GoalTypeSelectorDialog(),
      );
    }
  }

  Future<void> _showProfileSetup(BuildContext context, WidgetRef ref) async {
    final profile = await showDialog<UserProfile>(
      context: context,
      builder: (_) => const ProfileSetupDialog(),
    );
    if (profile != null && context.mounted) {
      ref.read(userProfileProvider.notifier).setProfile(profile);
      showDialog(
        context: context,
        builder: (_) => const GoalTypeSelectorDialog(),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Profile setup dialog
// ---------------------------------------------------------------------------

class ProfileSetupDialog extends ConsumerStatefulWidget {
  const ProfileSetupDialog({super.key});

  @override
  ConsumerState<ProfileSetupDialog> createState() => _ProfileSetupDialogState();
}

class _ProfileSetupDialogState extends ConsumerState<ProfileSetupDialog> {
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.moderate;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                label: Text('Age'),
                border: OutlineInputBorder(),
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
            final age = int.tryParse(_ageController.text);
            final height = double.tryParse(_heightController.text);
            final weight = double.tryParse(_weightController.text);
            if (age == null || height == null || weight == null) return;
            Navigator.pop(
              context,
              UserProfile(
                age: age,
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
}

// ---------------------------------------------------------------------------
// Goal type selector dialog
// ---------------------------------------------------------------------------

class GoalTypeSelectorDialog extends ConsumerStatefulWidget {
  const GoalTypeSelectorDialog({super.key});

  @override
  ConsumerState<GoalTypeSelectorDialog> createState() =>
      _GoalTypeSelectorDialogState();
}

class _GoalTypeSelectorDialogState
    extends ConsumerState<GoalTypeSelectorDialog> {
  bool _isStrength = true;

  // Strength fields
  final _exerciseController = TextEditingController();
  final _strengthTargetController = TextEditingController();
  DateTime? _strengthTargetDate;

  // Body weight fields
  final _bwTargetController = TextEditingController();
  BodyWeightDirection _direction = BodyWeightDirection.lose;
  DateTime? _bwTargetDate;

  @override
  void dispose() {
    _exerciseController.dispose();
    _strengthTargetController.dispose();
    _bwTargetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Your Goal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Gain Strength')),
                ButtonSegment(value: false, label: Text('Change Weight')),
              ],
              selected: {_isStrength},
              onSelectionChanged: (v) => setState(() => _isStrength = v.first),
            ),
            const SizedBox(height: 16),
            if (_isStrength)
              _buildStrengthFields()
            else
              _buildBodyWeightFields(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _saveGoal, child: const Text('Save')),
      ],
    );
  }

  Widget _buildStrengthFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _exerciseController,
          decoration: const InputDecoration(
            label: Text('Exercise (e.g. Bench Press)'),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _strengthTargetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            label: Text('Target Weight (kg)'),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        _buildDatePicker(
          label: 'Target date (optional)',
          date: _strengthTargetDate,
          onPicked: (d) => setState(() => _strengthTargetDate = d),
        ),
      ],
    );
  }

  Widget _buildBodyWeightFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          controller: _bwTargetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            label: Text('Target Weight (kg)'),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        _buildDatePicker(
          label: 'Target date (optional)',
          date: _bwTargetDate,
          onPicked: (d) => setState(() => _bwTargetDate = d),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onPicked,
  }) {
    final formatted = date != null
        ? DateFormat('MMM d, yyyy').format(date)
        : 'Not set';
    return Row(
      children: [
        Expanded(child: Text('$label: $formatted')),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            );
            if (picked != null) onPicked(picked);
          },
          child: const Text('Pick'),
        ),
      ],
    );
  }

  void _saveGoal() {
    final Goal goal;
    if (_isStrength) {
      final exercise = _exerciseController.text.trim();
      final target = double.tryParse(_strengthTargetController.text);
      if (exercise.isEmpty || target == null) return;
      goal = StrengthGoal(
        exerciseName: exercise,
        targetWeightKg: target,
        targetDate: _strengthTargetDate,
      );
    } else {
      final target = double.tryParse(_bwTargetController.text);
      if (target == null) return;
      goal = BodyWeightGoal(
        targetWeightKg: target,
        direction: _direction,
        targetDate: _bwTargetDate,
      );
    }
    ref.read(goalProvider.notifier).setGoal(goal);
    Navigator.pop(context);
  }
}

// ---------------------------------------------------------------------------
// Charts (unchanged — kept from original, will be replaced in T08)
// ---------------------------------------------------------------------------

class StrengthTrendChart extends ConsumerWidget {
  const StrengthTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(chartPeriodProvider);
    final strengthData = ref.watch(strengthTrendProvider);

    final days = periodDays(period);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final filteredData = strengthData
        .where((d) => d.date.isAfter(cutoffDate))
        .toList();

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
            ..._buildStrengthChartData(context, filteredData),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStrengthChartData(
    BuildContext context,
    List<StrengthDataPoint> data,
  ) {
    final exercises = ['Bench Press', 'Deadlift', 'Squat'];
    final widgets = <Widget>[];

    for (final exercise in exercises) {
      final exerciseData = data.where((d) => d.exercise == exercise).toList();
      if (exerciseData.isNotEmpty) {
        final maxWeight = exerciseData
            .map((d) => d.maxWeight)
            .reduce((a, b) => a > b ? a : b);
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exercise),
              const SizedBox(height: 4),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.blue.withAlpha(51),
                ),
                child: FractionallySizedBox(
                  widthFactor: maxWeight / 200,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${maxWeight.toStringAsFixed(1)}kg',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      }
    }

    return widgets;
  }
}

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
