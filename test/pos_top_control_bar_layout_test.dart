import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/sales_orders/sales_pos/pos_billing_controller.dart';
import 'package:lotus_erp/ui/sales_orders/sales_pos/pos_top_control_bar.dart';

void main() {
  testWidgets('invoice preferences render without overflow on desktop card',
      (tester) async {
    final controller = PosBillingController();
    addTearDown(controller.dispose);

    tester.view.physicalSize = const Size(640, 220);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.2)),
            child: Center(
              child: SizedBox(
                width: 600,
                child: PosTopControlBar(ctrl: controller),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
