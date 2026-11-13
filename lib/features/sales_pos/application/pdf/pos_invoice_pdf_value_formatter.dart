import 'package:intl/intl.dart';

import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'pos_invoice_print_config.dart';

/// Keeps amounts and charge units consistent across every sales PDF layout.
class PosInvoicePdfValueFormatter {
  PosInvoicePdfValueFormatter._();

  static final NumberFormat _wholeMoney = NumberFormat('#,##,##0', 'en_IN');
  static final NumberFormat _fractionalMoney =
      NumberFormat('#,##,##0.00', 'en_IN');
  static final NumberFormat _compactNumber =
      NumberFormat('#,##,##0.##', 'en_IN');
  static final NumberFormat _weight = NumberFormat('#,##,##0.###', 'en_IN');

  static String amount(double value) {
    final paise = (value * 100).round();
    final rounded = paise / 100;
    return paise % 100 == 0
        ? _wholeMoney.format(rounded)
        : _fractionalMoney.format(rounded);
  }

  static String rupees(double value) => 'Rs ${amount(value)}';

  static String grams(double value) => _weight.format(value);

  static String ratePerGram(double value) => '${rupees(value)}/g';

  static String makingRate(SaleItemModel item) {
    final input = double.tryParse(
          item.makingCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0;
    if (input <= 0) return '-';

    switch (item.makingChargeType) {
      case MakingChargeType.percentage:
        return '${_compactNumber.format(input)}%';
      case MakingChargeType.perGram:
        return '${rupees(input)}/g';
      case MakingChargeType.perKg:
        return '${rupees(input)}/kg';
      case MakingChargeType.perPiece:
        final quantity = item.pcs > 1 ? ' × ${item.pcs}' : '';
        return 'Flat ${rupees(input)}$quantity';
    }
  }

  static String making(
    SaleItemModel item,
    BillSettings settings, {
    required bool isWholesale,
  }) {
    final basis = makingRate(item);
    if (settings.showMakingType) return basis;

    final total = isWholesale ? item.wholesaleLabourAmt : item.makingAmt;
    final amountLabel = rupees(total);
    return basis == '-' ? amountLabel : '$amountLabel ($basis)';
  }
}
