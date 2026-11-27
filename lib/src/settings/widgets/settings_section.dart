import 'package:material_ui/material_ui.dart';

import '../../ui/tokens.dart';
import '../../ui/widgets/section_header.dart';

/// Centers and caps [child] to [FitFatTokens.kContentMaxWidth] so settings
/// screens share the same large-screen layout as the dashboard and exercise
/// lists.
class SettingsBody extends StatelessWidget {
  final Widget child;

  const SettingsBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: FitFatTokens.kContentMaxWidth),
        child: child,
      ),
    );
  }
}

/// A Material 3 settings group: a small header label followed by a spaced
/// list of controls. Children are separated by whitespace (no divider lines),
/// which keeps dense settings screens readable without visual clutter.
class SettingsSection extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <Widget>[];
    if (title != null) {
      items.add(SectionHeader(title!));
    }
    if (subtitle != null) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: FitFatTokens.spaceS),
          child: Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    items.addAll(children);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FitFatTokens.spaceS,
      children: items,
    );
  }
}

/// A consistent settings row: optional leading icon, title, subtitle and a
/// trailing control. Replaces ad-hoc [ListTile] usage and the
/// `contentPadding: EdgeInsets.zero` alignment hack used across settings.
class SettingsTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SettingsTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: leading,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
      minLeadingWidth: FitFatTokens.spaceL,
    );
  }
}

/// An Inset group: optional small-caps title, then one card holding the rows
/// with inset dividers between them.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      indent: FitFatTokens.spaceL + 30 + FitFatTokens.spaceM,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          SectionHeader(
            title!,
            padding: const EdgeInsets.fromLTRB(
              FitFatTokens.spaceXs,
              FitFatTokens.spaceL,
              FitFatTokens.spaceXs,
              FitFatTokens.spaceS,
            ),
          ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) divider,
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A settings row: tinted icon, title (and optional subtitle), the current
/// value on the right, then a chevron or an inline control.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.control,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Current value, shown muted on the right (e.g. "2,400 kcal").
  final String? value;

  /// Inline control (switch, segmented button) instead of the chevron.
  final Widget? control;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = danger ? scheme.error : scheme.primary;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: FitFatTokens.rowHeight + 4,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FitFatTokens.spaceL,
            vertical: FitFatTokens.spaceS,
          ),
          child: Row(
            spacing: FitFatTokens.spaceM,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
                ),
                child: Icon(icon, size: 18, color: tint),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: danger ? scheme.error : null,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (value != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: Text(
                    value!,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (control != null)
                control!
              else if (onTap != null)
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small sheet listing the choices for one setting; returns the picked
/// value (null when dismissed). Used by "grouped rows + sheets" pages.
Future<T?> showSettingsChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FitFatTokens.spaceXl,
              0,
              FitFatTokens.spaceXl,
              FitFatTokens.spaceS,
            ),
            child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
          ),
          RadioGroup<T>(
            groupValue: selected,
            onChanged: (v) => Navigator.of(ctx).pop(v),
            child: Column(
              children: [
                for (final (value, label) in options)
                  RadioListTile<T>(value: value, title: Text(label)),
              ],
            ),
          ),
          const SizedBox(height: FitFatTokens.spaceS),
        ],
      ),
    ),
  );
}
