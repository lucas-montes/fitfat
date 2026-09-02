import 'package:flutter/material.dart';

import 'settings_section.dart';

/// Wraps a settings sub-screen body in a Scaffold with a standard AppBar.
///
/// Used for phone (pushed) navigation. On the adaptive [NavigationRail] the
/// same body is rendered without this scaffold (via the sub-screen's
/// `embed` flag) so we don't end up with nested AppBars.
class SettingsSubScreenScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const SettingsSubScreenScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SettingsBody(child: body),
    );
  }
}
