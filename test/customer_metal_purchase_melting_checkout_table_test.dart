import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/melting_checkout/customer_metal_melting_checkout_table.dart';

void main() {
  testWidgets('melting checkout table shows compact ledger status details',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final selected = <String>{'direct|1'};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1900,
            child: CustomerMetalMeltingCheckoutTable(
              entries: [
                _entry(
                  id: 1,
                  referenceNo: 'AJ-PUR-2026-0001',
                  date: DateTime(2026, 9, 1),
                  customerName: 'REYANSH SONI',
                  amount: 72500,
                ),
                _entry(
                  id: 2,
                  referenceNo: 'AJ-PUR-2026-0002',
                  date: DateTime(2026, 9, 2),
                  customerName: 'MOHIT SONI',
                  amount: 64000,
                  isTransferredToMelting: true,
                  transferredToMeltingAt: DateTime(2026, 9, 5, 10, 15),
                  meltingBatchNo: 'CMB-GOLD-20260905-101500',
                ),
              ],
              selectedEntryKeys: selected,
              accent: const Color(0xFFD4A017),
              entryKeyBuilder: (entry) => '${entry.source}|${entry.id}',
              onSelectionToggled: (_) {},
              onCustomerPressed: (_) {},
              onReferencePressed: (_) {},
              onReturnPressed: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Select'), findsOneWidget);
    expect(find.text('S. No.'), findsOneWidget);
    expect(find.text('Voucher No'), findsOneWidget);
    expect(find.text('Purchase Date'), findsOneWidget);
    expect(find.text('Metal Status'), findsOneWidget);
    expect(find.text('Status Date'), findsOneWidget);
    expect(find.text('Batch No'), findsOneWidget);
    expect(find.text('Ready to Melt'), findsOneWidget);
    expect(find.text('Melted & Closed'), findsOneWidget);
    expect(find.text('05 Sep 2026'), findsOneWidget);
    expect(find.text('CMB-GOLD-20260905-101500'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });
}

CustomerMetalPurchaseEntry _entry({
  required int id,
  required String referenceNo,
  required DateTime date,
  required String customerName,
  required double amount,
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
    amount: amount,
    paidAmount: amount,
    pendingAmount: 0,
    mobile: '9304479436',
    isTransferredToMelting: isTransferredToMelting,
    transferredToMeltingAt: transferredToMeltingAt,
    meltingBatchNo: meltingBatchNo,
  );
}
