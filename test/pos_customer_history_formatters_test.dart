import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/sales_orders/sales_pos/customer_history/pos_customer_history_formatters.dart';

void main() {
  test('customer history amount shows full invoice due without compact suffix',
      () {
    expect(PosCustomerHistoryFormatters.amount(94000), 'Rs 94,000.00');
    expect(PosCustomerHistoryFormatters.amount(4400), 'Rs 4,400.00');
    expect(PosCustomerHistoryFormatters.amount(89600), 'Rs 89,600.00');
  });
}
