import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';
import '../services/pos_invoice_scope_service.dart';
import 'pos_invoice_financial_breakdown.dart';
import 'pos_invoice_policy_copy.dart';
import 'pos_invoice_print_config.dart';
import 'pos_invoice_pdf_text_renderer.dart';
import 'pos_invoice_shop_print_blocks.dart';

class PosLotusSignatureInvoicePdfLayout {
  static final _amountFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final _dateFormat = DateFormat('dd MMM yyyy');

  static const _gold = PdfColor(0.72, 0.47, 0.10);
  static const _softGold = PdfColor(0.98, 0.95, 0.88);
  static const _ink = PdfColors.black;
  static const _line = PdfColor(0.76, 0.67, 0.53);
  static const _success = PdfColor.fromInt(0xFF166534);
  static const _danger = PdfColor.fromInt(0xFFB91C1C);
  static const _policyEnglishFontSize = 12.6;
  static const _policyHindiFontSize = 12.0;
  static const _footerMessageFontSize = 10.8;
  static const _footerMessageMaxWidth = 360.0;
  static const _policyPageShopNameMaxWidth = 220.0;

  final PosInvoiceScopeService scopeService;
  final Map<MetalType, BillSettings> metalPrintSettings;
  final Map<String, pw.MemoryImage> policyIconImages;
  final bool suppressPaymentSettlement;
  final PosInvoicePdfTextRenderer? textRenderer;

  const PosLotusSignatureInvoicePdfLayout({
    required this.scopeService,
    required this.metalPrintSettings,
    this.policyIconImages = const {},
    this.suppressPaymentSettlement = false,
    this.textRenderer,
  });

  pw.Widget build(
    PosInvoiceModel invoice, {
    bool includePolicyBlock = true,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _gold, width: 0.9),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header(invoice),
          pw.SizedBox(height: 14),
          _customerAndInvoiceDetails(invoice),
          pw.SizedBox(height: 14),
          _saleItemSections(invoice),
          if (_visibleTradeInItems(invoice).isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _tradeInSection(invoice),
          ],
          pw.SizedBox(height: 14),
          suppressPaymentSettlement
              ? _amountSummary(invoice)
              : _paymentAndTotals(invoice),
          if (includePolicyBlock) ...[
            if (_policyLines(invoice).isNotEmpty) ...[
              pw.SizedBox(height: 10),
              _policyPreview(invoice),
            ],
            ..._shopPrintSocialSection(invoice),
          ],
          pw.Spacer(),
          _footer(invoice),
        ],
      ),
    );
  }

  List<pw.Widget> _shopPrintSocialSection(PosInvoiceModel invoice) {
    final section = PosInvoiceShopPrintBlocks.socialSection(
      invoice,
      textRenderer: textRenderer,
      borderColor: _line,
      accentColor: _gold,
    );
    if (section == null) return const [];
    return [section, pw.SizedBox(height: 10)];
  }

  void addPolicyPages(
    pw.Document doc,
    PosInvoiceModel invoice,
    PdfPageFormat pageFormat, {
    required bool includeDuplicateStamp,
  }) {
    final entries = _policyEntries(invoice);
    if (entries.isEmpty &&
        !PosInvoiceShopPrintBlocks.hasPrintableSocialSection(invoice)) {
      return;
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(24),
          buildBackground: includeDuplicateStamp
              ? (_) => pw.Center(child: _duplicateWatermark(fontSize: 60))
              : null,
        ),
        footer: (context) => _policyPageFooter(invoice, context),
        build: (_) => _policyPageContent(invoice, entries),
      ),
    );
  }

  pw.Widget _header(PosInvoiceModel invoice) {
    final addressLines = _addressLines(invoice);
    final phoneLine = _shopPhoneLine(invoice);
    final emailLine = _shopEmailLine(invoice);
    final gstinLine = _shopGstinLine(invoice);
    final bisLine = _shopBisLine(invoice);

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _gold, width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 124,
            padding: const pw.EdgeInsets.only(right: 14),
            child: _brandMark(invoice),
          ),
          pw.Container(width: 1, height: 124, color: _line),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _fallback(invoice.printShopName, invoice.shopName),
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                          color: _ink,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      if (addressLines.isNotEmpty)
                        _headerAddressBlock(
                          addressLines.take(2).toList(growable: false),
                        ),
                      if (phoneLine.isNotEmpty)
                        _headerInfoLine('phone', phoneLine, strong: true),
                      if (emailLine.isNotEmpty)
                        _headerInfoLine('mail', emailLine, strong: true),
                      if (gstinLine.isNotEmpty) _headerGstinLine(gstinLine),
                      if (bisLine.isNotEmpty)
                        _headerInfoLine('gst', bisLine, strong: true),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Container(
                  width: 132,
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        _invoiceTitle(invoice),
                        style: pw.TextStyle(
                          fontSize: 17.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      pw.Container(
                        width: 58,
                        height: 1,
                        margin: const pw.EdgeInsets.only(top: 6, bottom: 4),
                        color: _gold,
                      ),
                      pw.Text(
                        _metalInvoiceLabel(invoice),
                        style: pw.TextStyle(
                          fontSize: 10.8,
                          fontWeight: pw.FontWeight.bold,
                          color: _gold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 13),
                      _invoiceMeta('Invoice No.', invoice.invoiceNumber),
                      _invoiceMeta(
                        'Invoice Date',
                        _dateFormat.format(invoice.invoiceDate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _brandMark(PosInvoiceModel invoice) {
    final logoImage = invoice.shouldPrintBrandMark
        ? _loadLogoImage(invoice.shopLogoPath)
        : null;
    if (logoImage != null) {
      return pw.Container(
        height: 94,
        width: 104,
        alignment: pw.Alignment.center,
        child: pw.Image(
          logoImage,
          fit: pw.BoxFit.contain,
          alignment: pw.Alignment.center,
        ),
      );
    }

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Container(
          width: 46,
          height: 46,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _gold, width: 1),
            shape: pw.BoxShape.circle,
          ),
          child: pw.Text(
            _initials(_fallback(invoice.printShopName, invoice.shopName)),
            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
              color: _gold,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          _firstBrandWord(_fallback(invoice.printShopName, invoice.shopName)),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 19,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.2,
            color: _gold,
          ),
        ),
        pw.Text(
          'JEWELLERS',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(
            fontSize: 7.5,
            letterSpacing: 2,
            color: _gold,
          ),
        ),
      ],
    );
  }

  pw.Widget _customerAndInvoiceDetails(PosInvoiceModel invoice) {
    final status = PosInvoiceFinancialBreakdown.status(invoice);
    final statusColor = status.isDue ? _danger : _success;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _outlinedBox(
            'BILL TO',
            [
              _detailLine(
                'customer',
                'Customer Name',
                _fallback(invoice.customerName, 'Walk-in Customer'),
                valueFontSize: 10.6,
              ),
              if (invoice.customerMobile.trim().isNotEmpty)
                _detailLine(
                  'phone',
                  'Mobile',
                  _formatPhone(invoice.customerMobile),
                ),
              if (invoice.customerCity.trim().isNotEmpty)
                _addressDetailLine(
                    _formatCustomerAddress(invoice.customerCity)),
              if (invoice.customerGstin.trim().isNotEmpty)
                _detailLine(
                  'gst',
                  'Customer GSTIN (if applicable)',
                  invoice.customerGstin,
                  showDivider: false,
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: _outlinedBox(
            'INVOICE DETAILS',
            [
              _detailLine(
                'location',
                'Place of Supply',
                _stateText(invoice),
              ),
              if (!suppressPaymentSettlement)
                _detailLine(
                  'status',
                  'Payment Status',
                  status.label,
                  valueColor: statusColor,
                ),
              if (!suppressPaymentSettlement &&
                  status.isDue &&
                  invoice.promiseDate != null)
                _detailLine(
                  'calendar',
                  'Due Date',
                  _dueDate(invoice),
                  valueColor: _danger,
                  showDivider: false,
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _saleItemSections(PosInvoiceModel invoice) {
    final itemsByMetal = <MetalType, List<SaleItemModel>>{};
    for (final item in invoice.saleItems) {
      itemsByMetal.putIfAbsent(item.metal, () => []).add(item);
    }

    final sections = scopeService
        .collectMetals(invoice)
        .where((metal) => (itemsByMetal[metal] ?? const []).isNotEmpty)
        .map((metal) {
      final items = itemsByMetal[metal]!;
      return _metalSection(
        invoice: invoice,
        metal: metal,
        items: items,
        config: _configFor(metal),
      );
    }).toList(growable: false);

    if (sections.isEmpty) {
      return _emptySection('ITEM DETAILS', 'No sale items recorded.');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('ITEM DETAILS'),
        pw.SizedBox(height: 8),
        ...sections,
      ],
    );
  }

  pw.Widget _metalSection({
    required PosInvoiceModel invoice,
    required MetalType metal,
    required List<SaleItemModel> items,
    required BillSettings config,
  }) {
    final table = _itemsTable(invoice, items, config);
    final sectionTotal = items.fold<double>(
      0,
      (sum, item) => sum + item.totalValue,
    );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        table,
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: _line, width: 0.7),
              right: pw.BorderSide(color: _line, width: 0.7),
              bottom: pw.BorderSide(color: _line, width: 0.7),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Section Total (${metal.displayName})',
                style:
                    pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(width: 28),
              pw.Text(
                _amount(sectionTotal),
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _itemsTable(
    PosInvoiceModel invoice,
    List<SaleItemModel> items,
    BillSettings config,
  ) {
    final isWholesale = invoice.billingMode == BillingMode.wholesale;
    final headers = <String>[
      'S.No.',
      'Item Description',
      if (config.showHsnCode) 'HSN',
      if (config.showPurity) 'Purity',
      if (config.showGrossWt) 'Gross Wt.',
      if (config.showLessWt) 'Less Wt.',
      if (config.showNetWt) isWholesale ? 'Fine Wt.' : 'Net Wt.',
      if (config.showRate) 'Rate',
      if (config.showMaking || config.showMakingType)
        isWholesale ? 'Labour' : 'Making',
      if (config.showAmount) 'Amount',
    ];

    final rows = items.asMap().entries.map((entry) {
      final item = entry.value;
      return <String>[
        '${entry.key + 1}',
        _description(item, config),
        if (config.showHsnCode) _hsn(item),
        if (config.showPurity) _clean(item.purityCtrl.text),
        if (config.showGrossWt) _weight(item.grossCtrl.text),
        if (config.showLessWt) _weight(item.totalLessWt.toStringAsFixed(3)),
        if (config.showNetWt)
          _weight(
            isWholesale
                ? item.fineWt.toStringAsFixed(3)
                : item.netWt.toStringAsFixed(3),
          ),
        if (config.showRate) _plainAmount(item.rate),
        if (config.showMaking || config.showMakingType)
          _making(item, config, isWholesale: isWholesale),
        if (config.showAmount) _plainAmount(item.totalValue),
      ];
    }).toList(growable: false);

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.7),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _softGold),
          children: headers
              .map((header) => _tableCell(header, header: true))
              .toList(),
        ),
        ...rows.map(
          (row) => pw.TableRow(
            children: row.map(_tableCell).toList(),
          ),
        ),
      ],
    );
  }

  pw.Widget _tradeInSection(PosInvoiceModel invoice) {
    final rows = _visibleTradeInItems(invoice).asMap().entries.map((entry) {
      final item = entry.value;
      return [
        '${entry.key + 1}',
        item.metal.displayName,
        _fallback(item.descCtrl.text, '${item.metal.displayName} Settlement'),
        _weight(item.grossCtrl.text),
        _weight(item.lessCtrl.text),
        _weight(item.fineWt.toStringAsFixed(3)),
        _plainAmount(item.rate),
        _plainAmount(item.totalValue),
      ];
    }).toList(growable: false);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('CUSTOMER METAL SETTLEMENT'),
        pw.SizedBox(height: 8),
        _simpleTable(
          const [
            'S.No.',
            'Metal',
            'Description',
            'Gross',
            'Less',
            'Fine',
            'Rate',
            'Value'
          ],
          rows,
        ),
      ],
    );
  }

  pw.Widget _paymentAndTotals(PosInvoiceModel invoice) {
    final payments = PosInvoiceFinancialBreakdown.payments(invoice);
    final status = PosInvoiceFinancialBreakdown.status(invoice);
    final statusColor = status.isDue ? _danger : _success;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _outlinedBox(
            'PAYMENT RECEIVED',
            [
              if (payments.isEmpty)
                _pair('Payment Modes', 'No Payment Recorded')
              else
                for (final payment in payments)
                  _pair(payment.label, _amount(payment.amount)),
              _pair('Total Received', _amount(invoice.totalPaid)),
              _pair(
                'Payment Status',
                status.label,
                valueColor: statusColor,
              ),
              _pair(
                'Balance Outstanding',
                invoice.balanceDue > 0.005
                    ? _amount(invoice.balanceDue)
                    : 'Nil',
                valueColor: status.isDue ? _danger : _success,
              ),
              if (status.isDue && invoice.promiseDate != null)
                _pair(
                  'Due Date',
                  _dueDate(invoice),
                  valueColor: _danger,
                ),
              if (invoice.changeSettlementAmount > 0.005)
                _pair(
                  'Excess Payment Settlement',
                  _amount(invoice.changeSettlementAmount),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 36),
        pw.Expanded(
          child: _amountSummary(invoice),
        ),
      ],
    );
  }

  pw.Widget _amountSummary(PosInvoiceModel invoice) {
    final showGstBreakup = scopeService
        .collectMetals(invoice)
        .any((metal) => _configFor(metal).showGstBreakup);
    final summaryRows = PosInvoiceFinancialBreakdown.summaryRows(
      invoice,
      showGstBreakup: showGstBreakup,
    );

    return _outlinedBox(
      'AMOUNT SUMMARY',
      [
        for (final row in summaryRows) ...[
          if (row.isEmphasized)
            pw.Container(
              height: 1,
              margin: const pw.EdgeInsets.symmetric(vertical: 8),
              color: _gold,
            ),
          _summaryLine(
            row.isEmphasized ? row.label.toUpperCase() : row.label,
            _summaryAmount(row),
            strong: row.isEmphasized,
          ),
        ],
      ],
    );
  }

  pw.Widget _policyPreview(PosInvoiceModel invoice) {
    return _outlinedBox(
      'TERMS & POLICIES',
      _policyLines(invoice).take(4).map(_bulletLine).toList(growable: false),
    );
  }

  pw.Widget _policyPageFooter(PosInvoiceModel invoice, pw.Context context) {
    final shopName = _fallback(invoice.printShopName, invoice.shopName);
    final footerLines = _splitFooterLines(_footerMessage(invoice));
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.7)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (final line in footerLines)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: _policyText(
                          line,
                          maxWidth: _footerMessageMaxWidth,
                          style: pw.TextStyle(
                            fontSize: _footerMessageFontSize,
                            color: _ink,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Container(
                width: 128,
                child: pw.Column(
                  children: [
                    pw.Container(height: 12),
                    pw.Container(height: 0.7, color: _ink),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Authorized Signature',
                      style: pw.TextStyle(
                        fontSize: 10.4,
                        color: _ink,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _policyText(
                shopName.isEmpty ? _invoiceTitle(invoice) : shopName,
                maxWidth: _policyPageShopNameMaxWidth,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: 10.2,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(
                  fontSize: 9.8,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _policyPageContent(
    PosInvoiceModel invoice,
    List<PosInvoicePolicyEntry> entries,
  ) {
    if (entries.isEmpty) {
      final socialPanel = PosInvoiceShopPrintBlocks.policySocialPanel(
        invoice,
        textRenderer: textRenderer,
        borderColor: _line,
        accentColor: _gold,
      );
      return socialPanel == null ? const [] : [socialPanel];
    }

    final socialPanel = PosInvoiceShopPrintBlocks.policySocialPanel(
      invoice,
      textRenderer: textRenderer,
      borderColor: _line,
      accentColor: _gold,
    );

    final widgets = <pw.Widget>[
      for (var index = 0; index < entries.length; index++) ...[
        if (index > 0) pw.SizedBox(height: 12),
        ..._policyEntryWidgets(entries[index]),
      ],
    ];
    if (socialPanel != null) {
      widgets.add(pw.SizedBox(height: 14));
      widgets.add(socialPanel);
    }
    return widgets;
  }

  List<pw.Widget> _policyEntryWidgets(PosInvoicePolicyEntry entry) {
    final groups = PosInvoicePolicyCopy.bilingualGroups(entry.body);
    return [
      _policyEntryHeader(entry),
      for (final chunk in _policyBodyChunks(groups))
        _policyBodyContainer(
          chunk.groups,
          isLastChunk: chunk.isLast,
        ),
    ];
  }

  pw.Widget _policyEntryHeader(PosInvoicePolicyEntry entry) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: _softGold,
        border: pw.Border.all(color: _gold, width: 0.85),
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(8),
          topRight: pw.Radius.circular(8),
        ),
      ),
      padding: const pw.EdgeInsets.fromLTRB(11, 8, 11, 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _policyIconBadge(_policyIconKey(entry.section)),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              entry.title.toUpperCase(),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                color: _ink,
                fontSize: 13.8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _policyBodyContainer(
    List<List<String>> groups, {
    required bool isLastChunk,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _gold, width: 0.85),
        borderRadius: isLastChunk
            ? const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(8),
                bottomRight: pw.Radius.circular(8),
              )
            : null,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: groups.map(_policyBulletGroup).toList(growable: false),
      ),
    );
  }

  pw.Widget _policyIconBadge(String iconKey) {
    final image = policyIconImages[iconKey];
    if (image != null) {
      return pw.Container(
        width: 26,
        height: 26,
        alignment: pw.Alignment.center,
        child: pw.Image(image, fit: pw.BoxFit.contain),
      );
    }

    return pw.Container(
      width: 26,
      height: 26,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _gold, width: 0.9),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.SvgImage(svg: _headerIconSvg(iconKey)),
      ),
    );
  }

  String _policyIconKey(PosInvoicePolicySection section) {
    switch (section) {
      case PosInvoicePolicySection.termsAndConditions:
        return 'policy';
      case PosInvoicePolicySection.returnPolicy:
        return 'policy_return';
      case PosInvoicePolicySection.buybackPolicy:
        return 'policy_buyback';
    }
  }

  pw.Widget _policyBulletGroup(List<String> lines) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 3.8,
            height: 3.8,
            margin: const pw.EdgeInsets.only(top: 5.8, right: 8),
            decoration: const pw.BoxDecoration(
              color: _gold,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < lines.length; index++)
                  pw.Padding(
                    padding: pw.EdgeInsets.only(top: index == 0 ? 0 : 2),
                    child: _policyText(
                      lines[index],
                      maxWidth: 456,
                      style: pw.TextStyle(
                        fontSize: PosInvoicePolicyCopy.containsDevanagari(
                          lines[index],
                        )
                            ? _policyHindiFontSize
                            : _policyEnglishFontSize,
                        color: _ink,
                        fontWeight: pw.FontWeight.bold,
                        lineSpacing: 1.05,
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

  List<({List<List<String>> groups, bool isLast})> _policyBodyChunks(
    List<List<String>> groups,
  ) {
    const groupsPerChunk = 20;
    final chunks = <({List<List<String>> groups, bool isLast})>[];
    for (var start = 0; start < groups.length; start += groupsPerChunk) {
      final end = (start + groupsPerChunk).clamp(0, groups.length);
      chunks.add((
        groups: groups.sublist(start, end),
        isLast: end == groups.length,
      ));
    }
    return chunks;
  }

  pw.Widget _footer(PosInvoiceModel invoice) {
    final footer = _footerMessage(invoice);
    return pw.Column(
      children: [
        pw.Row(
          children: [
            pw.Expanded(child: _dottedRule()),
            pw.Container(
              width: 54,
              height: 54,
              margin: const pw.EdgeInsets.symmetric(horizontal: 18),
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _gold, width: 1),
                shape: pw.BoxShape.circle,
              ),
              child: pw.Text(
                _initials(invoice.printShopName.isEmpty
                    ? invoice.shopName
                    : invoice.printShopName),
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: _gold,
                ),
              ),
            ),
            pw.Expanded(child: _dottedRule()),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (footer.isNotEmpty)
                    for (final line in _splitFooterLines(footer))
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: _policyText(
                          line,
                          maxWidth: _footerMessageMaxWidth,
                          style: pw.TextStyle(
                            fontSize: _footerMessageFontSize,
                            color: _ink,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                ],
              ),
            ),
            pw.Container(
              width: 128,
              child: pw.Column(
                children: [
                  pw.Container(height: 24),
                  pw.Container(height: 0.7, color: _ink),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Authorized Signature',
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(
          width: 20,
          height: 20,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _gold, width: 0.8),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: pw.SvgImage(svg: _sectionIconSvg(title)),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12.2,
            fontWeight: pw.FontWeight.bold,
            color: _gold,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  pw.Widget _outlinedBox(String title, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _simpleTable(List<String> headers, List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.7),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _softGold),
          children: headers
              .map((header) => _tableCell(header, header: true))
              .toList(),
        ),
        ...rows
            .map((row) => pw.TableRow(children: row.map(_tableCell).toList())),
      ],
    );
  }

  pw.Widget _emptySection(String title, String message) {
    return _outlinedBox(title, [_smallText(message)]);
  }

  pw.Widget _tableCell(String value, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        value,
        textAlign: header ? pw.TextAlign.center : pw.TextAlign.left,
        maxLines: header ? 1 : 2,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          fontSize: header ? 8.4 : 8.3,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    );
  }

  pw.Widget _invoiceMeta(
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10.3,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Text(
            ':',
            style: pw.TextStyle(
              fontSize: 10.3,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Container(
            width: 70,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.left,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                fontSize: 10.7,
                fontWeight: pw.FontWeight.bold,
                color: valueColor ?? _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _headerAddressBlock(List<String> lines) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _headerIconBadge('location'),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 1),
                    child: _headerText(line, strong: true),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _headerInfoLine(
    String iconKey,
    String value, {
    bool strong = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _headerIconBadge(iconKey),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: _headerText(
              value,
              strong: strong,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _headerGstinLine(String gstin) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _headerIconBadge('gst'),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.RichText(
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              text: pw.TextSpan(
                style: pw.TextStyle(
                  fontSize: 9.8,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                ),
                children: [
                  pw.TextSpan(
                    text: 'GSTIN: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.TextSpan(
                    text: gstin,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _headerIconBadge(String iconKey) {
    return pw.Container(
      width: 18,
      height: 18,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _gold, width: 0.8),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(3),
        child: pw.SvgImage(svg: _headerIconSvg(iconKey)),
      ),
    );
  }

  pw.Widget _detailIconBadge(String iconKey) {
    return pw.Container(
      width: 19,
      height: 19,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _gold, width: 0.7),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(3.2),
        child: pw.SvgImage(svg: _headerIconSvg(iconKey)),
      ),
    );
  }

  String _sectionIconSvg(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('bill')) return _headerIconSvg('customer');
    if (normalized.contains('invoice')) return _headerIconSvg('invoice');
    if (normalized.contains('item')) return _headerIconSvg('items');
    if (normalized.contains('payment')) return _headerIconSvg('payment');
    if (normalized.contains('amount')) return _headerIconSvg('amount');
    if (normalized.contains('settlement')) return _headerIconSvg('settlement');
    if (normalized.contains('terms')) return _headerIconSvg('policy');
    return _headerIconSvg('invoice');
  }

  String _headerIconSvg(String iconKey) {
    const stroke = '#B8781A';
    switch (iconKey) {
      case 'location':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M12 21s6-5.2 6-11a6 6 0 0 0-12 0c0 5.8 6 11 6 11z"/>
  <circle cx="12" cy="10" r="2.2"/>
</svg>
''';
      case 'phone':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.7 19.7 0 0 1-8.6-3.1 19.1 19.1 0 0 1-5.9-5.9A19.7 19.7 0 0 1 2.2 4.2 2 2 0 0 1 4.2 2h3a2 2 0 0 1 2 1.7c.1 1 .4 2 .7 2.8a2 2 0 0 1-.5 2.1L8.1 9.9a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.5c.9.3 1.8.6 2.8.7A2 2 0 0 1 22 16.9z"/>
</svg>
''';
      case 'care':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 14v-2a8 8 0 0 1 16 0v2"/>
  <path d="M18 19c0 1.1-.9 2-2 2h-4"/>
  <rect x="3" y="12" width="4" height="6" rx="1.5"/>
  <rect x="17" y="12" width="4" height="6" rx="1.5"/>
</svg>
''';
      case 'mail':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3" y="5" width="18" height="14" rx="2"/>
  <path d="m3 7 9 6 9-6"/>
</svg>
''';
      case 'gst':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="4" y="3" width="16" height="18" rx="2"/>
  <path d="M8 8h8"/>
  <path d="M8 12h8"/>
  <path d="M8 16h4"/>
</svg>
''';
      case 'customer':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M20 21a8 8 0 0 0-16 0"/>
  <circle cx="12" cy="7" r="4"/>
</svg>
''';
      case 'invoice':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M7 3h10l3 3v15H4V3h3z"/>
  <path d="M16 3v4h4"/>
  <path d="M8 11h8"/>
  <path d="M8 15h6"/>
</svg>
''';
      case 'calendar':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3" y="5" width="18" height="16" rx="2"/>
  <path d="M16 3v4"/>
  <path d="M8 3v4"/>
  <path d="M3 10h18"/>
</svg>
''';
      case 'status':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="9"/>
  <path d="m8 12 2.5 2.5L16 9"/>
</svg>
''';
      case 'items':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m21 8-9-5-9 5 9 5 9-5z"/>
  <path d="M3 8v8l9 5 9-5V8"/>
  <path d="M12 13v8"/>
</svg>
''';
      case 'payment':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3" y="6" width="18" height="12" rx="2"/>
  <path d="M3 10h18"/>
  <path d="M7 15h4"/>
</svg>
''';
      case 'amount':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="4" y="3" width="16" height="18" rx="2"/>
  <path d="M8 8h8"/>
  <path d="M8 12h8"/>
  <path d="M8 16h5"/>
</svg>
''';
      case 'settlement':
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M7 7h10"/>
  <path d="m14 4 3 3-3 3"/>
  <path d="M17 17H7"/>
  <path d="m10 14-3 3 3 3"/>
  <path d="M6.5 7 8 5.5 9.5 7 8 8.5 6.5 7z"/>
  <path d="M14.5 17 16 15.5 17.5 17 16 18.5 14.5 17z"/>
</svg>
''';
      case 'policy':
        return '''
<svg width="22" height="22" viewBox="0 0 64 64" fill="none" stroke="$stroke" stroke-width="4.2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M19 10h21l9 9v31H19V10z"/>
  <path d="M40 10v10h9"/>
  <path d="M25 28h17"/>
  <path d="M25 36h13"/>
  <path d="M40 34l8-3 8 3v7.5c0 5.8-3.6 9.8-8 11.5-4.4-1.7-8-5.7-8-11.5V34z"/>
  <path d="m44.5 42 2.4 2.5 5-5.5"/>
</svg>
''';
      case 'policy_return':
        return '''
<svg width="22" height="22" viewBox="0 0 64 64" fill="none" stroke="$stroke" stroke-width="5" stroke-linecap="round" stroke-linejoin="round">
  <path d="M19 26h26"/>
  <path d="M37 16l10 10-10 10"/>
  <path d="M45 38H19"/>
  <path d="M27 28 17 38l10 10"/>
</svg>
''';
      case 'policy_buyback':
        return '''
<svg width="22" height="22" viewBox="0 0 64 64" fill="none" stroke="$stroke" stroke-width="4.6" stroke-linecap="round" stroke-linejoin="round">
  <path d="M17 22h30"/>
  <path d="M39 13l10 9-10 9"/>
  <path d="M47 42H17"/>
  <path d="M25 33 15 42l10 9"/>
  <circle cx="32" cy="32" r="10"/>
  <path d="M27 25h11"/>
  <path d="M27 30h11"/>
  <path d="M29 25c7.5 0 7.5 10 0 10"/>
  <path d="M29 35l8 8"/>
</svg>
''';
      default:
        return '''
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="8"/>
</svg>
''';
    }
  }

  pw.Widget _headerText(
    String value, {
    bool strong = false,
    PdfColor? color,
  }) {
    return pw.Text(
      value,
      maxLines: 1,
      overflow: pw.TextOverflow.clip,
      style: pw.TextStyle(
        fontSize: 10.2,
        fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.bold,
        color: color ?? _ink,
      ),
    );
  }

  pw.Widget _detailLine(
    String iconKey,
    String label,
    String value, {
    PdfColor? valueColor,
    double valueFontSize = 10.4,
    int valueMaxLines = 2,
    bool showDivider = true,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: showDivider
            ? const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _line, width: 0.45),
                ),
              )
            : null,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _detailIconBadge(iconKey),
            pw.SizedBox(width: 8),
            pw.SizedBox(
              width: 82,
              child: pw.Text(
                label,
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: 9.8,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
            ),
            pw.SizedBox(width: 5),
            pw.Text(
              ':',
              style: pw.TextStyle(
                fontSize: 10.1,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.SizedBox(width: 7),
            pw.Expanded(
              child: pw.Text(
                value,
                maxLines: valueMaxLines,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: valueColor ?? _ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _addressDetailLine(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: _line, width: 0.45),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _detailIconBadge('location'),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Address',
                  style: pw.TextStyle(
                    fontSize: 9.8,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 27),
              child: pw.Text(
                value,
                maxLines: 4,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: 10.2,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                  lineSpacing: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pair(
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                fontSize: 10.2,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ),
          pw.Text(
            ':',
            style: pw.TextStyle(
              fontSize: 10.2,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            width: 108,
            child: pw.Text(
              value,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                fontSize: 10.2,
                fontWeight: pw.FontWeight.bold,
                color: valueColor ?? _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryLine(
    String label,
    String value, {
    bool strong = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: strong ? 13.2 : 10.4,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: strong ? 13.6 : 10.4,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _bulletLine(String value) {
    final text = '- $value';
    const style = pw.TextStyle(fontSize: 8.3, color: _ink);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: _policyText(
        text,
        maxWidth: 470,
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
        style: style,
      ),
    );
  }

  pw.Widget _policyText(
    String value, {
    required pw.TextStyle style,
    required double maxWidth,
    int? maxLines,
    pw.TextOverflow? overflow,
  }) {
    final renderer = textRenderer;
    if (renderer == null) {
      return pw.Text(
        value,
        maxLines: maxLines,
        overflow: overflow,
        style: style,
      );
    }
    return renderer.text(
      value,
      maxWidth: maxWidth,
      maxLines: maxLines,
      overflow: overflow,
      style: style,
    );
  }

  pw.Widget _smallText(String value) {
    return pw.Text(value,
        style: const pw.TextStyle(fontSize: 8.4, color: _ink));
  }

  pw.Widget _dottedRule() {
    return pw.Row(
      children: List.generate(
        24,
        (_) => pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 1),
            height: 0.7,
            color: _line,
          ),
        ),
      ),
    );
  }

  BillSettings _configFor(MetalType metal) {
    return metalPrintSettings[metal] ??
        BillSettings(showHsnCode: true, showMakingType: true);
  }

  List<TradeInItemModel> _visibleTradeInItems(PosInvoiceModel invoice) {
    return invoice.tradeInItems
        .where((item) => _configFor(item.metal).showExchangeBreakdown)
        .toList(growable: false);
  }

  List<String> _addressLines(PosInvoiceModel invoice) {
    final address = _fallback(
      invoice.shopPrintValue('business_address'),
      invoice.printShopAddress,
    );
    if (address.trim().isEmpty) return const [];

    final parts = address
        .split(',')
        .map(_clean)
        .where((part) => part.isNotEmpty)
        .where((part) => part.toLowerCase() != 'india')
        .toList(growable: false);

    if (parts.length <= 2) return [_formatAddressTail(parts)];

    final pincodeIndex = parts.indexWhere(
      (part) => RegExp(r'\d{6}').hasMatch(part),
    );
    if (pincodeIndex > 1) {
      final splitAfter = pincodeIndex <= 3 ? 2 : pincodeIndex - 2;
      final firstLineParts = parts.take(splitAfter).toList();
      final secondLineParts = parts.skip(firstLineParts.length).toList();
      return [
        '${firstLineParts.join(', ')},',
        _formatAddressTail(secondLineParts),
      ];
    }

    final splitIndex = parts.length > 4 ? parts.length - 3 : parts.length - 2;
    return [
      '${parts.take(splitIndex).join(', ')},',
      _formatAddressTail(parts.skip(splitIndex).toList()),
    ];
  }

  String _shopPhoneLine(PosInvoiceModel invoice) {
    final primaryPhone = _fallback(
      invoice.shopPrintValue('mobile_number'),
      invoice.printShopPhone,
    );
    final whatsapp = invoice.shopPrintValue('whatsapp_number');
    final customerCare = invoice.shopPrintValue('help_desk_number');
    final callValue = _formatPhone(primaryPhone);
    final whatsappValue = _formatPhone(whatsapp);
    final careValue = _formatPhone(customerCare);
    final primaryValue = callValue.isNotEmpty ? callValue : whatsappValue;
    final values = <String>[
      if (primaryValue.isNotEmpty) primaryValue,
      if (careValue.isNotEmpty && careValue != primaryValue) careValue,
    ];

    return values.join('  |  ');
  }

  String _shopEmailLine(PosInvoiceModel invoice) {
    final email = invoice.shopPrintValue('business_email');
    return email.trim();
  }

  String _shopGstinLine(PosInvoiceModel invoice) {
    final gstin = _fallback(
      invoice.shopPrintValue('gstin'),
      invoice.printShopGstin,
    );
    if (gstin.trim().isEmpty ||
        gstin.trim().toLowerCase() == 'not registered') {
      return '';
    }
    return gstin.trim();
  }

  String _shopBisLine(PosInvoiceModel invoice) {
    final value = PosInvoiceShopPrintBlocks.bisRegistrationNumber(invoice);
    if (value.isEmpty) return '';
    return 'BIS Registration Number: $value';
  }

  String _formatAddressTail(List<String> parts) {
    final cleaned = parts.map(_clean).where((part) => part.isNotEmpty).toList();
    if (cleaned.isEmpty) return '';
    final pincodeIndex =
        cleaned.indexWhere((part) => RegExp(r'\d{6}').hasMatch(part));
    if (pincodeIndex > 0) {
      final prefix = cleaned.take(pincodeIndex).join(', ');
      return '$prefix - ${cleaned.skip(pincodeIndex).join(', ')}';
    }
    return cleaned.join(', ');
  }

  String _formatCustomerAddress(String value) {
    return _formatAddressTail(
      value
          .split(',')
          .map(_clean)
          .where((part) => part.isNotEmpty)
          .toList(growable: false),
    );
  }

  String _formatPhone(String value) {
    final cleaned = _clean(value);
    if (cleaned.isEmpty) return '';
    final digits = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+91 ${digits.substring(2, 7)} ${digits.substring(7)}';
    }
    return cleaned;
  }

  List<String> _policyLines(PosInvoiceModel invoice) {
    return _policyEntries(invoice)
        .expand((entry) => PosInvoicePolicyCopy.lines(entry.body))
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
  }

  List<PosInvoicePolicyEntry> _policyEntries(PosInvoiceModel invoice) {
    return PosInvoicePolicyCopy.entries(
      invoice: invoice,
      scopeService: scopeService,
      metalPrintSettings: metalPrintSettings,
    );
  }

  BillSettings _primaryConfig(PosInvoiceModel invoice) {
    final metals = scopeService.collectMetals(invoice);
    if (metals.isEmpty) return BillSettings();
    return _configFor(metals.first);
  }

  String _footerMessage(PosInvoiceModel invoice) {
    final config = _primaryConfig(invoice);
    if (!config.printFooterMessage) return '';
    return config.footerMessage.trim();
  }

  List<String> _splitFooterLines(String value) {
    return value
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map(_clean)
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  String _invoiceTitle(PosInvoiceModel invoice) {
    return invoice.billType == BillType.gst ? 'TAX INVOICE' : 'SALES INVOICE';
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

  String _metalInvoiceLabel(PosInvoiceModel invoice) {
    final metals = scopeService.collectMetals(invoice);
    if (metals.length == 1) {
      return '${metals.first.displayName.toUpperCase()} INVOICE';
    }
    return 'JEWELLERY INVOICE';
  }

  String _stateText(PosInvoiceModel invoice) {
    return _fallback(invoice.placeOfSupply, invoice.customerStateCode);
  }

  String _dueDate(PosInvoiceModel invoice) {
    final date = invoice.promiseDate;
    return date == null ? '-' : _dateFormat.format(date);
  }

  String _description(SaleItemModel item, BillSettings config) {
    final parts = <String>[
      _fallback(item.descCtrl.text, item.metal.displayName),
      if (config.showHuid && item.huidText.trim().isNotEmpty)
        'HUID ${item.huidText.trim()}',
    ];
    return parts.join(' | ');
  }

  String _hsn(SaleItemModel item) {
    final value = item.invoiceHsnCode?.trim() ?? '';
    return value.isEmpty ? '-' : value;
  }

  String _making(
    SaleItemModel item,
    BillSettings config, {
    required bool isWholesale,
  }) {
    final amount = isWholesale ? item.wholesaleLabourAmt : item.makingAmt;

    // Making Rate Type has priority when enabled: show the entered rate
    // (for example 12%, 15%, 120/g) instead of the calculated amount.
    if (config.showMakingType) {
      final input = double.tryParse(
            item.makingCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0.0;
      if (input > 0) {
        return '${_formatMakingInput(input)}${_makingUnit(item.makingChargeType)}';
      }
    }

    // Making Rate Type OFF -> show the calculated Making Amount only.
    // This prevents values such as 534.36% when the amount is 534.36.
    if (config.showMaking) {
      return _plainAmount(amount);
    }

    return '';
  }

  String _formatMakingInput(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.0001) {
      return rounded.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _makingUnit(MakingChargeType type) {
    switch (type) {
      case MakingChargeType.perGram:
        return '/g';
      case MakingChargeType.perKg:
        return '/kg';
      case MakingChargeType.perPiece:
        return '/pc';
      case MakingChargeType.percentage:
        return '%';
    }
  }

  String _weight(String value) {
    final number = double.tryParse(value.trim());
    if (number == null) return _fallback(value, '-');
    return '${number.toStringAsFixed(3)} g';
  }

  String _amount(double value) => 'Rs ${_amountFormat.format(value)}';

  String _plainAmount(double value) => _amountFormat.format(value);

  String _summaryAmount(PosInvoiceAmountSummaryEntry row) {
    final prefix = row.isDeduction ? '- ' : '';
    return '$prefix${_amount(row.amount.abs())}';
  }

  String _firstBrandWord(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    return words.isEmpty || words.first.isEmpty
        ? 'LOTUS'
        : words.first.toUpperCase();
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'LS';
    final initials = words.take(2).map((word) => word[0].toUpperCase()).join();
    return initials.isEmpty ? 'LS' : initials;
  }

  String _fallback(String value, String fallback) {
    final cleaned = _clean(value);
    return cleaned.isEmpty ? fallback : cleaned;
  }

  String _clean(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  pw.MemoryImage? _loadLogoImage(String rawPath) {
    final bytes = _readLogoBytes(rawPath);
    return bytes == null ? null : pw.MemoryImage(bytes);
  }

  Uint8List? _readLogoBytes(String rawPath) {
    var path = rawPath.trim();
    if (path.isEmpty) return null;

    try {
      final uri = Uri.tryParse(path);
      if (uri != null && uri.isScheme('file')) {
        path = uri.toFilePath();
      }

      final candidates = <File>[
        File(path),
        if (!_isAbsolutePath(path))
          File('${Directory.current.path}${Platform.pathSeparator}$path'),
      ];

      for (final file in candidates) {
        if (file.existsSync()) {
          return file.readAsBytesSync();
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  bool _isAbsolutePath(String path) {
    if (path.startsWith('/') || path.startsWith(r'\')) return true;
    return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
  }
}
