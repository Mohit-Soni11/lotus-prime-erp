import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/finance/account_book/account_book_month.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/ui/finance/account_book/account_book_day_list.dart';
import 'package:lotus_erp/ui/finance/account_book/account_book_summary.dart';

void main() {
  testWidgets('monthly summary and day drilldown fit a compact window',
      (tester) async {
    tester.view.physicalSize = const Size(760, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final date = DateTime(2026, 3, 5);
    final report = AccountBookMonth(
      month: DateTime(2026, 3),
      money: DayBookMoneyFlow(
        openingCash: 100,
        openingBank: 200,
        entries: const [],
      ),
      days: [
        AccountBookDay(
          date: date,
          openingCash: 100,
          openingBank: 200,
          cashIn: 50,
          cashOut: 0,
          bankIn: 0,
          bankOut: 0,
          activities: [
            AccountBookActivity(
              date: date.add(const Duration(hours: 10)),
              type: AccountBookActivityType.money,
              title: 'Sale',
              reference: 'CASH-1',
              amount: 50,
              incoming: true,
              isCash: true,
            ),
          ],
        ),
      ],
    );
    DateTime? opened;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(padding: const EdgeInsets.all(16), children: [
          AccountBookSummary(report: report),
          const SizedBox(height: 12),
          AccountBookDayList(
            report: report,
            filter: null,
            onOpenDayBook: (day) => opened = day,
          ),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('MONTHLY POSITION'), findsOneWidget);
    await tester.tap(find.text('Thu, 5 Mar 2026'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('CASH-1'), findsOneWidget);
    await tester.tap(find.text('View full Day Book'));
    expect(opened, date);
  });
}
