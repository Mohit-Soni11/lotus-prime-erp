import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/booking_advance/booking_advance_controller.dart';
import 'package:lotus_erp/theme/booking_advance/booking_advance_theme.dart';
import 'package:lotus_erp/ui/booking_advance/booking_advance_screen.dart';
import 'package:lotus_erp/ui/booking_advance/booking_customer_panel.dart';
import 'package:lotus_erp/ui/booking_advance/booking_items_table.dart';
import 'package:lotus_erp/ui/booking_advance/booking_top_control_bar.dart';

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
    expect(find.text('DEL. DATE'), findsOneWidget);
    expect(find.text('ACT'), findsOneWidget);
    expect(find.text('18KT'), findsOneWidget);
    expect(find.text('08 SEP 26'), findsOneWidget);
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
}
