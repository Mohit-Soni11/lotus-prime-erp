import '../../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';

final class PosInvoiceQuantityText {
  const PosInvoiceQuantityText._();

  static String format(SaleItemModel item) =>
      '${item.pcs} ${item.invoiceUnitLabel}';

  static bool showInDescription(SaleItemModel item, bool showQuantity) =>
      item.invoiceUnitLabelOverride != null || (showQuantity && item.pcs > 1);
}
