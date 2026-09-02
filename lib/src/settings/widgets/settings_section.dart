import 'package:flutter/material.dart';

import '../../ui/tokens.dart';

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
      items.add(
        Padding(
          padding: const EdgeInsets.only(
            top: FitFatTokens.spaceM,
            bottom: FitFatTokens.spaceXs,
          ),
          child: Text(
            title!,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
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
