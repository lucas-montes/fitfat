import 'package:flutter/material.dart';

class FoodEntryCard extends StatelessWidget {
  const FoodEntryCard({
    super.key,
    required this.title,
    required this.body,
    this.onTap,
    this.onDelete,
    this.deleteTooltip,
  });

  final String title;
  final Widget body;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String? deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final content = Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: deleteTooltip ?? 'Delete',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            body,
          ],
        ),
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: content,
    );
  }
}
