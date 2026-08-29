import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_voucher_detail.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/repositories/customer_metal_purchase_ledger_repository.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_filters/customer_metal_purchase_report_filter_bar.dart';

void main() {
  testWidgets('monthly report filter card removes custom date range',
      (tester) async {
    final controller = CustomerMetalPurchaseLedgerController(
      repository: _FakeCustomerMetalPurchaseLedgerRepository(),
      currentDate: DateTime(2026, 8, 29),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerMetalPurchaseReportFilterBar(controller: controller),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Report Controls'), findsOneWidget);
    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('August'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Custom Range'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Partial'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
  });
}

class _FakeCustomerMetalPurchaseLedgerRepository
    implements CustomerMetalPurchaseLedgerRepository {
  @override
  Future<List<CustomerMetalPurchaseEntry>> fetchLedger({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return const [];
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
