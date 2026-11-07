import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_balance_verification.dart';
import 'package:lotus_erp/ui/report/day_book/day_book_eod_bank_verification.dart';

void main() {
  testWidgets('day closing shows saved bank opening and pending difference',
      (tester) async {
    final verification = DayBookBalanceVerification(
      date: DateTime(2026, 11, 7),
      verifiedAt: DateTime(2026, 11, 7, 9),
      expectedCash: 400,
      actualCash: 400,
      cashVariance: 0,
      expectedBank: 200,
      actualBank: 195,
      bankVariance: -5,
      bankReason: 'UPI settlement pending',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DayBookEodBankVerification(verification: verification),
      ),
    ));
    expect(find.text('Opening Bank Verification'), findsOneWidget);
    expect(find.textContaining('200.00'), findsOneWidget);
    expect(find.textContaining('195.00'), findsOneWidget);
    expect(find.text('-₹5.00'), findsOneWidget);
    expect(find.textContaining('UPI settlement pending'), findsOneWidget);
  });
}
