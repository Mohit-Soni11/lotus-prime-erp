// =============================================================================
// FILE        : girvi_repository.dart
// MODULE      : Girvi / Pawn
// LAYER       : Repository / Data Access
// DESCRIPTION : Single data-access gateway for the entire Girvi module.
//               Controllers NEVER touch AppDatabase directly — only this class.
//               Covers: ticket generation, CRUD for loans & payments,
//               join queries with customers, aggregate stats, and filters.
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../../database/db/app_database.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';

class GirviRepository {
  final AppDatabase _db;

  GirviRepository(this._db);

  // ════════════════════════════════════════════════════════════════════════════
  // TICKET NUMBER GENERATION
  // ════════════════════════════════════════════════════════════════════════════

  /// Generates next ticket: GRV/YYYY/00001
  Future<String> generateNextTicketNo() async {
    final year = DateTime.now().year;
    final prefix = 'GRV/$year/';

    // Count existing tickets for this year
    final query = _db.selectOnly(_db.girviLoans)
      ..addColumns([_db.girviLoans.id.count()])
      ..where(_db.girviLoans.ticketNo.like('$prefix%'));

    final result = await query.getSingle();
    final count = result.read(_db.girviLoans.id.count()) ?? 0;
    final seq = (count + 1).toString().padLeft(5, '0');

    return '$prefix$seq';
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CREATE LOAN
  // ════════════════════════════════════════════════════════════════════════════

  Future<int> createLoan(GirviLoansCompanion companion) async {
    return _db.into(_db.girviLoans).insert(companion);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // READ — SINGLE LOAN
  // ════════════════════════════════════════════════════════════════════════════

  Future<GirviLoan?> getLoanById(int id) async {
    return (_db.select(_db.girviLoans)..where((l) => l.id.equals(id)))
        .getSingleOrNull();
  }

  Future<GirviLoan?> getLoanByTicket(String ticketNo) async {
    return (_db.select(_db.girviLoans)
          ..where((l) => l.ticketNo.equals(ticketNo)))
        .getSingleOrNull();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // READ — LIST WITH CUSTOMER JOIN
  // ════════════════════════════════════════════════════════════════════════════

  Future<List<GirviLoanWithCustomer>> getLoansWithCustomer({
    GirviFilter filter = GirviFilter.all,
    String searchQuery = '',
    int? customerId,
  }) async {
    final query = _db.select(_db.girviLoans).join([
      drift.innerJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.girviLoans.customerId),
      ),
    ]);

    // Status filter
    if (filter != GirviFilter.all) {
      switch (filter) {
        case GirviFilter.active:
          query.where(_db.girviLoans.status.equals(GirviStatus.active.dbValue));
        case GirviFilter.overdue:
          query
              .where(_db.girviLoans.status.equals(GirviStatus.overdue.dbValue));
        case GirviFilter.released:
          query.where(
              _db.girviLoans.status.equals(GirviStatus.released.dbValue));
        case GirviFilter.auctioned:
          query.where(
              _db.girviLoans.status.equals(GirviStatus.auctioned.dbValue));
        default:
          break;
      }
    }

    // Customer filter
    if (customerId != null) {
      query.where(_db.girviLoans.customerId.equals(customerId));
    }

    query.orderBy([drift.OrderingTerm.desc(_db.girviLoans.startDate)]);

    final rows = await query.get();

    var result = rows.map((row) {
      final loan = row.readTable(_db.girviLoans);
      final customer = row.readTable(_db.customers);
      return GirviLoanWithCustomer(
        loan: _mapLoan(loan),
        customerName: customer.name,
        customerMobile: customer.mobile,
        customerCity: customer.city,
      );
    }).toList();

    // Search filter (client-side for simplicity)
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((g) =>
              g.loan.ticketNo.toLowerCase().contains(q) ||
              g.customerName.toLowerCase().contains(q) ||
              g.customerMobile.contains(q) ||
              g.loan.itemDescription.toLowerCase().contains(q))
          .toList();
    }

    return result;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // READ — STATS
  // ════════════════════════════════════════════════════════════════════════════

  Future<GirviSummaryModel> getSummary() async {
    final allLoans = await (_db.select(_db.girviLoans)).get();

    int totalActive = 0;
    int totalOverdue = 0;
    int totalReleased = 0;
    int totalAuctioned = 0;
    double totalPrincipal = 0;
    double totalInterestDue = 0;
    double totalValue = 0;

    final now = DateTime.now();

    for (final loan in allLoans) {
      final model = _mapLoan(loan);
      switch (GirviStatus.fromDb(loan.status)) {
        case GirviStatus.active:
        case GirviStatus.partialRelease:
          final overdue =
              loan.maturityDate != null && now.isAfter(loan.maturityDate!);
          if (overdue) {
            totalOverdue++;
          } else {
            totalActive++;
          }
          totalPrincipal += loan.loanAmount;
          totalInterestDue += model.accruedInterest;
          totalValue += loan.totalValue;
        case GirviStatus.released:
          totalReleased++;
        case GirviStatus.auctioned:
          totalAuctioned++;
        case GirviStatus.overdue:
          totalOverdue++;
          totalPrincipal += loan.loanAmount;
          totalInterestDue += model.accruedInterest;
      }
    }

    // Monthly collections
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final payments = await (_db.select(_db.girviPayments)
          ..where((p) => p.paymentDate.isBiggerOrEqualValue(firstOfMonth)))
        .get();
    final monthlyCollected = payments.fold<double>(0.0, (s, p) => s + p.amount);

    return GirviSummaryModel(
      totalActive: totalActive,
      totalOverdue: totalOverdue,
      totalReleased: totalReleased,
      totalAuctioned: totalAuctioned,
      totalPrincipalActive: totalPrincipal,
      totalInterestDue: totalInterestDue,
      totalPortfolioValue: totalValue,
      totalCollectedThisMonth: monthlyCollected,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // UPDATE LOAN
  // ════════════════════════════════════════════════════════════════════════════

  Future<bool> updateLoan(int id, GirviLoansCompanion companion) async {
    final rows = await (_db.update(_db.girviLoans)
          ..where((l) => l.id.equals(id)))
        .write(companion);
    return rows > 0;
  }

  Future<bool> updateStatus(int id, GirviStatus status) async {
    return updateLoan(
      id,
      GirviLoansCompanion(
        status: drift.Value(status.dbValue),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // RELEASE LOAN
  // ════════════════════════════════════════════════════════════════════════════

  Future<bool> releaseLoan({
    required int loanId,
    required double principal,
    required double interest,
    required double penalty,
    required double totalAmount,
    required String paymentMode,
    String? notes,
    String? releasedBy,
  }) async {
    return _db.transaction(() async {
      // 1. Update loan record
      final loanUpdated = await updateLoan(
        loanId,
        GirviLoansCompanion(
          status: drift.Value(GirviStatus.released.dbValue),
          releaseDate: drift.Value(DateTime.now()),
          releasePrincipal: drift.Value(principal),
          releaseInterest: drift.Value(interest),
          releasePenalty: drift.Value(penalty),
          releaseTotalAmount: drift.Value(totalAmount),
          releasePaymentMode: drift.Value(paymentMode),
          releaseNotes: drift.Value(notes),
          releasedBy: drift.Value(releasedBy),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      if (!loanUpdated) return false;

      // 2. Insert final payment record
      // RULE: required fields (no default in table) = raw value
      //       optional fields (withDefault / nullable) = drift.Value()
      await _db.into(_db.girviPayments).insert(
            GirviPaymentsCompanion.insert(
              girviId: loanId, // required — raw int
              paymentType:
                  GirviPaymentType.fullRelease.dbValue, // required — raw String
              amount: drift.Value(totalAmount), // withDefault → drift.Value
              paymentMode:
                  drift.Value(paymentMode), // withDefault → drift.Value
              balanceAfter: const drift.Value(0.0), // withDefault → drift.Value
              notes: const drift.Value(
                  'Full release settlement'), // nullable   → drift.Value
            ),
          );

      return true;
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PAYMENTS — CRUD
  // ════════════════════════════════════════════════════════════════════════════

  Future<int> addPayment(GirviPaymentsCompanion companion) async {
    return _db.into(_db.girviPayments).insert(companion);
  }

  Future<List<GirviPayment>> getPaymentsForLoan(int loanId) async {
    return (_db.select(_db.girviPayments)
          ..where((p) => p.girviId.equals(loanId))
          ..orderBy([(p) => drift.OrderingTerm.desc(p.paymentDate)]))
        .get();
  }

  Future<double> getTotalPaidForLoan(int loanId) async {
    final payments = await getPaymentsForLoan(loanId);
    return payments.fold<double>(0.0, (s, p) => s + p.amount);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // OVERDUE SYNC — auto-update active overdue loans
  // ════════════════════════════════════════════════════════════════════════════

  Future<int> syncOverdueStatus() async {
    final now = DateTime.now();
    int updated = 0;

    final activeLoans = await (_db.select(_db.girviLoans)
          ..where((l) => l.status.equals(GirviStatus.active.dbValue)))
        .get();

    for (final loan in activeLoans) {
      if (loan.maturityDate != null && now.isAfter(loan.maturityDate!)) {
        await updateStatus(loan.id, GirviStatus.overdue);
        updated++;
      }
    }

    if (updated > 0) {
      debugPrint('🔄 GirviRepository: $updated loans marked overdue.');
    }
    return updated;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PRIVATE — MAP DB ROW → MODEL
  // ════════════════════════════════════════════════════════════════════════════

  GirviLoanModel _mapLoan(GirviLoan row) {
    return GirviLoanModel(
      id: row.id,
      ticketNo: row.ticketNo,
      customerId: row.customerId,
      itemDescription: row.itemDescription,
      itemCount: row.itemCount,
      metalType: row.metalType,
      metalPurity: row.metalPurity,
      grossWeight: row.grossWeight,
      stoneWeight: row.stoneWeight,
      netWeight: row.netWeight,
      ratePerGram: row.ratePerGram,
      totalValue: row.totalValue,
      ltvPercent: row.ltvPercent,
      loanAmount: row.loanAmount,
      interestRate: row.interestRate,
      durationMonths: row.durationMonths,
      disbursementMode: row.disbursementMode,
      startDate: row.startDate,
      createdAt: row.createdAt,
      maturityDate: row.maturityDate,
      releaseDate: row.releaseDate,
      lastInterestPaidDate: row.lastInterestPaidDate,
      idProofType: row.idProofType,
      idProofNumber: row.idProofNumber,
      idProofImagePath: row.idProofImagePath,
      status: row.status,
      notes: row.notes,
      releasePrincipal: row.releasePrincipal,
      releaseInterest: row.releaseInterest,
      releasePenalty: row.releasePenalty,
      releaseTotalAmount: row.releaseTotalAmount,
      releasePaymentMode: row.releasePaymentMode,
      releaseNotes: row.releaseNotes,
      releasedBy: row.releasedBy,
      updatedAt: row.updatedAt,
    );
  }
}
