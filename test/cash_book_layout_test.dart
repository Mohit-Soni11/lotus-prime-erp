import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/finance/cash_book/cash_book_controller.dart';
import 'package:lotus_erp/logic/finance/cash_book/cash_book_history_controller.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_period_summary.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_summary_model.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_transaction_model.dart';
import 'package:lotus_erp/repositories/finance/cash_book_repository.dart';
import 'package:lotus_erp/repositories/finance/cash_book_period_repository.dart';
import 'package:lotus_erp/ui/finance/cash_book/cash_book_add_entry_button.dart';
import 'package:lotus_erp/ui/finance/cash_book/cash_book_app_bar.dart';
import 'package:lotus_erp/ui/finance/cash_book/cash_book_body.dart';
import 'package:lotus_erp/ui/shared/system_status_badge.dart';

class _CashBookFixture extends CashBookRepository {
  _CashBookFixture(AppDatabase db) : super(db: db);

  @override
  Stream<List<CashTransactionModel>> watchTransactions({
    required DateTime from,
    required DateTime to,
  }) =>
      Stream.value(const []);

  @override
  Future<CashBookSummaryModel> computeSummary({
    required DateTime from,
    required DateTime to,
  }) async =>
      CashBookSummaryModel.zero();
}

class _HistoryFixture extends CashBookPeriodRepository {
  _HistoryFixture(AppDatabase db) : super(db: db);

  @override
  Stream<CashBookHistorySnapshot> watchHistory() =>
      Stream.value(const CashBookHistorySnapshot(
        months: [
          CashBookPeriodSummary(
            year: 2026,
            month: 1,
            openingBalance: 100,
            cashIn: 80,
            cashOut: 20,
            closingBalance: 160,
            transactionCount: 3,
          ),
          CashBookPeriodSummary(
            year: 2026,
            month: 2,
            openingBalance: 160,
            cashIn: 40,
            cashOut: 10,
            closingBalance: 190,
            transactionCount: 2,
          ),
        ],
        years: [
          CashBookPeriodSummary(
            year: 2025,
            month: null,
            openingBalance: 50,
            cashIn: 50,
            cashOut: 0,
            closingBalance: 100,
            transactionCount: 1,
          ),
          CashBookPeriodSummary(
            year: 2026,
            month: null,
            openingBalance: 100,
            cashIn: 120,
            cashOut: 30,
            closingBalance: 190,
            transactionCount: 5,
          ),
        ],
      ));
}

void main() {
  testWidgets('cash book overview and empty ledger fit responsive windows',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final ctrl = CashBookController(repository: _CashBookFixture(db));
    final history = CashBookHistoryController(repository: _HistoryFixture(db));
    var backTaps = 0;
    var homeTaps = 0;
    var addTaps = 0;
    var exportTaps = 0;
    addTearDown(() async {
      ctrl.dispose();
      history.dispose();
      await db.close();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.devicePixelRatio = 1;
    for (final size in [
      const Size(1920, 1080),
      const Size(850, 750),
      const Size(360, 700),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(MaterialApp(
        home: ListenableBuilder(
          listenable: Listenable.merge([ctrl, history]),
          builder: (_, __) => Scaffold(
            appBar: CashBookAppBar(
              onBack: () {
                if (history.view == CashBookHistoryView.daily) {
                  backTaps++;
                } else {
                  history.showDaily();
                }
              },
              onHome: () {
                homeTaps++;
                history.showDaily();
              },
              showHomeAction: history.view != CashBookHistoryView.daily,
              onExportCsv: () => exportTaps++,
              onPrintPdf: () {},
              status:
                  ctrl.isLoading ? SystemStatus.loading : SystemStatus.online,
            ),
            body: CashBookBody(ctrl: ctrl, history: history),
            floatingActionButton: CashBookAddEntryButton(
              onPressed: () => addTaps++,
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('ACCOUNT BOOK'), findsOneWidget);
      expect(find.text('Opening Balance'), findsOneWidget);
      expect(find.text('Cash Ledger Date'), findsOneWidget);
      expect(find.text('No cash transactions this month'), findsOneWidget);
      expect(find.textContaining('Cash Activity'), findsOneWidget);
      expect(find.text('0 cash transactions'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
      expect(find.text('Sync Bills'), findsNothing);
      expect(find.text('Add Cash Income'), findsWidgets);
      final addButton = find.byType(CashBookAddEntryButton);
      final buttonPosition = tester.getCenter(addButton);
      expect(buttonPosition.dx, greaterThan(size.width / 2));
      expect(buttonPosition.dy, greaterThan(size.height / 2));
      await tester.tap(addButton);
      final exportMenu = tester.widget<PopupMenuButton<String>>(
        find.byType(PopupMenuButton<String>),
      );
      exportMenu.onSelected!('csv');
      await tester.tap(find.byTooltip('Back'));
      await tester.tap(find.text('Monthly'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Monthly Cash Activity'), findsOneWidget);
      expect(find.text('January 2026'), findsOneWidget);
      expect(find.text('February 2026'), findsOneWidget);
      expect(find.text('2 months with transactions'), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Monthly overflow at $size');
      await tester.tap(find.text('Yearly'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Yearly Cash Activity'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2 years with transactions'), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Yearly overflow at $size');
      await tester.tap(find.text('ACCOUNT BOOK'));
      await tester.pump();
      expect(history.view, CashBookHistoryView.daily);
      await tester.tap(find.text('Monthly'));
      await tester.pump();
      await tester.tap(find.byTooltip('Back to Account Book Home'));
      await tester.pump();
      expect(history.view, CashBookHistoryView.daily);
    }
    expect(addTaps, 3);
    expect(exportTaps, 3);
    expect(backTaps, 3);
    expect(homeTaps, 3);

    ctrl.setFilter(CashBookFilter.incomeOnly);
    await tester.pump();
    expect(find.text('No matching transactions this month'), findsOneWidget);
    expect(find.text('Clear Filters'), findsOneWidget);
    expect(tester.takeException(), isNull);

    ctrl.setFilter(CashBookFilter.all);
    await tester.pump();
    await tester.tap(find.byTooltip('Edit Opening Balance'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), '-5');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a valid amount of zero or more.'), findsOneWidget);
  });
}
