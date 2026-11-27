import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../ui/palettes.dart';
import 'settings.dart';

/// The two palettes the user picked: one used in dark mode, one in light
/// mode. Theme mode itself stays in [SettingsState.themeMode].
@immutable
final class AppearanceState {
  const AppearanceState({required this.dark, required this.light});

  final ThemePalette dark;
  final ThemePalette light;

  ThemeData get darkTheme => FitFatTheme.fromPalette(dark);
  ThemeData get lightTheme => FitFatTheme.fromPalette(light);

  ThemePalette forBrightness(Brightness b) =>
      b == Brightness.dark ? dark : light;
}

final appearanceProvider =
    NotifierProvider<AppearanceNotifier, AppearanceState>(
      AppearanceNotifier.new,
    );

final class AppearanceNotifier extends Notifier<AppearanceState> {
  static const darkPaletteKey = 'settings_dark_palette';
  static const lightPaletteKey = 'settings_light_palette';

  @override
  AppearanceState build() {
    final prefs = ref.watch(sharedPreferencesHolderProvider);
    return AppearanceState(
      dark: paletteById(prefs?.getString(darkPaletteKey), Brightness.dark),
      light: paletteById(prefs?.getString(lightPaletteKey), Brightness.light),
    );
  }

  /// Sets the palette for [palette]'s brightness. Applies immediately.
  Future<void> setPalette(ThemePalette palette) async {
    final dark = palette.brightness == Brightness.dark;
    state = dark
        ? AppearanceState(dark: palette, light: state.light)
        : AppearanceState(dark: state.dark, light: palette);
    await ref
        .read(sharedPreferencesHolderProvider)
        ?.setString(dark ? darkPaletteKey : lightPaletteKey, palette.id);
  }
}
