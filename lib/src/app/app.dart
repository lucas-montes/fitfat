import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

final class FitFatApp extends StatelessWidget {
  const FitFatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'FitFat',
        debugShowCheckedModeBanner: false,
        theme: FitFatTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
