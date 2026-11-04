import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_document_summary_panel.dart';

void main() {
  testWidgets('document summary fits compact desktop without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookDocumentSummaryPanel(documents: [
            DayBookDocument(
              kind: DayBookDocumentKind.gstInvoice,
              sourceId: '1',
              number: 'TAX-1',
              date: DateTime(2026, 6, 25),
              amount: 103,
              status: 'ACTIVE',
              tax: 3,
              collection: 50,
            ),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Source Document Summary'), findsOneWidget);
    expect(find.text('GST Invoice'), findsNothing);
    await tester.tap(find.text('Source Document Summary'));
    await tester.pumpAndSettle();
    expect(find.text('GST Invoice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
