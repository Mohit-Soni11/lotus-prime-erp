part of '../../inventory_screen.dart';

class _InventoryBatchPdfService {
  const _InventoryBatchPdfService._();

  static Future<Uint8List> build({
    required StockCategory metal,
    required _InventoryGradeSummary grade,
    required _InventoryBatchGroup batch,
  }) async {
    final ui = stockMetalUiFor(metal);
    final title = _inventoryGradeTitle(metal, grade.gradeLabel);
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.notoSansRegular(),
          bold: await PdfGoogleFonts.notoSansBold(),
        ),
        build: (context) {
          final widgets = <pw.Widget>[
            _header(batch: batch, title: title, accent: _pdfColor(ui.accent)),
            pw.SizedBox(height: 14),
            _batchOverview(batch),
            pw.SizedBox(height: 12),
            pw.NewPage(freeSpace: 190),
            _itemLedger(batch),
            pw.SizedBox(height: 12),
            pw.NewPage(freeSpace: 150),
            _purchaseValuation(batch, metal),
            pw.SizedBox(height: 12),
            _settlementSummary(batch),
          ];

          if (batch.payment.hasAttachment) {
            widgets.addAll([
              pw.SizedBox(height: 12),
              _supplierDocument(batch),
            ]);
          }

          return widgets;
        },
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
      ),
    );

    return document.save();
  }

  static pw.Widget _header({
    required _InventoryBatchGroup batch,
    required String title,
    required PdfColor accent,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber100,
        border: pw.Border.all(color: accent, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        batch.batchCode,
                        maxLines: 1,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    if (batch.isGst) ...[
                      pw.SizedBox(width: 8),
                      _tag('GST PURCHASE', PdfColors.green700),
                    ],
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$title - Full Add Stock Batch Dossier',
                  style: const pw.TextStyle(
                    fontSize: 10.5,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
          _headerMetric('Quantity', batch.totalQuantityLabel),
          pw.SizedBox(width: 8),
          _headerMetric('Actual Fine', '${_weight(batch.actualFine)} g'),
        ],
      ),
    );
  }

  static pw.Widget _batchOverview(_InventoryBatchGroup batch) {
    final rows = <pw.Widget>[
      if (_hasText(batch.supplierName))
        _infoRow('Supplier', _dash(batch.supplierName)),
      if (_hasText(batch.supplierMobile))
        _infoRow('Supplier Mobile', batch.supplierMobile),
      if (_hasText(batch.supplierGstNumber))
        _infoRow('Supplier GSTIN', batch.supplierGstNumber),
      if (_hasText(batch.supplierInvoiceNo))
        _infoRow('Supplier Invoice', _dash(batch.supplierInvoiceNo)),
      _infoRow(
        'Purchase Type',
        batch.isGst ? 'GST Purchase' : 'Non-GST Purchase',
      ),
      if (batch.createdAt > 0)
        _infoRow(
          'Batch Date',
          DateFormat('dd MMM yyyy').format(
            DateTime.fromMillisecondsSinceEpoch(batch.createdAt),
          ),
        ),
    ];

    return _section(
      title: '1. Batch & Supplier Overview',
      children: [
        ...rows,
        if (rows.isNotEmpty) pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _metric('Total Qty', batch.totalQuantityLabel),
            if (_hasWeightDifference(
                batch.totalGrossWeight, batch.totalNetWeight))
              _metric('Gross Weight', '${_weight(batch.totalGrossWeight)} g'),
            _metric('Total Weight', '${_weight(batch.totalNetWeight)} g'),
            if (_hasWeight(batch.purityPercent))
              _metric('Base Purity', '${_percent(batch.purityPercent)}%'),
            if (_hasWeight(batch.wastagePercent))
              _metric('Wastage', '${_percent(batch.wastagePercent)}%'),
            if (_hasWeight(batch.valuationPurityPercent))
              _metric(
                'Valuation Purity',
                '${_percent(batch.valuationPurityPercent)}%',
              ),
            if (_hasWeight(batch.actualFine))
              _metric('Actual Fine', '${_weight(batch.actualFine)} g'),
            if (_hasWeight(batch.valuationFine))
              _metric('Valuation Fine', '${_weight(batch.valuationFine)} g'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _purchaseValuation(
    _InventoryBatchGroup batch,
    StockCategory metal,
  ) {
    final primaryRate = batch.units
        .map((unit) => unit.ratePerGram)
        .firstWhere((rate) => rate > 0, orElse: () => 0.0);
    return _section(
      title: '3. Purchase Valuation',
      children: [
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (_hasMoney(primaryRate))
              _metric('Rate / Gram', _money(primaryRate)),
            if (_hasMoney(primaryRate))
              _metric(
                  _purchaseRateUnitLabel(metal),
                  _money(
                    primaryRate * _purchaseRateUnitMultiplier(metal),
                  )),
            _metric('Actual Fine Total', '${_weight(batch.actualFine)} g'),
            _metric(
                'Valuation Fine Total', '${_weight(batch.valuationFine)} g'),
            if (_hasMoney(batch.makingAmount))
              _metric('Making Total', _money(batch.makingAmount)),
            if (_hasMoney(batch.payment.gstAmount))
              _metric('GST Total', _money(batch.payment.gstAmount)),
            if (_hasMoney(batch.payment.grandTotal))
              _metric(
                  'Final Purchase Amount', _money(batch.payment.grandTotal)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _settlementSummary(_InventoryBatchGroup batch) {
    final payment = batch.payment;
    final cards = <pw.Widget>[
      if (_hasMoney(payment.grandTotal))
        _metric('Final Bill', _money(payment.grandTotal)),
      if (_hasMoney(payment.totalPaid))
        _metric('Total Paid', _money(payment.totalPaid)),
      if (_hasMoney(payment.balanceDue))
        _metric('Cash Due', _money(payment.balanceDue)),
      if (_hasWeight(payment.metalPaidFine))
        _metric('Metal Paid', '${_weight(payment.metalPaidFine)} g'),
      if (_hasWeight(payment.fineDueWeight))
        _metric('Fine Due', '${_weight(payment.fineDueWeight)} g'),
      if (_hasWeight(payment.fineReturnWeight))
        _metric('Fine Return', '${_weight(payment.fineReturnWeight)} g'),
      if (batch.isGst && _hasMoney(payment.gstAmount))
        _metric('GST Total', _money(payment.gstAmount)),
      if (batch.isGst && _hasMoney(payment.cgstAmount))
        _metric('CGST', _money(payment.cgstAmount)),
      if (batch.isGst && _hasMoney(payment.sgstAmount))
        _metric('SGST', _money(payment.sgstAmount)),
      if (_hasMoney(payment.cashPaid))
        _metric('Cash', _money(payment.cashPaid)),
      if (_hasMoney(payment.upiPaid)) _metric('UPI', _money(payment.upiPaid)),
      if (_hasMoney(payment.bankPaid))
        _metric('Bank', _money(payment.bankPaid)),
      if (_hasMoney(payment.cardPaid))
        _metric('Card', _money(payment.cardPaid)),
      if (_hasText(payment.paymentStatus))
        _metric('Status', payment.paymentStatus.toUpperCase()),
    ];

    return _section(
      title: '4. Settlement Method',
      children: [
        if (_hasText(payment.paymentMode) ||
            _hasText(payment.balanceLabel)) ...[
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (_hasText(payment.paymentMode))
                _metric('Settlement Mode', _humanizeToken(payment.paymentMode)),
              if (_hasText(payment.balanceLabel))
                _metric(
                    'Balance Handling', _humanizeToken(payment.balanceLabel)),
              if (_hasText(payment.dueMode))
                _metric('Due Mode', _humanizeToken(payment.dueMode)),
              if (_hasText(payment.excessMode))
                _metric('Excess Mode', _humanizeToken(payment.excessMode)),
            ],
          ),
          pw.SizedBox(height: 8),
        ],
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children:
              cards.isEmpty ? [_metric('Status', 'No payment details')] : cards,
        ),
      ],
    );
  }

  static pw.Widget _supplierDocument(_InventoryBatchGroup batch) {
    final path = batch.payment.attachmentPath.trim();
    return _section(
      title: '5. Supplier Bill Document',
      children: [
        pw.Text(
          path.isEmpty
              ? 'No supplier bill attachment is linked with this batch.'
              : path,
          style: const pw.TextStyle(fontSize: 9.2, color: PdfColors.black),
        ),
      ],
    );
  }

  static pw.Widget _itemLedger(_InventoryBatchGroup batch) {
    return _section(
      title: '2. Item Entry Ledger',
      children: [
        pw.Column(
          children: [
            for (final entry in batch.units.asMap().entries)
              pw.Padding(
                padding: pw.EdgeInsets.only(
                  bottom: entry.key == batch.units.length - 1 ? 0 : 8,
                ),
                child: _unitCard(index: entry.key + 1, unit: entry.value),
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _unitCard({
    required int index,
    required _InventoryGradeUnit unit,
  }) {
    final status = unit.status.isEmpty ? 'Available' : unit.status;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 28,
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber100,
                  border: pw.Border.all(color: PdfColors.amber700, width: 0.5),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    index.toString().padLeft(2, '0'),
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            _dash(unit.itemName),
                            maxLines: 1,
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        _tag(
                          status,
                          status.toLowerCase() == 'available'
                              ? PdfColors.green700
                              : PdfColors.red700,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    if (_unitSubtitle(unit).isNotEmpty)
                      pw.Text(
                        _unitSubtitle(unit),
                        maxLines: 1,
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey800,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _unitMetric('Unit', unit.displayUnitPlural),
              _unitMetric('Total Qty', unit.totalQuantityLabel),
              if (_hasText(unit.huidDisplayText))
                _unitMetric('HUID', unit.huidDisplayText),
              if (_hasWeightDifference(
                  unit.displayTotalGrossWeight, unit.displayTotalNetWeight))
                _unitMetric('Gross Weight',
                    '${_weight(unit.displayTotalGrossWeight)} g'),
              if (_hasWeight(unit.lessWeight))
                _unitMetric('Less Weight', '${_weight(unit.lessWeight)} g'),
              _unitMetric(
                  'Total Weight', '${_weight(unit.displayTotalNetWeight)} g'),
              if (_hasWeight(unit.purityPercent))
                _unitMetric('Base Purity', '${_percent(unit.purityPercent)}%'),
              if (_hasWeight(unit.wastagePercent))
                _unitMetric('Wastage', '${_percent(unit.wastagePercent)}%'),
              if (_hasWeight(unit.totalPurityPercent))
                _unitMetric(
                  'Valuation Purity',
                  '${_percent(unit.totalPurityPercent)}%',
                ),
              if (_hasWeight(unit.actualFine))
                _unitMetric('Actual Fine', '${_weight(unit.actualFine)} g'),
              if (_hasWeight(unit.valuationFine))
                _unitMetric(
                    'Valuation Fine', '${_weight(unit.valuationFine)} g'),
              if (_hasMoney(unit.ratePerGram))
                _unitMetric('Rate / Gram', _money(unit.ratePerGram)),
              if (_hasMoney(unit.makingAmount))
                _unitMetric('Making', _money(unit.makingAmount)),
              if (_hasMoney(unit.unitCost))
                _unitMetric('Amount', _money(unit.unitCost)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _section({
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 8.7,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metric(String label, String value) {
    return pw.Container(
      width: 112,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.45),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 7.2,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 9.3,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _unitMetric(String label, String value) {
    return pw.Container(
      width: 96,
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.45),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 6.8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 8.4,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _headerMetric(String label, String value) {
    return pw.Container(
      width: 118,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.amber700, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tag(String label, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: color, width: 0.8),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static PdfColor _pdfColor(Color color) {
    return PdfColor.fromInt(color.toARGB32());
  }

  static bool _hasText(String value) => value.trim().isNotEmpty;

  static bool _hasMoney(double value) => value.abs() > 0.004;

  static bool _hasWeight(double value) => value.abs() > 0.0004;

  static String _purchaseRateUnitLabel(StockCategory metal) {
    return metal == StockCategory.silver ? 'Rate / Kg' : 'Rate / 10g';
  }

  static double _purchaseRateUnitMultiplier(StockCategory metal) {
    return metal == StockCategory.silver ? 1000 : 10;
  }

  static String _unitSubtitle(_InventoryGradeUnit unit) {
    return [
      unit.companyName,
      unit.itemType,
      unit.segment,
    ].where((value) => value.trim().isNotEmpty).join(' - ');
  }

  static String _humanizeToken(String value) {
    final spaced =
        value.trim().replaceAll('_', ' ').replaceAll('-', ' ').replaceAllMapped(
              RegExp(r'([a-z])([A-Z])'),
              (match) => '${match.group(1)} ${match.group(2)}',
            );
    return _titleCase(spaced);
  }
}
