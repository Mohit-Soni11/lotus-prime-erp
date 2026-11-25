import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/core/router/app_back_navigation.dart';
import 'package:lotus_erp/logic/report/day_book/day_book_controller.dart';
import 'package:lotus_erp/models/finance/cash_book/cash_book_enums.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_balance_verification.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_models.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_balance_dialog.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_eod_dialog.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_screen.dart';

void main() {
  for (final exit in [false, true]) {
    testWidgets(
        '${exit ? 'Exit' : 'Report'} verifies closing without opening verification',
        (tester) async {
      final controller = _WorkflowController();
      await _open(tester, controller, exit: exit);

      expect(find.byType(DayBookEodDialog), findsOneWidget);
      expect(find.byType(DayBookBalanceDialog), findsNothing);
      expect(
          tester
              .widget<DayBookEodDialog>(find.byType(DayBookEodDialog))
              .fullScreen,
          isTrue);
      expect(_closeButton(tester).onPressed, isNull);

      await tester.enterText(
          find.widgetWithText(TextField, 'Actual bank balance'), '0');
      await tester.pump();
      expect(_closeButton(tester).onPressed, isNull);
      expect(find.text('Verify Opening Balance'), findsNothing);
      expect(_closeButton(tester).onPressed, isNull);
      await tester.ensureVisible(find
          .text('I counted the cash drawer and confirm a zero cash balance.'));
      await tester.tap(find
          .text('I counted the cash drawer and confirm a zero cash balance.'));
      await tester.pump();
      expect(_closeButton(tester).onPressed, isNotNull);
      await tester.tap(find.text('Verify Day Closing'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(controller.summary.isDayLocked, isTrue);
      expect(find.byType(DayBookEodDialog), findsNothing);
      expect(find.byType(DayBookScreen), exit ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Back from exit closing returns directly to the caller',
      (tester) async {
    final controller = _WorkflowController();
    await _open(tester, controller, exit: true);
    expect(find.text('Cancel'), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(DayBookScreen), findsNothing);
    expect(find.text('Open workflow'), findsOneWidget);
    expect(controller.summary.isDayLocked, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one-time closing keeps Day Book usable after verification',
      (tester) async {
    final controller = _WorkflowController();
    await _open(tester, controller, action: 'close');
    await tester.enterText(find.byKey(const ValueKey('day-closing-bank')), '0');
    await tester.ensureVisible(find
        .text('I counted the cash drawer and confirm a zero cash balance.'));
    await tester.tap(find
        .text('I counted the cash drawer and confirm a zero cash balance.'));
    await tester.pump();
    await tester.tap(find.text('Verify Day Closing'));
    await tester.pumpAndSettle();

    expect(controller.summary.isDayLocked, isTrue);
    expect(find.byType(DayBookScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Open workflow'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expense Back returns to the pending Day Closing draft',
      (tester) async {
    final controller = _WorkflowController(openingCash: 100);
    await _open(tester, controller);
    await tester.enterText(find.byKey(const ValueKey('day-closing-bank')), '0');
    await tester.pump();
    await tester.tap(find.text('Cash Shortage'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Expense draft:'), findsOneWidget);
    await tester.tap(find.text('Back to closing'));
    await tester.pumpAndSettle();
    expect(find.byType(DayBookEodDialog), findsOneWidget);
    expect(find.text('Cash Shortage'), findsOneWidget);
    expect(controller.closingBankCtrl.text, '0');
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening verification action uses the same full-window form',
      (tester) async {
    final controller = _WorkflowController();
    await _open(tester, controller, action: 'verify');
    expect(find.byType(DayBookBalanceDialog), findsOneWidget);
    expect(find.byType(DayBookEodDialog), findsNothing);
    expect(
        tester
            .widget<DayBookBalanceDialog>(find.byType(DayBookBalanceDialog))
            .fullScreen,
        isTrue);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(DayBookScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(DayBookScreen), findsNothing);
    expect(controller.balanceVerification, isNull);
    expect(tester.takeException(), isNull);
  });
}

FilledButton _closeButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Verify Day Closing'));

Future<void> _open(WidgetTester tester, _WorkflowController controller,
    {bool exit = false, String? action}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(controller.dispose);
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, _) => Scaffold(
          body: TextButton(
        onPressed: () => context.push('/day-book'),
        child: const Text('Open workflow'),
      )),
    ),
    GoRoute(
      path: '/day-book',
      builder: (context, _) => DayBookScreen(
        controller: controller,
        initialDate: controller.selectedDate,
        initialAction: action ?? (exit ? 'close' : null),
        exitAfterClose: exit,
      ),
    ),
    GoRoute(
      path: RoutePaths.financeExpense,
      builder: (context, state) => Scaffold(
        body: Column(children: [
          Text('Expense draft: ${state.extra}'),
          Text('Expense date: ${state.uri.queryParameters['date']}'),
          TextButton(
            onPressed: () => AppBackNavigation.backOr(context, '/'),
            child: const Text('Back to closing'),
          ),
        ]),
      ),
    ),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
  ));
  await tester.tap(find.text('Open workflow'));
  await tester.pumpAndSettle();
  if (!exit && action == null) {
    await tester.tap(find.text('Day Closing'));
    await tester.pumpAndSettle();
  }
}

class _WorkflowController extends ChangeNotifier implements DayBookController {
  _WorkflowController({this.openingCash = 0}) {
    closingCashCountEntered = openingCash > 0;
  }

  final double openingCash;

  @override
  final TextEditingController closingBankCtrl = TextEditingController();
  @override
  bool closingCashCountEntered = false;
  @override
  bool closingZeroCashConfirmed = false;

  @override
  void markClosingCashCountEntered() {
    closingCashCountEntered = true;
    notifyListeners();
  }

  @override
  void setClosingZeroCashConfirmed(bool value) {
    closingZeroCashConfirmed = value;
    notifyListeners();
  }

  @override
  void resetClosingDraft() {
    closingBankCtrl.clear();
    closingCashCountEntered = false;
    closingZeroCashConfirmed = false;
    notifyListeners();
  }

  @override
  DateTime get selectedDate => DateTime(2026, 11, 20);
  bool _locked = false;
  bool _lastCloseSucceeded = false;
  @override
  bool get lastCloseSucceeded => _lastCloseSucceeded;
  DayBookBalanceVerification? _verification;
  final _counts = List.generate(7, (_) => TextEditingController(text: '0'));

  @override
  DayBookSummary get summary => DayBookSummary(
        date: selectedDate,
        isDayLocked: _locked,
        moneyFlow: DayBookMoneyFlow(
          openingCash: openingCash,
          openingBank: 0,
          entries: const [],
        ),
      );
  @override
  DayBookBalanceVerification? get balanceVerification => _verification;
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  bool get isToday => true;
  @override
  bool get canGoNext => false;
  @override
  bool get isCashMatched => true;
  @override
  bool get isMetalPositionVerified => true;
  @override
  bool get isRecordedMetalPositionConsistent => true;
  @override
  bool get isCustodyPositionVerified => true;
  @override
  double get physicalCashAmount => 0;
  @override
  DenominationCount get denomination => DenominationCount();
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
  Future<DayBookBalanceVerification> verifyBalance({
    required double actualCash,
    required double actualBank,
    ExpenseCategory? cashExpenseCategory,
    String? cashReason,
    String? bankReason,
  }) async {
    _verification = DayBookBalanceVerification(
      date: selectedDate,
      verifiedAt: selectedDate,
      expectedCash: 0,
      actualCash: actualCash,
      cashVariance: actualCash,
      expectedBank: 0,
      actualBank: actualBank,
      bankVariance: actualBank,
    );
    notifyListeners();
    return _verification!;
  }

  @override
  Future<bool> closeDay({required double physicalBank}) async {
    _locked = physicalBank == 0;
    _lastCloseSucceeded = _locked;
    notifyListeners();
    return _locked;
  }

  @override
  Future<void> loadData({bool silent = false}) async {}

  @override
  void dispose() {
    closingBankCtrl.dispose();
    for (final count in _counts) {
      count.dispose();
    }
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
