part of 'booking_invoice_pdf_service.dart';

LotusPrintableDocument _printableDocument({
  required ShopPrintDocumentProfile shopProfile,
  required PrintTemplateDefinition template,
  required PrintTemplatePdfProfile profile,
  required List<EditableBookingAdvance> bookings,
  required Customer? customer,
  required DateTime createdAt,
  required double estimatedTotal,
  required double totalAdvance,
  required BookingInvoicePrintOptions options,
}) {
  return LotusPrintableDocument(
    shopProfile: shopProfile,
    template: template,
    profile: profile,
    title: 'BOOKING ADVANCE INVOICE',
    subtitle: 'Advance booking document',
    documentNumberLabel: 'Booking No',
    documentNumber: _documentNumber(bookings),
    documentDateLabel: 'Booking Date',
    documentDate: DateFormat('dd MMM yyyy').format(createdAt),
    badgeLabel: _rateTypeSummary(bookings),
    primaryPanel: _printableCustomerPanel(
      customer,
      includeAddress: options.includeCustomerAddress,
    ),
    secondaryPanel: _printableBookingPanel(bookings),
    itemTable: _printableItemTable(bookings, options),
    settlementPanels: _printableSettlementPanels(
      estimatedTotal: estimatedTotal,
      totalAdvance: totalAdvance,
    ),
    policySections: options.includeTerms
        ? const [
            LotusPrintablePolicySection(
              title: 'Booking Terms',
              body:
                  'This document confirms advance received against the listed booking. Final billing will be prepared at delivery according to the applicable sale invoice policy.',
            ),
          ]
        : const [],
    footerMessage: options.includeTerms
        ? 'Final billing will be prepared at delivery.'
        : '',
    showHeaderDocumentMeta: true,
    showHeaderBadge: true,
    useFallbackShopName: true,
    renderPolicySectionsAsPages: false,
    startPolicySectionsOnNewPage: false,
    showLegalSignatureFooter: false,
  );
}

LotusPrintablePanel _printableCustomerPanel(
  Customer? customer, {
  required bool includeAddress,
}) {
  return LotusPrintablePanel(
    title: 'CUSTOMER DETAILS',
    details: [
      LotusPrintableDetail(
        iconKey: 'customer',
        label: 'Customer',
        value: customer?.name.trim().isNotEmpty == true
            ? customer!.name.trim()
            : 'Walk-in Customer',
        highlight: true,
      ),
      if ((customer?.mobile.trim() ?? '').isNotEmpty)
        LotusPrintableDetail(
          iconKey: 'phone',
          label: 'Mobile',
          value: customer!.mobile.trim(),
        ),
      if (includeAddress && _customerAddress(customer) != '-')
        LotusPrintableDetail(
          iconKey: 'location',
          label: 'Address',
          value: _customerAddress(customer),
          multiline: true,
        ),
    ],
  );
}

LotusPrintablePanel _printableBookingPanel(
  List<EditableBookingAdvance> bookings,
) {
  return LotusPrintablePanel(
    title: 'BOOKING DETAILS',
    details: [
      LotusPrintableDetail(
        iconKey: 'invoice',
        label: 'Booking No',
        value: _documentNumber(bookings),
        highlight: true,
      ),
      LotusPrintableDetail(
        iconKey: 'status',
        label: 'Rate Type',
        value: _rateTypeSummary(bookings),
        highlight: true,
      ),
      LotusPrintableDetail(
        iconKey: 'items',
        label: 'Booking Lines',
        value: '${bookings.length}',
      ),
      LotusPrintableDetail(
        iconKey: 'calendar',
        label: 'Delivery',
        value: _deliverySummary(bookings),
      ),
    ],
  );
}

LotusPrintableTable _printableItemTable(
  List<EditableBookingAdvance> bookings,
  BookingInvoicePrintOptions options,
) {
  final headers = <String>[
    'S. No.',
    'Item',
    'Metal',
    'Purity',
    'Weight',
    'Rate Type',
  ];
  if (options.includeRateColumn) headers.add('Rate');
  headers.addAll(['Delivery', 'Estimate', 'Advance']);

  return LotusPrintableTable(
    title: 'BOOKING ITEMS',
    headers: headers,
    rows: [
      for (var index = 0; index < bookings.length; index++)
        _itemRow(
          index + 1,
          bookings[index],
          includeRateColumn: options.includeRateColumn,
        ),
    ],
  );
}

List<LotusPrintablePanel> _printableSettlementPanels({
  required double estimatedTotal,
  required double totalAdvance,
}) {
  return [
    LotusPrintablePanel(
      title: 'ADVANCE SUMMARY',
      details: [
        LotusPrintableDetail(
          iconKey: 'amount',
          label: 'Estimated Booking Value',
          value: _money(estimatedTotal),
          highlight: true,
        ),
        LotusPrintableDetail(
          iconKey: 'payment',
          label: 'Advance Received',
          value: _money(totalAdvance),
          highlight: true,
        ),
      ],
    ),
  ];
}

List<pw.Widget> _thermalContent({
  required String shopName,
  required List<EditableBookingAdvance> bookings,
  required Customer? customer,
  required DateTime createdAt,
  required double estimatedTotal,
  required double totalAdvance,
  required String? copyLabel,
  required BookingInvoicePrintOptions options,
  required PrintTemplatePdfProfile profile,
}) {
  return [
    if (copyLabel != null) _thermalCopyStamp(copyLabel, profile),
    pw.Center(
      child: pw.Text(
        shopName,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    ),
    pw.SizedBox(height: 3),
    pw.Center(
      child: pw.Text(
        'BOOKING ADVANCE INVOICE',
        style: const pw.TextStyle(fontSize: 7),
      ),
    ),
    pw.Divider(),
    _thermalLine('Booking', _documentNumber(bookings)),
    _thermalLine('Booking Date', DateFormat('dd MMM yyyy').format(createdAt)),
    _thermalLine('Customer', customer?.name ?? '-'),
    _thermalLine('Mobile', customer?.mobile ?? '-'),
    if (options.includeCustomerAddress)
      _thermalLine('Address', _customerAddress(customer)),
    pw.Divider(),
    for (final booking in bookings) ...[
      _thermalBookingLine(booking, includeRate: options.includeRateColumn),
      pw.SizedBox(height: 4),
    ],
    pw.Divider(),
    _thermalLine('Estimate', _money(estimatedTotal), strong: true),
    _thermalLine('Advance', _money(totalAdvance), strong: true),
    if (options.includeTerms) ...[
      pw.Divider(),
      pw.Text(
        'Final billing will be prepared at delivery.',
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 6),
      ),
    ],
  ];
}

List<String> _itemRow(
  int serial,
  EditableBookingAdvance booking, {
  required bool includeRateColumn,
}) {
  final order = booking.order;
  return [
    serial.toString(),
    order.itemName,
    order.metalType,
    order.purity,
    '${_number(order.approxWeight)} g',
    order.bookingType,
    if (includeRateColumn) _money(order.lockedRate),
    order.deliveryDate == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(order.deliveryDate!),
    _money(_estimatedTotal(order)),
    _money(_advanceTotal(booking.advances)),
  ];
}

pw.Widget _thermalBookingLine(
  EditableBookingAdvance booking, {
  required bool includeRate,
}) {
  final order = booking.order;
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        order.itemName,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 2),
      _thermalLine('Metal', '${order.metalType} ${order.purity}'),
      _thermalLine('Weight', '${_number(order.approxWeight)} g'),
      _thermalLine('Rate Type', order.bookingType),
      if (includeRate) _thermalLine('Rate', _money(order.lockedRate)),
      _thermalLine('Estimate', _money(_estimatedTotal(order))),
      _thermalLine('Advance', _money(_advanceTotal(booking.advances))),
    ],
  );
}

pw.Widget _thermalCopyStamp(String label, PrintTemplatePdfProfile profile) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Center(
      child: pw.Text(
        label,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
    ),
  );
}

pw.Widget _thermalLine(String label, String value, {bool strong = false}) {
  final style = pw.TextStyle(
    fontSize: strong ? 7 : 6,
    fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: style,
          ),
        ),
      ],
    ),
  );
}

String _documentNumber(List<EditableBookingAdvance> bookings) {
  if (bookings.length == 1) {
    return bookings.single.order.orderNo;
  }
  return '${bookings.first.order.orderNo} +${bookings.length - 1}';
}

ShopPrintDocumentProfile _effectiveShopProfile(
  ShopPrintDocumentProfile profile,
  String fallbackShopName,
) {
  if (profile.invoiceHeaderName.trim().isNotEmpty) return profile;

  final name = fallbackShopName.trim();
  if (name.isEmpty) return profile;

  return ShopPrintDocumentProfile(
    tenantId: profile.tenantId,
    logoPath: profile.logoPath,
    logoShape: profile.logoShape,
    signaturePath: profile.signaturePath,
    signatureShape: profile.signatureShape,
    fields: [
      ShopPrintDocumentField(
        id: 'shop_name',
        label: 'Shop Name',
        value: name,
        group: ShopPrintFieldGroup.identity,
      ),
      ...profile.fields,
    ],
  );
}

String _shopName(ShopPrintDocumentProfile profile, String fallbackShopName) {
  final configuredName = profile.invoiceHeaderName.trim();
  if (configuredName.isNotEmpty) return configuredName;
  final fallback = fallbackShopName.trim();
  return fallback.isEmpty ? 'Lotus ERP' : fallback;
}

String _rateTypeSummary(List<EditableBookingAdvance> bookings) {
  final hasLocked = bookings.any((booking) => booking.order.lockedRate > 0);
  final hasOpen = bookings.any((booking) => booking.order.lockedRate <= 0);
  if (hasLocked && hasOpen) return 'MIXED RATE';
  return hasLocked ? 'LOCKED RATE' : 'OPEN RATE';
}

String _deliverySummary(List<EditableBookingAdvance> bookings) {
  final dates = bookings
      .map((booking) => booking.order.deliveryDate)
      .whereType<DateTime>()
      .toList(growable: false);
  if (dates.isEmpty) return '-';
  dates.sort();
  if (dates.length == 1) return DateFormat('dd MMM yyyy').format(dates.first);
  return '${DateFormat('dd MMM yyyy').format(dates.first)} +${dates.length - 1}';
}

double _estimatedTotal(SalesOrder order) {
  if (order.lockedRate <= 0 || order.approxWeight <= 0) {
    return 0;
  }
  return order.lockedRate * order.approxWeight;
}

pw.EdgeInsets _pageMarginFor(PrintFormat format) {
  return switch (format) {
    PrintFormat.a4 => const pw.EdgeInsets.all(32),
    PrintFormat.thermal3inch => const pw.EdgeInsets.all(
        4 * PdfPageFormat.mm,
      ),
    PrintFormat.thermal2inch => const pw.EdgeInsets.all(
        3 * PdfPageFormat.mm,
      ),
  };
}

String? _copyLabel(int copyIndex, BookingInvoicePrintOptions options) {
  if (!options.includeDuplicateStamp || copyIndex == 0) return null;
  return 'DUPLICATE COPY ${copyIndex + 1}';
}

String _customerAddress(Customer? customer) {
  final address = [
    customer?.addressLine1 ?? '',
    customer?.addressLine2 ?? '',
  ].where((value) => value.trim().isNotEmpty).join(', ');
  return address.isEmpty ? '-' : address;
}

double _advanceTotal(List<OrderAdvance> advances) {
  return advances.fold(0, (sum, row) => sum + row.amountPaid);
}

String _money(double value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().round().toString();
  if (digits.length <= 3) {
    return 'Rs $sign$digits';
  }
  final lastThree = digits.substring(digits.length - 3);
  final leading = digits.substring(0, digits.length - 3);
  final groupedLeading = leading.replaceAllMapped(
    RegExp(r'\B(?=(\d{2})+(?!\d))'),
    (_) => ',',
  );
  return 'Rs $sign$groupedLeading,$lastThree';
}

String _number(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.0001) {
    return rounded.toStringAsFixed(0);
  }
  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
