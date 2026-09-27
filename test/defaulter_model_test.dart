import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/customer/defaulter_model.dart';

void main() {
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

    test('excludes matured accounts when interest was paid before maturity',
        () {
      final account = _defaulter(
        isMaturityOverdue: true,
        totalReceived: 500,
        lastPaymentDate: DateTime(2026, 5, 1),
        hasInterestPaidBeforeMaturity: true,
        riskLevel: DefaulterRiskLevel.medium,
      );

      expect(account.isOverdue, isFalse);
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
    totalItemValue: 20000,
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
    riskLevel: riskLevel,
    collectionStage: 'Monitoring',
    nextActionLabel: 'Review',
  );
}
