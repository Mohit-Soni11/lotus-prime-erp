part of '../girvi_repository.dart';

extension GirviRepositoryStatusSync on GirviRepository {
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
}
