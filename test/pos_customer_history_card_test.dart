import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/sales_orders/sales_pos/pos_billing_controller.dart';
import 'package:lotus_erp/models/customer/customer_profile/customer_profile_model.dart';
import 'package:lotus_erp/ui/sales_orders/sales_pos/customer_history/pos_customer_history_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );
  });

  testWidgets('customer account card displays active booking advances',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = PosBillingController();
    addTearDown(controller.dispose);

    controller.customerHistory = CustomerProfileModel(
      id: 1,
      name: 'Reyansh Soni',
      mobile: '9304479436',
      type: 'Regular',
      createdAt: DateTime(2026, 9, 8),
      initials: 'RS',
      accountCreditBalance: 134480.28,
      outstanding: 2500,
      dues: [
        CustomerDueModel(
          billId: 101,
          billNo: 'AJ-26-011',
          totalAmount: 12500,
          paidAmount: 10000,
          billDate: DateTime(2026, 9, 7),
        ),
      ],
      advanceOrders: [
        CustomerAdvanceOrderModel(
          id: 11,
          orderNo: 'AJ-BK-26-0008',
          itemName: 'Gold Ring',
          metalType: 'GOLD',
          purity: '22KT',
          approxWeight: 10,
          lockedRate: 6500,
          bookingType: 'LOCKED',
          status: AdvanceOrderStatus.pending,
          totalAdvancePaid: 12000,
          estimatedTotal: 65000,
          createdAt: DateTime(2026, 9, 8),
        ),
        CustomerAdvanceOrderModel(
          id: 12,
          orderNo: 'AJ-BK-26-0009',
          itemName: 'Silver Chain',
          metalType: 'SILVER',
          purity: '925',
          approxWeight: 35,
          lockedRate: 0,
          bookingType: 'OPEN',
          status: AdvanceOrderStatus.ready,
          totalAdvancePaid: 5000,
          estimatedTotal: 0,
          createdAt: DateTime(2026, 9, 9),
        ),
        CustomerAdvanceOrderModel(
          id: 13,
          orderNo: 'AJ-BK-26-0010',
          itemName: 'Gold Bangle',
          metalType: 'GOLD',
          purity: '22KT',
          approxWeight: 18,
          lockedRate: 7200,
          bookingType: 'LOCKED',
          status: AdvanceOrderStatus.pending,
          totalAdvancePaid: 18000,
          estimatedTotal: 129600,
          createdAt: DateTime(2026, 9, 10),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1220,
            child: PosCustomerHistoryCard(ctrl: controller),
          ),
        ),
      ),
    );

    expect(find.text('Booking Advance Invoices'), findsOneWidget);
    expect(find.text('AJ-BK-26-0008'), findsOneWidget);
    expect(find.text('AJ-BK-26-0009'), findsOneWidget);
    expect(find.text('AJ-BK-26-0010'), findsOneWidget);
    expect(find.text('3 invoices'), findsOneWidget);
    expect(find.text('1 invoice'), findsOneWidget);
    expect(find.text('Rs 35,000.00'), findsNothing);
    expect(find.textContaining('Weight 10 g'), findsOneWidget);
    expect(find.textContaining('Locked Rs 6,500.00/g'), findsOneWidget);
    expect(find.textContaining('Advance Rs 12,000.00'), findsOneWidget);
    expect(find.textContaining('Estimate'), findsNothing);
    expect(find.textContaining('Customer credit available'), findsNothing);
    expect(find.textContaining('Rs 1,34,480.28'), findsNothing);
    expect(find.textContaining('more advance'), findsNothing);
  });
}
