import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

final class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAppBar)),
      body: Center(child: Text(l10n.settingsBody)),
    );
  }
}
