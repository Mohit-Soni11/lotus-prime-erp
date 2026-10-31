part of 'return_reversal_voucher_pdf_service.dart';

List<pw.Widget> _buildA4Content({
  required ReturnReversalState state,
  required ReturnReversalVoucherDocumentKind kind,
  required ReturnReversalSourceDocument sourceDocument,
  required List<_VoucherRow> rows,
  required _VoucherSettlement settlement,
  required ReturnReversalVoucherPrintOptions options,
  required PrintTemplateDefinition template,
  required int copy,
}) {
  return [
    _brandHeader(
      kind,
      state,
      sourceDocument,
      template,
      options,
      copy,
      false,
    ),
    pw.SizedBox(height: 16),
    _partyAndSourceBlock(sourceDocument, state, false),
    pw.SizedBox(height: 14),
    _itemsTable(kind, rows, options, false),
    if (options.includeSettlement) ...[
      pw.SizedBox(height: 14),
      _settlementBlock(kind, sourceDocument, settlement, false),
    ],
    pw.Spacer(),
    _voucherFooter(false),
  ];
}

List<pw.Widget> _buildThermalContent({
  required ReturnReversalState state,
  required ReturnReversalVoucherDocumentKind kind,
  required ReturnReversalSourceDocument sourceDocument,
  required List<_VoucherRow> rows,
  required _VoucherSettlement settlement,
  required ReturnReversalVoucherPrintOptions options,
  required PrintTemplateDefinition template,
  required int copy,
}) {
  return [
    _brandHeader(
      kind,
      state,
      sourceDocument,
      template,
      options,
      copy,
      true,
    ),
    _thermalDivider(),
    _partyAndSourceBlock(sourceDocument, state, true),
    _thermalDivider(),
    _thermalItems(kind, rows, options),
    if (options.includeSettlement) ...[
      _thermalDivider(),
      _settlementBlock(kind, sourceDocument, settlement, true),
    ],
    _thermalDivider(),
    _voucherFooter(true),
  ];
}

pw.Widget _brandHeader(
  ReturnReversalVoucherDocumentKind kind,
  ReturnReversalState state,
  ReturnReversalSourceDocument sourceDocument,
  PrintTemplateDefinition template,
  ReturnReversalVoucherPrintOptions options,
  int copy,
  bool thermal,
) {
  final result = state.lastProcessResult;
  final voucherNo = result?.voucherNo ??
      sourceDocument.reversalVoucherNo.ifBlank('DRAFT-${sourceDocument.id}');
  final textColor = thermal ? PdfColors.black : PdfColors.blueGrey900;
  return pw.Container(
    padding: thermal ? pw.EdgeInsets.zero : const pw.EdgeInsets.all(14),
    decoration: thermal
        ? null
        : pw.BoxDecoration(
            color: PdfColors.blueGrey900,
            borderRadius: pw.BorderRadius.circular(10),
          ),
    child: pw.Column(
      crossAxisAlignment:
          thermal ? pw.CrossAxisAlignment.center : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'LOTUS ERP',
          style: pw.TextStyle(
            fontSize: thermal ? 14 : 22,
            fontWeight: pw.FontWeight.bold,
            color: thermal ? PdfColors.black : PdfColors.amber100,
          ),
        ),
        pw.SizedBox(height: thermal ? 3 : 6),
        pw.Text(
          kind.title,
          style: pw.TextStyle(
            fontSize: thermal ? 10 : 13,
            fontWeight: pw.FontWeight.bold,
            color: thermal ? PdfColors.black : PdfColors.white,
          ),
        ),
        pw.SizedBox(height: thermal ? 3 : 8),
        pw.Text(
          'Voucher: $voucherNo  |  Source: ${sourceDocument.documentNo}'
          '  |  ${_formatDate(DateTime.now())}  |  ${_copyLabel(copy, state, options)}',
          textAlign: thermal ? pw.TextAlign.center : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: thermal ? 7 : 9,
            color: textColor,
          ).copyWith(color: thermal ? PdfColors.black : PdfColors.grey200),
        ),
        if (!thermal) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Template: ${template.shortName}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey300),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _partyAndSourceBlock(
  ReturnReversalSourceDocument sourceDocument,
  ReturnReversalState state,
  bool thermal,
) {
  final labelWidth = thermal ? 56.0 : 92.0;
  return pw.Container(
    padding: thermal
        ? const pw.EdgeInsets.symmetric(vertical: 4)
        : const pw.EdgeInsets.all(12),
    decoration: thermal
        ? null
        : pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
    child: pw.Column(
      children: [
        _infoRow('Customer', sourceDocument.customerName, labelWidth, thermal),
        _infoRow('Mobile', sourceDocument.mobile, labelWidth, thermal),
        _infoRow('Address', sourceDocument.address, labelWidth, thermal),
        _infoRow(
          'Source Type',
          sourceDocument.type.label,
          labelWidth,
          thermal,
        ),
        _infoRow(
          'Source Date',
          _formatDate(sourceDocument.documentDate),
          labelWidth,
          thermal,
        ),
        _infoRow(
          'Desk Mode',
          state.operationType.ledgerLabel,
          labelWidth,
          thermal,
        ),
      ],
    ),
  );
}

pw.Widget _itemsTable(
  ReturnReversalVoucherDocumentKind kind,
  List<_VoucherRow> rows,
  ReturnReversalVoucherPrintOptions options,
  bool thermal,
) {
  final headers = <String>[
    'S. No.',
    'Item',
    'Metal',
    'Sold Wt',
    'Received Wt',
    'Return',
  ];
  if (options.includeOriginalPricing) {
    headers.insert(5, 'Invoice Value');
  }
  if (options.includeStockRouting &&
      kind != ReturnReversalVoucherDocumentKind.bookingCancellation) {
    headers.add('Route');
  }

  final data = rows.map((row) {
    final line = row.line;
    final values = <String>[
      line.lineNo.toString(),
      line.description,
      line.metalType,
      '${_formatWeight(line.netWeight)} g',
      '${_formatWeight(row.draft.receivedNetWeight)} g',
      _formatMoney(row.returnValue),
    ];
    if (options.includeOriginalPricing) {
      values.insert(5, _formatMoney(row.adjustedLineAmount));
    }
    if (options.includeStockRouting &&
        kind != ReturnReversalVoucherDocumentKind.bookingCancellation) {
      values.add(row.draft.stockRoute.label);
    }
    return values;
  }).toList(growable: false);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle('Return Lines', false),
      pw.SizedBox(height: 7),
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: data,
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.amber100),
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellPadding: const pw.EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 6,
        ),
      ),
      if (options.includeVerificationAudit) ...[
        pw.SizedBox(height: 8),
        _auditStrip(rows),
      ],
    ],
  );
}

pw.Widget _thermalItems(
  ReturnReversalVoucherDocumentKind kind,
  List<_VoucherRow> rows,
  ReturnReversalVoucherPrintOptions options,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: rows.map((row) {
      final route =
          kind == ReturnReversalVoucherDocumentKind.bookingCancellation
              ? 'N/A'
              : row.draft.stockRoute.label;
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${row.line.lineNo}. ${row.line.description}',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              '${row.line.metalType} | ${_formatWeight(row.draft.receivedNetWeight)} g'
              ' | Route: $route',
              style: const pw.TextStyle(fontSize: 7),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Return Value', style: const pw.TextStyle(fontSize: 7)),
                pw.Text(
                  _formatMoney(row.returnValue),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList(growable: false),
  );
}

pw.Widget _settlementBlock(
  ReturnReversalVoucherDocumentKind kind,
  ReturnReversalSourceDocument sourceDocument,
  _VoucherSettlement settlement,
  bool thermal,
) {
  return pw.Container(
    padding: thermal ? pw.EdgeInsets.zero : const pw.EdgeInsets.all(12),
    decoration: thermal
        ? null
        : pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(kind.settlementTitle, thermal),
        pw.SizedBox(height: thermal ? 5 : 8),
        _amountRow('Original Total', sourceDocument.finalAmount, thermal),
        _amountRow('Amount Received', sourceDocument.paidAmount, thermal),
        _amountRow('Return / Refund Value', settlement.returnValue, thermal),
        _amountRow('Due Adjusted', settlement.dueAdjustedAmount, thermal),
        _amountRow('Refund Payable', settlement.refundPayableAmount, thermal),
      ],
    ),
  );
}

pw.Widget _auditStrip(List<_VoucherRow> rows) {
  final matched = rows
      .where((row) => row.draft.huidMatched && row.draft.unitMatched)
      .length;
  final total = rows.length;
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: PdfColors.green50,
      border: pw.Border.all(color: PdfColors.green200),
      borderRadius: pw.BorderRadius.circular(7),
    ),
    child: pw.Text(
      'Verification audit: $matched of $total line(s) matched HUID and unit checks.',
      style: pw.TextStyle(
        fontSize: 8,
        color: PdfColors.green900,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _voucherFooter(bool thermal) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      if (!thermal) pw.Divider(color: PdfColors.grey400),
      pw.SizedBox(height: thermal ? 4 : 8),
      pw.Text(
        'This document is generated from Lotus ERP Return & Reversal Desk.',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: thermal ? 6.5 : 8,
          color: PdfColors.grey700,
        ),
      ),
    ],
  );
}

pw.Widget _sectionTitle(String title, bool thermal) {
  return pw.Text(
    title,
    style: pw.TextStyle(
      fontSize: thermal ? 8 : 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.amber900,
    ),
  );
}

pw.Widget _infoRow(
  String label,
  String value,
  double labelWidth,
  bool thermal,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: labelWidth,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: thermal ? 7 : 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value.ifBlank('-'),
            style: pw.TextStyle(fontSize: thermal ? 7 : 8),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _amountRow(
  String label,
  double? value,
  bool thermal, {
  String? valueText,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: thermal ? 7 : 8)),
        pw.Text(
          valueText ?? _formatMoney(value ?? 0),
          style: pw.TextStyle(
            fontSize: thermal ? 7.5 : 8.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _thermalDivider() {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    child: pw.Container(height: 0.6, color: PdfColors.grey500),
  );
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

pw.EdgeInsets _pageMarginFor(PrintFormat format) {
  return switch (format) {
    PrintFormat.a4 => const pw.EdgeInsets.all(24),
    PrintFormat.thermal3inch => const pw.EdgeInsets.all(4 * PdfPageFormat.mm),
    PrintFormat.thermal2inch => const pw.EdgeInsets.all(3 * PdfPageFormat.mm),
  };
}

Future<pw.ThemeData> _documentTheme() async {
  return LotusPdfTheme.reportTheme();
}

String _shopName(ShopPrintDocumentProfile profile) {
  return profile.invoiceHeaderName.trim().ifBlank('Lotus ERP');
}

String _voucherNo(
  ReturnReversalState state,
  ReturnReversalSourceDocument sourceDocument,
) {
  final postedVoucherNo = state.lastProcessResult?.voucherNo ??
      sourceDocument.reversalVoucherNo.ifBlank('');
  if (postedVoucherNo.trim().isNotEmpty) {
    return postedVoucherNo.trim();
  }
  return 'DRAFT-${sourceDocument.documentNo}';
}

String _fallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String _matchedLineSummary(List<_VoucherRow> rows) {
  final matched = rows
      .where((row) => row.draft.huidMatched && row.draft.unitMatched)
      .length;
  return '$matched of ${rows.length} line(s)';
}

String _copyLabel(
  int copy,
  ReturnReversalState state,
  ReturnReversalVoucherPrintOptions options,
) {
  final statusLabel = state.lastProcessResult == null ? 'Draft' : 'Posted';
  final duplicate = options.includeDuplicateStamp && copy > 1;
  return '${duplicate ? 'Duplicate' : statusLabel} Copy $copy';
}
