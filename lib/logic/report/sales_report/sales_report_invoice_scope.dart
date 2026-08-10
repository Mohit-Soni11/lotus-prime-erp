import '../../../models/reports/sales_report/sales_report_models.dart';

List<SalesReportInvoiceRow> scopeSalesReportInvoicesToItems({
  required List<SalesReportInvoiceRow> invoices,
  required List<SalesReportItemRow> items,
}) {
  final itemsByBill = <int, List<SalesReportItemRow>>{};
  for (final item in items) {
    itemsByBill.putIfAbsent(item.billId, () => []).add(item);
  }

  final scoped = <SalesReportInvoiceRow>[];
  for (final invoice in invoices) {
    final billItems = itemsByBill[invoice.billId] ?? const [];
    if (billItems.isEmpty) continue;

    final scopedGross = billItems.fold<double>(
      0,
      (total, item) => total + item.itemTotal,
    );
    final ratio = _allocationRatio(
      scopedGross: scopedGross,
      invoiceGross: invoice.grossAmount,
    );
    final metalMix = billItems
        .map((item) => item.metalType.trim().toUpperCase())
        .where((metal) => metal.isNotEmpty)
        .toSet()
        .join(',');

    scoped.add(
      SalesReportInvoiceRow(
        billId: invoice.billId,
        billNo: invoice.billNo,
        billDate: invoice.billDate,
        customerName: invoice.customerName,
        mobile: invoice.mobile,
        billType: invoice.billType,
        paymentStatus: invoice.paymentStatus,
        isGst: invoice.isGst,
        grossAmount: scopedGross,
        discountAmount: invoice.discountAmount * ratio,
        taxableAmount: invoice.taxableAmount > 0.005
            ? invoice.taxableAmount * ratio
            : scopedGross - (invoice.discountAmount * ratio),
        gstAmount: invoice.gstAmount * ratio,
        roundOffAmount: invoice.roundOffAmount * ratio,
        finalAmount: invoice.finalAmount * ratio,
        paidAmount: invoice.paidAmount * ratio,
        dueAmount: invoice.dueAmount * ratio,
        cashAmount: invoice.cashAmount * ratio,
        upiAmount: invoice.upiAmount * ratio,
        cardAmount: invoice.cardAmount * ratio,
        advanceAmount: invoice.advanceAmount * ratio,
        makingAmount: invoice.makingAmount * ratio,
        tradeInDeduction: invoice.tradeInDeduction * ratio,
        itemCount: billItems.length,
        metalMix: metalMix,
      ),
    );
  }

  return scoped;
}

double _allocationRatio({
  required double scopedGross,
  required double invoiceGross,
}) {
  if (scopedGross <= 0.005) return 0;
  if (invoiceGross.abs() <= 0.005) return 1;
  return scopedGross / invoiceGross;
}
