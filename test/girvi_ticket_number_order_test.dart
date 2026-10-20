import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/girvi_ticket_number_order.dart';

void main() {
  test('natural ticket order handles numeric suffixes and mixed prefixes', () {
    final tickets = [
      'GRV-10',
      'GRV-2',
      'GRV-0013',
      'GRV-0011',
      'GRV-0012',
      'GRV-A-2',
      'GRV-A-10',
    ]..sort(GirviTicketNumberOrder.compare);

    expect(tickets, [
      'GRV-2',
      'GRV-10',
      'GRV-0011',
      'GRV-0012',
      'GRV-0013',
      'GRV-A-2',
      'GRV-A-10',
    ]);
  });
}
