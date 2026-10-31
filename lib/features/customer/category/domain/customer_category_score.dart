import '../../../../models/customer/customer_enums/customer_list_enums.dart';

class CustomerCategoryReason {
  const CustomerCategoryReason(this.label, this.points);

  final String label;
  final int points; // Hundredths of a point.
}

class CustomerCategoryScore {
  const CustomerCategoryScore({
    required this.points,
    required this.category,
    required this.visitCount,
    required this.reasons,
    required this.verifiedSalesContribution,
  });

  final int points;
  final CustomerType category;
  final int visitCount;
  final List<CustomerCategoryReason> reasons;
  final double? verifiedSalesContribution;

  String get formattedPoints => (points / 100).toStringAsFixed(1);
  bool get isProvisional => visitCount < 2;

  String get explanation {
    final buffer = StringBuffer('$formattedPoints/10 • $visitCount visit days');
    if (isProvisional) {
      buffer.write('\nStandard until the second visit day');
    }
    if (verifiedSalesContribution != null) {
      buffer.write('\nVerified sales contribution: '
          '₹${verifiedSalesContribution!.toStringAsFixed(2)}');
    }
    for (final reason in reasons) {
      final delta = (reason.points / 100).toStringAsFixed(1);
      buffer.write('\n${reason.label} '
          '${reason.points > 0 ? '+' : ''}$delta');
    }
    return buffer.toString();
  }
}

class CustomerCategoryFacts {
  const CustomerCategoryFacts({
    this.visitCount = 0,
    this.verifiedSalesContribution,
    this.verifiedSalesRevenue = 0,
    this.verifiedSalesCount = 0,
    this.unverifiedSalesCount = 0,
    this.returnedSalesCount = 0,
    this.customerRequestedReturnCount = 0,
    this.hasVerifiedSalesLoss = false,
    this.hasProfitableHighValueSale = false,
    this.responsibleDiscountCount = 0,
    this.excessiveDiscountCount = 0,
    this.activeDueCount = 0,
    this.overdueDueCount = 0,
    this.onTimeDueSettlements = 0,
    this.lateDueSettlements = 0,
    this.receivedGirviInterest = 0,
    this.overdueGirviCount = 0,
    this.convertedAdvanceCount = 0,
    this.cancelledAdvanceCount = 0,
    this.customerMetalPurchaseCount = 0,
    this.profitablePurchasedMetalResaleCount = 0,
  });

  final int visitCount;
  final double? verifiedSalesContribution;
  final double verifiedSalesRevenue;
  final int verifiedSalesCount;
  final int unverifiedSalesCount;
  final int returnedSalesCount;
  final int customerRequestedReturnCount;
  final bool hasVerifiedSalesLoss;
  final bool hasProfitableHighValueSale;
  final int responsibleDiscountCount;
  final int excessiveDiscountCount;
  final int activeDueCount;
  final int overdueDueCount;
  final int onTimeDueSettlements;
  final int lateDueSettlements;
  final double receivedGirviInterest;
  final int overdueGirviCount;
  final int convertedAdvanceCount;
  final int cancelledAdvanceCount;
  final int customerMetalPurchaseCount;
  final int profitablePurchasedMetalResaleCount;
}
