import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_voucher_detail.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/repositories/customer_metal_purchase_ledger_repository.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/screens/customer_metal_purchase_metal_detail_screen.dart';

void main() {
  testWidgets(
      'melting checkout shows all-time available metal, not monthly report only',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _CheckoutRepository();
    final controller = CustomerMetalPurchaseLedgerController(
      repository: repository,
      currentDate: DateTime(2026, 9, 12),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerMetalPurchaseMetalDetailScreen(
          metal: CustomerMetalPurchaseMetal.gold,
          controller: controller,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('AJ-PUR-OLD-2026-0001'), findsOneWidget);
    expect(find.text('AJ-PUR-SEP-2026-0002'), findsOneWidget);
    expect(find.text('OLD MONTH SELLER'), findsOneWidget);
    expect(find.text('CURRENT MONTH SELLER'), findsOneWidget);
    expect(find.text('Select All (2)'), findsOneWidget);

    expect(controller.entries.length, 1);
    expect(controller.entries.single.referenceNo, 'AJ-PUR-SEP-2026-0002');
    expect(repository.allTimeCheckoutFetchCount, greaterThanOrEqualTo(1));
  });

  testWidgets('melting confirmation dialog stays light and readable',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CustomerMetalPurchaseLedgerController(
      repository: _CheckoutRepository(),
      currentDate: DateTime(2026, 9, 12),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerMetalPurchaseMetalDetailScreen(
          metal: CustomerMetalPurchaseMetal.gold,
          controller: controller,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Select All (2)'));
    await tester.pump(const Duration(milliseconds: 180));
    await tester.tap(find.text('Checkout to Melting (2)'));
    await tester.pump(const Duration(milliseconds: 300));

    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.backgroundColor, Colors.white);
    expect(dialog.surfaceTintColor, Colors.transparent);
    expect(find.text('Checkout to Melting'), findsOneWidget);
    expect(find.text('Confirm Checkout'), findsOneWidget);

    final title = tester.widget<Text>(find.text('Checkout to Melting'));
    expect(title.style?.color, Colors.black);
    expect(title.style?.fontWeight, FontWeight.w900);
  });
}

class _CheckoutRepository implements CustomerMetalPurchaseLedgerRepository {
  var allTimeCheckoutFetchCount = 0;

  @override
  Future<List<CustomerMetalPurchaseEntry>> fetchLedger({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final currentMonthEntry = _entry(
      id: 2,
      referenceNo: 'AJ-PUR-SEP-2026-0002',
      date: DateTime(2026, 9, 12),
      customerName: 'CURRENT MONTH SELLER',
    );

    if (startDate != null || endDate != null) {
      return [currentMonthEntry];
    }

    allTimeCheckoutFetchCount++;
    return [
      _entry(
        id: 1,
        referenceNo: 'AJ-PUR-OLD-2026-0001',
        date: DateTime(2026, 7, 18),
        customerName: 'OLD MONTH SELLER',
      ),
      currentMonthEntry,
      _entry(
        id: 3,
        referenceNo: 'AJ-PUR-MELTED-2026-0003',
        date: DateTime(2026, 8, 4),
        customerName: 'CLOSED SELLER',
        isTransferredToMelting: true,
        transferredToMeltingAt: DateTime(2026, 8, 8),
        meltingBatchNo: 'CMB-GOLD-20260808-101500',
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

CustomerMetalPurchaseEntry _entry({
  required int id,
  required String referenceNo,
  required DateTime date,
  required String customerName,
  bool isTransferredToMelting = false,
  DateTime? transferredToMeltingAt,
  String? meltingBatchNo,
}) {
  return CustomerMetalPurchaseEntry(
    id: id,
    customerId: id,
    sourceDocumentId: id,
    date: date,
    source: 'direct',
    referenceNo: referenceNo,
    customerName: customerName,
    metalType: 'GOLD',
    itemDescription: 'Old gold jewellery',
    grossWeight: 10,
    netWeight: 9.5,
    purity: 91.6,
    fineWeight: 8.702,
    rate: 7400,
    amount: 72500,
    paidAmount: 72500,
    pendingAmount: 0,
    mobile: '9304479436',
    isTransferredToMelting: isTransferredToMelting,
    transferredToMeltingAt: transferredToMeltingAt,
    meltingBatchNo: meltingBatchNo,
  );
}
