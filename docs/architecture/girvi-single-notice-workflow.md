# Girvi single-notice workflow

New accounts prepare one formal notice, with independently approved Hindi and
English versions. The workflow is notice required, notice period, recovery
approval, collateral recovery, and closed. Expiry only makes a case available
for review; an operator must explicitly initiate recovery and record settlement.

## Ownership

- `GirviNoticeType.formal` is the only generatable notice type.
- `GirviNoticeGenerationService` builds both languages from the account timeline.
- `girvi_formal_notice_copy.dart` owns the single notice's wording.
- `GirviNoticeActionRepository` approves once, checks deadlines, and records output.
- `ContactRecoveryCase` exposes matching UI eligibility and status.
- `GirviNoticeHistory` only interprets the retired action types for saved records.

The notice-period setting remains configurable. Its deadline is persisted at
approval and is checked as an exact timestamp in both model and repository.
Approval, PDF save, printing, and recorded delivery are distinct events.
The application does not certify that its configured period or document meets
the legal requirements for a particular sale.

## Schema 59 and compatibility

The new action type is `NOTICE_PREPARED`. A partial unique index on `girvi_id`
prevents duplicate formal approvals, including writes that bypass the repository.
Delivery actions reference their approved notice through nullable
`notice_action_id`; language-specific text hashes are still verified.

The migration retains all earlier notice texts, stages, IDs, hashes, dates,
language documents, customer responses, and finance entries. Historical
First/Second reminders do not authorize recovery; an account with only those
records may prepare the new formal notice. An already approved historical Final
Notice retains its existing deadline and remains the recovery-review notice.
Accounts already in recovery or closed cannot prepare another notice.

Earlier documents remain accessible in a collapsed history section. They are
never regenerated using the new wording. Their saved language availability and
titles are preserved. New customer responses and output records link to the
exact approved action, rather than relying on the old stage number.

The three-stage approval trigger is retired. No historical customer or accounting
data is deleted, and the interest-calculation policy is not changed.
