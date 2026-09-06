import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/booking_advance/booking_advance_controller.dart';
import 'package:lotus_erp/theme/booking_advance/booking_advance_theme.dart';
import 'package:lotus_erp/ui/booking_advance/booking_advance_screen.dart';
import 'package:lotus_erp/ui/booking_advance/booking_customer_panel.dart';

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
            child: BookingCustomerPanel(ctrl: controller),
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
}
