import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitfat/src/models/seance_models.dart';
import 'package:fitfat/src/providers/seance_providers.dart';
import 'package:fitfat/src/repositories/in_memory_seance_repository.dart';

void main() {
  test('create and list templates in in-memory repo', () async {
    final container = ProviderContainer(
      overrides: [
        seanceRepositoryProvider.overrideWithValue(InMemorySeanceRepository()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(templateListProvider.notifier);
    final tmpl = SeanceTemplate(id: 't1', name: 'Test Template', exercises: []);
    await notifier.createTemplate(tmpl);
    final list = container.read(templateListProvider);
    expect(list.length, 1);
    expect(list.first.name, 'Test Template');
  });
}
