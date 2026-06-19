// =============================================================================
// FILE        : girvi_payments.dart
// MODULE      : Girvi / Pawn
// LAYER       : Database / Tables
// DESCRIPTION : Records every payment event on a girvi loan.
//               Covers interest payments, partial principal payments,
//               and the final full-release settlement.
//               Cascade-deletes with the parent GirviLoan.
// =============================================================================

import 'package:drift/drift.dart';
import '../base_table.dart';
import 'girvi_loans.dart';

@DataClassName('GirviPayment')
@TableIndex(name: 'idx_girvi_pay_girvi', columns: {#girviId})
@TableIndex(name: 'idx_girvi_pay_date', columns: {#paymentDate})
@TableIndex(name: 'idx_girvi_pay_type', columns: {#paymentType})
class GirviPayments extends Table with BaseTable {
  // ── PARENT REFERENCE ──────────────────────────────────────────────────────
  IntColumn get girviId =>
      integer().references(GirviLoans, #id, onDelete: KeyAction.cascade)();

  // ── PAYMENT DATA ──────────────────────────────────────────────────────────
  /// Date this payment was received
  DateTimeColumn get paymentDate =>
      dateTime().withDefault(currentDateAndTime)();

  /// Amount collected in this payment (₹)
  RealColumn get amount => real().withDefault(const Constant(0.0))();

  /// INTEREST | PARTIAL_PRINCIPAL | PARTIAL_INTEREST | FULL_RELEASE | PENALTY
  TextColumn get paymentType => text()();

  /// Cash | UPI | NEFT | Bank Transfer | Cheque
  TextColumn get paymentMode => text().withDefault(const Constant('Cash'))();

  /// Number of months covered (for interest payments)
  IntColumn get monthsCovered => integer().nullable()();

  /// Interest period FROM date (for interest payments)
  DateTimeColumn get interestFromDate => dateTime().nullable()();

  /// Interest period TO date (for interest payments)
  DateTimeColumn get interestToDate => dateTime().nullable()();

  /// Running outstanding balance AFTER this payment
  RealColumn get balanceAfter => real().withDefault(const Constant(0.0))();

  /// Principal portion of a Girvi release settlement payment.
  RealColumn get principalComponent =>
      real().withDefault(const Constant(0.0))();

  /// Interest portion of a Girvi release settlement payment.
  RealColumn get interestComponent => real().withDefault(const Constant(0.0))();

  /// Principal waived as part of the final Girvi release settlement.
  RealColumn get principalDiscountComponent =>
      real().withDefault(const Constant(0.0))();

  /// Interest waived as part of the final Girvi release settlement.
  RealColumn get interestDiscountComponent =>
      real().withDefault(const Constant(0.0))();

  /// Optional receipt/ref number
  TextColumn get receiptNo => text().nullable()();

  /// Any remarks
  TextColumn get notes => text().nullable()();
}
