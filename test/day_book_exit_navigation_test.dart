import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lotus_erp/constants/app_routes.dart';
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
        '${exit ? 'Exit' : 'Report'} opens closing first and uses the shared opening form',
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
          find.widgetWithText(TextField, 'Counted bank balance'), '0');
      await tester.pump();
      expect(_closeButton(tester).onPressed, isNull);

      await tester.ensureVisible(find.text('Verify Opening Balance'));
      await tester.tap(find.text('Verify Opening Balance'));
      await tester.pumpAndSettle();
      final form = tester
          .widget<DayBookBalanceDialog>(find.byType(DayBookBalanceDialog));
      expect(form.fullScreen, isTrue);
      expect(form.date, controller.selectedDate);
      expect(form.expectedCash, 0);
      expect(form.expectedBank, 0);

      // Cancelling verification returns to closing without authorizing exit.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(DayBookEodDialog), findsOneWidget);
      expect(controller.balanceVerification, isNull);
      expect(_closeButton(tester).onPressed, isNull);

      await tester.ensureVisible(find.text('Verify Opening Balance'));
      await tester.tap(find.text('Verify Opening Balance'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('actual-cash')), '0');
      await tester.enterText(find.byKey(const ValueKey('actual-bank')), '0');
      await tester.tap(find.text('Save & Verify'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(controller.balanceVerification, isNotNull);
      expect(find.byType(DayBookEodDialog), findsOneWidget);
      expect(find.text('Verify Opening Balance'), findsNothing);

      // Opening verification preserves the closing count already entered.
      expect(_closeButton(tester).onPressed, isNotNull);
      await tester.tap(find.text('Verify & Close Day'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(controller.summary.isDayLocked, isTrue);
      expect(find.byType(DayBookEodDialog), findsNothing);
      expect(find.byType(DayBookScreen), exit ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cancelling exit closing returns directly to the caller',
      (tester) async {
    final controller = _WorkflowController();
    await _open(tester, controller, exit: true);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(DayBookScreen), findsNothing);
    expect(find.text('Open workflow'), findsOneWidget);
    expect(controller.summary.isDayLocked, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening shortage expense returns to the active closing form',
      (tester) async {
    final controller = _WorkflowController(openingCash: 100);
    await _open(tester, controller, exit: true);
    await tester.ensureVisible(find.text('Verify Opening Balance'));
    await tester.tap(find.text('Verify Opening Balance'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<DayBookBalanceDialog>(find.byType(DayBookBalanceDialog))
            .expectedCash,
        100);
    await tester.enterText(find.byKey(const ValueKey('actual-cash')), '0');
    await tester.enterText(find.byKey(const ValueKey('actual-bank')), '0');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mismatch Transfer'));
    await tester.pumpAndSettle();
    expect(find.text('Expense draft: 100.0'), findsOneWidget);
    expect(find.text('Expense date: 2026-11-20T00:00:00.000'), findsOneWidget);
    await tester.tap(find.text('Back to closing'));
    await tester.pumpAndSettle();
    expect(find.byType(DayBookEodDialog), findsOneWidget);
    expect(controller.summary.isDayLocked, isFalse);
    expect(controller.balanceVerification, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(DayBookScreen), findsNothing);
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
    expect(find.byType(DayBookScreen), findsNothing);
    expect(controller.balanceVerification, isNull);
    expect(tester.takeException(), isNull);
  });
}

FilledButton _closeButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Verify & Close Day'));

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
            onPressed: () => context.pop(),
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
  _WorkflowController({this.openingCash = 0});
  final double openingCash;
  @override
  DateTime get selectedDate => DateTime(2026, 11, 20);
  bool _locked = false;
  DayBookBalanceVerification? _verification;
  final _counts = List.generate(7, (_) => TextEditingController(text: '0'));

  @override
  DayBookSummary get summary => DayBookSummary(
        date: selectedDate,
        isDayLocked: _locked,
        moneyFlow: DayBookMoneyFlow(
            openingCash: openingCash, openingBank: 0, entries: const []),
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
    _locked = _verification != null && physicalBank == 0;
    notifyListeners();
    return _locked;
  }

  @override
  Future<void> loadData({bool silent = false}) async {}

  @override
  void dispose() {
    for (final count in _counts) {
      count.dispose();
    }
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
