import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../settings/providers/settings.dart';

enum CascadeChoice { cancel, deleteOnly, cascade }

Future<CascadeChoice?> showCascadeDeleteDialog(
  BuildContext context, {
  required String title,
  required CascadeDeleteBehavior behavior,
  int linkedTaskCount = 0,
}) async {
  final l10n = AppLocalizations.of(context)!;
  if (behavior == CascadeDeleteBehavior.alwaysCascade) {
    return CascadeChoice.cascade;
  }
  if (behavior == CascadeDeleteBehavior.neverCascade) {
    return CascadeChoice.deleteOnly;
  }
  return showDialog<CascadeChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        linkedTaskCount > 0 ? l10n.cascadeDeleteTitleWithTasks : title,
      ),
      content: Text(
        linkedTaskCount > 0
            ? l10n.cascadeDeleteBodyWithTasks(linkedTaskCount)
            : l10n.cascadeDeleteBody,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(CascadeChoice.cancel),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(CascadeChoice.deleteOnly),
          child: Text(l10n.cascadeDeleteKeepTasks),
        ),
        if (linkedTaskCount > 0)
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(CascadeChoice.cascade),
            child: Text(l10n.cascadeDeleteWithTasks),
          ),
      ],
    ),
  );
}
