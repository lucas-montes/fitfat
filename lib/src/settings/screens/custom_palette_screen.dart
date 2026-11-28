import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/palettes.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/top_banner.dart';
import '../providers/appearance.dart';
import '../widgets/palette_picker.dart';

/// Edits the custom palette for one brightness: the 16 base16 colors as hex
/// fields, each saying which parts of the app it colors. Changes save and
/// apply as you type (when the custom palette is the one in use).
final class CustomPaletteScreen extends ConsumerWidget {
  const CustomPaletteScreen({super.key, required this.brightness});

  final Brightness brightness;

  Future<void> _paste(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final found = parseBase16(data?.text ?? '');
    if (!context.mounted) return;
    if (found.isEmpty) {
      showTopBanner(context, message: l10n.customPalettePasteNone);
      return;
    }
    await ref
        .read(appearanceProvider.notifier)
        .setCustomColors(brightness, found);
    if (context.mounted) {
      showTopBanner(context, message: l10n.customPalettePasted(found.length));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final appearance = ref.watch(appearanceProvider);
    final colors = appearance.customFor(brightness);
    final palette = appearance.customPalette(brightness);
    final inUse = appearance.forBrightness(brightness).id == customPaletteId;
    final roles = base16Roles(brightness);
    final dark = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          dark ? l10n.customPaletteTitleDark : l10n.customPaletteTitleLight,
        ),
        actions: [
          IconButton(
            tooltip: l10n.customPalettePaste,
            icon: const Icon(Icons.content_paste),
            onPressed: () => _paste(context, ref),
          ),
          IconButton(
            tooltip: l10n.customPaletteReset,
            icon: const Icon(Icons.restart_alt),
            onPressed: () =>
                ref.read(appearanceProvider.notifier).resetCustom(brightness),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        children: [
          Row(
            spacing: FitFatTokens.spaceL,
            children: [
              SizedBox(
                width: 150,
                height: 130,
                child: PaletteTile(
                  palette: palette,
                  selected: inUse,
                  onTap: () =>
                      ref.read(appearanceProvider.notifier).setPalette(palette),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FitFatTokens.spaceS,
                  children: [
                    Text(
                      l10n.customPaletteHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (inUse)
                      Row(
                        spacing: 4,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          Text(l10n.customPaletteInUse),
                        ],
                      )
                    else
                      FilledButton.tonal(
                        onPressed: () => ref
                            .read(appearanceProvider.notifier)
                            .setPalette(palette),
                        child: Text(l10n.customPaletteUse),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FitFatTokens.spaceL),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < 16; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 60),
                  _SlotRow(
                    key: ValueKey('base16-$i'),
                    index: i,
                    color: colors[i],
                    roles: roles[i] ?? const [],
                    onChanged: (c) => ref
                        .read(appearanceProvider.notifier)
                        .setCustomColors(brightness, {i: c}),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _roleName(AppLocalizations l10n, PaletteRole r) => switch (r) {
  PaletteRole.background => l10n.paletteRoleBackground,
  PaletteRole.cards => l10n.paletteRoleCards,
  PaletteRole.chips => l10n.paletteRoleChips,
  PaletteRole.sheets => l10n.paletteRoleSheets,
  PaletteRole.text => l10n.paletteRoleText,
  PaletteRole.secondaryText => l10n.paletteRoleSecondaryText,
  PaletteRole.lines => l10n.paletteRoleLines,
  PaletteRole.accent => l10n.paletteRoleAccent,
  PaletteRole.textOnColor => l10n.paletteRoleTextOnColor,
  PaletteRole.success => l10n.paletteRoleSuccess,
  PaletteRole.warning => l10n.paletteRoleWarning,
  PaletteRole.danger => l10n.paletteRoleDanger,
};

/// One base16 slot: swatch, "base0A", what it colors, and a hex field that
/// applies as soon as it holds six hex digits.
final class _SlotRow extends StatefulWidget {
  const _SlotRow({
    super.key,
    required this.index,
    required this.color,
    required this.roles,
    required this.onChanged,
  });

  final int index;
  final Color color;
  final List<PaletteRole> roles;
  final ValueChanged<Color> onChanged;

  @override
  State<_SlotRow> createState() => _SlotRowState();
}

final class _SlotRowState extends State<_SlotRow> {
  late final _controller = TextEditingController(
    text: colorToHex(widget.color),
  );

  @override
  void didUpdateWidget(_SlotRow old) {
    super.didUpdateWidget(old);
    // Follow pastes and resets, unless the field already says the same.
    final typed = colorFromHex(_controller.text);
    if (old.color != widget.color && typed != widget.color) {
      _controller.text = colorToHex(widget.color);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final name = 'base0${widget.index.toRadixString(16).toUpperCase()}';
    final valid = colorFromHex(_controller.text) != null;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FitFatTokens.spaceM,
        vertical: FitFatTokens.spaceS,
      ),
      child: Row(
        spacing: FitFatTokens.spaceM,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  widget.roles.isEmpty
                      ? l10n.paletteRoleUnused
                      : widget.roles.map((r) => _roleName(l10n, r)).join(', '),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 112,
            child: TextField(
              controller: _controller,
              maxLength: 7,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
              ],
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                prefixText: '#',
                errorText: valid ? null : '',
                errorStyle: const TextStyle(height: 0, fontSize: 0),
              ),
              onChanged: (text) {
                setState(() {});
                final c = colorFromHex(text);
                if (c != null) widget.onChanged(c);
              },
            ),
          ),
        ],
      ),
    );
  }
}
