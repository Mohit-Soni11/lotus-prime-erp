import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';

final class PosInvoiceFileNaming {
  const PosInvoiceFileNaming._();

  static String pdfBaseName(PosInvoiceModel invoice) {
    final customerName =
        invoice.customerName.isNotEmpty ? invoice.customerName : 'Customer';
    final cleanName = customerName
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final cleanInvoice =
        invoice.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '_');
    final prefix = cleanName.isEmpty ? 'Customer' : cleanName;

    return '${prefix}_$cleanInvoice';
  }

  static String pdfFileName(PosInvoiceModel invoice) {
    return '${pdfBaseName(invoice)}.pdf';
  }
}
