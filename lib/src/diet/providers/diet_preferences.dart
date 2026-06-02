import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _macroDisplayKey = 'macro_display_preference';

/// Provider for diet preferences (macro visibility settings)
final dietPreferencesProvider =
    NotifierProvider<DietPreferencesNotifier, DietPreferences>(
      DietPreferencesNotifier.new,
    );

class DietPreferencesNotifier extends Notifier<DietPreferences> {
  @override
  DietPreferences build() {
    _loadFromPrefs();
    return DietPreferences();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsString = prefs.getString(_macroDisplayKey);
      if (prefsString != null) {
        final macros = const JsonDecoder().convert(prefsString);
        state = DietPreferences(macros: macros.cast<String, bool>());
      } else {
        // Default preference: show all macros
        state = DietPreferences(
          macros: {
            'calories': true,
            'protein': true,
            'carbs': true,
            'fat': true,
          },
        );
      }
    } catch (e) {
      // Default to showing all macros on error
      state = DietPreferences(
        macros: {'calories': true, 'protein': true, 'carbs': true, 'fat': true},
      );
    }
  }

  Future<void> savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_macroDisplayKey, const JsonEncoder().convert(state));
  }

  void toggleMacro(String key) {
    final currentValue = state.macros[key] ?? true;
    final newMacros = Map<String, bool>.from(state.macros);
    newMacros[key] = !currentValue;
    state = DietPreferences(macros: newMacros);
    savePrefs();
  }

  void setAllVisible(bool visible) {
    state = DietPreferences(
      macros: {
        'calories': visible,
        'protein': visible,
        'carbs': visible,
        'fat': visible,
      },
    );
    savePrefs();
  }
}

class DietPreferences {
  final Map<String, bool> macros;

  DietPreferences({
    this.macros = const {
      'calories': true,
      'protein': true,
      'carbs': true,
      'fat': true,
    },
  });

  DietPreferences copyWith({Map<String, bool>? macros}) {
    return DietPreferences(macros: macros ?? this.macros);
  }

  bool get isCaloriesVisible => macros['calories'] ?? true;
  bool get isProteinVisible => macros['protein'] ?? true;
  bool get isCarbsVisible => macros['carbs'] ?? true;
  bool get isFatVisible => macros['fat'] ?? true;

  List<String> get visibleMacroKeys =>
      macros.entries.where((e) => e.value).map((e) => e.key).toList();

  Map<String, dynamic> toJson() {
    return Map<String, dynamic>.from(macros);
  }
}
