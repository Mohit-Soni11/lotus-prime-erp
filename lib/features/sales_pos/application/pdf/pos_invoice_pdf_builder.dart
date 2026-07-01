import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../features/print_templates/domain/print_template_registry.dart';
import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';
import '../services/pos_invoice_scope_service.dart';
import 'pos_invoice_print_config.dart';
import 'pos_invoice_template_renderer_registry.dart';

class PosInvoicePdfBuildOptions {
  final PrintFormat format;
  final int copies;
  final bool includeDuplicateStamp;
  final MetalType? activeMetal;
  final bool includeAllMetals;
  final String templateId;
  final Map<MetalType, BillSettings> metalPrintSettings;

  const PosInvoicePdfBuildOptions({
    required this.format,
    required this.copies,
    required this.includeDuplicateStamp,
    required this.metalPrintSettings,
    this.templateId = PrintTemplateRegistry.defaultTemplateId,
    this.activeMetal,
    this.includeAllMetals = false,
  });
}

class PosInvoicePdfBuilder {
  final PosInvoiceScopeService _scopeService;

  const PosInvoicePdfBuilder({
    PosInvoiceScopeService scopeService = const PosInvoiceScopeService(),
  }) : _scopeService = scopeService;

  Future<Uint8List> build({
    required PosInvoiceModel invoice,
    required PosInvoicePdfBuildOptions options,
  }) {
    return _PosInvoicePdfDocumentBuilder(
      scopeService: _scopeService,
      options: options,
    ).build(invoice);
  }
}

class _PosInvoicePdfDocumentBuilder {
  static const PdfColor _pdfTextColor = PdfColors.black;
  static const PdfColor _pdfMutedTextColor = PdfColors.black;
  static const PdfColor _pdfBorderColor = PdfColors.grey600;
  static const PdfColor _pdfLightBorderColor = PdfColors.grey500;
  static const PdfColor _pdfSoftFillColor = PdfColors.grey100;
  static const PdfColor _pdfHeaderFillColor = PdfColors.grey200;
  static const double _pdfShopTitleSize = 22;
  static const double _pdfTitleSize = 15;
  static const double _pdfCustomerNameSize = 13.5;
  static const double _pdfBodySize = 10.5;
  static const double _pdfLabelSize = 9.5;
  static const double _pdfTableHeaderSize = 9.2;
  static const double _pdfTableCellSize = 9;
  static const double _pdfTotalSize = 10.5;
  static const double _pdfGrandLabelSize = 12.5;
  static const double _pdfGrandValueSize = 13.5;
  static const double _pdfPolicyTitleSize = 9;
  static const double _pdfPolicyBodySize = 8.8;

  final PosInvoiceScopeService scopeService;
  final PosInvoicePdfBuildOptions options;

  const _PosInvoicePdfDocumentBuilder({
    required this.scopeService,
    required this.options,
  });

  Future<Uint8List> build(PosInvoiceModel invoice) async {
    final devanagariFont = await _loadDevanagariFont();
    final doc = pw.Document(theme: await _buildTheme(devanagariFont));
    final pageFormat = _pageFormatFor(options.format);
    final scopedInvoices = options.includeAllMetals
        ? scopeService.scopedInvoicesForAllMetals(invoice)
        : [
            scopeService.scopedInvoiceForMetal(
              invoice,
              options.activeMetal,
            ),
          ];

    for (int i = 0; i < options.copies; i++) {
      for (final scopedInvoice in scopedInvoices) {
        _addInvoicePage(doc, scopedInvoice, options.format, pageFormat);
      }
    }
    return doc.save();
  }

  Future<pw.Font?> _loadDevanagariFont() async {
    const assetPath = 'assets/fonts/lohit_devanagari/Lohit-Devanagari.ttf';
    try {
      return pw.Font.ttf(await rootBundle.load(assetPath));
    } catch (_) {
      try {
        final fontFile = File(assetPath);
        if (fontFile.existsSync()) {
          return pw.Font.ttf(_asByteData(await fontFile.readAsBytes()));
        }
      } catch (_) {}
    }
    return null;
  }

  Future<pw.ThemeData> _buildTheme(pw.Font? devanagariFont) async {
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
            fontFallback: devanagariFont == null ? null : [devanagariFont],
          );
        } catch (_) {}
      }
    }

    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      fontFallback: devanagariFont == null ? null : [devanagariFont],
    );
  }

  ByteData _asByteData(Uint8List bytes) {
    return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
  }

  PdfPageFormat _pageFormatFor(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return PdfPageFormat.a4;
      case PrintFormat.thermal3inch:
        return const PdfPageFormat(
          80 * PdfPageFormat.mm,
          250 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        );
      case PrintFormat.thermal2inch:
        return const PdfPageFormat(
          57 * PdfPageFormat.mm,
          250 * PdfPageFormat.mm,
          marginAll: 3 * PdfPageFormat.mm,
        );
    }
  }

  void _addInvoicePage(
    pw.Document doc,
    PosInvoiceModel invoice,
    PrintFormat format,
    PdfPageFormat pageFormat,
  ) {
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: format == PrintFormat.a4
            ? const pw.EdgeInsets.all(24)
            : const pw.EdgeInsets.all(6),
        build: (pw.Context context) {
          final layout = format == PrintFormat.a4
              ? _buildA4Layout(invoice)
              : _buildThermalLayout(invoice, format);
          if (options.includeDuplicateStamp) {
            return pw.Stack(
              alignment: pw.Alignment.center,
              children: [
                pw.Center(
                  child: pw.Transform.rotate(
                    angle: 0.785,
                    child: pw.Text(
                      'DUPLICATE',
                      style: pw.TextStyle(
                        color: PdfColors.grey300,
                        fontSize: format == PrintFormat.a4 ? 60 : 25,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                layout,
              ],
            );
          }
          return layout;
        },
      ),
    );
  }

  pw.Widget _buildA4Layout(PosInvoiceModel invoice) {
    final templateLayout = PosInvoiceTemplateRendererRegistry.tryBuildA4(
      templateId: options.templateId,
      invoice: invoice,
      context: PosInvoiceTemplateRenderContext(
        scopeService: scopeService,
        metalPrintSettings: options.metalPrintSettings,
      ),
    );
    if (templateLayout != null) {
      return templateLayout;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _pdfA4Header(invoice),
        pw.SizedBox(height: 16),
        _pdfCustomerBlock(invoice),
        pw.SizedBox(height: 14),
        _pdfItemsTable(invoice),
        pw.SizedBox(height: 14),
        _pdfTotalsBlock(invoice),
        pw.SizedBox(height: 14),
        _pdfPaymentBlock(invoice),
        _pdfPolicyBlock(invoice),
        pw.Spacer(),
        _pdfFooter(invoice),
      ],
    );
  }

  pw.Widget _pdfA4Header(PosInvoiceModel invoice) {
    final title = _invoiceTitle(invoice);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (invoice.printShopName.trim().isNotEmpty)
              pw.Text(
                invoice.printShopName,
                style: pw.TextStyle(
                  fontSize: _pdfShopTitleSize,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfTextColor,
                ),
              ),
            for (final line in invoice.shopPrintHeaderLines)
              pw.Text(
                line,
                style: const pw.TextStyle(
                  fontSize: _pdfBodySize,
                  color: _pdfMutedTextColor,
                ),
              ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if (title.isNotEmpty)
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: _pdfTitleSize,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.amber800,
                ),
              ),
            pw.SizedBox(height: 4),
            pw.Text(
              'No: ${invoice.invoiceNumber}',
              style: pw.TextStyle(
                fontSize: _pdfBodySize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Date: ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
              style: const pw.TextStyle(
                fontSize: _pdfBodySize,
                color: _pdfTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _invoiceTitle(PosInvoiceModel invoice) {
    final metals = scopeService.collectMetals(invoice);
    final typeLabel =
        invoice.billType == BillType.gst ? 'TAX INVOICE' : 'INVOICE';
    if (metals.length == 1) {
      return '${metals.first.displayName.toUpperCase()} $typeLabel';
    }
    return invoice.billType == BillType.gst ? typeLabel : '';
  }

  pw.Widget _pdfCustomerBlock(PosInvoiceModel invoice) {
    final name = invoice.customerName.isEmpty
        ? 'Walk-in Customer'
        : invoice.customerName;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: _pdfSoftFillColor,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILL TO',
                  style: const pw.TextStyle(
                    fontSize: _pdfLabelSize,
                    color: _pdfTextColor,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: _pdfCustomerNameSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (invoice.customerMobile.isNotEmpty)
                  pw.Text(
                    invoice.customerMobile,
                    style: const pw.TextStyle(
                      fontSize: _pdfBodySize,
                      color: _pdfTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfItemsTable(PosInvoiceModel invoice) {
    final isWholesale = invoice.billingMode == BillingMode.wholesale;
    final itemsByMetal = <MetalType, List<SaleItemModel>>{};
    for (final item in invoice.saleItems) {
      itemsByMetal.putIfAbsent(item.metal, () => []).add(item);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        ...scopeService
            .collectMetals(invoice)
            .where((metal) => (itemsByMetal[metal] ?? []).isNotEmpty)
            .map((metal) {
          final items = itemsByMetal[metal]!;
          final activeConfig = _getMetalConfig(metal);
          final sectionTotal =
              items.fold(0.0, (sum, item) => sum + item.totalValue);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: const pw.BoxDecoration(color: _pdfHeaderFillColor),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${metal.displayName} ITEM DETAILS',
                      style: pw.TextStyle(
                        fontSize: _pdfLabelSize,
                        fontWeight: pw.FontWeight.bold,
                        color: _pdfTextColor,
                      ),
                    ),
                    pw.Text(
                      'Section Total: Rs ${sectionTotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: _pdfLabelSize,
                        fontWeight: pw.FontWeight.bold,
                        color: _pdfTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(color: _pdfBorderColor, width: 0.55),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.amber50),
                    children: [
                      _th('#'),
                      _th('Item Description'),
                      if (activeConfig.showPurity) _th('Purity'),
                      if (activeConfig.showGrossWt) _th('Gross(g)'),
                      if (activeConfig.showLessWt) _th('Less(g)'),
                      if (activeConfig.showNetWt)
                        _th(isWholesale ? 'Fine(g)' : 'Net(g)'),
                      if (activeConfig.showFineWeight && !isWholesale)
                        _th('Fine(g)'),
                      if (activeConfig.showRate) _th('Rate'),
                      if (activeConfig.showMaking ||
                          activeConfig.showMakingType)
                        _th(isWholesale ? 'Labour' : 'Making'),
                      if (activeConfig.showAmount) _th('Amount'),
                    ],
                  ),
                  ...items.asMap().entries.map((entry) {
                    final item = entry.value;
                    var desc = item.descCtrl.text.isNotEmpty
                        ? item.descCtrl.text
                        : '${item.metal.name.toUpperCase()} ITEM';
                    if (activeConfig.showHuid &&
                        item.huidCtrl.text.isNotEmpty) {
                      desc += '\n[HUID: ${item.huidCtrl.text}]';
                    }
                    if (activeConfig.showPcs && item.pcs > 1) {
                      desc += ' (${item.pcs} pcs)';
                    }

                    return pw.TableRow(
                      children: [
                        _cell('${entry.key + 1}'),
                        _cell(desc),
                        if (activeConfig.showPurity) _cell(_formatPurity(item)),
                        if (activeConfig.showGrossWt)
                          _cell(item.grossCtrl.text.isNotEmpty
                              ? item.grossCtrl.text
                              : '0.000'),
                        if (activeConfig.showLessWt)
                          _cell(item.totalLessWt.toStringAsFixed(3)),
                        if (activeConfig.showNetWt)
                          _cell(isWholesale
                              ? item.fineWt.toStringAsFixed(3)
                              : item.netWt.toStringAsFixed(3)),
                        if (activeConfig.showFineWeight && !isWholesale)
                          _cell(item.fineWt.toStringAsFixed(3)),
                        if (activeConfig.showRate)
                          _cell(item.rate.toStringAsFixed(0)),
                        if (activeConfig.showMaking ||
                            activeConfig.showMakingType)
                          _cell(
                            _formatMakingCharge(
                              item,
                              activeConfig,
                              isWholesale: isWholesale,
                            ),
                          ),
                        if (activeConfig.showAmount)
                          _cell(item.totalValue.toStringAsFixed(2)),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 10),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: _pdfTableHeaderSize,
          fontWeight: pw.FontWeight.bold,
          color: _pdfTextColor,
        ),
      ),
    );
  }

  pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: _pdfTableCellSize,
          color: _pdfTextColor,
        ),
      ),
    );
  }

  String _formatMakingCharge(
    SaleItemModel item,
    BillSettings config, {
    required bool isWholesale,
  }) {
    final input = double.tryParse(
          item.makingCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
    final inputLabel = input <= 0
        ? '-'
        : '${_formatCompactNumber(input)}${item.makingChargeType.symbol}';
    final amount = isWholesale ? item.wholesaleLabourAmt : item.makingAmt;
    final amountLabel = 'Rs ${amount.toStringAsFixed(0)}';

    if (config.showMakingType) {
      return inputLabel;
    }
    return amountLabel;
  }

  String _formatCompactNumber(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.0001) {
      return rounded.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatPurity(SaleItemModel item) {
    final text = item.purityCtrl.text.trim();
    final tunch = item.tunch;

    switch (item.metal) {
      case MetalType.gold:
        final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
        final ktVal = match != null
            ? double.tryParse(match.group(1)!)
            : (tunch > 0 ? tunch : null);

        if (ktVal != null && ktVal > 0) {
          final pct = _ktToPercent(ktVal);
          return '${ktVal % 1 == 0 ? ktVal.toInt() : ktVal}KT ($pct%)';
        }
        return text.isNotEmpty ? text : '-';

      case MetalType.silver:
        if (tunch > 0) {
          final clean = tunch % 1 == 0
              ? tunch.toInt().toString()
              : tunch.toStringAsFixed(1);
          return '$clean%';
        }
        if (text.isNotEmpty) return '$text%';
        return '-';

      case MetalType.platinum:
        if (tunch > 0) return '${tunch.toStringAsFixed(1)}%';
        if (text.isNotEmpty) return text;
        return '-';

      case MetalType.diamond:
        if (text.isNotEmpty) return text;
        if (tunch > 0) return '${tunch.toStringAsFixed(2)}ct';
        return '-';
    }
  }

  String _ktToPercent(double kt) {
    switch (kt.round()) {
      case 9:
        return '37.5';
      case 10:
        return '41.7';
      case 12:
        return '50.0';
      case 14:
        return '58.5';
      case 18:
        return '75.0';
      case 20:
        return '83.3';
      case 21:
        return '87.5';
      case 22:
        return '91.60';
      case 23:
        return '95.8';
      case 24:
        return '99.99';
      default:
        final pct = (kt / 24) * 100;
        return pct.toStringAsFixed(1);
    }
  }

  pw.Widget _pdfTotalsBlock(PosInvoiceModel invoice) {
    final showExchangeBreakdown = invoice.oldGoldItems.any(
      (item) => _getMetalConfig(item.metal).showExchangeBreakdown,
    );
    final showGstBreakup = scopeService
        .collectMetals(invoice)
        .any((metal) => _getMetalConfig(metal).showGstBreakup);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: 240,
          child: pw.Column(
            children: [
              _totalRow('Gross Amount', invoice.grossAmount),
              if (invoice.discountAmount > 0)
                _totalRow(
                  'Discount',
                  -invoice.discountAmount,
                  isDeduction: true,
                ),
              if (invoice.billType == BillType.gst && showGstBreakup) ...[
                _totalRow('CGST', invoice.cgst),
                _totalRow('SGST', invoice.sgst),
              ],
              if (invoice.totalOldGoldDeduction > 0) ...[
                () {
                  final goldExchange = invoice.oldGoldItems
                      .where((item) => item.metal == MetalType.gold)
                      .fold(0.0, (sum, item) => sum + item.totalValue);
                  final silverExchange = invoice.oldGoldItems
                      .where((item) => item.metal == MetalType.silver)
                      .fold(0.0, (sum, item) => sum + item.totalValue);
                  final platinumExchange = invoice.oldGoldItems
                      .where((item) => item.metal == MetalType.platinum)
                      .fold(0.0, (sum, item) => sum + item.totalValue);

                  if (!showExchangeBreakdown) {
                    return _totalRow(
                      'Less: Old Metal Exchange',
                      -invoice.totalOldGoldDeduction,
                      isDeduction: true,
                    );
                  }
                  return pw.Column(
                    children: [
                      if (goldExchange > 0)
                        _totalRow(
                          'Less: Gold Exchange',
                          -goldExchange,
                          isDeduction: true,
                        ),
                      if (silverExchange > 0)
                        _totalRow(
                          'Less: Silver Exchange',
                          -silverExchange,
                          isDeduction: true,
                        ),
                      if (platinumExchange > 0)
                        _totalRow(
                          'Less: Platinum Exchange',
                          -platinumExchange,
                          isDeduction: true,
                        ),
                      if (goldExchange == 0 &&
                          silverExchange == 0 &&
                          platinumExchange == 0)
                        _totalRow(
                          'Less: Old Metal Exchange',
                          -invoice.totalOldGoldDeduction,
                          isDeduction: true,
                        ),
                    ],
                  );
                }(),
              ],
              pw.Divider(color: PdfColors.amber800, thickness: 1.0),
              _totalRow(
                'GRAND TOTAL',
                invoice.netPayable,
                isBold: true,
                isGrand: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _totalRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isDeduction = false,
    bool isGrand = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isGrand ? _pdfGrandLabelSize : _pdfTotalSize,
              color: _pdfTextColor,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            "${isDeduction ? '- ' : ''}Rs ${amount.abs().toStringAsFixed(2)}",
            style: pw.TextStyle(
              fontSize: isGrand ? _pdfGrandValueSize : _pdfTotalSize,
              color: _pdfTextColor,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfPaymentBlock(PosInvoiceModel invoice) {
    final totalCashPaid = invoice.totalPaid;
    final hasChangeSettlement = invoice.changeSettlementMethod != null &&
        invoice.changeSettlementAmount > 0.5;

    final payments = <Map<String, dynamic>>[
      if (invoice.cashPaid > 0) {'label': 'Cash', 'amount': invoice.cashPaid},
      if (invoice.upiPaid > 0)
        {'label': 'UPI / Bank Transfer', 'amount': invoice.upiPaid},
      if (invoice.cardPaid > 0) {'label': 'Card', 'amount': invoice.cardPaid},
      if (invoice.advancePaid > 0)
        {'label': 'Advance', 'amount': invoice.advancePaid},
    ];

    final hasDue = invoice.balanceDue > 0.5;
    final isPaid = !hasDue;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _pdfBorderColor, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PAYMENT RECEIVED',
                style: pw.TextStyle(
                  fontSize: _pdfLabelSize,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfTextColor,
                ),
              ),
              if (isPaid)
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    ' FULLY PAID',
                    style: pw.TextStyle(
                      fontSize: _pdfLabelSize,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 8),
          if (payments.isNotEmpty) ...[
            pw.Wrap(
              spacing: 12,
              runSpacing: 6,
              children: payments.map((payment) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    color: _pdfSoftFillColor,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border:
                        pw.Border.all(color: _pdfLightBorderColor, width: 0.5),
                  ),
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: "${payment['label']}:  ",
                          style: const pw.TextStyle(
                            fontSize: _pdfBodySize,
                            color: _pdfTextColor,
                          ),
                        ),
                        pw.TextSpan(
                          text:
                              "Rs ${(payment['amount'] as double).toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            fontSize: _pdfBodySize,
                            fontWeight: pw.FontWeight.bold,
                            color: _pdfTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 10),
          ],
          if (hasChangeSettlement) ...[
            _pdfChangeSettlementBlock(invoice),
            pw.SizedBox(height: 10),
          ],
          if (payments.length > 1) ...[
            pw.Divider(color: _pdfLightBorderColor, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Paid',
                  style: const pw.TextStyle(
                    fontSize: _pdfBodySize,
                    color: _pdfTextColor,
                  ),
                ),
                pw.Text(
                  'Rs ${totalCashPaid.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: _pdfBodySize,
                    fontWeight: pw.FontWeight.bold,
                    color: _pdfTextColor,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
          ],
          pw.Divider(color: _pdfBorderColor, thickness: 0.8),
          pw.SizedBox(height: 6),
          if (hasDue) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Balance Outstanding',
                      style: pw.TextStyle(
                        fontSize: _pdfBodySize,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red700,
                      ),
                    ),
                    if (invoice.promiseDate != null)
                      pw.Text(
                        'Pay by: ${invoice.promiseDate!.day.toString().padLeft(2, '0')}/${invoice.promiseDate!.month.toString().padLeft(2, '0')}/${invoice.promiseDate!.year}',
                        style: const pw.TextStyle(
                          fontSize: _pdfLabelSize,
                          color: _pdfTextColor,
                        ),
                      ),
                  ],
                ),
                pw.Text(
                  'Rs ${invoice.balanceDue.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: _pdfGrandValueSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700,
                  ),
                ),
              ],
            ),
          ] else ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Balance Outstanding',
                  style: const pw.TextStyle(
                    fontSize: _pdfBodySize,
                    color: _pdfTextColor,
                  ),
                ),
                pw.Text(
                  'Nil',
                  style: pw.TextStyle(
                    fontSize: _pdfBodySize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _pdfChangeSettlementBlock(PosInvoiceModel invoice) {
    final method = invoice.changeSettlementMethod;
    final amount = invoice.changeSettlementAmount;
    final settlementLabel = _changeSettlementLabel(method);
    final sourceLabel = _paymentModeLabel(invoice.changeSettlementPaymentMode);
    final isAccountCredit = method == RefundMethod.accountCredit;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: isAccountCredit ? PdfColors.green50 : PdfColors.amber50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(
          color: isAccountCredit ? PdfColors.green700 : PdfColors.amber800,
          width: 0.65,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'EXCESS PAYMENT SETTLEMENT',
            style: pw.TextStyle(
              fontSize: _pdfLabelSize,
              fontWeight: pw.FontWeight.bold,
              color: _pdfTextColor,
            ),
          ),
          pw.SizedBox(height: 5),
          _pdfMiniSettlementRow(
            'Excess Amount',
            'Rs ${amount.toStringAsFixed(2)}',
          ),
          _pdfMiniSettlementRow('Settlement', settlementLabel),
          if (sourceLabel.isNotEmpty)
            _pdfMiniSettlementRow('Received Through', sourceLabel),
        ],
      ),
    );
  }

  pw.Widget _pdfMiniSettlementRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: _pdfLabelSize,
              color: _pdfTextColor,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: _pdfLabelSize,
              fontWeight: pw.FontWeight.bold,
              color: _pdfTextColor,
            ),
          ),
        ],
      ),
    );
  }

  String _changeSettlementLabel(RefundMethod? method) {
    switch (method) {
      case RefundMethod.cash:
        return 'Returned to customer in Cash';
      case RefundMethod.upi:
        return 'Returned to customer through UPI';
      case RefundMethod.accountCredit:
        return 'Added to Customer Account Credit';
      case null:
        return '';
    }
  }

  String _paymentModeLabel(PaymentMode? mode) {
    switch (mode) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI / Bank Transfer';
      case PaymentMode.card:
        return 'Card';
      case PaymentMode.advance:
        return 'Customer Advance';
      case null:
        return '';
    }
  }

  pw.Widget _pdfPolicyBlock(PosInvoiceModel invoice) {
    final entries = <pw.Widget>[];

    for (final metal in scopeService.collectMetals(invoice)) {
      final config = _getMetalConfig(metal);
      _addPolicyEntry(
        entries,
        title: '${metal.displayName} TERMS & CONDITIONS',
        body: config.termsAndConditions,
        enabled: config.printTermsAndConditions,
      );
      _addPolicyEntry(
        entries,
        title: '${metal.displayName} RETURN POLICY',
        body: config.returnPolicyText,
        enabled: config.printReturnPolicy,
      );
      _addPolicyEntry(
        entries,
        title: '${metal.displayName} BUYBACK POLICY',
        body: config.buybackPolicyText,
        enabled: config.printBuybackPolicy,
      );
    }

    if (entries.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _pdfBorderColor, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: entries,
      ),
    );
  }

  void _addPolicyEntry(
    List<pw.Widget> entries, {
    required String title,
    required String body,
    required bool enabled,
  }) {
    final text = body.trim();
    if (!enabled || !_hasPrintableCopy(text)) return;

    if (entries.isNotEmpty) {
      entries.add(pw.SizedBox(height: 7));
    }
    entries.add(
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: _pdfPolicyTitleSize,
          fontWeight: pw.FontWeight.bold,
          color: _pdfTextColor,
        ),
      ),
    );
    entries.add(pw.SizedBox(height: 2));
    entries.add(
      pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: _pdfPolicyBodySize,
          color: _pdfTextColor,
          lineSpacing: 1.2,
        ),
      ),
    );
  }

  pw.Widget _pdfFooter(PosInvoiceModel invoice) {
    final footerMessages = scopeService
        .collectMetals(invoice)
        .map((metal) {
          final config = _getMetalConfig(metal);
          return config.printFooterMessage ? config.footerMessage.trim() : '';
        })
        .where((message) => message.isNotEmpty)
        .where(_hasPrintableCopy)
        .toSet()
        .toList();
    final footerMessage = footerMessages.join(' | ');

    return pw.Column(
      children: [
        pw.Divider(color: _pdfBorderColor),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                footerMessage,
                style: const pw.TextStyle(
                  fontSize: _pdfLabelSize,
                  color: _pdfTextColor,
                ),
              ),
            ),
            pw.Text(
              invoice.printShopName.trim().isEmpty
                  ? 'E&OE'
                  : '${invoice.printShopName}  E&OE',
              style: const pw.TextStyle(
                fontSize: _pdfLabelSize,
                color: _pdfTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _hasPrintableCopy(String value) {
    final text = value.trim();
    return text.isNotEmpty && text != '0' && text != '-';
  }

  pw.Widget _buildThermalLayout(
    PosInvoiceModel invoice,
    PrintFormat format,
  ) {
    final fontSize = format == PrintFormat.thermal2inch ? 8.5 : 9.5;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (invoice.printShopName.trim().isNotEmpty)
          pw.Text(
            invoice.printShopName,
            style: pw.TextStyle(
              fontSize: 13.0,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        for (final line in invoice.shopPrintHeaderLines.take(3))
          pw.Text(
            line,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: fontSize - 1),
          ),
        pw.Text(
          'No: ${invoice.invoiceNumber}',
          style: pw.TextStyle(fontSize: fontSize),
        ),
        pw.Divider(color: _pdfBorderColor),
        pw.Text(
          'GRAND TOTAL: Rs ${invoice.netPayable.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: fontSize + 2,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (invoice.changeSettlementMethod != null &&
            invoice.changeSettlementAmount > 0.5) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'EXCESS: Rs ${invoice.changeSettlementAmount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            _changeSettlementLabel(invoice.changeSettlementMethod),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  BillSettings _getMetalConfig(MetalType metal) {
    return options.metalPrintSettings[metal] ?? BillSettings();
  }
}
