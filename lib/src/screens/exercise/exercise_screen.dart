import 'package:flutter/material.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exercise'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Exercises'),
              Tab(text: 'Seances'),
            ],
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
