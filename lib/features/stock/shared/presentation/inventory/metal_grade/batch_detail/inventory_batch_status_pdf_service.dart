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
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Stock Status Report',
                        maxLines: 1,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    _statusBadge(
                      batch.stockStatusLabel.toUpperCase(),
                      _batchStatusPdfColor(batch),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$title - ${batch.batchCode}',
                  maxLines: 1,
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _statusSummary(_InventoryBatchGroup batch) {
    return _statusSection(
      title: 'Current Stock Snapshot',
      children: [
        _snapshotGroup(
          'Quantity Movement',
          [
            _StatusMetricData('Total Quantity', batch.totalQuantityLabel),
            _StatusMetricData(
                'Available Quantity', batch.availableQuantityLabel),
            _StatusMetricData('Sold Quantity', batch.soldQuantityLabel),
          ],
        ),
        pw.SizedBox(height: 8),
        _snapshotGroup(
          'Weight Movement',
          [
            if (_hasWeightDifference(
                batch.totalGrossWeight, batch.totalNetWeight))
              _StatusMetricData(
                  'Gross Weight', '${_weight(batch.totalGrossWeight)} g'),
            _StatusMetricData(
                'Total Weight', '${_weight(batch.totalNetWeight)} g'),
            _StatusMetricData(
                'Available Weight', '${_weight(batch.availableNetWeight)} g'),
            if (_hasWeight(batch.soldNetWeight))
              _StatusMetricData(
                  'Sold Weight', '${_weight(batch.soldNetWeight)} g'),
          ],
        ),
        if (_hasWeight(batch.actualFine) ||
            _hasWeight(batch.valuationFine)) ...[
          pw.SizedBox(height: 8),
          _snapshotGroup(
            'Fine Balance',
            [
              if (_hasWeight(batch.actualFine))
                _StatusMetricData(
                    'Available Actual Fine', '${_weight(batch.actualFine)} g'),
              if (_hasWeight(batch.valuationFine))
                _StatusMetricData('Available Valuation Fine',
                    '${_weight(batch.valuationFine)} g'),
            ],
          ),
        ],
      ],
    );
  }

  static pw.Widget _statusLedger(_InventoryBatchGroup batch) {
    return _statusSection(
      title: 'Stock Movement Ledger',
      children: [
        for (final entry in batch.units.asMap().entries) ...[
          _statusItemCard(entry.key + 1, entry.value),
          if (entry.key != batch.units.length - 1) pw.SizedBox(height: 8),
        ],
      ],
    );
  }

  static pw.Widget _statusItemCard(int index, _InventoryGradeUnit unit) {
    final status = _unitStockStatusLabel(unit);
    final statusColor = _unitStockStatusColor(status);
    final statusBg = _unitStockStatusBackground(status);
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: statusBg,
        border: pw.Border.all(
          color: statusColor,
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
                statusColor,
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _statusMetric('Company', _dash(unit.companyName)),
              _statusMetric('Type', _dash(unit.itemType)),
              if (unit.segment.trim().isNotEmpty)
                _statusMetric('Segment', unit.segment),
              _statusMetric('Unit', unit.displayUnitPlural),
              _statusMetric('Total Qty', unit.totalQuantityLabel),
              _statusMetric('Available', unit.availableQuantityLabel),
              _statusMetric('Sold', unit.soldQuantityLabel),
              if (unit.huid.trim().isNotEmpty) _statusMetric('HUID', unit.huid),
              if (_hasWeightDifference(
                  unit.displayTotalGrossWeight, unit.displayTotalNetWeight))
                _statusMetric('Gross Weight',
                    '${_weight(unit.displayTotalGrossWeight)} g'),
              _statusMetric(
                  'Total Weight', '${_weight(unit.displayTotalNetWeight)} g'),
              if (_hasWeight(unit.displayAvailableNetWeight))
                _statusMetric('Available Weight',
                    '${_weight(unit.displayAvailableNetWeight)} g'),
              if (_hasWeight(unit.soldNetWeight))
                _statusMetric(
                    'Sold Weight', '${_weight(unit.soldNetWeight)} g'),
              if (_hasWeight(unit.purityPercent))
                _statusMetric(
                    'Base Purity', '${_percent(unit.purityPercent)}%'),
              if (_hasWeight(unit.wastagePercent))
                _statusMetric('Wastage', '${_percent(unit.wastagePercent)}%'),
              if (_hasWeight(unit.totalPurityPercent))
                _statusMetric(
                  'Valuation Purity',
                  '${_percent(unit.totalPurityPercent)}%',
                ),
              if (_hasWeight(unit.actualFine))
                _statusMetric('Actual Fine', '${_weight(unit.actualFine)} g'),
              if (_hasWeight(unit.valuationFine))
                _statusMetric(
                  'Valuation Fine',
                  '${_weight(unit.valuationFine)} g',
                ),
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

  static pw.Widget _snapshotGroup(
    String title,
    List<_StatusMetricData> metrics,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.45),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 6),
          _snapshotMetricRow(metrics),
        ],
      ),
    );
  }

  static pw.Widget _snapshotMetricRow(List<_StatusMetricData> metrics) {
    return pw.Row(
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          pw.Expanded(child: _snapshotMetric(metrics[index])),
          if (index != metrics.length - 1) pw.SizedBox(width: 7),
        ],
      ],
    );
  }

  static pw.Widget _snapshotMetric(_StatusMetricData metric) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.45),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            metric.label,
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 6.9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            metric.value,
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 8.6,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
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

  static PdfColor _batchStatusPdfColor(_InventoryBatchGroup batch) {
    if (batch.isSoldOut) return PdfColors.red700;
    if (batch.isPartiallySold) return PdfColors.amber800;
    return PdfColors.green700;
  }

  static bool _hasWeight(double value) => value.abs() > 0.0004;

  static String _unitStockStatusLabel(_InventoryGradeUnit unit) {
    if (unit.displayTotalQuantity > 0 && unit.displayAvailableQuantity <= 0) {
      return 'Sold Out';
    }
    if (unit.displaySoldQuantity > 0) return 'Partially Sold';
    final status = unit.status.trim();
    return status.isEmpty ? 'Available' : status;
  }

  static PdfColor _unitStockStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('sold out')) return PdfColors.red700;
    if (normalized.contains('sold')) return PdfColors.amber800;
    return PdfColors.green700;
  }

  static PdfColor _unitStockStatusBackground(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('sold out')) return PdfColors.red50;
    if (normalized.contains('sold')) return PdfColors.amber100;
    return PdfColors.green50;
  }
}

class _StatusMetricData {
  final String label;
  final String value;

  const _StatusMetricData(this.label, this.value);
}
