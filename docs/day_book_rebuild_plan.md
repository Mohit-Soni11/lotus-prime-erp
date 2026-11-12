# Day Book rebuild: source contracts and acceptance gates

## Scope

Day Book is a read model over posted source documents, with a separate audited
closing workflow. It never creates a second sale, receipt, expense, stock move,
or Girvi posting. Cash, bank, owned stock, and customer custody remain separate.

## Current source map

| Register | Source of truth | Rule |
| --- | --- | --- |
| Counter cash | `cash_transactions` where `payment_mode = CASH` | Exclude voids and noncash shadow rows. |
| Bank | `bank_transactions` plus `bank_accounts` opening | Keep mode, account, cheque status, and value date. |
| Invoice turnover and tax | Finalized `bills` and `bill_items` | Use stored taxable, CGST, SGST, IGST, collection, and due values. |
| Due receipts | Cash/bank receipt ledgers linked to bill | Collection only; never new turnover. |
| Operational expenses | Posted expense source and linked bank debit | Purchase, Girvi disbursement, refund, drawing, and contra are distinct. |
| Owned metal | `stock_movements` and item/unit source snapshots | Reconcile quantity, gross, net, and fine by metal, purity, item. |
| Girvi custody | `girvi_loans`, `girvi_loan_items`, release/recovery events | Never add to owned inventory. |
| Archived documents | Source module's saved document locator | Open original bytes when available. |

## Required work before approval

1. Define immutable canonical source references and a deterministic mapping of
   every posting category to business event, ledger account, and payment mode.
   Preserve legacy references through an explicit migration map.
2. Replace bill-derived metal estimates with a stock movement read model.
   Stock movements currently lack an immutable purity snapshot, so add it with
   an additive migration and update each source writer. Validate an authorized
   opening stock baseline before historical metal closing is displayed as
   verified. Do not backfill unknown purity or quantity as if it were observed.
3. Build invoice, collection, expense, outstanding, and chronological register
   projections from source records. Match split payments by immutable source
   reference and exclude advance application and old-dues collection from new
   turnover. Preserve original PDF locators.
4. Extend day closing to a database transaction containing actor identity,
   physical count, variance decision, cash and bank positions, owned-stock and
   custody snapshots, source watermark/hash, and audit event. Close only after
   reconciliation. Protect finalized invoices and stock sources as well as
   cash/bank rows from silent closed-day changes.
5. Ship an additive, versioned migration with a verified pre-upgrade backup and
   rollback path. Test upgrade from supported historical schema snapshots.
6. Verify split payments, returns, exchanges, Girvi creation/release, multiple
   metals and purities, bank contra, out-of-order entry, void/reversal, PDF
   archive lookup, and day-close replay in end-to-end tests.

## Acceptance invariants

- Closing cash = opening cash + posted cash receipts - posted cash payments.
- Closing bank = opening bank + posted credits - posted debits, with uncleared
  cheques identified separately from cleared balance.
- External money in/out excludes balanced internal transfers; transfers still
  affect their respective cash or bank position.
- New invoice turnover comes from final invoices once. Due receipts and advance
  adjustments change receivables/liabilities, not turnover.
- Owned stock closing = verified opening + owned inward - owned outward by
  metal, purity, item, pieces, gross, net, and fine weight.
- Girvi collateral has its own custody equation and cannot alter owned stock.
- A closed day has a persistent, attributable snapshot and refuses silent
  mutation of any source used to calculate it.
- A missing source, ambiguous historical value, or failed query is visible as
  an error or reconciliation exception, never a fabricated zero.

## Current release status

The module does **not** meet the completion condition yet. Schema v77 now
persists close evidence and protects earlier source dates after a later close,
but the unverified historical stock baseline, legacy source values, and
remaining reconciliation flows prevent certified metal and day-close figures.

### Latest integrity and UI pass

- Schema v77 adds append-only, actor-attributed physical owned-metal counts.
  The closing dialog requires item/purity-wise pieces and gross/net/fine
  weights, rejects unknown purity and mismatches, and marks a count stale when
  underlying inventory changes. Closing rechecks the count against the owned
  stock ledger inside the database transaction and saves its evidence in the
  day-close snapshot and export. No physical result is assumed for the shop.
- Day Book now refreshes the selected date when registered source tables change,
  including an open historical date. Source read and watcher failures show an
  error instead of leaving a fabricated zero balance on screen.
- Schema v76 rebuilds the day-lock triggers on upgrade. Once any later day has
  closed, cash, bank, invoice issue snapshots, stock movements, and the other
  guarded source records cannot be backdated into an earlier day.
- The Day Book closing action requires a saved daily opening verification and
  rechecks that opening against posted cash and bank activity in its closing
  transaction. Owned metal remains unverified without a physical count.
- Issue-time due is shown only when an invoice issue snapshot exists. Legacy
  invoices with an unknown issue-time due show an unavailable value. Personal
  owner drawings appear in the Expense Entry list; cancelled purchase vouchers
  no longer count as purchases.
- Historical day locks without a saved closing snapshot export as legacy locks
  with missing physical evidence clearly identified. They are not presented as
  open days, and a physical count or hash is never invented.
- The retired 2,497-line Day Book screen implementation and its obsolete layout
  test were removed. Current UI uses the modular overview, movement, position,
  source, receipts, and stock batch panels.

### Implemented in the current rebuild pass

- Day reads now use one database snapshot and propagate source query errors.
- Cash and bank postings drive the money position, with transfer exclusion,
  account and payment mode breakdown, cheque exposure, and reconciliation state.
- Outgoing postings are classified into operations, purchases, Girvi loans,
  refunds, owner drawings, tax remittances, financing, and other payments.
- GST uses saved tax components including IGST. Incomplete finalized tax data
  blocks the projection instead of deriving a percentage.
- Owned stock daily movements read `stock_movements`; Girvi custody now derives
  opening, receipt, actual handover/recovery, and closing from loan items (or
  clearly marked legacy loan totals), with pieces and gross/net/fine weights.
  Metal opening and closing show **Unverified** until a
  historical baseline and immutable purity snapshot are available.
- The chronological transaction timeline combines source documents, posted
  payments, owned-metal movements, business activities, and expense entries.
  It filters by source, event type, and payment mode without adding event values
  into another total. Linked sales receipts open original archived PDF bytes
  when present.
- Day Book UI panels now consume live summary records only. Design sample
  records live under `test/support` and are absent from the release build.
- Daily source-document summary now separates regular/GST invoices, order
  advances, Girvi tickets, purchase vouchers, and returns. Split sale receipts
  enrich invoice collection; old due receipts never add new turnover. Unknown
  historical collection/outstanding values display as unavailable.
- Cash close rechecks the current posted balance inside its database transaction,
  records the actor, and requires an active owner or manager profile. Historical
  preference locks migrate using calculated cash closing, never a literal zero.
- The Day Book close action is disabled until owned metal opening/closing can be
  verified; the lower-level existing finance lock remains cash/bank only.
- App database upgrades now create an SQLite online backup before migration,
  verify integrity and schema version, and retain a restorable file. A WAL
  database and corrupt-source failure are covered by tests.
- Schema v71 adds an immutable-at-insert purity snapshot to stock movements.
  Historical rows remain unknown; mixed-purity lots do not receive an inferred
  grade. Upgrade and mixed-purity tests cover these rules.
- Closed-day database guards protect invoices, purchase/return vouchers and
  their lines, stock movements, Girvi collateral, and opening balances. Later
  due settlement and documented return status changes remain possible; the
  original invoice turnover stays on its issue date after a return.
- New booking advances post cash, UPI, and card receipts atomically with the
  source receipt. Old metal credit remains in the purchase/booking source and
  does not become Money In. Booking edits preserve receipt IDs and dates;
  changing an existing receipt requires a separate reversal or receipt flow.
- Girvi bank principal now posts as Girvi return. The Day Book projection also
  reclassifies old Girvi bank rows that were saved as Due Collection, without
  rewriting their historical ledger records. Customer change and refund-payable
  receipts are separated from operating income and expense classifications.
- Purchase bank/UPI/card payouts now require an active bank account. A failed
  lookup rolls back the voucher and stock writes instead of saving a noncash
  shadow transaction that Day Book could not include.
- Schema v75 stores an immutable day-close evidence snapshot with physical
  denomination count, cash/bank and account positions, owned gold/silver,
  Girvi custody, and a hash of source records. The snapshot is inserted in the
  same database transaction as the close lock. Existing v74 closures remain
  locked but are explicitly missing audit snapshots; evidence is not invented.
- New and edited sales invoices persist an issue-time financial snapshot in
  the same transaction as the bill. Day Book uses it for original sales value,
  saved tax, and new due even after a later due receipt/discount changes the
  mutable bill balance. Legacy invoices without this snapshot still need
  source-document reconciliation before their historical issue value is
  certified.

### Remaining blockers for the stated completion condition

#### Read-only live database audit (12 November 2026)

The SQLite integrity check passed and the database is at schema v77. The
aggregate audit found 3 bills and 0 bill issue snapshots, 0 configured bank
accounts, 5 stock items and units, 10 stock movements, 2 Girvi loans, and 0
physical metal verifications or day closes. No live rows were changed.

Legacy invoice amounts and tax are now visibly marked unverified in the Day
Book and export. A certified day close refuses a date containing invoices
without issue evidence. Revised invoices update their issue snapshot through
the existing sale edit flow. The archived invoice metadata does not contain
enough original financial fields to rebuild these snapshots automatically. Reconcile against
the original issued documents before treating historical sales and GST as
certified. The bank account and physical metal count require real shop inputs.

Bank Book balance reads now surface database failures instead of showing a
fabricated zero or empty transaction history.

- Actual shop physical inventory count and correction of any missing legacy
  purity or stock variance. The count workflow exists, but no physical count
  has been supplied, so the current shop position remains unverified.
- Girvi partial handovers and disputed legacy item values need source-level
  custody events and historical verification; current item dates come from
  loan-level delivery or recovery disposition.
- Due settlements and refund payments need their own immutable document event
  projections. The read-only timeline is present, but source edit audit history
  and historical outstanding balances are not yet certified.
- Legacy invoice issue-time amounts and tax require reconciliation against
  archived issued PDFs or original source documents where no issue snapshot
  exists. The migration never invents an original invoice amount.
- Settlement-aware bank position, including cleared balance and value dates.
- The close snapshot records bank, owned metal, custody, and physical cash and
  owned-metal counts when verified. Historical days without physical counts
  are not retroactively certified. Partial Girvi handover and formal variance
  approvals still require dedicated source events.
- Historical upgrade/backups and end-to-end reconciliation tests for every
  required posting path. Current focused tests do not certify these gates.
