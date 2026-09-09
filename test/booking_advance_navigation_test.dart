import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/booking_advance/booking_advance_controller.dart';
import 'package:lotus_erp/logic/booking_advance/booking_invoice_preview_controller.dart';
import 'package:lotus_erp/repositories/booking_advance/booking_advance_repository.dart';
import 'package:lotus_erp/theme/booking_advance/booking_advance_theme.dart';
import 'package:lotus_erp/ui/booking_advance/booking_advance_screen.dart';
import 'package:lotus_erp/ui/booking_advance/booking_customer_panel.dart';
import 'package:lotus_erp/ui/booking_advance/booking_items_table.dart';
import 'package:lotus_erp/ui/booking_advance/booking_top_control_bar.dart';
import 'package:lotus_erp/ui/booking_advance/widgets/booking_action_buttons.dart';
import 'package:lotus_erp/ui/booking_advance/widgets/booking_invoice_command_panel.dart';
import 'package:lotus_erp/ui/booking_advance/widgets/booking_payment_hub.dart';

void main() {
  testWidgets('booking app bar back uses the provided module back handler',
      (tester) async {
    var backCount = 0;
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: BookingAdvanceScreen(
          onBack: () => backCount++,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    await tester.tap(find.byIcon(BookingAdvanceIcons.backArrow));
    await tester.pump();

    expect(backCount, 1);
  });

  testWidgets(
      'booking customer card keeps POS customer fields without KYC boxes',
      (tester) async {
    final controller = BookingAdvanceController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 1308,
              child: BookingCustomerPanel(ctrl: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text(BookingAdvanceStrings.lblMobile), findsOneWidget);
    expect(find.text(BookingAdvanceStrings.lblName), findsOneWidget);
    expect(find.text(BookingAdvanceStrings.lblCity), findsOneWidget);
    expect(find.text(BookingAdvanceStrings.btnCreateCustomer), findsOneWidget);
    expect(find.text('PAN / AADHAR'), findsNothing);
    expect(find.text('GST NUMBER'), findsNothing);
  });

  testWidgets('booking customer lookup shows a no-match state', (tester) async {
    final controller = BookingAdvanceController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 1308,
              child: BookingCustomerPanel(ctrl: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    controller.mobileCtrl.text = '9999999999';
    controller.customerNotFound = true;
    controller.notifyListeners();
    await tester.pump();

    expect(find.text('No Customer Match'), findsOneWidget);
    expect(find.text('Mobile: 9999999999'), findsOneWidget);
  });

  testWidgets('booking item row renders dense values without layout exceptions',
      (tester) async {
    final controller = BookingAdvanceController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    controller.addBookingItem();
    final item = controller.bookingItems.single;
    item.descCtrl.text = 'ring';
    item.purityCtrl.text = '18KT';
    item.grossCtrl.text = '5';
    item.rateCtrl.text = '12200';
    item.makingCtrl.text = '12';
    controller.setDeliveryDate(DateTime(2026, 9, 8));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1308,
            child: BookingItemsTable(ctrl: controller),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('TOTAL'), findsOneWidget);
    expect(find.text('DELIVERY'), findsOneWidget);
    expect(find.text('ACT'), findsOneWidget);
    expect(find.text('18KT'), findsOneWidget);
    expect(find.text('08 SEP'), findsOneWidget);
    final tableRect = tester.getRect(find.byType(BookingItemsTable));
    final actionRect =
        tester.getRect(find.byIcon(Icons.delete_outline_rounded));
    expect(actionRect.right, lessThanOrEqualTo(tableRect.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('booking preference tabs fill the segmented control',
      (tester) async {
    final controller = BookingAdvanceController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(420, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    controller.addBookingItem();
    controller.bookingItems.single.rateCtrl.text = '12200';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: BookingTopControlBar(ctrl: controller),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text(BookingAdvanceStrings.openRate), findsWidgets);
    expect(find.text(BookingAdvanceStrings.lockedRate), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'booking side panel replaces clear action with invoice generation',
      (tester) async {
    final controller = BookingAdvanceController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(420, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: BookingActionButtons(
              controller: controller,
              onSaved: (_, __) {},
              onGenerateInvoice: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(BookingAdvanceStrings.btnSaveBooking), findsOneWidget);
    expect(
      find.text(BookingAdvanceStrings.btnGenerateInvoice),
      findsOneWidget,
    );
    expect(find.text(BookingAdvanceStrings.btnClearAll), findsNothing);
  });

  testWidgets('generate invoice opens preview flow without success feedback',
      (tester) async {
    final controller = _GenerateInvoiceSuccessController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(420, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var savedFeedbackCount = 0;
    var generatedInvoiceCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: BookingActionButtons(
              controller: controller,
              onSaved: (_, __) => savedFeedbackCount++,
              onGenerateInvoice: (_) => generatedInvoiceCount++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(BookingAdvanceStrings.btnGenerateInvoice));
    for (var i = 0; i < 20 && generatedInvoiceCount == 0; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(savedFeedbackCount, 0);
    expect(generatedInvoiceCount, 1);
  });

  testWidgets('booking invoice command panel keeps only completion controls',
      (tester) async {
    final controller = BookingInvoicePreviewController(
      initialBookings: [_samplePreviewBooking()],
    )
      ..bookings = [_samplePreviewBooking()]
      ..genState = BookingInvoiceGenerationState.ready;
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(440, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var saveAndNewCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookingInvoiceCommandPanel(
            controller: controller,
            isSharing: false,
            isExporting: false,
            isPrinting: false,
            isCompleting: false,
            isExported: false,
            isPrinted: false,
            onBack: () {},
            onShare: () async {},
            onExport: () async {},
            onPrint: () async {},
            onSaveAndNew: () async => saveAndNewCount++,
          ),
        ),
      ),
    );

    expect(find.text('BOOKING CONTEXT'), findsNothing);
    expect(find.text('DOCUMENT DISPLAY'), findsNothing);
    expect(find.text('Print Booking Invoice & New'), findsOneWidget);
    expect(find.text('Save & New'), findsOneWidget);

    await tester.tap(find.text('Save & New'));
    await tester.pump();

    expect(saveAndNewCount, 1);
  });

  testWidgets('booking payment hub does not render balance due',
      (tester) async {
    final controller = BookingAdvanceController();
    addTearDown(controller.dispose);
    controller.addBookingItem();
    controller.bookingItems.single.grossCtrl.text = '5';
    controller.bookingItems.single.rateCtrl.text = '12000';
    await tester.binding.setSurfaceSize(const Size(420, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: BookingPaymentHub(controller: controller),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('BALANCE DUE'), findsNothing);
    expect(find.text(BookingAdvanceStrings.lblAdvanceTotal), findsOneWidget);
  });
}

class _GenerateInvoiceSuccessController extends BookingAdvanceController {
  @override
  Future<BookingInvoiceDraftResult> buildInvoicePreviewDraft() async {
    return BookingInvoiceDraftResult(
      success: true,
      message: 'Booking invoice preview is ready.',
      bookings: [_samplePreviewBooking()],
    );
  }

  @override
  Future<
      ({
        bool success,
        String message,
        String bookingNo,
        List<int> orderIds,
      })> saveBooking() async {
    fail('Generate Invoice must not save booking data.');
  }
}

EditableBookingAdvance _samplePreviewBooking() {
  final now = DateTime(2026, 9, 9);
  return EditableBookingAdvance(
    order: SalesOrder(
      id: -1,
      createdAt: now,
      orderNo: 'AJ-BK-26-0001',
      customerId: 0,
      itemName: 'Gold Ring',
      metalType: 'GOLD',
      purity: '22K',
      approxWeight: 5,
      bookingType: 'OPEN',
      lockedRate: 0,
      status: 'PREVIEW',
    ),
    customer: Customer(
      id: 0,
      createdAt: now,
      name: 'Reyansh Soni',
      mobile: '9304479436',
      type: 'Regular',
      entityType: 'Individual',
      country: 'India',
      openingBalance: 0,
      creditLimit: 0,
      customerTier: 'Regular',
    ),
    advances: const [],
  );
}
