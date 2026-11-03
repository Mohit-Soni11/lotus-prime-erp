import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/theme/reports/day_book/day_book_colors.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_overview_cards.dart';

void main() {
  for (final width in [320.0, 800.0, 1440.0]) {
    testWidgets('daily overview remains readable at ${width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DayBookOverviewCards(
                summary: DayBookSummary(date: DateTime(2026, 6, 25)),
              ),
            ),
          ),
        ),
      ));

      for (final title in [
        'Total Sales',
        'Sales Collected',
        'Counter Cash',
        'Opening Cash',
        'Regular Invoices',
        'Tax Invoices',
        'GST Invoice Collection',
        'Due Collection',
      ]) {
        expect(find.text(title), findsOneWidget);
        expect((tester.widget<Text>(find.text(title))).style?.color,
            DayBookColors.textPrimary);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
