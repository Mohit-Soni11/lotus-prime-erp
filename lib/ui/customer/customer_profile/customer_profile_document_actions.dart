part of 'customer_profile_screen.dart';

extension _ProfileDocumentActions on _CustomerProfileScreenState {
  Future<void> _previewBillPdf(int billId, String billNo) async {
    await showIssuedPdfPreview(
      context: context,
      title: 'Sales Bill $billNo',
      pdfBytesFuture: _loadIssuedSalesInvoice(
        billId,
        billNo,
        notifyUnavailable: false,
      ),
    );
  }

  Future<void> _printBillPdf(int billId, String billNo) async {
    final bytes = await _loadIssuedSalesInvoice(billId, billNo);
    if (!mounted || bytes == null) return;
    await Printing.layoutPdf(
      name: 'sales_invoice_$billNo.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _previewLinkedDocumentPdf(
    CustomerLinkedDocumentModel document,
  ) async {
    final bytes = await _loadIssuedReturnVoucher(document);
    if (!mounted || bytes == null) return;
    await _showCleanPdfPreview(bytes);
  }

  Future<void> _printLinkedDocumentPdf(
    CustomerLinkedDocumentModel document,
  ) async {
    final bytes = await _loadIssuedReturnVoucher(document);
    if (!mounted || bytes == null) return;
    await Printing.layoutPdf(
      name: 'return_voucher_${document.documentNo}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _previewGirviInvoice(CustomerLoanModel loan) async {
    final bytes = await _loadIssuedGirviInvoice(loan);
    if (!mounted || bytes == null) return;
    await _showCleanPdfPreview(bytes);
  }

  Future<void> _printGirviInvoice(CustomerLoanModel loan) async {
    final bytes = await _loadIssuedGirviInvoice(loan);
    if (!mounted || bytes == null) return;
    await Printing.layoutPdf(
      name: 'girvi_invoice_${loan.loanNo}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _previewAdvancePdf(CustomerAdvanceOrderModel order) async {
    final bytes = await _loadIssuedBookingInvoice(order);
    if (!mounted || bytes == null) return;
    await _showCleanPdfPreview(bytes);
  }

  Future<void> _printAdvancePdf(CustomerAdvanceOrderModel order) async {
    final bytes = await _loadIssuedBookingInvoice(order);
    if (!mounted || bytes == null) return;
    await Printing.layoutPdf(
      name: 'booking_invoice_${order.orderNo}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _showCleanPdfPreview(Uint8List bytes) {
    return showIssuedPdfPreview(
      context: context,
      pdfBytes: bytes,
    );
  }
}
