import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_voucher_detail.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/repositories/customer_metal_purchase_ledger_repository.dart';

void main() {
  test('metal drilldown keeps monthly melted entries and hides empty metals',
      () async {
    final controller = CustomerMetalPurchaseLedgerController(
      repository: _MetalSummaryRepository(),
      currentDate: DateTime(2026, 9, 12),
    );
    addTearDown(controller.dispose);
    await controller.fetchData();

    final summaries = controller.visibleMetalSummaries;

    expect(summaries.keys, [CustomerMetalPurchaseMetal.gold]);
    expect(summaries[CustomerMetalPurchaseMetal.gold]!.entryCount, 1);
    expect(summaries[CustomerMetalPurchaseMetal.gold]!.voucherCount, 1);
    expect(summaries[CustomerMetalPurchaseMetal.gold]!.amount, 25000);
    expect(summaries.containsKey(CustomerMetalPurchaseMetal.silver), isFalse);
    expect(controller.filteredEntries.single.metalFlowStatusLabel,
        'Melted & Closed');
  });

  test('metal drilldown cards are not removed by selected metal filter',
      () async {
    final controller = CustomerMetalPurchaseLedgerController(
      repository: _MetalSummaryRepository(),
      currentDate: DateTime(2026, 9, 12),
    );
    addTearDown(controller.dispose);
    await controller.fetchData();

    controller.selectMetal(CustomerMetalPurchaseMetal.silver);

    expect(controller.filteredEntries, isEmpty);
    expect(controller.dashboardSummary.voucherCount, 0);
    expect(controller.reportScopeDashboardSummary.voucherCount, 1);
    expect(
      controller.visibleMetalSummaries.keys,
      [CustomerMetalPurchaseMetal.gold],
    );
  });

  test('checkout report filter shows only melted checkout entries', () async {
    final controller = CustomerMetalPurchaseLedgerController(
      repository: _CheckoutFilterRepository(),
      currentDate: DateTime(2026, 9, 12),
    );
    addTearDown(controller.dispose);
    await controller.fetchData();

    controller.setPaymentStatusFilter('CHECKOUT');

    expect(controller.filteredEntries, hasLength(1));
    expect(controller.filteredEntries.single.referenceNo, 'AJ-PUR-2026-0001');
    expect(
      controller.filteredEntries.single.metalFlowStatusLabel,
      'Melted & Closed',
    );
  });

  test('pending filter includes unpaid and part-paid payout records', () async {
    final controller = CustomerMetalPurchaseLedgerController(
      repository: _CheckoutFilterRepository(),
      currentDate: DateTime(2026, 9, 12),
    );
    addTearDown(controller.dispose);
    await controller.fetchData();

    controller.setPaymentStatusFilter('PENDING');

    expect(controller.filteredEntries.map((entry) => entry.referenceNo), [
      'AJ-PUR-2026-0002',
      'AJ-PUR-2026-0003',
    ]);
  });
}

class _MetalSummaryRepository implements CustomerMetalPurchaseLedgerRepository {
  @override
  Future<List<CustomerMetalPurchaseEntry>> fetchLedger({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return [
      CustomerMetalPurchaseEntry(
        id: 1,
        customerId: 1,
        sourceDocumentId: 1,
        date: DateTime(2026, 9, 3),
        source: 'direct',
        referenceNo: 'AJ-PUR-2026-0001',
        customerName: 'REYANSH SONI',
        metalType: 'GOLD',
        itemDescription: 'Old gold ring',
        grossWeight: 4,
        netWeight: 3.8,
        purity: 91.6,
        fineWeight: 3.481,
        rate: 7182.42,
        amount: 25000,
        paidAmount: 25000,
        pendingAmount: 0,
        isTransferredToMelting: true,
        transferredToMeltingAt: DateTime(2026, 9, 8),
        meltingBatchNo: 'CMB-GOLD-20260908-120000',
      ),
    ];
  }

  @override
  Future<CustomerMetalPurchaseVoucherDetail?> fetchVoucherDetail(
    int voucherId,
  ) async {
    return null;
  }

  @override
  Future<void> markReturned(CustomerMetalPurchaseEntry entry) async {}

  @override
  Future<String> createMeltingBatch({
    required String metalType,
    required List<CustomerMetalPurchaseEntry> entries,
  }) async {
    return 'CMB-TEST';
  }
}

class _CheckoutFilterRepository
    implements CustomerMetalPurchaseLedgerRepository {
  @override
  Future<List<CustomerMetalPurchaseEntry>> fetchLedger({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return [
      CustomerMetalPurchaseEntry(
        id: 1,
        customerId: 1,
        sourceDocumentId: 1,
        date: DateTime(2026, 9, 3),
        source: 'direct',
        referenceNo: 'AJ-PUR-2026-0001',
        customerName: 'REYANSH SONI',
        metalType: 'GOLD',
        itemDescription: 'Old gold ring',
        grossWeight: 4,
        netWeight: 3.8,
        purity: 91.6,
        fineWeight: 3.481,
        rate: 7182.42,
        amount: 25000,
        paidAmount: 25000,
        pendingAmount: 0,
        isTransferredToMelting: true,
        transferredToMeltingAt: DateTime(2026, 9, 8),
        meltingBatchNo: 'CMB-GOLD-20260908-120000',
      ),
      CustomerMetalPurchaseEntry(
        id: 2,
        customerId: 1,
        sourceDocumentId: 2,
        date: DateTime(2026, 9, 4),
        source: 'direct',
        referenceNo: 'AJ-PUR-2026-0002',
        customerName: 'REYANSH SONI',
        metalType: 'SILVER',
        itemDescription: 'Old silver chain',
        grossWeight: 30,
        netWeight: 30,
        purity: 60,
        fineWeight: 18,
        rate: 110,
        amount: 3300,
        paidAmount: 0,
        pendingAmount: 3300,
      ),
      CustomerMetalPurchaseEntry(
        id: 3,
        customerId: 2,
        sourceDocumentId: 3,
        date: DateTime(2026, 9, 5),
        source: 'direct',
        referenceNo: 'AJ-PUR-2026-0003',
        customerName: 'MOHIT SONI',
        metalType: 'GOLD',
        itemDescription: 'Old gold chain',
        grossWeight: 2,
        netWeight: 2,
        purity: 75,
        fineWeight: 1.5,
        rate: 7000,
        amount: 14000,
        paidAmount: 5000,
        pendingAmount: 9000,
      ),
    ];
  }

  @override
  Future<CustomerMetalPurchaseVoucherDetail?> fetchVoucherDetail(
    int voucherId,
  ) async {
    return null;
  }

  @override
  Future<void> markReturned(CustomerMetalPurchaseEntry entry) async {}

  @override
  Future<String> createMeltingBatch({
    required String metalType,
    required List<CustomerMetalPurchaseEntry> entries,
  }) async {
    return 'CMB-TEST';
  }
}
