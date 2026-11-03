import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/reports/day_book/day_book_money_flow.dart';

void main() {
  test('split payments retain account, mode and cheque clearing state', () {
    final date = DateTime(2026, 6, 25);
    DayBookMoneyEntry bank(String id, String mode, double amount,
            {String? chequeStatus, bool reconciled = false}) =>
        DayBookMoneyEntry(
          date: date,
          amount: amount,
          incoming: true,
          isCash: false,
          category: 'SALE_PAYMENT',
          paymentMode: mode,
          transactionId: id,
          accountName: 'Current Account',
          referenceId: 'INV-1',
          chequeStatus: chequeStatus,
          isReconciled: reconciled,
        );
    final flow = DayBookMoneyFlow(
      openingCash: 0,
      openingBank: 100,
      entries: [
        bank('U-1', 'UPI', 50, reconciled: true),
        bank('C-1', 'CHEQUE', 25, chequeStatus: 'PRESENTED'),
        bank('N-1', 'NEFT', 75),
      ],
    );
    expect(flow.bankIn, 150);
    expect(flow.byMode(incoming: true), {'UPI': 50, 'CHEQUE': 25, 'NEFT': 75});
    expect(flow.byBankAccount(incoming: true), {'Current Account': 150});
    expect(flow.byBankReconciliation(incoming: true), {
      'Statement Matched': 50,
      'Uncleared Cheque': 25,
      'Unreconciled': 75,
    });
    expect(flow.unclearedChequeIn, 25);
    expect(flow.closingBank, 250);
  });
}
