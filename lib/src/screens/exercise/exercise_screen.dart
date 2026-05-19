import 'package:flutter/material.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            elevation: 0,
            title: const SizedBox.shrink(),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Exercises'),
                Tab(text: 'Seances'),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Exercises')),
            Center(child: Text('Seances')),
          ],
        ),
      ),
    );
  }
}
