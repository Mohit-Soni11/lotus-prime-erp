import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_document.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_smart_summary.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_activity_card.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_card_presentation.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_smart_cards.dart';
import 'support/day_book_demo_preview.dart';

void main() {
  test('sales and receipts share green; dues is yellow; outflows are red', () {
    final cards =
        DayBookSmartSummary.fromDay(DayBookSummary(date: DateTime(2026, 11, 4)))
            .cards;
    final colors = cards
        .map((card) => DayBookCardPresentation.fromCard(card).accent)
        .toList();
    expect(colors[0], colors[1]);
    expect(colors[1], colors[2]);
    expect(colors[3], isNot(colors[2]));
    expect(colors[3], isNot(colors[4]));
    expect(colors.sublist(4).toSet(), hasLength(1));
  });

  testWidgets('empty day keeps all cards accessible at narrow width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child:
              DayBookSmartCards(summary: DayBookSummary(date: DateTime(2026))),
        ),
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

  testWidgets('fixture displays every activity in two aligned rows',
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
            summary: DayBookDemoPreview.forDate(date),
          ),
        ),
      ),
    ));

    for (final title in [
      'Total Sales',
      'Advance Received',
      "Today's Receipts",
      "Today's Dues",
      'Girvi Given',
      'Return & Cancellation',
      'Customer Metal Purchase',
      'Expenses',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    for (final amount in [
      '₹3,11,000',
      '₹1,50,000',
      '₹60,000',
      '₹22,000',
      '₹2,00,000',
      '₹27,000',
      '₹3,79,000',
      '₹17,500',
    ]) {
      expect(find.text(amount), findsOneWidget);
    }
    final firstRow = [
      'Total Sales',
      'Advance Received',
      "Today's Receipts",
      "Today's Dues",
    ]
        .map((title) => tester.getTopLeft(find.ancestor(
            of: find.text(title), matching: find.byType(DayBookActivityCard))))
        .toList();
    final secondRow = [
      'Girvi Given',
      'Return & Cancellation',
      'Customer Metal Purchase',
      'Expenses',
    ]
        .map((title) => tester.getTopLeft(find.ancestor(
            of: find.text(title), matching: find.byType(DayBookActivityCard))))
        .toList();
    expect(firstRow.map((point) => point.dy).toSet(), hasLength(1));
    expect(secondRow.map((point) => point.dy).toSet(), hasLength(1));
    expect(secondRow.first.dy, greaterThan(firstRow.first.dy));
    expect(firstRow.map((point) => point.dx).toList(),
        orderedEquals([...firstRow.map((point) => point.dx)]..sort()));
    expect(secondRow.map((point) => point.dx).toList(),
        orderedEquals([...secondRow.map((point) => point.dx)]..sort()));
    await tester.tap(find.text('Total Sales'));
    await tester.pumpAndSettle();
    expect(find.text('Regular invoices'), findsOneWidget);
    expect(find.text('GST invoices'), findsOneWidget);
    expect(find.text('REG-025'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
