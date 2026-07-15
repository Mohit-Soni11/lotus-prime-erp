part of '../../inventory_screen.dart';

class _InventoryBatchStatusPdfService {
  const _InventoryBatchStatusPdfService._();

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
        build: (context) => [
          _statusHeader(
            batch: batch,
            title: title,
            accent: PdfColor.fromInt(ui.accent.toARGB32()),
          ),
          pw.SizedBox(height: 14),
          _statusSummary(batch),
          pw.SizedBox(height: 12),
          pw.NewPage(freeSpace: 170),
          _statusLedger(batch),
        ],
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

  static pw.Widget _statusHeader({
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
                pw.Text(
                  'Stock Status Report',
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$title - ${batch.batchCode}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
          _statusMetric('Available', '${batch.availableItems} pcs'),
          pw.SizedBox(width: 8),
          _statusMetric(
              'Sold', '${batch.totalItems - batch.availableItems} pcs'),
        ],
      ),
    );
  }

  static pw.Widget _statusSummary(_InventoryBatchGroup batch) {
    return _statusSection(
      title: 'Stock Snapshot',
      children: [
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _statusMetric('Total Items', '${batch.totalItems} pcs'),
            _statusMetric('Available', '${batch.availableItems} pcs'),
            _statusMetric(
                'Sold', '${batch.totalItems - batch.availableItems} pcs'),
            _statusMetric('Gross Wt', '${_weight(batch.grossWeight)} g'),
            _statusMetric('Net Wt', '${_weight(batch.netWeight)} g'),
            _statusMetric('Actual Fine', '${_weight(batch.actualFine)} g'),
            _statusMetric(
                'Valuation Fine', '${_weight(batch.valuationFine)} g'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _statusLedger(_InventoryBatchGroup batch) {
    return _statusSection(
      title: 'Item Status Ledger',
      children: [
        for (final entry in batch.units.asMap().entries) ...[
          _statusItemCard(entry.key + 1, entry.value),
          if (entry.key != batch.units.length - 1) pw.SizedBox(height: 8),
        ],
      ],
    );
  }

  static pw.Widget _statusItemCard(int index, _InventoryGradeUnit unit) {
    final available = unit.status.toLowerCase() == 'available';
    final status = unit.status.isEmpty ? 'Available' : unit.status;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: available ? PdfColors.green50 : PdfColors.red50,
        border: pw.Border.all(
          color: available ? PdfColors.green300 : PdfColors.red300,
          width: 0.5,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                index.toString().padLeft(2, '0'),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(width: 8),
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
              _statusBadge(
                status,
                available ? PdfColors.green700 : PdfColors.red700,
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _statusMetric('Type', _dash(unit.itemType)),
              if (unit.segment.trim().isNotEmpty)
                _statusMetric('Segment', unit.segment),
              if (unit.huid.trim().isNotEmpty) _statusMetric('HUID', unit.huid),
              _statusMetric('Gross', '${_weight(unit.grossWeight)} g'),
              _statusMetric('Net', '${_weight(unit.netWeight)} g'),
              _statusMetric('Purity', '${_percent(unit.purityPercent)}%'),
              _statusMetric('Wastage', '${_percent(unit.wastagePercent)}%'),
              _statusMetric('Actual Fine', '${_weight(unit.actualFine)} g'),
              if (unit.unitCost > 0)
                _statusMetric('Cost', _money(unit.unitCost)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _statusSection({
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
              fontSize: 12,
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

  static pw.Widget _statusMetric(String label, String value) {
    return pw.Container(
      width: 104,
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
              fontSize: 8.3,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _statusBadge(String label, PdfColor color) {
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
}
