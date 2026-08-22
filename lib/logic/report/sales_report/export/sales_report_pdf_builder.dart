import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/pdf/lotus_pdf_theme.dart';
import '../../../../models/reports/sales_report/sales_report_models.dart';
import 'sales_report_export_formatters.dart';

class SalesReportPdfBuilder {
  SalesReportPdfBuilder._();

  static const PdfColor _black = PdfColors.black;
  static const PdfColor _dark = PdfColors.black;
  static const PdfColor _gold = PdfColor.fromInt(0xFFF2C94C);
  static const PdfColor _softGold = PdfColor.fromInt(0xFFFFF6D8);
  static const PdfColor _paper = PdfColor.fromInt(0xFFFFFCF4);
  static const PdfColor _white = PdfColors.white;

  static Future<Uint8List> buildComplete(
    SalesReportSnapshot snapshot, {
    required String reportTitle,
    required SalesReportExportIdentity identity,
  }) async {
    final document = pw.Document(
      title:
          '$reportTitle - ${SalesReportExportFormatters.periodLabel(snapshot.filter)}',
      author: identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: await LotusPdfTheme.reportTheme(),
        footer: _pdfFooter,
        build: (_) => _completeReportWidgets(
          reportTitle: reportTitle,
          snapshot: snapshot,
          identity: identity,
        ),
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildGstLiability(
    SalesReportSnapshot snapshot, {
    required SalesReportExportIdentity identity,
  }) async {
    final document = pw.Document(
      title:
          'GST Liability Report - ${SalesReportExportFormatters.periodLabel(snapshot.filter)}',
      author: identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: await LotusPdfTheme.reportTheme(),
        footer: _pdfFooter,
        build: (_) => [
          _pdfHeader('GST Liability Report', snapshot.filter, identity),
          pw.SizedBox(height: 16),
          _pdfSection(
            'GST Liability Summary',
            const ['Metric', 'Value'],
            SalesReportExportFormatters.gstLiabilityRows(snapshot.gstLiability),
          ),
          pw.SizedBox(height: 16),
          _pdfSection(
            'Invoice Tax Audit',
            const [
              'Invoice',
              'Date',
              'Customer',
              'Type',
              'Taxable',
              'GST',
              'Final',
            ],
            snapshot.invoices
                .map(
                  (invoice) => [
                    invoice.billNo,
                    SalesReportExportFormatters.date(invoice.billDate),
                    invoice.customerName,
                    invoice.isGst ? 'GST' : 'NON-GST',
                    SalesReportExportFormatters.money(invoice.taxableAmount),
                    SalesReportExportFormatters.money(invoice.gstAmount),
                    SalesReportExportFormatters.money(invoice.finalAmount),
                  ],
                )
                .toList(growable: false),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildMetalComplete(
    SalesReportSnapshot snapshot, {
    required String metalTitle,
    required SalesReportExportIdentity identity,
  }) async {
    final document = pw.Document(
      title:
          '$metalTitle Sales Report - ${SalesReportExportFormatters.periodLabel(snapshot.filter)}',
      author: identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: await LotusPdfTheme.reportTheme(),
        footer: _pdfFooter,
        build: (_) => _metalCompleteReportWidgets(
          metalTitle: metalTitle,
          snapshot: snapshot,
          identity: identity,
        ),
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildInvoiceLedger(
    SalesReportSnapshot snapshot, {
    required SalesReportExportIdentity identity,
    String reportTitle = 'Invoice Ledger',
  }) async {
    final document = pw.Document(
      title:
          '$reportTitle - ${SalesReportExportFormatters.periodLabel(snapshot.filter)}',
      author: identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: await LotusPdfTheme.reportTheme(),
        footer: _pdfFooter,
        build: (_) => [
          _pdfHeader(reportTitle, snapshot.filter, identity),
          pw.SizedBox(height: 14),
          _pdfSection(
            'Invoice Register',
            const [
              'S.No',
              'Invoice',
              'Date/Time',
              'Status',
              'Customer',
              'Mobile',
              'GSTIN',
              'B2B/B2C',
              'Place',
              'Bill Status',
            ],
            _invoiceIdentityRegisterRows(snapshot.invoices),
          ),
          pw.SizedBox(height: 14),
          _pdfSection(
            'Invoice Tax Register',
            const [
              'S.No',
              'Invoice',
              'Gross',
              'Discount',
              'Taxable',
              'CGST',
              'SGST',
              'IGST',
              'Round',
              'Invoice Total',
            ],
            _invoiceTaxRegisterRows(snapshot.invoices),
          ),
          pw.SizedBox(height: 14),
          _pdfSection(
            'Payment Collection Register',
            const [
              'S.No',
              'Invoice',
              'Date/Time',
              'Customer',
              'Mobile',
              'Invoice Total',
              'Cash',
              'UPI',
              'Card',
              'Bank',
              'Paid',
              'Due',
              'Payment Status',
            ],
            _paymentCollectionRows(snapshot.invoices),
          ),
          pw.SizedBox(height: 14),
          _pdfSection(
            'Payment Adjustment Register',
            const [
              'S.No',
              'Invoice',
              'Advance',
              'Old Gold Adj.',
              'Return/Credit',
              'Bill Status',
            ],
            _paymentAdjustmentRows(snapshot.invoices),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildItemLedger(
    SalesReportSnapshot snapshot, {
    required SalesReportExportIdentity identity,
    String reportTitle = 'Item Ledger',
  }) async {
    final document = pw.Document(
      title:
          '$reportTitle - ${SalesReportExportFormatters.periodLabel(snapshot.filter)}',
      author: identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(22),
        theme: await LotusPdfTheme.reportTheme(),
        footer: _pdfFooter,
        build: (_) => [
          _pdfHeader(reportTitle, snapshot.filter, identity),
          pw.SizedBox(height: 14),
          _pdfSection(
            'Item Ledger',
            const [
              'S.No',
              'Invoice',
              'Date',
              'Customer',
              'Type',
              'Metal',
              'Item',
              'HUID',
              'Purity',
              'Pcs',
            ],
            _itemIdentityRows(snapshot.items),
          ),
          pw.SizedBox(height: 14),
          _pdfSection(
            'Item Weight & Amount Ledger',
            const [
              'S.No',
              'Invoice',
              'Metal',
              'Item',
              'Gross',
              'Less',
              'Net',
              'Rate',
              'Making',
              'Total',
            ],
            _itemAmountRows(snapshot.items),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildGradeWise(
    SalesReportSnapshot snapshot, {
    required String metalTitle,
    required SalesReportExportIdentity identity,
  }) async {
    final document = pw.Document(
      title: '$metalTitle Grade-wise Sales Report',
      author: identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        theme: await LotusPdfTheme.reportTheme(),
        footer: _pdfFooter,
        build: (_) => [
          _pdfHeader(
            '$metalTitle Grade-wise Sales Report',
            snapshot.filter,
            identity,
          ),
          pw.SizedBox(height: 14),
          _pdfSection(
            '$metalTitle Grade Summary',
            const [
              'Grade',
              'Invoices',
              'Items',
              'Pcs',
              'Gross Wt',
              'Net Wt',
              'Making',
              'Sales',
            ],
            SalesReportExportFormatters.gradeRows(snapshot.items),
          ),
          pw.SizedBox(height: 14),
          _pdfSection(
            '$metalTitle Item Ledger',
            const [
              'S.No',
              'Invoice',
              'Customer',
              'Item',
              'HUID',
              'Grade',
              'Pcs',
              'Gross',
              'Net',
              'Rate',
              'Total',
            ],
            _gradeItemRows(snapshot.items),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _pdfHeader(
    String title,
    SalesReportFilter filter,
    SalesReportExportIdentity identity,
  ) {
    final shopName = identity.shopName.trim().isEmpty
        ? 'Sales Report'
        : identity.shopName.trim();
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: const pw.BoxDecoration(color: _dark),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: _white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: _white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                for (final line in identity.headerLines.take(2))
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      line,
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: _white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Text(
            SalesReportExportFormatters.periodLabel(filter),
            style: pw.TextStyle(
              fontSize: 10,
              color: _white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generated ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: _black),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: _black),
        ),
      ],
    );
  }

  static List<pw.Widget> _completeReportWidgets({
    required String reportTitle,
    required SalesReportSnapshot snapshot,
    required SalesReportExportIdentity identity,
  }) {
    final widgets = <pw.Widget>[
      _pdfHeader(reportTitle, snapshot.filter, identity),
      pw.SizedBox(height: 14),
      _pdfSection(
        'Sales Summary',
        const ['Metric', 'Value'],
        SalesReportExportFormatters.salesSummaryRowsWithMetalBreakdown(
          snapshot,
        ),
      ),
    ];

    _addPdfSection(
      widgets,
      'GST Liability Summary',
      const ['Metric', 'Value'],
      SalesReportExportFormatters.gstLiabilityRows(snapshot.gstLiability),
    );

    if (snapshot.metals.isNotEmpty) {
      _addPdfSection(
        widgets,
        'Metal Sales Summary',
        const [
          'Metal',
          'Invoices',
          'Items',
          'Pcs',
          'Gross Wt',
          'Net Wt',
          'Making',
          'Sales',
        ],
        SalesReportExportFormatters.metalRows(snapshot.metals),
      );
    }

    if (snapshot.invoices.isNotEmpty) {
      _addPdfSection(
        widgets,
        'Invoice Register',
        const [
          'S.No',
          'Invoice',
          'Date/Time',
          'Status',
          'Customer',
          'Mobile',
          'GSTIN',
          'B2B/B2C',
          'Place',
          'Bill Status',
        ],
        _invoiceIdentityRegisterRows(snapshot.invoices),
      );
      _addPdfSection(
        widgets,
        'Invoice Tax Register',
        const [
          'S.No',
          'Invoice',
          'Gross',
          'Discount',
          'Taxable',
          'CGST',
          'SGST',
          'IGST',
          'Round',
          'Invoice Total',
        ],
        _invoiceTaxRegisterRows(snapshot.invoices),
      );
      _addPdfSection(
        widgets,
        'Payment Collection Register',
        const [
          'S.No',
          'Invoice',
          'Date/Time',
          'Customer',
          'Mobile',
          'Invoice Total',
          'Cash',
          'UPI',
          'Card',
          'Bank',
          'Paid',
          'Due',
          'Payment Status',
        ],
        _paymentCollectionRows(snapshot.invoices),
      );
      _addPdfSection(
        widgets,
        'Payment Adjustment Register',
        const [
          'S.No',
          'Invoice',
          'Advance',
          'Old Gold Adj.',
          'Return/Credit',
          'Bill Status',
        ],
        _paymentAdjustmentRows(snapshot.invoices),
      );
      _addPdfSection(
        widgets,
        'Customer Sales Register',
        const [
          'S.No',
          'Customer',
          'Mobile',
          'GSTIN',
          'B2B/B2C',
          'Invoices',
          'Gross',
          'Discount',
          'Taxable',
          'GST',
          'Invoice Total',
          'Paid',
          'Due',
          'Advance',
          'Old Gold Adj.',
        ],
        _customerSalesRows(snapshot.invoices),
      );
    }

    if (snapshot.items.isNotEmpty) {
      _addPdfSection(
        widgets,
        'Item Register',
        const [
          'S.No',
          'Invoice',
          'Date',
          'Customer',
          'Type',
          'Metal',
          'Item',
          'HUID',
          'Purity',
          'Pcs',
        ],
        _itemIdentityRows(snapshot.items),
      );
      _addPdfSection(
        widgets,
        'Item Weight & Amount Register',
        const [
          'S.No',
          'Invoice',
          'Metal',
          'Item',
          'Gross',
          'Less',
          'Net',
          'Rate',
          'Making',
          'Total',
        ],
        _itemAmountRows(snapshot.items),
      );
    }

    final gstInvoices =
        snapshot.invoices.where((invoice) => invoice.isGst).toList();
    if (gstInvoices.isNotEmpty) {
      _addPdfSection(
        widgets,
        'GST Register',
        const [
          'S.No',
          'Invoice',
          'Date',
          'Customer',
          'Taxable',
          'CGST',
          'SGST',
          'IGST',
          'Total GST',
          'Invoice Total',
        ],
        _recordedGstRows(gstInvoices),
      );
      final hsnRows = _hsnGstRows(snapshot);
      if (hsnRows.isNotEmpty) {
        _addPdfSection(
          widgets,
          'HSN GST Register',
          const [
            'S.No',
            'HSN/SAC',
            'GST Rate',
            'Invoices',
            'Lines',
            'Pcs',
            'Taxable',
            'CGST',
            'SGST',
            'IGST',
            'Total GST',
            'Invoice Value',
          ],
          hsnRows,
        );
      }
    }

    final nonGstInvoices =
        snapshot.invoices.where((invoice) => !invoice.isGst).toList();
    if (nonGstInvoices.isNotEmpty) {
      _addPdfSection(
        widgets,
        'Non-GST Sales Estimate',
        const [
          'S.No',
          'Invoice',
          'Date',
          'Customer',
          'Non-GST Sales',
          'Estimated GST 3%',
          'Estimated Total',
        ],
        _nonGstEstimateRows(nonGstInvoices),
      );
    }

    _addOptionalInvoiceSection(
      widgets,
      title: 'Advance Register',
      invoices: snapshot.invoices
          .where((invoice) => invoice.advanceAmount.abs() > 0.005)
          .toList(growable: false),
      headers: const [
        'S.No',
        'Invoice',
        'Date/Time',
        'Customer',
        'Mobile',
        'Invoice Total',
        'Advance',
        'Cash',
        'UPI',
        'Card',
        'Bank',
        'Paid',
        'Due',
        'Payment',
        'Bill Status',
      ],
      rows: _advanceRegisterRows,
    );
    _addOptionalInvoiceSection(
      widgets,
      title: 'Due Register',
      invoices: snapshot.invoices
          .where((invoice) => invoice.dueAmount.abs() > 0.005)
          .toList(growable: false),
      headers: const [
        'S.No',
        'Invoice',
        'Date/Time',
        'Customer',
        'Mobile',
        'GSTIN',
        'B2B/B2C',
        'Place',
        'Invoice Total',
        'Advance',
        'Paid',
        'Due',
        'Cash',
        'UPI/Card/Bank',
        'Bill Status',
      ],
      rows: _dueRegisterRows,
    );
    _addOptionalInvoiceSection(
      widgets,
      title: 'Old Gold Adjustment Register',
      invoices: snapshot.invoices
          .where((invoice) => invoice.tradeInDeduction.abs() > 0.005)
          .toList(growable: false),
      headers: const [
        'S.No',
        'Invoice',
        'Date/Time',
        'Customer',
        'Mobile',
        'Gross',
        'Old Gold Adj.',
        'Invoice Total',
        'Cash',
        'UPI',
        'Card',
        'Paid',
        'Due',
        'Bill Status',
      ],
      rows: _oldGoldRegisterRows,
    );
    _addOptionalInvoiceSection(
      widgets,
      title: 'Return Credit Register',
      invoices: snapshot.invoices
          .where((invoice) => invoice.returnCreditNoteAmount.abs() > 0.005)
          .toList(growable: false),
      headers: const [
        'S.No',
        'Invoice',
        'Date/Time',
        'Customer',
        'Mobile',
        'Invoice Total',
        'Return/Credit',
        'Paid',
        'Due',
        'Payment',
        'Bill Status',
      ],
      rows: _returnCreditRegisterRows,
    );

    if (snapshot.items.isNotEmpty) {
      _addPdfSection(
        widgets,
        'Metal Grade Register',
        const [
          'S.No',
          'Metal',
          'Grade/Purity',
          'Invoices',
          'Lines',
          'Pcs',
          'Gross Wt',
          'Net Wt',
          'Item Amount',
          'Making',
        ],
        _metalGradeRows(snapshot.items),
      );
    }

    return widgets;
  }

  static List<pw.Widget> _metalCompleteReportWidgets({
    required String metalTitle,
    required SalesReportSnapshot snapshot,
    required SalesReportExportIdentity identity,
  }) {
    final widgets = <pw.Widget>[
      _pdfHeader('$metalTitle Sales Report', snapshot.filter, identity),
      pw.SizedBox(height: 14),
      _pdfSection(
        'Metal Sales Ledger',
        const ['Metric', 'Value'],
        _metalSalesLedgerRows(snapshot, metalTitle),
      ),
    ];

    if (snapshot.items.isNotEmpty) {
      _addPdfSection(
        widgets,
        'Grade-wise Sales',
        const [
          'Grade',
          'Invoices',
          'Items',
          'Pcs',
          'Gross Wt',
          'Net Wt',
          'Making',
          'Sales',
        ],
        SalesReportExportFormatters.gradeRows(snapshot.items),
      );
    }

    if (snapshot.invoices.isNotEmpty) {
      _addPdfSection(
        widgets,
        'Invoice Ledger',
        const [
          'S.No',
          'Invoice',
          'Date/Time',
          'Status',
          'Customer',
          'Mobile',
          'Type',
          'Metal Weight',
          'Gross',
          'Discount',
          'Taxable',
          'GST',
          'Final',
          'Paid',
          'Due',
        ],
        _metalInvoiceLedgerRows(snapshot.invoices, snapshot.items),
      );
    }

    if (snapshot.items.isNotEmpty) {
      _addPdfSection(
        widgets,
        'Item Ledger',
        const [
          'S.No',
          'Invoice',
          'Date',
          'Customer',
          'Type',
          'Item',
          'HUID',
          'Purity',
          'Pcs',
          'Gross',
          'Less',
          'Net',
          'Rate',
          'Making',
          'Total',
        ],
        _metalItemLedgerRows(snapshot.items),
      );
    }

    return widgets;
  }

  static void _addPdfSection(
    List<pw.Widget> widgets,
    String title,
    List<String> headers,
    List<List<String>> rows,
  ) {
    widgets
      ..add(pw.SizedBox(height: 12))
      ..add(
        pw.NewPage(
          freeSpace: _sectionStartFreeSpace(
            columnCount: headers.length,
            rowCount: rows.isEmpty ? 1 : rows.length,
          ),
        ),
      )
      ..add(_pdfSection(title, headers, rows));
  }

  static void _addOptionalInvoiceSection(
    List<pw.Widget> widgets, {
    required String title,
    required List<SalesReportInvoiceRow> invoices,
    required List<String> headers,
    required List<List<String>> Function(List<SalesReportInvoiceRow>) rows,
  }) {
    if (invoices.isEmpty) return;
    _addPdfSection(widgets, title, headers, rows(invoices));
  }

  static pw.Widget _pdfSection(
    String title,
    List<String> headers,
    List<List<String>> rows,
  ) {
    final table = pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows.isEmpty ? [List.filled(headers.length, 'No records')] : rows,
      headerStyle: pw.TextStyle(
        fontSize: 8.6,
        fontWeight: pw.FontWeight.bold,
        color: _black,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8.2, color: _black),
      headerDecoration: const pw.BoxDecoration(color: _gold),
      oddRowDecoration: const pw.BoxDecoration(color: _softGold),
      border: pw.TableBorder.all(color: _black, width: 0.35),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    );
    final width = _sectionTableWidth(headers.length);
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _paper,
        border: pw.Border.all(color: _black, width: 0.35),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11.4,
              color: _black,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            color: _white,
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: width == null
                  ? table
                  : pw.SizedBox(width: width, child: table),
            ),
          ),
        ],
      ),
    );
  }

  static double? _sectionTableWidth(int columnCount) {
    if (columnCount <= 2) return 430;
    if (columnCount <= 6) return 620;
    if (columnCount <= 8) return 760;
    return null;
  }

  static double _sectionStartFreeSpace({
    required int columnCount,
    required int rowCount,
  }) {
    final visibleRows = rowCount > 10 ? 10 : rowCount;
    final rowHeight = columnCount <= 2 ? 18.0 : 16.0;
    return 56 + (visibleRows + 1) * rowHeight;
  }

  static List<List<String>> _metalSalesLedgerRows(
    SalesReportSnapshot snapshot,
    String metalTitle,
  ) {
    final summary = snapshot.summary;
    final pieces = snapshot.metals.fold<int>(
      0,
      (sum, metal) => sum + metal.pieces,
    );
    final grossWeight = snapshot.metals.fold<double>(
      0,
      (sum, metal) => sum + metal.grossWeight,
    );
    return [
      ['Metal', metalTitle],
      ['Invoices', '${summary.invoiceCount}'],
      ['GST Invoices', '${summary.gstInvoiceCount}'],
      ['Non-GST Invoices', '${summary.nonGstInvoiceCount}'],
      ['Pieces', '$pieces'],
      ['Gross Weight', SalesReportExportFormatters.weight(grossWeight)],
      [
        'Net Weight',
        SalesReportExportFormatters.totalNetWeightWithBreakdown(snapshot.items),
      ],
      ['Making', SalesReportExportFormatters.money(summary.makingAmount)],
      ['Sales Value', SalesReportExportFormatters.money(summary.grossAmount)],
      ['Taxable', SalesReportExportFormatters.money(summary.taxableAmount)],
      ['GST', SalesReportExportFormatters.money(summary.gstAmount)],
      ['Final Amount', SalesReportExportFormatters.money(summary.finalAmount)],
    ];
  }

  static List<List<String>> _metalInvoiceLedgerRows(
    List<SalesReportInvoiceRow> invoices,
    List<SalesReportItemRow> items,
  ) {
    final weights = _metalWeightByBill(items);
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.dateTime(invoices[index].billDate),
          invoices[index].paymentStatus,
          invoices[index].customerName,
          invoices[index].mobile,
          invoices[index].isGst ? 'GST' : 'NON-GST',
          weights[invoices[index].billId] ?? '',
          SalesReportExportFormatters.money(invoices[index].grossAmount),
          SalesReportExportFormatters.money(invoices[index].discountAmount),
          SalesReportExportFormatters.money(invoices[index].taxableAmount),
          SalesReportExportFormatters.money(invoices[index].gstAmount),
          SalesReportExportFormatters.money(invoices[index].finalAmount),
          SalesReportExportFormatters.money(invoices[index].paidAmount),
          SalesReportExportFormatters.money(invoices[index].dueAmount),
        ],
      [
        'TOTAL',
        '${invoices.length} invoices',
        '',
        '',
        '',
        '',
        '',
        SalesReportExportFormatters.totalNetWeightWithBreakdown(items),
        _moneyTotal(invoices, (row) => row.grossAmount),
        _moneyTotal(invoices, (row) => row.discountAmount),
        _moneyTotal(invoices, (row) => row.taxableAmount),
        _moneyTotal(invoices, (row) => row.gstAmount),
        _moneyTotal(invoices, (row) => row.finalAmount),
        _moneyTotal(invoices, (row) => row.paidAmount),
        _moneyTotal(invoices, (row) => row.dueAmount),
      ],
    ];
  }

  static List<List<String>> _metalItemLedgerRows(
    List<SalesReportItemRow> items,
  ) {
    return [
      for (var index = 0; index < items.length; index++)
        [
          '${index + 1}',
          items[index].billNo,
          SalesReportExportFormatters.date(items[index].billDate),
          items[index].customerName,
          items[index].isGst ? 'GST' : 'NON-GST',
          items[index].itemName,
          items[index].huid.isEmpty ? 'Not linked' : items[index].huid,
          items[index].purity,
          '${items[index].quantity}',
          SalesReportExportFormatters.weight(items[index].grossWeight),
          SalesReportExportFormatters.weight(items[index].lessWeight),
          SalesReportExportFormatters.weight(items[index].netWeight),
          SalesReportExportFormatters.money(items[index].rate),
          SalesReportExportFormatters.money(items[index].makingCharge),
          SalesReportExportFormatters.money(items[index].itemTotal),
        ],
      [
        'TOTAL',
        '${items.length} items',
        '',
        '',
        '',
        '',
        '',
        '',
        '${items.fold(0, (sum, item) => sum + item.quantity)}',
        SalesReportExportFormatters.weight(
          items.fold(0, (sum, item) => sum + item.grossWeight),
        ),
        SalesReportExportFormatters.weight(
          items.fold(0, (sum, item) => sum + item.lessWeight),
        ),
        SalesReportExportFormatters.totalNetWeightWithBreakdown(items),
        '',
        SalesReportExportFormatters.money(
          items.fold(0, (sum, item) => sum + item.makingCharge),
        ),
        SalesReportExportFormatters.money(
          items.fold(0, (sum, item) => sum + item.itemTotal),
        ),
      ],
    ];
  }

  static Map<int, String> _metalWeightByBill(List<SalesReportItemRow> items) {
    final totals = <int, Map<String, double>>{};
    for (final item in items) {
      final billTotals = totals.putIfAbsent(item.billId, () => {});
      final metal = item.metalType.trim().isEmpty ? 'Metal' : item.metalType;
      billTotals[metal] = (billTotals[metal] ?? 0) + item.netWeight;
    }
    return {
      for (final entry in totals.entries)
        entry.key: (entry.value.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)))
            .map((weight) {
          return '${weight.key} ${SalesReportExportFormatters.weight(weight.value)}';
        }).join(' | '),
    };
  }

  static List<List<String>> _invoiceIdentityRegisterRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.dateTime(invoices[index].billDate),
          invoices[index].paymentStatus,
          invoices[index].customerName,
          invoices[index].mobile,
          invoices[index].customerGstin,
          invoices[index].businessType,
          invoices[index].placeOfSupply,
          invoices[index].billStatus,
        ],
      [
        'TOTAL',
        '${invoices.length} invoices',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
    ];
  }

  static List<List<String>> _invoiceTaxRegisterRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.money(invoices[index].grossAmount),
          SalesReportExportFormatters.money(invoices[index].discountAmount),
          SalesReportExportFormatters.money(invoices[index].taxableAmount),
          SalesReportExportFormatters.money(_gstBreakup(invoices[index]).cgst),
          SalesReportExportFormatters.money(_gstBreakup(invoices[index]).sgst),
          SalesReportExportFormatters.money(_gstBreakup(invoices[index]).igst),
          SalesReportExportFormatters.money(invoices[index].roundOffAmount),
          SalesReportExportFormatters.money(invoices[index].finalAmount),
        ],
      [
        'TOTAL',
        '',
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + row.grossAmount),
        ),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + row.discountAmount),
        ),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + row.taxableAmount),
        ),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + _gstBreakup(row).cgst),
        ),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + _gstBreakup(row).sgst),
        ),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + _gstBreakup(row).igst),
        ),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + row.roundOffAmount),
        ),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + row.finalAmount),
        ),
      ],
    ];
  }

  static List<List<String>> _paymentCollectionRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.dateTime(invoices[index].billDate),
          invoices[index].customerName,
          invoices[index].mobile,
          SalesReportExportFormatters.money(invoices[index].finalAmount),
          SalesReportExportFormatters.money(invoices[index].cashAmount),
          SalesReportExportFormatters.money(invoices[index].upiAmount),
          SalesReportExportFormatters.money(invoices[index].cardAmount),
          SalesReportExportFormatters.money(invoices[index].bankAmount),
          SalesReportExportFormatters.money(invoices[index].paidAmount),
          SalesReportExportFormatters.money(invoices[index].dueAmount),
          invoices[index].paymentStatus,
        ],
      [
        'TOTAL',
        '',
        '',
        '',
        '',
        _moneyTotal(invoices, (row) => row.finalAmount),
        _moneyTotal(invoices, (row) => row.cashAmount),
        _moneyTotal(invoices, (row) => row.upiAmount),
        _moneyTotal(invoices, (row) => row.cardAmount),
        _moneyTotal(invoices, (row) => row.bankAmount),
        _moneyTotal(invoices, (row) => row.paidAmount),
        _moneyTotal(invoices, (row) => row.dueAmount),
        '',
      ],
    ];
  }

  static List<List<String>> _paymentAdjustmentRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.money(invoices[index].advanceAmount),
          SalesReportExportFormatters.money(invoices[index].tradeInDeduction),
          SalesReportExportFormatters.money(
            invoices[index].returnCreditNoteAmount,
          ),
          invoices[index].billStatus,
        ],
      [
        'TOTAL',
        '',
        _moneyTotal(invoices, (row) => row.advanceAmount),
        _moneyTotal(invoices, (row) => row.tradeInDeduction),
        _moneyTotal(invoices, (row) => row.returnCreditNoteAmount),
        '',
      ],
    ];
  }

  static List<List<String>> _customerSalesRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    final accumulators = <String, _PdfCustomerSalesAccumulator>{};
    for (final invoice in invoices) {
      final name = invoice.customerName.trim().isEmpty
          ? 'Walk-in Customer'
          : invoice.customerName.trim();
      final key = '${name.toUpperCase()}|${invoice.mobile.trim()}';
      final acc = accumulators.putIfAbsent(
        key,
        () => _PdfCustomerSalesAccumulator(
          customerName: name,
          mobile: invoice.mobile,
        ),
      );
      acc.invoiceIds.add(invoice.billId);
      acc.businessTypes.add(invoice.businessType);
      acc.gstins.add(invoice.customerGstin);
      acc.grossAmount += invoice.grossAmount;
      acc.discountAmount += invoice.discountAmount;
      acc.taxableAmount += invoice.taxableAmount;
      acc.gstAmount += invoice.gstAmount;
      acc.finalAmount += invoice.finalAmount;
      acc.paidAmount += invoice.paidAmount;
      acc.dueAmount += invoice.dueAmount;
      acc.advanceAmount += invoice.advanceAmount;
      acc.tradeInDeduction += invoice.tradeInDeduction;
    }
    final rows = accumulators.values.map((acc) => acc.toRow()).toList()
      ..sort((a, b) {
        final amountCompare = b.finalAmount.compareTo(a.finalAmount);
        if (amountCompare != 0) return amountCompare;
        return a.customerName.compareTo(b.customerName);
      });
    return [
      for (var index = 0; index < rows.length; index++)
        [
          '${index + 1}',
          rows[index].customerName,
          rows[index].mobile,
          rows[index].gstin,
          rows[index].businessType,
          '${rows[index].invoiceCount}',
          SalesReportExportFormatters.money(rows[index].grossAmount),
          SalesReportExportFormatters.money(rows[index].discountAmount),
          SalesReportExportFormatters.money(rows[index].taxableAmount),
          SalesReportExportFormatters.money(rows[index].gstAmount),
          SalesReportExportFormatters.money(rows[index].finalAmount),
          SalesReportExportFormatters.money(rows[index].paidAmount),
          SalesReportExportFormatters.money(rows[index].dueAmount),
          SalesReportExportFormatters.money(rows[index].advanceAmount),
          SalesReportExportFormatters.money(rows[index].tradeInDeduction),
        ],
      [
        'TOTAL',
        '',
        '',
        '',
        '',
        '${rows.fold(0, (sum, row) => sum + row.invoiceCount)}',
        _customerMoneyTotal(rows, (row) => row.grossAmount),
        _customerMoneyTotal(rows, (row) => row.discountAmount),
        _customerMoneyTotal(rows, (row) => row.taxableAmount),
        _customerMoneyTotal(rows, (row) => row.gstAmount),
        _customerMoneyTotal(rows, (row) => row.finalAmount),
        _customerMoneyTotal(rows, (row) => row.paidAmount),
        _customerMoneyTotal(rows, (row) => row.dueAmount),
        _customerMoneyTotal(rows, (row) => row.advanceAmount),
        _customerMoneyTotal(rows, (row) => row.tradeInDeduction),
      ],
    ];
  }

  static List<List<String>> _recordedGstRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.dateTime(invoices[index].billDate),
          invoices[index].customerName,
          SalesReportExportFormatters.money(invoices[index].taxableAmount),
          SalesReportExportFormatters.money(_gstBreakup(invoices[index]).cgst),
          SalesReportExportFormatters.money(_gstBreakup(invoices[index]).sgst),
          SalesReportExportFormatters.money(_gstBreakup(invoices[index]).igst),
          SalesReportExportFormatters.money(invoices[index].gstAmount),
          SalesReportExportFormatters.money(invoices[index].finalAmount),
        ],
      [
        'TOTAL',
        '',
        '',
        '',
        _moneyTotal(invoices, (row) => row.taxableAmount),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + _gstBreakup(row).cgst),
        ),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + _gstBreakup(row).sgst),
        ),
        SalesReportExportFormatters.money(
          invoices.fold(0, (sum, row) => sum + _gstBreakup(row).igst),
        ),
        _moneyTotal(invoices, (row) => row.gstAmount),
        _moneyTotal(invoices, (row) => row.finalAmount),
      ],
    ];
  }

  static List<List<String>> _nonGstEstimateRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.dateTime(invoices[index].billDate),
          invoices[index].customerName,
          SalesReportExportFormatters.money(invoices[index].taxableAmount),
          SalesReportExportFormatters.money(
            _roundMoney(invoices[index].taxableAmount * 0.03),
          ),
          SalesReportExportFormatters.money(
            invoices[index].taxableAmount +
                _roundMoney(invoices[index].taxableAmount * 0.03),
          ),
        ],
      [
        'TOTAL',
        '',
        '',
        '',
        _moneyTotal(invoices, (row) => row.taxableAmount),
        SalesReportExportFormatters.money(
          invoices.fold(
            0,
            (sum, row) => sum + _roundMoney(row.taxableAmount * 0.03),
          ),
        ),
        SalesReportExportFormatters.money(
          invoices.fold(
            0,
            (sum, row) =>
                sum + row.taxableAmount + _roundMoney(row.taxableAmount * 0.03),
          ),
        ),
      ],
    ];
  }

  static List<List<String>> _advanceRegisterRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.dateTime(invoices[index].billDate),
          invoices[index].customerName,
          invoices[index].mobile,
          SalesReportExportFormatters.money(invoices[index].finalAmount),
          SalesReportExportFormatters.money(invoices[index].advanceAmount),
          SalesReportExportFormatters.money(invoices[index].cashAmount),
          SalesReportExportFormatters.money(invoices[index].upiAmount),
          SalesReportExportFormatters.money(invoices[index].cardAmount),
          SalesReportExportFormatters.money(invoices[index].bankAmount),
          SalesReportExportFormatters.money(invoices[index].paidAmount),
          SalesReportExportFormatters.money(invoices[index].dueAmount),
          invoices[index].paymentStatus,
          invoices[index].billStatus,
        ],
      [
        'TOTAL',
        '',
        '',
        '',
        '',
        _moneyTotal(invoices, (row) => row.finalAmount),
        _moneyTotal(invoices, (row) => row.advanceAmount),
        _moneyTotal(invoices, (row) => row.cashAmount),
        _moneyTotal(invoices, (row) => row.upiAmount),
        _moneyTotal(invoices, (row) => row.cardAmount),
        _moneyTotal(invoices, (row) => row.bankAmount),
        _moneyTotal(invoices, (row) => row.paidAmount),
        _moneyTotal(invoices, (row) => row.dueAmount),
        '',
        '',
      ],
    ];
  }

  static List<List<String>> _dueRegisterRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.dateTime(invoices[index].billDate),
          invoices[index].customerName,
          invoices[index].mobile,
          invoices[index].customerGstin,
          invoices[index].businessType,
          invoices[index].placeOfSupply,
          SalesReportExportFormatters.money(invoices[index].finalAmount),
          SalesReportExportFormatters.money(invoices[index].advanceAmount),
          SalesReportExportFormatters.money(invoices[index].paidAmount),
          SalesReportExportFormatters.money(invoices[index].dueAmount),
          SalesReportExportFormatters.money(invoices[index].cashAmount),
          SalesReportExportFormatters.money(
            invoices[index].upiAmount +
                invoices[index].cardAmount +
                invoices[index].bankAmount,
          ),
          invoices[index].billStatus,
        ],
      [
        'TOTAL',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        _moneyTotal(invoices, (row) => row.finalAmount),
        _moneyTotal(invoices, (row) => row.advanceAmount),
        _moneyTotal(invoices, (row) => row.paidAmount),
        _moneyTotal(invoices, (row) => row.dueAmount),
        _moneyTotal(invoices, (row) => row.cashAmount),
        SalesReportExportFormatters.money(
          invoices.fold(
            0,
            (sum, row) => sum + row.upiAmount + row.cardAmount + row.bankAmount,
          ),
        ),
        '',
      ],
    ];
  }

  static List<List<String>> _oldGoldRegisterRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.dateTime(invoices[index].billDate),
          invoices[index].customerName,
          invoices[index].mobile,
          SalesReportExportFormatters.money(invoices[index].grossAmount),
          SalesReportExportFormatters.money(invoices[index].tradeInDeduction),
          SalesReportExportFormatters.money(invoices[index].finalAmount),
          SalesReportExportFormatters.money(invoices[index].cashAmount),
          SalesReportExportFormatters.money(invoices[index].upiAmount),
          SalesReportExportFormatters.money(invoices[index].cardAmount),
          SalesReportExportFormatters.money(invoices[index].paidAmount),
          SalesReportExportFormatters.money(invoices[index].dueAmount),
          invoices[index].billStatus,
        ],
      [
        'TOTAL',
        '',
        '',
        '',
        '',
        _moneyTotal(invoices, (row) => row.grossAmount),
        _moneyTotal(invoices, (row) => row.tradeInDeduction),
        _moneyTotal(invoices, (row) => row.finalAmount),
        _moneyTotal(invoices, (row) => row.cashAmount),
        _moneyTotal(invoices, (row) => row.upiAmount),
        _moneyTotal(invoices, (row) => row.cardAmount),
        _moneyTotal(invoices, (row) => row.paidAmount),
        _moneyTotal(invoices, (row) => row.dueAmount),
        '',
      ],
    ];
  }

  static List<List<String>> _returnCreditRegisterRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.dateTime(invoices[index].billDate),
          invoices[index].customerName,
          invoices[index].mobile,
          SalesReportExportFormatters.money(invoices[index].finalAmount),
          SalesReportExportFormatters.money(
            invoices[index].returnCreditNoteAmount,
          ),
          SalesReportExportFormatters.money(invoices[index].paidAmount),
          SalesReportExportFormatters.money(invoices[index].dueAmount),
          invoices[index].paymentStatus,
          invoices[index].billStatus,
        ],
      [
        'TOTAL',
        '',
        '',
        '',
        '',
        _moneyTotal(invoices, (row) => row.finalAmount),
        _moneyTotal(invoices, (row) => row.returnCreditNoteAmount),
        _moneyTotal(invoices, (row) => row.paidAmount),
        _moneyTotal(invoices, (row) => row.dueAmount),
        '',
        '',
      ],
    ];
  }

  static List<List<String>> _itemIdentityRows(List<SalesReportItemRow> items) {
    return [
      for (var index = 0; index < items.length; index++)
        [
          '${index + 1}',
          items[index].billNo,
          SalesReportExportFormatters.date(items[index].billDate),
          items[index].customerName,
          items[index].isGst ? 'GST' : 'NON-GST',
          items[index].metalType,
          items[index].itemName,
          items[index].huid.isEmpty ? 'Not linked' : items[index].huid,
          items[index].purity,
          '${items[index].quantity}',
        ],
      [
        'TOTAL',
        '${items.length} items',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '${items.fold(0, (sum, item) => sum + item.quantity)}',
      ],
    ];
  }

  static List<List<String>> _itemAmountRows(List<SalesReportItemRow> items) {
    return [
      for (var index = 0; index < items.length; index++)
        [
          '${index + 1}',
          items[index].billNo,
          items[index].metalType,
          items[index].itemName,
          SalesReportExportFormatters.weight(items[index].grossWeight),
          SalesReportExportFormatters.weight(items[index].lessWeight),
          SalesReportExportFormatters.weight(items[index].netWeight),
          SalesReportExportFormatters.money(items[index].rate),
          SalesReportExportFormatters.money(items[index].makingCharge),
          SalesReportExportFormatters.money(items[index].itemTotal),
        ],
      [
        'TOTAL',
        '',
        '',
        '',
        SalesReportExportFormatters.weight(
          items.fold(0, (sum, item) => sum + item.grossWeight),
        ),
        SalesReportExportFormatters.weight(
          items.fold(0, (sum, item) => sum + item.lessWeight),
        ),
        SalesReportExportFormatters.totalNetWeightWithBreakdown(items),
        '',
        SalesReportExportFormatters.money(
          items.fold(0, (sum, item) => sum + item.makingCharge),
        ),
        SalesReportExportFormatters.money(
          items.fold(0, (sum, item) => sum + item.itemTotal),
        ),
      ],
    ];
  }

  static List<List<String>> _gradeItemRows(List<SalesReportItemRow> items) {
    return [
      for (var index = 0; index < items.length; index++)
        [
          '${index + 1}',
          items[index].billNo,
          items[index].customerName,
          items[index].itemName,
          items[index].huid.isEmpty ? 'Not linked' : items[index].huid,
          items[index].purity,
          '${items[index].quantity}',
          SalesReportExportFormatters.weight(items[index].grossWeight),
          SalesReportExportFormatters.weight(items[index].netWeight),
          SalesReportExportFormatters.money(items[index].rate),
          SalesReportExportFormatters.money(items[index].itemTotal),
        ],
      [
        'TOTAL',
        '',
        '',
        '',
        '',
        '',
        '${items.fold(0, (sum, item) => sum + item.quantity)}',
        SalesReportExportFormatters.weight(
          items.fold(0, (sum, item) => sum + item.grossWeight),
        ),
        SalesReportExportFormatters.weight(
          items.fold(0, (sum, item) => sum + item.netWeight),
        ),
        '',
        SalesReportExportFormatters.money(
          items.fold(0, (sum, item) => sum + item.itemTotal),
        ),
      ],
    ];
  }

  static List<List<String>> _hsnGstRows(SalesReportSnapshot snapshot) {
    final invoicesById = {
      for (final invoice in snapshot.invoices) invoice.billId: invoice,
    };
    final accumulators = <String, _PdfHsnGstAccumulator>{};
    for (final item in snapshot.items) {
      final invoice = invoicesById[item.billId];
      if (invoice == null || !invoice.isGst) continue;
      final hsn =
          item.hsnCode.trim().isEmpty ? 'UNMAPPED' : item.hsnCode.trim();
      final taxableBase = _taxableBaseFor(invoice);
      final ratio = _allocationRatio(
        scopedGross: item.itemTotal,
        invoiceGross: invoice.grossAmount,
      );
      final taxable = taxableBase * ratio;
      final split = _gstBreakup(invoice);
      final cgst = split.cgst * ratio;
      final sgst = split.sgst * ratio;
      final igst = split.igst * ratio;
      final gst = cgst + sgst + igst;
      final rate = taxable.abs() <= 0.005 ? 0.0 : (gst / taxable) * 100;
      final key = '$hsn|${rate.toStringAsFixed(2)}';
      final acc = accumulators.putIfAbsent(
        key,
        () => _PdfHsnGstAccumulator(hsnCode: hsn, gstRate: rate),
      );
      acc.invoiceIds.add(invoice.billId);
      acc.lineItemCount++;
      acc.pieces += item.quantity;
      acc.taxableAmount += taxable;
      acc.cgstAmount += cgst;
      acc.sgstAmount += sgst;
      acc.igstAmount += igst;
      acc.gstAmount += gst;
      acc.invoiceAmount += taxable + gst + (invoice.roundOffAmount * ratio);
    }
    final rows = accumulators.values.toList()
      ..sort((a, b) {
        final hsnCompare = a.hsnCode.compareTo(b.hsnCode);
        if (hsnCompare != 0) return hsnCompare;
        return a.gstRate.compareTo(b.gstRate);
      });
    return [
      for (var index = 0; index < rows.length; index++)
        [
          '${index + 1}',
          rows[index].hsnCode,
          '${rows[index].gstRate.toStringAsFixed(2)}%',
          '${rows[index].invoiceIds.length}',
          '${rows[index].lineItemCount}',
          '${rows[index].pieces}',
          SalesReportExportFormatters.money(rows[index].taxableAmount),
          SalesReportExportFormatters.money(rows[index].cgstAmount),
          SalesReportExportFormatters.money(rows[index].sgstAmount),
          SalesReportExportFormatters.money(rows[index].igstAmount),
          SalesReportExportFormatters.money(rows[index].gstAmount),
          SalesReportExportFormatters.money(rows[index].invoiceAmount),
        ],
      [
        'TOTAL',
        '',
        '',
        '${rows.fold(0, (sum, row) => sum + row.invoiceIds.length)}',
        '${rows.fold(0, (sum, row) => sum + row.lineItemCount)}',
        '${rows.fold(0, (sum, row) => sum + row.pieces)}',
        _hsnMoneyTotal(rows, (row) => row.taxableAmount),
        _hsnMoneyTotal(rows, (row) => row.cgstAmount),
        _hsnMoneyTotal(rows, (row) => row.sgstAmount),
        _hsnMoneyTotal(rows, (row) => row.igstAmount),
        _hsnMoneyTotal(rows, (row) => row.gstAmount),
        _hsnMoneyTotal(rows, (row) => row.invoiceAmount),
      ],
    ];
  }

  static List<List<String>> _metalGradeRows(List<SalesReportItemRow> items) {
    final accumulators = <String, _PdfMetalGradeAccumulator>{};
    for (final item in items) {
      final metal = item.metalType.trim().isEmpty ? 'Unmapped' : item.metalType;
      final purity = item.purity.trim().isEmpty ? 'Unmapped' : item.purity;
      final key = '${metal.toUpperCase()}|${purity.toUpperCase()}';
      final acc = accumulators.putIfAbsent(
        key,
        () => _PdfMetalGradeAccumulator(metalType: metal, purity: purity),
      );
      acc.invoiceIds.add(item.billId);
      acc.lineItemCount++;
      acc.pieces += item.quantity;
      acc.grossWeight += item.grossWeight;
      acc.netWeight += item.netWeight;
      acc.itemAmount += item.itemTotal;
      acc.makingAmount += item.makingCharge;
    }
    final rows = accumulators.values.toList()
      ..sort((a, b) {
        final metalCompare = a.metalType.compareTo(b.metalType);
        if (metalCompare != 0) return metalCompare;
        return a.purity.compareTo(b.purity);
      });
    return [
      for (var index = 0; index < rows.length; index++)
        [
          '${index + 1}',
          rows[index].metalType,
          rows[index].purity,
          '${rows[index].invoiceIds.length}',
          '${rows[index].lineItemCount}',
          '${rows[index].pieces}',
          SalesReportExportFormatters.weight(rows[index].grossWeight),
          SalesReportExportFormatters.weight(rows[index].netWeight),
          SalesReportExportFormatters.money(rows[index].itemAmount),
          SalesReportExportFormatters.money(rows[index].makingAmount),
        ],
      [
        'TOTAL',
        '',
        '',
        '${rows.fold(0, (sum, row) => sum + row.invoiceIds.length)}',
        '${rows.fold(0, (sum, row) => sum + row.lineItemCount)}',
        '${rows.fold(0, (sum, row) => sum + row.pieces)}',
        SalesReportExportFormatters.weight(
          rows.fold(0, (sum, row) => sum + row.grossWeight),
        ),
        SalesReportExportFormatters.weight(
          rows.fold(0, (sum, row) => sum + row.netWeight),
        ),
        _metalGradeMoneyTotal(rows, (row) => row.itemAmount),
        _metalGradeMoneyTotal(rows, (row) => row.makingAmount),
      ],
    ];
  }

  static String _moneyTotal(
    List<SalesReportInvoiceRow> rows,
    double Function(SalesReportInvoiceRow row) selector,
  ) {
    return SalesReportExportFormatters.money(
      rows.fold<double>(0, (sum, row) => sum + selector(row)),
    );
  }

  static String _customerMoneyTotal(
    List<_PdfCustomerSalesRow> rows,
    double Function(_PdfCustomerSalesRow row) selector,
  ) {
    return SalesReportExportFormatters.money(
      rows.fold<double>(0, (sum, row) => sum + selector(row)),
    );
  }

  static String _hsnMoneyTotal(
    List<_PdfHsnGstAccumulator> rows,
    double Function(_PdfHsnGstAccumulator row) selector,
  ) {
    return SalesReportExportFormatters.money(
      rows.fold<double>(0, (sum, row) => sum + selector(row)),
    );
  }

  static String _metalGradeMoneyTotal(
    List<_PdfMetalGradeAccumulator> rows,
    double Function(_PdfMetalGradeAccumulator row) selector,
  ) {
    return SalesReportExportFormatters.money(
      rows.fold<double>(0, (sum, row) => sum + selector(row)),
    );
  }

  static double _taxableBaseFor(SalesReportInvoiceRow invoice) {
    if (invoice.taxableAmount > 0.005) return invoice.taxableAmount;
    final discountedGross = invoice.grossAmount - invoice.discountAmount;
    if (discountedGross > 0.005) return discountedGross;
    if (invoice.gstAmount <= 0.005) return invoice.finalAmount;
    return invoice.grossAmount;
  }

  static double _allocationRatio({
    required double scopedGross,
    required double invoiceGross,
  }) {
    if (scopedGross <= 0.005) return 0;
    if (invoiceGross.abs() <= 0.005) return 1;
    return scopedGross / invoiceGross;
  }

  static _PdfGstBreakup _gstBreakup(SalesReportInvoiceRow invoice) {
    final total = _roundMoney(invoice.gstAmount);
    if (total.abs() <= 0.005) {
      return const _PdfGstBreakup(cgst: 0, sgst: 0, igst: 0);
    }
    final storedIgst = _roundMoney(invoice.igstAmount);
    if (storedIgst.abs() > 0.005) {
      return _PdfGstBreakup(cgst: 0, sgst: 0, igst: total);
    }
    var cgst = _roundMoney(invoice.cgstAmount);
    var sgst = _roundMoney(invoice.sgstAmount);
    if (cgst.abs() <= 0.005 && sgst.abs() <= 0.005) {
      cgst = _roundMoney(total / 2);
    }
    sgst = _roundMoney(total - cgst);
    return _PdfGstBreakup(
      cgst: cgst,
      sgst: sgst,
      igst: 0,
    );
  }

  static double _roundMoney(double value) => (value * 100).round() / 100;
}

class _PdfGstBreakup {
  final double cgst;
  final double sgst;
  final double igst;

  const _PdfGstBreakup({
    required this.cgst,
    required this.sgst,
    required this.igst,
  });
}

class _PdfCustomerSalesAccumulator {
  final String customerName;
  final String mobile;
  final Set<int> invoiceIds = <int>{};
  final Set<String> businessTypes = <String>{};
  final Set<String> gstins = <String>{};
  double grossAmount = 0;
  double discountAmount = 0;
  double taxableAmount = 0;
  double gstAmount = 0;
  double finalAmount = 0;
  double paidAmount = 0;
  double dueAmount = 0;
  double advanceAmount = 0;
  double tradeInDeduction = 0;

  _PdfCustomerSalesAccumulator({
    required this.customerName,
    required this.mobile,
  });

  _PdfCustomerSalesRow toRow() {
    final normalizedBusinessTypes = businessTypes
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    final normalizedGstins = gstins
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    return _PdfCustomerSalesRow(
      customerName: customerName,
      mobile: mobile,
      gstin: normalizedGstins.isEmpty
          ? ''
          : normalizedGstins.length == 1
              ? normalizedGstins.first
              : 'MULTIPLE',
      businessType: normalizedBusinessTypes.length == 1
          ? normalizedBusinessTypes.first
          : 'MIXED',
      invoiceCount: invoiceIds.length,
      grossAmount: grossAmount,
      discountAmount: discountAmount,
      taxableAmount: taxableAmount,
      gstAmount: gstAmount,
      finalAmount: finalAmount,
      paidAmount: paidAmount,
      dueAmount: dueAmount,
      advanceAmount: advanceAmount,
      tradeInDeduction: tradeInDeduction,
    );
  }
}

class _PdfCustomerSalesRow {
  final String customerName;
  final String mobile;
  final String gstin;
  final String businessType;
  final int invoiceCount;
  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double gstAmount;
  final double finalAmount;
  final double paidAmount;
  final double dueAmount;
  final double advanceAmount;
  final double tradeInDeduction;

  const _PdfCustomerSalesRow({
    required this.customerName,
    required this.mobile,
    required this.gstin,
    required this.businessType,
    required this.invoiceCount,
    required this.grossAmount,
    required this.discountAmount,
    required this.taxableAmount,
    required this.gstAmount,
    required this.finalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.advanceAmount,
    required this.tradeInDeduction,
  });
}

class _PdfHsnGstAccumulator {
  final String hsnCode;
  final double gstRate;
  final Set<int> invoiceIds = <int>{};
  int lineItemCount = 0;
  int pieces = 0;
  double taxableAmount = 0;
  double cgstAmount = 0;
  double sgstAmount = 0;
  double igstAmount = 0;
  double gstAmount = 0;
  double invoiceAmount = 0;

  _PdfHsnGstAccumulator({
    required this.hsnCode,
    required this.gstRate,
  });
}

class _PdfMetalGradeAccumulator {
  final String metalType;
  final String purity;
  final Set<int> invoiceIds = <int>{};
  int lineItemCount = 0;
  int pieces = 0;
  double grossWeight = 0;
  double netWeight = 0;
  double itemAmount = 0;
  double makingAmount = 0;

  _PdfMetalGradeAccumulator({
    required this.metalType,
    required this.purity,
  });
}
