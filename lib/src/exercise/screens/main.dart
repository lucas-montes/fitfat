import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import 'exercises/list.dart';
import 'training/tab.dart';
import 'stats/stats_tab.dart';

class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          elevation: 0,
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.trainingTab),
              Tab(text: l10n.exercises),
              Tab(text: l10n.statsTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [TrainingTab(), ExercisesListTab(), StatsTab()],
        ),
      ),
    );
  }
}
