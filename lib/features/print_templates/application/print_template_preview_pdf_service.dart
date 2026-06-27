import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/print_template_registry.dart';

class PrintTemplatePreviewPdfService {
  static final _amountFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static const _navy = PdfColor.fromInt(0xFF172437);
  static const _gold = PdfColor.fromInt(0xFFC89421);
  static const _goldLight = PdfColor.fromInt(0xFFFBF6E9);
  static const _ink = PdfColor.fromInt(0xFF172033);
  static const _muted = PdfColor.fromInt(0xFF111111);
  static const _line = PdfColor.fromInt(0xFFD8DEE8);
  static const _surface = PdfColor.fromInt(0xFFF6F8FB);

  Future<Uint8List> build({
    required PrintTemplateDefinition template,
    required PrintTemplateDocumentType documentType,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final pdf = pw.Document(
      theme: await _buildTheme(),
      title: '${template.shortName} ${documentType.label}',
      author: 'Lotus ERP',
      creator: 'Lotus ERP',
      subject: 'Print template preview',
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 22),
        ),
        footer: (context) => _footer(context, template),
        build: (_) => [
          _heroHeader(template, documentType),
          pw.SizedBox(height: 10),
          _partyAndAmountPanel(documentType),
          pw.SizedBox(height: 10),
          _sectionHeading(
            number: '01',
            title: _itemSectionTitle(documentType),
            subtitle: _itemSectionSubtitle(documentType),
          ),
          pw.SizedBox(height: 8),
          _itemsTable(documentType),
          pw.SizedBox(height: 10),
          _settlementPanel(documentType),
          pw.SizedBox(height: 10),
          _sectionHeading(
            number: '02',
            title: 'TERMS & DECLARATION',
            subtitle: 'Module-specific terms print here when enabled',
          ),
          pw.SizedBox(height: 8),
          _termsBlock(documentType),
          pw.SizedBox(height: 12),
          _signOff(documentType),
        ],
      ),
    );

    return pdf.save();
  }

  Future<pw.ThemeData> _buildTheme() async {
    final windowsDirectory = Platform.environment['WINDIR'];
    if (windowsDirectory != null) {
      final regularFile = File('$windowsDirectory\\Fonts\\segoeui.ttf');
      final boldFile = File('$windowsDirectory\\Fonts\\segoeuib.ttf');
      if (regularFile.existsSync() && boldFile.existsSync()) {
        try {
          return pw.ThemeData.withFont(
            base: pw.Font.ttf(_asByteData(await regularFile.readAsBytes())),
            bold: pw.Font.ttf(_asByteData(await boldFile.readAsBytes())),
          );
        } catch (_) {}
      }
    }
    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );
  }

  ByteData _asByteData(Uint8List bytes) {
    return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
  }

  pw.Widget _heroHeader(
    PrintTemplateDefinition template,
    PrintTemplateDocumentType documentType,
  ) {
    final metadata = <({String label, String value})>[
      (label: 'DOCUMENT NUMBER', value: _documentNumber(documentType)),
      (label: 'PRINT DATE', value: _dateFormat.format(DateTime.now())),
      (label: 'TEMPLATE', value: template.shortName),
      (label: 'MODULE', value: documentType.label),
    ];

    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _brandMark(),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ANJALI JEWELLERS',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 19,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'EAST LAKSHMI NAGAR, KHEMNICHAK, PATNA, BIHAR',
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Mobile: 9304479436',
                        style: pw.TextStyle(
                          color: _gold,
                          fontSize: 7.2,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: _goldLight,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                      child: pw.Text(
                        _documentTitle(documentType),
                        style: pw.TextStyle(
                          color: _navy,
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'TEMPLATE PREVIEW',
                      style: pw.TextStyle(
                        color: _gold,
                        fontSize: 6.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Container(height: 1.4, color: _gold),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: pw.Row(
              children: [
                for (var index = 0; index < metadata.length; index++) ...[
                  if (index > 0) _headerDivider(),
                  pw.Expanded(
                    child: _headerMeta(
                      label: metadata[index].label,
                      value: metadata[index].value,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _brandMark() {
    return pw.Container(
      width: 52,
      height: 52,
      padding: const pw.EdgeInsets.all(2),
      decoration: const pw.BoxDecoration(
        color: _gold,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Container(
        alignment: pw.Alignment.center,
        decoration: const pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text(
          'AJ',
          style: pw.TextStyle(
            color: _gold,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _headerDivider() {
    return pw.Container(
      width: 0.7,
      height: 27,
      margin: const pw.EdgeInsets.symmetric(horizontal: 14),
      color: _gold,
    );
  }

  pw.Widget _headerMeta({
    required String label,
    required String value,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 7.5,
            letterSpacing: 0.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _partyAndAmountPanel(PrintTemplateDocumentType type) {
    final isPurchase = type == PrintTemplateDocumentType.purchaseVoucher ||
        type == PrintTemplateDocumentType.purchaseReturn;
    final partyTitle = isPurchase ? 'COUNTERPARTY DETAILS' : 'CUSTOMER DETAILS';
    final partyName = isPurchase ? 'MAA DURGA SUPPLIERS' : 'REYANSH SONI';
    final amountTitle = type == PrintTemplateDocumentType.girviReceipt
        ? 'LOAN AMOUNT'
        : type == PrintTemplateDocumentType.bookingAdvance
            ? 'ADVANCE AMOUNT'
            : 'TOTAL AMOUNT';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            height: 112,
            padding: const pw.EdgeInsets.all(13),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _line),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _eyebrow(partyTitle),
                pw.SizedBox(height: 7),
                pw.Text(
                  partyName,
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Spacer(),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _metaPair(
                        label: 'MOBILE',
                        value: isPurchase ? '9876543210' : '9304479436',
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: _metaPair(
                        label: 'ADDRESS',
                        value: isPurchase ? 'PATNA WHOLESALE MARKET' : 'PATNA',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            height: 112,
            padding: const pw.EdgeInsets.all(13),
            decoration: pw.BoxDecoration(
              color: _goldLight,
              border: pw.Border.all(color: _gold, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _eyebrow(amountTitle, color: _gold),
                pw.SizedBox(height: 6),
                pw.Text(
                  _amount(_mainAmount(type)),
                  style: pw.TextStyle(
                    color: _navy,
                    fontSize: 19,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Spacer(),
                pw.Container(
                  width: double.infinity,
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(
                        color: const PdfColor.fromInt(0xFFEAD6A0)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        _supportAmountLabel(type),
                        style: pw.TextStyle(
                          color: _muted,
                          fontSize: 6.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      pw.Text(
                        _supportAmountValue(type),
                        style: pw.TextStyle(
                          color: _ink,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionHeading({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 32,
          height: 32,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: _goldLight,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFEAD6A0)),
          ),
          child: pw.Text(
            number,
            style: pw.TextStyle(
              color: _gold,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 9),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                subtitle,
                style: pw.TextStyle(
                  color: _muted,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _itemsTable(PrintTemplateDocumentType type) {
    final rows = _sampleRows(type);
    return pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: _navy, width: 0.9),
        bottom: pw.BorderSide(color: _line, width: 0.6),
        horizontalInside: pw.BorderSide(color: _line, width: 0.45),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(28),
        1: pw.FlexColumnWidth(1.1),
        2: pw.FlexColumnWidth(2),
        3: pw.FixedColumnWidth(34),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1),
        6: pw.FlexColumnWidth(1),
        7: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _navy),
          children: _headers(type).map(_headerCell).toList(),
        ),
        ...rows.asMap().entries.map(
              (entry) => pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: entry.key.isEven ? PdfColors.white : _surface,
                ),
                children: entry.value.map(_bodyCell).toList(),
              ),
            ),
      ],
    );
  }

  pw.Widget _settlementPanel(PrintTemplateDocumentType type) {
    final metrics = _settlementMetrics(type);
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _surface,
        border: pw.Border.all(color: _line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
      ),
      child: pw.Row(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            if (index > 0) pw.SizedBox(width: 10),
            pw.Expanded(
              child: _metricBox(
                metrics[index].label,
                metrics[index].value,
                highlight: index == metrics.length - 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _termsBlock(PrintTemplateDocumentType type) {
    final lines = _terms(type);
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < lines.length; index++)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: index == 0 ? 0 : 5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${index + 1}. ',
                    style: pw.TextStyle(
                      color: _gold,
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      lines[index],
                      style: const pw.TextStyle(
                        color: _ink,
                        fontSize: 8.6,
                        lineSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _signOff(PrintTemplateDocumentType type) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            'This is a template preview. Live invoices will use actual module data, enabled columns and business terms.',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Container(
          width: 170,
          padding: const pw.EdgeInsets.only(top: 24),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _navy, width: 0.7)),
          ),
          child: pw.Text(
            _signatureLabel(type),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _footer(
    pw.Context context,
    PrintTemplateDefinition template,
  ) {
    return pw.Column(
      children: [
        pw.Divider(color: _line, height: 1),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${template.shortName} template preview',
              style: const pw.TextStyle(color: _muted, fontSize: 7.5),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(color: _muted, fontSize: 7.5),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _eyebrow(String text, {PdfColor color = _gold}) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        color: color,
        fontSize: 7.3,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.45,
      ),
    );
  }

  pw.Widget _metaPair({
    required String label,
    required String value,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: _muted,
            fontSize: 6.5,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          maxLines: 2,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            color: _ink,
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _metricBox(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: highlight ? _goldLight : PdfColors.white,
        border: pw.Border.all(color: highlight ? _gold : _line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: _muted,
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: highlight ? _gold : _ink,
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _bodyCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(
          color: _ink,
          fontSize: 7.8,
        ),
      ),
    );
  }

  String _documentTitle(PrintTemplateDocumentType type) {
    switch (type) {
      case PrintTemplateDocumentType.salesInvoice:
        return 'SALES INVOICE';
      case PrintTemplateDocumentType.salesReturn:
        return 'SALES RETURN';
      case PrintTemplateDocumentType.purchaseVoucher:
        return 'PURCHASE VOUCHER';
      case PrintTemplateDocumentType.purchaseReturn:
        return 'PURCHASE RETURN';
      case PrintTemplateDocumentType.bookingAdvance:
        return 'ADVANCE RECEIPT';
      case PrintTemplateDocumentType.girviReceipt:
        return 'GIRVI RECEIPT';
    }
  }

  String _documentNumber(PrintTemplateDocumentType type) {
    switch (type) {
      case PrintTemplateDocumentType.salesInvoice:
        return 'SALE-00042';
      case PrintTemplateDocumentType.salesReturn:
        return 'SRT-00008';
      case PrintTemplateDocumentType.purchaseVoucher:
        return 'PUR-00031';
      case PrintTemplateDocumentType.purchaseReturn:
        return 'PRT-00005';
      case PrintTemplateDocumentType.bookingAdvance:
        return 'ADV-00019';
      case PrintTemplateDocumentType.girviReceipt:
        return 'GRV-0016';
    }
  }

  String _itemSectionTitle(PrintTemplateDocumentType type) {
    switch (type) {
      case PrintTemplateDocumentType.girviReceipt:
        return 'PLEDGED ITEMS';
      case PrintTemplateDocumentType.bookingAdvance:
        return 'BOOKING DETAILS';
      default:
        return 'ITEM DETAILS';
    }
  }

  String _itemSectionSubtitle(PrintTemplateDocumentType type) {
    switch (type) {
      case PrintTemplateDocumentType.salesInvoice:
        return 'Live sales items grouped by selected metal';
      case PrintTemplateDocumentType.salesReturn:
        return 'Returned sales items and value reversal';
      case PrintTemplateDocumentType.purchaseVoucher:
        return 'Purchased metal details from customer or supplier';
      case PrintTemplateDocumentType.purchaseReturn:
        return 'Returned purchase items and settlement details';
      case PrintTemplateDocumentType.bookingAdvance:
        return 'Advance booking item details and expected delivery';
      case PrintTemplateDocumentType.girviReceipt:
        return 'Pledged ornaments recorded with this ticket';
    }
  }

  List<String> _headers(PrintTemplateDocumentType type) {
    switch (type) {
      case PrintTemplateDocumentType.purchaseVoucher:
      case PrintTemplateDocumentType.purchaseReturn:
        return const [
          'S/N',
          'Metal',
          'Item',
          'Pcs',
          'Purity',
          'Gross',
          'Fine',
          'Value',
        ];
      case PrintTemplateDocumentType.girviReceipt:
        return const [
          'S/N',
          'Metal',
          'Item',
          'Pcs',
          'Purity',
          'Gross',
          'Net',
          'Valuation',
        ];
      default:
        return const [
          'S/N',
          'Metal',
          'Item',
          'Pcs',
          'Purity',
          'Net',
          'Rate',
          'Amount',
        ];
    }
  }

  List<List<String>> _sampleRows(PrintTemplateDocumentType type) {
    switch (type) {
      case PrintTemplateDocumentType.purchaseVoucher:
      case PrintTemplateDocumentType.purchaseReturn:
        return const [
          [
            '01',
            'Gold',
            'Old Ring',
            '1',
            '22KT',
            '8.000 g',
            '7.333 g',
            'Rs 88,000'
          ],
          [
            '02',
            'Silver',
            'Payal',
            '2',
            '925',
            '46.000 g',
            '42.550 g',
            'Rs 4,255'
          ],
        ];
      case PrintTemplateDocumentType.girviReceipt:
        return const [
          [
            '01',
            'Gold',
            'Ring',
            '1',
            '18KT',
            '4.000 g',
            '4.000 g',
            'Rs 31,200'
          ],
          [
            '02',
            'Silver',
            'Chain',
            '1',
            '925',
            '20.000 g',
            '20.000 g',
            'Rs 2,100'
          ],
        ];
      case PrintTemplateDocumentType.bookingAdvance:
        return const [
          [
            '01',
            'Gold',
            'Custom Ring',
            '1',
            '22KT',
            '8.000 g',
            'Rs 12,000',
            'Rs 1,08,000'
          ],
          [
            '02',
            'Diamond',
            'Solitaire',
            '1',
            'VVS1',
            '0.75 ct',
            'Rs 40,000',
            'Rs 40,000'
          ],
        ];
      default:
        return const [
          [
            '01',
            'Gold',
            'Ring',
            '1',
            '22KT',
            '8.000 g',
            'Rs 12,000',
            'Rs 1,07,520'
          ],
          [
            '02',
            'Diamond',
            'Pendant',
            '1',
            'VVS1',
            '0.500 ct',
            'Rs 35,000',
            'Rs 35,000'
          ],
        ];
    }
  }

  List<({String label, String value})> _settlementMetrics(
    PrintTemplateDocumentType type,
  ) {
    switch (type) {
      case PrintTemplateDocumentType.girviReceipt:
        return [
          (label: 'Principal', value: _amount(12000)),
          (label: 'Interest Rate', value: '5.00% monthly'),
          (label: 'Maturity', value: '10 Sep 2025'),
          (label: 'Net Payable', value: _amount(12000)),
        ];
      case PrintTemplateDocumentType.bookingAdvance:
        return [
          (label: 'Estimated Value', value: _amount(148000)),
          (label: 'Advance Paid', value: _amount(25000)),
          (label: 'Balance Due', value: _amount(123000)),
          (label: 'Delivery Date', value: '15 Jul 2026'),
        ];
      case PrintTemplateDocumentType.purchaseVoucher:
      case PrintTemplateDocumentType.purchaseReturn:
        return [
          (label: 'Gross Purchase', value: _amount(92255)),
          (label: 'GST / Charges', value: _amount(0)),
          (label: 'Paid', value: _amount(80000)),
          (label: 'Balance', value: _amount(12255)),
        ];
      default:
        return [
          (label: 'Gross Value', value: _amount(147520)),
          (label: 'Discount', value: _amount(200)),
          (label: 'Paid', value: _amount(147320)),
          (label: 'Balance', value: _amount(0)),
        ];
    }
  }

  List<String> _terms(PrintTemplateDocumentType type) {
    switch (type) {
      case PrintTemplateDocumentType.girviReceipt:
        return const [
          'Customer must keep this receipt safely and present it at the time of release.',
          'Pledged items will be released only after principal, interest and applicable charges are cleared.',
          'Terms, declaration and footer text will follow Girvi billing setup.',
        ];
      case PrintTemplateDocumentType.purchaseVoucher:
      case PrintTemplateDocumentType.purchaseReturn:
        return const [
          'Quality, purity and weight verification will be recorded before final settlement.',
          'Purchase return and supplier settlement terms will follow purchase billing setup.',
          'Payment breakup will print from the actual purchase ledger.',
        ];
      default:
        return const [
          'Original bill is required for service, exchange or return workflow.',
          'Payment breakup, due amount and customer credit will print from the actual invoice ledger.',
          'Terms, return policy and footer text will follow sales billing setup.',
        ];
    }
  }

  String _signatureLabel(PrintTemplateDocumentType type) {
    switch (type) {
      case PrintTemplateDocumentType.purchaseVoucher:
      case PrintTemplateDocumentType.purchaseReturn:
        return 'Authorized Purchase Signature';
      case PrintTemplateDocumentType.girviReceipt:
        return 'Authorized Girvi Signature';
      default:
        return 'Authorized Signature';
    }
  }

  double _mainAmount(PrintTemplateDocumentType type) {
    switch (type) {
      case PrintTemplateDocumentType.girviReceipt:
        return 12000;
      case PrintTemplateDocumentType.bookingAdvance:
        return 25000;
      case PrintTemplateDocumentType.purchaseVoucher:
      case PrintTemplateDocumentType.purchaseReturn:
        return 92255;
      default:
        return 147320;
    }
  }

  String _supportAmountLabel(PrintTemplateDocumentType type) {
    switch (type) {
      case PrintTemplateDocumentType.girviReceipt:
        return 'MONTHLY INTEREST';
      case PrintTemplateDocumentType.bookingAdvance:
        return 'ESTIMATED VALUE';
      case PrintTemplateDocumentType.purchaseVoucher:
      case PrintTemplateDocumentType.purchaseReturn:
        return 'BALANCE DUE';
      default:
        return 'PAYMENT STATUS';
    }
  }

  String _supportAmountValue(PrintTemplateDocumentType type) {
    switch (type) {
      case PrintTemplateDocumentType.girviReceipt:
        return _amount(600);
      case PrintTemplateDocumentType.bookingAdvance:
        return _amount(148000);
      case PrintTemplateDocumentType.purchaseVoucher:
      case PrintTemplateDocumentType.purchaseReturn:
        return _amount(12255);
      default:
        return 'Fully Paid';
    }
  }

  String _amount(double value) => 'Rs ${_amountFormat.format(value)}';
}
