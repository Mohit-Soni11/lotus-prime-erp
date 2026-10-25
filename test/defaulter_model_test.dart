import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/customer/defaulter_model.dart';
import 'package:lotus_erp/ui/customer/defaulter/defaulter_data_table.dart';

void main() {
  test('risk queue defaults to newest invoice first', () {
    expect(DefaulterScreenState.initial().activeSort,
        DefaulterSortBy.newestInvoice);
  });

  testWidgets('risk account actions fit desktop and compact layouts',
      (tester) async {
    final account = _defaulter(
      riskLevel: DefaulterRiskLevel.critical,
      isNoticeEligible: true,
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [1600.0, 800.0, 460.0]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DefaulterDataTable(
            defaulters: [account],
            isLoading: false,
            onOpenAccount: (_) {},
            onOpenInterestEntry: (_) {},
            onOpenContactRecovery: (_) {},
          ),
        ),
      ));
      expect(find.text('Notice & Recovery'), findsOneWidget);
      expect(find.text('Total to Collect'), findsOneWidget);
      final noticeButton = find.ancestor(
        of: find.text('Notice & Recovery'),
        matching: find.byType(InkWell),
      );
      expect(
          tester.getTopRight(noticeButton.first).dx, greaterThan(width - 90));
      expect(tester.takeException(), isNull, reason: 'at width $width');
    }
  });

  testWidgets('closed recovery shows settlement and no collection action',
      (tester) async {
    final account = _defaulter(
      isRecoverySettled: true,
      isCollateralRecovery: true,
      recoveryDispositionStatus: 'MELTED',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DefaulterDataTable(
          defaulters: [account],
          showRecoveryHistory: true,
          isLoading: false,
          onOpenAccount: (_) {},
          onOpenInterestEntry: (_) {},
          onOpenContactRecovery: (_) {},
        ),
      ),
    ));

    expect(find.text('MELTED · ACCOUNT CLOSED'), findsOneWidget);
    expect(find.text('Item melted'), findsOneWidget);
    expect(find.text('Amount Recovered'), findsNothing);
    expect(find.text('Balance Due'), findsNothing);
    expect(find.text('View Recovery'), findsOneWidget);
    expect(find.text('Collect Payment'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('monitoring account keeps Notice & Recovery action',
      (tester) async {
    final account = _defaulter(
      isMaturityOverdue: true,
      isPaymentMonitoring: true,
      isNoticeEligible: true,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DefaulterDataTable(
          defaulters: [account],
          isLoading: false,
          onOpenAccount: (_) {},
          onOpenInterestEntry: (_) {},
          onOpenContactRecovery: (_) {},
        ),
      ),
    ));

    expect(find.text('MONITORING'), findsOneWidget);
    expect(find.text('Notice & Recovery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('completed recoveries do not inflate active risk exposure', () {
    final active = _defaulter();
    final closed = _defaulter(
      isRecoverySettled: true,
      isCollateralRecovery: true,
    );
    final stats = DefaulterStatsModel.fromList([active, closed]);

    expect(stats.totalRiskAccounts, 1);
    expect(stats.collateralRecoveryCount, 1);
    expect(stats.recoveryCompletedCount, 1);
    expect(stats.totalAmountDue, active.totalDue);
  });

  group('DefaulterModel overdue classification', () {
    test('includes matured accounts without interest paid before maturity', () {
      final account = _defaulter(
        isMaturityOverdue: true,
        totalReceived: 500,
        lastPaymentDate: DateTime(2026, 9, 1),
        hasInterestPaidBeforeMaturity: false,
        riskLevel: DefaulterRiskLevel.high,
      );

      expect(account.isOverdue, isTrue);
    });

    test('includes critical accounts when no interest was paid by maturity',
        () {
      final account = _defaulter(
        isMaturityOverdue: true,
        totalReceived: 0,
        lastPaymentDate: null,
        hasInterestPaidBeforeMaturity: false,
        riskLevel: DefaulterRiskLevel.critical,
      );

      expect(account.isOverdue, isTrue);
    });

    test(
        'includes matured accounts even when interest was paid before maturity',
        () {
      final account = _defaulter(
        isMaturityOverdue: true,
        totalReceived: 500,
        lastPaymentDate: DateTime(2026, 5, 1),
        hasInterestPaidBeforeMaturity: true,
        riskLevel: DefaulterRiskLevel.medium,
      );

      expect(account.isOverdue, isTrue);
    });

    test('does not treat interest-only overdue as overdue filter item', () {
      final account = _defaulter(
        isInterestOverdue: true,
        isMaturityOverdue: false,
        totalReceived: 500,
        lastPaymentDate: DateTime(2026, 9, 1),
        hasInterestPaidBeforeMaturity: false,
        riskLevel: DefaulterRiskLevel.medium,
      );

      expect(account.isOverdue, isFalse);
    });
  });
}

DefaulterModel _defaulter({
  bool isInterestOverdue = false,
  bool isMaturityOverdue = false,
  bool hasInterestPaidBeforeMaturity = false,
  double totalReceived = 0,
  DateTime? lastPaymentDate,
  DefaulterRiskLevel riskLevel = DefaulterRiskLevel.medium,
  bool isRecoverySettled = false,
  String? recoveryDispositionStatus,
  bool isCollateralRecovery = false,
  bool isPaymentMonitoring = false,
  bool isNoticeEligible = false,
}) {
  return DefaulterModel(
    loanId: 1,
    customerId: 1,
    customerName: 'Test Customer',
    mobile: '9999999999',
    city: 'Patna',
    address: 'Patna',
    customerType: 'Girvi',
    defaulterType: DefaulterType.loan,
    referenceNo: 'GRV-0001',
    itemSummary: '1 item',
    pledgedItemCount: 1,
    itemName: 'Ring',
    metalType: 'Gold',
    purity: '22KT',
    pieces: 1,
    grossWeight: 10,
    lessWeight: 0,
    statusLabel: 'Active',
    statusValue: 'ACTIVE',
    principalAmount: 10000,
    principalOutstanding: 10000,
    interestRate: 5,
    interestAccrued: 500,
    interestOutstanding: 500,
    totalDue: 10500,
    totalReceived: totalReceived,
    currentMonthReceived: 0,
    netWeight: 10,
    startDate: DateTime(2026, 1, 1),
    maturityDate: DateTime(2026, 6, 1),
    lastPaymentDate: lastPaymentDate,
    lastActivityAt: DateTime(2026, 9, 1),
    daysOverdue: 90,
    monthsOverdue: 3,
    unpaidInterestMonths: isInterestOverdue ? 3 : 0,
    maturityOverdueDays: isMaturityOverdue ? 90 : 0,
    isInterestOverdue: isInterestOverdue,
    isMaturityOverdue: isMaturityOverdue,
    hasInterestPaidBeforeMaturity: hasInterestPaidBeforeMaturity,
    isCollateralRecovery: isCollateralRecovery,
    isPaymentMonitoring: isPaymentMonitoring,
    isNoticeEligible: isNoticeEligible,
    isRecoverySettled: isRecoverySettled,
    recoveryDispositionStatus: recoveryDispositionStatus,
    recoverySettlementTotal: isRecoverySettled ? 11000 : 0,
    recoveredAmount: isRecoverySettled ? 10500 : 0,
    recoveryBalanceDue: isRecoverySettled ? 500 : 0,
    riskLevel: riskLevel,
    collectionStage: 'Monitoring',
    nextActionLabel: 'Review',
  );
}
