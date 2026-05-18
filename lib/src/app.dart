import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'router/app_router.dart';

class FitFatApp extends StatelessWidget {
  const FitFatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'fitfat',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
