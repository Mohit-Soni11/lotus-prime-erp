import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/girvi/new_girvi/new_girvi_screen.dart';

void main() {
  testWidgets('loan invoice summary renders on desktop without overflow',
      (tester) async {
    await _pumpGirviScreen(tester, const Size(1440, 1100));

    expect(find.text('LOAN INVOICE SUMMARY'), findsOneWidget);
    expect(find.text('Create & Print Invoice'), findsOneWidget);
    expect(find.text('INVOICE CHECKLIST'), findsOneWidget);
    expect(find.text('CHANGE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loan invoice summary renders in stacked layout', (tester) async {
    await _pumpGirviScreen(tester, const Size(900, 1200));

    expect(find.text('LOAN INVOICE SUMMARY'), findsOneWidget);
    expect(find.text('Save Ticket Only'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary automatically shows a mixed payment split',
      (tester) async {
    await _pumpGirviScreen(tester, const Size(1440, 1100));

    await tester.enterText(
      find.byKey(const ValueKey('girvi-disbursement-cash')),
      '500',
    );
    await tester.enterText(
      find.byKey(const ValueKey('girvi-disbursement-upi')),
      '500',
    );
    await tester.pump();

    expect(find.text('MIXED PAYMENT'), findsOneWidget);
    expect(find.text('Automatically detected from entered amounts'),
        findsOneWidget);
    expect(find.text('Cash'), findsWidgets);
    expect(find.text('UPI'), findsWidgets);
    expect(find.text('Rs 500.00'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpGirviScreen(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NewGirviScreen(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}
