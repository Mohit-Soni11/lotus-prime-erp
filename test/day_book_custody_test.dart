import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_custody_position.dart';
import 'package:lotus_erp/theme/reports/day_book/day_book_theme.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_custody_panel.dart';

void main() {
  final position = DayBookCustodyPosition(DateTime(2026, 6, 25), [
    DayBookCustodyLine(
      ticketNo: 'GRV-1',
      itemName: 'Gold Ring',
      metal: 'Gold',
      purity: '22K',
      pieces: 1,
      grossWeight: 27,
      netWeight: 25,
      fineWeight: 22.9,
      receivedAt: DateTime(2026, 6, 25, 11),
    ),
  ]);
  final summary = DayBookSummary(
    date: DateTime(2026, 6, 25),
    openingGoldGrams: 100,
    metalIn: const MetalInflow(
      girviSecurityDeposit: MetalWeight(gold22k: 25),
    ),
    custodyPosition: position,
  );

  test('customer Girvi metal never increases owned closing stock', () {
    expect(summary.metalIn.custodyReceived.totalGold, 25);
    expect(summary.metalIn.total.totalGold, 0);
    expect(summary.closingGold, 100);
  });

  testWidgets('custody is labelled separately from owned stock',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: DayBookStyles.theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: DayBookCustodyPanel(position: position),
        ),
      ),
    ));

    expect(find.text('Girvi Customer Custody'), findsOneWidget);
    expect(find.textContaining('separate from owned stock'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
