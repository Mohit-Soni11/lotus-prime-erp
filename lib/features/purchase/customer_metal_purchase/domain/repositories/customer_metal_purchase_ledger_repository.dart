import '../entities/customer_metal_purchase_entry.dart';
import '../entities/customer_metal_purchase_voucher_detail.dart';

abstract class CustomerMetalPurchaseLedgerRepository {
  Future<List<CustomerMetalPurchaseEntry>> fetchLedger({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<CustomerMetalPurchaseVoucherDetail?> fetchVoucherDetail(int voucherId);

  Future<void> markReturned(CustomerMetalPurchaseEntry entry);

  Future<String> createMeltingBatch({
    required String metalType,
    required List<CustomerMetalPurchaseEntry> entries,
  });
}
