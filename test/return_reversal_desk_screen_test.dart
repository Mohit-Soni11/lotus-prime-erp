import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_line_inspection.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_process.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_transaction_summary.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/repositories/return_reversal_repository.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/screens/return_reversal_desk_screen.dart';
import 'package:lotus_erp/features/sales/return_reversal/presentation/widgets/customer/return_reversal_customer_details_card.dart';
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
    expect(find.text('Sales return and purchase return'), findsOneWidget);
    expect(find.text('DESK READY'), findsOneWidget);
    expect(find.text('RETURN'), findsOneWidget);
    expect(find.text('CANCELLATION'), findsOneWidget);
    expect(find.text('Sales + Purchase'), findsOneWidget);
    expect(find.text('Booking only'), findsOneWidget);
    expect(find.text('DOCUMENT NUMBER'), findsOneWidget);
    expect(find.text('SOURCE NO.'), findsOneWidget);
    expect(find.text('VOUCHER NO.'), findsNothing);
    expect(find.text('NOT SELECTED'), findsOneWidget);
    expect(find.text('CUSTOMER DETAILS'), findsOneWidget);
    expect(find.text('SOURCE NUMBER'), findsOneWidget);
    expect(find.text('MOBILE'), findsOneWidget);
    expect(find.text('CUSTOMER NAME'), findsOneWidget);
    expect(find.text('ADDRESS'), findsOneWidget);
    expect(find.text('INVOICE ITEMS'), findsNothing);
    expect(find.text('NO INVOICE SELECTED'), findsNothing);
    expect(find.text('LOAD INVOICE ITEMS'), findsNothing);
    expect(find.text('RETURN WORKFLOW'), findsOneWidget);
    expect(find.text('Invoice Items'), findsWidgets);
    expect(find.text('Verification'), findsOneWidget);
    expect(find.text('Weight Check'), findsOneWidget);
    expect(find.text('Stock Routing'), findsOneWidget);
    expect(find.text('HUID matched'), findsNothing);
    expect(find.text('RETURN SETTLEMENT'), findsOneWidget);
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
    expect(find.text('SOURCE NO.'), findsOneWidget);
    expect(find.text('VOUCHER NO.'), findsNothing);
    expect(find.text('NOT SELECTED'), findsOneWidget);
    expect(find.text('CUSTOMER DETAILS'), findsOneWidget);
    expect(find.text('SOURCE NUMBER'), findsOneWidget);
    expect(find.text('RETURN WORKFLOW'), findsOneWidget);
    expect(find.text('INVOICE ITEMS'), findsNothing);
    expect(find.text('RETURN SETTLEMENT'), findsOneWidget);
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
    expect(find.text('CANCELLATION SETUP'), findsOneWidget);
    expect(find.text('BOOKING NO.'), findsOneWidget);
    expect(find.text('ADVANCE VOUCHER'), findsNothing);
    expect(find.text('BOOKING NUMBER'), findsOneWidget);
    expect(find.text('BOOKING ITEMS'), findsNothing);
    expect(find.text('NO BOOKING SELECTED'), findsNothing);
    expect(find.text('LOAD BOOKING ITEMS'), findsNothing);
    expect(find.text('Refund Value'), findsOneWidget);
    expect(find.text('Process Cancellation'), findsOneWidget);
    expect(find.text('SOURCE NUMBER'), findsNothing);
    expect(find.text('RETURN NO.'), findsNothing);
    expect(find.text('CANCELLATION NO.'), findsNothing);
  });

  testWidgets('source history follows return and cancellation setup rules',
      (tester) async {
    final controller = ReturnReversalController(
      repository: _AllSourceTypesReturnReversalRepository(),
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

    expect(find.text('SALES  1'), findsOneWidget);
    expect(find.text('PURCHASE  1'), findsOneWidget);
    expect(find.text('BOOKING  1'), findsNothing);
    expect(controller.state.selectedSourceDocument?.type,
        ReturnReversalSourceDocumentType.salesInvoice);

    await tester.tap(find.text('CANCELLATION'));
    await tester.pump(const Duration(milliseconds: 220));
    await controller.searchRecords();
    await tester.pump();
    await tester.pump();

    expect(find.text('CANCELLATION SETUP'), findsOneWidget);
    expect(find.text('BOOKING  1'), findsOneWidget);
    expect(find.text('SALES  1'), findsNothing);
    expect(find.text('PURCHASE  1'), findsNothing);
    expect(controller.state.selectedSourceDocument?.type,
        ReturnReversalSourceDocumentType.advanceBooking);
  });

  testWidgets('booking cancellation skips stock routing and prepares refund',
      (tester) async {
    final repository = _AllSourceTypesReturnReversalRepository();
    final controller = ReturnReversalController(repository: repository);
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

    await tester.tap(find.text('CANCELLATION'));
    await tester.pump(const Duration(milliseconds: 220));
    controller.customerMobileCtrl.text = '9304479436';
    await controller.searchRecords();
    await tester.pump();
    await tester.pump();

    expect(controller.state.selectedSourceDocument?.type,
        ReturnReversalSourceDocumentType.advanceBooking);
    expect(controller.state.returnCartLineNumbers, {1});
    expect(find.text('CANCELLATION WORKFLOW'), findsOneWidget);
    expect(find.text('Booking'), findsWidgets);
    expect(find.text('Advance Settlement'), findsOneWidget);
    expect(find.text('Stock Routing'), findsNothing);
    expect(find.text('Add Stock'), findsNothing);
    expect(find.text('Melting'), findsNothing);
    expect(find.text('Hold'), findsNothing);
    expect(find.text('HUID matched'), findsNothing);
    expect(find.text('Received Net Weight'), findsNothing);
    expect(find.text('CANCELLATION SETTLEMENT'), findsWidgets);
    expect(find.text('Refund Value'), findsWidgets);

    await controller.processReturn();

    expect(repository.lastRequest, isNotNull);
    expect(repository.lastRequest!.operationType,
        ReturnReversalOperationType.bookingCancellation);
    expect(repository.lastRequest!.lines.single.stockDisposition,
        ReturnReversalStockDisposition.notApplicable);
    expect(repository.lastRequest!.lines.single.receivedNetWeight, 0);
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
    expect(find.text('LOADED : AJ-PUR-2026-0006'), findsNothing);
    expect(find.text('Silver Payal'), findsWidgets);
    expect(find.text('RETURN : 1'), findsNothing);
    expect(find.text('METAL'), findsNothing);
    expect(find.text('ITEM DESCRIPTION'), findsNothing);
    expect(find.text('UNIT'), findsNothing);
    expect(find.text('HUID / SET'), findsNothing);
    expect(find.text('PURITY'), findsNothing);
    expect(find.text('GR. WT'), findsNothing);
    expect(find.text('LESS'), findsNothing);
    expect(find.text('MAKING'), findsNothing);
    expect(find.text('TOTAL'), findsNothing);
    expect(find.text('1 PAIR'), findsWidgets);
    expect(find.text('12%'), findsOneWidget);
    expect(find.text('DISCOUNT'), findsNothing);
    expect(find.text('ACT'), findsNothing);
    expect(find.text('HUID123456'), findsWidgets);
    expect(find.text('PUR-SILVER-001'), findsNothing);
    expect(find.text('Rs 1,587'), findsWidgets);
    expect(find.text('Rs 19,590'), findsWidgets);
    expect(find.text('Rs 20,178'), findsWidgets);
    expect(find.text('ORIGINAL INVOICE PRICING'), findsOneWidget);
    expect(find.text('Silver Pricing'), findsOneWidget);
    expect(find.text('Silver Value'), findsOneWidget);
    expect(find.text('Discount'), findsWidgets);
    expect(find.text('Taxable Value'), findsWidgets);
    expect(find.text('GST (3%)'), findsOneWidget);
    expect(find.text('Silver Total'), findsOneWidget);
    expect(find.text('PAYMENT METHOD'), findsOneWidget);
    expect(find.text('Cash Rs 5,000'), findsOneWidget);
    expect(find.text('UPI Rs 10,000'), findsOneWidget);
    expect(find.text('Collected'), findsOneWidget);
    expect(find.text('Balance Due'), findsOneWidget);
    expect(find.text('RETURN CART'), findsOneWidget);
    expect(find.text('No return items added to cart.'), findsOneWidget);
    expect(find.text('Return Value'), findsOneWidget);
    expect(find.text('Cart Items'), findsOneWidget);
    expect(find.text('HUID matched'), findsOneWidget);
    expect(find.text('Unit matched'), findsOneWidget);
    expect(find.text('ITEM IDENTITY'), findsOneWidget);
    expect(find.text('ORIGINAL SALE'), findsOneWidget);
    expect(find.text('TAX SNAPSHOT'), findsOneWidget);
    expect(find.text('Received Net Weight'), findsOneWidget);
    expect(find.text('Rate'), findsOneWidget);
    expect(find.text('Making Input'), findsOneWidget);
    expect(find.text('Making Amount'), findsOneWidget);
    expect(find.text('Taxable Value'), findsWidgets);
    expect(find.text('GST'), findsWidgets);
    expect(find.text('Metal Value Only'), findsOneWidget);
    expect(find.text('Metal + Making'), findsOneWidget);
    expect(find.text('This Item Return'), findsOneWidget);
    expect(find.text('Add To Return Cart'), findsOneWidget);
    expect(find.text('Add Stock'), findsOneWidget);
    expect(find.text('Melting'), findsOneWidget);
    expect(find.text('Selected Discount'), findsNothing);
    expect(find.text('Selected GST'), findsNothing);
    expect(find.text('DUE 2.0K'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    expect(controller.state.returnCartLineItems, isEmpty);

    controller.addLineToReturnCart(1);
    await tester.pump();

    expect(controller.state.returnCartLineItems, hasLength(1));
    expect(find.text('ADDED'), findsOneWidget);
    expect(find.text('Update Cart'), findsOneWidget);
    expect(find.text('Silver Return'), findsOneWidget);
    expect(find.text('Silver Net Weight'), findsOneWidget);
    expect(find.text('Silver Metal Amount'), findsOneWidget);
    expect(find.text('Silver Making Available'), findsOneWidget);
    expect(find.text('Silver Making Returned'), findsOneWidget);
    expect(find.text('Silver Return Total'), findsOneWidget);
    expect(find.text('Rs 18,003'), findsWidgets);

    controller.setLineMakingReturn(1, true);
    await tester.pump();

    expect(controller.state.activeInspectionDraft?.includeMakingCharge, isTrue);
    expect(find.text('Rs 19,590'), findsWidgets);

    controller.removeLineFromReturnCart(1);
    await tester.pump();

    expect(controller.state.returnCartLineItems, isEmpty);
    expect(find.text('Rs 0'), findsWidgets);
  });

  testWidgets('returned invoice lines open readonly audit and stay locked',
      (tester) async {
    final controller = ReturnReversalController(
      repository: _PartiallyReturnedReturnReversalRepository(),
    );
    addTearDown(controller.dispose);

    controller.sourceDocumentNumberCtrl.text = 'AJ-LOCK-2026-0001';
    await controller.searchRecords();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: 1180,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  return ReturnReversalWorkflowTabs(controller: controller);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(controller.state.activeInspectionLineNo, 2);
    expect(find.text('RETURNED'), findsOneWidget);
    expect(find.text('POSTED'), findsNothing);
    expect(find.text('Gold Ring'), findsOneWidget);
    expect(find.text('Gold Chain'), findsWidgets);

    await tester.tap(find.text('Gold Ring'));
    await tester.pump();

    expect(controller.state.activeInspectionLineNo, 1);
    expect(find.text('Read-only return audit | Invoice Date 01 SEP 2026'),
        findsOneWidget);
    expect(find.text('RETURNED | Voucher SR-26-00011 | Returned 03 SEP 2026'),
        findsOneWidget);
    expect(find.text('Rs 7,650'), findsWidgets);
    expect(find.text('Melting'), findsOneWidget);

    controller.setLineMakingReturn(1, true);
    controller.setStockRoute(1, ReturnReversalStockRoute.addToStock);
    controller.updateReceivedNetWeight(1, 0.25);
    await tester.pump();

    final lockedDraft = controller.state.activeInspectionDraft!;
    expect(lockedDraft.includeMakingCharge, isFalse);
    expect(lockedDraft.stockRoute, ReturnReversalStockRoute.melting);
    expect(lockedDraft.receivedNetWeight, 0.85);
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

  testWidgets('source navigation scrolls the selected card into view',
      (tester) async {
    tester.view.physicalSize = const Size(700, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ReturnReversalController(
      repository: _ScrollableHistoryReturnReversalRepository(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 620,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  return ReturnReversalCustomerDetailsCard(
                    controller: controller,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    controller.customerMobileCtrl.text = '9304479436';
    await controller.searchRecords();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    for (var i = 0; i < 5; i += 1) {
      await tester.tap(find.byIcon(Icons.chevron_right_rounded).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
    }

    expect(controller.sourceDocumentNumberCtrl.text, 'AJ-PUR-2026-0011');
    final selectedNumberRect =
        tester.getRect(find.text('AJ-PUR-2026-0011').last);
    expect(selectedNumberRect.left, greaterThanOrEqualTo(0));
    expect(selectedNumberRect.right, lessThanOrEqualTo(700));
  });

  testWidgets('return settlement scrolls inside a bounded desktop rail',
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

    expect(find.text('RETURN SETTLEMENT'), findsOneWidget);
    expect(find.text('ORIGINAL INVOICE PRICING'), findsOneWidget);
    expect(find.text('RETURN CART'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('process return posts selected cart through repository',
      (tester) async {
    final repository = _ProcessTrackingReturnReversalRepository();
    final controller = ReturnReversalController(repository: repository);
    addTearDown(controller.dispose);

    controller.sourceDocumentNumberCtrl.text = 'AJ-PUR-2026-0006';
    await controller.searchRecords();
    controller.addLineToReturnCart(1);
    await controller.processReturn();

    expect(repository.lastRequest, isNotNull);
    expect(repository.lastRequest!.operationType,
        ReturnReversalOperationType.salesReturn);
    expect(
        repository.lastRequest!.sourceDocument.documentNo, 'AJ-PUR-2026-0006');
    expect(repository.lastRequest!.lines, hasLength(1));
    expect(repository.lastRequest!.lines.single.sourceLineNo, 1);
    expect(controller.state.returnCartLineItems, isEmpty);
    expect(controller.state.lastProcessResult?.voucherNo, 'SR-26-00099');
    expect(controller.state.processMessage, contains('SR-26-00099 posted'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('return settlement separates original pricing by metal',
      (tester) async {
    final controller = ReturnReversalController(
      repository: _MixedMetalReturnReversalRepository(),
    );
    addTearDown(controller.dispose);

    controller.sourceDocumentNumberCtrl.text = 'AJ-MIX-2026-0001';
    await controller.searchRecords();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 560,
            child: ReturnReversalInvoiceSummaryPanel(
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ORIGINAL INVOICE PRICING'), findsOneWidget);
    expect(find.text('Gold Pricing'), findsOneWidget);
    expect(find.text('Gold Value'), findsOneWidget);
    expect(find.text('Gold Total'), findsOneWidget);
    expect(find.text('Silver Pricing'), findsOneWidget);
    expect(find.text('Silver Value'), findsOneWidget);
    expect(find.text('Silver Total'), findsOneWidget);
    expect(find.text('GST (3%)'), findsNWidgets(2));
    expect(find.text('Original Invoice Total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('return cart separates selected totals by metal', (tester) async {
    final controller = ReturnReversalController(
      repository: _MixedMetalReturnReversalRepository(),
    );
    addTearDown(controller.dispose);

    controller.sourceDocumentNumberCtrl.text = 'AJ-MIX-2026-0001';
    await controller.searchRecords();
    controller.addLineToReturnCart(1);
    controller.setLineMakingReturn(2, true);
    controller.addLineToReturnCart(2);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 560,
            child: ReturnReversalInvoiceSummaryPanel(
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('RETURN CART'), findsOneWidget);
    expect(find.text('Cart Items'), findsOneWidget);
    expect(find.text('Gold Return'), findsOneWidget);
    expect(find.text('Gold Net Weight'), findsOneWidget);
    expect(find.text('Gold Metal Amount'), findsOneWidget);
    expect(find.text('Gold Making Available'), findsOneWidget);
    expect(find.text('Gold Making Returned'), findsOneWidget);
    expect(find.text('Gold Return Total'), findsOneWidget);
    expect(find.text('Silver Return'), findsOneWidget);
    expect(find.text('Silver Net Weight'), findsOneWidget);
    expect(find.text('Silver Metal Amount'), findsOneWidget);
    expect(find.text('Silver Making Available'), findsOneWidget);
    expect(find.text('Silver Making Returned'), findsOneWidget);
    expect(find.text('Silver Return Total'), findsOneWidget);
    expect(find.text('Rs 8,500'), findsWidgets);
    expect(find.text('Rs 15,000'), findsWidgets);
    expect(find.text('Rs 23,500'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('partial received weight recalculates workflow and return cart',
      (tester) async {
    tester.view.physicalSize = const Size(1480, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ReturnReversalController(
      repository: _MixedMetalReturnReversalRepository(),
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

    controller.sourceDocumentNumberCtrl.text = 'AJ-MIX-2026-0001';
    await controller.searchRecords();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    await tester.enterText(
      find.byKey(const ValueKey('received-weight-1')),
      '0.75',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(controller.state.activeInspectionDraft?.receivedNetWeight, 0.75);
    expect(find.text('0.750 g'), findsWidgets);
    expect(find.text('Rs 4,250'), findsWidgets);

    controller.addLineToReturnCart(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Gold Net Weight'), findsOneWidget);
    expect(find.text('Gold Metal Amount'), findsOneWidget);
    expect(find.text('Gold Return Total'), findsOneWidget);
    expect(find.text('Rs 4,250'), findsWidgets);
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
        quantityUnitCode: 'PCS',
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

  @override
  Future<ReturnReversalProcessResult> processReturn(
    ReturnReversalProcessRequest request,
  ) async {
    return const ReturnReversalProcessResult(
      voucherId: 1,
      voucherNo: 'SR-26-00001',
      processedLineCount: 1,
      returnValue: 17500,
      dueAdjustedAmount: 2000,
      customerCreditAmount: 15500,
      status: 'POSTED',
    );
  }
}

class _ProcessTrackingReturnReversalRepository
    extends _TestReturnReversalRepository {
  ReturnReversalProcessRequest? lastRequest;

  @override
  Future<ReturnReversalProcessResult> processReturn(
    ReturnReversalProcessRequest request,
  ) async {
    lastRequest = request;
    return const ReturnReversalProcessResult(
      voucherId: 99,
      voucherNo: 'SR-26-00099',
      processedLineCount: 1,
      returnValue: 17500,
      dueAdjustedAmount: 2000,
      customerCreditAmount: 15500,
      status: 'POSTED',
    );
  }
}

class _PartiallyReturnedReturnReversalRepository
    extends _TestReturnReversalRepository {
  static final _invoice = ReturnReversalSourceDocument(
    id: 90,
    type: ReturnReversalSourceDocumentType.salesInvoice,
    documentNo: 'AJ-LOCK-2026-0001',
    customerName: 'REYANSH SONI',
    mobile: '9304479436',
    address: 'Patna',
    documentDate: DateTime(2026, 9, 1),
    grossValue: 18000,
    paidAmount: 18000,
    dueAmount: 0,
    netWeight: 2,
    lineItems: [
      ReturnReversalSourceLineItem(
        lineNo: 1,
        metalType: 'GOLD',
        description: 'Gold Ring',
        quantity: 1,
        grossWeight: 1,
        netWeight: 1,
        rate: 9000,
        value: 9000,
        status: 'ACTIVE',
        reversalStatus: 'POSTED',
        reversalVoucherNo: 'SR-26-00011',
        reversalDate: DateTime(2026, 9, 3),
        reversalReceivedNetWeight: 0.85,
        reversalHuidMatched: true,
        reversalUnitMatched: true,
        reversalIncludeMakingCharge: false,
        reversalStockDisposition: 'MELTING',
        reversalMetalReturnAmount: 7650,
        reversalMakingReturnedAmount: 0,
        reversalLineReturnValue: 7650,
      ),
      const ReturnReversalSourceLineItem(
        lineNo: 2,
        metalType: 'GOLD',
        description: 'Gold Chain',
        quantity: 1,
        grossWeight: 1,
        netWeight: 1,
        rate: 9000,
        value: 9000,
        status: 'ACTIVE',
      ),
    ],
  );

  @override
  Future<ReturnReversalSourceDocument?> findSourceDocumentByNumber(
    String documentNumber,
  ) async {
    return documentNumber == _invoice.documentNo ? _invoice : null;
  }
}

class _ScrollableHistoryReturnReversalRepository
    extends _TestReturnReversalRepository {
  static final _invoices = List<ReturnReversalSourceDocument>.generate(
    6,
    (index) {
      final serial = (index + 6).toString().padLeft(4, '0');
      return ReturnReversalSourceDocument(
        id: 100 + index,
        type: ReturnReversalSourceDocumentType.salesInvoice,
        documentNo: 'AJ-PUR-2026-$serial',
        customerName: 'REYANSH SONI',
        mobile: '9304479436',
        address: 'Patna',
        documentDate: DateTime(2026, 8, 20 + index),
        grossValue: 10000 + (index * 1000),
        paidAmount: 10000 + (index * 1000),
        dueAmount: 0,
        netWeight: 1,
        lineItems: [
          ReturnReversalSourceLineItem(
            lineNo: 1,
            metalType: 'GOLD',
            description: 'Gold Chain $serial',
            quantity: 1,
            grossWeight: 1,
            netWeight: 1,
            rate: 10000 + (index * 1000),
            value: 10000 + (index * 1000),
            status: 'ACTIVE',
          ),
        ],
      );
    },
  );

  @override
  Future<ReturnReversalLookupResult> findCustomerHistoryByMobile(
    String mobile,
  ) async {
    return ReturnReversalLookupResult(
      salesInvoices: mobile == '9304479436' ? _invoices : const [],
      advanceBookings: const [],
      customerPurchases: const [],
    );
  }
}

class _MixedMetalReturnReversalRepository implements ReturnReversalRepository {
  static final _invoice = ReturnReversalSourceDocument(
    id: 3,
    type: ReturnReversalSourceDocumentType.salesInvoice,
    documentNo: 'AJ-MIX-2026-0001',
    customerName: 'REYANSH SONI',
    mobile: '9304479436',
    address: 'Patna',
    documentDate: DateTime(2026, 8, 31),
    grossValue: 25000,
    discountAmount: 250,
    taxableAmount: 24750,
    cgstAmount: 371.25,
    sgstAmount: 371.25,
    gstAmount: 742.5,
    makingTotal: 2500,
    finalAmount: 25493,
    paidAmount: 25493,
    cashPaid: 20000,
    upiPaid: 5493,
    dueAmount: 0,
    netWeight: 51.5,
    lineItems: const [
      ReturnReversalSourceLineItem(
        lineNo: 1,
        metalType: 'GOLD',
        description: 'Nose Pin',
        hsnCode: '71131910',
        purity: '18KT',
        quantity: 1,
        quantityUnitCode: 'PCS',
        grossWeight: 1.5,
        lessWeight: 0,
        netWeight: 1.5,
        rate: 12700,
        makingChargeType: 'PERCENTAGE',
        makingChargeInput: 12,
        makingAmount: 1500,
        discountAmount: 100,
        taxableAmount: 9900,
        gstAmount: 297,
        invoiceValue: 10197,
        value: 10000,
        status: 'ACTIVE',
      ),
      ReturnReversalSourceLineItem(
        lineNo: 2,
        metalType: 'SILVER',
        description: 'Payal',
        hsnCode: '71131120',
        purity: '60',
        quantity: 1,
        quantityUnitCode: 'PAIR',
        grossWeight: 50,
        lessWeight: 0,
        netWeight: 50,
        rate: 220,
        makingChargeType: 'PER_GRAM',
        makingChargeInput: 20,
        makingAmount: 1000,
        discountAmount: 150,
        taxableAmount: 14850,
        gstAmount: 445.5,
        invoiceValue: 15296,
        value: 15000,
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
      salesInvoices: mobile == '9304479436' ? [_invoice] : const [],
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

  @override
  Future<ReturnReversalProcessResult> processReturn(
    ReturnReversalProcessRequest request,
  ) async {
    return const ReturnReversalProcessResult(
      voucherId: 2,
      voucherNo: 'SR-26-00002',
      processedLineCount: 2,
      returnValue: 23500,
      dueAdjustedAmount: 0,
      customerCreditAmount: 23500,
      status: 'POSTED',
    );
  }
}

class _AllSourceTypesReturnReversalRepository
    implements ReturnReversalRepository {
  ReturnReversalProcessRequest? lastRequest;

  static final _salesInvoice = ReturnReversalSourceDocument(
    id: 10,
    type: ReturnReversalSourceDocumentType.salesInvoice,
    documentNo: 'AJ-SALE-2026-0001',
    customerName: 'REYANSH SONI',
    mobile: '9304479436',
    address: 'Patna',
    documentDate: DateTime(2026, 8),
    grossValue: 12000,
    finalAmount: 12360,
    paidAmount: 12360,
    dueAmount: 0,
    netWeight: 1,
    lineItems: const [
      ReturnReversalSourceLineItem(
        lineNo: 1,
        metalType: 'GOLD',
        description: 'Ring',
        quantity: 1,
        grossWeight: 1,
        netWeight: 1,
        rate: 12000,
        gstAmount: 360,
        invoiceValue: 12360,
        value: 12000,
        status: 'ACTIVE',
      ),
    ],
  );

  static final _purchaseReturnSource = ReturnReversalSourceDocument(
    id: 11,
    type: ReturnReversalSourceDocumentType.customerPurchase,
    documentNo: 'AJ-PURCHASE-2026-0001',
    customerName: 'REYANSH SONI',
    mobile: '9304479436',
    address: 'Patna',
    documentDate: DateTime(2026, 8, 2),
    grossValue: 5000,
    finalAmount: 5000,
    paidAmount: 5000,
    dueAmount: 0,
    netWeight: 25,
    lineItems: const [
      ReturnReversalSourceLineItem(
        lineNo: 1,
        metalType: 'SILVER',
        description: 'Old Silver',
        quantity: 1,
        grossWeight: 25,
        netWeight: 25,
        rate: 200,
        value: 5000,
        status: 'ACTIVE',
      ),
    ],
  );

  static final _booking = ReturnReversalSourceDocument(
    id: 12,
    type: ReturnReversalSourceDocumentType.advanceBooking,
    documentNo: 'AJ-BOOK-2026-0001',
    customerName: 'REYANSH SONI',
    mobile: '9304479436',
    address: 'Patna',
    documentDate: DateTime(2026, 8, 3),
    grossValue: 3000,
    finalAmount: 3000,
    paidAmount: 3000,
    dueAmount: 0,
    netWeight: 0,
    lineItems: const [
      ReturnReversalSourceLineItem(
        lineNo: 1,
        metalType: 'GOLD',
        description: 'Advance Booking',
        quantity: 1,
        grossWeight: 0,
        netWeight: 0,
        rate: 0,
        value: 3000,
        status: 'PENDING',
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
      salesInvoices: mobile == '9304479436' ? [_salesInvoice] : const [],
      advanceBookings: mobile == '9304479436' ? [_booking] : const [],
      customerPurchases:
          mobile == '9304479436' ? [_purchaseReturnSource] : const [],
    );
  }

  @override
  Future<ReturnReversalSourceDocument?> findSourceDocumentByNumber(
    String documentNumber,
  ) async {
    return [
      _salesInvoice,
      _purchaseReturnSource,
      _booking,
    ].cast<ReturnReversalSourceDocument?>().firstWhere(
          (document) => document?.documentNo == documentNumber,
          orElse: () => null,
        );
  }

  @override
  Future<ReturnReversalProcessResult> processReturn(
    ReturnReversalProcessRequest request,
  ) async {
    lastRequest = request;
    return const ReturnReversalProcessResult(
      voucherId: 3,
      voucherNo: 'SR-26-00003',
      processedLineCount: 1,
      returnValue: 12000,
      dueAdjustedAmount: 0,
      customerCreditAmount: 12000,
      status: 'POSTED',
    );
  }
}
