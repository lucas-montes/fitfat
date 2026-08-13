import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/theme_extensions.dart';
import '../ui/tokens.dart';

final class FitFatTheme {
  FitFatTheme._();

  static ThemeData get light => _build(Brightness.light, FitFatColors.light);

  static ThemeData get dark => _build(Brightness.dark, FitFatColors.dark);

  /// Dark scheme with teal-tinted surfaces (tuned on top of the T07 standard
  /// M3 dark `ThemeData`); cards render on `surfaceContainerLow`.
  static final ColorScheme _darkScheme =
      ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF101415),
        surfaceContainerLowest: const Color(0xFF0B0F10),
        surfaceContainerLow: const Color(0xFF181D1E),
        surfaceContainer: const Color(0xFF1D2324),
        surfaceContainerHigh: const Color(0xFF282F30),
        surfaceContainerHighest: const Color(0xFF333B3C),
      );

  static ThemeData _build(Brightness brightness, FitFatColors statusColors) {
    final scheme = brightness == Brightness.dark
        ? _darkScheme
        : ColorScheme.fromSeed(seedColor: Colors.teal);
    final radius = BorderRadius.circular(FitFatTokens.radiusM);
    final radiusL = BorderRadius.circular(FitFatTokens.radiusL);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      extensions: [statusColors],
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
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
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
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
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FitFatTokens.spaceL,
          vertical: FitFatTokens.spaceM,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        // Status bar icons match the brightness: dark icons on the light
        // surface, light icons on the teal-tinted dark surface (T10).
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: radiusL),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(FitFatTokens.spaceL),
        shape: RoundedRectangleBorder(borderRadius: radius),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: FitFatTokens.spaceL,
        ),
        childrenPadding: const EdgeInsets.only(bottom: FitFatTokens.spaceS),
      ),
      listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: radiusL),
      ),
    );
  }
}
