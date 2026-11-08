# Day Book: source and closing workflow

## Daily money position

1. Opening counter cash is the shop's registered opening cash plus all earlier
   posted, nonvoided `CASH` ledger movements. Opening bank is each account's
   registered opening balance plus its earlier nonvoided bank movements.
2. Cash, UPI, card, bank transfer, and cheque are read from posted finance
   ledgers. An invoice identifies the business activity; its payment posting
   determines whether counter cash or a bank account moved. Unpaid invoices
   create a due, not a money movement.
3. Money In and Money Out use actual cash and bank postings. Internal transfers
   change the two positions but are shown separately from external receipts
   and payments. Closing cash and bank are opening plus posted inflow minus
   posted outflow; the combined balance is their sum.

## Business activity

- A finalized regular or GST invoice creates sales turnover once. Its issue
  snapshot fixes invoice value, tax, and new due for Day Book even when an old
  due is collected later. Cash, UPI, and card collections use their own ledgers.
- Booking advance receipts post cash, UPI, and card by mode in the same database
  transaction as the order receipt. Old metal surrendered against the booking
  is a customer metal purchase/credit, not cash or bank money in. Applying an
  earlier advance to a sale does not create a second receipt.
- Girvi disbursement is Money Out and a loan receivable. Girvi principal and
  interest collections are Money In under separate Girvi categories. Pledged
  metal remains customer custody, outside owned inventory.
- Customer metal purchases appear as purchase activity; only actual cash or
  bank payout enters Money Out. Credit purchase remains payable without a
  fictitious payment. Expense Entry is limited to operating expenses.
- A return or advance cancellation records a reversal and, where applicable,
  a refund payable. It becomes Money Out only when an actual refund posting is
  made. Customer change returned at checkout is distinguished from operating
  expense.

## Daily verification and close

1. Daily Balance Verification shows the dated previous-day closing and asks
   for today's counted cash and bank balance. It compares cash and bank
   separately; an equal combined total alone cannot verify the opening.
   A confirmed cash shortage posts one linked Expense Entry adjustment, with
   personal use classified as an owner drawing. A bank difference stays
   pending for reconciliation; settlement delays must not become expense.
   Opposite cash and bank variances require a recorded transfer or corrected
   payment mode before verification, so a transfer cannot become an expense.
2. End of day counts physical cash by denomination and checks it against the
   posted cash balance. Owned gold/silver and Girvi custody are separate checks.
3. After authorization and successful checks, the database transaction saves
   the close lock and immutable evidence: physical count, cash/bank positions,
   account balances, owned metal, custody, and source hash. Closed-day source
   and ledger guards prevent silent changes. The following day's opening is
   recalculated from the prior posted closing, not manually copied.

## Certification still required

The user has not yet performed a physical item-wise metal count. Calculated
gold/silver weights remain **unverified**, and the UI blocks certified day
closing. Historical invoice issue values without an issue snapshot, unknown
purity on legacy stock movements, partial Girvi custody handovers, refund
payout records, and a complete all-source audit register still need source
verification or further implementation. No historical amount is backfilled as
verified without evidence.
