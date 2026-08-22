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
import 'pos_invoice_pdf_text_renderer.dart';
import 'pos_invoice_shop_print_blocks.dart';
import 'pos_invoice_print_config.dart';
import 'pos_invoice_shop_header_details.dart';

class PosLotusClassicInvoicePdfLayout {
  static final _amountFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final _dateFormat = DateFormat('dd MMM yyyy');

  static const _navy = PdfColor.fromInt(0xFF172437);
  static const _gold = PdfColor.fromInt(0xFFC89421);
  static const _goldLight = PdfColor.fromInt(0xFFFBF6E9);
  static const _ink = PdfColor.fromInt(0xFF111827);
  static const _line = PdfColor.fromInt(0xFFD8DEE8);
  static const _surface = PdfColor.fromInt(0xFFF6F8FB);
  static const _success = PdfColor.fromInt(0xFF166534);
  static const _danger = PdfColor.fromInt(0xFFB91C1C);

  final PosInvoiceScopeService scopeService;
  final Map<MetalType, BillSettings> metalPrintSettings;
  final PosInvoicePdfTextRenderer? textRenderer;

  const PosLotusClassicInvoicePdfLayout({
    required this.scopeService,
    required this.metalPrintSettings,
    this.textRenderer,
  });

  pw.Widget build(
    PosInvoiceModel invoice, {
    bool includePolicyBlock = true,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _header(invoice),
        pw.SizedBox(height: 10),
        _customerAndAmountPanel(invoice),
        pw.SizedBox(height: 10),
        _sectionHeading(
          number: '01',
          title: 'ITEM DETAILS',
          subtitle: '',
        ),
        pw.SizedBox(height: 8),
        _saleItemSections(invoice),
        if (_visibleTradeInItems(invoice).isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _sectionHeading(
            number: '02',
            title: 'CUSTOMER METAL SETTLEMENT',
            subtitle: 'Customer metal adjustment recorded against this invoice',
          ),
          pw.SizedBox(height: 8),
          _tradeInTable(invoice),
        ],
        pw.SizedBox(height: 10),
        _totalsAndPayment(invoice),
        pw.SizedBox(height: 10),
        if (includePolicyBlock) ...[
          _policyBlock(invoice),
          ..._shopPrintSocialSection(invoice),
        ],
        pw.Spacer(),
        _footer(invoice),
      ],
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
    return [section, pw.SizedBox(height: 8)];
  }

  pw.Widget _header(PosInvoiceModel invoice) {
    final shopHeader = PosInvoiceShopHeaderDetails.fromInvoice(invoice);
    final metadata = <({String label, String value})>[
      (label: 'INVOICE NUMBER', value: invoice.invoiceNumber),
      (label: 'INVOICE DATE', value: _dateFormat.format(invoice.invoiceDate)),
      (label: 'BILL TYPE', value: _billTypeLabel(invoice)),
      (label: 'MODULE', value: 'New Sales'),
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
                if (invoice.shouldPrintBrandMark) ...[
                  _brandMark(invoice),
                  pw.SizedBox(width: 14),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (shopHeader.shopName.isNotEmpty)
                        pw.Text(
                          shopHeader.shopName,
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 19,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      if (shopHeader.shopName.isNotEmpty)
                        pw.SizedBox(height: 3),
                      for (final line in shopHeader.lines.take(4)) ...[
                        pw.SizedBox(height: 2),
                        _shopHeaderLine(line),
                      ],
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
                        _invoiceTitle(invoice),
                        style: pw.TextStyle(
                          color: _navy,
                          fontSize: 8.7,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.55,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      _billTypeLabel(invoice).toUpperCase(),
                      style: pw.TextStyle(
                        color: _gold,
                        fontSize: 6.7,
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
                  if (index > 0)
                    pw.Container(
                      width: 0.7,
                      height: 27,
                      margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                      color: _gold,
                    ),
                  pw.Expanded(
                    flex: index == 0 ? 2 : 1,
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

  pw.Widget _brandMark(PosInvoiceModel invoice) {
    final details = PosInvoiceShopHeaderDetails.fromInvoice(invoice);
    final initials = _initials(details.shopName);
    final logoImage = _loadLogoImage(invoice.shopLogoPath);
    final logoShape = invoice.shopLogoShape.trim().toLowerCase();
    final isSquare = logoShape != 'circle';
    final content = logoImage == null
        ? pw.Container(
            alignment: pw.Alignment.center,
            color: _gold,
            child: pw.Text(
              initials,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          )
        : pw.Container(
            color: PdfColors.white,
            child: pw.Image(
              logoImage,
              fit: pw.BoxFit.cover,
            ),
          );
    final clipped = isSquare
        ? pw.ClipRRect(
            horizontalRadius: 7,
            verticalRadius: 7,
            child: content,
          )
        : pw.ClipOval(child: content);

    return pw.Container(
      width: 52,
      height: 52,
      padding: const pw.EdgeInsets.all(2),
      decoration: pw.BoxDecoration(
        color: _gold,
        shape: isSquare ? pw.BoxShape.rectangle : pw.BoxShape.circle,
        borderRadius:
            isSquare ? const pw.BorderRadius.all(pw.Radius.circular(8)) : null,
      ),
      child: clipped,
    );
  }

  pw.Widget _shopHeaderLine(PosInvoiceShopHeaderLine line) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '${line.label}: ',
          style: pw.TextStyle(
            color: _gold,
            fontSize: 7.4,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            line.value,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 7.4,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
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
            fontSize: 7.2,
            letterSpacing: 0.45,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.FittedBox(
          fit: pw.BoxFit.scaleDown,
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            value,
            maxLines: 1,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _customerAndAmountPanel(PosInvoiceModel invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            height: 105,
            padding: const pw.EdgeInsets.all(13),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _line),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _eyebrow('CUSTOMER DETAILS'),
                pw.SizedBox(height: 6),
                pw.Text(
                  _fallback(invoice.customerName, 'Walk-in Customer'),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
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
                        value:
                            _fallback(invoice.customerMobile, 'Not provided'),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: _metaPair(
                        label: 'ADDRESS',
                        value: _fallback(invoice.customerCity, 'Not provided'),
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
            height: 105,
            padding: const pw.EdgeInsets.all(13),
            decoration: pw.BoxDecoration(
              color: _goldLight,
              border: pw.Border.all(color: _gold, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _eyebrow(_amountPanelLabel(invoice), color: _gold),
                pw.SizedBox(height: 6),
                pw.Text(
                  _signedAmount(invoice.netPayable),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    color: _navy,
                    fontSize: 18.5,
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
                      color: const PdfColor.fromInt(0xFFEAD6A0),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'PAYMENT STATUS',
                        style: pw.TextStyle(
                          color: _ink,
                          fontSize: 6.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      pw.Text(
                        _paymentStatusLabel(invoice),
                        style: pw.TextStyle(
                          color: _statusColor(invoice),
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
              if (subtitle.trim().isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  subtitle,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
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
      final config = _getMetalConfig(metal);
      final sectionTotal =
          items.fold(0.0, (sum, item) => sum + item.totalValue);
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _metalSectionHeader(metal, sectionTotal),
            _itemsTable(invoice, items, config),
          ],
        ),
      );
    }).toList();

    if (sections.isEmpty) {
      return _emptyPanel('No sale items recorded.');
    }
    return pw.Column(children: sections);
  }

  pw.Widget _metalSectionHeader(MetalType metal, double sectionTotal) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const pw.BoxDecoration(
        color: _surface,
        border: pw.Border(
          top: pw.BorderSide(color: _line, width: 0.7),
          left: pw.BorderSide(color: _line, width: 0.7),
          right: pw.BorderSide(color: _line, width: 0.7),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${metal.displayName.toUpperCase()} ITEM DETAILS',
            style: pw.TextStyle(
              color: _ink,
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Section Total: ${_amount(sectionTotal)}',
            style: pw.TextStyle(
              color: _ink,
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _itemsTable(
    PosInvoiceModel invoice,
    List<SaleItemModel> items,
    BillSettings config,
  ) {
    final isWholesale = invoice.billingMode == BillingMode.wholesale;
    final headers = <String>[
      'S/N',
      'Item Description',
      if (config.showHsnCode) 'HSN',
      if (config.showPurity) 'Purity',
      if (config.showGrossWt) 'Gross',
      if (config.showLessWt) 'Less',
      if (config.showNetWt) isWholesale ? 'Fine' : 'Net',
      if (config.showFineWeight && !isWholesale) 'Fine',
      if (config.showRate) 'Rate',
      if (config.showMaking || config.showMakingType)
        isWholesale ? 'Labour' : 'Making',
      if (config.showAmount) 'Amount',
    ];

    final rows = items.asMap().entries.map((entry) {
      final item = entry.value;
      final row = <String>[
        '${entry.key + 1}',
        _itemDescription(item, config),
        if (config.showHsnCode) _hsnCode(item),
        if (config.showPurity) _formatPurity(item),
        if (config.showGrossWt) _weightText(item.grossCtrl.text),
        if (config.showLessWt) _weightText(item.totalLessWt.toStringAsFixed(3)),
        if (config.showNetWt)
          _weightText(
            isWholesale
                ? item.fineWt.toStringAsFixed(3)
                : item.netWt.toStringAsFixed(3),
          ),
        if (config.showFineWeight && !isWholesale)
          _weightText(item.fineWt.toStringAsFixed(3)),
        if (config.showRate) _amount(item.rate),
        if (config.showMaking || config.showMakingType)
          _formatMakingCharge(item, config, isWholesale: isWholesale),
        if (config.showAmount) _amount(item.totalValue),
      ];
      return row;
    }).toList();

    return _table(headers, rows);
  }

  pw.Widget _tradeInTable(PosInvoiceModel invoice) {
    final visibleItems = _visibleTradeInItems(invoice);
    const headers = [
      'S/N',
      'Metal',
      'Item',
      'Gross',
      'Less',
      'Fine',
      'Rate',
      'Deduction',
    ];

    final rows = visibleItems.asMap().entries.map((entry) {
      final item = entry.value;
      return [
        '${entry.key + 1}',
        item.metal.displayName,
        _fallback(item.descCtrl.text, '${item.metal.displayName} Settlement'),
        _weightText(item.grossCtrl.text),
        _weightText(item.lessCtrl.text),
        _weightText(item.fineWt.toStringAsFixed(3)),
        _amount(item.rate),
        _amount(item.totalValue),
      ];
    }).toList();

    return _table(headers, rows);
  }

  pw.Widget _table(List<String> headers, List<List<String>> rows) {
    return pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: _navy, width: 0.9),
        bottom: pw.BorderSide(color: _line, width: 0.6),
        left: pw.BorderSide(color: _line, width: 0.6),
        right: pw.BorderSide(color: _line, width: 0.6),
        horizontalInside: pw.BorderSide(color: _line, width: 0.45),
        verticalInside: pw.BorderSide(color: _line, width: 0.45),
      ),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _navy),
          children: headers.map(_headerCell).toList(),
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

  pw.Widget _totalsAndPayment(PosInvoiceModel invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: _paymentBlock(invoice),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          flex: 4,
          child: _totalsBlock(invoice),
        ),
      ],
    );
  }

  pw.Widget _totalsBlock(PosInvoiceModel invoice) {
    final showGstBreakup = scopeService
        .collectMetals(invoice)
        .any((metal) => _getMetalConfig(metal).showGstBreakup);
    final totalLines = PosInvoiceFinancialBreakdown.summaryRows(
      invoice,
      showGstBreakup: showGstBreakup,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
      ),
      child: pw.Column(
        children: [
          for (final row in totalLines) ...[
            if (row.isEmphasized) pw.Divider(color: _gold, thickness: 0.8),
            _totalLine(
              row.label,
              row.amount,
              isBold: row.isEmphasized,
              isDeduction: row.isDeduction,
              isGrand: row.isEmphasized,
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _paymentBlock(PosInvoiceModel invoice) {
    final payments = PosInvoiceFinancialBreakdown.payments(invoice);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _surface,
        border: pw.Border.all(color: _line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
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
                  color: _ink,
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              _statusBadge(invoice),
            ],
          ),
          pw.SizedBox(height: 8),
          if (payments.isEmpty)
            pw.Text(
              'No payment has been recorded.',
              style: const pw.TextStyle(color: _ink, fontSize: 8.5),
            )
          else
            pw.Wrap(
              spacing: 7,
              runSpacing: 6,
              children: payments
                  .map((payment) => _paymentChip(payment.label, payment.amount))
                  .toList(),
            ),
          if (invoice.changeSettlementMethod != null &&
              invoice.changeSettlementAmount > 0.5) ...[
            pw.SizedBox(height: 8),
            _changeSettlement(invoice),
          ],
          pw.SizedBox(height: 8),
          _paymentSummary(invoice),
        ],
      ),
    );
  }

  pw.Widget _policyBlock(PosInvoiceModel invoice) {
    final entries = PosInvoicePolicyCopy.entries(
      invoice: invoice,
      scopeService: scopeService,
      metalPrintSettings: metalPrintSettings,
    );

    if (entries.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0) pw.SizedBox(height: 6),
            pw.Text(
              entries[index].title.toUpperCase(),
              style: pw.TextStyle(
                color: _gold,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.25,
              ),
            ),
            pw.SizedBox(height: 2),
            ..._policyBodyLines(entries[index].body),
          ],
        ],
      ),
    );
  }

  List<pw.Widget> _policyBodyLines(String body) {
    const style = pw.TextStyle(
      color: _ink,
      fontSize: 8,
      lineSpacing: 1.3,
    );
    final lines = PosInvoicePolicyCopy.lines(body);
    return [
      for (final rawLine in lines)
        if (rawLine.trim().isEmpty)
          pw.SizedBox(height: 4)
        else
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2.5),
            child: _policyText(rawLine, style: style, maxWidth: 500),
          ),
    ];
  }

  pw.Widget _policyText(
    String value, {
    required pw.TextStyle style,
    required double maxWidth,
  }) {
    final renderer = textRenderer;
    if (renderer == null) {
      return pw.Text(value, style: style);
    }
    return renderer.text(value, style: style, maxWidth: maxWidth);
  }

  pw.Widget _footer(PosInvoiceModel invoice) {
    final footerMessages = scopeService
        .collectMetals(invoice)
        .map((metal) {
          final config = _getMetalConfig(metal);
          return config.printFooterMessage ? config.footerMessage.trim() : '';
        })
        .where(_hasPrintableCopy)
        .toSet()
        .toList();

    return pw.Column(
      children: [
        pw.Divider(color: _line, height: 1),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Text(
                footerMessages.join(' | '),
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
                style: const pw.TextStyle(color: _ink, fontSize: 7.5),
              ),
            ),
            pw.SizedBox(width: 24),
            pw.Container(
              width: 150,
              padding: const pw.EdgeInsets.only(top: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: _navy, width: 0.7)),
              ),
              child: pw.Text(
                'Authorized Signature',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: _ink,
                  fontSize: 8.2,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(
          color: _ink,
          fontSize: 7.7,
          lineSpacing: 1.1,
        ),
      ),
    );
  }

  pw.Widget _eyebrow(String text, {PdfColor color = _gold}) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        color: color,
        fontSize: 7.2,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.42,
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
            color: _ink,
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

  pw.Widget _totalLine(
    String label,
    double amount, {
    bool isBold = false,
    bool isDeduction = false,
    bool isGrand = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: _ink,
              fontSize: isGrand ? 11.5 : 8.8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '${isDeduction ? '- ' : ''}${_amount(amount.abs())}',
            style: pw.TextStyle(
              color: _ink,
              fontSize: isGrand ? 12.5 : 8.8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _paymentChip(String label, double amount) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: _line, width: 0.55),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: const pw.TextStyle(color: _ink, fontSize: 8.4),
            ),
            pw.TextSpan(
              text: _amount(amount),
              style: pw.TextStyle(
                color: _ink,
                fontSize: 8.4,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _statusBadge(PosInvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _statusFill(invoice),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Text(
        _paymentStatusLabel(invoice),
        style: pw.TextStyle(
          color: _statusColor(invoice),
          fontSize: 8.4,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _changeSettlement(PosInvoiceModel invoice) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: pw.BoxDecoration(
        color: _goldLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: _gold, width: 0.55),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'EXCESS PAYMENT SETTLEMENT',
            style: pw.TextStyle(
              color: _ink,
              fontSize: 7.8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          _miniRow('Excess Amount', _amount(invoice.changeSettlementAmount)),
          _miniRow(
            'Settlement',
            _changeSettlementLabel(invoice.changeSettlementMethod),
          ),
          if (invoice.changeSettlementPaymentMode != null)
            _miniRow(
              'Received Through',
              _paymentModeLabel(invoice.changeSettlementPaymentMode),
            ),
        ],
      ),
    );
  }

  pw.Widget _paymentSummary(PosInvoiceModel invoice) {
    final hasDue = invoice.balanceDue > 0.5;
    if (hasDue) {
      return pw.Column(
        children: [
          _miniRow('Total Received', _amount(invoice.totalPaid)),
          _miniRow(
            'Balance Outstanding',
            _amount(invoice.balanceDue),
            valueColor: _danger,
          ),
          if (invoice.promiseDate != null)
            _miniRow(
              'Due Date',
              _dateFormat.format(invoice.promiseDate!),
              valueColor: _danger,
            ),
        ],
      );
    }
    if (_isScopedSectionExcess(invoice)) {
      return _miniRow(
          'Adjusted in Final Bill', _amount(invoice.netPayable.abs()));
    }
    if (invoice.netPayable < -0.5) {
      return _miniRow('Customer Credit', _amount(invoice.netPayable.abs()));
    }
    return _miniRow(
      'Payment Status',
      'PAID',
      valueColor: _success,
    );
  }

  pw.Widget _miniRow(
    String label,
    String value, {
    PdfColor? labelColor,
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(color: labelColor ?? _ink, fontSize: 8),
          ),
          pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: valueColor ?? _ink,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _emptyPanel(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _surface,
        border: pw.Border.all(color: _line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
      ),
      child: pw.Text(
        message,
        style: const pw.TextStyle(color: _ink, fontSize: 9),
      ),
    );
  }

  String _invoiceTitle(PosInvoiceModel invoice) {
    final metals = scopeService.collectMetals(invoice);
    if (metals.length == 1) {
      return '${metals.first.displayName.toUpperCase()} INVOICE';
    }
    return 'SALES INVOICE';
  }

  String _billTypeLabel(PosInvoiceModel invoice) {
    if (invoice.billType != BillType.gst) return 'Sales Invoice';
    return invoice.gstPricingMode == GstPricingMode.inclusive
        ? 'Legacy GST Included Tax Invoice'
        : 'Tax Invoice';
  }

  String _itemDescription(SaleItemModel item, BillSettings config) {
    final parts = <String>[
      _fallback(item.descCtrl.text, '${item.metal.displayName} Item'),
    ];
    if (config.showHuid && item.huidText.trim().isNotEmpty) {
      parts.add('HUID: ${item.huidText.trim()}');
    }
    if (config.showPcs && item.pcs > 1) {
      parts.add('${item.pcs} pcs');
    }
    return parts.join('\n');
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
    final amount = isWholesale ? item.wholesaleLabourAmt : item.makingAmt;

    if (config.showMakingType) {
      if (input <= 0) return '-';
      return '${_compact(input)}${item.makingChargeType.symbol}';
    }
    return _amount(amount);
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
          return '${_compact(ktVal)}KT';
        }
        return text.isNotEmpty ? text : '-';
      case MetalType.silver:
        if (text.isNotEmpty) return text;
        return tunch > 0 ? '${_compact(tunch)}%' : '-';
      case MetalType.platinum:
        if (text.isNotEmpty) return text;
        return tunch > 0 ? '${_compact(tunch)}%' : '-';
      case MetalType.diamond:
        if (text.isNotEmpty) return text;
        return tunch > 0 ? '${_compact(tunch)} ct' : '-';
    }
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

  PdfColor _statusColor(PosInvoiceModel invoice) {
    final status = PosInvoiceFinancialBreakdown.status(invoice);
    return status.isDue ? _danger : _success;
  }

  PdfColor _statusFill(PosInvoiceModel invoice) {
    final status = PosInvoiceFinancialBreakdown.status(invoice);
    return status.isDue
        ? const PdfColor.fromInt(0xFFFEE2E2)
        : const PdfColor.fromInt(0xFFDCFCE7);
  }

  BillSettings _getMetalConfig(MetalType metal) {
    return metalPrintSettings[metal] ?? BillSettings();
  }

  List<TradeInItemModel> _visibleTradeInItems(PosInvoiceModel invoice) {
    return invoice.tradeInItems
        .where((item) => _getMetalConfig(item.metal).showExchangeBreakdown)
        .toList(growable: false);
  }

  bool _hasPrintableCopy(String value) {
    final text = value.trim();
    return text.isNotEmpty && text != '0' && text != '-';
  }

  String _fallback(String value, String fallback) {
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String _weightText(String value) {
    final clean = value.trim();
    if (clean.isEmpty) {
      return '0.000 g';
    }
    final parsed = double.tryParse(clean.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (parsed == null) {
      return '$clean g';
    }
    return '${parsed.toStringAsFixed(3)} g';
  }

  String _amount(double value) => 'Rs ${_amountFormat.format(value)}';

  String _signedAmount(double value) {
    if (value < -0.5) return _amount(value.abs());
    return _amount(value);
  }

  String _amountPanelLabel(PosInvoiceModel invoice) =>
      _isScopedSectionExcess(invoice)
          ? 'SECTION EXCESS'
          : invoice.netPayable < -0.5
              ? 'CUSTOMER CREDIT'
              : 'NET PAYABLE';

  bool _isScopedSectionExcess(PosInvoiceModel invoice) =>
      invoice.isMetalScopedCopy && invoice.netPayable < -0.5;

  String _paymentStatusLabel(PosInvoiceModel invoice) =>
      _isScopedSectionExcess(invoice)
          ? 'ADJUSTED'
          : PosInvoiceFinancialBreakdown.status(invoice).label;

  String _compact(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.0001) {
      return rounded.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
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
