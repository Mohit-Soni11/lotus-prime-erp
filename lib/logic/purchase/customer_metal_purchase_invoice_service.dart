import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import '../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../features/print_templates/domain/print_template_registry.dart';
import '../../models/purchase/purchase_entry/purchase_item_model.dart';
import '../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'purchase_entry_controller.dart';

class CustomerMetalPurchaseInvoiceLine {
  final String metalKey;
  final String metalName;
  final String description;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double purity;
  final double fineWeight;
  final double rate;
  final double totalValue;

  const CustomerMetalPurchaseInvoiceLine({
    this.metalKey = '',
    required this.metalName,
    required this.description,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.purity,
    required this.fineWeight,
    required this.rate,
    required this.totalValue,
  });

  factory CustomerMetalPurchaseInvoiceLine.fromItem(PurchaseItemModel item) {
    return CustomerMetalPurchaseInvoiceLine(
      metalKey: item.metal.name,
      metalName: item.metal.displayName,
      description: item.descCtrl.text,
      grossWeight: item.grossWt,
      lessWeight: item.lessWt,
      netWeight: item.netWt,
      purity: item.purity,
      fineWeight: item.fineWt,
      rate: item.rate,
      totalValue: item.totalValue,
    );
  }
}

class CustomerMetalPurchaseInvoiceData {
  final String purchaseNo;
  final String sellerName;
  final String sellerMobile;
  final String sellerAddress;
  final String sellerPanOrAadhaar;
  final DateTime? payoutCommitmentDate;
  final List<CustomerMetalPurchaseInvoiceLine> lineItems;
  final double grossPurchaseAmount;
  final double sellerPayable;
  final double cashPaid;
  final double upiPaid;
  final double cardPaid;
  final double totalPaid;
  final double balanceDue;
  final bool hasPendingSellerPayout;
  final bool hasSellerPayoutExcess;

  const CustomerMetalPurchaseInvoiceData({
    required this.purchaseNo,
    required this.sellerName,
    required this.sellerMobile,
    required this.sellerAddress,
    required this.sellerPanOrAadhaar,
    required this.payoutCommitmentDate,
    required this.lineItems,
    required this.grossPurchaseAmount,
    required this.sellerPayable,
    required this.cashPaid,
    required this.upiPaid,
    required this.cardPaid,
    required this.totalPaid,
    required this.balanceDue,
    required this.hasPendingSellerPayout,
    required this.hasSellerPayoutExcess,
  });

  factory CustomerMetalPurchaseInvoiceData.fromController(
    PurchaseEntryController controller,
  ) {
    return CustomerMetalPurchaseInvoiceData(
      purchaseNo: controller.formattedPurchaseNo,
      sellerName: controller.nameCtrl.text,
      sellerMobile: controller.mobileCtrl.text,
      sellerAddress: controller.cityCtrl.text,
      sellerPanOrAadhaar: controller.panCtrl.text,
      payoutCommitmentDate: controller.payoutCommitmentDate,
      lineItems: controller.items
          .where((item) => item.hasContent)
          .map(CustomerMetalPurchaseInvoiceLine.fromItem)
          .toList(growable: false),
      grossPurchaseAmount: controller.grossPurchaseAmount,
      sellerPayable: controller.grandTotal,
      cashPaid: controller.cashPaid,
      upiPaid: controller.upiPaid,
      cardPaid: controller.cardPaid,
      totalPaid: controller.totalPaid,
      balanceDue: controller.balanceDue,
      hasPendingSellerPayout: controller.hasPendingSellerPayout,
      hasSellerPayoutExcess: controller.hasSellerPayoutExcess,
    );
  }
}

class _PurchaseInvoiceColumn {
  final String key;
  final String label;
  final double width;
  final bool alignRight;

  const _PurchaseInvoiceColumn({
    required this.key,
    required this.label,
    required this.width,
    this.alignRight = true,
  });
}

class CustomerMetalPurchaseInvoiceService {
  CustomerMetalPurchaseInvoiceService._();

  static final NumberFormat _amountFormat =
      NumberFormat('#,##,##0.00', 'en_IN');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final ShopPrintInformationRepository _shopProfileRepository =
      ShopPrintInformationRepository();

  static const PdfColor _ink = PdfColor.fromInt(0xFF111827);
  static const PdfColor _muted = PdfColor.fromInt(0xFF4B5563);
  static const PdfColor _line = PdfColor.fromInt(0xFFD8DEE8);
  static const PdfColor _gold = PdfColor.fromInt(0xFFC89421);
  static const PdfColor _goldSoft = PdfColor.fromInt(0xFFFBF6E9);
  static const PdfColor _success = PdfColor.fromInt(0xFF166534);
  static const PdfColor _danger = PdfColor.fromInt(0xFFB91C1C);

  static Future<void> printInvoice(PurchaseEntryController controller) async {
    final invoice = CustomerMetalPurchaseInvoiceData.fromController(controller);
    final bytes = await buildInvoiceBytesForData(invoice);
    await Printing.layoutPdf(
      name: _fileName(invoice),
      onLayout: (_) async => bytes,
    );
  }

  static Future<Uint8List> buildInvoiceBytes(
    PurchaseEntryController controller, {
    ShopPrintDocumentProfile? shopProfileOverride,
    DateTime? invoiceDate,
    String templateId = PrintTemplateRegistry.defaultTemplateId,
    PrintFormat format = PrintFormat.a4,
    Map<String, PurchaseBillingModel> displaySettings =
        const <String, PurchaseBillingModel>{},
    int copies = 1,
    bool includeDuplicateStamp = false,
  }) async {
    return buildInvoiceBytesForData(
      CustomerMetalPurchaseInvoiceData.fromController(controller),
      shopProfileOverride: shopProfileOverride,
      invoiceDate: invoiceDate,
      templateId: templateId,
      format: format,
      displaySettings: displaySettings,
      copies: copies,
      includeDuplicateStamp: includeDuplicateStamp,
    );
  }

  static Future<Uint8List> buildInvoiceBytesForData(
    CustomerMetalPurchaseInvoiceData invoice, {
    ShopPrintDocumentProfile? shopProfileOverride,
    DateTime? invoiceDate,
    String templateId = PrintTemplateRegistry.defaultTemplateId,
    PrintFormat format = PrintFormat.a4,
    Map<String, PurchaseBillingModel> displaySettings =
        const <String, PurchaseBillingModel>{},
    int copies = 1,
    bool includeDuplicateStamp = false,
  }) async {
    if (invoice.lineItems.isEmpty) {
      throw StateError(
          'Add at least one metal item before generating invoice.');
    }

    final shopProfile = shopProfileOverride ??
        await _shopProfileRepository.loadDocumentProfile();
    final document = pw.Document(
      title: 'Customer Metal Purchase ${invoice.purchaseNo}',
      author: _shopName(shopProfile),
      creator: 'Lotus ERP',
      subject:
          'Customer Metal Purchase Invoice (${PrintTemplateRegistry.labelFor(templateId)})',
      theme: await _documentTheme(),
    );

    final normalizedCopies = copies.clamp(1, 5).toInt();
    for (var copyIndex = 0; copyIndex < normalizedCopies; copyIndex++) {
      final duplicate = includeDuplicateStamp && copyIndex > 0;
      document.addPage(
        pw.MultiPage(
          pageFormat: _pageFormatFor(format),
          margin: _pageMarginFor(format),
          footer: (_) => format == PrintFormat.a4
              ? _footer(shopProfile)
              : pw.SizedBox.shrink(),
          build: (_) {
            final content = format == PrintFormat.a4
                ? _a4Content(
                    shopProfile,
                    invoice,
                    invoiceDate ?? DateTime.now(),
                    displaySettings,
                  )
                : _thermalContent(
                    shopProfile,
                    invoice,
                    invoiceDate ?? DateTime.now(),
                    format,
                    displaySettings,
                  );
            return [
              if (duplicate) _duplicateStamp(format),
              ...content,
            ];
          },
        ),
      );
    }

    return document.save();
  }

  static List<pw.Widget> _a4Content(
    ShopPrintDocumentProfile shopProfile,
    CustomerMetalPurchaseInvoiceData invoice,
    DateTime invoiceDate,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    return [
      _header(shopProfile, invoice, invoiceDate),
      pw.SizedBox(height: 12),
      _sellerAndInvoiceDetails(invoice, invoiceDate, displaySettings),
      pw.SizedBox(height: 14),
      _sectionTitle('CUSTOMER METAL ITEMS'),
      pw.SizedBox(height: 8),
      _itemsTable(invoice.lineItems, displaySettings),
      pw.SizedBox(height: 14),
      _payoutAndSummary(invoice),
    ];
  }

  static List<pw.Widget> _thermalContent(
    ShopPrintDocumentProfile shopProfile,
    CustomerMetalPurchaseInvoiceData invoice,
    DateTime invoiceDate,
    PrintFormat format,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    final compact = format == PrintFormat.thermal2inch;
    return [
      _thermalHeader(shopProfile, invoice, invoiceDate, compact: compact),
      _thermalDivider(),
      _thermalSeller(
        invoice,
        displaySettings: displaySettings,
        compact: compact,
      ),
      _thermalDivider(),
      _thermalItems(
        invoice.lineItems,
        displaySettings: displaySettings,
        compact: compact,
      ),
      _thermalDivider(),
      _thermalTotals(invoice, compact: compact),
      pw.SizedBox(height: compact ? 8 : 10),
      pw.Text(
        'Computer generated customer metal purchase invoice.',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(color: _muted, fontSize: compact ? 6.8 : 7.5),
      ),
      pw.SizedBox(height: compact ? 16 : 20),
      pw.Container(height: 0.7, color: _ink),
      pw.SizedBox(height: 4),
      pw.Text(
        'Authorised Signatory',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: _ink,
          fontSize: compact ? 7 : 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ];
  }

  static pw.Widget _header(
    ShopPrintDocumentProfile profile,
    CustomerMetalPurchaseInvoiceData invoice,
    DateTime invoiceDate,
  ) {
    final logo = _loadImage(profile.logoPath);
    final lines = _headerLines(profile);

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _gold, width: 0.9),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 110,
                height: 92,
                alignment: pw.Alignment.center,
                child: logo == null
                    ? _brandFallback(profile)
                    : pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.Container(
                width: 1,
                height: 108,
                margin: const pw.EdgeInsets.symmetric(horizontal: 16),
                color: _line,
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _shopName(profile).toUpperCase(),
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                      style: pw.TextStyle(
                        color: _ink,
                        fontSize: 23,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    for (final line in lines.take(4))
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Text(
                          line,
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                          style: pw.TextStyle(
                            color: _ink,
                            fontSize: 9.8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                width: 130,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'PURCHASE INVOICE',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        color: _ink,
                        fontSize: 15.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      width: 58,
                      height: 1,
                      margin: const pw.EdgeInsets.only(top: 6, bottom: 5),
                      color: _gold,
                    ),
                    pw.Text(
                      'CUSTOMER METAL',
                      style: pw.TextStyle(
                        color: _gold,
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 13),
                    _meta('Invoice No.', invoice.purchaseNo),
                    _meta('Invoice Date', _dateFormat.format(invoiceDate)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _sellerAndInvoiceDetails(
    CustomerMetalPurchaseInvoiceData invoice,
    DateTime invoiceDate,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    final sellerSettings = _settingsForInvoice(invoice, displaySettings);
    final showSellerDetails = sellerSettings.showSupplierDetails;
    final showPanNumber = sellerSettings.showPanNumber;
    final sellerRows = <pw.Widget>[
      if (showSellerDetails)
        _strongLine(_fallback(invoice.sellerName, 'Walk-in Seller')),
      if (showSellerDetails) _keyValue('Mobile', invoice.sellerMobile),
      if (showSellerDetails) _keyValue('Address', invoice.sellerAddress),
      if (showPanNumber) _keyValue('PAN / Aadhaar', invoice.sellerPanOrAadhaar),
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _panel(
            'SELLER DETAILS',
            sellerRows.isEmpty ? [pw.SizedBox.shrink()] : sellerRows,
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: _panel(
            'INVOICE DETAILS',
            [
              _keyValue('Purchase Type', 'Customer Metal Purchase'),
              _keyValue('Payout Status', _payoutStatus(invoice),
                  valueColor: _statusColor(invoice), strong: true),
              _keyValue('Generated On', _dateFormat.format(invoiceDate)),
              if (invoice.payoutCommitmentDate != null)
                _keyValue(
                  'Commitment',
                  PurchaseEntryController.formatDisplayDate(
                    invoice.payoutCommitmentDate!,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _itemsTable(
    List<CustomerMetalPurchaseInvoiceLine> items,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    final columns = _visibleColumns(items, displaySettings);
    final headers = columns.map((column) => column.label).toList();
    final rows = items.asMap().entries.map((entry) {
      final item = entry.value;
      return columns
          .map((column) => _columnValue(column, item, entry.key + 1))
          .toList(growable: false);
    }).toList(growable: false);

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.6),
      columnWidths: {
        for (var index = 0; index < columns.length; index++)
          index: pw.FlexColumnWidth(columns[index].width),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _goldSoft),
          children: headers
              .map((header) => _tableCell(header, header: true))
              .toList(growable: false),
        ),
        for (final row in rows)
          pw.TableRow(
            children: [
              for (var index = 0; index < row.length; index++)
                _tableCell(
                  row[index],
                  alignRight: columns[index].alignRight,
                ),
            ],
          ),
      ],
    );
  }

  static List<_PurchaseInvoiceColumn> _visibleColumns(
    List<CustomerMetalPurchaseInvoiceLine> items,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    bool visible(bool Function(PurchaseBillingModel settings) test) {
      return items.any((item) => test(_settingsForLine(item, displaySettings)));
    }

    return [
      const _PurchaseInvoiceColumn(
        key: 'index',
        label: '#',
        width: 0.45,
      ),
      const _PurchaseInvoiceColumn(
        key: 'metal',
        label: 'Metal',
        width: 0.85,
        alignRight: false,
      ),
      const _PurchaseInvoiceColumn(
        key: 'description',
        label: 'Description',
        width: 2.15,
        alignRight: false,
      ),
      if (visible((settings) => settings.showGrossWeight))
        const _PurchaseInvoiceColumn(key: 'gross', label: 'Gross', width: 0.95),
      if (visible((settings) => settings.showLessWeight))
        const _PurchaseInvoiceColumn(key: 'less', label: 'Less', width: 0.95),
      if (visible((settings) => settings.showNetWeight))
        const _PurchaseInvoiceColumn(key: 'net', label: 'Net', width: 0.95),
      if (visible((settings) => settings.showPurity))
        const _PurchaseInvoiceColumn(
          key: 'purity',
          label: 'Purity',
          width: 0.9,
        ),
      if (visible((settings) => settings.showFineWeight))
        const _PurchaseInvoiceColumn(key: 'fine', label: 'Fine', width: 0.95),
      if (visible((settings) => settings.showRate))
        const _PurchaseInvoiceColumn(key: 'rate', label: 'Rate', width: 1.05),
      if (visible((settings) => settings.showTotalValue))
        const _PurchaseInvoiceColumn(key: 'value', label: 'Value', width: 1.15),
    ];
  }

  static String _columnValue(
    _PurchaseInvoiceColumn column,
    CustomerMetalPurchaseInvoiceLine item,
    int rowNumber,
  ) {
    switch (column.key) {
      case 'index':
        return '$rowNumber';
      case 'metal':
        return item.metalName;
      case 'description':
        return _fallback(item.description, '${item.metalName} Purchase');
      case 'gross':
        return _weight(item.grossWeight);
      case 'less':
        return _weight(item.lessWeight);
      case 'net':
        return _weight(item.netWeight);
      case 'purity':
        return item.purity.toStringAsFixed(2);
      case 'fine':
        return _weight(item.fineWeight);
      case 'rate':
        return _plainAmount(item.rate);
      case 'value':
        return _plainAmount(item.totalValue);
    }
    return '';
  }

  static pw.Widget _payoutAndSummary(
    CustomerMetalPurchaseInvoiceData invoice,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _panel(
            'PAYOUT RELEASED',
            [
              _keyValue('Cash', _amount(invoice.cashPaid)),
              _keyValue('UPI / Bank', _amount(invoice.upiPaid)),
              _keyValue('Card', _amount(invoice.cardPaid)),
              _keyValue('Released', _amount(invoice.totalPaid), strong: true),
            ],
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: _panel(
            'AMOUNT SUMMARY',
            [
              _keyValue(
                  'Assessed Metal Value', _amount(invoice.grossPurchaseAmount)),
              _keyValue('Seller Payable', _amount(invoice.sellerPayable),
                  strong: true, valueColor: _gold),
              _keyValue(
                invoice.hasSellerPayoutExcess
                    ? 'Payout Excess'
                    : 'Pending Seller Payout',
                _amount(invoice.balanceDue.abs()),
                strong: true,
                valueColor: _statusColor(invoice),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _thermalHeader(
    ShopPrintDocumentProfile profile,
    CustomerMetalPurchaseInvoiceData invoice,
    DateTime invoiceDate, {
    required bool compact,
  }) {
    final lines = _headerLines(profile).take(compact ? 2 : 3);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          _shopName(profile).toUpperCase(),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            color: _ink,
            fontSize: compact ? 10.5 : 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        for (final line in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(
              line,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: _muted,
                fontSize: compact ? 6.4 : 7.2,
              ),
            ),
          ),
        pw.SizedBox(height: 5),
        pw.Text(
          'CUSTOMER METAL PURCHASE',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            color: _ink,
            fontSize: compact ? 8.2 : 9.2,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        _thermalKeyValue(
          'Invoice',
          invoice.purchaseNo,
          compact: compact,
          strong: true,
        ),
        _thermalKeyValue(
          'Date',
          _dateFormat.format(invoiceDate),
          compact: compact,
        ),
      ],
    );
  }

  static pw.Widget _thermalSeller(
    CustomerMetalPurchaseInvoiceData invoice, {
    required Map<String, PurchaseBillingModel> displaySettings,
    required bool compact,
  }) {
    final settings = _settingsForInvoice(invoice, displaySettings);
    final rows = <pw.Widget>[
      if (settings.showSupplierDetails)
        _thermalKeyValue(
          'Name',
          _fallback(invoice.sellerName, 'Walk-in Seller'),
          compact: compact,
          strong: true,
        ),
      if (settings.showSupplierDetails)
        _thermalKeyValue('Mobile', invoice.sellerMobile, compact: compact),
      if (settings.showSupplierDetails)
        _thermalKeyValue('Address', invoice.sellerAddress, compact: compact),
      if (settings.showPanNumber)
        _thermalKeyValue(
          'PAN/ID',
          invoice.sellerPanOrAadhaar,
          compact: compact,
        ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _thermalSectionTitle('SELLER', compact: compact),
        ...rows,
      ],
    );
  }

  static pw.Widget _thermalItems(
    List<CustomerMetalPurchaseInvoiceLine> items, {
    required Map<String, PurchaseBillingModel> displaySettings,
    required bool compact,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _thermalSectionTitle('METAL ITEMS', compact: compact),
        for (final entry in items.asMap().entries)
          _thermalItem(
            entry.key + 1,
            entry.value,
            settings: _settingsForLine(entry.value, displaySettings),
            compact: compact,
          ),
      ],
    );
  }

  static pw.Widget _thermalItem(
    int index,
    CustomerMetalPurchaseInvoiceLine item, {
    required PurchaseBillingModel settings,
    required bool compact,
  }) {
    final fontSize = compact ? 6.6 : 7.5;
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: compact ? 6 : 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$index. ${item.metalName} - ${_fallback(item.description, '${item.metalName} Purchase')}',
            style: pw.TextStyle(
              color: _ink,
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          if (settings.showGrossWeight)
            _thermalKeyValue('Gross', _weight(item.grossWeight),
                compact: compact),
          if (settings.showLessWeight)
            _thermalKeyValue('Less', _weight(item.lessWeight),
                compact: compact),
          if (settings.showNetWeight)
            _thermalKeyValue('Net', _weight(item.netWeight), compact: compact),
          if (settings.showPurity)
            _thermalKeyValue(
              'Purity',
              item.purity.toStringAsFixed(2),
              compact: compact,
            ),
          if (settings.showFineWeight)
            _thermalKeyValue('Fine', _weight(item.fineWeight),
                compact: compact),
          if (settings.showRate)
            _thermalKeyValue('Rate', _amount(item.rate), compact: compact),
          if (settings.showTotalValue)
            _thermalKeyValue(
              'Value',
              _amount(item.totalValue),
              compact: compact,
              strong: true,
            ),
        ],
      ),
    );
  }

  static pw.Widget _thermalTotals(
    CustomerMetalPurchaseInvoiceData invoice, {
    required bool compact,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _thermalSectionTitle('SUMMARY', compact: compact),
        _thermalKeyValue(
          'Metal Value',
          _amount(invoice.grossPurchaseAmount),
          compact: compact,
        ),
        _thermalKeyValue(
          'Seller Payable',
          _amount(invoice.sellerPayable),
          compact: compact,
          strong: true,
        ),
        _thermalKeyValue('Cash', _amount(invoice.cashPaid), compact: compact),
        _thermalKeyValue(
          'UPI/Bank',
          _amount(invoice.upiPaid),
          compact: compact,
        ),
        _thermalKeyValue('Card', _amount(invoice.cardPaid), compact: compact),
        _thermalKeyValue(
          'Released',
          _amount(invoice.totalPaid),
          compact: compact,
          strong: true,
        ),
        _thermalKeyValue(
          _payoutStatus(invoice),
          _amount(invoice.balanceDue.abs()),
          compact: compact,
          strong: true,
        ),
      ],
    );
  }

  static pw.Widget _thermalKeyValue(
    String label,
    String value, {
    required bool compact,
    bool strong = false,
  }) {
    final clean = value.trim();
    if (clean.isEmpty) return pw.SizedBox.shrink();
    final fontSize = compact ? 6.7 : 7.6;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2.4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: compact ? 45 : 58,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: _muted,
                fontSize: fontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              clean,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                color: _ink,
                fontSize: fontSize,
                fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _thermalSectionTitle(
    String title, {
    required bool compact,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: compact ? 4 : 5),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: _ink,
          fontSize: compact ? 7.2 : 8.2,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _thermalDivider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      child: pw.Container(height: 0.6, color: _line),
    );
  }

  static pw.Widget _duplicateStamp(PrintFormat format) {
    final compact = format == PrintFormat.thermal2inch;
    final isThermal = format != PrintFormat.a4;
    return pw.Container(
      width: double.infinity,
      margin: pw.EdgeInsets.only(bottom: isThermal ? 6 : 10),
      padding: pw.EdgeInsets.symmetric(
        horizontal: isThermal ? 5 : 9,
        vertical: isThermal ? 3 : 5,
      ),
      decoration: pw.BoxDecoration(
        color: _goldSoft,
        border: pw.Border.all(color: _gold, width: 0.7),
        borderRadius: pw.BorderRadius.circular(isThermal ? 3 : 5),
      ),
      child: pw.Text(
        'DUPLICATE COPY',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: _ink,
          fontSize: compact
              ? 6.8
              : isThermal
                  ? 7.6
                  : 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _panel(String title, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.75),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _gold,
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: _ink,
        fontSize: 12.5,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _strongLine(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        value,
        maxLines: 1,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          color: _ink,
          fontSize: 11.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _keyValue(
    String label,
    String value, {
    bool strong = false,
    PdfColor? valueColor,
  }) {
    final clean = value.trim();
    if (clean.isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 95,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: _muted,
                fontSize: 8.8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              clean,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                color: valueColor ?? _ink,
                fontSize: strong ? 10.5 : 9.2,
                fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(
    String value, {
    bool header = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        value,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          color: _ink,
          fontSize: header ? 7.8 : 7.3,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _footer(ShopPrintDocumentProfile profile) {
    final signature = _loadImage(profile.signaturePath);
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Text(
              'This is a computer generated customer metal purchase invoice.',
              style: const pw.TextStyle(color: _muted, fontSize: 8.5),
            ),
          ),
          pw.Container(
            width: 120,
            child: pw.Column(
              children: [
                if (signature != null) ...[
                  pw.Image(signature, height: 24, fit: pw.BoxFit.contain),
                  pw.SizedBox(height: 4),
                ] else
                  pw.SizedBox(height: 22),
                pw.Container(height: 0.7, color: _ink),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Authorised Signatory',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _brandFallback(ShopPrintDocumentProfile profile) {
    return pw.Container(
      width: 64,
      height: 64,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: _goldSoft,
        border: pw.Border.all(color: _gold, width: 1),
        shape: pw.BoxShape.circle,
      ),
      child: pw.Text(
        _initials(_shopName(profile)),
        style: pw.TextStyle(
          color: _gold,
          fontSize: 19,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _meta(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(color: _muted, fontSize: 6.8),
          ),
          pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 8.7,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _headerLines(ShopPrintDocumentProfile profile) {
    final selectedLines = profile.headerLines
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (selectedLines.isNotEmpty) return selectedLines;

    return [
      if (profile.primaryAddress.trim().isNotEmpty) profile.primaryAddress,
      if (profile.primaryPhone.trim().isNotEmpty)
        'Mobile: ${profile.primaryPhone.trim()}',
      if (profile.valueOf('business_email').trim().isNotEmpty)
        'Email: ${profile.valueOf('business_email').trim()}',
      if (profile.gstin.trim().isNotEmpty) 'GSTIN: ${profile.gstin.trim()}',
    ];
  }

  static pw.MemoryImage? _loadImage(String? path) {
    final clean = path?.trim() ?? '';
    if (clean.isEmpty) return null;
    try {
      final file = File(clean);
      if (file.existsSync()) return pw.MemoryImage(file.readAsBytesSync());
    } catch (_) {}
    return null;
  }

  static Future<pw.ThemeData> _documentTheme() async {
    final devanagariFont = await _loadFont(
      'assets/fonts/lohit_devanagari/Lohit-Devanagari.ttf',
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
            fontFallback:
                devanagariFont == null ? null : <pw.Font>[devanagariFont],
          );
        } catch (_) {}
      }
    }

    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      fontFallback: devanagariFont == null ? null : <pw.Font>[devanagariFont],
    );
  }

  static Future<pw.Font?> _loadFont(String assetPath) async {
    try {
      return pw.Font.ttf(await rootBundle.load(assetPath));
    } catch (_) {
      try {
        final file = File(assetPath);
        if (!file.existsSync()) return null;
        final bytes = await file.readAsBytes();
        return pw.Font.ttf(_asByteData(bytes));
      } catch (_) {
        return null;
      }
    }
  }

  static ByteData _asByteData(Uint8List bytes) {
    return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
  }

  static PdfPageFormat _pageFormatFor(PrintFormat format) {
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

  static pw.EdgeInsets _pageMarginFor(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return const pw.EdgeInsets.all(24);
      case PrintFormat.thermal3inch:
        return const pw.EdgeInsets.all(4 * PdfPageFormat.mm);
      case PrintFormat.thermal2inch:
        return const pw.EdgeInsets.all(3 * PdfPageFormat.mm);
    }
  }

  static String _shopName(ShopPrintDocumentProfile profile) {
    return _fallback(profile.primaryName, 'Lotus Jewellers');
  }

  static String _fileName(CustomerMetalPurchaseInvoiceData invoice) {
    final seller = _fallback(invoice.sellerName, 'customer-metal');
    final cleanSeller = seller
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '')
        .toLowerCase();
    return '${cleanSeller}_${invoice.purchaseNo}_invoice.pdf';
  }

  static String _payoutStatus(CustomerMetalPurchaseInvoiceData invoice) {
    if (invoice.hasSellerPayoutExcess) return 'PAYOUT EXCESS';
    if (invoice.hasPendingSellerPayout) return 'PENDING';
    return 'SETTLED';
  }

  static PdfColor _statusColor(CustomerMetalPurchaseInvoiceData invoice) {
    if (invoice.hasSellerPayoutExcess) return _danger;
    if (invoice.hasPendingSellerPayout) return _gold;
    return _success;
  }

  static PurchaseBillingModel _settingsForInvoice(
    CustomerMetalPurchaseInvoiceData invoice,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    if (invoice.lineItems.isNotEmpty) {
      return _settingsForLine(invoice.lineItems.first, displaySettings);
    }
    return PurchaseBillingModel.defaultFor('gold');
  }

  static PurchaseBillingModel _settingsForLine(
    CustomerMetalPurchaseInvoiceLine line,
    Map<String, PurchaseBillingModel> displaySettings,
  ) {
    final key = _metalKeyForLine(line);
    return displaySettings[key] ?? PurchaseBillingModel.defaultFor(key);
  }

  static String _metalKeyForLine(CustomerMetalPurchaseInvoiceLine line) {
    final key = line.metalKey.trim().toLowerCase();
    if (key.isNotEmpty) return key;
    return line.metalName.trim().toLowerCase();
  }

  static String _amount(double value) => 'Rs. ${_amountFormat.format(value)}';

  static String _plainAmount(double value) => _amountFormat.format(value);

  static String _weight(double value) => value.toStringAsFixed(3);

  static String _fallback(String value, String fallback) {
    final clean = value.trim();
    return clean.isEmpty ? fallback : clean;
  }

  static String _initials(String value) {
    final words = value
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}';
    if (words.isNotEmpty) return words.first.substring(0, 1).toUpperCase();
    return 'L';
  }
}
