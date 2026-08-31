import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_transaction_summary.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/repositories/return_reversal_repository.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/screens/return_reversal_desk_screen.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/widgets/summary/return_reversal_invoice_summary_panel.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/widgets/workflow/return_reversal_workflow_tabs.dart';

void main() {
  testWidgets('Return Reversal Desk opens with the ERP module app bar',
      (tester) async {
    var backPressed = false;
    final controller = ReturnReversalController(
      repository: _TestReturnReversalRepository(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ReturnReversalDeskScreen(
          onBack: () => backPressed = true,
          controller: controller,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('Return & Reversal Desk'), findsOneWidget);
    expect(find.text('SYSTEM ONLINE'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_return_rounded), findsOneWidget);
    expect(find.text('RETURN SETUP'), findsOneWidget);
    expect(find.text('DESK READY'), findsOneWidget);
    expect(find.text('RETURN'), findsOneWidget);
    expect(find.text('CANCELLATION'), findsOneWidget);
    expect(find.text('DOCUMENT NUMBER'), findsOneWidget);
    expect(find.text('INVOICE NO.'), findsOneWidget);
    expect(find.text('VOUCHER NO.'), findsNothing);
    expect(find.text('NOT SELECTED'), findsOneWidget);
    expect(find.text('CUSTOMER DETAILS'), findsOneWidget);
    expect(find.text('INVOICE NUMBER'), findsOneWidget);
    expect(find.text('MOBILE'), findsOneWidget);
    expect(find.text('CUSTOMER NAME'), findsOneWidget);
    expect(find.text('ADDRESS'), findsOneWidget);
    expect(find.text('INVOICE ITEMS'), findsOneWidget);
    expect(find.text('NO INVOICE SELECTED'), findsOneWidget);
    expect(find.text('LOAD INVOICE ITEMS'), findsOneWidget);
    expect(find.text('RETURN WORKFLOW'), findsOneWidget);
    expect(find.text('Invoice Items'), findsWidgets);
    expect(find.text('Verification'), findsOneWidget);
    expect(find.text('Weight Check'), findsOneWidget);
    expect(find.text('Stock Routing'), findsOneWidget);
    expect(find.text('HUID matched'), findsNothing);
    expect(find.text('INVOICE SUMMARY'), findsOneWidget);
    expect(find.text('Return Value'), findsOneWidget);
    expect(find.text('Process Return'), findsOneWidget);
    expect(find.text('RETURN NO.'), findsNothing);
    expect(find.text('CANCELLATION NO.'), findsNothing);
    expect(find.text('PAN'), findsNothing);
    expect(find.text('Sales Return'), findsNothing);
    expect(find.text('Booking Cancellation'), findsNothing);
    expect(find.text('Under Construction'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(backPressed, isTrue);
  });

  testWidgets('Return Reversal Desk shell stays usable in a narrow window',
      (tester) async {
    tester.view.physicalSize = const Size(430, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ReturnReversalController(
      repository: _TestReturnReversalRepository(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ReturnReversalDeskScreen(
          onBack: () {},
          controller: controller,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('Return & Reversal Desk'), findsOneWidget);
    expect(find.text('RETURN'), findsOneWidget);
    expect(find.text('CANCELLATION'), findsOneWidget);
    expect(find.text('DOCUMENT NUMBER'), findsOneWidget);
    expect(find.text('INVOICE NO.'), findsOneWidget);
    expect(find.text('VOUCHER NO.'), findsNothing);
    expect(find.text('NOT SELECTED'), findsOneWidget);
    expect(find.text('CUSTOMER DETAILS'), findsOneWidget);
    expect(find.text('INVOICE NUMBER'), findsOneWidget);
    expect(find.text('INVOICE ITEMS'), findsOneWidget);
    expect(find.text('INVOICE SUMMARY'), findsOneWidget);
    expect(find.text('Find Transaction'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Return Reversal operation setup updates selected workflow',
      (tester) async {
    final controller = ReturnReversalController(
      repository: _TestReturnReversalRepository(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ReturnReversalDeskScreen(
          onBack: () {},
          controller: controller,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    expect(
      controller.state.operationType,
      ReturnReversalOperationType.salesReturn,
    );

    await tester.tap(find.text('CANCELLATION'));
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      controller.state.operationType,
      ReturnReversalOperationType.bookingCancellation,
    );
    expect(find.text('BOOKING NO.'), findsOneWidget);
    expect(find.text('ADVANCE VOUCHER'), findsNothing);
    expect(find.text('BOOKING NUMBER'), findsOneWidget);
    expect(find.text('BOOKING ITEMS'), findsOneWidget);
    expect(find.text('NO BOOKING SELECTED'), findsOneWidget);
    expect(find.text('LOAD BOOKING ITEMS'), findsOneWidget);
    expect(find.text('Return Value'), findsOneWidget);
    expect(find.text('Process Cancellation'), findsOneWidget);
    expect(find.text('INVOICE NUMBER'), findsNothing);
    expect(find.text('RETURN NO.'), findsNothing);
    expect(find.text('CANCELLATION NO.'), findsNothing);
  });

  testWidgets('source number search loads customer and invoice items',
      (tester) async {
    final controller = ReturnReversalController(
      repository: _TestReturnReversalRepository(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ReturnReversalDeskScreen(
          onBack: () {},
          controller: controller,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    controller.sourceDocumentNumberCtrl.text = 'AJ-PUR-2026-0006';
    await controller.searchRecords();
    await tester.pump();

    expect(controller.customerMobileCtrl.text, '9304479436');
    expect(controller.customerNameCtrl.text, 'REYANSH SONI');
    expect(find.text('LOADED : AJ-PUR-2026-0006'), findsOneWidget);
    expect(find.text('Silver Payal'), findsWidgets);
    expect(find.text('RETURN : 1'), findsOneWidget);
    expect(find.text('METAL'), findsOneWidget);
    expect(find.text('ITEM DESCRIPTION'), findsOneWidget);
    expect(find.text('UNIT'), findsNothing);
    expect(find.text('HUID / SET'), findsOneWidget);
    expect(find.text('PURITY'), findsOneWidget);
    expect(find.text('GR. WT'), findsNothing);
    expect(find.text('LESS'), findsNothing);
    expect(find.text('MAKING'), findsOneWidget);
    expect(find.text('TOTAL'), findsWidgets);
    expect(find.text('PAIR'), findsOneWidget);
    expect(find.text('12%'), findsOneWidget);
    expect(find.text('DISCOUNT'), findsNothing);
    expect(find.text('ACT'), findsNothing);
    expect(find.text('HUID123456'), findsWidgets);
    expect(find.text('PUR-SILVER-001'), findsNothing);
    expect(find.text('Rs 1,587'), findsWidgets);
    expect(find.text('Rs 19,590'), findsWidgets);
    expect(find.text('Rs 20,178'), findsOneWidget);
    expect(find.text('ORIGINAL INVOICE'), findsOneWidget);
    expect(find.text('SILVER'), findsWidgets);
    expect(find.text('Silver Value'), findsOneWidget);
    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('Taxable Value'), findsOneWidget);
    expect(find.text('GST (3%)'), findsOneWidget);
    expect(find.text('Silver Total'), findsOneWidget);
    expect(find.text('PAYMENT METHOD'), findsOneWidget);
    expect(find.text('Cash Rs 5,000'), findsOneWidget);
    expect(find.text('UPI Rs 10,000'), findsOneWidget);
    expect(find.text('Collected'), findsOneWidget);
    expect(find.text('Balance Due'), findsOneWidget);
    expect(find.text('SELECTED RETURN'), findsOneWidget);
    expect(find.text('Metal Amount'), findsOneWidget);
    expect(find.text('Making Available'), findsOneWidget);
    expect(find.text('Making Returned'), findsOneWidget);
    expect(find.text('Return Value'), findsOneWidget);
    expect(find.text('Rs 18,003'), findsWidgets);
    expect(find.text('HUID matched'), findsOneWidget);
    expect(find.text('Unit matched'), findsOneWidget);
    expect(find.text('Received Net Weight'), findsOneWidget);
    expect(find.text('Metal Value Only'), findsOneWidget);
    expect(find.text('Metal + Making'), findsOneWidget);
    expect(find.text('This Item Return'), findsOneWidget);
    expect(find.text('Add Stock'), findsOneWidget);
    expect(find.text('Melting'), findsOneWidget);
    expect(find.text('Selected Discount'), findsNothing);
    expect(find.text('Selected GST'), findsNothing);
    expect(find.text('1 / 1 selected'), findsOneWidget);
    expect(find.text('DUE 2.0K'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    controller.setLineMakingReturn(1, true);
    await tester.pump();

    expect(controller.state.activeInspectionDraft?.includeMakingCharge, isTrue);

    controller.toggleSourceLineSelection(1);
    await tester.pump();

    expect(find.text('0 / 1 selected'), findsOneWidget);
    expect(find.text('Rs 0'), findsWidgets);
  });

  testWidgets('keyboard arrow keys move between visible source documents',
      (tester) async {
    final controller = ReturnReversalController(
      repository: _TestReturnReversalRepository(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ReturnReversalDeskScreen(
          onBack: () {},
          controller: controller,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    controller.customerMobileCtrl.text = '9304479436';
    await controller.searchRecords();
    await tester.pump();
    await tester.pump();

    expect(controller.sourceDocumentNumberCtrl.text, 'AJ-PUR-2026-0006');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(controller.sourceDocumentNumberCtrl.text, 'AJ-PUR-2026-0007');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(controller.sourceDocumentNumberCtrl.text, 'AJ-PUR-2026-0006');
  });

  testWidgets('invoice summary scrolls inside a bounded desktop rail',
      (tester) async {
    final controller = ReturnReversalController(
      repository: _TestReturnReversalRepository(),
    );
    addTearDown(controller.dispose);

    controller.sourceDocumentNumberCtrl.text = 'AJ-PUR-2026-0006';
    await controller.searchRecords();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              width: 560,
              height: 520,
              child: ReturnReversalInvoiceSummaryPanel(
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('INVOICE SUMMARY'), findsOneWidget);
    expect(find.text('ORIGINAL INVOICE'), findsOneWidget);
    expect(find.text('SELECTED RETURN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('return workflow fits weight metrics and wraps stage chips',
      (tester) async {
    tester.view.physicalSize = const Size(1180, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ReturnReversalController(
      repository: _TestReturnReversalRepository(),
    );
    addTearDown(controller.dispose);

    controller.sourceDocumentNumberCtrl.text = 'AJ-PUR-2026-0006';
    await controller.searchRecords();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: 930,
              child: ReturnReversalWorkflowTabs(controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('RETURN WORKFLOW'), findsOneWidget);
    expect(find.text('Received Net Weight'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestReturnReversalRepository implements ReturnReversalRepository {
  static final _invoice = ReturnReversalSourceDocument(
    id: 1,
    type: ReturnReversalSourceDocumentType.salesInvoice,
    documentNo: 'AJ-PUR-2026-0006',
    customerName: 'REYANSH SONI',
    mobile: '9304479436',
    address: 'Patna',
    documentDate: DateTime(2026, 8, 28),
    grossValue: 19590,
    discountAmount: 250,
    taxableAmount: 19019,
    cgstAmount: 285.5,
    sgstAmount: 285.5,
    gstAmount: 571,
    makingTotal: 1587,
    finalAmount: 19911,
    paidAmount: 15000,
    cashPaid: 5000,
    upiPaid: 10000,
    dueAmount: 2000,
    netWeight: 1,
    lineItems: const [
      ReturnReversalSourceLineItem(
        lineNo: 1,
        metalType: 'SILVER',
        description: 'Silver Payal',
        hsnCode: '71131120',
        purity: '60',
        quantity: 1,
        quantityUnitCode: 'PAIR',
        grossWeight: 79.361,
        lessWeight: 0,
        netWeight: 79.361,
        fineWeight: 47.617,
        rate: 220,
        makingChargeType: 'PERCENTAGE',
        makingChargeInput: 12,
        makingAmount: 1587,
        discountAmount: 250,
        taxableAmount: 19019,
        gstAmount: 571,
        invoiceValue: 20178,
        value: 19590,
        huidNumber: 'HUID123456',
        linkedStockSku: 'PUR-SILVER-001',
        status: 'ACTIVE',
      ),
    ],
  );

  static final _secondInvoice = ReturnReversalSourceDocument(
    id: 2,
    type: ReturnReversalSourceDocumentType.salesInvoice,
    documentNo: 'AJ-PUR-2026-0007',
    customerName: 'REYANSH SONI',
    mobile: '9304479436',
    address: 'Patna',
    documentDate: DateTime(2026, 8, 29),
    grossValue: 12000,
    paidAmount: 12000,
    dueAmount: 0,
    netWeight: 0.8,
    lineItems: const [
      ReturnReversalSourceLineItem(
        lineNo: 1,
        metalType: 'GOLD',
        description: 'Gold Chain',
        quantity: 1,
        grossWeight: 0.8,
        netWeight: 0.8,
        rate: 12000,
        value: 12000,
        status: 'ACTIVE',
      ),
    ],
  );

  @override
  Future<ReturnReversalTransactionSummary> fetchTransactionSummary() async {
    return const ReturnReversalTransactionSummary.empty();
  }

  @override
  Future<ReturnReversalLookupResult> findCustomerHistoryByMobile(
    String mobile,
  ) async {
    return ReturnReversalLookupResult(
      salesInvoices:
          mobile == '9304479436' ? [_invoice, _secondInvoice] : const [],
      advanceBookings: const [],
      customerPurchases: const [],
    );
  }

  @override
  Future<ReturnReversalSourceDocument?> findSourceDocumentByNumber(
    String documentNumber,
  ) async {
    return documentNumber == _invoice.documentNo ? _invoice : null;
  }
}
