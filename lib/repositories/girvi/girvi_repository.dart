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

import '../../database/db/app_database.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../core/logging/app_logger.dart';

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

  // ════════════════════════════════════════════════════════════════════════════
  // TICKET NUMBER GENERATION
  // ════════════════════════════════════════════════════════════════════════════

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

  Future<String> generateNextPaymentReceiptNo({
    String prefix = 'GIP-',
    int startingNumber = 1,
  }) async {
    final rows = await (_db.select(_db.girviPayments)
          ..where((payment) => payment.receiptNo.like('$prefix%')))
        .get();

    var highest = startingNumber - 1;
    final trailingNumber = RegExp(r'(\d+)$');
    for (final row in rows) {
      final match = trailingNumber.firstMatch(row.receiptNo ?? '');
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value > highest) highest = value;
    }

    final next = highest + 1;
    return '$prefix${next.toString().padLeft(5, '0')}';
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
          expectedDeliveryDate: drift.Value(DateTime.now()),
          deliveredAt: drift.Value(DateTime.now()),
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
              principalComponent: drift.Value(principal),
              interestComponent: drift.Value(interest),
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

  Future<GirviSettlementResult> recordReleaseSettlement({
    required int loanId,
    required double principalDue,
    required double interestDue,
    required double principalReceived,
    required double interestReceived,
    double discountAmount = 0,
    required GirviPaymentMode paymentMode,
    required DateTime paymentDate,
    required DateTime expectedDeliveryDate,
    String? receiptNo,
    String? notes,
    String? processedBy,
  }) async {
    const tolerance = _moneyTolerance;
    final principalDueValue = _normalizeMoney(principalDue);
    final interestDueValue = _normalizeMoney(interestDue);
    final principalReceivedValue = _normalizeMoney(principalReceived);
    final interestReceivedValue = _normalizeMoney(interestReceived);
    final discountValue = _normalizeMoney(discountAmount);
    final normalizedReceiptNo = _normalizeReference(receiptNo);
    final normalizedNotes = _normalizeReference(notes);

    if (principalReceivedValue < 0 ||
        interestReceivedValue < 0 ||
        discountValue < 0) {
      throw ArgumentError('Release amounts cannot be negative');
    }
    if (principalReceivedValue + interestReceivedValue + discountValue <= 0) {
      throw ArgumentError('Enter a payment or discount amount');
    }
    if (principalReceivedValue > principalDueValue + tolerance) {
      throw ArgumentError('Principal received exceeds principal due');
    }
    if (interestReceivedValue > interestDueValue + tolerance) {
      throw ArgumentError('Interest received exceeds interest due');
    }

    final grossDue = principalDueValue + interestDueValue;
    final cashReceived = principalReceivedValue + interestReceivedValue;
    if (cashReceived + discountValue > grossDue + tolerance) {
      throw ArgumentError('Payment plus discount exceeds total due');
    }

    final interestBalanceAfterCash =
        (interestDueValue - interestReceivedValue).clamp(0.0, double.infinity);
    final interestDiscount = _normalizeMoney(
      discountValue.clamp(0.0, interestBalanceAfterCash).toDouble(),
    );
    final principalDiscount = _normalizeMoney(discountValue - interestDiscount);
    final principalBalanceAfterCash =
        (principalDueValue - principalReceivedValue)
            .clamp(0.0, double.infinity);
    if (principalDiscount > principalBalanceAfterCash + tolerance) {
      throw ArgumentError('Discount exceeds the remaining settlement due');
    }

    final principalRemaining = _normalizeMoney(
      (principalDueValue - principalReceivedValue - principalDiscount)
          .clamp(0.0, double.infinity)
          .toDouble(),
    );
    final interestRemaining = _normalizeMoney(
      (interestDueValue - interestReceivedValue - interestDiscount)
          .clamp(0.0, double.infinity)
          .toDouble(),
    );
    final fullySettled =
        principalRemaining <= tolerance && interestRemaining <= tolerance;
    if (discountAmount > tolerance && !fullySettled) {
      throw ArgumentError(
        'Discount can only be approved with a complete settlement',
      );
    }

    return _db.transaction(() async {
      final loan = await getLoanById(loanId);
      if (loan == null) {
        throw StateError('Girvi loan not found for release settlement');
      }
      if (GirviStatus.fromDb(loan.status).isClosed) {
        throw StateError('Girvi loan is already closed');
      }

      final amountReceived =
          _normalizeMoney(principalReceivedValue + interestReceivedValue);

      final updated = await updateLoan(
        loanId,
        GirviLoansCompanion(
          status: drift.Value(
            fullySettled
                ? GirviStatus.readyForDelivery.dbValue
                : GirviStatus.partialRelease.dbValue,
          ),
          releaseDate: fullySettled
              ? drift.Value(paymentDate)
              : const drift.Value.absent(),
          releasePrincipal: drift.Value(_normalizeMoney(
            (loan.releasePrincipal ?? 0) + principalReceivedValue,
          )),
          releaseInterest: drift.Value(_normalizeMoney(
            (loan.releaseInterest ?? 0) + interestReceivedValue,
          )),
          releasePenalty: const drift.Value(0),
          releaseDiscount: drift.Value(_normalizeMoney(
            (loan.releaseDiscount ?? 0) + discountValue,
          )),
          releaseTotalAmount: drift.Value(_normalizeMoney(
            (loan.releaseTotalAmount ?? 0) + amountReceived,
          )),
          releasePaymentMode: drift.Value(paymentMode.dbValue),
          releaseNotes: drift.Value(normalizedNotes),
          releasedBy: drift.Value(processedBy),
          expectedDeliveryDate: drift.Value(expectedDeliveryDate),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
      if (!updated) {
        throw StateError('Unable to update Girvi settlement');
      }

      await _db.into(_db.girviPayments).insert(
            GirviPaymentsCompanion.insert(
              girviId: loanId,
              paymentType: GirviPaymentType.fullRelease.dbValue,
              paymentDate: drift.Value(paymentDate),
              amount: drift.Value(amountReceived),
              paymentMode: drift.Value(paymentMode.dbValue),
              balanceAfter: drift.Value(
                _normalizeMoney(principalRemaining + interestRemaining),
              ),
              principalComponent: drift.Value(principalReceivedValue),
              interestComponent: drift.Value(interestReceivedValue),
              principalDiscountComponent: drift.Value(principalDiscount),
              interestDiscountComponent: drift.Value(interestDiscount),
              receiptNo: drift.Value(normalizedReceiptNo),
              notes: drift.Value(normalizedNotes),
            ),
          );

      return GirviSettlementResult(
        fullySettled: fullySettled,
        principalRemaining: principalRemaining,
        interestRemaining: interestRemaining,
        principalDiscount: principalDiscount,
        interestDiscount: interestDiscount,
      );
    });
  }

  Future<bool> markGirviDelivered({
    required int loanId,
    required DateTime deliveredAt,
    String? deliveredBy,
  }) async {
    return _db.transaction(() async {
      final loan = await getLoanById(loanId);
      if (loan == null) throw StateError('Girvi loan not found');
      if (GirviStatus.fromDb(loan.status) != GirviStatus.readyForDelivery) {
        throw StateError('Girvi must be fully settled before delivery');
      }
      return updateLoan(
        loanId,
        GirviLoansCompanion(
          status: drift.Value(GirviStatus.released.dbValue),
          deliveredAt: drift.Value(deliveredAt),
          releasedBy: drift.Value(deliveredBy ?? loan.releasedBy),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    });
  }

  Future<int> recordInterestLedgerPayment({
    required int loanId,
    required GirviPaymentMode paymentMode,
    required double amount,
    required DateTime paymentDate,
    int? monthsCovered,
    DateTime? interestFromDate,
    DateTime? interestToDate,
    String? receiptNo,
    String? notes,
  }) async {
    final receivedAmount = _normalizeMoney(amount);
    final normalizedReceiptNo = _normalizeReference(receiptNo);
    final normalizedNotes = _normalizeReference(notes);

    if (receivedAmount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Payment amount must be > 0',
      );
    }

    return _db.transaction(() async {
      final loan = await getLoanById(loanId);
      if (loan == null) {
        throw StateError('Girvi loan not found for interest payment');
      }

      final updated = await updateLoan(
        loanId,
        GirviLoansCompanion(updatedAt: drift.Value(DateTime.now())),
      );
      if (!updated) {
        throw StateError('Unable to update girvi loan before payment entry');
      }

      return _db.into(_db.girviPayments).insert(
            GirviPaymentsCompanion.insert(
              girviId: loanId,
              paymentType: GirviPaymentType.interest.dbValue,
              paymentDate: drift.Value(paymentDate),
              amount: drift.Value(receivedAmount),
              paymentMode: drift.Value(paymentMode.dbValue),
              monthsCovered: drift.Value(monthsCovered),
              interestFromDate: drift.Value(interestFromDate),
              interestToDate: drift.Value(interestToDate),
              balanceAfter: drift.Value(_normalizeMoney(loan.loanAmount)),
              receiptNo: drift.Value(normalizedReceiptNo),
              notes: drift.Value(normalizedNotes),
            ),
          );
    });
  }

  /// Legacy payment entry path kept for historical data compatibility.
  /// New Interest Entry UI uses [recordInterestLedgerPayment]; release uses
  /// [recordReleaseSettlement].
  Future<int> recordPayment({
    required int loanId,
    required GirviPaymentType paymentType,
    required GirviPaymentMode paymentMode,
    required double amount,
    required DateTime paymentDate,
    int? monthsCovered,
    DateTime? interestFromDate,
    DateTime? interestToDate,
    String? receiptNo,
    String? notes,
  }) async {
    final receivedAmount = _normalizeMoney(amount);
    final normalizedReceiptNo = _normalizeReference(receiptNo);
    final normalizedNotes = _normalizeReference(notes);

    if (receivedAmount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Payment amount must be > 0',
      );
    }

    return _db.transaction(() async {
      final loan = await getLoanById(loanId);
      if (loan == null) {
        throw StateError('Girvi loan not found for payment entry');
      }
      final loanModel = _mapLoan(loan);

      var balanceAfter = loan.loanAmount;
      var resolvedMonthsCovered = monthsCovered;
      var resolvedInterestFromDate = interestFromDate;
      var resolvedInterestToDate = interestToDate;
      var loanUpdate = GirviLoansCompanion(
        updatedAt: drift.Value(DateTime.now()),
      );

      if (paymentType == GirviPaymentType.interest) {
        final interestStart = loanModel.lastInterestPaidDate ??
            interestFromDate ??
            loanModel.startDate;
        final coveredMonths = loanModel.interestMonthsCoveredByPayment(
          amount: receivedAmount,
          fromDate: interestStart,
          paymentDate: paymentDate,
        );
        if (coveredMonths <= 0) {
          throw ArgumentError.value(
            amount,
            'amount',
            'Interest payment must cover at least one full interest month',
          );
        }
        final paidThrough =
            GirviLoanModel.addChargeableMonths(interestStart, coveredMonths);
        resolvedMonthsCovered = coveredMonths;
        resolvedInterestFromDate = interestStart;
        resolvedInterestToDate = paidThrough;
        loanUpdate = loanUpdate.copyWith(
          lastInterestPaidDate: drift.Value(paidThrough),
        );
      }

      if (paymentType == GirviPaymentType.partialPrincipal) {
        if (receivedAmount > loan.loanAmount + _moneyTolerance) {
          throw ArgumentError.value(
            amount,
            'amount',
            'Principal payment cannot exceed outstanding principal',
          );
        }
        balanceAfter = _normalizeMoney(
          (loan.loanAmount - receivedAmount)
              .clamp(0.0, double.infinity)
              .toDouble(),
        );
        loanUpdate = loanUpdate.copyWith(
          loanAmount: drift.Value(balanceAfter),
        );
      }

      final updated = await updateLoan(loanId, loanUpdate);
      if (!updated) {
        throw StateError('Unable to update girvi loan before payment entry');
      }

      return _db.into(_db.girviPayments).insert(
            GirviPaymentsCompanion.insert(
              girviId: loanId,
              paymentType: paymentType.dbValue,
              paymentDate: drift.Value(paymentDate),
              amount: drift.Value(receivedAmount),
              paymentMode: drift.Value(paymentMode.dbValue),
              monthsCovered: drift.Value(resolvedMonthsCovered),
              interestFromDate: drift.Value(resolvedInterestFromDate),
              interestToDate: drift.Value(resolvedInterestToDate),
              balanceAfter: drift.Value(_normalizeMoney(balanceAfter)),
              receiptNo: drift.Value(normalizedReceiptNo),
              notes: drift.Value(normalizedNotes),
            ),
          );
    });
  }

  Future<List<GirviPayment>> getPaymentsForLoan(int loanId) async {
    return (_db.select(_db.girviPayments)
          ..where((p) => p.girviId.equals(loanId))
          ..orderBy([(p) => drift.OrderingTerm.desc(p.paymentDate)]))
        .get();
  }

  Future<List<GirviPaymentModel>> getPaymentModelsForLoan(int loanId) async {
    final rows = await getPaymentsForLoan(loanId);
    return rows.map(_mapPayment).toList();
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
      AppLogger.debug('🔄 GirviRepository: $updated loans marked overdue.');
    }
    return updated;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PRIVATE — MAP DB ROW → MODEL
  // ════════════════════════════════════════════════════════════════════════════

  Future<int> syncSettlementStatus() async {
    const tolerance = 0.01;
    final openLoans = await (_db.select(_db.girviLoans)
          ..where(
            (loan) =>
                loan.status.equals(GirviStatus.active.dbValue) |
                loan.status.equals(GirviStatus.overdue.dbValue) |
                loan.status.equals(GirviStatus.partialRelease.dbValue),
          ))
        .get();
    if (openLoans.isEmpty) return 0;

    final loanIds = openLoans.map((loan) => loan.id).toList();
    final payments = await (_db.select(_db.girviPayments)
          ..where((payment) => payment.girviId.isIn(loanIds)))
        .get();
    final paymentsByLoan = <int, List<GirviPayment>>{};
    for (final payment in payments) {
      paymentsByLoan.putIfAbsent(payment.girviId, () => []).add(payment);
    }

    var updatedCount = 0;
    final now = DateTime.now();
    for (final loan in openLoans) {
      final loanPayments = paymentsByLoan[loan.id] ?? const <GirviPayment>[];
      if (loanPayments.isEmpty) continue;

      var legacyPrincipalRepaid = 0.0;
      var releasePrincipalPaid = 0.0;
      var interestPaid = 0.0;
      var principalDiscount = 0.0;
      var interestDiscount = 0.0;
      DateTime? latestPaymentDate;

      for (final payment in loanPayments) {
        final type = GirviPaymentType.fromDb(payment.paymentType);
        if (type == GirviPaymentType.partialPrincipal) {
          legacyPrincipalRepaid += payment.amount;
        } else if (type == GirviPaymentType.interest ||
            type == GirviPaymentType.partialInterest) {
          interestPaid += payment.amount;
        } else if (type == GirviPaymentType.fullRelease) {
          releasePrincipalPaid += payment.principalComponent;
          interestPaid += payment.interestComponent;
          principalDiscount += payment.principalDiscountComponent;
          interestDiscount += payment.interestDiscountComponent;
        }

        if (latestPaymentDate == null ||
            payment.paymentDate.isAfter(latestPaymentDate)) {
          latestPaymentDate = payment.paymentDate;
        }
      }

      final originalPrincipal = loan.loanAmount + legacyPrincipalRepaid;
      final principalDue =
          (loan.loanAmount - releasePrincipalPaid - principalDiscount)
              .clamp(0.0, double.infinity);
      final interestMonths = GirviLoanModel.chargeableMonthsBetween(
        loan.startDate,
        loan.releaseDate ?? now,
      );
      final grossInterest = GirviLoanModel.calculateCompoundInterest(
        principal: originalPrincipal,
        monthlyRatePercent: loan.interestRate,
        months: interestMonths,
      );
      final interestDue = (grossInterest - interestPaid - interestDiscount)
          .clamp(0.0, double.infinity);

      if (principalDue <= tolerance && interestDue <= tolerance) {
        final settlementDate = loan.releaseDate ?? latestPaymentDate ?? now;
        final updated = await updateLoan(
          loan.id,
          GirviLoansCompanion(
            status: drift.Value(GirviStatus.readyForDelivery.dbValue),
            releaseDate: drift.Value(settlementDate),
            expectedDeliveryDate: drift.Value(loan.expectedDeliveryDate ?? now),
            updatedAt: drift.Value(now),
          ),
        );
        if (updated) updatedCount++;
      }
    }

    return updatedCount;
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