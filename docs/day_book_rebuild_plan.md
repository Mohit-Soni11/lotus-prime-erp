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

The module does **not** meet the completion condition yet. The existing stock
history and closure schema need the migrations and tests above before its metal
and day-close figures can be certified.

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
- Money register supports source/reference search and direction/mode filters.
  Linked sales receipts open original archived PDF bytes when present.
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

### Remaining blockers for the stated completion condition

- Verified opening inventory baseline and item-wise closing reconciliation.
  Historical stock movement purity needs source-document verification before
  a legacy row can be certified.
- Girvi partial handovers and disputed legacy item values need source-level
  custody events and historical verification; current item dates come from
  loan-level delivery or recovery disposition.
- Due settlements and refund payments need their own document event projections.
  Historical outstanding balances and an all-source chronological register
  (with audit history) remain pending.
- Settlement-aware bank position, including cleared balance and value dates.
- Atomic close snapshot covering bank, owned metal, custody, physical count,
  variance decision, source watermark, and audit events. The current source
  guards are a safety layer, not a substitute for that snapshot and audit.
- Historical upgrade/backups and end-to-end reconciliation tests for every
  required posting path. Current focused tests do not certify these gates.
