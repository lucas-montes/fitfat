import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/palettes.dart';
import '../../ui/tokens.dart';
import '../providers/appearance.dart';

/// Settings › Appearance palette picker: a toggle between the dark and light
/// palette lists, then a grid of tiny screens drawn in each palette. Tapping
/// a tile applies that palette immediately.
class PalettePicker extends ConsumerStatefulWidget {
  const PalettePicker({super.key});

  @override
  ConsumerState<PalettePicker> createState() => _PalettePickerState();
}

class _PalettePickerState extends ConsumerState<PalettePicker> {
  Brightness? _editing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appearance = ref.watch(appearanceProvider);
    // Start on the palette list for the brightness currently on screen.
    final editing = _editing ?? Theme.of(context).brightness;
    final palettes = editing == Brightness.dark ? darkPalettes : lightPalettes;
    final selected = appearance.forBrightness(editing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FitFatTokens.spaceM,
      children: [
        SegmentedButton<Brightness>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: Brightness.dark,
              label: Text(l10n.settingsDarkPalette),
            ),
            ButtonSegment(
              value: Brightness.light,
              label: Text(l10n.settingsLightPalette),
            ),
          ],
          selected: {editing},
          onSelectionChanged: (s) => setState(() => _editing = s.first),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: FitFatTokens.spaceM,
          crossAxisSpacing: FitFatTokens.spaceM,
          childAspectRatio: 1.35,
          children: [
            for (final p in palettes)
              PaletteTile(
                palette: p,
                selected: p.id == selected.id,
                isDefault: identical(p, palettes.first),
                defaultLabel: l10n.settingsPaletteDefault,
                onTap: () =>
                    ref.read(appearanceProvider.notifier).setPalette(p),
              ),
          ],
        ),
      ],
    );
  }
}

/// A miniature screen drawn in [palette]: title bar, a card with two text
/// lines, and accent / success / danger swatches.
class PaletteTile extends StatelessWidget {
  const PaletteTile({
    super.key,
    required this.palette,
    required this.selected,
    required this.onTap,
    this.isDefault = false,
    this.defaultLabel = 'Default',
  });

  final ThemePalette palette;
  final bool selected;
  final bool isDefault;
  final String defaultLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = palette;
    Widget bar(double w, double h, Color c, [double r = 3]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: p.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: FitFatTokens.spaceXs,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: FitFatTokens.motionFast,
                padding: const EdgeInsets.all(FitFatTokens.spaceS),
                decoration: BoxDecoration(
                  color: p.bg,
                  borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
                  border: Border.all(
                    color: selected ? theme.colorScheme.primary : p.line,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, c) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      bar(c.maxWidth * 0.55, 8, p.fg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            bar(c.maxWidth * 0.7, 5, p.muted),
                            bar(
                              c.maxWidth * 0.5,
                              5,
                              p.muted.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        spacing: 4,
                        children: [
                          bar(c.maxWidth * 0.38, 12, p.accent, 6),
                          bar(12, 12, p.success, 6),
                          bar(12, 12, p.danger, 6),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: theme.textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDefault)
                  Text(
                    defaultLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
