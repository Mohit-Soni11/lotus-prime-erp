import '../../../models/girvi/girvi_enums.dart';
import '../../../models/girvi/girvi_loan_model.dart';

class GirviLedgerBalance {
  const GirviLedgerBalance({
    required this.principalRemaining,
    required this.interestRemaining,
  });

  final double principalRemaining;
  final double interestRemaining;

  double get totalRemaining => principalRemaining + interestRemaining;
}

/// Replays the ledger so each row shows balances at that payment date.
class GirviLedgerBalanceService {
  const GirviLedgerBalanceService._();

  static Map<int, GirviLedgerBalance> calculate(
    GirviLoanWithCustomer account,
    Iterable<GirviPaymentModel> payments,
  ) {
    final ordered = payments.toList()
      ..sort((first, second) {
        final dateOrder = first.paymentDate.compareTo(second.paymentDate);
        return dateOrder != 0 ? dateOrder : first.id.compareTo(second.id);
      });
    final adjustments = <GirviInterestAdjustment>[];
    final balances = <int, GirviLedgerBalance>{};
    var principalRemaining = account.originalPrincipal;

    for (final payment in ordered) {
      final type = payment.type;
      if (type == GirviPaymentType.partialPrincipal) {
        principalRemaining -= payment.amount;
      } else if (type == GirviPaymentType.interest ||
          type == GirviPaymentType.partialInterest) {
        principalRemaining -= payment.principalComponent;
        final hasSplitComponents =
            payment.interestComponent > 0 || payment.principalComponent > 0;
        adjustments.add(GirviInterestAdjustment(
          date: payment.paymentDate,
          paid: hasSplitComponents ? payment.interestComponent : payment.amount,
        ));
      } else if (type == GirviPaymentType.fullRelease) {
        principalRemaining -=
            payment.principalComponent + payment.principalDiscountComponent;
        adjustments.add(GirviInterestAdjustment(
          date: payment.paymentDate,
          paid: payment.interestComponent,
          discount: payment.interestDiscountComponent,
        ));
      }

      final remainingPrincipal =
          principalRemaining.clamp(0.0, double.infinity).toDouble();
      final remainingInterest = type == GirviPaymentType.fullRelease
          ? (payment.balanceAfter - remainingPrincipal)
              .clamp(0.0, double.infinity)
              .toDouble()
          : GirviInterestCalculator.quoteAt(
              principal: account.originalPrincipal,
              monthlyRatePercent: account.loan.interestRate,
              startDate: account.loan.startDate,
              asOf: payment.paymentDate,
              adjustments: adjustments,
            ).interestOutstanding;
      balances[payment.id] = GirviLedgerBalance(
        principalRemaining: remainingPrincipal,
        interestRemaining: remainingInterest,
      );
    }

    return Map.unmodifiable(balances);
  }
}
