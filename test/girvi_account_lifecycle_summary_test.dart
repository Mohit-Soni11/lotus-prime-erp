import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/girvi/girvi_account_lifecycle_summary.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';

void main() {
  test('shows running, settlement pending and delivery pending for open loans',
      () {
    final account = _account(
      status: GirviStatus.active,
      startDate: DateTime(2026, 1, 10),
    );

    final summary = GirviAccountLifecycleSummary.fromAccount(
      account,
      now: DateTime(2026, 4, 12),
      moneyLabel: _money,
    );

    expect(summary.settlementComplete, isFalse);
    expect(summary.delivered, isFalse);
    expect(summary.period.kind, GirviLifecycleTileKind.runningPeriod);
    expect(summary.period.value, '3 months 2 days');
    expect(summary.period.subtitle, '92 total days | 4 bill months');
    expect(summary.settlement.kind, GirviLifecycleTileKind.settlementPending);
    expect(summary.settlement.title, 'Settlement Pending');
    expect(summary.settlement.value, startsWith('Rs '));
    expect(summary.delivery.kind, GirviLifecycleTileKind.deliveryPending);
    expect(summary.delivery.value, 'Not delivered');
  });

  test('shows ready delivery when settlement is complete but item is not sent',
      () {
    final account = _account(
      status: GirviStatus.readyForDelivery,
      startDate: DateTime(2026, 3, 1),
      expectedDeliveryDate: DateTime(2026, 6, 25),
    );

    final summary = GirviAccountLifecycleSummary.fromAccount(
      account,
      now: DateTime(2026, 6, 22),
      dateLabel: _date,
      moneyLabel: _money,
    );

    expect(summary.settlementComplete, isTrue);
    expect(summary.delivered, isFalse);
    expect(summary.settlement.kind, GirviLifecycleTileKind.settlementComplete);
    expect(summary.settlement.value, 'Balance cleared');
    expect(summary.delivery.kind, GirviLifecycleTileKind.deliveryReady);
    expect(summary.delivery.value, 'Pickup pending');
    expect(summary.delivery.subtitle, 'Expected 25/06/2026');
  });

  test('shows closed period and delivered status for completed accounts', () {
    final deliveredAt = DateTime(2026, 6, 21, 19, 35);
    final account = _account(
      status: GirviStatus.released,
      startDate: DateTime(2026, 2, 5),
      releaseDate: DateTime(2026, 6, 20),
      deliveredAt: deliveredAt,
    );

    final summary = GirviAccountLifecycleSummary.fromAccount(
      account,
      now: DateTime(2026, 6, 22),
      dateTimeLabel: _dateTime,
      moneyLabel: _money,
    );

    expect(summary.settlementComplete, isTrue);
    expect(summary.delivered, isTrue);
    expect(summary.period.kind, GirviLifecycleTileKind.closedPeriod);
    expect(summary.delivery.kind, GirviLifecycleTileKind.deliveryDelivered);
    expect(summary.delivery.title, 'Delivery Delivered');
    expect(summary.delivery.subtitle, 'Done 21/06/2026 19:35');
  });
}

GirviLoanWithCustomer _account({
  required GirviStatus status,
  required DateTime startDate,
  DateTime? releaseDate,
  DateTime? expectedDeliveryDate,
  DateTime? deliveredAt,
}) {
  return GirviLoanWithCustomer(
    loan: GirviLoanModel(
      id: 1,
      ticketNo: 'GRV-LIFE-001',
      customerId: 1,
      itemDescription: 'Gold ring',
      itemCount: 1,
      metalType: 'Gold',
      metalPurity: '22K',
      grossWeight: 4,
      stoneWeight: 0,
      netWeight: 4,
      ratePerGram: 7800,
      totalValue: 31200,
      ltvPercent: 38.46,
      loanAmount: 12000,
      interestRate: 5,
      durationMonths: 12,
      disbursementMode: 'Cash',
      startDate: startDate,
      releaseDate: releaseDate,
      expectedDeliveryDate: expectedDeliveryDate,
      deliveredAt: deliveredAt,
      status: status.dbValue,
      createdAt: startDate,
    ),
    customerName: 'Reyansh Soni',
    customerMobile: '9304479436',
    customerAddress: 'Patna',
  );
}

String _money(double value) => 'Rs ${value.round()}';

String _date(DateTime? value) {
  if (value == null) return 'Not set';
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String _dateTime(DateTime? value) {
  if (value == null) return 'Not set';
  return '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
