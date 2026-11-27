import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';

/// The standard form screen: close on the left, a small filled Save button
/// in the top right, the fields in a centered column, and (in edit mode) a
/// danger row at the very bottom that says what else is removed.
///
/// ```dart
/// FormScaffold(
///   title: 'Edit ingredient',
///   canSave: _dirty,
///   saving: _saving,
///   onSave: _save,
///   delete: isEdit
///       ? FormDeleteAction(
///           label: 'Delete ingredient',
///           consequence: 'Also removes 3 prices and 2 photos',
///           onDelete: _delete,
///         )
///       : null,
///   children: [...fields],
/// )
/// ```
class FormScaffold extends StatelessWidget {
  const FormScaffold({
    super.key,
    required this.title,
    required this.onSave,
    required this.children,
    this.canSave = true,
    this.saving = false,
    this.saveLabel,
    this.delete,
    this.footer,
    this.formKey,
    this.leading,
    this.titleWidget,
    this.pinned,
    this.actions = const [],
  });

  final String title;

  /// The form fields, top to bottom.
  final List<Widget> children;

  /// Called when Save is tapped. The button is disabled while [saving] or
  /// when [canSave] is false (e.g. nothing changed yet).
  final VoidCallback onSave;
  final bool canSave;
  final bool saving;

  /// Overrides the "Save" label (e.g. "Add").
  final String? saveLabel;

  /// Shown last, in edit mode only.
  final FormDeleteAction? delete;

  /// Small muted line under the delete row (e.g. "Added 12 Mar 2026").
  final String? footer;

  /// Wraps the fields in a [Form] when set.
  final GlobalKey<FormState>? formKey;

  /// Defaults to a close (×) button.
  final Widget? leading;

  /// Replaces the plain [title] text (e.g. a tappable date).
  final Widget? titleWidget;

  /// Stays on top while the fields scroll (e.g. live totals).
  final Widget? pinned;

  /// Extra app-bar actions before Save (e.g. a ⋮ menu).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final enabled = canSave && !saving;

    Widget body = ListView(
      padding: const EdgeInsets.fromLTRB(
        FitFatTokens.spaceL,
        FitFatTokens.spaceS,
        FitFatTokens.spaceL,
        FitFatTokens.spaceXxl,
      ),
      children: [
        ...children,
        if (delete != null) ...[
          const SizedBox(height: FitFatTokens.spaceXl),
          DangerRow(action: delete!),
        ],
        if (footer != null) ...[
          const SizedBox(height: FitFatTokens.spaceM),
          Text(
            footer!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    if (formKey != null) body = Form(key: formKey, child: body);

    return Scaffold(
      appBar: AppBar(
        leading: leading ?? const CloseButton(),
        title: titleWidget ?? Text(title),
        actions: [
          ...actions,
          Padding(
            padding: const EdgeInsets.only(right: FitFatTokens.spaceM),
            child: FilledButton(
              onPressed: enabled ? onSave : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: FitFatTokens.spaceL,
                ),
                visualDensity: VisualDensity.compact,
              ),
              child: saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(saveLabel ?? l10n.commonSave),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FitFatTokens.kContentMaxWidth,
          ),
          child: pinned == null
              ? body
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        FitFatTokens.spaceL,
                        FitFatTokens.spaceS,
                        FitFatTokens.spaceL,
                        FitFatTokens.spaceXs,
                      ),
                      child: pinned,
                    ),
                    Expanded(child: body),
                  ],
                ),
        ),
      ),
    );
  }
}

/// What the bottom danger row deletes, and what goes with it.
@immutable
class FormDeleteAction {
  const FormDeleteAction({
    required this.label,
    required this.onDelete,
    this.consequence,
  });

  /// e.g. "Delete ingredient".
  final String label;

  /// e.g. "Also removes 3 prices and 2 photos". Omit when nothing else goes.
  final String? consequence;
  final VoidCallback onDelete;
}

/// A full-width card row in the danger color: trash icon, label, and the
/// consequence underneath. Used at the bottom of edit forms and detail
/// screens.
class DangerRow extends StatelessWidget {
  const DangerRow({super.key, required this.action});

  final FormDeleteAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = theme.colorScheme.error;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(Icons.delete_outline, color: danger),
        title: Text(action.label, style: TextStyle(color: danger)),
        subtitle: action.consequence == null ? null : Text(action.consequence!),
        onTap: action.onDelete,
      ),
    );
  }
}
