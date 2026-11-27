# Money screens — Budget domain

Accounts and transactions come from the sync server and are **read-only** on the
phone (no create, edit or delete). The phone adds only receipts (an upload queue,
`receipt_list_screen.dart`, reached from the receipt icon on the Money tab).
Drafts never reach the screens (`liveTransactionsProvider` filters them out of
`transactionListProvider`). A transaction has a category and an optional note but
no merchant name: a row's title is the note, else the category.

## Files

| File | Purpose |
|------|---------|
| `lib/src/budget/services/money_data.dart` | `MoneyEntry` (a transaction seen from one account, signed), `historyEntries` (a transfer → an out line and an in line), `statementEntries`, `groupMoneyDays` (net excludes transfers unless `countTransfers`), `MoneyFilter` (date, accounts, categories, kinds, query), `AccountGroup`/`accountGroupOf`, `inOut`, `netChangeSince`, `balanceSeries` |
| `lib/src/budget/widgets/money_widgets.dart` | `formatMoneyIn` (locale currency, signed), `categoryColor` (stable per name), `entryTitle`, `MoneyRow` (compact line: dot, title, account · category, signed amount, original currency under it), `MoneyDayCard` (tinted header with the date and net), `showTransactionSheet` |
| `lib/src/budget/screens/budget_overview_screen.dart` | Money tab: net worth (+ change this month), Everyday / Savings & investment / Other as horizontal rows of `AccountCard`s with the group total, the last 3 days with All |
| `lib/src/budget/screens/transaction_list_screen.dart` | History: day cards of `MoneyRow`s; search in the app bar; "Filters · N" opens `showMoneyFilterSheet` (When, Account, Category, Type, live "Show N transactions"); set filters show as removable `InputChip`s on the same line |
| `lib/src/budget/screens/account_detail_screen.dart` | Statement: type · base currency, balance, this month in/out, balance line chart (last 3 months), `DateFilterChips`, day cards of this account's lines (transfers signed by direction, counted in the day net) |

## Rules

- **Transfers**: in the history a transfer is two lines — "Transfer to Savings −300"
  on the source, "Transfer from BBVA +300" on the destination — and never counts in
  a day's net. In a statement it is one line signed for that account and counts.
- Amounts are shown in the base currency (`amountBase`); a foreign transaction also
  shows its original amount, and the sheet shows the rate used
  (base per unit of the original currency).
- Local-first: no spinners or error screens; empty states only.
