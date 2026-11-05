import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_document_summary_panel.dart';

void main() {
  testWidgets('explorer stays usable at 320px', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookDocumentSummaryPanel(
            summary: DayBookSummary(date: DateTime(2026, 11, 4)),
            showDemoPreview: true,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('REG-025'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sample explorer shows regular and GST invoice cards at 390px',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookDocumentSummaryPanel(
            summary: DayBookSummary(date: DateTime(2026, 11, 4)),
            showDemoPreview: true,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Source Document Summary'), findsOneWidget);
    expect(find.text('DEMO PREVIEW'), findsOneWidget);
    expect(find.text('REG-025'), findsOneWidget);
    expect(find.text('Mr. Ramesh Shah'), findsOneWidget);
    expect(find.text('24.500 g'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('document-tab-gstSales')));
    await tester.pumpAndSettle();
    expect(find.text('TAX-030'), findsOneWidget);
    expect(find.text('REG-025'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all eight activity tabs remain available', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookDocumentSummaryPanel(
            summary: DayBookSummary(date: DateTime(2026, 11, 4)),
            showDemoPreview: true,
          ),
        ),
      ),
    ));
    for (final tab in [
      'sales',
      'gstSales',
      'girvi',
      'advance',
      'returns',
      'purchase',
      'expenses',
      'otherPayments',
    ]) {
      expect(find.byKey(ValueKey('document-tab-$tab')), findsOneWidget);
    }
  });

  testWidgets(
      'reference-width layout keeps tabs, totals and five cards aligned',
      (tester) async {
    tester.view.physicalSize = const Size(1225, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookDocumentSummaryPanel(
            summary: DayBookSummary(date: DateTime(2026, 11, 4)),
            showDemoPreview: true,
          ),
        ),
      ),
    ));
    final positions = [
      for (final id in ['REG-025', 'REG-026', 'REG-027', 'REG-028', 'REG-029'])
        tester.getTopLeft(find.text(id)).dy,
    ];
    expect(positions.toSet(), hasLength(1));
    final metrics = [
      for (final label in [
        'Total Invoices',
        'Invoice Range',
        'Total Sales',
        'Total Paid',
        'Total Due',
      ])
        tester.getTopLeft(find.text(label)).dy,
    ];
    expect(metrics.toSet(), hasLength(1));
    await tester.tap(find.byKey(const ValueKey('document-tab-girvi')));
    await tester.pumpAndSettle();
    expect(find.text('GRV-112'), findsOneWidget);
    expect(find.text('Mr. Dev Patel'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('document-tab-expenses')));
    await tester.pumpAndSettle();
    expect(find.text('EXP-101'), findsOneWidget);
    expect(find.text('Shop Rent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
