import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/girvi_notice_eligibility.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';

void main() {
  bool eligible({
    GirviStatus status = GirviStatus.overdue,
    DateTime? maturity,
    double principal = 5000,
    double interest = 200,
    DateTime? asOf,
  }) =>
      GirviNoticeEligibility.hasMaturedBalance(
        status: status,
        maturityDate: maturity ?? DateTime(2026, 9, 20),
        principalDue: principal,
        interestDue: interest,
        asOf: asOf ?? DateTime(2026, 10, 20),
      );

  test('matured pledge remains eligible after a partial payment', () {
    expect(eligible(principal: 3000, interest: 50), isTrue);
    expect(eligible(principal: 0, interest: 50), isTrue);
  });

  test('eligibility begins the day after maturity', () {
    expect(eligible(asOf: DateTime(2026, 9, 20, 23)), isFalse);
    expect(eligible(asOf: DateTime(2026, 9, 21)), isTrue);
  });

  test('settled and closed loans cannot start a new notice', () {
    expect(eligible(principal: 0, interest: 0), isFalse);
    expect(eligible(status: GirviStatus.readyForDelivery), isFalse);
    expect(eligible(status: GirviStatus.released), isFalse);
    expect(eligible(status: GirviStatus.auctioned), isFalse);
  });
}
