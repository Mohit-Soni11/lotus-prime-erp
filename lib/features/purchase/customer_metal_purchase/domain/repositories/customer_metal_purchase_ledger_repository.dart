import '../entities/customer_metal_purchase_entry.dart';

abstract class CustomerMetalPurchaseLedgerRepository {
  Future<List<CustomerMetalPurchaseEntry>> fetchLedger({
    DateTime? startDate,
    DateTime? endDate,
  });
}
