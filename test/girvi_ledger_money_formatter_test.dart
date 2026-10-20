import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/girvi/girvi_list/girvi_ledger_money_formatter.dart';

void main() {
  test('ledger amounts keep paise when present', () {
    expect(GirviLedgerMoneyFormatter.format(25000), 'Rs 25,000');
    expect(GirviLedgerMoneyFormatter.format(123.46), 'Rs 123.46');
    expect(GirviLedgerMoneyFormatter.format(0.49), 'Rs 0.49');
    expect(GirviLedgerMoneyFormatter.format(1234.567), 'Rs 1,234.57');
  });
}
