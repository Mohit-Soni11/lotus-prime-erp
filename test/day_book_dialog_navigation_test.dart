import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/report/day_book/day_book_controller.dart';
import 'package:lotus_erp/models/finance/expense/expense_draft.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_balance_verification.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_balance_dialog.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_eod_dialog.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_income_dialog.dart';

void main() {
  testWidgets('Daily Closing shows carried balances without opening count',
      (tester) async {
    final controller = _UnverifiedClosingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
            builder: (context) => ElevatedButton(
                  onPressed: () => showDialog<ExpenseDraft>(
                    context: context,
                    builder: (_) => DayBookEodDialog(ctrl: controller),
                  ),
                  child: const Text('Open closing'),
                )),
      ),
    ));

    await tester.tap(find.text('Open closing'));
    await tester.pumpAndSettle();
    expect(find.text('System Closing · 11 Nov 2026'), findsOneWidget);
    expect(find.text('Cash Balance'), findsOneWidget);
    expect(find.text('Bank Balance'), findsOneWidget);
    expect(find.textContaining('Verify today’s opening cash and bank'),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daily Closing cancel and close dismiss the typed dialog',
      (tester) async {
    final controller = _EmptyClosingController();
    addTearDown(controller.dispose);
    ExpenseDraft? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
            builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<ExpenseDraft>(
                      context: context,
                      builder: (_) => DayBookEodDialog(ctrl: controller),
                    );
                  },
                  child: const Text('Open closing'),
                )),
      ),
    ));

    await tester.tap(find.text('Open closing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DayBookEodDialog), findsNothing);
    expect(result, isNull);

    await tester.tap(find.text('Open closing'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DayBookEodDialog), findsNothing);
    expect(result, isNull);
  });

  testWidgets('Add Cash Income cancel and close dismiss the dialog',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
            builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<bool>(
                      context: context,
                      builder: (_) => DayBookIncomeDialog(
                        date: DateTime(2026, 11, 11),
                        bankAccounts: const [],
                        onSave: ({
                          required amount,
                          required category,
                          required paymentMode,
                          bankAccountId,
                          customLabel,
                        }) async =>
                            false,
                      ),
                    );
                  },
                  child: const Text('Open income'),
                )),
      ),
    ));

    await tester.tap(find.text('Open income'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DayBookIncomeDialog), findsNothing);
    expect(result, isFalse);

    await tester.tap(find.text('Open income'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DayBookIncomeDialog), findsNothing);
    expect(result, isFalse);
  });

  testWidgets('Daily Balance cancel and close dismiss the typed dialog',
      (tester) async {
    DayBookBalanceDialogResult? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              result = await showDialog<DayBookBalanceDialogResult>(
                context: context,
                builder: (_) => DayBookBalanceDialog(
                  date: DateTime(2026, 11, 11),
                  expectedCash: 100,
                  expectedBank: 0,
                  onSave: ({
                    required actualCash,
                    required actualBank,
                    cashExpenseCategory,
                    cashReason,
                    bankReason,
                  }) =>
                      throw StateError('Saving is not part of this test.'),
                ),
              );
            },
            child: const Text('Open verification'),
          );
        }),
      ),
    ));

    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();
    expect(find.byType(DayBookBalanceDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DayBookBalanceDialog), findsNothing);
    expect(result, isNull);

    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DayBookBalanceDialog), findsNothing);
    expect(result, isNull);
  });
}

class _EmptyClosingController extends ChangeNotifier
    implements DayBookController {
  @override
  DateTime get selectedDate => DateTime(2026, 11, 11);

  @override
  DayBookSummary? get summary => null;

  @override
  DayBookBalanceVerification? get balanceVerification => null;

  @override
  double get physicalCashAmount => 0;

  @override
  bool get isCashMatched => false;

  @override
  bool get isMetalPositionVerified => false;

  @override
  bool get isCustodyPositionVerified => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnverifiedClosingController extends _EmptyClosingController {
  @override
  DayBookSummary get summary => DayBookSummary(
        date: selectedDate,
        moneyFlow: DayBookMoneyFlow(
          openingCash: 500,
          openingBank: 200,
          entries: const [],
        ),
      );

  final _denomination = DenominationCount();
  final _counts = List.generate(7, (_) => TextEditingController(text: '0'));

  @override
  DenominationCount get denomination => _denomination;
  @override
  TextEditingController get denom500Ctrl => _counts[0];
  @override
  TextEditingController get denom200Ctrl => _counts[1];
  @override
  TextEditingController get denom100Ctrl => _counts[2];
  @override
  TextEditingController get denom50Ctrl => _counts[3];
  @override
  TextEditingController get denom20Ctrl => _counts[4];
  @override
  TextEditingController get denom10Ctrl => _counts[5];
  @override
  TextEditingController get denomCoinsCtrl => _counts[6];

  @override
  void dispose() {
    for (final controller in _counts) {
      controller.dispose();
    }
    super.dispose();
  }
}
