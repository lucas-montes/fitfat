# Plan: Money group redesign — Money tab, history, statement (Phase MG)

**Status:** completed (2026-11-27) — T01–T06 shipped on branch ui/design-system. Deviation: in one account's statement a transfer counts in the day net (it changes that account's balance); only the all-accounts history leaves transfers out.

## Change Summary

Rebuild the Money tab on the design system (proposals:
https://claude.ai/artifact/SjcVZMs4L9oVqCTm9sSTmm, rounds 4, 14–15). Accounts and
transactions come from the server and are **read-only** on the phone; the phone
only adds receipts (an upload queue, unchanged, still under Money).

1. **Money tab** — net worth, accounts grouped by type as horizontal card rows,
   the last days of transactions with All.
2. **Transaction history** — compact one-line rows in day cards; one Filters
   button (sheet: when, account, category, type, live count) and the active
   filters as removable chips; search.
3. **Account statement** — balance, this month in/out, balance chart, month
   chips + Range, compact rows signed by direction.
4. **Transaction sheet** — tap a row: amount, original currency and rate,
   account, category, date, note, button to the account's statement.

## Decisions

| # | Question | Status |
|---|---|---|
| D1 | Money tab | **decided: round 15 C** — net worth (+ change this month); groups Everyday (bank, card, cash) and Savings & investment (savings, investment, securities), each a horizontal row of account cards with the group total; Recent day cards + All; receipts icon with the waiting count in the top bar |
| D2 | History rows | **decided: round 14 B** — compact: category color dot, title (note, else category), account under it, signed amount (original currency under it when foreign) |
| D3 | History filters | **decided: round 15 B** — "Filters · N" button opening a sheet (When: All / months / Range; Account; Category; Type: All / In / Out / Transfers; "Show N transactions"); the set filters show as removable chips on the same line |
| D4 | Transfers in the history | **decided: round 15 B** — two rows, one per account: "Transfer to Savings −300.00" on BBVA, "Transfer from BBVA +300.00" on Savings; transfers never count in a day's net |
| D5 | Statement | **decided: round 14 B + month chips** — header (type, balance, month in/out), balance line chart (last 3 months), month chips + Range, compact rows; transfers signed by direction |
| D6 | Tapping a transaction | **decided: round 14 A** — small read-only sheet |

## Data

No schema change. Balances are derived as today (`accountBalance`). Drafts are
excluded everywhere. A transaction's title is its note, else its category
(there is no merchant field).

## Tasks

- [x] T01 — `money_data.dart`: history entries (transfers split into two signed
      entries), day grouping with net (transfers excluded), filters, account
      groups, daily balance series.
- [x] T02 — Money tab (`budget_overview_screen.dart`).
- [x] T03 — History with the filter sheet (`transaction_list_screen.dart`).
- [x] T04 — Transaction sheet.
- [x] T05 — Statement (`account_detail_screen.dart`).
- [x] T06 — Tests, l10n, docs.

## Acceptance

- Analyzer clean, all tests pass.
- Transfers show as two signed rows in the history and one signed row in a
  statement; day nets ignore transfers.
- All filters fit on one line; the sheet shows a live count.
