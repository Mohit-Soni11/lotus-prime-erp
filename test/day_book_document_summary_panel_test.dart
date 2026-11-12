import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_document_summary_panel.dart';
import 'support/day_book_demo_preview.dart';

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
            summary: DayBookDemoPreview.forDate(DateTime(2026, 11, 4)),
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
            summary: DayBookDemoPreview.forDate(DateTime(2026, 11, 4)),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Source Documents'), findsOneWidget);
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

  testWidgets('all six document tabs remain available', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookDocumentSummaryPanel(
            summary: DayBookDemoPreview.forDate(DateTime(2026, 11, 4)),
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
            summary: DayBookDemoPreview.forDate(DateTime(2026, 11, 4)),
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
    expect(tester.takeException(), isNull);
  });
}
