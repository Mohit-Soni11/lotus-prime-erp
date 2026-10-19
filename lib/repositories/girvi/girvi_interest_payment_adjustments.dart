import '../../database/db/app_database.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_interest_calculator.dart';

/// Converts recorded interest allocations into the dated financial timeline.
class GirviInterestPaymentAdjustments {
  const GirviInterestPaymentAdjustments._();

  static List<GirviInterestAdjustment> fromPayments(
    Iterable<GirviPayment> payments,
  ) =>
      List.unmodifiable(
        payments.map(fromPayment).whereType<GirviInterestAdjustment>(),
      );

  static GirviInterestAdjustment? fromPayment(GirviPayment payment) {
    final type = GirviPaymentType.fromDb(payment.paymentType);
    if (type == GirviPaymentType.fullRelease) {
      return GirviInterestAdjustment(
        date: payment.paymentDate,
        paid: payment.interestComponent,
        discount: payment.interestDiscountComponent,
      );
    }
    if (type != GirviPaymentType.interest &&
        type != GirviPaymentType.partialInterest) {
      return null;
    }
    final hasSplitComponents =
        payment.interestComponent > 0 || payment.principalComponent > 0;
    return GirviInterestAdjustment(
      date: payment.paymentDate,
      paid: hasSplitComponents ? payment.interestComponent : payment.amount,
    );
  }
}
