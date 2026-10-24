import 'package:intl/intl.dart';

String recoveryCompletionNote({
  required String dispositionMethod,
  required String ticketNo,
  required double amountDue,
  required double recoveredAmount,
  required DateTime recoveredAt,
  String remarks = '',
}) {
  final action = dispositionMethod == 'SOLD' ? 'sold' : 'melted';
  final date = DateFormat('dd MMM yyyy').format(recoveredAt);
  final money = NumberFormat('#,##,##0.00', 'en_IN');
  final surplus = recoveredAmount - amountDue;
  final recoveryDue =
      amountDue > recoveredAmount ? amountDue - recoveredAmount : 0.0;
  final audit =
      StringBuffer('Pledged item $action on $date for account $ticketNo. ');
  if (dispositionMethod == 'MELTED') {
    audit.write('No cash or bank receipt was recorded. ');
  } else {
    audit.write(
        'Actual sale proceeds received: Rs ${money.format(recoveredAmount)}. ');
  }
  audit.write('Account closed. ');
  if (recoveryDue > 0.01) {
    audit.write('Recovery due at closure: Rs ${money.format(recoveryDue)}.');
  } else {
    audit.write('Recovery due at closure: Rs 0.00.');
  }
  if (surplus > 0.01) {
    audit.write(' Rs ${money.format(surplus)} recorded as customer surplus.');
  }
  final extra = remarks.trim();
  if (extra.isNotEmpty) audit.write(' Note: $extra');
  return audit.toString();
}
