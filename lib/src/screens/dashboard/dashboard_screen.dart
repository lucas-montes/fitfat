import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class DailyNutritionCard extends ConsumerWidget {
  const DailyNutritionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyNutrition = ref.watch(dailyNutritionProvider);
    final goal = ref.watch(goalProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildMacroRow(
              context,
              'Calories',
              dailyNutrition.calories.toStringAsFixed(0),
              goal.dailyCalories.toStringAsFixed(0),
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              context,
              'Protein',
              dailyNutrition.protein.toStringAsFixed(1),
              goal.dailyProtein.toStringAsFixed(1),
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              context,
              'Carbs',
              dailyNutrition.carbs.toStringAsFixed(1),
              goal.dailyCarbs.toStringAsFixed(1),
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              context,
              'Fat',
              dailyNutrition.fat.toStringAsFixed(1),
              goal.dailyFat.toStringAsFixed(1),
              Colors.green,
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
        Text('$value / $target g'),
      ],
    );
  }
}

class GoalsCard extends ConsumerWidget {
  const GoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalProvider);

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
                  'Goals',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showGoalsEditor(context, ref, goal),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGoalRow('Daily Calories', '${goal.dailyCalories.toStringAsFixed(0)} kcal'),
            const SizedBox(height: 8),
            _buildGoalRow('Daily Protein', '${goal.dailyProtein.toStringAsFixed(0)}g'),
            const SizedBox(height: 8),
            _buildGoalRow('Daily Carbs', '${goal.dailyCarbs.toStringAsFixed(0)}g'),
            const SizedBox(height: 8),
            _buildGoalRow('Daily Fat', '${goal.dailyFat.toStringAsFixed(0)}g'),
            const SizedBox(height: 8),
            _buildGoalRow('Target Weight', '${goal.targetWeight.toStringAsFixed(1)}kg'),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showGoalsEditor(
    BuildContext context,
    WidgetRef ref,
    NutritionGoal goal,
  ) {
    showDialog(
      context: context,
      builder: (context) => GoalsEditDialog(goal: goal),
    );
  }
}

class GoalsEditDialog extends ConsumerStatefulWidget {
  const GoalsEditDialog({required this.goal, super.key});

  final NutritionGoal goal;

  @override
  ConsumerState<GoalsEditDialog> createState() => _GoalsEditDialogState();
}

class _GoalsEditDialogState extends ConsumerState<GoalsEditDialog> {
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _caloriesController = TextEditingController(
      text: widget.goal.dailyCalories.toStringAsFixed(0),
    );
    _proteinController = TextEditingController(
      text: widget.goal.dailyProtein.toStringAsFixed(0),
    );
    _carbsController = TextEditingController(
      text: widget.goal.dailyCarbs.toStringAsFixed(0),
    );
    _fatController = TextEditingController(
      text: widget.goal.dailyFat.toStringAsFixed(0),
    );
    _weightController = TextEditingController(
      text: widget.goal.targetWeight.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Goals'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                label: Text('Daily Calories'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _proteinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                label: Text('Daily Protein (g)'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _carbsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                label: Text('Daily Carbs (g)'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fatController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                label: Text('Daily Fat (g)'),
                border: OutlineInputBorder(),
              ),
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
            ref.read(goalProvider.notifier).updateGoal(
                  dailyCalories: double.tryParse(_caloriesController.text),
                  dailyProtein: double.tryParse(_proteinController.text),
                  dailyCarbs: double.tryParse(_carbsController.text),
                  dailyFat: double.tryParse(_fatController.text),
                  targetWeight: double.tryParse(_weightController.text),
                );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

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
                      ref.read(chartPeriodProvider.notifier).updatePeriod(newPeriod);
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
        final maxWeight = exerciseData.map((d) => d.maxWeight).reduce((a, b) => a > b ? a : b);
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
    final filteredData = weightData.where((d) => d.date.isAfter(minDate)).toList();

    if (filteredData.isEmpty) {
      return const SizedBox.shrink();
    }

    final minWeight = filteredData.map((d) => d.weight).reduce((a, b) => a < b ? a : b);
    final maxWeight = filteredData.map((d) => d.weight).reduce((a, b) => a > b ? a : b);
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
                children: List.generate(
                  filteredData.length,
                  (i) {
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
                  },
                ),
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
