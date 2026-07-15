part of '../stock_search_screen.dart';

Future<Uint8List> _buildStockCardPdfBytes(StockSearchResult item) async {
  final document = pw.Document();
  final gold = PdfColor.fromHex('#D4AF37');
  final dark = PdfColor.fromHex('#111827');
  final muted = PdfColor.fromHex('#64748B');
  final panel = PdfColor.fromHex('#FAF7EF');
  final border = PdfColor.fromHex('#E5E0D8');
  final success = PdfColor.fromHex('#10B981');
  final danger = PdfColor.fromHex('#EF4444');
  final statusColor = item.isSold ? danger : success;

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        _stockPdfHeader(item, gold, dark, muted, statusColor),
        pw.SizedBox(height: 16),
        _stockPdfSection(
          title: 'Stock Identity',
          border: border,
          panel: panel,
          dark: dark,
          muted: muted,
          fields: [
            _StockPdfField(
              'HUID / Serial',
              item.hasHuid ? item.huid : item.unitCode,
            ),
            _StockPdfField('Unit Code', item.unitCode),
            _StockPdfField('Batch Code', item.batchCode),
            _StockPdfField('Piece No.', item.pieceNo.toString()),
            _StockPdfField('Status', item.status),
          ],
        ),
        pw.SizedBox(height: 10),
        _stockPdfSection(
          title: 'Item Classification',
          border: border,
          panel: panel,
          dark: dark,
          muted: muted,
          fields: [
            _StockPdfField('Metal', _clean(item.metalType)),
            _StockPdfField('Item Type', _clean(item.itemType)),
            _StockPdfField('Segment', _clean(item.segment)),
            _StockPdfField('Tracking', item.trackingLabel),
            _StockPdfField('Created', _formatDateTime(item.createdAt)),
          ],
        ),
        pw.SizedBox(height: 10),
        _stockPdfSection(
          title: 'Weight & Purity',
          border: border,
          panel: panel,
          dark: dark,
          muted: muted,
          fields: [
            _StockPdfField('Gross Weight', _grams(item.grossWeight)),
            _StockPdfField('Less Weight', _grams(item.lessWeight)),
            _StockPdfField('Net Weight', _grams(item.netWeight)),
            _StockPdfField('Purity', _percent(item.purityPercent)),
            _StockPdfField('Actual Fine', _grams(item.actualFineWeight)),
            _StockPdfField('Valuation Fine', _grams(item.valuationFineWeight)),
          ],
        ),
        pw.SizedBox(height: 10),
        _stockPdfSection(
          title: 'Purchase Source',
          border: border,
          panel: panel,
          dark: dark,
          muted: muted,
          fields: [
            _StockPdfField('Supplier', _clean(item.supplierName)),
            _StockPdfField('Supplier Invoice', item.sourceInvoice),
            _StockPdfField('Purchase Tax Type', _clean(item.taxType)),
            _StockPdfField('Batch Date', _formatDateTime(item.createdAt)),
          ],
        ),
        if (item.isSold || item.soldBillNo.trim().isNotEmpty) ...[
          pw.SizedBox(height: 10),
          _stockPdfSection(
            title: 'Sale Status',
            border: PdfColor.fromHex('#FECACA'),
            panel: PdfColor.fromHex('#FFF7F7'),
            dark: dark,
            muted: muted,
            fields: [
              _StockPdfField('Sale Invoice', _clean(item.soldBillNo)),
              _StockPdfField('Customer', _clean(item.soldCustomerName)),
              _StockPdfField(
                'Sale Date',
                _formatDateTime(item.soldBillDate ?? item.soldAt),
              ),
              _StockPdfField(
                'Bill Amount',
                _currencyFormat.format(item.soldBillAmount),
              ),
              _StockPdfField(
                'Profit Snapshot',
                _currencyFormat.format(item.soldProfitAmount),
              ),
            ],
          ),
        ],
        pw.SizedBox(height: 18),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'Generated from Lotus ERP Stock Search Center. Use this stock card for internal verification, audit reference and stock movement review.',
            style: pw.TextStyle(fontSize: 9, color: muted),
          ),
        ),
      ],
    ),
  );

  return document.save();
}

pw.Widget _stockPdfHeader(
  StockSearchResult item,
  PdfColor gold,
  PdfColor dark,
  PdfColor muted,
  PdfColor statusColor,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#FFF4C4'),
      border: pw.Border.all(color: gold),
      borderRadius: pw.BorderRadius.circular(12),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.displayName,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: dark,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '${item.metalType.toUpperCase()} | ${item.trackingLabel} | ${item.batchCode}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
        pw.Container(
          width: 118,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#FFFFFF'),
            border: pw.Border.all(color: statusColor),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.status.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: statusColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                item.isSold ? _formatDateTime(item.soldAt) : 'Ready for sale',
                style: pw.TextStyle(fontSize: 8.5, color: dark),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _stockPdfSection({
  required String title,
  required PdfColor border,
  required PdfColor panel,
  required PdfColor dark,
  required PdfColor muted,
  required List<_StockPdfField> fields,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#FFFFFF'),
      border: pw.Border.all(color: border),
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: dark,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fields
              .map((field) => _stockPdfField(field, panel, border, dark, muted))
              .toList(),
        ),
      ],
    ),
  );
}

pw.Widget _stockPdfField(
  _StockPdfField field,
  PdfColor panel,
  PdfColor border,
  PdfColor dark,
  PdfColor muted,
) {
  return pw.Container(
    width: 158,
    padding: const pw.EdgeInsets.all(9),
    decoration: pw.BoxDecoration(
      color: panel,
      border: pw.Border.all(color: border),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          field.label,
          style: pw.TextStyle(
            fontSize: 7.6,
            fontWeight: pw.FontWeight.bold,
            color: muted,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          field.value.trim().isEmpty ? 'Not recorded' : field.value.trim(),
          maxLines: 2,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: dark,
          ),
        ),
      ],
    ),
  );
}

class _StockPdfField {
  final String label;
  final String value;

  const _StockPdfField(this.label, this.value);
}

String _stockCardPdfFileName(StockSearchResult item) {
  final source = item.hasHuid ? item.huid : item.unitCode;
  final clean = source
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return 'stock_card_${clean.isEmpty ? item.id : clean}.pdf';
}

Future<void> _printStockCard(StockSearchResult item) async {
  final bytes = await _buildStockCardPdfBytes(item);
  await Printing.layoutPdf(
    name: _stockCardPdfFileName(item),
    onLayout: (_) async => bytes,
  );
}

Future<void> _exportStockCard(StockSearchResult item) async {
  final bytes = await _buildStockCardPdfBytes(item);
  await Printing.sharePdf(
    bytes: bytes,
    filename: _stockCardPdfFileName(item),
  );
}

class _StockCardPdfPreviewScreen extends StatelessWidget {
  final StockSearchResult item;

  const _StockCardPdfPreviewScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _StockSearchAppBar(
        onBack: () => Navigator.of(context).maybePop(),
        onRefresh: () {},
      ),
      body: PdfPreview(
        build: (_) => _buildStockCardPdfBytes(item),
        pdfFileName: _stockCardPdfFileName(item),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowSharing: true,
        allowPrinting: true,
        maxPageWidth: 900,
      ),
    );
  }
}
