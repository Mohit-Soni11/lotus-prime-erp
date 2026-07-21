part of 'market_refill_report_screen.dart';

class MarketPurchasePdfService {
  const MarketPurchasePdfService();

  Future<Uint8List> build(MarketRefillReport report) {
    return _buildMarketPurchasePdfBytes(report);
  }
}

Future<Uint8List> _buildMarketPurchasePdfBytes(
  MarketRefillReport report,
) async {
  final document = pw.Document();
  final gold = PdfColor.fromHex('#D4AF37');
  final silver = PdfColor.fromHex('#64748B');
  final dark = PdfColor.fromHex('#111827');
  final muted = PdfColor.fromHex('#64748B');
  final border = PdfColor.fromHex('#E8DDC9');
  final panel = PdfColor.fromHex('#FAF7EF');
  final theme = await _marketPdfTheme();

  final goldRows = report.rows
      .where((row) => row.metal.trim().toLowerCase() == 'gold')
      .toList(growable: false);
  final silverRows = report.rows
      .where((row) => row.metal.trim().toLowerCase() == 'silver')
      .toList(growable: false);
  final otherRows = report.rows.where((row) {
    final metal = row.metal.trim().toLowerCase();
    return metal != 'gold' && metal != 'silver';
  }).toList(growable: false);

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(26),
      theme: theme,
      build: (context) => [
        _marketPdfHeader(report, gold, dark, muted),
        pw.SizedBox(height: 14),
        _marketPdfSummary(report, panel, border, dark, muted),
        pw.SizedBox(height: 14),
        if (goldRows.isNotEmpty)
          _marketPdfMetalSection(
            title: 'Gold Purchase List',
            modeLabel: 'Grade wise',
            rows: goldRows,
            accent: gold,
            border: border,
            panel: panel,
            dark: dark,
            muted: muted,
          ),
        if (goldRows.isNotEmpty && silverRows.isNotEmpty)
          pw.SizedBox(height: 12),
        if (silverRows.isNotEmpty)
          _marketPdfMetalSection(
            title: 'Silver Purchase List',
            modeLabel: 'Company wise',
            rows: silverRows,
            accent: silver,
            border: border,
            panel: panel,
            dark: dark,
            muted: muted,
          ),
        if (otherRows.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _marketPdfMetalSection(
            title: 'Other Purchase List',
            modeLabel: 'Group wise',
            rows: otherRows,
            accent: muted,
            border: border,
            panel: panel,
            dark: dark,
            muted: muted,
          ),
        ],
      ],
    ),
  );

  return document.save();
}

Future<pw.ThemeData> _marketPdfTheme() async {
  final devanagari = pw.Font.ttf(
    await rootBundle.load('assets/fonts/lohit_devanagari/Lohit-Devanagari.ttf'),
  );
  final windowsDirectory = Platform.environment['WINDIR'];
  if (windowsDirectory != null) {
    final regularFile = File('$windowsDirectory\\Fonts\\segoeui.ttf');
    final boldFile = File('$windowsDirectory\\Fonts\\segoeuib.ttf');
    if (regularFile.existsSync() && boldFile.existsSync()) {
      try {
        return pw.ThemeData.withFont(
          base: pw.Font.ttf(_asByteData(await regularFile.readAsBytes())),
          bold: pw.Font.ttf(_asByteData(await boldFile.readAsBytes())),
          fontFallback: [devanagari],
        );
      } catch (_) {
        // Built-in PDF fonts remain the last fallback.
      }
    }
  }
  return pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
    fontFallback: [devanagari],
  );
}

ByteData _asByteData(Uint8List bytes) {
  return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
}

pw.Widget _marketPdfHeader(
  MarketRefillReport report,
  PdfColor gold,
  PdfColor dark,
  PdfColor muted,
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
                'Market Purchase List',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: dark,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                report.lastClearedAt == null
                    ? 'All sold stock waiting for market purchase checkout.'
                    : 'Sold stock after last checkout: ${_date(report.lastClearedAt)}',
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
        pw.Container(
          width: 126,
          padding: const pw.EdgeInsets.all(9),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#FFFFFF'),
            border: pw.Border.all(color: gold),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GENERATED',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: muted,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _date(DateTime.now()),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: dark,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _marketPdfSummary(
  MarketRefillReport report,
  PdfColor panel,
  PdfColor border,
  PdfColor dark,
  PdfColor muted,
) {
  final goldQty = _metalSoldQuantity(report, 'gold');
  final silverQty = _metalSoldQuantity(report, 'silver');
  return pw.Row(
    children: [
      _marketPdfMetric('Total Sold', '${report.summary.soldQuantity} unit',
          panel, border, dark, muted),
      pw.SizedBox(width: 8),
      _marketPdfMetric(
          'Gold Sold', '$goldQty unit', panel, border, dark, muted),
      pw.SizedBox(width: 8),
      _marketPdfMetric(
          'Silver Sold', '$silverQty unit', panel, border, dark, muted),
      pw.SizedBox(width: 8),
      _marketPdfMetric('Items', '${report.summary.itemGroups} lines', panel,
          border, dark, muted),
    ],
  );
}

pw.Widget _marketPdfMetric(
  String label,
  String value,
  PdfColor panel,
  PdfColor border,
  PdfColor dark,
  PdfColor muted,
) {
  return pw.Expanded(
    child: pw.Container(
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
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: muted,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: dark,
            ),
          ),
        ],
      ),
    ),
  );
}

pw.Widget _marketPdfMetalSection({
  required String title,
  required String modeLabel,
  required List<MarketRefillItemRow> rows,
  required PdfColor accent,
  required PdfColor border,
  required PdfColor panel,
  required PdfColor dark,
  required PdfColor muted,
}) {
  final grouped = <String, List<MarketRefillItemRow>>{};
  for (final row in rows) {
    grouped.putIfAbsent(_marketPdfGroupTitle(row), () => []).add(row);
  }

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
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: dark,
                ),
              ),
            ),
            pw.Text(
              '$modeLabel | ${rows.length} lines',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        for (final entry in grouped.entries) ...[
          _marketPdfGroupBlock(
            title: entry.key,
            rows: entry.value,
            accent: accent,
            border: border,
            panel: panel,
            dark: dark,
            muted: muted,
          ),
          if (entry.key != grouped.keys.last) pw.SizedBox(height: 9),
        ],
      ],
    ),
  );
}

pw.Widget _marketPdfGroupBlock({
  required String title,
  required List<MarketRefillItemRow> rows,
  required PdfColor accent,
  required PdfColor border,
  required PdfColor panel,
  required PdfColor dark,
  required PdfColor muted,
}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: border),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: pw.BoxDecoration(
            color: panel,
            borderRadius: const pw.BorderRadius.vertical(
              top: pw.Radius.circular(8),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: dark,
                  ),
                ),
              ),
              pw.Text(
                '${rows.length} item',
                style: pw.TextStyle(fontSize: 8, color: muted),
              ),
            ],
          ),
        ),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(3.4),
            1: pw.FlexColumnWidth(1.35),
            2: pw.FlexColumnWidth(1.35),
            3: pw.FlexColumnWidth(0.9),
          },
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: border, width: 0.6),
          ),
          children: [
            _marketPdfTableRow(
              ['Item Name', 'Sold Qty', 'Bought Qty', 'Done'],
              dark,
              muted,
              isHeader: true,
            ),
            for (final row in rows)
              _marketPdfTableRow(
                [
                  _marketPdfItemName(row),
                  _marketPdfQty(row.soldQuantity, row.unitLabel),
                  _marketPdfQty(row.boughtQuantity, row.unitLabel),
                  row.purchaseDone ? 'Yes' : 'No',
                ],
                dark,
                muted,
              ),
          ],
        ),
      ],
    ),
  );
}

pw.TableRow _marketPdfTableRow(
  List<String> values,
  PdfColor dark,
  PdfColor muted, {
  bool isHeader = false,
}) {
  return pw.TableRow(
    children: [
      for (final value in values)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: pw.Text(
            value,
            maxLines: isHeader ? 1 : 2,
            style: pw.TextStyle(
              fontSize: isHeader ? 7.5 : 9,
              fontWeight: pw.FontWeight.bold,
              color: isHeader ? muted : dark,
            ),
          ),
        ),
    ],
  );
}

class _MarketPurchasePdfPreviewScreen extends StatelessWidget {
  final MarketRefillReport report;

  const _MarketPurchasePdfPreviewScreen({required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvColors.bodyBg,
      appBar: _MarketRefillAppBar(
        onBack: () => Navigator.of(context).maybePop(),
        onRefresh: () {},
      ),
      body: PdfPreview(
        build: (_) => const MarketPurchasePdfService().build(report),
        pdfFileName: _marketPurchasePdfFileName(),
        initialPageFormat: PdfPageFormat.a4,
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

String _marketPdfGroupTitle(MarketRefillItemRow row) {
  if (row.metal.trim().toLowerCase() == 'silver') return row.companyLabel;
  final grade = row.gradeLabel.trim();
  return grade.isEmpty ? '${row.metal} Stock' : grade;
}

String _marketPdfItemName(MarketRefillItemRow row) {
  if (row.itemNames.isEmpty) return row.title;
  if (row.itemNames.length <= 2) return row.itemNames.join(' / ');
  return '${row.title} (${row.itemNames.length} item names)';
}

String _marketPdfQty(int value, String unitLabel) => '$value $unitLabel';

int _metalSoldQuantity(MarketRefillReport report, String metal) {
  return report.rows
      .where((row) => row.metal.trim().toLowerCase() == metal)
      .fold(0, (sum, row) => sum + row.soldQuantity);
}

String _marketPurchasePdfFileName() {
  final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
  return 'lotus_market_purchase_list_$stamp.pdf';
}
