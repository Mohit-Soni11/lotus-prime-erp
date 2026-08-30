import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_voucher_detail.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/repositories/customer_metal_purchase_ledger_repository.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_navigation/customer_metal_purchase_report_command_strip.dart';

void main() {
  testWidgets('report command strip shows tabs and updates selected tab',
      (tester) async {
    final controller = CustomerMetalPurchaseLedgerController(
      repository: _FakeCustomerMetalPurchaseLedgerRepository(),
      currentDate: DateTime(2026, 8, 29),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: CustomerMetalPurchaseReportCommandStrip(
              controller: controller,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ledger'), findsOneWidget);
    expect(find.text('Metal Summary'), findsOneWidget);
    expect(find.text('Seller Summary'), findsOneWidget);
    expect(find.text('Pending Payout'), findsOneWidget);
    expect(find.text('Payment Summary'), findsOneWidget);
    expect(find.text('Print Report'), findsOneWidget);
    expect(controller.selectedTab, CustomerMetalPurchaseReportTab.ledger);

    await tester.tap(find.text('Seller Summary'));
    await tester.pumpAndSettle();

    expect(
        controller.selectedTab, CustomerMetalPurchaseReportTab.sellerSummary);
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
