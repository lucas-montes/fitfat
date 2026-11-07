import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' show AppDatabase;
import 'package:fitfat/src/notes/repositories/note_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late NoteRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = NoteRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('insert, list (newest first), update and delete a note', () async {
    final first = newNote(title: 'First', body: 'Hello').copyWith(
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    );
    final second = newNote(title: 'Second', body: 'World').copyWith(
      updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
      createdAt: DateTime.fromMillisecondsSinceEpoch(2000),
    );
    await repository.insert(first);
    await repository.insert(second);

    var all = await repository.getAll();
    expect(all.map((n) => n.title), ['Second', 'First']);

    await repository.update(
      second.copyWith(
        body: 'Updated body',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(3000),
      ),
    );
    all = await repository.getAll();
    expect(all.first.body, 'Updated body');

    await repository.delete(first.id);
    all = await repository.getAll();
    expect(all.map((n) => n.title), ['Second']);

    final missing = await repository.getById(first.id);
    expect(missing, isNull);
  });
}
