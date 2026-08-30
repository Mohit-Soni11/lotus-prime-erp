import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_voucher_detail.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/repositories/customer_metal_purchase_ledger_repository.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_report_workspace.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

void main() {
  testWidgets('ledger table hides row checkbox and fine weight column',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CustomerMetalPurchaseLedgerController(
      repository: _FakeCustomerMetalPurchaseLedgerRepository(),
      currentDate: DateTime(2026, 8, 29),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerMetalPurchaseReportBody(
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('S. No.'), findsOneWidget);
    expect(find.text('Net Wt'), findsOneWidget);
    expect(find.text('Fine Wt'), findsNothing);
    expect(find.text('1.000 g'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(DataTable), findsNothing);

    final rowFinder = find.byKey(
      const ValueKey('customer-metal-purchase-ledger-row-1'),
    );
    expect(rowFinder, findsOneWidget);
    expect(find.descendant(of: rowFinder, matching: find.byType(AnimatedScale)),
        findsNothing);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(rowFinder));
    await tester.pump(const Duration(milliseconds: 180));
    final hoveredRowContainer = tester.widget<AnimatedContainer>(
      find.descendant(of: rowFinder, matching: find.byType(AnimatedContainer)),
    );
    expect(
      hoveredRowContainer.transform,
      Matrix4.translationValues(0, -1, 0),
    );
    final hoveredDecoration = hoveredRowContainer.decoration! as BoxDecoration;
    expect(hoveredDecoration.color, Colors.white);
    expect(
      hoveredDecoration.border!.top.color,
      PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.70),
    );
    expect(hoveredDecoration.border!.top.width, 1.5);
    expect(
      hoveredDecoration.boxShadow!.single.color,
      PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.20),
    );
    await gesture.moveTo(const Offset(1915, 755));
    await tester.pump(const Duration(milliseconds: 220));

    final viewPdfButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.picture_as_pdf_rounded),
    );
    expect(viewPdfButton.style?.foregroundColor?.resolve({}), Colors.black);
    expect(viewPdfButton.style?.fixedSize?.resolve({}), const Size(32, 32));
    expect(find.widgetWithIcon(IconButton, Icons.image_rounded), findsWidgets);
    expect(
        find.widgetWithIcon(IconButton, Icons.print_rounded), findsOneWidget);

    await tester.tap(rowFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    expect(find.text('View PDF'), findsOneWidget);
    expect(find.text('View Photo'), findsOneWidget);
    expect(find.text('Download PDF'), findsOneWidget);
    expect(find.text('Print PDF'), findsOneWidget);
    expect(find.text('PDF Style'), findsOneWidget);
    expect(find.text('Fine Weight'), findsNothing);
  });
}

class _FakeCustomerMetalPurchaseLedgerRepository
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
        sourceDocumentId: 11,
        date: DateTime(2026, 8, 28),
        source: 'direct',
        referenceNo: 'AJ-PUR-2026-0006',
        customerName: 'REYANSH SONI',
        metalType: 'GOLD',
        itemDescription: 'Old gold',
        grossWeight: 1,
        netWeight: 1,
        purity: 100,
        fineWeight: 1,
        rate: 15000,
        amount: 15000,
        paidAmount: 15000,
        pendingAmount: 0,
        mobile: '9304479436',
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
