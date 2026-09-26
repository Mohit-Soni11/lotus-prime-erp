part of '../girvi_repository.dart';

extension GirviRepositoryStatusSync on GirviRepository {
  static const int releasedLoanRetentionDays = 30;

  Future<int> purgeExpiredReleasedLoans({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final cutoff = today.subtract(
      const Duration(days: releasedLoanRetentionDays),
    );
    final releasedLoans = await (_db.select(_db.girviLoans)
          ..where((loan) => loan.status.equals(GirviStatus.released.dbValue)))
        .get();
    final expiredLoanIds = releasedLoans
        .where((loan) => _releasedAtForRetention(loan).isBefore(cutoff))
        .map((loan) => loan.id)
        .toList(growable: false);
    if (expiredLoanIds.isEmpty) return 0;

    await _db.transaction(() async {
      final pledgedItems = await (_db.select(_db.girviLoanItems)
            ..where((item) => item.girviId.isIn(expiredLoanIds)))
          .get();
      final pledgedItemIds =
          pledgedItems.map((item) => item.id).toList(growable: false);
      if (pledgedItemIds.isNotEmpty) {
        await (_db.delete(_db.girviItemPhotos)
              ..where((photo) => photo.itemId.isIn(pledgedItemIds)))
            .go();
      }
      await (_db.delete(_db.girviPayments)
            ..where((payment) => payment.girviId.isIn(expiredLoanIds)))
          .go();
      await (_db.delete(_db.girviDisbursements)
            ..where((entry) => entry.girviId.isIn(expiredLoanIds)))
          .go();
      await (_db.delete(_db.girviNoticeActions)
            ..where((entry) => entry.girviId.isIn(expiredLoanIds)))
          .go();
      await (_db.delete(_db.girviLoanItems)
            ..where((item) => item.girviId.isIn(expiredLoanIds)))
          .go();
      await (_db.delete(_db.girviLoans)
            ..where((loan) => loan.id.isIn(expiredLoanIds)))
          .go();
    });

    AppLogger.debug(
      'GirviRepository: ${expiredLoanIds.length} released loans purged '
      'after $releasedLoanRetentionDays days.',
    );
    return expiredLoanIds.length;
  }

  DateTime _releasedAtForRetention(GirviLoan loan) {
    return loan.deliveredAt ??
        loan.releaseDate ??
        loan.updatedAt ??
        loan.createdAt;
  }

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
      AppLogger.debug('GirviRepository: $updated loans marked overdue.');
    }
    return updated;
  }

  Future<int> syncSettlementStatus() async {
    const tolerance = 0.01;
    await _repairUnallocatedInterestCredits();
    final openLoans = await (_db.select(_db.girviLoans)
          ..where(
            (loan) =>
                loan.status.equals(GirviStatus.active.dbValue) |
                loan.status.equals(GirviStatus.overdue.dbValue) |
                loan.status.equals(GirviStatus.partialRelease.dbValue),
          ))
        .get();
    if (openLoans.isEmpty) return 0;

    final interestType = await _loadInterestCalculationType();
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
          final hasSplitComponents =
              payment.interestComponent > 0 || payment.principalComponent > 0;
          interestPaid +=
              hasSplitComponents ? payment.interestComponent : payment.amount;
          legacyPrincipalRepaid += payment.principalComponent;
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
      final grossInterest = GirviLoanModel.calculateInterest(
        principal: originalPrincipal,
        monthlyRatePercent: loan.interestRate,
        months: interestMonths,
        interestType: interestType,
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

  Future<int> _repairUnallocatedInterestCredits() async {
    final openLoans = await (_db.select(_db.girviLoans)
          ..where(
            (loan) =>
                loan.status.equals(GirviStatus.active.dbValue) |
                loan.status.equals(GirviStatus.overdue.dbValue) |
                loan.status.equals(GirviStatus.partialRelease.dbValue),
          ))
        .get();
    if (openLoans.isEmpty) return 0;

    var repairedCount = 0;
    for (final loan in openLoans) {
      final payments = await (_db.select(_db.girviPayments)
            ..where((payment) => payment.girviId.equals(loan.id))
            ..orderBy([
              (payment) => drift.OrderingTerm.asc(payment.paymentDate),
              (payment) => drift.OrderingTerm.asc(payment.id),
            ]))
          .get();
      if (payments.isEmpty) continue;

      final updates =
          <({GirviPayment payment, double interest, double balance})>[];

      for (final payment in payments) {
        final type = GirviPaymentType.fromDb(payment.paymentType);
        if (type == GirviPaymentType.partialPrincipal) {
          continue;
        }
        if (type == GirviPaymentType.fullRelease) {
          continue;
        }
        if (type != GirviPaymentType.interest &&
            type != GirviPaymentType.partialInterest) {
          continue;
        }

        final hasSplitComponents =
            payment.interestComponent > 0 || payment.principalComponent > 0;
        if (hasSplitComponents) {
          continue;
        }

        final canRepairAsAdvance = payment.monthsCovered == null &&
            payment.interestFromDate == null &&
            payment.interestToDate == null;
        if (!canRepairAsAdvance) {
          continue;
        }

        final interestComponent = _normalizeMoney(payment.amount);
        updates.add((
          payment: payment,
          interest: interestComponent,
          balance: _normalizeMoney(loan.loanAmount),
        ));
      }

      if (updates.isEmpty) continue;
      await _db.transaction(() async {
        for (final update in updates) {
          await (_db.update(_db.girviPayments)
                ..where((payment) => payment.id.equals(update.payment.id)))
              .write(
            GirviPaymentsCompanion(
              principalComponent: const drift.Value(0),
              interestComponent: drift.Value(update.interest),
              balanceAfter: drift.Value(update.balance),
              updatedAt: drift.Value(DateTime.now()),
            ),
          );
        }
      });
      repairedCount += updates.length;
    }

    return repairedCount;
  }
}
