import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/food.dart';
import '../theme_extensions.dart';
import '../tokens.dart';

/// The five nutrients the app shows as one bar, always in this order:
/// protein · carbs · fat · fiber · sodium (grams).
@immutable
final class MacroValues {
  const MacroValues({
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sodium = 0,
  });

  factory MacroValues.of(Nutrition n) => MacroValues(
    protein: n.protein,
    carbs: n.carbs,
    fat: n.fat,
    fiber: n.fiber,
    sodium: n.sodium,
  );

  static const zero = MacroValues();

  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;

  List<double> get values => [protein, carbs, fat, fiber, sodium];

  MacroValues operator +(MacroValues o) => MacroValues(
    protein: protein + o.protein,
    carbs: carbs + o.carbs,
    fat: fat + o.fat,
    fiber: fiber + o.fiber,
    sodium: sodium + o.sodium,
  );

  MacroValues scale(double f) => MacroValues(
    protein: protein * f,
    carbs: carbs * f,
    fat: fat * f,
    fiber: fiber * f,
    sodium: sodium * f,
  );
}

/// Formats one bar value: whole grams, sodium with one decimal.
String formatMacro(int index, double v) {
  if (index == 4) {
    final r = (v * 10).round() / 10;
    return r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(1);
  }
  return v.round().toString();
}

/// Short labels in bar order, for the one header that names them.
List<String> macroLabels(AppLocalizations l10n) => [
  l10n.macroProtein,
  l10n.macroCarbs,
  l10n.macroFat,
  l10n.macroFiber,
  l10n.macroSodium,
];

/// Bar colors in bar order, blended over the surface so the numbers on top
/// read in the normal text color in both themes.
final class MacroColors {
  MacroColors._(this.base, this.fill);

  factory MacroColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = theme.extension<FitFatColors>();
    final base = [
      scheme.primary,
      _carbs,
      status?.warning ?? scheme.tertiary,
      status?.success ?? scheme.secondary,
      scheme.onSurfaceVariant,
    ];
    return MacroColors._(base, [
      for (final c in base) Color.lerp(scheme.surface, c, 0.58)!,
    ]);
  }

  static const _carbs = Color(0xFF5E9FE0);

  /// Full-strength colors, for small dots next to labels.
  final List<Color> base;

  /// Segment fills.
  final List<Color> fill;
}

/// Calories each nutrient brings per gram, which sizes the segments. Fiber
/// counts 2 kcal/g; sodium none (it only gets the minimum width).
const _kcalPerGram = [4.0, 4.0, 9.0, 2.0, 0.0];

/// One bar with the macro numbers inside, sized by the calories each brings.
/// Every segment keeps a minimum width so its number stays readable.
class MacroBar extends StatelessWidget {
  const MacroBar(this.values, {super.key, this.height = 18});

  final MacroValues values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = MacroColors.of(context);
    final theme = Theme.of(context);
    final small = height < 16;
    final style = theme.textTheme.labelSmall?.copyWith(
      fontSize: small ? 10 : 11,
      height: 1,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final v = values.values;
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 2.0;
        final widths = segmentWidths(
          [for (var i = 0; i < 5; i++) v[i] * _kcalPerGram[i]],
          box.maxWidth - gap * 4,
          minWidth: small ? 20 : 24,
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(FitFatTokens.radiusS / 1.6),
          child: SizedBox(
            height: height,
            child: Row(
              spacing: gap,
              children: [
                for (var i = 0; i < 5; i++)
                  Container(
                    width: widths[i],
                    color: colors.fill[i],
                    alignment: Alignment.center,
                    child: Text(
                      formatMacro(i, v[i]),
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Splits [total] in proportion to [weights], giving every part at least
/// [minWidth]. Parts below the minimum are pinned to it and the rest is
/// shared among the others.
@visibleForTesting
List<double> segmentWidths(
  List<double> weights,
  double total, {
  required double minWidth,
}) {
  final n = weights.length;
  if (total <= minWidth * n) return List.filled(n, total / n);
  final pinned = List.filled(n, false);
  while (true) {
    final free = [
      for (var i = 0; i < n; i++)
        if (!pinned[i]) i,
    ];
    final room = total - minWidth * (n - free.length);
    final sum = free.fold(0.0, (a, i) => a + weights[i]);
    var changed = false;
    final out = List<double>.filled(n, minWidth);
    for (final i in free) {
      out[i] = sum <= 0 ? room / free.length : room * weights[i] / sum;
      if (out[i] < minWidth) {
        pinned[i] = true;
        changed = true;
      }
    }
    if (!changed) return out;
  }
}

/// Labeled columns for a header: a colored dot and short name over each
/// value, in bar order. [values] are already formatted.
class MacroColumns extends StatelessWidget {
  const MacroColumns({super.key, required this.labels, required this.values});

  final List<String> labels;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = MacroColors.of(context);
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 3,
                    children: [
                      if (i < colors.base.length)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: colors.base[i],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    values[i],
                    maxLines: 1,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
