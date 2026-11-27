import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../ui/palettes.dart';
import '../ui/theme_extensions.dart';
import '../ui/tokens.dart';

/// Builds the app theme from a [ThemePalette] in the "Inset" style: grouped
/// sections on a tinted canvas, flat cards, fields on a solid surface, 50dp
/// rows. Color comes only from the palette; shape and density come from
/// [FitFatTokens].
final class FitFatTheme {
  FitFatTheme._();

  /// Default light theme (Alucard).
  static ThemeData get light => fromPalette(defaultLightPalette);

  /// Default dark theme (Dracula).
  static ThemeData get dark => fromPalette(defaultDarkPalette);

  static final Map<String, ThemeData> _cache = {};

  /// Theme for [p], cached per palette so switching palettes is instant.
  static ThemeData fromPalette(ThemePalette p) =>
      _cache.putIfAbsent('${p.brightness.name}:${p.id}', () => _build(p));

  /// Maps the 13 palette roles onto a full Material 3 [ColorScheme].
  static ColorScheme schemeFor(ThemePalette p) {
    Color tint(Color c, double amount, Color over) =>
        Color.lerp(over, c, amount)!;
    return ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      primaryContainer: tint(p.accent, 0.22, p.surface),
      onPrimaryContainer: p.fg,
      secondary: p.accent,
      onSecondary: p.onAccent,
      secondaryContainer: tint(p.accent, 0.18, p.surface),
      onSecondaryContainer: p.fg,
      tertiary: p.warning,
      onTertiary: p.brightness == Brightness.dark ? p.bg : Colors.white,
      tertiaryContainer: tint(p.warning, 0.18, p.surface),
      onTertiaryContainer: p.fg,
      error: p.danger,
      onError: p.onDanger,
      errorContainer: tint(p.danger, 0.18, p.surface),
      onErrorContainer: p.fg,
      surface: p.bg,
      onSurface: p.fg,
      onSurfaceVariant: p.muted,
      surfaceDim: p.bg,
      surfaceBright: p.raise,
      surfaceContainerLowest: p.bg,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.raise,
      surfaceContainerHighest: p.surface2,
      outline: tint(p.muted, 0.6, p.line),
      outlineVariant: p.line,
      inverseSurface: p.fg,
      onInverseSurface: p.bg,
      inversePrimary: p.accent,
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: Colors.transparent,
    );
  }

  static ThemeData _build(ThemePalette p) {
    final scheme = schemeFor(p);
    final brightness = p.brightness;
    final radius = BorderRadius.circular(FitFatTokens.radiusM);
    final radiusL = BorderRadius.circular(FitFatTokens.radiusL);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      dividerColor: p.line,
      extensions: [FitFatColors.fromPalette(p)],
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        elevation: 0,
        color: p.surface,
        margin: const EdgeInsets.all(FitFatTokens.spaceXs),
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: p.line),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      // Inset: fields sit on a solid surface with no border; focus draws the
      // accent outline.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: p.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: p.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: p.danger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FitFatTokens.spaceL,
          vertical: FitFatTokens.spaceM,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: scheme.secondaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.bg,
        indicatorColor: scheme.secondaryContainer,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.fg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        // Status bar icons match the brightness.
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.raise,
        shape: RoundedRectangleBorder(borderRadius: radiusL),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.raise,
        modalBackgroundColor: p.raise,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FitFatTokens.radiusL),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.raise,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: p.line),
        selectedColor: scheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: FitFatTokens.spaceL,
        ),
        childrenPadding: const EdgeInsets.only(bottom: FitFatTokens.spaceS),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.muted,
        minTileHeight: FitFatTokens.rowHeight,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: p.accent,
        shape: RoundedRectangleBorder(borderRadius: radiusL),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surface2,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.fg,
        contentTextStyle: TextStyle(color: p.bg),
        actionTextColor: p.accent,
      ),
    );
  }
}
