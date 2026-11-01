import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/finance/cash_book/cash_book_controller.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_summary_model.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_transaction_model.dart';
import 'package:lotus_erp/repositories/finance/cash_book_repository.dart';
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

void main() {
  testWidgets('cash book overview and empty ledger fit responsive windows',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final ctrl = CashBookController(repository: _CashBookFixture(db));
    addTearDown(() async {
      ctrl.dispose();
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
          listenable: ctrl,
          builder: (_, __) => Scaffold(
            appBar: CashBookAppBar(
              onBack: () {},
              status:
                  ctrl.isLoading ? SystemStatus.loading : SystemStatus.online,
              onAddEntry: () {},
              onSyncBills: () {},
            ),
            body: CashBookBody(ctrl: ctrl, onAddEntry: () {}),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'Overflow at $size');
      expect(find.text('CASH BOOK'), findsOneWidget);
      expect(find.text('Opening Balance'), findsOneWidget);
      expect(find.text('No transactions found'), findsOneWidget);
    }

    ctrl.searchCtrl.text = 'missing';
    await tester.pump();
    expect(find.text('No matching transactions'), findsOneWidget);
    expect(find.text('Clear Filters'), findsOneWidget);
    expect(tester.takeException(), isNull);

    ctrl.searchCtrl.clear();
    await tester.pump();
    await tester.tap(find.byTooltip('Edit Opening Balance'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), '-5');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Enter a valid amount of zero or more.'), findsOneWidget);
  });
}
