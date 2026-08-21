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
import 'pos_invoice_print_config.dart';
import 'pos_invoice_shop_header_details.dart';

class PosLotusEconomyInvoicePdfLayout {
  static final _amountFormat = NumberFormat('#,##,##0.00', 'en_IN');
  static final _dateFormat = DateFormat('dd MMM yyyy');

  static const _ink = PdfColors.black;
  static const _muted = PdfColors.grey700;
  static const _line = PdfColors.grey500;
  static const _lightLine = PdfColors.grey300;
  static const _success = PdfColor.fromInt(0xFF166534);
  static const _danger = PdfColor.fromInt(0xFFB91C1C);

  final PosInvoiceScopeService scopeService;
  final Map<MetalType, BillSettings> metalPrintSettings;
  final PosInvoicePdfTextRenderer? textRenderer;

  const PosLotusEconomyInvoicePdfLayout({
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
        pw.SizedBox(height: 8),
        _partyAndTaxPanel(invoice),
        pw.SizedBox(height: 8),
        _saleItemSections(invoice),
        if (_visibleTradeInItems(invoice).isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _tradeInSection(invoice),
        ],
        pw.SizedBox(height: 8),
        _totalsAndPayment(invoice),
        if (includePolicyBlock && _policyLines(invoice).isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _compactPolicyBlock(invoice),
        ],
        pw.Spacer(),
        _footer(invoice),
      ],
    );
  }

  pw.Widget _header(PosInvoiceModel invoice) {
    final shopHeader = PosInvoiceShopHeaderDetails.fromInvoice(invoice);
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 9, 10, 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _ink, width: 0.9),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  shopHeader.shopName,
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 3),
                for (final line in shopHeader.lines.take(4))
                  _shopHeaderLine(line),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  _invoiceTitle(invoice),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 5),
                _headerPair('Invoice No.', invoice.invoiceNumber),
                _headerPair('Date', _dateFormat.format(invoice.invoiceDate)),
                _headerPair('Mode', _billingModeLabel(invoice.billingMode)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _partyAndTaxPanel(PosInvoiceModel invoice) {
    final showGstBreakup = _showGstBreakup(invoice);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _box(
            title: 'BILL TO',
            children: [
              pw.Text(
                _fallback(invoice.customerName, 'Walk-in Customer'),
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  fontSize: 11.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              if (invoice.customerMobile.trim().isNotEmpty)
                _keyLine('Mobile', invoice.customerMobile),
              if (invoice.customerCity.trim().isNotEmpty)
                _keyLine('Address', invoice.customerCity),
              if (invoice.customerGstin.trim().isNotEmpty)
                _keyLine('GSTIN', invoice.customerGstin),
              if (invoice.customerStateCode.trim().isNotEmpty)
                _keyLine('State Code', invoice.customerStateCode),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _box(
            title: 'TAX SNAPSHOT',
            children: [
              _keyLine('Taxable Value', _amount(invoice.taxableAmount)),
              if (showGstBreakup) ...[
                if (invoice.hasIgstBreakup)
                  _keyLine('IGST', _amount(invoice.igst))
                else ...[
                  if (invoice.cgst > posInvoiceMoneyEpsilon)
                    _keyLine('CGST', _amount(invoice.cgst)),
                  if (invoice.sgst > posInvoiceMoneyEpsilon)
                    _keyLine('SGST', _amount(invoice.sgst)),
                ],
                _keyLine('Total GST', _amount(invoice.totalGst)),
              ] else if (invoice.totalGst > posInvoiceMoneyEpsilon)
                _keyLine(
                  PosInvoiceFinancialBreakdown.combinedGstLabel(invoice),
                  _amount(invoice.totalGst),
                ),
              _keyLine('Place of Supply',
                  _fallback(invoice.placeOfSupply, invoice.customerStateCode)),
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
      final config = _configFor(metal);
      final sectionTotal = items.fold<double>(
        0,
        (sum, item) => sum + item.totalValue,
      );
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionBar(
            '${metal.displayName.toUpperCase()} ITEMS',
            'Section Total ${_amount(sectionTotal)}',
          ),
          _itemsTable(invoice, items, config),
        ],
      );
    }).toList(growable: false);

    if (sections.isEmpty) {
      return _box(
        title: 'ITEM DETAILS',
        children: [_smallText('No sale items recorded.')],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionBar('ITEM DETAILS', '${invoice.saleItems.length} line item(s)'),
        pw.SizedBox(height: 4),
        ...sections,
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
      '#',
      'Description',
      if (config.showHsnCode) 'HSN',
      if (config.showPurity) 'Purity',
      if (config.showPcs) 'Pcs',
      if (config.showGrossWt) 'Gross',
      if (config.showLessWt) 'Less',
      if (config.showNetWt) isWholesale ? 'Fine' : 'Net',
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
        if (config.showPcs) item.pcs.toString(),
        if (config.showGrossWt) _weight(item.grossCtrl.text),
        if (config.showLessWt) _weight(item.totalLessWt.toStringAsFixed(3)),
        if (config.showNetWt)
          _weight(
            isWholesale
                ? item.fineWt.toStringAsFixed(3)
                : item.netWt.toStringAsFixed(3),
          ),
        if (config.showRate) _amount(item.rate),
        if (config.showMaking || config.showMakingType)
          _making(item, config, isWholesale: isWholesale),
        if (config.showAmount) _amount(item.totalValue),
      ];
    }).toList(growable: false);

    return _table(headers, rows);
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
        _amount(item.rate),
        _amount(item.totalValue),
      ];
    }).toList(growable: false);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionBar('CUSTOMER METAL SETTLEMENT', 'Exchange or purchase entry'),
        pw.SizedBox(height: 4),
        _table(
          const [
            '#',
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

  pw.Widget _totalsAndPayment(PosInvoiceModel invoice) {
    final payments = PosInvoiceFinancialBreakdown.payments(invoice);
    final status = PosInvoiceFinancialBreakdown.status(invoice);
    final summaryRows = PosInvoiceFinancialBreakdown.summaryRows(
      invoice,
      showGstBreakup: _showGstBreakup(invoice),
    );
    final statusColor = status.isDue ? _danger : _success;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _box(
            title: 'PAYMENT RECEIVED',
            children: [
              if (payments.isEmpty)
                _keyLine('Payment Modes', 'No Payment Recorded')
              else
                for (final payment in payments)
                  _keyLine(payment.label, _amount(payment.amount)),
              _divider(),
              _keyLine(
                'Total Received',
                _amount(invoice.totalPaid),
                strong: true,
              ),
              _keyLine(
                'Payment Status',
                status.label,
                strong: true,
                valueColor: statusColor,
              ),
              if (invoice.balanceDue > 0.005)
                _keyLine(
                  'Balance Outstanding',
                  _amount(invoice.balanceDue),
                  strong: true,
                  valueColor: _danger,
                ),
              if (invoice.balanceDue > 0.005 && invoice.promiseDate != null)
                _keyLine(
                  'Due Date',
                  _dateFormat.format(invoice.promiseDate!),
                  strong: true,
                  valueColor: _danger,
                ),
              if (invoice.changeSettlementAmount > 0.005)
                _keyLine(
                  'Excess Payment Settlement',
                  _amount(invoice.changeSettlementAmount),
                  strong: true,
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _box(
            title: 'INVOICE TOTALS',
            children: [
              for (final row in summaryRows) ...[
                if (row.isEmphasized) _divider(),
                _keyLine(
                  row.label,
                  _summaryAmount(row),
                  strong: row.isEmphasized,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _compactPolicyBlock(PosInvoiceModel invoice) {
    final lines = _policyLines(invoice);
    return _box(
      title: 'TERMS',
      children: lines.take(5).map(_policyLine).toList(growable: false),
    );
  }

  pw.Widget _policyLine(String value) {
    const style = pw.TextStyle(fontSize: 8.4, color: _ink);
    final renderer = textRenderer;
    if (renderer == null || value.trim().isEmpty) {
      return _smallText(value);
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: renderer.text(value, style: style, maxWidth: 500),
    );
  }

  pw.Widget _footer(PosInvoiceModel invoice) {
    final footer = _footerMessage(invoice);
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.7)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (footer.isNotEmpty)
                  for (final line in _splitFooterLines(footer))
                    _smallText(line),
              ],
            ),
          ),
          pw.SizedBox(width: 18),
          pw.Container(
            width: 126,
            child: pw.Column(
              children: [
                pw.Container(height: 30),
                pw.Container(height: 0.7, color: _line),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Authorized Signature',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _box({
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 8.4,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
              letterSpacing: 0.2,
            ),
          ),
          pw.SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _sectionBar(String title, String trailing) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _line, width: 0.7),
          bottom: pw.BorderSide(color: _line, width: 0.7),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ),
          pw.Text(
            trailing,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _table(List<String> headers, List<List<String>> rows) {
    return pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: _line, width: 0.7),
        bottom: pw.BorderSide(color: _line, width: 0.7),
        horizontalInside: pw.BorderSide(color: _lightLine, width: 0.35),
      ),
      children: [
        pw.TableRow(
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

  pw.Widget _tableCell(String value, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: pw.Text(
        value,
        maxLines: header ? 1 : 2,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          fontSize: header ? 7.5 : 7.3,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: _ink,
        ),
      ),
    );
  }

  pw.Widget _headerPair(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            '$label: ',
            style: const pw.TextStyle(fontSize: 8.2, color: _muted),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _keyLine(
    String label,
    String value, {
    bool strong = false,
    PdfColor? labelColor,
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: strong ? 8.7 : 8.1,
                color: labelColor ?? (strong ? _ink : _muted),
                fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: strong ? 9.2 : 8.1,
                color: valueColor ?? _ink,
                fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _smallText(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        value,
        maxLines: 1,
        overflow: pw.TextOverflow.clip,
        style: const pw.TextStyle(
          fontSize: 7.8,
          color: _ink,
        ),
      ),
    );
  }

  pw.Widget _shopHeaderLine(PosInvoiceShopHeaderLine line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${line.label}: ',
            style: pw.TextStyle(
              fontSize: 7.8,
              color: _ink,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              line.value,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: const pw.TextStyle(
                fontSize: 7.8,
                color: _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _divider() {
    return pw.Container(
      height: 0.6,
      margin: const pw.EdgeInsets.symmetric(vertical: 3),
      color: _lightLine,
    );
  }

  BillSettings _configFor(MetalType metal) {
    return metalPrintSettings[metal] ??
        BillSettings(
          showHsnCode: true,
          showMakingType: true,
        );
  }

  List<TradeInItemModel> _visibleTradeInItems(PosInvoiceModel invoice) {
    return invoice.tradeInItems
        .where((item) => _configFor(item.metal).showExchangeBreakdown)
        .toList(growable: false);
  }

  List<String> _policyLines(PosInvoiceModel invoice) {
    return PosInvoicePolicyCopy.entries(
      invoice: invoice,
      scopeService: scopeService,
      metalPrintSettings: metalPrintSettings,
    )
        .expand((entry) => PosInvoicePolicyCopy.lines(entry.body))
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
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

  bool _showGstBreakup(PosInvoiceModel invoice) {
    return scopeService
        .collectMetals(invoice)
        .any((metal) => _configFor(metal).showGstBreakup);
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

  String _billingModeLabel(BillingMode mode) {
    return mode == BillingMode.wholesale ? 'B2B' : 'B2C';
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
    if (!config.showMakingType) return _amount(amount);
    final unit = _makingUnit(item.makingChargeType);
    return '${_amount(amount)} ($unit)';
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
    return number.toStringAsFixed(3);
  }

  String _amount(double value) => 'Rs ${_amountFormat.format(value)}';

  String _summaryAmount(PosInvoiceAmountSummaryEntry row) {
    final prefix = row.isDeduction ? '- ' : '';
    return '$prefix${_amount(row.amount.abs())}';
  }

  String _fallback(String value, String fallback) {
    final cleaned = _clean(value);
    return cleaned.isEmpty ? fallback : cleaned;
  }

  String _clean(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
