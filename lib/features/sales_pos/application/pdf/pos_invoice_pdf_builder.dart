import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../features/print_templates/domain/print_template_registry.dart';
import '../../../../features/sales_pos/domain/services/pos_invoice_file_naming.dart';
import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';
import '../services/pos_invoice_scope_service.dart';
import 'pos_invoice_financial_breakdown.dart';
import 'pos_invoice_policy_copy.dart';
import 'pos_invoice_print_config.dart';
import 'pos_invoice_pdf_text_renderer.dart';
import 'pos_invoice_shop_print_blocks.dart';
import 'pos_invoice_shop_header_details.dart';
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
  }) async {
    final textRenderer = await PosInvoicePdfTextRenderer.create();
    final policyIconImages =
        await _PosInvoicePdfDocumentBuilder.loadPolicyIconImages();
    return _PosInvoicePdfDocumentBuilder(
      scopeService: _scopeService,
      options: options,
      textRenderer: textRenderer,
      policyIconImages: policyIconImages,
    ).build(invoice);
  }
}

class _PosInvoicePdfDocumentBuilder {
  static const Map<String, String> _policyIconAssetPaths = {
    'policy': 'lib/logo/1.png',
    'policy_return': 'lib/logo/2.png',
    'policy_buyback': 'lib/logo/3.png',
  };

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
  static const double _pdfPolicyTitleSize = 12;
  static const double _pdfPolicyBodySize = 11.2;

  final PosInvoiceScopeService scopeService;
  final PosInvoicePdfBuildOptions options;
  final PosInvoicePdfTextRenderer textRenderer;
  final Map<String, pw.MemoryImage> policyIconImages;

  const _PosInvoicePdfDocumentBuilder({
    required this.scopeService,
    required this.options,
    required this.textRenderer,
    required this.policyIconImages,
  });

  Future<Uint8List> build(PosInvoiceModel invoice) async {
    final devanagariFont = await _loadDevanagariFont();
    final doc = pw.Document(
      title: PosInvoiceFileNaming.pdfBaseName(invoice),
      author: invoice.shopName,
      creator: 'Lotus ERP',
      subject: 'Sales invoice ${invoice.invoiceNumber}',
      theme: await _buildTheme(devanagariFont),
    );
    final pageFormat = _pageFormatFor(options.format);
    final scopedInvoices = options.includeAllMetals
        ? scopeService.scopedInvoicesForAllMetals(invoice)
        : [
            scopeService.scopedInvoiceForMetal(
              invoice,
              options.activeMetal,
            ),
          ];
    await _warmPolicyText(scopedInvoices, pageFormat);

    for (int i = 0; i < options.copies; i++) {
      for (final scopedInvoice in scopedInvoices) {
        _addInvoicePage(
          doc,
          scopedInvoice,
          options.format,
          pageFormat,
          copyIndex: i,
        );
      }
    }
    return doc.save();
  }

  static Future<Map<String, pw.MemoryImage>> loadPolicyIconImages() async {
    final images = <String, pw.MemoryImage>{};
    for (final entry in _policyIconAssetPaths.entries) {
      final image = await _loadImage(entry.value);
      if (image != null) images[entry.key] = image;
    }
    return images;
  }

  static Future<pw.MemoryImage?> _loadImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      try {
        final file = File(assetPath);
        if (file.existsSync()) {
          return pw.MemoryImage(await file.readAsBytes());
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _warmPolicyText(
    List<PosInvoiceModel> invoices,
    PdfPageFormat pageFormat,
  ) async {
    final lines = invoices
        .expand(
          (invoice) => PosInvoicePolicyCopy.entries(
            invoice: invoice,
            scopeService: scopeService,
            metalPrintSettings: options.metalPrintSettings,
          ),
        )
        .expand((entry) => PosInvoicePolicyCopy.lines(entry.body))
        .followedBy(_footerTextLines(invoices))
        .followedBy(_policyPageShopNames(invoices))
        .followedBy(_shopPrintTextLines(invoices))
        .toSet();

    await textRenderer.warmPolicyLines(
      lines,
      specs: [
        PosInvoicePdfTextSpec(
          fontSize: _pdfPolicyBodySize,
          color: _pdfTextColor,
          bold: true,
          maxWidth: _fallbackPolicyBodyWidth(pageFormat),
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 12.1,
          color: PdfColors.black,
          bold: true,
          maxWidth: 456,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 11.6,
          color: PdfColors.black,
          bold: true,
          maxWidth: 456,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 8.3,
          color: PdfColors.black,
          bold: false,
          maxWidth: 470,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 10.2,
          color: PdfColors.black,
          bold: true,
          maxWidth: 360,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 10.2,
          color: PdfColors.black,
          bold: true,
          maxWidth: 500,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 9.8,
          color: PdfColors.black,
          bold: true,
          maxWidth: 500,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 9.4,
          color: PdfColors.black,
          bold: true,
          maxWidth: 360,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 9.2,
          color: PdfColors.black,
          bold: true,
          maxWidth: 220,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: _pdfLabelSize,
          color: PdfColors.black,
          bold: false,
          maxWidth: 360,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 9,
          color: PdfColors.black,
          bold: true,
          maxWidth: 360,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 10.8,
          color: PdfColors.black,
          bold: true,
          maxWidth: 390,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 7.2,
          color: PdfColors.black,
          bold: true,
          maxWidth: 430,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 7.4,
          color: PdfColors.black,
          bold: false,
          maxWidth: 130,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 6.8,
          color: PdfColors.black,
          bold: false,
          maxWidth: 96,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 8,
          color: PdfColor.fromInt(0xFF111827),
          bold: false,
          maxWidth: 500,
        ),
        const PosInvoicePdfTextSpec(
          fontSize: 8.4,
          color: PdfColors.black,
          bold: false,
          maxWidth: 500,
        ),
      ],
    );
  }

  Iterable<String> _footerTextLines(List<PosInvoiceModel> invoices) sync* {
    for (final invoice in invoices) {
      for (final metal in scopeService.collectMetals(invoice)) {
        final config = options.metalPrintSettings[metal] ?? BillSettings();
        if (!config.printFooterMessage) continue;
        yield* PosInvoicePolicyCopy.lines(
          config.footerMessage,
          keepBlankLines: false,
        );
      }
    }
  }

  Iterable<String> _policyPageShopNames(List<PosInvoiceModel> invoices) {
    return invoices.map((invoice) {
      final printName = invoice.printShopName.trim();
      return printName.isEmpty ? invoice.shopName.trim() : printName;
    }).where((name) => name.isNotEmpty);
  }

  Iterable<String> _shopPrintTextLines(List<PosInvoiceModel> invoices) sync* {
    for (final invoice in invoices) {
      yield* PosInvoiceShopPrintBlocks.printableTextLines(invoice);
    }
  }

  double _fallbackPolicyBodyWidth(PdfPageFormat pageFormat) {
    return pageFormat.width - 56;
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

  void _addInvoicePage(pw.Document doc, PosInvoiceModel invoice,
      PrintFormat format, PdfPageFormat pageFormat,
      {required int copyIndex}) {
    final includeDuplicateStamp = _includeDuplicateStamp(copyIndex);
    if (format == PrintFormat.a4) {
      _addA4InvoicePage(
        doc,
        invoice,
        pageFormat,
        includeDuplicateStamp: includeDuplicateStamp,
      );
      _addA4PolicyPages(
        doc,
        invoice,
        pageFormat,
        includeDuplicateStamp: includeDuplicateStamp,
      );
      return;
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(6),
          buildBackground: includeDuplicateStamp
              ? (_) => pw.Center(child: _duplicateWatermark(fontSize: 25))
              : null,
        ),
        build: (_) => [_buildThermalLayout(invoice, format)],
      ),
    );
  }

  void _addA4InvoicePage(
      pw.Document doc, PosInvoiceModel invoice, PdfPageFormat pageFormat,
      {required bool includeDuplicateStamp}) {
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          final layout = _buildA4Layout(
            invoice,
            includePolicyBlock: false,
          );
          if (includeDuplicateStamp) {
            return pw.Stack(
              alignment: pw.Alignment.center,
              children: [
                _duplicateWatermark(fontSize: 60),
                layout,
              ],
            );
          }
          return layout;
        },
      ),
    );
  }

  void _addA4PolicyPages(
      pw.Document doc, PosInvoiceModel invoice, PdfPageFormat pageFormat,
      {required bool includeDuplicateStamp}) {
    final templateHandled =
        PosInvoiceTemplateRendererRegistry.tryAddA4PolicyPages(
      templateId: options.templateId,
      doc: doc,
      invoice: invoice,
      pageFormat: pageFormat,
      context: PosInvoiceTemplateRenderContext(
        scopeService: scopeService,
        metalPrintSettings: options.metalPrintSettings,
        policyIconImages: policyIconImages,
        textRenderer: textRenderer,
      ),
      includeDuplicateStamp: includeDuplicateStamp,
    );
    if (templateHandled) return;

    final entries = _policyEntries(invoice);
    if (entries.isEmpty &&
        !PosInvoiceShopPrintBlocks.hasPrintableSocialSection(invoice)) {
      return;
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(28),
          buildBackground: includeDuplicateStamp
              ? (_) => pw.Center(
                    child: _duplicateWatermark(fontSize: 60),
                  )
              : null,
        ),
        header: (_) => _policyPageHeader(invoice),
        footer: (context) => _policyPageFooter(invoice, context),
        build: (_) => _policyPageContent(
          invoice,
          entries,
          bodyWidth: _fallbackPolicyBodyWidth(pageFormat),
        ),
      ),
    );
  }

  bool _includeDuplicateStamp(int copyIndex) {
    return options.includeDuplicateStamp && copyIndex > 0;
  }

  pw.Widget _duplicateWatermark({required double fontSize}) {
    return pw.Transform.rotate(
      angle: 0.785,
      child: pw.Text(
        'DUPLICATE',
        style: pw.TextStyle(
          color: PdfColors.grey300,
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildA4Layout(
    PosInvoiceModel invoice, {
    bool includePolicyBlock = true,
  }) {
    final templateLayout = PosInvoiceTemplateRendererRegistry.tryBuildA4(
      templateId: options.templateId,
      invoice: invoice,
      context: PosInvoiceTemplateRenderContext(
        scopeService: scopeService,
        metalPrintSettings: options.metalPrintSettings,
        policyIconImages: policyIconImages,
        includePolicyBlock: includePolicyBlock,
        textRenderer: textRenderer,
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
        if (includePolicyBlock) ...[
          _pdfPolicyBlock(invoice),
          ..._pdfShopPrintSocialSection(invoice),
        ],
        pw.Spacer(),
        _pdfFooter(invoice),
      ],
    );
  }

  List<pw.Widget> _pdfShopPrintSocialSection(PosInvoiceModel invoice) {
    final section = PosInvoiceShopPrintBlocks.socialSection(
      invoice,
      textRenderer: textRenderer,
      borderColor: _pdfLightBorderColor,
      accentColor: _pdfBorderColor,
    );
    if (section == null) return const [];
    return [section, pw.SizedBox(height: 8)];
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
    if (metals.length == 1) {
      return '${metals.first.displayName.toUpperCase()} INVOICE';
    }
    return 'SALES INVOICE';
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
                      if (activeConfig.showHsnCode) _th('HSN'),
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
                    if (activeConfig.showHuid && item.huidText.isNotEmpty) {
                      desc += '\n[HUID: ${item.huidText}]';
                    }
                    if (activeConfig.showPcs && item.pcs > 1) {
                      desc += ' (${item.pcs} pcs)';
                    }

                    return pw.TableRow(
                      children: [
                        _cell('${entry.key + 1}'),
                        _cell(desc),
                        if (activeConfig.showHsnCode) _cell(_hsnCode(item)),
                        if (activeConfig.showPurity) _cell(_formatPurity(item)),
                        if (activeConfig.showGrossWt)
                          _cell(_formatWeightText(
                            item.grossCtrl.text,
                            fallback: item.netWt,
                            includeUnit: false,
                          )),
                        if (activeConfig.showLessWt)
                          _cell(_formatWeightText(
                            item.totalLessWt.toStringAsFixed(3),
                            includeUnit: false,
                          )),
                        if (activeConfig.showNetWt)
                          _cell(_formatWeightText(
                            isWholesale
                                ? item.fineWt.toStringAsFixed(3)
                                : item.netWt.toStringAsFixed(3),
                            includeUnit: false,
                          )),
                        if (activeConfig.showFineWeight && !isWholesale)
                          _cell(_formatWeightText(
                            item.fineWt.toStringAsFixed(3),
                            includeUnit: false,
                          )),
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

  String _hsnCode(SaleItemModel item) {
    final code = item.invoiceHsnCode?.trim() ?? '';
    return code.isEmpty ? '-' : code;
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

  String _formatWeightText(
    String value, {
    double fallback = 0.0,
    bool includeUnit = true,
  }) {
    final clean = value.trim();
    final parsed = clean.isEmpty
        ? fallback
        : double.tryParse(clean.replaceAll(RegExp(r'[^0-9.]'), '')) ?? fallback;
    final formatted = parsed.toStringAsFixed(3);
    return includeUnit ? '$formatted g' : formatted;
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
                if (invoice.hasIgstBreakup)
                  _totalRow('IGST', invoice.igst)
                else ...[
                  _totalRow('CGST', invoice.cgst),
                  _totalRow('SGST', invoice.sgst),
                ],
              ] else if (invoice.billType == BillType.gst &&
                  invoice.totalGst > 0.005)
                _totalRow(
                  PosInvoiceFinancialBreakdown.combinedGstLabel(invoice),
                  invoice.totalGst,
                ),
              if (invoice.totalTradeInDeduction > 0)
                _totalRow(
                  'Less: Customer Metal Settlement',
                  -invoice.totalTradeInDeduction,
                  isDeduction: true,
                ),
              if (invoice.roundOffAmount.abs() > 0.005)
                _totalRow(
                  'Round Off',
                  invoice.roundOffAmount,
                  isDeduction: invoice.roundOffAmount < 0,
                ),
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

  List<PosInvoicePolicyEntry> _policyEntries(PosInvoiceModel invoice) {
    return PosInvoicePolicyCopy.entries(
      invoice: invoice,
      scopeService: scopeService,
      metalPrintSettings: options.metalPrintSettings,
    );
  }

  pw.Widget _policyPageHeader(PosInvoiceModel invoice) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 9),
      padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: pw.BoxDecoration(
        color: _pdfHeaderFillColor,
        border: pw.Border.all(color: _pdfLightBorderColor, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TERMS & POLICIES',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfTextColor,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                invoice.printShopName.trim().isEmpty
                    ? _invoiceTitle(invoice)
                    : '${invoice.printShopName} | ${_invoiceTitle(invoice)}',
                style: const pw.TextStyle(
                  fontSize: 8.8,
                  color: _pdfMutedTextColor,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Invoice No.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: _pdfMutedTextColor,
                ),
              ),
              pw.Text(
                invoice.invoiceNumber,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _policyPageFooter(PosInvoiceModel invoice, pw.Context context) {
    final footerLines = _footerTextLinesForInvoice(invoice);
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 7),
      padding: const pw.EdgeInsets.only(top: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _pdfLightBorderColor)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final line in footerLines)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: textRenderer.text(
                      line,
                      maxWidth: 360,
                      style: pw.TextStyle(
                        fontSize: 9.4,
                        color: _pdfTextColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 9.1,
              color: _pdfTextColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _policyPageContent(
    PosInvoiceModel invoice,
    List<PosInvoicePolicyEntry> entries, {
    required double bodyWidth,
  }) {
    final widgets = <pw.Widget>[];

    if (entries.isEmpty) {
      final socialPanel = PosInvoiceShopPrintBlocks.policySocialPanel(
        invoice,
        textRenderer: textRenderer,
        borderColor: _pdfLightBorderColor,
        accentColor: _pdfBorderColor,
      );
      if (socialPanel != null) {
        widgets.add(socialPanel);
      }
      return widgets;
    }

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      if (index > 0) {
        widgets.add(pw.SizedBox(height: 12));
      }
      widgets.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.black, width: 0.55),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            entry.title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: _pdfPolicyTitleSize,
              fontWeight: pw.FontWeight.bold,
              color: _pdfTextColor,
            ),
          ),
        ),
      );
      widgets.add(pw.SizedBox(height: 4));
      widgets.addAll(_policyBodyLines(entry.body, bodyWidth: bodyWidth));
    }

    final socialPanel = PosInvoiceShopPrintBlocks.policySocialPanel(
      invoice,
      textRenderer: textRenderer,
      borderColor: _pdfLightBorderColor,
      accentColor: _pdfBorderColor,
    );
    if (socialPanel != null) {
      widgets.add(pw.SizedBox(height: 14));
      widgets.add(socialPanel);
    }

    return widgets;
  }

  List<pw.Widget> _policyBodyLines(
    String body, {
    required double bodyWidth,
  }) {
    final rawLines = PosInvoicePolicyCopy.lines(body);
    final widgets = <pw.Widget>[];

    for (final rawLine in rawLines) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 5));
        continue;
      }
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: textRenderer.text(
            line,
            maxWidth: bodyWidth,
            style: pw.TextStyle(
              fontSize: _pdfPolicyBodySize,
              color: _pdfTextColor,
              fontWeight: pw.FontWeight.bold,
              lineSpacing: 1.05,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  pw.Widget _pdfPolicyBlock(PosInvoiceModel invoice) {
    final entries = <pw.Widget>[];

    for (final entry in _policyEntries(invoice)) {
      _addPolicyEntry(
        entries,
        title: entry.title.toUpperCase(),
        body: entry.body,
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
  }) {
    if (!_hasPrintableCopy(body)) return;

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
    entries.addAll(_policyBodyLines(body, bodyWidth: 500));
  }

  pw.Widget _pdfFooter(PosInvoiceModel invoice) {
    final footerLines = _footerTextLinesForInvoice(invoice);

    return pw.Column(
      children: [
        pw.Divider(color: _pdfBorderColor),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (final line in footerLines)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: textRenderer.text(
                        line,
                        maxWidth: 360,
                        style: const pw.TextStyle(
                          fontSize: _pdfLabelSize,
                          color: _pdfTextColor,
                        ),
                      ),
                    ),
                ],
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

  List<String> _footerTextLinesForInvoice(PosInvoiceModel invoice) {
    return _footerMessages(invoice)
        .expand(
          (message) => PosInvoicePolicyCopy.lines(
            message,
            keepBlankLines: false,
          ),
        )
        .toList(growable: false);
  }

  List<String> _footerMessages(PosInvoiceModel invoice) {
    return scopeService
        .collectMetals(invoice)
        .map((metal) {
          final config = _getMetalConfig(metal);
          return config.printFooterMessage ? config.footerMessage.trim() : '';
        })
        .where((message) => message.isNotEmpty)
        .where(_hasPrintableCopy)
        .toSet()
        .toList(growable: false);
  }

  bool _hasPrintableCopy(String value) {
    final text = value.trim();
    return text.isNotEmpty && text != '0' && text != '-';
  }

  pw.Widget _buildThermalLayout(
    PosInvoiceModel invoice,
    PrintFormat format,
  ) {
    final fontSize = _thermalFontSize(format);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _thermalHeader(invoice, fontSize),
        _thermalSectionTitle('Customer', fontSize),
        _thermalKeyValue(
          'Name',
          invoice.customerName.trim().isEmpty
              ? 'Walk-in Customer'
              : invoice.customerName.trim(),
          fontSize,
        ),
        if (invoice.customerMobile.trim().isNotEmpty)
          _thermalKeyValue('Mobile', invoice.customerMobile.trim(), fontSize),
        if (invoice.customerCity.trim().isNotEmpty)
          _thermalKeyValue('Address', invoice.customerCity.trim(), fontSize),
        if (invoice.customerGstin.trim().isNotEmpty)
          _thermalKeyValue('GSTIN', invoice.customerGstin.trim(), fontSize),
        _thermalSaleItems(invoice, fontSize),
        if (_showCustomerMetalSettlement(invoice))
          _thermalMetalSettlement(invoice, fontSize),
        _thermalTotals(invoice, fontSize),
        _thermalPayments(invoice, fontSize),
        _thermalFooter(invoice, fontSize),
      ],
    );
  }

  double _thermalFontSize(PrintFormat format) {
    return format == PrintFormat.thermal2inch ? 7.2 : 8.4;
  }

  pw.Widget _thermalHeader(PosInvoiceModel invoice, double fontSize) {
    final shopHeader = PosInvoiceShopHeaderDetails.fromInvoice(invoice);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (shopHeader.shopName.isNotEmpty)
          pw.Text(
            shopHeader.shopName.toUpperCase(),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: fontSize + 3,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        for (final line in shopHeader.thermalLines.take(5))
          if (line.trim().isNotEmpty)
            pw.Text(
              line.trim(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: fontSize - 0.4),
            ),
        pw.SizedBox(height: 4),
        pw.Text(
          _invoiceTitle(invoice),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: fontSize + 1,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        _thermalDivider(),
        _thermalKeyValue('Invoice No', invoice.invoiceNumber, fontSize),
        _thermalKeyValue('Date', _thermalDate(invoice.invoiceDate), fontSize),
        _thermalKeyValue(
          'Bill Type',
          _invoiceTypeLabel(invoice),
          fontSize,
        ),
      ],
    );
  }

  pw.Widget _thermalSaleItems(PosInvoiceModel invoice, double fontSize) {
    if (invoice.saleItems.isEmpty) return pw.SizedBox.shrink();
    var lineNo = 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _thermalSectionTitle('Item Details', fontSize),
        for (final item in invoice.saleItems) ...[
          _thermalItemBlock(++lineNo, item, invoice, fontSize),
          if (lineNo < invoice.saleItems.length) _thermalDashedDivider(),
        ],
      ],
    );
  }

  pw.Widget _thermalItemBlock(
    int lineNo,
    SaleItemModel item,
    PosInvoiceModel invoice,
    double fontSize,
  ) {
    final config = _getMetalConfig(item.metal);
    final isWholesale = invoice.billingMode == BillingMode.wholesale;
    final description = item.descCtrl.text.trim().isEmpty
        ? '${item.metal.displayName} Item'
        : item.descCtrl.text.trim();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _thermalKeyValue(
          '$lineNo. ${item.metal.displayName}',
          description,
          fontSize,
          boldValue: true,
        ),
        if (config.showHuid && item.huidText.trim().isNotEmpty)
          _thermalKeyValue('HUID', item.huidText.trim(), fontSize),
        if (config.showHsnCode)
          _thermalKeyValue('HSN', _hsnCode(item), fontSize),
        if (config.showPcs) _thermalKeyValue('Pcs', '${item.pcs}', fontSize),
        if (config.showPurity)
          _thermalKeyValue('Purity', _formatPurity(item), fontSize),
        if (config.showGrossWt)
          _thermalKeyValue(
            'Gross',
            _formatWeightText(item.grossCtrl.text, fallback: item.netWt),
            fontSize,
          ),
        if (config.showLessWt)
          _thermalKeyValue(
            'Less',
            _formatWeightText(item.totalLessWt.toStringAsFixed(3)),
            fontSize,
          ),
        if (config.showNetWt)
          _thermalKeyValue(
            isWholesale ? 'Fine' : 'Net',
            _formatWeightText(
              (isWholesale ? item.fineWt : item.netWt).toStringAsFixed(3),
            ),
            fontSize,
          ),
        if (config.showFineWeight && !isWholesale)
          _thermalKeyValue(
            'Fine',
            _formatWeightText(item.fineWt.toStringAsFixed(3)),
            fontSize,
          ),
        if (config.showRate)
          _thermalKeyValue('Rate', _thermalMoney(item.rate), fontSize),
        if (config.showMaking || config.showMakingType)
          _thermalKeyValue(
            isWholesale ? 'Labour' : 'Making',
            _formatMakingCharge(item, config, isWholesale: isWholesale),
            fontSize,
          ),
        if (config.showAmount)
          _thermalKeyValue(
            'Amount',
            _thermalMoney(item.totalValue),
            fontSize,
            boldValue: true,
          ),
      ],
    );
  }

  bool _showCustomerMetalSettlement(PosInvoiceModel invoice) {
    return _visibleTradeInItems(invoice).isNotEmpty;
  }

  pw.Widget _thermalMetalSettlement(
    PosInvoiceModel invoice,
    double fontSize,
  ) {
    final visibleItems = _visibleTradeInItems(invoice);
    final settlementTotal = visibleItems.fold<double>(
      0,
      (sum, item) => sum + item.totalValue,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _thermalSectionTitle('Customer Metal Settlement', fontSize),
        for (var i = 0; i < visibleItems.length; i++) ...[
          _thermalTradeInBlock(i + 1, visibleItems[i], fontSize),
          if (i < visibleItems.length - 1) _thermalDashedDivider(),
        ],
        _thermalKeyValue(
          'Settlement Total',
          '- ${_thermalMoney(settlementTotal)}',
          fontSize,
          boldValue: true,
        ),
      ],
    );
  }

  List<TradeInItemModel> _visibleTradeInItems(PosInvoiceModel invoice) {
    return invoice.tradeInItems
        .where((item) => _getMetalConfig(item.metal).showExchangeBreakdown)
        .toList(growable: false);
  }

  pw.Widget _thermalTradeInBlock(
    int lineNo,
    TradeInItemModel item,
    double fontSize,
  ) {
    final description = item.descCtrl.text.trim().isEmpty
        ? '${item.metal.displayName} Metal'
        : item.descCtrl.text.trim();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _thermalKeyValue(
          '$lineNo. ${item.metal.displayName}',
          description,
          fontSize,
          boldValue: true,
        ),
        _thermalKeyValue(
          'Gross / Net',
          '${_formatWeightText(item.grossCtrl.text, fallback: item.netWt)} / ${_formatWeightText(item.netWt.toStringAsFixed(3))}',
          fontSize,
        ),
        _thermalKeyValue(
          'Purity / Fine',
          '${item.purityPercent.toStringAsFixed(2)}% / ${_formatWeightText(item.fineWt.toStringAsFixed(3))}',
          fontSize,
        ),
        _thermalKeyValue('Rate', _thermalMoney(item.rate), fontSize),
        _thermalKeyValue(
          'Value',
          _thermalMoney(item.totalValue),
          fontSize,
          boldValue: true,
        ),
      ],
    );
  }

  pw.Widget _thermalTotals(PosInvoiceModel invoice, double fontSize) {
    final showGstBreakup = scopeService
        .collectMetals(invoice)
        .any((metal) => _getMetalConfig(metal).showGstBreakup);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _thermalSectionTitle('Bill Summary', fontSize),
        _thermalKeyValue(
            'Gross Value', _thermalMoney(invoice.grossAmount), fontSize),
        if (invoice.discountAmount > 0.5)
          _thermalKeyValue(
            'Discount',
            '- ${_thermalMoney(invoice.discountAmount)}',
            fontSize,
          ),
        if (invoice.billType == BillType.gst) ...[
          _thermalKeyValue(
              'Taxable Value', _thermalMoney(invoice.taxableAmount), fontSize),
          if (showGstBreakup) ...[
            if (invoice.hasIgstBreakup)
              _thermalKeyValue('IGST', _thermalMoney(invoice.igst), fontSize)
            else ...[
              if (invoice.cgst > posInvoiceMoneyEpsilon)
                _thermalKeyValue('CGST', _thermalMoney(invoice.cgst), fontSize),
              if (invoice.sgst > posInvoiceMoneyEpsilon)
                _thermalKeyValue('SGST', _thermalMoney(invoice.sgst), fontSize),
            ],
            _thermalKeyValue(
                'Total GST', _thermalMoney(invoice.totalGst), fontSize),
          ] else if (invoice.totalGst > posInvoiceMoneyEpsilon)
            _thermalKeyValue(
              PosInvoiceFinancialBreakdown.combinedGstLabel(invoice),
              _thermalMoney(invoice.totalGst),
              fontSize,
            ),
        ],
        if (invoice.totalTradeInDeduction > 0.5)
          _thermalKeyValue(
            'Metal Adjusted',
            '- ${_thermalMoney(invoice.totalTradeInDeduction)}',
            fontSize,
          ),
        if (invoice.roundOffAmount.abs() > 0.005)
          _thermalKeyValue(
            'Round Off',
            invoice.roundOffAmount < 0
                ? '- ${_thermalMoney(invoice.roundOffAmount.abs())}'
                : _thermalMoney(invoice.roundOffAmount),
            fontSize,
          ),
        _thermalDivider(),
        _thermalKeyValue(
          'Net Payable',
          _thermalMoney(invoice.netPayable),
          fontSize + 0.8,
          boldLabel: true,
          boldValue: true,
        ),
      ],
    );
  }

  pw.Widget _thermalPayments(PosInvoiceModel invoice, double fontSize) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _thermalSectionTitle('Payment', fontSize),
        if (invoice.cashPaid > 0.5)
          _thermalKeyValue('Cash', _thermalMoney(invoice.cashPaid), fontSize),
        if (invoice.upiPaid > 0.5)
          _thermalKeyValue(
              'UPI / Bank', _thermalMoney(invoice.upiPaid), fontSize),
        if (invoice.cardPaid > 0.5)
          _thermalKeyValue('Card', _thermalMoney(invoice.cardPaid), fontSize),
        if (invoice.advancePaid > 0.5)
          _thermalKeyValue(
              'Advance', _thermalMoney(invoice.advancePaid), fontSize),
        _thermalKeyValue('Paid', _thermalMoney(invoice.totalPaid), fontSize),
        if (invoice.balanceDue > 0.5)
          _thermalKeyValue(
            'Balance Due',
            _thermalMoney(invoice.balanceDue),
            fontSize,
            boldValue: true,
          )
        else
          _thermalKeyValue(
            'Status',
            'PAID',
            fontSize,
            boldLabel: true,
            boldValue: true,
          ),
        if (invoice.changeSettlementMethod != null &&
            invoice.changeSettlementAmount > 0.5) ...[
          _thermalKeyValue(
            'Excess',
            _thermalMoney(invoice.changeSettlementAmount),
            fontSize,
            boldValue: true,
          ),
          _thermalKeyValue(
            'Returned',
            _changeSettlementLabel(invoice.changeSettlementMethod),
            fontSize,
          ),
        ],
      ],
    );
  }

  pw.Widget _thermalFooter(PosInvoiceModel invoice, double fontSize) {
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

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _thermalDivider(),
        if (footerMessages.isNotEmpty)
          pw.Text(
            footerMessages.join(' | '),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: fontSize - 0.4),
          ),
        if (footerMessages.isNotEmpty) pw.SizedBox(height: 3),
        pw.Text(
          'E&OE',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: fontSize - 0.8),
        ),
      ],
    );
  }

  pw.Widget _thermalSectionTitle(String title, double fontSize) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _thermalDivider(),
        pw.Text(
          title.toUpperCase(),
          textAlign: pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
      ],
    );
  }

  pw.Widget _thermalKeyValue(
    String label,
    String value,
    double fontSize, {
    bool boldLabel = false,
    bool boldValue = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 58,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: boldLabel ? pw.FontWeight.bold : null,
              ),
            ),
          ),
          pw.Text(': ', style: pw.TextStyle(fontSize: fontSize)),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: boldValue ? pw.FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _thermalDivider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Container(height: 0.7, color: _pdfBorderColor),
    );
  }

  pw.Widget _thermalDashedDivider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Text(
        '--------------------------------',
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 6, color: _pdfMutedTextColor),
      ),
    );
  }

  String _thermalDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _thermalMoney(double amount) {
    return 'Rs ${amount.toStringAsFixed(2)}';
  }

  String _invoiceTypeLabel(PosInvoiceModel invoice) {
    if (invoice.billType != BillType.gst) return 'Sales Invoice';
    return invoice.gstPricingMode == GstPricingMode.inclusive
        ? 'Legacy GST Included Tax Invoice'
        : 'Tax Invoice';
  }

  BillSettings _getMetalConfig(MetalType metal) {
    return options.metalPrintSettings[metal] ?? BillSettings();
  }
}
