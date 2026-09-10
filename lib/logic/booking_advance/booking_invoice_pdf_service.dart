import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/pdf/lotus_pdf_text_renderer.dart';
import '../../database/db/app_database.dart';
import '../../features/print_templates/application/global/lotus_print_template_renderer_registry.dart';
import '../../features/print_templates/application/global/lotus_printable_document.dart';
import '../../features/print_templates/domain/print_template_pdf_profile.dart';
import '../../features/print_templates/domain/print_template_registry.dart';
import '../../features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import '../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../models/setting/billing_setup/booking_advance_billing_model.dart';
import '../../repositories/booking_advance/booking_advance_repository.dart';

part 'booking_invoice_pdf_builders.dart';

class BookingInvoicePrintOptions {
  const BookingInvoicePrintOptions({
    required this.format,
    this.templateId = PrintTemplateRegistry.defaultTemplateId,
    this.copies = 1,
    this.includeDuplicateStamp = false,
    this.includeCustomerAddress = true,
    this.includeTerms = true,
    this.includeFooterMessage = true,
    this.includeRateColumn = true,
    this.termsAndConditions =
        BookingAdvanceBillingModel.defaultTermsAndConditions,
    this.footerMessage = BookingAdvanceBillingModel.defaultFooterMessage,
  });

  final PrintFormat format;
  final String templateId;
  final int copies;
  final bool includeDuplicateStamp;
  final bool includeCustomerAddress;
  final bool includeTerms;
  final bool includeFooterMessage;
  final bool includeRateColumn;
  final String termsAndConditions;
  final String footerMessage;
}

class BookingInvoicePdfService {
  const BookingInvoicePdfService({
    ShopPrintInformationRepository? shopProfileRepository,
  }) : _shopProfileRepository = shopProfileRepository;

  final ShopPrintInformationRepository? _shopProfileRepository;

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
    ShopPrintDocumentProfile? shopProfileOverride,
  }) async {
    if (bookings.isEmpty) {
      throw ArgumentError.value(bookings, 'bookings', 'No booking data found.');
    }

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
    final shopProfile = _effectiveShopProfile(
      shopProfileOverride ?? await _loadShopProfile(),
      shopName,
    );
    final printableDocument = options.format == PrintFormat.a4
        ? _printableDocument(
            shopProfile: shopProfile,
            template: template,
            profile: profile,
            bookings: bookings,
            customer: customer,
            createdAt: createdAt,
            estimatedTotal: estimatedTotal,
            totalAdvance: totalAdvance,
            options: options,
          )
        : null;
    final textRenderer =
        printableDocument == null ? null : await LotusPdfTextRenderer.create();
    if (printableDocument != null && textRenderer != null) {
      await LotusPrintTemplateRendererRegistry.warmPolicyText(
        printableDocument,
        textRenderer,
      );
    }

    final document = pw.Document(
      title: 'Booking Advance Invoice ${_documentNumber(bookings)}',
      author: _shopName(shopProfile, shopName),
      creator: 'Lotus ERP Booking Advance',
      subject:
          'Booking Advance Invoice (${PrintTemplateRegistry.labelFor(template.id)})',
    );

    final copyCount = options.copies.clamp(1, 5);
    for (var copyIndex = 0; copyIndex < copyCount; copyIndex++) {
      final duplicate = options.includeDuplicateStamp && copyIndex > 0;
      document.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: pageFormatFor(options.format),
            margin: _pageMarginFor(options.format),
          ),
          build: (context) {
            if (options.format == PrintFormat.a4) {
              return LotusPrintTemplateRendererRegistry.buildA4(
                templateId: template.id,
                context: LotusPrintTemplateRenderContext(
                  document: printableDocument!,
                  textRenderer: textRenderer!,
                ),
                isDuplicateCopy: duplicate,
              );
            }

            return _thermalContent(
              shopName: shopName,
              bookings: bookings,
              customer: customer,
              createdAt: createdAt,
              estimatedTotal: estimatedTotal,
              totalAdvance: totalAdvance,
              copyLabel: _copyLabel(copyIndex, options),
              options: options,
              profile: profile,
            );
          },
        ),
      );
    }

    return document.save();
  }

  Future<ShopPrintDocumentProfile> _loadShopProfile() async {
    try {
      return await (_shopProfileRepository ?? ShopPrintInformationRepository())
          .loadDocumentProfile();
    } catch (_) {
      return ShopPrintDocumentProfile.empty;
    }
  }
}
