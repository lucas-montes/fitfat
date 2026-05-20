import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/seance_providers.dart';

import 'create_seance_screen.dart';

class SeanceLibraryScreen extends ConsumerWidget {
  const SeanceLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templateListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seance Library')),
      body: templates.isEmpty
          ? const Center(child: Text('No templates yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              separatorBuilder: (context, idx) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final t = templates[index];
                return Card(
                  child: ListTile(
                    title: Text(t.name),
                    subtitle: Text('${t.exercises.length} exercise(s)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            // ignore: use_build_context_synchronously
                            await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => CreateSeanceScreen(template: t),
                            ));
                            await ref.read(templateListProvider.notifier).loadTemplates();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () async {
                            final cloned = await ref
                                .read(templateListProvider.notifier)
                                .cloneTemplate(t.id);
                            // immediately navigate to edit the cloned template
                            // ignore: use_build_context_synchronously
                            await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => CreateSeanceScreen(template: cloned),
                            ));
                            await ref.read(templateListProvider.notifier).loadTemplates();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await ref.read(templateListProvider.notifier).deleteTemplate(t.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // ignore: use_build_context_synchronously
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const CreateSeanceScreen(),
          ));
          await ref.read(templateListProvider.notifier).loadTemplates();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
