part of '../girvi_repository.dart';

extension GirviRepositoryPayments on GirviRepository {
  Future<GirviSettlementResult> recordReleaseSettlement({
    required int loanId,
    required double principalDue,
    required double interestDue,
    required double principalReceived,
    required double interestReceived,
    double discountAmount = 0,
    required GirviPaymentMode paymentMode,
    int? bankAccountId,
    required DateTime paymentDate,
    required DateTime expectedDeliveryDate,
    String? receiptNo,
    String? notes,
    String? processedBy,
  }) async {
    const tolerance = GirviRepository._moneyTolerance;
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
    if (discountValue > interestBalanceAfterCash + tolerance) {
      throw ArgumentError('Interest discount cannot reduce principal due');
    }
    final interestDiscount = discountValue;

    final principalRemaining = _normalizeMoney(
      (principalDueValue - principalReceivedValue)
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
      if (GirviStatus.fromDb(loan.status) == GirviStatus.readyForDelivery) {
        throw StateError('Girvi settlement is already complete');
      }
      final account = (await getLoansWithCustomer(loanId: loanId)).single;
      if ((account.principalDue - principalDueValue).abs() > tolerance) {
        throw StateError('Principal due changed; refresh the settlement');
      }

      final collectionDay = DateTime(
        paymentDate.year,
        paymentDate.month,
        paymentDate.day,
      );
      final pledgeDay = DateTime(
        loan.startDate.year,
        loan.startDate.month,
        loan.startDate.day,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final pickupDay = DateTime(
        expectedDeliveryDate.year,
        expectedDeliveryDate.month,
        expectedDeliveryDate.day,
      );
      if (collectionDay.isBefore(pledgeDay) || collectionDay.isAfter(today)) {
        throw ArgumentError(
            'Collection date must be between pledge date and today');
      }
      if (pickupDay.isBefore(collectionDay)) {
        throw ArgumentError(
            'Expected pickup date cannot be before collection date');
      }
      final currentInterestDue = _normalizeMoney(
          account.interestQuoteAt(paymentDate).interestOutstanding);
      if ((currentInterestDue - interestDueValue).abs() > tolerance) {
        throw StateError('Interest due changed; refresh the settlement');
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

      final paymentId = await _db.into(_db.girviPayments).insert(
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
              principalDiscountComponent: const drift.Value(0),
              interestDiscountComponent: drift.Value(interestDiscount),
              receiptNo: drift.Value(normalizedReceiptNo),
              notes: drift.Value(normalizedNotes),
            ),
          );
      await GirviFinancialPosting(_db).collection(
        loanId: loanId,
        paymentId: paymentId,
        customerName: account.customerName,
        date: paymentDate,
        mode: paymentMode.dbValue,
        principal: principalReceivedValue,
        interest: interestReceivedValue,
        bankAccountId: bankAccountId,
      );

      return GirviSettlementResult(
        fullySettled: fullySettled,
        principalRemaining: principalRemaining,
        interestRemaining: interestRemaining,
        principalDiscount: 0,
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
          expectedDeliveryDate: drift.Value(deliveredAt),
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
    int? bankAccountId,
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
      final loanModel = _mapLoan(loan);
      final collectionDay = DateTime(
        paymentDate.year,
        paymentDate.month,
        paymentDate.day,
      );
      final pledgeDay = DateTime(
        loan.startDate.year,
        loan.startDate.month,
        loan.startDate.day,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (collectionDay.isBefore(pledgeDay)) {
        throw ArgumentError(
            'Collection date cannot be before the pledge date.');
      }
      if (collectionDay.isAfter(today)) {
        throw ArgumentError('Collection date cannot be in the future.');
      }
      if (loanModel.girviStatus.isClosed ||
          loanModel.girviStatus == GirviStatus.readyForDelivery) {
        throw StateError('Interest cannot be collected after settlement.');
      }

      final existingPayments = await (_db.select(_db.girviPayments)
            ..where((payment) => payment.girviId.equals(loanId)))
          .get();
      var principalRepaid = 0.0;
      final interestAdjustments = <GirviInterestAdjustment>[];
      var calculationDate = paymentDate;
      for (final payment in existingPayments) {
        final type = GirviPaymentType.fromDb(payment.paymentType);
        if (payment.paymentDate.isAfter(calculationDate)) {
          calculationDate = payment.paymentDate;
        }
        final adjustment = GirviInterestPaymentAdjustments.fromPayment(payment);
        if (adjustment != null) interestAdjustments.add(adjustment);
        if (type == GirviPaymentType.partialPrincipal) {
          principalRepaid += payment.amount;
        } else if (type == GirviPaymentType.interest ||
            type == GirviPaymentType.partialInterest) {
          principalRepaid += payment.principalComponent;
        }
      }

      final originalPrincipal = loan.loanAmount + principalRepaid;
      final interestComponent = receivedAmount;
      final priorCoveredMonths =
          GirviInterestCalculator.coveredMonthsForTimeline(
        principal: originalPrincipal,
        monthlyRatePercent: loan.interestRate,
        startDate: loan.startDate,
        asOf: calculationDate,
        adjustments: interestAdjustments,
      );
      final totalCoveredMonths =
          GirviInterestCalculator.coveredMonthsForTimeline(
        principal: originalPrincipal,
        monthlyRatePercent: loan.interestRate,
        startDate: loan.startDate,
        asOf: calculationDate,
        adjustments: [
          ...interestAdjustments,
          GirviInterestAdjustment(date: paymentDate, paid: receivedAmount),
        ],
      );
      final entryCoveredMonths =
          (totalCoveredMonths - priorCoveredMonths).clamp(0, 1000000);
      final resolvedMonthsCovered =
          entryCoveredMonths > 0 ? entryCoveredMonths : monthsCovered;
      final resolvedInterestFromDate = interestFromDate ??
          (entryCoveredMonths > 0
              ? GirviLoanModel.addChargeableMonths(
                  loan.startDate,
                  priorCoveredMonths,
                )
              : null);
      final resolvedInterestToDate = interestToDate ??
          (entryCoveredMonths > 0
              ? GirviLoanModel.addChargeableMonths(
                  loan.startDate,
                  totalCoveredMonths,
                )
              : null);
      final paidThrough = resolvedInterestToDate;
      final shouldMovePaidThrough = paidThrough != null &&
          (loanModel.lastInterestPaidDate == null ||
              paidThrough.isAfter(loanModel.lastInterestPaidDate!));
      final balanceAfter = _normalizeMoney(loan.loanAmount);

      final updated = await updateLoan(
        loanId,
        GirviLoansCompanion(
          lastInterestPaidDate: shouldMovePaidThrough
              ? drift.Value(paidThrough)
              : const drift.Value.absent(),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
      if (!updated) {
        throw StateError('Unable to update girvi loan before payment entry');
      }

      final paymentId = await _db.into(_db.girviPayments).insert(
            GirviPaymentsCompanion.insert(
              girviId: loanId,
              paymentType: GirviPaymentType.interest.dbValue,
              paymentDate: drift.Value(paymentDate),
              amount: drift.Value(receivedAmount),
              paymentMode: drift.Value(paymentMode.dbValue),
              monthsCovered: drift.Value(resolvedMonthsCovered),
              interestFromDate: drift.Value(resolvedInterestFromDate),
              interestToDate: drift.Value(resolvedInterestToDate),
              balanceAfter: drift.Value(balanceAfter),
              principalComponent: const drift.Value(0),
              interestComponent: drift.Value(interestComponent),
              receiptNo: drift.Value(normalizedReceiptNo),
              notes: drift.Value(normalizedNotes),
            ),
          );
      final customer = await (_db.select(_db.customers)
            ..where((row) => row.id.equals(loan.customerId)))
          .getSingle();
      await GirviFinancialPosting(_db).collection(
        loanId: loanId,
        paymentId: paymentId,
        customerName: customer.name,
        date: paymentDate,
        mode: paymentMode.dbValue,
        principal: 0,
        interest: receivedAmount,
        bankAccountId: bankAccountId,
      );
      return paymentId;
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

  /// Loads several loan ledgers in one query for collection screens.
  Future<Map<int, List<GirviPaymentModel>>> getPaymentModelsForLoans(
    List<int> loanIds,
  ) async {
    if (loanIds.isEmpty) return const {};

    final rows = await (_db.select(_db.girviPayments)
          ..where((payment) => payment.girviId.isIn(loanIds))
          ..orderBy([
            (payment) => drift.OrderingTerm.asc(payment.girviId),
            (payment) => drift.OrderingTerm.desc(payment.paymentDate),
            (payment) => drift.OrderingTerm.desc(payment.id),
          ]))
        .get();

    final result = <int, List<GirviPaymentModel>>{};
    for (final row in rows) {
      result
          .putIfAbsent(row.girviId, () => <GirviPaymentModel>[])
          .add(_mapPayment(row));
    }
    return result;
  }

  Future<double> getTotalPaidForLoan(int loanId) async {
    final payments = await getPaymentsForLoan(loanId);
    return payments.fold<double>(0.0, (s, p) => s + p.amount);
  }
}
