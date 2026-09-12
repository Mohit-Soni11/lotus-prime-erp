import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/data/customer_metal_purchase_ledger_drift_repository.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_voucher_detail.dart';
import 'package:lotus_erp/features/settings/billing_setup/purchase/data/purchase_billing_settings_repository.dart';
import 'package:lotus_erp/logic/purchase/customer_metal_purchase_invoice_service.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/setting/billing_setup/purchase_billing_model.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

part 'customer_metal_purchase_ledger_action_sheet.dart';
part 'customer_metal_purchase_pdf_preview_dialog.dart';
part 'customer_metal_purchase_photo_preview_dialog.dart';
part 'customer_metal_purchase_pdf_template_selector.dart';
part 'customer_metal_purchase_report_action_buttons.dart';

class CustomerMetalPurchaseLedgerActions {
  CustomerMetalPurchaseLedgerActions._();

  static final PurchaseBillingSettingsRepository _billingSettingsRepository =
      PurchaseBillingSettingsRepository();

  static Future<void> showOptions(
    BuildContext context,
    CustomerMetalPurchaseEntry entry,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (sheetContext) => _LedgerActionSheet(
        parentContext: context,
        entry: entry,
      ),
    );
  }

  static Future<void> viewPdf(
    BuildContext context,
    CustomerMetalPurchaseEntry entry, {
    String? templateId,
    Map<String, PurchaseBillingModel>? displaySettings,
  }) {
    return showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black.withValues(alpha: 0.50),
      builder: (_) => _LedgerPdfPreviewDialog(
        entry: entry,
        initialTemplateId: templateId,
        initialDisplaySettings: displaySettings,
      ),
    );
  }

  static Future<void> printPdf(
    BuildContext context,
    CustomerMetalPurchaseEntry entry, {
    String? templateId,
    Map<String, PurchaseBillingModel>? displaySettings,
  }) async {
    await _runWithErrorSnackBar(context, () async {
      final bytes = await _buildInvoiceBytes(
        entry,
        templateId: templateId,
        displaySettings: displaySettings,
      );
      await Printing.layoutPdf(
        name: _pdfFileName(entry),
        onLayout: (_) async => bytes,
      );
    });
  }

  static Future<void> downloadPdf(
    BuildContext context,
    CustomerMetalPurchaseEntry entry, {
    String? templateId,
    Map<String, PurchaseBillingModel>? displaySettings,
  }) async {
    await _runWithErrorSnackBar(context, () async {
      final resolvedTemplateId = _resolveTemplateId(
        templateId ?? PrintTemplateRegistry.defaultTemplateId,
      );
      final bytes = await _buildInvoiceBytes(
        entry,
        templateId: resolvedTemplateId,
        displaySettings: displaySettings,
      );
      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory == null) {
        throw StateError('Downloads folder was not found.');
      }
      final file = File(
        '${downloadsDirectory.path}\\${_pdfFileName(entry, templateId: resolvedTemplateId)}',
      );
      await file.writeAsBytes(bytes, flush: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF downloaded to ${file.path}')),
      );
    });
  }

  static Future<void> viewPhoto(
    BuildContext context,
    CustomerMetalPurchaseEntry entry,
  ) {
    final photo = _sellerPhotoFile(entry);
    if (photo == null) {
      return _showMissingPhotoSnackBar(context);
    }

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _SellerPhotoPreviewDialog(entry: entry, photo: photo),
    );
  }

  static Future<void> printPhoto(
    BuildContext context,
    CustomerMetalPurchaseEntry entry,
  ) async {
    final photo = _sellerPhotoFile(entry);
    if (photo == null) {
      await _showMissingPhotoSnackBar(context);
      return;
    }

    await _runWithErrorSnackBar(context, () async {
      final bytes = await _buildPhotoPrintBytes(entry, photo);
      await Printing.layoutPdf(
        name: '${entry.referenceNo}-seller-photo.pdf',
        onLayout: (_) async => bytes,
      );
    });
  }

  static Future<Uint8List> _buildInvoiceBytes(
    CustomerMetalPurchaseEntry entry, {
    String? templateId,
    Map<String, PurchaseBillingModel>? displaySettings,
  }) async {
    final settings = displaySettings ?? await _loadDisplaySettings();
    final resolvedTemplateId = _resolveTemplateId(
      templateId ?? _configuredTemplateId(entry, settings),
    );
    final payload = await _invoicePayloadFromEntry(entry);

    return CustomerMetalPurchaseInvoiceService.buildInvoiceBytesForData(
      payload.invoice,
      invoiceDate: payload.invoiceDate,
      templateId: resolvedTemplateId,
      format: PrintFormat.a4,
      displaySettings: settings,
    );
  }

  static Future<_PdfStylePreferences> _loadPdfStylePreferences(
    CustomerMetalPurchaseEntry entry,
  ) async {
    final settings = await _loadDisplaySettings();
    return _PdfStylePreferences(
      selectedTemplateId: _resolveTemplateId(
        _configuredTemplateId(entry, settings),
      ),
      displaySettings: settings,
    );
  }

  static Future<Map<String, PurchaseBillingModel>>
      _loadDisplaySettings() async {
    try {
      return await _billingSettingsRepository.fetchAll();
    } catch (_) {
      return const <String, PurchaseBillingModel>{};
    }
  }

  static String _configuredTemplateId(
    CustomerMetalPurchaseEntry entry,
    Map<String, PurchaseBillingModel> settings,
  ) {
    final metalKey = entry.metalType.trim().toLowerCase();
    final configured = settings[metalKey]?.selectedTemplate.trim();
    if (configured == null || configured.isEmpty) {
      return PrintTemplateRegistry.defaultTemplateId;
    }
    return configured;
  }

  static String _resolveTemplateId(String templateId) {
    final template = PrintTemplateRegistry.byId(templateId);
    if (template.supports(PrintTemplateDocumentType.purchaseVoucher)) {
      return template.id;
    }
    return PrintTemplateRegistry.forDocument(
      PrintTemplateDocumentType.purchaseVoucher,
    ).first.id;
  }

  static Future<_InvoiceBuildPayload> _invoicePayloadFromEntry(
    CustomerMetalPurchaseEntry entry,
  ) async {
    final voucher = await _fetchFullVoucherDetail(entry);
    if (voucher != null) {
      return _InvoiceBuildPayload(
        invoice: _invoiceDataFromVoucher(voucher),
        invoiceDate: voucher.createdAt,
      );
    }

    return _InvoiceBuildPayload(
      invoice: _invoiceDataFromEntry(entry),
      invoiceDate: entry.date,
    );
  }

  static Future<CustomerMetalPurchaseVoucherDetail?> _fetchFullVoucherDetail(
    CustomerMetalPurchaseEntry entry,
  ) async {
    if (!_canResolvePurchaseVoucher(entry)) {
      return null;
    }

    try {
      final repository = DriftCustomerMetalPurchaseLedgerRepository(
        AppDatabase(),
      );
      return await repository.fetchVoucherDetail(entry.sourceDocumentId);
    } catch (_) {
      return null;
    }
  }

  static bool _canResolvePurchaseVoucher(CustomerMetalPurchaseEntry entry) {
    final source = entry.source.trim().toLowerCase();
    return !source.contains('trade') && !source.contains('exchange');
  }

  static CustomerMetalPurchaseInvoiceData _invoiceDataFromVoucher(
    CustomerMetalPurchaseVoucherDetail voucher,
  ) {
    return CustomerMetalPurchaseInvoiceData(
      purchaseNo: voucher.voucherNo,
      sellerName: voucher.partyName,
      sellerMobile: voucher.mobile ?? '',
      sellerAddress: voucher.city ?? '',
      sellerPanOrAadhaar: voucher.panNumber ?? '',
      sellerPhotoPath: voucher.sellerPhotoPath ?? '',
      payoutCommitmentDate: voucher.promiseDate,
      lineItems: [
        for (final line in voucher.lines)
          CustomerMetalPurchaseInvoiceLine(
            metalKey: line.metalType.toLowerCase(),
            metalName: line.metalType.toUpperCase(),
            description: line.itemDescription,
            grossWeight: line.grossWeight,
            lessWeight: line.lessWeight,
            netWeight: line.netWeight,
            purity: line.purity,
            fineWeight: line.fineWeight,
            rate: line.rate,
            totalValue: line.lineAmount,
          ),
      ],
      grossPurchaseAmount: voucher.grossAmount,
      sellerPayable: voucher.grandTotal,
      cashPaid: voucher.cashPaid,
      upiPaid: voucher.upiPaid + voucher.bankPaid,
      cardPaid: voucher.cardPaid,
      totalPaid: voucher.totalPaid,
      balanceDue: voucher.balanceDue,
      hasPendingSellerPayout: voucher.balanceDue > 0.005,
      hasSellerPayoutExcess: voucher.balanceDue < -0.005,
    );
  }

  static CustomerMetalPurchaseInvoiceData _invoiceDataFromEntry(
    CustomerMetalPurchaseEntry entry,
  ) {
    final description = entry.itemDescription.trim().isEmpty
        ? entry.metalType
        : entry.itemDescription.trim();
    final paidTotal = entry.paidAmount;

    return CustomerMetalPurchaseInvoiceData(
      purchaseNo: entry.referenceNo,
      sellerName: entry.customerName,
      sellerMobile: entry.mobile ?? '',
      sellerAddress: '',
      sellerPanOrAadhaar: '',
      sellerPhotoPath: entry.sellerPhotoPath ?? '',
      payoutCommitmentDate: entry.commitmentDate,
      lineItems: [
        CustomerMetalPurchaseInvoiceLine(
          metalKey: entry.metalType.toLowerCase(),
          metalName: entry.metalType.toUpperCase(),
          description: description,
          grossWeight: entry.grossWeight,
          lessWeight:
              (entry.grossWeight - entry.netWeight).clamp(0.0, 999999.0),
          netWeight: entry.netWeight,
          purity: entry.purity,
          fineWeight: entry.fineWeight,
          rate: entry.effectiveRate,
          totalValue: entry.amount,
        ),
      ],
      grossPurchaseAmount: entry.amount,
      sellerPayable: entry.amount,
      cashPaid: entry.cashPaid,
      upiPaid: entry.upiPaid + entry.bankPaid,
      cardPaid: entry.cardPaid,
      totalPaid: paidTotal,
      balanceDue: entry.pendingAmount,
      hasPendingSellerPayout: entry.pendingAmount > 0.005,
      hasSellerPayoutExcess: entry.pendingAmount < -0.005,
    );
  }

  static Future<Uint8List> _buildPhotoPrintBytes(
    CustomerMetalPurchaseEntry entry,
    File photo,
  ) async {
    final imageBytes = await photo.readAsBytes();
    final image = pw.MemoryImage(imageBytes);
    final document = pw.Document(
      title: '${entry.referenceNo} Seller Photo',
      author: 'Lotus ERP',
      creator: 'Lotus ERP',
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Seller Photo Proof',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(entry.referenceNo),
              pw.Text(entry.customerName),
              if ((entry.mobile ?? '').trim().isNotEmpty)
                pw.Text(entry.mobile!.trim()),
              pw.SizedBox(height: 18),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              ),
            ],
          );
        },
      ),
    );

    return document.save();
  }

  static File? _sellerPhotoFile(CustomerMetalPurchaseEntry entry) {
    final path = entry.sellerPhotoPath?.trim();
    if (path == null || path.isEmpty) {
      return null;
    }
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  static String _pdfFileName(
    CustomerMetalPurchaseEntry entry, {
    String? templateId,
  }) {
    final safeReference =
        entry.referenceNo.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-');
    final style = PrintTemplateRegistry.labelFor(
      templateId ?? PrintTemplateRegistry.defaultTemplateId,
    ).replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-').toLowerCase();
    return '$safeReference-$style.pdf';
  }

  static Future<void> _showMissingPhotoSnackBar(BuildContext context) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seller photo is not available.')),
    );
  }

  static Future<void> _runWithErrorSnackBar(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $error')),
      );
    }
  }
}

class _InvoiceBuildPayload {
  final CustomerMetalPurchaseInvoiceData invoice;
  final DateTime invoiceDate;

  const _InvoiceBuildPayload({
    required this.invoice,
    required this.invoiceDate,
  });
}
