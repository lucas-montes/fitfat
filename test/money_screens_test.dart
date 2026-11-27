import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/budget/models/account.dart';
import 'package:fitfat/src/budget/models/transaction.dart';
import 'package:fitfat/src/budget/screens/account_detail_screen.dart';
import 'package:fitfat/src/budget/screens/transaction_list_screen.dart';
import 'package:fitfat/src/budget/services/money_data.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/ui/widgets/date_filter_chips.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction tx(
  String id,
  TransactionType type,
  double amount,
  String account,
  DateTime date, {
  String? to,
  String? category,
  String? note,
  bool draft = false,
}) => Transaction(
  id: id,
  type: type,
  amount: amount,
  currencyCode: 'EUR',
  amountBase: amount,
  rateUsed: 1,
  accountId: account,
  toAccountId: to,
  category: category,
  date: date,
  note: note,
  isDraft: draft,
  createdAt: date,
);

void main() {
  final d1 = DateTime(2026, 11, 24, 10);
  final d2 = DateTime(2026, 11, 25, 10);
  final txns = [
    tx('a', TransactionType.expense, 40, 'bbva', d2, category: 'Groceries'),
    tx('b', TransactionType.income, 2000, 'bbva', d2, category: 'Salary'),
    tx('c', TransactionType.transfer, 300, 'bbva', d1, to: 'sav'),
    tx('d', TransactionType.expense, 10, 'rev', d1, category: 'Shopping'),
    tx('e', TransactionType.expense, 99, 'bbva', d1, draft: true),
  ];

  group('money data', () {
    test('a transfer becomes two signed lines; drafts are dropped', () {
      final e = historyEntries(txns);
      expect(e.map((x) => x.txn.id), ['a', 'b', 'c', 'c', 'd']..sort());
      final out = e.firstWhere((x) => x.txn.id == 'c' && x.accountId == 'bbva');
      final inn = e.firstWhere((x) => x.txn.id == 'c' && x.accountId == 'sav');
      expect(out.signedBase, -300);
      expect(out.isTransferOut, isTrue);
      expect(out.counterpartId, 'sav');
      expect(inn.signedBase, 300);
    });

    test(
      'day nets skip transfers in the history, count them in a statement',
      () {
        final days = groupMoneyDays(historyEntries(txns));
        expect(days.map((d) => d.day), [
          DateTime(2026, 11, 25),
          DateTime(2026, 11, 24),
        ]);
        expect(days.first.net, 1960);
        expect(days.last.net, -10);
        final stmt = groupMoneyDays(
          statementEntries(txns, 'bbva'),
          countTransfers: true,
        );
        expect(stmt.last.net, -300);
        expect(stmt.last.entries.single.signedBase, -300);
      },
    );

    test('filters: account, category, kind, month, search', () {
      final e = historyEntries(txns);
      List<String> ids(MoneyFilter f) => [
        for (final x in e)
          if (f.matches(x)) '${x.txn.id}@${x.accountId}',
      ];
      expect(ids(const MoneyFilter(accounts: {'sav'})), ['c@sav']);
      expect(ids(const MoneyFilter(categories: {'Groceries'})), ['a@bbva']);
      expect(ids(const MoneyFilter(kinds: {MoneyKind.transfer})), [
        'c@bbva',
        'c@sav',
      ]);
      expect(
        ids(MoneyFilter(date: DateFilter(month: DateTime(2026, 10)))),
        isEmpty,
      );
      expect(ids(const MoneyFilter(query: 'shop')), ['d@rev']);
      expect(
        const MoneyFilter(accounts: {'x'}, kinds: {MoneyKind.income}).count,
        2,
      );
    });

    test('balance series ends at the account balance', () {
      final acc = Account(
        id: 'bbva',
        name: 'BBVA',
        type: AccountType.bank,
        openingBalance: 100,
        createdAt: DateTime(2026),
      );
      final s = balanceSeries(
        acc,
        txns,
        from: DateTime(2026, 11, 23),
        to: DateTime(2026, 11, 25),
      );
      expect(s.map((x) => x.balance), [100, -200, 1760]);
    });

    test('account groups', () {
      expect(accountGroupOf(AccountType.credit), AccountGroup.everyday);
      expect(accountGroupOf(AccountType.securities), AccountGroup.savings);
    });
  });

  group('screens', () {
    late db.AppDatabase database;
    ProviderContainer? container;

    setUp(() async {
      database = db.AppDatabase.forTesting(NativeDatabase.memory());
      for (final (id, name, type) in [
        ('bbva', 'BBVA', 'bank'),
        ('sav', 'Savings', 'savings'),
        ('rev', 'Revolut', 'credit'),
      ]) {
        await database
            .into(database.accounts)
            .insert(
              db.AccountsCompanion.insert(
                id: id,
                name: name,
                type: type,
                createdAt: 0,
              ),
            );
      }
      final now = DateTime.now();
      var n = 0;
      for (final t in [
        tx(
          'a',
          TransactionType.expense,
          40,
          'bbva',
          now,
          category: 'Groceries',
          note: 'Mercadona',
        ),
        tx('b', TransactionType.transfer, 300, 'bbva', now, to: 'sav'),
        tx('c', TransactionType.expense, 10, 'rev', now, category: 'Shopping'),
      ]) {
        await database
            .into(database.transactions)
            .insert(
              db.TransactionsCompanion.insert(
                id: t.id,
                type: t.type.name,
                amount: t.amount,
                currencyCode: 'USD',
                amountBase: t.amountBase,
                rateUsed: 1,
                accountId: Value(t.accountId),
                toAccountId: Value(t.toAccountId),
                category: Value(t.category),
                note: Value(t.note),
                date: t.date.millisecondsSinceEpoch,
                createdAt: n++,
              ),
            );
      }
    });

    tearDown(() async {
      container?.dispose();
      container = null;
      await database.close();
    });

    Future<void> pump(WidgetTester tester, Widget home) async {
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(database)],
      );
      container!.read(startupGateProvider.notifier).complete();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container!,
          child: MaterialApp(
            theme: FitFatTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: home,
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('history: a transfer shows out and in; filters narrow it', (
      tester,
    ) async {
      await pump(tester, const TransactionListScreen());
      expect(find.text('Transfer to Savings'), findsOneWidget);
      expect(find.text('Transfer from BBVA'), findsOneWidget);
      expect(find.text('Mercadona'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('moneyFilters')));
      await tester.pumpAndSettle();
      expect(find.text('Show 4 transactions'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Shopping'));
      await tester.pumpAndSettle();
      expect(find.text('Show 1 transaction'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('moneyFilterApply')));
      await tester.pumpAndSettle();

      expect(find.text('Filters · 1'), findsOneWidget);
      expect(find.text('Mercadona'), findsNothing);
      expect(find.text('Shopping'), findsWidgets);
      // The set filter is a removable chip beside the button.
      tester
          .widget<InputChip>(find.widgetWithText(InputChip, 'Shopping'))
          .onDeleted!();
      await tester.pumpAndSettle();
      expect(find.text('Mercadona'), findsOneWidget);
      expect(find.text('Filters'), findsOneWidget);
    });

    testWidgets('statement: transfer out is negative, sheet opens', (
      tester,
    ) async {
      await pump(tester, const AccountDetailScreen(accountId: 'bbva'));
      expect(find.text('Transfer to Savings'), findsOneWidget);
      expect(find.text('Transfer from BBVA'), findsNothing);
      expect(find.text('−\$300.00'), findsOneWidget);
      // Day net counts the transfer in a statement: −40 − 300.
      expect(find.text('−\$340.00'), findsNWidgets(2)); // balance and day net

      await tester.tap(find.text('Mercadona'));
      await tester.pumpAndSettle();
      expect(find.text('Groceries'), findsWidgets);
      expect(find.textContaining('Open'), findsNothing);
    });
  });
}
