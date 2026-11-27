import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';

/// Builds the scrolling content of an [showAppSheet] for the current
/// search [query]. Attach [controller] to the list so dragging works.
typedef AppSheetBuilder =
    Widget Function(
      BuildContext context,
      String query,
      ScrollController controller,
    );

/// The app's standard picker sheet: near full height, with the search field
/// (and optional filter chips) pinned on top and the results below.
///
/// Pop with `Navigator.of(context).pop(value)` from inside [builder] to
/// return a value.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required AppSheetBuilder builder,
  String? searchHint,
  bool search = true,
  Widget? filters,
  String? title,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (ctx, controller) => _AppSheetBody(
        builder: builder,
        controller: controller,
        searchHint: searchHint,
        search: search,
        filters: filters,
        title: title,
      ),
    ),
  );
}

class _AppSheetBody extends StatefulWidget {
  const _AppSheetBody({
    required this.builder,
    required this.controller,
    required this.search,
    this.searchHint,
    this.filters,
    this.title,
  });

  final AppSheetBuilder builder;
  final ScrollController controller;
  final bool search;
  final String? searchHint;
  final Widget? filters;
  final String? title;

  @override
  State<_AppSheetBody> createState() => _AppSheetBodyState();
}

class _AppSheetBodyState extends State<_AppSheetBody> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FitFatTokens.spaceL,
            0,
            FitFatTokens.spaceL,
            FitFatTokens.spaceS,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FitFatTokens.spaceS,
            children: [
              if (widget.title != null)
                Text(widget.title!, style: theme.textTheme.titleMedium),
              if (widget.search)
                TextField(
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: widget.searchHint ?? l10n.commonSearch,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ?widget.filters,
            ],
          ),
        ),
        Expanded(child: widget.builder(context, _query, widget.controller)),
      ],
    );
  }
}
