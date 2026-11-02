# Cash Book modernization plan

## Product rules

- The Cash Book shows physical cash receipts and payments only. UPI, card, cheque and bank transfers belong to their respective account books.
- Sales, collections, purchase payments, girvi movements and expenses are posted by their source workflows. Cash Book's manual action records extra cash income only.
- A posted receipt or payment remains traceable to its source. Corrections must retain the original record and a reason.
- Opening, movements, closing, running balances and exports must agree for the same period and the same active transactions.

## Implemented in the current working tree

The finance navigation and screen are labeled **Account Book**. The current view and its export remain explicitly scoped to cash; bank movements will require a separate, reconciled integration.

1. Cash-only source posting, carried opening balance, active-transaction summaries and database-backed day close from the finance ledger correction.
2. A Cash Ledger Date field matching the POS Promise Date interaction selects any historical day. Separate Monthly and Yearly cards list only periods with recorded cash transactions. Each period shows its opening balance, cash in, cash out, closing balance, net movement and transaction count. Aggregation uses local calendar boundaries and bounded SQL batches.
3. Manual extra cash income with restricted categories, mandatory reason and repository-level rejection of manual sales or expenses. Existing source-generated expenses remain in the ledger.
4. Per-transaction running balance, negative balance highlighting, reference/amount search and deterministic ordering for transactions at the same time.
5. Complete-period CSV export and print/PDF with opening, every movement, running balances and closing. CSV text is escaped and formula-prefixed fields are neutralized.
6. The calendar keeps the selected day's balance summary and daily export. The ledger below it always shows the selected month, including days other than the selected date, with monthly opening, cash in, cash out and closing. All/Income/Expense filter the monthly rows; the unused Cash Book search field was removed. The header title and summary-view back action return to today's Cash Book home.

## Next architecture milestones

### 1. Voucher and general-ledger integration

Define cash account(s), counterparty account, voucher ID and debit/credit lines in a shared finance posting service. Each source workflow should post its business record, cash movement and balanced voucher in one database transaction. Add explicit cash-to-bank transfer (contra) with both sides linked by one voucher. Migrate existing rows only after a reconciliation report identifies unmatched and ambiguous records. Acceptance: each active cash movement maps to a balanced voucher; cash account balance equals Cash Book closing; a failed post leaves no partial records.

### 2. Operator audit and approval

Persist actor, timestamp, source, reason and revision events for manual income, void, day close and reopening. Reuse the project's authentication/role model instead of inventing a parallel user table. Require appropriate permission for cash correction and day reopening. Acceptance: an auditor can reconstruct who changed what and when without overwriting earlier facts.

### 3. Cash register sessions and reconciliation

Introduce cash drawer/location and cashier session identities, configurable opening count, denomination count, expected vs physical closing, explicit shortage/excess posting and manager approval threshold. Keep Day Book's existing database lock as the enforcement boundary. Acceptance: each drawer has an independent opening/closing position and no difference is silently accepted.

### 4. Large-ledger reporting

Move annual and custom-range list search, paging and running-balance windows to indexed SQLite queries. Keep summary aggregates in SQL and export through a bounded/streamed reader. Add source drill-down, negative-cash exception report and report-column filters. Acceptance: annual ledgers remain responsive with large transaction counts, and exported totals equal the unfiltered ledger.

### 5. Monetary precision migration

Move financial amounts from SQLite `REAL`/Dart `double` to integer minor units or an audited decimal type across POS, Cash Book, Bank Book, Day Book and reports. Run a pre-migration reconciliation and verify old/new balances before switching writes. Acceptance: every migrated amount preserves paise exactly and all ledger balances match.

## Release verification

- Focused tests for calendar, monthly/yearly aggregation, responsive period cards, manual posting rules, automatic expenses, running balance, search and report export.
- Full Flutter test suite, static analysis and Windows release build.
- A copy of real business data requires a separate reconciliation audit before claiming historical balances are correct.
