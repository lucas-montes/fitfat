import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../ui/palettes.dart';
import 'settings.dart';

/// The two palettes the user picked: one used in dark mode, one in light
/// mode, plus the colors of their own custom palette for each. Theme mode
/// itself stays in [SettingsState.themeMode].
@immutable
final class AppearanceState {
  const AppearanceState({
    required this.dark,
    required this.light,
    this.customDark = defaultBase16,
    this.customLight = defaultBase16,
  });

  final ThemePalette dark;
  final ThemePalette light;

  /// The custom palettes' base16 colors (base00 → base0F).
  final List<Color> customDark;
  final List<Color> customLight;

  ThemeData get darkTheme => FitFatTheme.fromPalette(dark);
  ThemeData get lightTheme => FitFatTheme.fromPalette(light);

  ThemePalette forBrightness(Brightness b) =>
      b == Brightness.dark ? dark : light;

  List<Color> customFor(Brightness b) =>
      b == Brightness.dark ? customDark : customLight;

  ThemePalette customPalette(Brightness b) =>
      paletteFromBase16(customFor(b), b);
}

final appearanceProvider =
    NotifierProvider<AppearanceNotifier, AppearanceState>(
      AppearanceNotifier.new,
    );

final class AppearanceNotifier extends Notifier<AppearanceState> {
  static const darkPaletteKey = 'settings_dark_palette';
  static const lightPaletteKey = 'settings_light_palette';
  static const customDarkKey = 'settings_custom_dark_base16';
  static const customLightKey = 'settings_custom_light_base16';

  @override
  AppearanceState build() {
    final prefs = ref.watch(sharedPreferencesHolderProvider);
    final customDark = _readColors(prefs?.getStringList(customDarkKey));
    final customLight = _readColors(prefs?.getStringList(customLightKey));
    ThemePalette pick(String? id, Brightness b, List<Color> custom) =>
        id == customPaletteId
        ? paletteFromBase16(custom, b)
        : paletteById(id, b);
    return AppearanceState(
      dark: pick(prefs?.getString(darkPaletteKey), Brightness.dark, customDark),
      light: pick(
        prefs?.getString(lightPaletteKey),
        Brightness.light,
        customLight,
      ),
      customDark: customDark,
      customLight: customLight,
    );
  }

  /// Saved hex strings, falling back to the defaults slot by slot.
  static List<Color> _readColors(List<String>? hex) => [
    for (var i = 0; i < 16; i++)
      (hex != null && i < hex.length ? colorFromHex(hex[i]) : null) ??
          defaultBase16[i],
  ];

  /// Sets the palette for [palette]'s brightness. Applies immediately.
  Future<void> setPalette(ThemePalette palette) async {
    final dark = palette.brightness == Brightness.dark;
    state = AppearanceState(
      dark: dark ? palette : state.dark,
      light: dark ? state.light : palette,
      customDark: state.customDark,
      customLight: state.customLight,
    );
    await ref
        .read(sharedPreferencesHolderProvider)
        ?.setString(dark ? darkPaletteKey : lightPaletteKey, palette.id);
  }

  /// Replaces slots of [brightness]'s custom palette (slot → color). When
  /// that palette is the one in use, the theme follows at once.
  Future<void> setCustomColors(
    Brightness brightness,
    Map<int, Color> changes,
  ) async {
    final colors = [...state.customFor(brightness)];
    changes.forEach((i, c) {
      if (i >= 0 && i < 16) colors[i] = c;
    });
    await _saveCustom(brightness, colors);
  }

  /// Puts [brightness]'s custom palette back to the default colors.
  Future<void> resetCustom(Brightness brightness) =>
      _saveCustom(brightness, defaultBase16);

  Future<void> _saveCustom(Brightness b, List<Color> colors) async {
    final dark = b == Brightness.dark;
    final palette = paletteFromBase16(colors, b);
    final inUse = state.forBrightness(b).id == customPaletteId;
    state = AppearanceState(
      dark: dark && inUse ? palette : state.dark,
      light: !dark && inUse ? palette : state.light,
      customDark: dark ? colors : state.customDark,
      customLight: dark ? state.customLight : colors,
    );
    await ref.read(sharedPreferencesHolderProvider)?.setStringList(
      dark ? customDarkKey : customLightKey,
      [for (final c in colors) colorToHex(c)],
    );
  }
}
