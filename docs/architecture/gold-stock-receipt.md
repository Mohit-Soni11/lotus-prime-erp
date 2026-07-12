# Gold Stock Receipt Architecture

## Ownership

`features/gold_stock_receipts` owns Gold receipt rules, Gold-specific validation, purity calculations, Gold supplier receipt workflows, and Gold presentation state. It must not import Silver, Diamond, or Platinum features.

The shared inventory feature owns only reusable primitives: receipt transaction boundaries, inventory movements, attachments, audit events, and inventory projections.

## Stable Boundaries

The Gold presentation layer may depend on Gold application commands and immutable presentation state. It must not import Drift tables, repositories, or database classes.

The Gold application layer may depend on Gold domain types and repository interfaces. It coordinates a single receipt transaction but does not contain Flutter widgets or Drift SQL.

The Gold domain layer is pure Dart. It owns money, weight, purity, item valuation, and validation rules. It must not import Flutter, Drift, file pickers, or application state objects.

The Gold data layer implements repository interfaces and maps the domain receipt to database records. It is the only Gold layer allowed to import Drift.

## Data Model

The replacement flow will persist these records in one transaction:

- A receipt header with the supplier, source, invoice reference, receipt number, and timestamp.
- Gold receipt lines with category, physical weights, purity, rate, making charge, HUID, and stone information.
- Inventory lots and immutable inventory movements created from the receipt lines.
- Structured payment settlement rows instead of a JSON payment payload.
- Attachment metadata and a separate audit event for every create, approval, amendment, void, and reversal.

Gold receipt lines must retain a source foreign key to their inventory lots and movement records. HUID-tracked articles require quantity one and are globally unique across new Gold receipt lines. Non-HUID bulk material may remain a lot with a quantity greater than one.

## Precision Rules

Money is represented as integer paise. Gold weight is represented as integer milligrams. Purity is represented as parts per thousand. Conversion to display values is restricted to the presentation boundary.

## Migration Strategy

Existing `stock_items` and `purchase_vouchers` records remain readable. New Gold receipt tables will be introduced through formal Drift migrations only; no receipt save operation may alter the database schema. The legacy Gold screen will remain active until new receipt creation, inventory projection, payment settlement, and rollback tests pass.

## Initial Acceptance Rules

- A Gold supplier receipt requires a saved supplier profile.
- A receipt requires at least one valid Gold line.
- Gross weight must be positive and stone weight must not exceed gross weight.
- HUID values must be six uppercase letters or digits, unique within a receipt, and attached only to a single article.
- Every persisted receipt must create an audit event and inventory movement in the same transaction.
