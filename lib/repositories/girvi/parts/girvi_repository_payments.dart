part of '../girvi_repository.dart';

extension GirviRepositoryPayments on GirviRepository {
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
        if (receivedAmount >
            loan.loanAmount + GirviRepository._moneyTolerance) {
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
}
