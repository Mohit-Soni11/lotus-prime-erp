import '../../../../models/customer/customer_enums/customer_list_enums.dart';
import 'customer_category_policy.dart';
import 'customer_category_score.dart';

class CustomerCategoryEngine {
  const CustomerCategoryEngine();

  CustomerCategoryScore evaluate(CustomerCategoryFacts facts) {
    if (facts.visitCount < CustomerCategoryPolicy.minimumVisitsToClassify) {
      return CustomerCategoryScore(
        points: CustomerCategoryPolicy.initialPoints,
        category: CustomerType.standard,
        visitCount: facts.visitCount,
        reasons: const [CustomerCategoryReason('New customer baseline', 0)],
        verifiedSalesContribution: facts.verifiedSalesContribution,
      );
    }

    final reasons = <CustomerCategoryReason>[];
    void add(String label, int points) {
      reasons.add(CustomerCategoryReason(label, points));
    }

    if (facts.visitCount >= 5) {
      add('Five or more visit days', 100);
    } else if (facts.visitCount >= 3) {
      add('Repeat visits', 50);
    }

    final contribution = facts.verifiedSalesContribution;
    if (contribution != null && facts.verifiedSalesCount > 0) {
      if (contribution >= CustomerCategoryPolicy.contributionLevelTwo &&
          facts.verifiedSalesRevenue > 0 &&
          contribution / facts.verifiedSalesRevenue >= 0.10) {
        add('Verified sales contribution and margin', 150);
      } else if (contribution >= CustomerCategoryPolicy.contributionLevelOne) {
        add('Verified sales contribution', 100);
      } else if (contribution > 0) {
        add('Positive verified sales contribution', 50);
      }
    }
    if (facts.hasVerifiedSalesLoss) add('Verified loss on a sale', -100);
    if (facts.unverifiedSalesCount > 0) {
      add('Sales cost missing; margin not scored', 0);
    }
    if (facts.returnedSalesCount > 0) {
      add('Returned sale excluded from margin score', 0);
    }
    if (facts.customerRequestedReturnCount >= 3) {
      add('Three or more customer-requested returns', -50);
    }
    if (facts.hasProfitableHighValueSale) add('Profitable high-value sale', 50);
    if (facts.responsibleDiscountCount > 0) {
      add('Discount within recorded margin', 50);
    }
    if (facts.excessiveDiscountCount > 0) {
      add('Discount consumed most of recorded margin', -50);
    }
    if (facts.onTimeDueSettlements > 0) add('Due paid on time', 50);
    if (facts.lateDueSettlements > 0) {
      add('Due settled after promise date', -150);
    }
    if (facts.activeDueCount > 0) add('Open sales due', -100);
    if (facts.overdueDueCount > 0) add('Overdue sales payment', -150);
    if (facts.receivedGirviInterest > 0) add('Girvi interest received', 50);
    if (facts.overdueGirviCount > 0) add('Overdue Girvi account', -150);
    if (facts.convertedAdvanceCount > 0) add('Advance converted to sale', 50);
    if (facts.cancelledAdvanceCount >= 3) {
      add('Three or more advance cancellations', -150);
    }
    if (facts.customerMetalPurchaseCount > 0) {
      add('Customer metal purchase recorded; resale margin pending', 0);
    }
    if (facts.profitablePurchasedMetalResaleCount > 0) {
      add('Purchased metal resold with verified margin', 50);
    }

    var points = CustomerCategoryPolicy.initialPoints +
        reasons.fold<int>(0, (sum, reason) => sum + reason.points);
    if (facts.activeDueCount > 0 ||
        facts.overdueGirviCount > 0 ||
        facts.cancelledAdvanceCount >= 3) {
      points = points.clamp(
        CustomerCategoryPolicy.minimumPoints,
        CustomerCategoryPolicy.alertRiskCap,
      );
    }
    points = points.clamp(
      CustomerCategoryPolicy.minimumPoints,
      CustomerCategoryPolicy.maximumPoints,
    );
    return CustomerCategoryScore(
      points: points,
      category: points < 500
          ? CustomerType.alert
          : points > 500
              ? CustomerType.elite
              : CustomerType.standard,
      visitCount: facts.visitCount,
      reasons: List.unmodifiable(reasons),
      verifiedSalesContribution: contribution,
    );
  }
}
