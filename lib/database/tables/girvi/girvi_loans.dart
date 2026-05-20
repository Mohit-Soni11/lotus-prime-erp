// =============================================================================
// FILE        : girvi_loans.dart
// MODULE      : Girvi / Pawn
// LAYER       : Database / Tables
// DESCRIPTION : Full production-grade Girvi (Pawn Loan) table.
//               Schema v9 — new table, no migration from old Loans table.
//               Fields cover: ticket, customer ref, item details, valuation,
//               loan terms, KYC, dates, status, and release settlement data.
// =============================================================================

import 'package:drift/drift.dart';
import '../base_table.dart';
import '../customers.dart';

@DataClassName('GirviLoan')
@TableIndex(name: 'idx_girvi_customer', columns: {#customerId})
@TableIndex(name: 'idx_girvi_status', columns: {#status})
@TableIndex(name: 'idx_girvi_ticket', columns: {#ticketNo})
@TableIndex(name: 'idx_girvi_startdate', columns: {#startDate})
class GirviLoans extends Table with BaseTable {
  // ── TICKET ───────────────────────────────────────────────────────────────
  /// Unique ticket number e.g. GRV/2024/00001
  TextColumn get ticketNo => text().unique()();

  // ── CUSTOMER REF ─────────────────────────────────────────────────────────
  IntColumn get customerId =>
      integer().references(Customers, #id, onDelete: KeyAction.restrict)();

  // ── ITEM DETAILS ─────────────────────────────────────────────────────────
  /// Free-text description e.g. "Gold Necklace with pendant"
  TextColumn get itemDescription => text()();

  /// Count of items in this girvi
  IntColumn get itemCount => integer().withDefault(const Constant(1))();

  /// Gold | Silver | Diamond | Platinum | Mixed | Other
  TextColumn get metalType => text().withDefault(const Constant('Gold'))();

  /// 24K | 22K | 18K | 14K | 925 | 999 | Other
  TextColumn get metalPurity => text().withDefault(const Constant('22K'))();

  /// Total gross weight in grams
  RealColumn get grossWeight => real().withDefault(const Constant(0.0))();

  /// Stone/bead/non-metal deduction in grams
  RealColumn get stoneWeight => real().withDefault(const Constant(0.0))();

  /// Net metal weight = gross - stone (computed & stored for speed)
  RealColumn get netWeight => real().withDefault(const Constant(0.0))();

  // ── VALUATION ─────────────────────────────────────────────────────────────
  /// Rate per gram at time of loan (₹/g)
  RealColumn get ratePerGram => real().withDefault(const Constant(0.0))();

  /// Total market value of items (netWeight × ratePerGram)
  RealColumn get totalValue => real().withDefault(const Constant(0.0))();

  /// LTV % = loanAmount / totalValue × 100 (stored for reporting)
  RealColumn get ltvPercent => real().withDefault(const Constant(0.0))();

  // ── LOAN TERMS ────────────────────────────────────────────────────────────
  /// Principal loan amount disbursed to customer (₹)
  RealColumn get loanAmount => real().withDefault(const Constant(0.0))();

  /// Monthly interest rate in % (e.g. 2.0 = 2% per month)
  RealColumn get interestRate => real().withDefault(const Constant(2.0))();

  /// Agreed loan duration in months
  IntColumn get durationMonths => integer().withDefault(const Constant(12))();

  /// How the customer received the loan money
  /// Cash | UPI | NEFT | Bank Transfer | Cheque
  TextColumn get disbursementMode =>
      text().withDefault(const Constant('Cash'))();

  // ── DATES ─────────────────────────────────────────────────────────────────
  /// Date loan was created/started
  DateTimeColumn get startDate => dateTime().withDefault(currentDateAndTime)();

  /// Maturity date = startDate + durationMonths (stored for alerts)
  DateTimeColumn get maturityDate => dateTime().nullable()();

  /// Actual date of release / redemption
  DateTimeColumn get releaseDate => dateTime().nullable()();

  /// Date of last interest payment
  DateTimeColumn get lastInterestPaidDate => dateTime().nullable()();

  // ── KYC / COMPLIANCE ──────────────────────────────────────────────────────
  /// Aadhaar | PAN | Voter ID | Passport | Driving License | Other
  TextColumn get idProofType => text().nullable()();
  TextColumn get idProofNumber => text().nullable()();

  /// Path to scanned ID proof document
  TextColumn get idProofImagePath => text().nullable()();

  // ── STATUS ────────────────────────────────────────────────────────────────
  /// ACTIVE | RELEASED | OVERDUE | AUCTIONED | PARTIAL_RELEASE
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();

  // ── NOTES ─────────────────────────────────────────────────────────────────
  TextColumn get notes => text().nullable()();

  // ── RELEASE / SETTLEMENT DATA ─────────────────────────────────────────────
  /// Principal outstanding at release
  RealColumn get releasePrincipal => real().nullable()();

  /// Total interest charged at release
  RealColumn get releaseInterest => real().nullable()();

  /// Penalty (if any overdue charges) at release
  RealColumn get releasePenalty => real().nullable()();

  /// Total amount collected at release
  RealColumn get releaseTotalAmount => real().nullable()();

  /// Payment mode used at release
  TextColumn get releasePaymentMode => text().nullable()();

  /// Remarks at time of release
  TextColumn get releaseNotes => text().nullable()();

  /// Who processed the release (staff name / ID)
  TextColumn get releasedBy => text().nullable()();
}
