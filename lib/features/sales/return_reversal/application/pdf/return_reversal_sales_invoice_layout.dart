part of 'return_reversal_sales_invoice_pdf_service.dart';

LotusPrintableDocument _printableDocument({
  required ShopPrintDocumentProfile shopProfile,
  required ReturnReversalSourceDocument sourceDocument,
  required _InvoiceCopyData invoiceData,
  required ReturnReversalSalesInvoiceCopyMode mode,
  required String templateId,
}) {
  final template = PrintTemplateRegistry.byId(templateId);
  return LotusPrintableDocument(
    shopProfile: shopProfile,
    template: template,
    profile: PrintTemplatePdfProfile.forTemplate(template.id),
    title: mode.title,
    subtitle: mode == ReturnReversalSalesInvoiceCopyMode.original
        ? 'Original bill copy'
        : 'Return deducted bill copy',
    documentNumberLabel: 'Invoice No',
    documentNumber: sourceDocument.documentNo,
    documentDateLabel: 'Invoice Date',
    documentDate: _formatDate(sourceDocument.documentDate),
    badgeLabel: mode.badgeLabel,
    primaryPanel: _customerPanel(sourceDocument),
    secondaryPanel: _invoicePanel(sourceDocument, invoiceData, mode),
    itemTable: _itemTable(invoiceData.lines, mode),
    settlementPanels: [
      _totalsPanel(sourceDocument, invoiceData, mode),
      if (mode == ReturnReversalSalesInvoiceCopyMode.updatedAfterReturn)
        _returnAdjustmentPanel(invoiceData),
    ],
    policySections: const [],
    footerMessage:
        'Computer generated ${mode.title.toLowerCase()} from Lotus ERP.',
    showHeaderDocumentMeta: true,
    showHeaderBadge: true,
    useFallbackShopName: true,
    renderPolicySectionsAsPages: false,
    startPolicySectionsOnNewPage: false,
    showLegalSignatureFooter: true,
  );
}

LotusPrintablePanel _customerPanel(
  ReturnReversalSourceDocument sourceDocument,
) {
  return LotusPrintablePanel(
    title: 'CUSTOMER DETAILS',
    details: [
      LotusPrintableDetail(
        iconKey: 'customer',
        label: 'Customer',
        value: _fallback(sourceDocument.customerName, 'Walk-in Customer'),
        highlight: true,
      ),
      if (sourceDocument.mobile.trim().isNotEmpty)
        LotusPrintableDetail(
          iconKey: 'phone',
          label: 'Mobile',
          value: sourceDocument.mobile.trim(),
        ),
      if (sourceDocument.address.trim().isNotEmpty)
        LotusPrintableDetail(
          iconKey: 'location',
          label: 'Address',
          value: sourceDocument.address.trim(),
          multiline: true,
        ),
    ],
  );
}

LotusPrintablePanel _invoicePanel(
  ReturnReversalSourceDocument sourceDocument,
  _InvoiceCopyData invoiceData,
  ReturnReversalSalesInvoiceCopyMode mode,
) {
  return LotusPrintablePanel(
    title: 'INVOICE DETAILS',
    details: [
      LotusPrintableDetail(
        iconKey: 'invoice',
        label: 'Invoice No',
        value: sourceDocument.documentNo,
        highlight: true,
      ),
      LotusPrintableDetail(
        iconKey: 'calendar',
        label: 'Invoice Date',
        value: _formatDate(sourceDocument.documentDate),
      ),
      LotusPrintableDetail(
        iconKey: 'items',
        label: 'Invoice Type',
        value: mode == ReturnReversalSalesInvoiceCopyMode.original
            ? 'Original Sales Invoice'
            : 'Updated After Return',
        highlight: true,
      ),
      LotusPrintableDetail(
        iconKey: 'status',
        label: 'Active Lines',
        value: '${invoiceData.lines.length}',
      ),
    ],
  );
}

LotusPrintableTable _itemTable(
  List<ReturnReversalSourceLineItem> lines,
  ReturnReversalSalesInvoiceCopyMode mode,
) {
  final rows = lines.isEmpty
      ? const [
          ['-', 'No available items', '-', '-', '-', '-', '-'],
        ]
      : [
          for (final line in lines)
            [
              line.lineNo.toString(),
              line.description,
              line.metalType,
              _quantity(line),
              '${_formatWeight(line.netWeight)} g',
              _formatMoney(line.rate),
              _formatMoney(line.displayLineTotal),
            ],
        ];
  return LotusPrintableTable(
    title: mode.tableTitle,
    headers: const ['#', 'Item', 'Metal', 'Qty', 'Net Wt', 'Rate', 'Amount'],
    rows: rows,
  );
}

LotusPrintablePanel _totalsPanel(
  ReturnReversalSourceDocument sourceDocument,
  _InvoiceCopyData invoiceData,
  ReturnReversalSalesInvoiceCopyMode mode,
) {
  final documentLabel = mode == ReturnReversalSalesInvoiceCopyMode.original
      ? 'Invoice Total'
      : 'Updated Invoice Total';
  return LotusPrintablePanel(
    title: 'PAYMENT SUMMARY',
    details: [
      LotusPrintableDetail(
        iconKey: 'amount',
        label: documentLabel,
        value: _formatMoney(invoiceData.finalAmount),
        highlight: true,
      ),
      LotusPrintableDetail(
        iconKey: 'payment',
        label: 'Collected',
        value: _formatMoney(sourceDocument.paidAmount),
      ),
      if (sourceDocument.cashPaid > 0.005)
        LotusPrintableDetail(
          iconKey: 'payment',
          label: 'Cash',
          value: _formatMoney(sourceDocument.cashPaid),
        ),
      if (sourceDocument.upiPaid > 0.005)
        LotusPrintableDetail(
          iconKey: 'payment',
          label: 'UPI / Bank',
          value: _formatMoney(sourceDocument.upiPaid),
        ),
      if (sourceDocument.cardPaid > 0.005)
        LotusPrintableDetail(
          iconKey: 'payment',
          label: 'Card',
          value: _formatMoney(sourceDocument.cardPaid),
        ),
      if (sourceDocument.dueAmount > 0.005)
        LotusPrintableDetail(
          iconKey: 'amount',
          label: 'Original Due',
          value: _formatMoney(sourceDocument.dueAmount),
        ),
    ],
  );
}

LotusPrintablePanel _returnAdjustmentPanel(
  _InvoiceCopyData invoiceData,
) {
  return LotusPrintablePanel(
    title: 'RETURN ADJUSTMENT',
    details: [
      LotusPrintableDetail(
        iconKey: 'amount',
        label: 'Original Invoice',
        value: _formatMoney(invoiceData.originalFinalAmount),
      ),
      LotusPrintableDetail(
        iconKey: 'amount',
        label: 'Return Deducted',
        value: _formatMoney(invoiceData.deductedAmount),
        highlight: true,
      ),
      LotusPrintableDetail(
        iconKey: 'items',
        label: 'Removed Lines',
        value: '${invoiceData.removedLineCount}',
      ),
      const LotusPrintableDetail(
        iconKey: 'status',
        label: 'Copy Status',
        value: 'After Return',
        highlight: true,
      ),
    ],
  );
}

String _shopName(ShopPrintDocumentProfile profile) {
  return profile.invoiceHeaderName.trim().ifBlank('Lotus ERP');
}

String _quantity(ReturnReversalSourceLineItem line) {
  final unit = line.quantityUnitCode.trim();
  if (unit.isEmpty) return '${line.quantity}';
  return '${line.quantity} $unit';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = _monthShort[date.month - 1];
  return '$day $month ${date.year}';
}

String _formatMoney(double value) {
  final rounded = value.round();
  final negative = rounded < 0;
  final digits = negative ? (-rounded).toString() : rounded.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return '${negative ? '-' : ''}Rs ${buffer.toString()}';
}

String _formatWeight(double value) => value.toStringAsFixed(3);

String _compactNumber(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.000001) {
    return rounded.toInt().toString();
  }
  return value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}
