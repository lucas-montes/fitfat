import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/notes/screens/note_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The editor's body field is raw markdown with a preview toggle (T06): the
/// toolbar inserts markers at the cursor, and the preview renders headings,
/// bold text and lists from that raw text rather than showing them literally.
void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: Scaffold(body: NoteEditorScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'preview renders a heading, bold text and a list item from raw markdown',
    (tester) async {
      await pumpEditor(tester);

      await tester.enterText(
        find.byKey(const ValueKey('notesBodyField')),
        '## Shopping\n\n**Milk** and eggs\n\n- bread\n- butter',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('notesBodyPreviewToggle')));
      await tester.pumpAndSettle();

      // The raw markdown TextFormField is gone; the rendered preview text is
      // showing instead (headings/bold strip their markers, list items keep
      // their own text).
      expect(find.byKey(const ValueKey('notesBodyField')), findsNothing);
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.textContaining('Milk'), findsOneWidget);
      expect(find.textContaining('bread'), findsOneWidget);
      expect(find.textContaining('butter'), findsOneWidget);
    },
  );

  testWidgets('the bold toolbar button wraps the current selection', (
    tester,
  ) async {
    await pumpEditor(tester);

    await tester.enterText(
      find.byKey(const ValueKey('notesBodyField')),
      'hello world',
    );
    await tester.pumpAndSettle();

    final fieldFinder = find.byKey(const ValueKey('notesBodyField'));
    final field = tester.widget<TextFormField>(fieldFinder);
    field.controller!.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 5,
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('notesToolbarBold')));
    await tester.pump();

    expect(field.controller!.text, '**hello** world');
  });

  testWidgets('the heading toolbar button prefixes the current line', (
    tester,
  ) async {
    await pumpEditor(tester);

    await tester.enterText(
      find.byKey(const ValueKey('notesBodyField')),
      'todo',
    );
    await tester.pumpAndSettle();

    final fieldFinder = find.byKey(const ValueKey('notesBodyField'));
    final field = tester.widget<TextFormField>(fieldFinder);
    field.controller!.selection = const TextSelection.collapsed(offset: 4);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('notesToolbarHeading')));
    await tester.pump();

    expect(field.controller!.text, '## todo');
  });

  testWidgets('switching back to edit restores the raw markdown field', (
    tester,
  ) async {
    await pumpEditor(tester);

    await tester.enterText(
      find.byKey(const ValueKey('notesBodyField')),
      '# Title',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notesBodyPreviewToggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notesBodyField')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('notesBodyPreviewToggle')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(
      find.byKey(const ValueKey('notesBodyField')),
    );
    expect(field.controller!.text, '# Title');
  });
}
