import 'package:flutter/material.dart';

final class FitFatTheme {
  FitFatTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.teal,
    brightness: Brightness.light,
  );
}
