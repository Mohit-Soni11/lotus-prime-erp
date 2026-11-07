import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/theme/reports/day_book/day_book_theme.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_primary_grid.dart';

void main() {
  testWidgets('Day Book uses available width and stacks on narrow screens',
      (tester) async {
    final summary = DayBookSummary(
      date: DateTime(2026, 11, 2),
      openingCash: 404610,
      moneyFlow: DayBookMoneyFlow(
        openingCash: 404610,
        openingBank: 0,
        entries: [],
      ),
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [1920.0, 1200.0, 360.0]) {
      tester.view.physicalSize = Size(width, 1100);
      await tester.pumpWidget(MaterialApp(
        theme: DayBookStyles.theme,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: DayBookPrimaryGrid(summary: summary),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overflow at $width px');

      final money = tester.getTopLeft(find.text('Money Movement'));
      final opening = tester.getTopLeft(find.text('Opening Position'));
      expect(find.text('Closing Position'), findsOneWidget);
      expect(find.text('Opening Balance'), findsNWidgets(2));
      expect(find.text('Opening Cash'), findsNothing);
      if (width >= 1550) {
        expect(opening.dx, greaterThan(money.dx));
      } else {
        expect(opening.dy, greaterThan(money.dy));
      }
    }
  });
}
