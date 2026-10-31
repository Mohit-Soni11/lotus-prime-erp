import 'package:drift/drift.dart';

import '../../../../database/db/app_database.dart';
import '../domain/customer_category_engine.dart';
import '../domain/customer_category_policy.dart';
import '../domain/customer_category_score.dart';
import 'customer_due_evidence_store.dart';

part 'customer_category_sales_queries.dart';
part 'customer_category_relationship_queries.dart';

/// Builds category facts in batches. Missing historical costs never become
/// zero-cost profit. Advance cancellations use posted order status.
class CustomerCategoryRepository {
  CustomerCategoryRepository(this._db);

  final AppDatabase _db;
  static const _engine = CustomerCategoryEngine();

  Future<CustomerCategoryScore> scoreFor(int customerId) async {
    final scores = await scoresFor([customerId]);
    return scores[customerId] ??
        _engine.evaluate(const CustomerCategoryFacts());
  }

  /// Synchronizes legacy tier fields for older ERP screens that still read
  /// customers directly. A second refresh does not write unchanged rows.
  Future<void> persistCategories(
    Map<int, CustomerCategoryScore> scores,
  ) async {
    if (scores.isEmpty) return;
    final customers = await (_db.select(_db.customers)
          ..where((row) => row.id.isIn(scores.keys)))
        .get();
    for (final customer in customers) {
      final score = scores[customer.id];
      if (score == null) continue;
      final value = score.category.value;
      if (customer.type == value && customer.customerTier == value) continue;
      await (_db.update(_db.customers)
            ..where((row) => row.id.equals(customer.id)))
          .write(CustomersCompanion(
        type: Value(value),
        customerTier: Value(value),
      ));
    }
  }

  Future<Map<int, CustomerCategoryScore>> scoresFor(
    Iterable<int> customerIds,
  ) async {
    final ids = customerIds.toSet();
    if (ids.isEmpty) return const {};
    final facts = {for (final id in ids) id: _FactsBuilder()};
    final since = DateTime.now()
            .subtract(
                const Duration(days: CustomerCategoryPolicy.reviewWindowDays))
            .millisecondsSinceEpoch ~/
        1000;
    await _db.ensureReturnReversalSchema();
    await CustomerDueEvidenceStore(_db).ensureSchema();

    await Future.wait<void>([
      _loadVisits(facts, since),
      _loadSales(facts, since),
      _loadMetalDiscounts(facts, since),
      _loadGirvi(facts, since),
      _loadAdvances(facts, since),
      _loadCustomerPurchases(facts, since),
      _loadPurchasedMetalResales(facts, since),
      _loadDueEvidence(facts, since),
      _loadCustomerReturns(facts, since),
    ]);

    return {
      for (final entry in facts.entries)
        entry.key: _engine.evaluate(entry.value.build()),
    };
  }

  double _number(QueryRow row, String column) =>
      (row.data[column] as num).toDouble();
}

class _FactsBuilder {
  int visits = 0;
  double verifiedContribution = 0;
  double verifiedRevenue = 0;
  int verifiedSales = 0;
  int unverifiedSales = 0;
  int returnedSales = 0;
  int customerRequestedReturns = 0;
  bool hasSalesLoss = false;
  bool hasHighValueSale = false;
  int responsibleDiscounts = 0;
  int excessiveDiscounts = 0;
  int activeDues = 0;
  int overdueDues = 0;
  int onTimeSettlements = 0;
  int lateSettlements = 0;
  double receivedInterest = 0;
  int overdueGirvi = 0;
  int convertedAdvances = 0;
  int cancelledAdvances = 0;
  int customerPurchases = 0;
  int profitableResales = 0;

  CustomerCategoryFacts build() => CustomerCategoryFacts(
        visitCount: visits,
        verifiedSalesContribution:
            verifiedSales > 0 ? verifiedContribution : null,
        verifiedSalesRevenue: verifiedRevenue,
        verifiedSalesCount: verifiedSales,
        unverifiedSalesCount: unverifiedSales,
        returnedSalesCount: returnedSales,
        customerRequestedReturnCount: customerRequestedReturns,
        hasVerifiedSalesLoss: hasSalesLoss,
        hasProfitableHighValueSale: hasHighValueSale,
        responsibleDiscountCount: responsibleDiscounts,
        excessiveDiscountCount: excessiveDiscounts,
        activeDueCount: activeDues,
        overdueDueCount: overdueDues,
        onTimeDueSettlements: onTimeSettlements,
        lateDueSettlements: lateSettlements,
        receivedGirviInterest: receivedInterest,
        overdueGirviCount: overdueGirvi,
        convertedAdvanceCount: convertedAdvances,
        cancelledAdvanceCount: cancelledAdvances,
        customerMetalPurchaseCount: customerPurchases,
        profitablePurchasedMetalResaleCount: profitableResales,
      );
}
