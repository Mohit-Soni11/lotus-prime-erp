import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/customer/risk_payment_monitoring.dart';

void main() {
  final maturity = DateTime(2025, 6, 1);
  final today = DateTime(2026, 10, 20);

  bool applies(
    DateTime? payment, {
    bool overdue = true,
    double due = 1000,
  }) =>
      RiskPaymentMonitoring.applies(
        isMaturityOverdue: overdue,
        totalDue: due,
        maturityDate: maturity,
        lastPaymentDate: payment,
        asOf: today,
      );

  test('recent post-maturity payment moves pending account to monitoring', () {
    expect(applies(DateTime(2026, 10, 19)), isTrue);
  });

  test('old payment no longer masks collection severity', () {
    expect(applies(DateTime(2026, 8, 1)), isFalse);
  });

  test('pre-maturity and future payments cannot trigger monitoring', () {
    expect(applies(DateTime(2025, 5, 31)), isFalse);
    expect(applies(DateTime(2025, 6, 1)), isFalse);
    expect(applies(DateTime(2026, 10, 21)), isFalse);
  });

  test('settled and unmatured accounts do not enter monitoring', () {
    expect(applies(DateTime(2026, 10, 19), due: 0), isFalse);
    expect(applies(DateTime(2026, 10, 19), overdue: false), isFalse);
  });
}
