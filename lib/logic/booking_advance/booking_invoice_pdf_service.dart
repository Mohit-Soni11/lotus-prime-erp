import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../database/db/app_database.dart';
import '../../features/print_templates/domain/print_template_pdf_profile.dart';
import '../../features/print_templates/domain/print_template_registry.dart';
import '../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../repositories/booking_advance/booking_advance_repository.dart';

class BookingInvoicePrintOptions {
  const BookingInvoicePrintOptions({
    required this.format,
    this.templateId = PrintTemplateRegistry.defaultTemplateId,
    this.copies = 1,
    this.includeDuplicateStamp = false,
    this.includeCustomerAddress = true,
    this.includeTerms = true,
    this.includeRateColumn = true,
  });

  final PrintFormat format;
  final String templateId;
  final int copies;
  final bool includeDuplicateStamp;
  final bool includeCustomerAddress;
  final bool includeTerms;
  final bool includeRateColumn;
}

class BookingInvoicePdfService {
  const BookingInvoicePdfService();

  static PdfPageFormat pageFormatFor(PrintFormat format) {
    return switch (format) {
      PrintFormat.a4 => PdfPageFormat.a4,
      PrintFormat.thermal3inch => const PdfPageFormat(
          80 * PdfPageFormat.mm,
          900 * PdfPageFormat.mm,
          marginAll: 4 * PdfPageFormat.mm,
        ),
      PrintFormat.thermal2inch => const PdfPageFormat(
          57 * PdfPageFormat.mm,
          900 * PdfPageFormat.mm,
          marginAll: 3 * PdfPageFormat.mm,
        ),
    };
  }

  Future<Uint8List> buildInvoice({
    required String shopName,
    required List<EditableBookingAdvance> bookings,
    BookingInvoicePrintOptions options = const BookingInvoicePrintOptions(
      format: PrintFormat.a4,
    ),
    DateTime? generatedAt,
  }) {
    if (bookings.isEmpty) {
      throw ArgumentError.value(bookings, 'bookings', 'No booking data found.');
    }

    final document = pw.Document();
    final createdAt = generatedAt ?? DateTime.now();
    final firstBooking = bookings.first;
    final customer = firstBooking.customer;
    final totalAdvance = bookings.fold<double>(
      0,
      (sum, booking) => sum + _advanceTotal(booking.advances),
    );
    final estimatedTotal = bookings.fold<double>(
      0,
      (sum, booking) => sum + _estimatedTotal(booking.order),
    );
    final template = PrintTemplateRegistry.byId(options.templateId);
    final profile = PrintTemplatePdfProfile.forTemplate(template.id);

    final copyCount = options.copies.clamp(1, 5);
    for (var copyIndex = 0; copyIndex < copyCount; copyIndex++) {
      document.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: pageFormatFor(options.format),
            margin: _pageMarginFor(options.format),
          ),
          build: (context) => options.format == PrintFormat.a4
              ? _a4Content(
                  shopName: shopName,
                  bookings: bookings,
                  customer: customer,
                  createdAt: createdAt,
                  estimatedTotal: estimatedTotal,
                  totalAdvance: totalAdvance,
                  copyLabel: _copyLabel(copyIndex, options),
                  options: options,
                  profile: profile,
                )
              : _thermalContent(
                  shopName: shopName,
                  bookings: bookings,
                  customer: customer,
                  createdAt: createdAt,
                  estimatedTotal: estimatedTotal,
                  totalAdvance: totalAdvance,
                  copyLabel: _copyLabel(copyIndex, options),
                  options: options,
                  profile: profile,
                ),
        ),
      );
    }

    return document.save();
  }

  List<pw.Widget> _a4Content({
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
      if (copyLabel != null) _copyStamp(copyLabel, profile),
      _header(
        shopName: shopName,
        documentNumber: _documentNumber(bookings),
        generatedAt: createdAt,
        profile: profile,
      ),
      pw.SizedBox(height: 18),
      _partySection(
        customer,
        includeAddress: options.includeCustomerAddress,
        profile: profile,
      ),
      pw.SizedBox(height: 18),
      _itemsTable(
        bookings,
        includeRateColumn: options.includeRateColumn,
        profile: profile,
      ),
      pw.SizedBox(height: 16),
      _paymentSummary(
        estimatedTotal: estimatedTotal,
        totalAdvance: totalAdvance,
        profile: profile,
      ),
      if (options.includeTerms) ...[
        pw.SizedBox(height: 18),
        _terms(profile),
      ],
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
      _thermalLine('Date', DateFormat('dd MMM yyyy hh:mm a').format(createdAt)),
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

  pw.Widget _header({
    required String shopName,
    required String documentNumber,
    required DateTime generatedAt,
    required PrintTemplatePdfProfile profile,
  }) {
    if (profile.isEconomy) {
      return _economyHeader(
        shopName: shopName,
        documentNumber: documentNumber,
        generatedAt: generatedAt,
        profile: profile,
      );
    }

    return pw.Container(
      padding: pw.EdgeInsets.all(profile.headerPadding + 4),
      decoration: pw.BoxDecoration(
        color: profile.headerColor,
        border: profile.isSignature
            ? pw.Border.all(
                color: profile.headerBorderColor,
                width: profile.headerBorderWidth + 0.6,
              )
            : null,
        borderRadius: pw.BorderRadius.circular(profile.radius + 5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 44,
            height: 44,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: profile.accentColor,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Text(
              'B',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  shopName,
                  style: pw.TextStyle(
                    color: profile.headerPrimaryTextColor,
                    fontSize: profile.titleFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'BOOKING ADVANCE INVOICE',
                  style: pw.TextStyle(
                    color: profile.headerSecondaryTextColor,
                    fontSize: profile.labelFontSize + 1,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                documentNumber,
                style: pw.TextStyle(
                  color: profile.headerPrimaryTextColor,
                  fontSize: profile.documentTitleFontSize - 2,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(generatedAt),
                style: pw.TextStyle(
                  color: profile.headerSecondaryTextColor,
                  fontSize: profile.labelFontSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _economyHeader({
    required String shopName,
    required String documentNumber,
    required DateTime generatedAt,
    required PrintTemplatePdfProfile profile,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(profile.headerPadding),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: profile.headerBorderColor,
          width: profile.headerBorderWidth,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  shopName,
                  style: pw.TextStyle(
                    color: profile.headerPrimaryTextColor,
                    fontSize: profile.titleFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'BOOKING ADVANCE INVOICE',
                  style: pw.TextStyle(
                    color: profile.headerSecondaryTextColor,
                    fontSize: profile.labelFontSize + 1,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                documentNumber,
                style: pw.TextStyle(
                  color: profile.headerPrimaryTextColor,
                  fontSize: profile.documentTitleFontSize - 2,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(generatedAt),
                style: pw.TextStyle(
                  color: profile.headerSecondaryTextColor,
                  fontSize: profile.labelFontSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _partySection(
    Customer? customer, {
    required bool includeAddress,
    required PrintTemplatePdfProfile profile,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(profile.panelPadding + 3),
      decoration: pw.BoxDecoration(
        color: profile.panelColor,
        border: pw.Border.all(
          color: profile.borderColor,
          width: profile.borderWidth,
        ),
        borderRadius: pw.BorderRadius.circular(profile.radius + 3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Customer Details', profile),
          pw.SizedBox(height: 8),
          _infoRow('Customer', customer?.name ?? '-', profile),
          _infoRow('Mobile', customer?.mobile ?? '-', profile),
          if (includeAddress)
            _infoRow('Address', _customerAddress(customer), profile),
        ],
      ),
    );
  }

  pw.Widget _itemsTable(
    List<EditableBookingAdvance> bookings, {
    required bool includeRateColumn,
    required PrintTemplatePdfProfile profile,
  }) {
    return pw.TableHelper.fromTextArray(
      headerDecoration: pw.BoxDecoration(
        color: profile.tableHeaderColor,
      ),
      border: pw.TableBorder.all(
        color: profile.tableBorderColor,
        width: profile.tableBorderWidth,
      ),
      cellPadding: pw.EdgeInsets.symmetric(
        horizontal: profile.tableCellPadding + 0.8,
        vertical: profile.tableCellPadding + 2.6,
      ),
      headerStyle: pw.TextStyle(
        fontSize: profile.tableFontSize,
        fontWeight: pw.FontWeight.bold,
        color: profile.tableHeaderTextColor,
      ),
      cellStyle: pw.TextStyle(
        fontSize: profile.tableFontSize,
        color: profile.bodyTextColor,
      ),
      headers: [
        'No.',
        'Item',
        'Metal',
        'Purity',
        'Weight',
        'Rate Type',
        if (includeRateColumn) 'Rate',
        'Delivery',
        'Estimate',
        'Advance',
      ],
      data: [
        for (var index = 0; index < bookings.length; index++)
          _itemRow(
            index + 1,
            bookings[index],
            includeRateColumn: includeRateColumn,
          ),
      ],
    );
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

  pw.Widget _paymentSummary({
    required double estimatedTotal,
    required double totalAdvance,
    required PrintTemplatePdfProfile profile,
  }) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: profile.summaryWidth,
        padding: pw.EdgeInsets.all(profile.panelPadding + 3),
        decoration: pw.BoxDecoration(
          color: profile.summaryColor,
          border: pw.Border.all(
            color: profile.borderColor,
            width: profile.borderWidth,
          ),
          borderRadius: pw.BorderRadius.circular(profile.radius + 3),
        ),
        child: pw.Column(
          children: [
            _summaryRow(
              'Estimated Booking Value',
              _money(estimatedTotal),
              profile,
            ),
            pw.SizedBox(height: 8),
            _summaryRow(
              'Advance Received',
              _money(totalAdvance),
              profile,
              strong: true,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _terms(PrintTemplatePdfProfile profile) {
    return pw.Container(
      padding: pw.EdgeInsets.all(profile.panelPadding + 1),
      decoration: pw.BoxDecoration(
        color: profile.policyPanelColor,
        border: pw.Border.all(
          color: profile.borderColor,
          width: profile.borderWidth,
        ),
        borderRadius: pw.BorderRadius.circular(profile.radius + 1),
      ),
      child: pw.Text(
        'This document confirms advance received against the listed booking. Final billing will be prepared at delivery according to the applicable sale invoice policy.',
        style: pw.TextStyle(
          fontSize: profile.policyFontSize,
          color: profile.bodyTextColor,
        ),
      ),
    );
  }

  pw.Widget _copyStamp(String label, PrintTemplatePdfProfile profile) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: profile.duplicateStampColor,
        border: pw.Border.all(
          color: profile.borderColor,
          width: profile.borderWidth,
        ),
        borderRadius: pw.BorderRadius.circular(profile.radius + 1),
      ),
      child: pw.Text(
        label,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: profile.duplicateStampTextColor,
          fontSize: profile.labelFontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
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

  pw.Widget _sectionTitle(String text, PrintTemplatePdfProfile profile) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        color: profile.bodyTextColor,
        fontSize: profile.labelFontSize + 2,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _infoRow(
      String label, String value, PrintTemplatePdfProfile profile) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: profile.bodyTextColor,
                fontSize: profile.labelFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: profile.bodyTextColor,
                fontSize: profile.bodyFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(
    String label,
    String value,
    PrintTemplatePdfProfile profile, {
    bool strong = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: profile.bodyTextColor,
            fontSize: profile.labelFontSize,
            fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: profile.bodyTextColor,
            fontSize: strong ? profile.bodyFontSize + 2 : profile.bodyFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
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
}
