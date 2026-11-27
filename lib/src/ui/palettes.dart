import 'package:material_ui/material_ui.dart';

/// A color palette: the 13 roles every screen draws from.
///
/// The theme is built from one palette per brightness (see
/// `FitFatTheme.fromPalette`); the user picks both in Settings › Appearance.
/// Values follow each theme's published colors, with `muted` nudged where
/// needed so secondary text keeps ≥ 4.5:1 contrast on `bg` and `surface`.
@immutable
final class ThemePalette {
  const ThemePalette({
    required this.id,
    required this.name,
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.raise,
    required this.fg,
    required this.muted,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.onDanger,
  });

  /// Stable id stored in preferences.
  final String id;

  /// Display name (a proper name, not translated).
  final String name;
  final Brightness brightness;

  /// Screen canvas.
  final Color bg;

  /// Cards, grouped sections and form fields.
  final Color surface;

  /// Highest surface: chips, tracks, selected rows, hairline-heavy areas.
  final Color surface2;

  /// Raised surfaces: dialogs, sheets, menus.
  final Color raise;

  /// Primary text.
  final Color fg;

  /// Secondary text and icons.
  final Color muted;

  /// Dividers and outlines.
  final Color line;
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color onDanger;
}

/// Dark palettes, default first.
const List<ThemePalette> darkPalettes = [
  ThemePalette(
    id: 'dracula',
    name: 'Dracula',
    brightness: Brightness.dark,
    bg: Color(0xFF282A36),
    surface: Color(0xFF313343),
    surface2: Color(0xFF44475A),
    raise: Color(0xFF363949),
    fg: Color(0xFFF8F8F2),
    muted: Color(0xFFA9B0D3),
    line: Color(0xFF44475A),
    accent: Color(0xFFBD93F9),
    onAccent: Color(0xFF282A36),
    success: Color(0xFF50FA7B),
    warning: Color(0xFFFFB86C),
    danger: Color(0xFFFF5555),
    onDanger: Color(0xFF282A36),
  ),
  ThemePalette(
    id: 'mocha',
    name: 'Catppuccin Mocha',
    brightness: Brightness.dark,
    bg: Color(0xFF1E1E2E),
    surface: Color(0xFF28283A),
    surface2: Color(0xFF313244),
    raise: Color(0xFF313244),
    fg: Color(0xFFCDD6F4),
    muted: Color(0xFFA6ADC8),
    line: Color(0xFF45475A),
    accent: Color(0xFFCBA6F7),
    onAccent: Color(0xFF1E1E2E),
    success: Color(0xFFA6E3A1),
    warning: Color(0xFFFAB387),
    danger: Color(0xFFF38BA8),
    onDanger: Color(0xFF1E1E2E),
  ),
  ThemePalette(
    id: 'nord',
    name: 'Nord',
    brightness: Brightness.dark,
    bg: Color(0xFF2E3440),
    surface: Color(0xFF3B4252),
    surface2: Color(0xFF434C5E),
    raise: Color(0xFF3B4252),
    fg: Color(0xFFECEFF4),
    muted: Color(0xFFC2CAD8),
    line: Color(0xFF4C566A),
    accent: Color(0xFF88C0D0),
    onAccent: Color(0xFF2E3440),
    success: Color(0xFFA3BE8C),
    warning: Color(0xFFEBCB8B),
    danger: Color(0xFFD27983),
    onDanger: Color(0xFF2E3440),
  ),
  ThemePalette(
    id: 'gruvbox',
    name: 'Gruvbox Dark',
    brightness: Brightness.dark,
    bg: Color(0xFF282828),
    surface: Color(0xFF32302F),
    surface2: Color(0xFF3C3836),
    raise: Color(0xFF3C3836),
    fg: Color(0xFFEBDBB2),
    muted: Color(0xFFBDAE93),
    line: Color(0xFF504945),
    accent: Color(0xFFFABD2F),
    onAccent: Color(0xFF282828),
    success: Color(0xFFB8BB26),
    warning: Color(0xFFFE8019),
    danger: Color(0xFFFB4934),
    onDanger: Color(0xFF282828),
  ),
  ThemePalette(
    id: 'solarized',
    name: 'Solarized Dark',
    brightness: Brightness.dark,
    bg: Color(0xFF002B36),
    surface: Color(0xFF073642),
    surface2: Color(0xFF0D4251),
    raise: Color(0xFF073642),
    fg: Color(0xFFEEE8D5),
    muted: Color(0xFF93A1A1),
    line: Color(0xFF16505F),
    accent: Color(0xFF268BD2),
    onAccent: Color(0xFFFDF6E3),
    success: Color(0xFF859900),
    warning: Color(0xFFB58900),
    danger: Color(0xFFE2504B),
    onDanger: Color(0xFFFDF6E3),
  ),
  ThemePalette(
    id: 'tokyo',
    name: 'Tokyo Night',
    brightness: Brightness.dark,
    bg: Color(0xFF1A1B26),
    surface: Color(0xFF222436),
    surface2: Color(0xFF292E42),
    raise: Color(0xFF24283B),
    fg: Color(0xFFC0CAF5),
    muted: Color(0xFFA9B1D6),
    line: Color(0xFF3B4261),
    accent: Color(0xFF7AA2F7),
    onAccent: Color(0xFF1A1B26),
    success: Color(0xFF9ECE6A),
    warning: Color(0xFFE0AF68),
    danger: Color(0xFFF7768E),
    onDanger: Color(0xFF1A1B26),
  ),
  ThemePalette(
    id: 'teal',
    name: 'FitFat Teal',
    brightness: Brightness.dark,
    bg: Color(0xFF101415),
    surface: Color(0xFF181D1E),
    surface2: Color(0xFF333B3C),
    raise: Color(0xFF282F30),
    fg: Color(0xFFDEE4E2),
    muted: Color(0xFFBEC9C6),
    line: Color(0xFF3F4947),
    accent: Color(0xFF80D5CE),
    onAccent: Color(0xFF003734),
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    danger: Color(0xFFFFB4AB),
    onDanger: Color(0xFF690005),
  ),
];

/// Light palettes, default first.
const List<ThemePalette> lightPalettes = [
  ThemePalette(
    id: 'alucard',
    name: 'Alucard',
    brightness: Brightness.light,
    bg: Color(0xFFFFFBEB),
    surface: Color(0xFFF6F1DC),
    surface2: Color(0xFFECE6CF),
    raise: Color(0xFFFFFDF5),
    fg: Color(0xFF1F1F1F),
    muted: Color(0xFF635D45),
    line: Color(0xFFDCD6C0),
    accent: Color(0xFF644AC9),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF14710A),
    warning: Color(0xFFA34D14),
    danger: Color(0xFFCB3A2A),
    onDanger: Color(0xFFFFFFFF),
  ),
  ThemePalette(
    id: 'latte',
    name: 'Catppuccin Latte',
    brightness: Brightness.light,
    bg: Color(0xFFEFF1F5),
    surface: Color(0xFFE6E9EF),
    surface2: Color(0xFFDCE0E8),
    raise: Color(0xFFF8F9FB),
    fg: Color(0xFF4C4F69),
    muted: Color(0xFF5C5F77),
    line: Color(0xFFCCD0DA),
    accent: Color(0xFF8839EF),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF2F7D1F),
    warning: Color(0xFFB4530A),
    danger: Color(0xFFD20F39),
    onDanger: Color(0xFFFFFFFF),
  ),
  ThemePalette(
    id: 'nordlight',
    name: 'Nord Light',
    brightness: Brightness.light,
    bg: Color(0xFFECEFF4),
    surface: Color(0xFFE5E9F0),
    surface2: Color(0xFFD8DEE9),
    raise: Color(0xFFF5F7FA),
    fg: Color(0xFF2E3440),
    muted: Color(0xFF4C566A),
    line: Color(0xFFCDD4E0),
    accent: Color(0xFF5E81AC),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF4E7A38),
    warning: Color(0xFF966A10),
    danger: Color(0xFFB0464F),
    onDanger: Color(0xFFFFFFFF),
  ),
  ThemePalette(
    id: 'gruvlight',
    name: 'Gruvbox Light',
    brightness: Brightness.light,
    bg: Color(0xFFFBF1C7),
    surface: Color(0xFFF2E5BC),
    surface2: Color(0xFFEBDBB2),
    raise: Color(0xFFF9F5D7),
    fg: Color(0xFF3C3836),
    muted: Color(0xFF665C54),
    line: Color(0xFFD5C4A1),
    accent: Color(0xFFAF3A03),
    onAccent: Color(0xFFFBF1C7),
    success: Color(0xFF79740E),
    warning: Color(0xFFB57614),
    danger: Color(0xFF9D0006),
    onDanger: Color(0xFFFBF1C7),
  ),
  ThemePalette(
    id: 'sollight',
    name: 'Solarized Light',
    brightness: Brightness.light,
    bg: Color(0xFFFDF6E3),
    surface: Color(0xFFEEE8D5),
    surface2: Color(0xFFE4DDC8),
    raise: Color(0xFFFFFBF0),
    fg: Color(0xFF073642),
    muted: Color(0xFF586E75),
    line: Color(0xFFDDD6C1),
    accent: Color(0xFF1F78B8),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF647300),
    warning: Color(0xFF8C6800),
    danger: Color(0xFFC42B28),
    onDanger: Color(0xFFFFFFFF),
  ),
  ThemePalette(
    id: 'tokyoday',
    name: 'Tokyo Day',
    brightness: Brightness.light,
    bg: Color(0xFFE1E2E7),
    surface: Color(0xFFD5D6DB),
    surface2: Color(0xFFC8CAD3),
    raise: Color(0xFFECEDF1),
    fg: Color(0xFF343B58),
    muted: Color(0xFF5A6191),
    line: Color(0xFFC4C8DA),
    accent: Color(0xFF2E7DE9),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF4F6E2E),
    warning: Color(0xFF8C6C3E),
    danger: Color(0xFFD21F55),
    onDanger: Color(0xFFFFFFFF),
  ),
  ThemePalette(
    id: 'teal',
    name: 'FitFat Teal',
    brightness: Brightness.light,
    bg: Color(0xFFF4FBF9),
    surface: Color(0xFFEEF5F3),
    surface2: Color(0xFFDDE4E2),
    raise: Color(0xFFE9EFED),
    fg: Color(0xFF161D1C),
    muted: Color(0xFF3F4947),
    line: Color(0xFFBEC9C6),
    accent: Color(0xFF006A64),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF2E7D32),
    warning: Color(0xFF8A4F00),
    danger: Color(0xFFBA1A1A),
    onDanger: Color(0xFFFFFFFF),
  ),
];

/// Default dark palette (Dracula).
ThemePalette get defaultDarkPalette => darkPalettes.first;

/// Default light palette (Alucard, Dracula's official light variant).
ThemePalette get defaultLightPalette => lightPalettes.first;

/// Looks up a palette by [id] for [brightness], falling back to the default
/// for unknown or missing ids (e.g. a palette removed in a later release).
ThemePalette paletteById(String? id, Brightness brightness) {
  final list = brightness == Brightness.dark ? darkPalettes : lightPalettes;
  return list.firstWhere((p) => p.id == id, orElse: () => list.first);
}
