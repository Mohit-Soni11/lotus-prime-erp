import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/settings/billing_setup/purchase/data/purchase_billing_settings_repository.dart';
import 'package:lotus_erp/logic/purchase/customer_metal_purchase_invoice_service.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/setting/billing_setup/purchase_billing_model.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

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

    return CustomerMetalPurchaseInvoiceService.buildInvoiceBytesForData(
      _invoiceDataFromEntry(entry),
      invoiceDate: entry.date,
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

class _PdfStylePreferences {
  final String selectedTemplateId;
  final Map<String, PurchaseBillingModel> displaySettings;

  const _PdfStylePreferences({
    required this.selectedTemplateId,
    required this.displaySettings,
  });
}

class _LedgerActionSheet extends StatefulWidget {
  final BuildContext parentContext;
  final CustomerMetalPurchaseEntry entry;

  const _LedgerActionSheet({
    required this.parentContext,
    required this.entry,
  });

  @override
  State<_LedgerActionSheet> createState() => _LedgerActionSheetState();
}

class _LedgerActionSheetState extends State<_LedgerActionSheet> {
  late final Future<_PdfStylePreferences> _stylePreferencesFuture;
  String _selectedTemplateId = PrintTemplateRegistry.defaultTemplateId;
  Map<String, PurchaseBillingModel> _displaySettings =
      const <String, PurchaseBillingModel>{};

  @override
  void initState() {
    super.initState();
    _stylePreferencesFuture =
        CustomerMetalPurchaseLedgerActions._loadPdfStylePreferences(
      widget.entry,
    )..then((preferences) {
            if (!mounted) return;
            setState(() {
              _selectedTemplateId = preferences.selectedTemplateId;
              _displaySettings = preferences.displaySettings;
            });
          });
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.entry.hasSellerPhoto;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 620),
          margin: const EdgeInsets.all(18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PurchaseEntryColors.bodyBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PurchaseEntryColors.purchaseAccent.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: PurchaseEntryColors.purchaseAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.referenceNo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: PurchaseEntryColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.entry.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.black,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<_PdfStylePreferences>(
                future: _stylePreferencesFuture,
                builder: (context, snapshot) {
                  return _PdfTemplateSelector(
                    selectedTemplateId: _selectedTemplateId,
                    isLoading: snapshot.connectionState != ConnectionState.done,
                    onChanged: _selectTemplate,
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SheetActionButton(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'View PDF',
                    onPressed: () {
                      Navigator.of(context).pop();
                      CustomerMetalPurchaseLedgerActions.viewPdf(
                        widget.parentContext,
                        widget.entry,
                        templateId: _selectedTemplateId,
                        displaySettings: _displaySettings,
                      );
                    },
                  ),
                  _SheetActionButton(
                    icon: Icons.image_rounded,
                    label: 'View Photo',
                    enabled: hasPhoto,
                    onPressed: () {
                      Navigator.of(context).pop();
                      CustomerMetalPurchaseLedgerActions.viewPhoto(
                        widget.parentContext,
                        widget.entry,
                      );
                    },
                  ),
                  _SheetActionButton(
                    icon: Icons.download_rounded,
                    label: 'Download PDF',
                    onPressed: () {
                      Navigator.of(context).pop();
                      CustomerMetalPurchaseLedgerActions.downloadPdf(
                        widget.parentContext,
                        widget.entry,
                        templateId: _selectedTemplateId,
                        displaySettings: _displaySettings,
                      );
                    },
                  ),
                  _SheetActionButton(
                    icon: Icons.print_rounded,
                    label: 'Print PDF',
                    onPressed: () {
                      Navigator.of(context).pop();
                      CustomerMetalPurchaseLedgerActions.printPdf(
                        widget.parentContext,
                        widget.entry,
                        templateId: _selectedTemplateId,
                        displaySettings: _displaySettings,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTemplate(String templateId) {
    setState(() {
      _selectedTemplateId =
          CustomerMetalPurchaseLedgerActions._resolveTemplateId(templateId);
    });
  }
}

class _LedgerPdfPreviewDialog extends StatefulWidget {
  final CustomerMetalPurchaseEntry entry;
  final String? initialTemplateId;
  final Map<String, PurchaseBillingModel>? initialDisplaySettings;

  const _LedgerPdfPreviewDialog({
    required this.entry,
    required this.initialTemplateId,
    required this.initialDisplaySettings,
  });

  @override
  State<_LedgerPdfPreviewDialog> createState() =>
      _LedgerPdfPreviewDialogState();
}

class _LedgerPdfPreviewDialogState extends State<_LedgerPdfPreviewDialog> {
  late final Future<_PdfStylePreferences> _stylePreferencesFuture;
  late String _selectedTemplateId;
  late Map<String, PurchaseBillingModel> _displaySettings;
  late Future<Uint8List> _pdfBytes;

  @override
  void initState() {
    super.initState();
    _selectedTemplateId = CustomerMetalPurchaseLedgerActions._resolveTemplateId(
      widget.initialTemplateId ?? PrintTemplateRegistry.defaultTemplateId,
    );
    _displaySettings =
        widget.initialDisplaySettings ?? const <String, PurchaseBillingModel>{};
    _stylePreferencesFuture =
        CustomerMetalPurchaseLedgerActions._loadPdfStylePreferences(
      widget.entry,
    )..then((preferences) {
            if (!mounted) return;
            if (widget.initialTemplateId != null) {
              setState(() => _displaySettings = preferences.displaySettings);
              return;
            }
            setState(() {
              _selectedTemplateId = preferences.selectedTemplateId;
              _displaySettings = preferences.displaySettings;
              _pdfBytes = _buildPdfBytes();
            });
          });
    _pdfBytes = _buildPdfBytes();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: PurchaseEntryColors.bodyPanel,
      child: Column(
        children: [
          _PreviewHeader(
            entry: widget.entry,
            selectedTemplateId: _selectedTemplateId,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: PurchaseEntryColors.bodyBorder),
              ),
            ),
            child: FutureBuilder<_PdfStylePreferences>(
              future: _stylePreferencesFuture,
              builder: (context, snapshot) {
                return _PdfTemplateSelector(
                  selectedTemplateId: _selectedTemplateId,
                  isLoading: snapshot.connectionState != ConnectionState.done,
                  onChanged: _selectTemplate,
                );
              },
            ),
          ),
          Expanded(
            child: PdfPreview(
              key: ValueKey(_selectedTemplateId),
              build: (_) => _pdfBytes,
              initialPageFormat: PdfPageFormat.a4,
              allowPrinting: false,
              allowSharing: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              useActions: false,
              maxPageWidth: 980,
              pdfFileName: CustomerMetalPurchaseLedgerActions._pdfFileName(
                widget.entry,
                templateId: _selectedTemplateId,
              ),
              scrollViewDecoration: const BoxDecoration(
                color: PurchaseEntryColors.bodyBg,
              ),
            ),
          ),
          _PreviewBottomBar(
            entry: widget.entry,
            selectedTemplateId: _selectedTemplateId,
            displaySettings: _displaySettings,
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _buildPdfBytes() {
    return CustomerMetalPurchaseLedgerActions._buildInvoiceBytes(
      widget.entry,
      templateId: _selectedTemplateId,
      displaySettings: _displaySettings,
    );
  }

  void _selectTemplate(String templateId) {
    setState(() {
      _selectedTemplateId =
          CustomerMetalPurchaseLedgerActions._resolveTemplateId(templateId);
      _pdfBytes = _buildPdfBytes();
    });
  }
}

class _PreviewHeader extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;
  final String selectedTemplateId;

  const _PreviewHeader({
    required this.entry,
    required this.selectedTemplateId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: PurchaseEntryColors.shellPanel,
        border: Border(
          bottom: BorderSide(color: PurchaseEntryColors.shellBorder),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            color: PurchaseEntryColors.purchaseAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Metal Purchase PDF',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${entry.referenceNo} • ${entry.customerName} • ${PrintTemplateRegistry.labelFor(selectedTemplateId)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PurchaseEntryColors.shellMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close preview',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _PreviewBottomBar extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;
  final String selectedTemplateId;
  final Map<String, PurchaseBillingModel> displaySettings;

  const _PreviewBottomBar({
    required this.entry,
    required this.selectedTemplateId,
    required this.displaySettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: PurchaseEntryColors.bodyBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _PreviewActionButton(
            icon: Icons.image_rounded,
            label: 'Print Photo',
            enabled: entry.hasSellerPhoto,
            onPressed: () => CustomerMetalPurchaseLedgerActions.printPhoto(
              context,
              entry,
            ),
          ),
          const SizedBox(width: 10),
          _PreviewActionButton(
            icon: Icons.download_rounded,
            label: 'Download PDF',
            onPressed: () => CustomerMetalPurchaseLedgerActions.downloadPdf(
              context,
              entry,
              templateId: selectedTemplateId,
              displaySettings: displaySettings,
            ),
          ),
          const SizedBox(width: 10),
          _PreviewActionButton(
            icon: Icons.print_rounded,
            label: 'Print PDF',
            onPressed: () => CustomerMetalPurchaseLedgerActions.printPdf(
              context,
              entry,
              templateId: selectedTemplateId,
              displaySettings: displaySettings,
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerPhotoPreviewDialog extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;
  final File photo;

  const _SellerPhotoPreviewDialog({
    required this.entry,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PhotoHeader(entry: entry),
            Flexible(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF8FAFC),
                child: Image.file(photo, fit: BoxFit.contain),
              ),
            ),
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _PreviewActionButton(
                    icon: Icons.print_rounded,
                    label: 'Print Photo',
                    onPressed: () =>
                        CustomerMetalPurchaseLedgerActions.printPhoto(
                      context,
                      entry,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoHeader extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;

  const _PhotoHeader({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: PurchaseEntryColors.bodyBorder)),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_rounded,
              color: PurchaseEntryColors.purchaseAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${entry.customerName} Photo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: PurchaseEntryColors.textMain,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _PdfTemplateSelector extends StatelessWidget {
  final String selectedTemplateId;
  final bool isLoading;
  final ValueChanged<String> onChanged;

  const _PdfTemplateSelector({
    required this.selectedTemplateId,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final templates = PrintTemplateRegistry.forDocument(
      PrintTemplateDocumentType.purchaseVoucher,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'PDF Style',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: PurchaseEntryColors.textMain,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PurchaseEntryColors.purchaseAccent,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final template in templates)
              _PdfTemplateChip(
                template: template,
                selected: template.id == selectedTemplateId,
                onTap: () => onChanged(template.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _PdfTemplateChip extends StatelessWidget {
  final PrintTemplateDefinition template;
  final bool selected;
  final VoidCallback onTap;

  const _PdfTemplateChip({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.10)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? PurchaseEntryColors.purchaseAccent
                  : PurchaseEntryColors.bodyBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.description_outlined,
                size: 16,
                color: selected
                    ? PurchaseEntryColors.purchaseAccent
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 7),
              Text(
                template.shortName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? PurchaseEntryColors.purchaseAccent
                      : PurchaseEntryColors.textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _SheetActionButton({
    required this.icon,
    required this.label,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionButtonSurface(
      icon: icon,
      label: label,
      enabled: enabled,
      onPressed: onPressed,
      minWidth: 180,
    );
  }
}

class _PreviewActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _PreviewActionButton({
    required this.icon,
    required this.label,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionButtonSurface(
      icon: icon,
      label: label,
      enabled: enabled,
      onPressed: onPressed,
      minWidth: 132,
    );
  }
}

class _ActionButtonSurface extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final double minWidth;

  const _ActionButtonSurface({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: Size(minWidth, 42),
        backgroundColor: PurchaseEntryColors.purchaseAccent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE5E7EB),
        disabledForegroundColor: const Color(0xFF94A3B8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
