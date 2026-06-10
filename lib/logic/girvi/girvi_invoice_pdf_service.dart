import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/girvi/girvi_invoice_draft.dart';
import '../../models/setting/billing_setup/girvi_billing_model.dart';

enum GirviInvoiceFormat {
  a4,
  compactA5;

  String get label => this == a4 ? 'A4 Size' : 'Compact A5';

  String get subtitle =>
      this == a4 ? 'Premium full-page invoice' : 'Landscape counter copy';

  PdfPageFormat get pageFormat =>
      this == a4 ? PdfPageFormat.a4 : PdfPageFormat.a5.landscape;
}

class GirviInvoicePdfService {
  static final _amountFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final _dateFormat = DateFormat('dd MMM yyyy');

  static const _navy = PdfColor.fromInt(0xFF172437);
  static const _navySoft = PdfColor.fromInt(0xFF22344E);
  static const _gold = PdfColor.fromInt(0xFFC89421);
  static const _goldLight = PdfColor.fromInt(0xFFFBF6E9);
  static const _ink = PdfColor.fromInt(0xFF172033);
  static const _muted = PdfColor.fromInt(0xFF667085);
  static const _line = PdfColor.fromInt(0xFFD8DEE8);
  static const _surface = PdfColor.fromInt(0xFFF6F8FB);

  static const customerItemHeaders = <String>[
    'S/N',
    'Metal',
    'Item',
    'Pcs',
    'HUID',
    'Purity',
    'Gross Wt.',
    'Less Wt.',
    'Net Wt.',
  ];

  Future<Uint8List> build({
    required GirviInvoiceDraft draft,
    required GirviInvoiceFormat format,
    GirviBillingModel settings = const GirviBillingModel(),
    int copies = 1,
    bool duplicateStamp = false,
  }) async {
    final pdf = pw.Document(
      theme: await _buildTheme(),
      title: 'Girvi Invoice ${draft.ticketNo}',
      author: 'Lotus ERP',
      creator: 'Lotus ERP',
      subject: 'Girvi customer receipt',
    );
    final safeCopies = copies.clamp(1, 5);

    for (var copy = 0; copy < safeCopies; copy++) {
      final copyLabel = duplicateStamp && copy == 0
          ? 'DUPLICATE COPY'
          : copy > 0
              ? 'COPY ${copy + 1}'
              : 'CUSTOMER COPY';
      final compact = format == GirviInvoiceFormat.compactA5;

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: format.pageFormat,
            margin: pw.EdgeInsets.fromLTRB(
              compact ? 18 : 28,
              compact ? 16 : 24,
              compact ? 18 : 28,
              compact ? 18 : 22,
            ),
          ),
          footer: (context) => _buildPageFooter(
            context,
            draft,
            compact,
          ),
          build: (_) => _buildDocument(
            draft,
            format,
            copyLabel,
          ),
        ),
      );
    }

    return pdf.save();
  }

  Future<pw.ThemeData> _buildTheme() async {
    final windowsDirectory = Platform.environment['WINDIR'];
    if (windowsDirectory != null) {
      final regularFile = File('$windowsDirectory\\Fonts\\segoeui.ttf');
      final boldFile = File('$windowsDirectory\\Fonts\\segoeuib.ttf');
      if (regularFile.existsSync() && boldFile.existsSync()) {
        try {
          final regularBytes = await regularFile.readAsBytes();
          final boldBytes = await boldFile.readAsBytes();
          return pw.ThemeData.withFont(
            base: pw.Font.ttf(_asByteData(regularBytes)),
            bold: pw.Font.ttf(_asByteData(boldBytes)),
          );
        } catch (_) {
          // The built-in fonts remain a reliable fallback.
        }
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

  List<pw.Widget> _buildDocument(
    GirviInvoiceDraft draft,
    GirviInvoiceFormat format,
    String copyLabel,
  ) {
    final compact = format == GirviInvoiceFormat.compactA5;
    final sectionGap = compact ? 10.0 : 14.0;
    final photos = _loadPhotos(draft);

    return [
      _buildHeroHeader(draft, compact, copyLabel),
      pw.SizedBox(height: sectionGap),
      _buildCustomerAndLoanPanel(draft, compact),
      pw.SizedBox(height: sectionGap),
      pw.NewPage(freeSpace: compact ? 115 : 150),
      _buildSectionHeading(
        number: '01',
        title: 'PLEDGED ITEM DETAILS',
        subtitle: 'Customer-facing item description and weights',
        compact: compact,
      ),
      pw.SizedBox(height: compact ? 6 : 8),
      _buildItemsTable(draft, compact),
      if (photos.isNotEmpty) ...[
        pw.SizedBox(height: sectionGap),
        pw.NewPage(freeSpace: compact ? 135 : 175),
        _buildPhotoSection(photos, compact),
      ],
    ];
  }

  pw.Widget _buildHeroHeader(
    GirviInvoiceDraft draft,
    bool compact,
    String copyLabel,
  ) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Padding(
            padding: pw.EdgeInsets.fromLTRB(
              compact ? 12 : 16,
              compact ? 11 : 15,
              compact ? 12 : 16,
              compact ? 9 : 12,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: compact ? 31 : 38,
                  height: compact ? 31 : 38,
                  alignment: pw.Alignment.center,
                  decoration: const pw.BoxDecoration(
                    color: _gold,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Text(
                    'L',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: compact ? 15 : 19,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: compact ? 9 : 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LOTUS ERP',
                        style: pw.TextStyle(
                          color: _gold,
                          fontSize: compact ? 7.5 : 9,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'GIRVI LOAN RECEIPT',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: compact ? 14 : 18,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'JEWELLERY | PLEDGE CUSTOMER DOCUMENT',
                        style: pw.TextStyle(
                          color: PdfColors.grey300,
                          fontSize: compact ? 5.5 : 6.5,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 5 : 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: _navySoft,
                    border: pw.Border.all(
                      color: _gold,
                      width: 0.7,
                    ),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Text(
                    copyLabel,
                    style: pw.TextStyle(
                      color: _gold,
                      fontSize: compact ? 6 : 7,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            height: 1.4,
            color: _gold,
          ),
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 7 : 9,
            ),
            child: pw.Row(
              children: [
                _buildHeaderMeta(
                  label: 'RECEIPT NUMBER',
                  value: draft.ticketNo,
                  compact: compact,
                ),
                pw.Container(
                  width: 0.7,
                  height: compact ? 22 : 27,
                  margin: pw.EdgeInsets.symmetric(
                    horizontal: compact ? 13 : 18,
                  ),
                  color: PdfColors.grey700,
                ),
                _buildHeaderMeta(
                  label: 'ISSUE DATE',
                  value: _dateFormat.format(draft.createdAt),
                  compact: compact,
                ),
                pw.Spacer(),
                pw.Text(
                  'Secure customer copy',
                  style: pw.TextStyle(
                    color: PdfColors.grey400,
                    fontSize: compact ? 5.8 : 7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHeaderMeta({
    required String label,
    required String value,
    required bool compact,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColors.grey400,
            fontSize: compact ? 5.2 : 6.2,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: compact ? 7.2 : 8.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerAndLoanPanel(
    GirviInvoiceDraft draft,
    bool compact,
  ) {
    final panelHeight = compact ? 82.0 : 101.0;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            height: panelHeight,
            padding: pw.EdgeInsets.all(compact ? 10 : 13),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _line),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildEyebrow('CUSTOMER DETAILS', compact),
                pw.SizedBox(height: compact ? 5 : 7),
                pw.Text(
                  draft.customerName,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: compact ? 11 : 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Spacer(),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: _buildCustomerMeta(
                        label: 'MOBILE',
                        value: draft.customerMobile,
                        compact: compact,
                      ),
                    ),
                    pw.SizedBox(width: compact ? 8 : 12),
                    pw.Expanded(
                      flex: 6,
                      child: _buildCustomerMeta(
                        label: 'CITY',
                        value: draft.customerCity.isEmpty
                            ? '-'
                            : draft.customerCity,
                        compact: compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: compact ? 9 : 12),
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            height: panelHeight,
            padding: pw.EdgeInsets.all(compact ? 10 : 13),
            decoration: pw.BoxDecoration(
              color: _goldLight,
              border: pw.Border.all(
                color: _gold,
                width: 0.8,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildEyebrow('LOAN AMOUNT', compact, color: _gold),
                pw.SizedBox(height: compact ? 4 : 6),
                pw.Text(
                  _amount(draft.loanAmount),
                  style: pw.TextStyle(
                    color: _navy,
                    fontSize: compact ? 14 : 19,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Spacer(),
                pw.Container(
                  width: double.infinity,
                  padding: pw.EdgeInsets.symmetric(
                    horizontal: compact ? 7 : 9,
                    vertical: compact ? 5 : 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFFEAD6A0),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'MONTHLY INTEREST',
                        style: pw.TextStyle(
                          color: _muted,
                          fontSize: compact ? 5.5 : 6.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      pw.Spacer(),
                      pw.Text(
                        '${draft.interestRate.toStringAsFixed(2)}%',
                        style: pw.TextStyle(
                          color: _navy,
                          fontSize: compact ? 8 : 10,
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

  pw.Widget _buildEyebrow(
    String value,
    bool compact, {
    PdfColor color = _muted,
  }) {
    return pw.Text(
      value,
      style: pw.TextStyle(
        color: color,
        fontSize: compact ? 5.8 : 7,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.7,
      ),
    );
  }

  pw.Widget _buildCustomerMeta({
    required String label,
    required String value,
    required bool compact,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildEyebrow(label, compact),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            color: _ink,
            fontSize: compact ? 7 : 8.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSectionHeading({
    required String number,
    required String title,
    required String subtitle,
    required bool compact,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: compact ? 24 : 29,
          height: compact ? 24 : 29,
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(
            color: _navy,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Text(
            number,
            style: pw.TextStyle(
              color: _gold,
              fontSize: compact ? 7 : 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: compact ? 8 : 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: _ink,
                fontSize: compact ? 8 : 10,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                color: _muted,
                fontSize: compact ? 5.5 : 6.7,
              ),
            ),
          ],
        ),
        pw.SizedBox(width: compact ? 10 : 14),
        pw.Expanded(
          child: pw.Container(
            height: 0.7,
            color: _line,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(
    GirviInvoiceDraft draft,
    bool compact,
  ) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: _navySoft),
        children: [
          for (var index = 0; index < customerItemHeaders.length; index++)
            _buildTableCell(
              customerItemHeaders[index],
              compact: compact,
              header: true,
              alignment:
                  index == 2 ? pw.Alignment.centerLeft : pw.Alignment.center,
            ),
        ],
      ),
      for (var index = 0; index < draft.items.length; index++)
        _buildItemRow(draft.items[index], index, compact),
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(0.42),
          1: pw.FlexColumnWidth(0.65),
          2: pw.FlexColumnWidth(2.25),
          3: pw.FlexColumnWidth(0.44),
          4: pw.FlexColumnWidth(0.86),
          5: pw.FlexColumnWidth(0.63),
          6: pw.FlexColumnWidth(0.84),
          7: pw.FlexColumnWidth(0.78),
          8: pw.FlexColumnWidth(0.84),
        },
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _line, width: 0.45),
          verticalInside: pw.BorderSide(color: _line, width: 0.45),
        ),
        children: rows,
      ),
    );
  }

  pw.TableRow _buildItemRow(
    GirviInvoiceItemDraft item,
    int index,
    bool compact,
  ) {
    final values = <String>[
      item.serialNo.toString(),
      item.metal,
      item.description,
      item.pieces.toString(),
      item.huid.isEmpty ? '-' : item.huid,
      item.purity,
      '${item.grossWeight.toStringAsFixed(3)} g',
      '${item.lessWeight.toStringAsFixed(3)} g',
      '${item.netWeight.toStringAsFixed(3)} g',
    ];
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: index.isEven ? PdfColors.white : _surface,
      ),
      children: [
        for (var cellIndex = 0; cellIndex < values.length; cellIndex++)
          _buildTableCell(
            values[cellIndex],
            compact: compact,
            alignment: cellIndex == 2
                ? pw.Alignment.centerLeft
                : cellIndex >= 6
                    ? pw.Alignment.centerRight
                    : pw.Alignment.center,
            strong: cellIndex == 0 || cellIndex == 2,
          ),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String value, {
    required bool compact,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    bool header = false,
    bool strong = false,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: pw.EdgeInsets.symmetric(
        horizontal: compact ? 3 : 4,
        vertical: compact ? 5 : 6.5,
      ),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          color: header ? PdfColors.white : _ink,
          fontSize: header ? (compact ? 5.7 : 6.5) : (compact ? 5.8 : 6.8),
          fontWeight:
              header || strong ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  List<_GirviPhoto> _loadPhotos(GirviInvoiceDraft draft) {
    final photos = <_GirviPhoto>[];
    for (final item in draft.items) {
      for (final path in item.photoPaths) {
        final file = File(path);
        if (!file.existsSync()) continue;
        try {
          photos.add(
            _GirviPhoto(
              serialNo: item.serialNo,
              title: item.description,
              image: pw.MemoryImage(file.readAsBytesSync()),
            ),
          );
        } catch (_) {
          // A damaged image should not stop the customer invoice.
        }
      }
    }
    return photos;
  }

  pw.Widget _buildPhotoSection(
    List<_GirviPhoto> photos,
    bool compact,
  ) {
    const columns = 3;
    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionHeading(
                number: '02',
                title: 'PLEDGED ITEM PHOTOS',
                subtitle: 'Visual reference attached with this receipt',
                compact: compact,
              ),
              pw.SizedBox(height: compact ? 7 : 9),
            ],
          ),
        ],
      ),
    ];
    for (var start = 0; start < photos.length; start += columns) {
      final end =
          (start + columns < photos.length) ? start + columns : photos.length;
      final rowPhotos = photos.sublist(start, end);
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.only(
                bottom: start + columns < photos.length ? (compact ? 7 : 9) : 0,
              ),
              child: _buildPhotoRow(rowPhotos, columns, compact),
            ),
          ],
        ),
      );
    }
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(),
      },
      children: rows,
    );
  }

  pw.Widget _buildPhotoRow(
    List<_GirviPhoto> photos,
    int columns,
    bool compact,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < columns; index++) ...[
          if (index > 0) pw.SizedBox(width: compact ? 7 : 9),
          pw.Expanded(
            child: index < photos.length
                ? _buildPhotoCard(photos[index], compact)
                : pw.SizedBox(),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildPhotoCard(
    _GirviPhoto photo,
    bool compact,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(compact ? 4 : 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            height: compact ? 70 : 94,
            width: double.infinity,
            padding: const pw.EdgeInsets.all(3),
            decoration: const pw.BoxDecoration(
              color: _surface,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Image(
              photo.image,
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(height: compact ? 4 : 5),
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: const pw.BoxDecoration(
                  color: _goldLight,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  '#${photo.serialNo}',
                  style: pw.TextStyle(
                    color: _gold,
                    fontSize: compact ? 5.5 : 6.3,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 5),
              pw.Expanded(
                child: pw.Text(
                  photo.title,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: compact ? 5.5 : 6.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(
    pw.Context context,
    GirviInvoiceDraft draft,
    bool compact,
  ) {
    final isLastPage = context.pageNumber == context.pagesCount;
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (isLastPage) ...[
          pw.SizedBox(height: compact ? 13 : 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSignature('Customer Signature', compact),
              _buildSignature('Authorized Signature', compact),
            ],
          ),
          pw.SizedBox(height: compact ? 8 : 11),
        ],
        pw.Container(height: 0.7, color: _line),
        pw.SizedBox(height: compact ? 4 : 6),
        pw.Row(
          children: [
            pw.Text(
              'LOTUS ERP | GIRVI CUSTOMER COPY',
              style: pw.TextStyle(
                color: _navy,
                fontSize: compact ? 5.2 : 6.2,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              '${draft.ticketNo}  |  Page ${context.pageNumber}',
              style: pw.TextStyle(
                color: _muted,
                fontSize: compact ? 5.2 : 6.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSignature(String label, bool compact) {
    return pw.SizedBox(
      width: compact ? 128 : 165,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(height: 0.7, color: _muted),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              color: _muted,
              fontSize: compact ? 5.8 : 7,
            ),
          ),
        ],
      ),
    );
  }

  String _amount(double value) => 'Rs ${_amountFormat.format(value)}';
}

class _GirviPhoto {
  const _GirviPhoto({
    required this.serialNo,
    required this.title,
    required this.image,
  });

  final int serialNo;
  final String title;
  final pw.MemoryImage image;
}
