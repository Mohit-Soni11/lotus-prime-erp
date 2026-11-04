import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_smart_cards.dart';

void main() {
  testWidgets('empty day keeps all cards accessible at narrow width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookSmartCards(summary: DayBookSummary(date: DateTime(2026))),
      ),
    ));
    expect(find.text('Total Sales'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invoice details expand while zero-activity cards remain',
      (tester) async {
    final date = DateTime(2026, 11, 4);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookSmartCards(
          summary: DayBookSummary(date: date, documents: [
            DayBookDocument(
              kind: DayBookDocumentKind.gstInvoice,
              sourceId: '2',
              number: 'TAX-30',
              date: date,
              amount: 52500,
              tax: 2500,
              collection: 30000,
              status: 'ACTIVE',
            ),
          ]),
        ),
      ),
    ));
    expect(find.text('Total Sales'), findsOneWidget);
    expect(find.text('Girvi Given'), findsOneWidget);
    await tester.tap(find.text('Total Sales'));
    await tester.pumpAndSettle();
    expect(find.text('GST invoices'), findsOneWidget);
    expect(find.text('TAX-30'), findsOneWidget);
    expect(find.textContaining('GST charged'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo preview displays every activity without mixing real rows',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final date = DateTime(2026, 11, 4);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookSmartCards(
            showDemoPreview: true,
            summary: DayBookSummary(date: date, documents: [
              DayBookDocument(
                kind: DayBookDocumentKind.regularInvoice,
                sourceId: '1',
                number: 'REAL-1',
                date: date,
                amount: 200,
                status: 'ACTIVE',
              ),
            ]),
          ),
        ),
      ),
    ));

    for (final title in [
      'Total Sales',
      'Girvi Given',
      'Advance Received',
      'Return & Cancellation',
      'Customer Metal Purchase',
      "Today's Dues",
      "Today's Receipts",
      'Expenses',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    for (final amount in [
      '₹4,75,000',
      '₹1,50,000',
      '₹60,000',
      '₹22,000',
      '₹2,00,000',
      '₹15,000',
      '₹5,55,000',
      '₹17,500',
    ]) {
      expect(find.text(amount), findsOneWidget);
    }
    expect(find.textContaining('DEMO PREVIEW'), findsOneWidget);
    expect(find.text('REAL-1'), findsNothing);
    await tester.tap(find.text('Total Sales'));
    await tester.pumpAndSettle();
    expect(find.text('Regular invoices'), findsOneWidget);
    expect(find.text('GST invoices'), findsOneWidget);
    expect(find.text('INV-025'), findsOneWidget);
    expect(find.text('REAL-1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
