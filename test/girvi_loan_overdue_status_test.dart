import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';

void main() {
  test('stored overdue status stays overdue and maturity uses calendar days',
      () {
    final today = DateTime.now();
    final maturityToday = DateTime(today.year, today.month, today.day);
    final maturityYesterday = maturityToday.subtract(const Duration(days: 1));

    expect(_loan(GirviStatus.overdue, maturityYesterday).isOverdue, isTrue);
    expect(_loan(GirviStatus.active, maturityYesterday).isOverdue, isTrue);
    expect(
        _loan(GirviStatus.partialRelease, maturityYesterday).isOverdue, isTrue);
    expect(_loan(GirviStatus.active, maturityToday).isOverdue, isFalse);
    expect(_loan(GirviStatus.readyForDelivery, maturityYesterday).isOverdue,
        isFalse);
    expect(_loan(GirviStatus.released, maturityYesterday).isOverdue, isFalse);
  });
}

GirviLoanModel _loan(GirviStatus status, DateTime maturityDate) {
  return GirviLoanModel(
    id: 1,
    ticketNo: 'GRV-OVERDUE',
    customerId: 1,
    itemDescription: 'Gold ring',
    itemCount: 1,
    metalType: 'Gold',
    metalPurity: '22KT',
    grossWeight: 8,
    stoneWeight: 0,
    netWeight: 8,
    loanAmount: 3000,
    interestRate: 5,
    durationMonths: 5,
    disbursementMode: 'Cash',
    startDate: DateTime(2025, 5, 5),
    maturityDate: maturityDate,
    createdAt: DateTime(2025, 5, 5),
    status: status.dbValue,
  );
}
