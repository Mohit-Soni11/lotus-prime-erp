import 'package:drift/drift.dart' as drift;

import '../../database/db/app_database.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../core/logging/app_logger.dart';

part 'parts/girvi_repository_payment_numbering.dart';
part 'parts/girvi_repository_payments.dart';
part 'parts/girvi_repository_status_sync.dart';

class GirviRepository {
  final AppDatabase _db;

  GirviRepository(this._db);

  static const double _moneyTolerance = 0.01;

  double _normalizeMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  String? _normalizeReference(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  // TICKET NUMBER GENERATION

  Future<String> generateNextTicketNo({
    String prefix = 'GRV-',
    int startingNumber = 1,
  }) async {
    final resolvedPrefix =
        prefix.replaceAll('{YYYY}', DateTime.now().year.toString());
    final rows = await (_db.select(_db.girviLoans)
          ..where((loan) => loan.ticketNo.like('$resolvedPrefix%')))
        .get();

    var highest = startingNumber - 1;
    final trailingNumber = RegExp(r'(\d+)$');
    for (final row in rows) {
      final match = trailingNumber.firstMatch(row.ticketNo);
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value > highest) highest = value;
    }

    final next = highest + 1;
    return '$resolvedPrefix${next.toString().padLeft(4, '0')}';
  }

  Future<int> createLoan(GirviLoansCompanion companion) async {
    return _db.into(_db.girviLoans).insert(companion);
  }

  Future<GirviLoan?> getLoanById(int id) async {
    return (_db.select(_db.girviLoans)..where((l) => l.id.equals(id)))
        .getSingleOrNull();
  }

  Future<GirviLoan?> getLoanByTicket(String ticketNo) async {
    return (_db.select(_db.girviLoans)
          ..where((l) => l.ticketNo.equals(ticketNo)))
        .getSingleOrNull();
  }

  Future<List<GirviLoanWithCustomer>> getLoansWithCustomer({
    GirviFilter filter = GirviFilter.all,
    String searchQuery = '',
    int? customerId,
    int? loanId,
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
        case GirviFilter.settlementPending:
          query.where(
            _db.girviLoans.status.equals(GirviStatus.partialRelease.dbValue),
          );
        case GirviFilter.readyForDelivery:
          query.where(
            _db.girviLoans.status.equals(GirviStatus.readyForDelivery.dbValue),
          );
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

    if (loanId != null) {
      query.where(_db.girviLoans.id.equals(loanId));
    }

    query.orderBy([drift.OrderingTerm.desc(_db.girviLoans.startDate)]);

    final rows = await query.get();

    final loanIds =
        rows.map((row) => row.readTable(_db.girviLoans).id).toList();
    final interestPaidByLoan = <int, double>{};
    final principalPaidByLoan = <int, double>{};
    final interestDiscountByLoan = <int, double>{};
    final principalDiscountByLoan = <int, double>{};
    final legacyPrincipalRepaidByLoan = <int, double>{};
    if (loanIds.isNotEmpty) {
      final paymentRows = await (_db.select(_db.girviPayments)
            ..where((payment) => payment.girviId.isIn(loanIds)))
          .get();
      for (final payment in paymentRows) {
        final type = GirviPaymentType.fromDb(payment.paymentType);
        if (type == GirviPaymentType.interest ||
            type == GirviPaymentType.partialInterest) {
          interestPaidByLoan[payment.girviId] =
              (interestPaidByLoan[payment.girviId] ?? 0) + payment.amount;
        } else if (type == GirviPaymentType.fullRelease &&
            payment.interestComponent > 0) {
          interestPaidByLoan[payment.girviId] =
              (interestPaidByLoan[payment.girviId] ?? 0) +
                  payment.interestComponent;
        }
        if (type == GirviPaymentType.fullRelease &&
            payment.principalComponent > 0) {
          principalPaidByLoan[payment.girviId] =
              (principalPaidByLoan[payment.girviId] ?? 0) +
                  payment.principalComponent;
        }
        if (type == GirviPaymentType.fullRelease &&
            payment.interestDiscountComponent > 0) {
          interestDiscountByLoan[payment.girviId] =
              (interestDiscountByLoan[payment.girviId] ?? 0) +
                  payment.interestDiscountComponent;
        }
        if (type == GirviPaymentType.fullRelease &&
            payment.principalDiscountComponent > 0) {
          principalDiscountByLoan[payment.girviId] =
              (principalDiscountByLoan[payment.girviId] ?? 0) +
                  payment.principalDiscountComponent;
        }
        if (type == GirviPaymentType.partialPrincipal) {
          legacyPrincipalRepaidByLoan[payment.girviId] =
              (legacyPrincipalRepaidByLoan[payment.girviId] ?? 0) +
                  payment.amount;
        }
      }
    }

    var result = rows.map((row) {
      final loan = row.readTable(_db.girviLoans);
      final customer = row.readTable(_db.customers);
      return GirviLoanWithCustomer(
        loan: _mapLoan(loan),
        customerName: customer.name,
        customerMobile: customer.mobile,
        customerCity: customer.city,
        customerAddress: _formatCustomerAddress(customer),
        interestPaidTotal: interestPaidByLoan[loan.id] ?? 0,
        principalPaidTotal: principalPaidByLoan[loan.id] ?? 0,
        interestDiscountTotal: interestDiscountByLoan[loan.id] ?? 0,
        principalDiscountTotal: principalDiscountByLoan[loan.id] ?? 0,
        legacyPrincipalRepaidTotal: legacyPrincipalRepaidByLoan[loan.id] ?? 0,
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

  String _formatCustomerAddress(Customer customer) {
    final parts = <String>[
      customer.addressLine1 ?? '',
      customer.addressLine2 ?? '',
      customer.city ?? '',
      customer.state ?? '',
      customer.pincode ?? '',
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return '';
    return parts.join(', ');
  }

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
        case GirviStatus.readyForDelivery:
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

  // UPDATE LOAN

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

  // RELEASE LOAN

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
          expectedDeliveryDate: drift.Value(DateTime.now()),
          deliveredAt: drift.Value(DateTime.now()),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      if (!loanUpdated) return false;

      await _db.into(_db.girviPayments).insert(
            GirviPaymentsCompanion.insert(
              girviId: loanId,
              paymentType: GirviPaymentType.fullRelease.dbValue,
              amount: drift.Value(totalAmount),
              paymentMode: drift.Value(paymentMode),
              balanceAfter: const drift.Value(0.0),
              principalComponent: drift.Value(principal),
              interestComponent: drift.Value(interest),
              notes: const drift.Value('Full release settlement'),
            ),
          );

      return true;
    });
  }

  GirviLoanModel _mapLoan(GirviLoan row) {
    return GirviLoanModel(
      id: row.id,
      ticketNo: row.ticketNo,
      customerId: row.customerId,
      itemDescription: row.itemDescription,
      itemCount: row.itemCount,
      huidNumber: row.huidNumber,
      itemPhotoPath: row.itemPhotoPath,
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
      invoiceGenerated: row.invoiceGenerated,
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
      releaseDiscount: row.releaseDiscount,
      releaseTotalAmount: row.releaseTotalAmount,
      releasePaymentMode: row.releasePaymentMode,
      releaseNotes: row.releaseNotes,
      releasedBy: row.releasedBy,
      expectedDeliveryDate: row.expectedDeliveryDate,
      deliveredAt: row.deliveredAt,
      updatedAt: row.updatedAt,
    );
  }

  GirviPaymentModel _mapPayment(GirviPayment row) {
    return GirviPaymentModel(
      id: row.id,
      girviId: row.girviId,
      paymentDate: row.paymentDate,
      amount: row.amount,
      paymentType: row.paymentType,
      paymentMode: row.paymentMode,
      monthsCovered: row.monthsCovered,
      interestFromDate: row.interestFromDate,
      interestToDate: row.interestToDate,
      balanceAfter: row.balanceAfter,
      principalComponent: row.principalComponent,
      interestComponent: row.interestComponent,
      principalDiscountComponent: row.principalDiscountComponent,
      interestDiscountComponent: row.interestDiscountComponent,
      receiptNo: row.receiptNo,
      notes: row.notes,
      createdAt: row.createdAt,
    );
  }
}
