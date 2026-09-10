import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'pos_invoice_print_config.dart';

class PosInvoiceTaxDisplayPolicy {
  const PosInvoiceTaxDisplayPolicy._();

  static bool isTaxInvoice(PosInvoiceModel invoice) {
    return invoice.billType == BillType.gst;
  }

  static bool shouldShowHsnCode(
    PosInvoiceModel invoice,
    BillSettings settings,
  ) {
    return isTaxInvoice(invoice) && settings.showHsnCode;
  }

  static bool shouldShowGstBreakup(
    PosInvoiceModel invoice,
    BillSettings settings,
  ) {
    return isTaxInvoice(invoice) && settings.showGstBreakup;
  }
}
