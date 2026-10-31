# Return & Reversal Desk Architecture

This feature owns sales returns and booking cancellations from a single ERP desk while keeping both workflows isolated internally.

## Structure

- `domain/models`: Pure business types, operation metadata, statuses, and calculation-ready value models.
- `domain/repositories`: Repository contracts used by the application layer.
- `application`: Controllers and immutable screen state. No Flutter widget composition belongs here.
- `data/repositories`: Drift-backed persistence adapters and SQL orchestration.
- `presentation/screens`: Route-level screen composition and dependency wiring.
- `presentation/body`: Page-level layout containers that consume controllers.
- `presentation/theme`: Feature-specific design tokens layered over the global Lotus ERP theme.
- `presentation/widgets`: Small reusable UI components only. Split by workflow or surface when a widget grows.

The Drift adapter keeps source lookup, posting guards, stock updates, ledger
updates, and shared mapping in separate part files. PDF document data and
layout are also separate. Presentation parts group customer details, workflow
steps, summary panels, and voucher controls by responsibility.

## Rules

- Keep sales return and booking cancellation logic separate below the shared desk shell.
- Keep database access behind repository contracts.
- Keep domain models free from Flutter UI dependencies.
- Keep screen files small; move cards, forms, dialogs, tables, and actions into dedicated files.
- Add tests with fake repositories for UI and controller behavior before touching production database flows.
- Re-read the selected source inside the posting transaction and reject a
  changed snapshot before writing vouchers, stock, or ledgers.
