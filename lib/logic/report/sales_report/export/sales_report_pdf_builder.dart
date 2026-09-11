import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/pdf/lotus_pdf_theme.dart';
import '../../../../models/reports/sales_report/sales_report_models.dart';
import 'sales_report_export_formatters.dart';

part 'sales_report_pdf_models.dart';

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
          'Sales Overview - ${SalesReportExportFormatters.periodLabel(snapshot.filter)}',
      author: identity.shopName,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: await LotusPdfTheme.reportTheme(),
        footer: _pdfFooter,
        build: (_) => [
          _pdfHeader('Sales Overview', snapshot.filter, identity),
          pw.SizedBox(height: 16),
          _pdfSection(
            'Sales Overview',
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
                    invoice.isGst ? 'GST BILL' : 'NORMAL',
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
    final normalInvoices = snapshot.invoices
        .where((invoice) => !invoice.isGst)
        .toList(growable: false);
    final gstInvoices = snapshot.invoices
        .where((invoice) => invoice.isGst)
        .toList(growable: false);

    final widgets = <pw.Widget>[
      _pdfHeader(reportTitle, snapshot.filter, identity),
      pw.SizedBox(height: 14),
      _pdfSection(
        'Sales Overview',
        const ['Metric', 'Value'],
        _executiveSalesOverviewRows(snapshot),
      ),
    ];

    if (snapshot.metals.isNotEmpty) {
      _addPdfSection(
        widgets,
        'Metal Sales',
        [
          'Metal',
          'Bills With Metal',
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

    if (normalInvoices.isNotEmpty) {
      _addPdfSection(
        widgets,
        'Normal Sales Invoice Ledger',
        const [
          'S.No',
          'Bill No',
          'Date',
          'Customer',
          'Mobile',
          'Metal',
          'Sale Amount',
          'Discount',
          'Net Total',
          'Due',
          'Status',
        ],
        _normalSalesInvoiceLedgerRows(normalInvoices),
      );
    }

    if (gstInvoices.isNotEmpty) {
      _addPdfSection(
        widgets,
        'GST Sales Invoice Ledger',
        const [
          'S.No',
          'Bill No',
          'Date',
          'Customer',
          'GSTIN',
          'Taxable Sales',
          'GST',
          'Invoice Total',
          'Due',
          'Status',
        ],
        _gstSalesInvoiceLedgerRows(gstInvoices),
      );
    }

    if (snapshot.items.isNotEmpty) {
      _addPdfSection(
        widgets,
        'Sales Item Ledger',
        [
          'S.No',
          'Bill No',
          'Date',
          'Customer',
          'Metal',
          'Item',
          'Purity',
          'Pcs',
          'Gross Wt',
          'Net Wt',
          'Line Total',
        ],
        _salesItemLedgerRows(snapshot.items),
      );
      _addPdfSection(
        widgets,
        'Metal-wise Sales Ledger',
        const [
          'S.No',
          'Metal',
          'Bills With Metal',
          'Items',
          'Pcs',
          'Gross Wt',
          'Net Wt',
          'Making',
          'Sales',
        ],
        _metalWiseLedgerRows(snapshot.metals),
      );
    }

    _addOptionalInvoiceSection(
      widgets,
      title: 'Sales Advance Ledger',
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
      title: 'Due Sales Ledger',
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
      title: 'Old Gold Adjustment Ledger',
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
      title: 'Return and Reversal Ledger',
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

    final goldPurityRows = _goldPurityLedgerRows(snapshot.items);
    if (goldPurityRows.isNotEmpty) {
      _addPdfSection(
        widgets,
        'Gold Purity Ledger',
        const [
          'S.No',
          'Purity',
          'Bills With Purity',
          'Lines',
          'Pcs',
          'Gross Wt',
          'Net Wt',
          'Making',
          'Sales',
        ],
        goldPurityRows,
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

  static List<List<String>> _executiveSalesOverviewRows(
    SalesReportSnapshot snapshot,
  ) {
    final summary = snapshot.summary;
    final liability = snapshot.gstLiability;
    final returnCredit = snapshot.invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.returnCreditNoteAmount,
    );
    final rows = <List<String>>[
      [
        'Report Period',
        SalesReportExportFormatters.periodLabel(snapshot.filter),
      ],
      ['Total Invoices', '${summary.invoiceCount} bills'],
      ['Total Sales', SalesReportExportFormatters.money(summary.finalAmount)],
      [
        'Net Weight Sold',
        SalesReportExportFormatters.totalNetWeightWithBreakdown(snapshot.items),
      ],
    ];

    if (liability.nonGstInvoiceCount > 0) {
      rows.add([
        'Normal Bill Sales',
        '${SalesReportExportFormatters.money(liability.nonGstSalesAmount)} '
            '(${liability.nonGstInvoiceCount} bills)',
      ]);
    }
    if (liability.gstInvoiceCount > 0) {
      rows.add([
        'GST Bill Sales',
        '${SalesReportExportFormatters.money(liability.gstTaxableAmount)} '
            'before GST (${liability.gstInvoiceCount} bills)',
      ]);
    }
    if (liability.recordedGstAmount.abs() > 0.005) {
      rows.add([
        'GST Collected',
        SalesReportExportFormatters.money(liability.recordedGstAmount),
      ]);
    }
    if (liability.projectedGstAmount.abs() > 0.005) {
      rows.add([
        'Normal Bill GST Estimate',
        SalesReportExportFormatters.money(liability.projectedGstAmount),
      ]);
    }
    if (summary.dueAmount.abs() > 0.005) {
      rows.add([
        'Due Amount',
        SalesReportExportFormatters.money(summary.dueAmount),
      ]);
    }
    if (summary.advanceAmount.abs() > 0.005) {
      rows.add([
        'Advance Adjusted',
        SalesReportExportFormatters.money(summary.advanceAmount),
      ]);
    }
    if (returnCredit.abs() > 0.005) {
      rows.add([
        'Return/Reversal Credit',
        SalesReportExportFormatters.money(returnCredit),
      ]);
    }
    return rows;
  }

  static List<List<String>> _normalSalesInvoiceLedgerRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.date(invoices[index].billDate),
          invoices[index].customerName,
          invoices[index].mobile,
          invoices[index].metalMix,
          SalesReportExportFormatters.money(invoices[index].taxableAmount),
          SalesReportExportFormatters.money(invoices[index].discountAmount),
          SalesReportExportFormatters.money(invoices[index].finalAmount),
          SalesReportExportFormatters.money(invoices[index].dueAmount),
          invoices[index].billStatus,
        ],
      [
        'TOTAL',
        '${invoices.length} normal bills',
        '',
        '',
        '',
        '',
        _moneyTotal(invoices, (row) => row.taxableAmount),
        _moneyTotal(invoices, (row) => row.discountAmount),
        _moneyTotal(invoices, (row) => row.finalAmount),
        _moneyTotal(invoices, (row) => row.dueAmount),
        '',
      ],
    ];
  }

  static List<List<String>> _gstSalesInvoiceLedgerRows(
    List<SalesReportInvoiceRow> invoices,
  ) {
    return [
      for (var index = 0; index < invoices.length; index++)
        [
          '${index + 1}',
          invoices[index].billNo,
          SalesReportExportFormatters.date(invoices[index].billDate),
          invoices[index].customerName,
          invoices[index].customerGstin.trim().isEmpty
              ? 'Unregistered'
              : invoices[index].customerGstin,
          SalesReportExportFormatters.money(invoices[index].taxableAmount),
          SalesReportExportFormatters.money(invoices[index].gstAmount),
          SalesReportExportFormatters.money(invoices[index].finalAmount),
          SalesReportExportFormatters.money(invoices[index].dueAmount),
          invoices[index].billStatus,
        ],
      [
        'TOTAL',
        '${invoices.length} GST bills',
        '',
        '',
        '',
        _moneyTotal(invoices, (row) => row.taxableAmount),
        _moneyTotal(invoices, (row) => row.gstAmount),
        _moneyTotal(invoices, (row) => row.finalAmount),
        _moneyTotal(invoices, (row) => row.dueAmount),
        '',
      ],
    ];
  }

  static List<List<String>> _salesItemLedgerRows(
    List<SalesReportItemRow> items,
  ) {
    return [
      for (var index = 0; index < items.length; index++)
        [
          '${index + 1}',
          items[index].billNo,
          SalesReportExportFormatters.date(items[index].billDate),
          items[index].customerName,
          items[index].metalType,
          items[index].itemName,
          items[index].purity,
          '${items[index].quantity}',
          SalesReportExportFormatters.weight(items[index].grossWeight),
          SalesReportExportFormatters.weight(items[index].netWeight),
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
        '${items.fold(0, (sum, item) => sum + item.quantity)}',
        SalesReportExportFormatters.weight(
          items.fold(0, (sum, item) => sum + item.grossWeight),
        ),
        SalesReportExportFormatters.totalNetWeightWithBreakdown(items),
        SalesReportExportFormatters.money(
          items.fold(0, (sum, item) => sum + item.itemTotal),
        ),
      ],
    ];
  }

  static List<List<String>> _metalWiseLedgerRows(
    List<SalesReportMetalSummary> metals,
  ) {
    return [
      for (var index = 0; index < metals.length; index++)
        [
          '${index + 1}',
          metals[index].metalType,
          '${metals[index].invoiceCount}',
          '${metals[index].itemCount}',
          '${metals[index].pieces}',
          SalesReportExportFormatters.weight(metals[index].grossWeight),
          SalesReportExportFormatters.weight(metals[index].netWeight),
          SalesReportExportFormatters.money(metals[index].makingAmount),
          SalesReportExportFormatters.money(metals[index].salesAmount),
        ],
      [
        'TOTAL',
        '${metals.length} metals',
        'Unique bills in overview',
        '${metals.fold(0, (sum, metal) => sum + metal.itemCount)}',
        '${metals.fold(0, (sum, metal) => sum + metal.pieces)}',
        SalesReportExportFormatters.weight(
          metals.fold(0, (sum, metal) => sum + metal.grossWeight),
        ),
        SalesReportExportFormatters.weight(
          metals.fold(0, (sum, metal) => sum + metal.netWeight),
        ),
        SalesReportExportFormatters.money(
          metals.fold(0, (sum, metal) => sum + metal.makingAmount),
        ),
        SalesReportExportFormatters.money(
          metals.fold(0, (sum, metal) => sum + metal.salesAmount),
        ),
      ],
    ];
  }

  static List<List<String>> _goldPurityLedgerRows(
    List<SalesReportItemRow> items,
  ) {
    final goldItems = items.where(_isGoldItem).toList(growable: false);
    if (goldItems.isEmpty) return const [];

    final grouped = <String, List<SalesReportItemRow>>{};
    for (final item in goldItems) {
      final purity = item.purity.trim().isEmpty ? 'Unspecified' : item.purity;
      grouped.putIfAbsent(purity, () => []).add(item);
    }

    final purities = grouped.keys.toList()..sort();
    final rows = <List<String>>[
      for (var index = 0; index < purities.length; index++)
        _goldPurityRow(index + 1, purities[index], grouped[purities[index]]!),
    ];
    rows.add([
      'TOTAL',
      '${purities.length} purities',
      '${goldItems.map((item) => item.billId).toSet().length}',
      '${goldItems.length}',
      '${goldItems.fold(0, (sum, item) => sum + item.quantity)}',
      SalesReportExportFormatters.weight(
        goldItems.fold(0, (sum, item) => sum + item.grossWeight),
      ),
      SalesReportExportFormatters.weight(
        goldItems.fold(0, (sum, item) => sum + item.netWeight),
      ),
      SalesReportExportFormatters.money(
        goldItems.fold(0, (sum, item) => sum + item.makingCharge),
      ),
      SalesReportExportFormatters.money(
        goldItems.fold(0, (sum, item) => sum + item.itemTotal),
      ),
    ]);
    return rows;
  }

  static List<String> _goldPurityRow(
    int serial,
    String purity,
    List<SalesReportItemRow> items,
  ) {
    return [
      '$serial',
      purity,
      '${items.map((item) => item.billId).toSet().length}',
      '${items.length}',
      '${items.fold(0, (sum, item) => sum + item.quantity)}',
      SalesReportExportFormatters.weight(
        items.fold(0, (sum, item) => sum + item.grossWeight),
      ),
      SalesReportExportFormatters.weight(
        items.fold(0, (sum, item) => sum + item.netWeight),
      ),
      SalesReportExportFormatters.money(
        items.fold(0, (sum, item) => sum + item.makingCharge),
      ),
      SalesReportExportFormatters.money(
        items.fold(0, (sum, item) => sum + item.itemTotal),
      ),
    ];
  }

  static bool _isGoldItem(SalesReportItemRow item) {
    final metal = item.metalType.trim().toUpperCase();
    return metal == 'GOLD' || metal.contains('GOLD');
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
      ['GST Bills', '${summary.gstInvoiceCount}'],
      ['Normal Bills', '${summary.nonGstInvoiceCount}'],
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
          invoices[index].isGst ? 'GST BILL' : 'NORMAL',
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
          items[index].isGst ? 'GST BILL' : 'NORMAL',
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
          items[index].isGst ? 'GST BILL' : 'NORMAL',
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

  static String _moneyTotal(
    List<SalesReportInvoiceRow> rows,
    double Function(SalesReportInvoiceRow row) selector,
  ) {
    return SalesReportExportFormatters.money(
      rows.fold<double>(0, (sum, row) => sum + selector(row)),
    );
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
