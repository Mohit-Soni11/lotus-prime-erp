import '../../database/db/app_database.dart';
import '../../logic/girvi/girvi_notice_eligibility.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_loan_model.dart';
import 'girvi_repository.dart';

/// Rechecks account state inside the action transaction, after the UI quote.
class GirviNoticeAccountGuard {
  GirviNoticeAccountGuard(AppDatabase db) : _loans = GirviRepository(db);

  final GirviRepository _loans;

  Future<void> requireOutstanding(int girviId, DateTime asOf,
      {bool requireMaturity = false}) async {
    final accounts = await _loans.getLoansWithCustomer(loanId: girviId);
    if (accounts.length != 1) {
      throw StateError('The pledge account was not found.');
    }
    final account = accounts.single;
    final status = account.loan.girviStatus;
    if (status.isClosed || status == GirviStatus.readyForDelivery) {
      throw StateError('An open pledge account is required.');
    }
    final quote = account.interestQuoteAt(asOf);
    if (!quote.totalPayable.isFinite || quote.totalPayable <= 0.01) {
      throw StateError('This pledge account has no outstanding balance.');
    }
    if (!requireMaturity) return;
    final maturity = account.loan.maturityDate ??
        GirviLoanModel.addChargeableMonths(
          account.loan.startDate,
          account.loan.durationMonths,
        );
    if (!GirviNoticeEligibility.hasMaturedBalance(
      status: status,
      maturityDate: maturity,
      principalDue: account.principalDue,
      interestDue: quote.interestOutstanding,
      asOf: asOf,
    )) {
      throw StateError('The pledge account is not eligible for notice.');
    }
  }
}
