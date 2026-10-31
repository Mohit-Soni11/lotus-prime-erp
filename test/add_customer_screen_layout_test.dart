import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/customer/add_customer/add_customer_screen.dart';

void main() {
  testWidgets('new customer form keeps all sections and fits desktop width',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: AddCustomerScreen(onBack: () {})),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Customer Category'), findsOneWidget);
    expect(find.text('Standard Customer'), findsOneWidget);
    expect(find.text('Preferences & CRM'), findsNothing);
    expect(find.text('Additional Info'), findsNothing);
    expect(find.text('Date of Birth'), findsNothing);
    expect(find.text('Anniversary Date (Optional)'), findsNothing);
    expect(find.text('Opening Balance'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Corporate'));
    await tester.pump();
    expect(find.text('COMPANY NAME'), findsOneWidget);
    expect(find.text('KYC & Compliance'), findsOneWidget);
    expect(find.text('Customer Category'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(600, 800);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
