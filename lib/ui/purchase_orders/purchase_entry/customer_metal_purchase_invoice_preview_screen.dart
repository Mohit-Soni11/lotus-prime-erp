import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/pdf/lotus_pdf_page_counter.dart';
import '../../../core/printing/lotus_pdf_print_dispatcher.dart';
import '../../../features/print_templates/domain/print_template_registry.dart';
import '../../../features/settings/billing_setup/purchase/domain/purchase_billing_metal_profile.dart';
import '../../../features/settings/billing_setup/shop_info/data/shop_print_information_repository.dart';
import '../../../features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import '../../../features/settings/billing_setup/shop_info/presentation/widgets/shop_print_information_widgets.dart';
import '../../../logic/purchase/customer_metal_purchase_invoice_service.dart';
import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../repositories/setting/billing_setup/purchase_billing_repo.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import '../../sales_orders/sales_pos/pos_invoice_template_selector.dart';

class CustomerMetalPurchaseInvoicePreviewScreen extends StatefulWidget {
  final PurchaseEntryController controller;

  const CustomerMetalPurchaseInvoicePreviewScreen({
    super.key,
    required this.controller,
  });

  static Future<void> push(
    BuildContext context, {
    required PurchaseEntryController controller,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return CustomerMetalPurchaseInvoicePreviewScreen(
            controller: controller,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  @override
  State<CustomerMetalPurchaseInvoicePreviewScreen> createState() =>
      _CustomerMetalPurchaseInvoicePreviewScreenState();
}

class _CustomerMetalPurchaseInvoicePreviewScreenState
    extends State<CustomerMetalPurchaseInvoicePreviewScreen> {
  final PurchaseBillingRepo _billingRepo = PurchaseBillingRepo();
  final ShopPrintInformationRepository _shopPrintRepo =
      ShopPrintInformationRepository();
  final LotusPdfPrintDispatcher _printDispatcher =
      const LotusPdfPrintDispatcher();

  Uint8List? _pdfBytes;
  final Map<String, PurchaseBillingModel> _purchaseBillingSettings = {};
  ShopPrintInformationState? _shopPrintState;
  ShopPrintDocumentProfile _shopPrintProfile = ShopPrintDocumentProfile.empty;
  String _selectedTemplateId = PrintTemplateRegistry.defaultTemplateId;
  PrintFormat _selectedFormat = PrintFormat.a4;
  String? _activeDisplayMetal;
  int _printCopies = 1;
  bool _includeDuplicateStamp = false;
  bool _usePrinterDriverSettings = true;
  bool _isBuilding = true;
  bool _isPrinting = false;
  bool _isCompletingPurchase = false;
  bool _hasFinalizedPurchaseInvoice = false;
  bool _hasPrintedPurchaseInvoice = false;
  bool _hasWorkspaceTemplateSelection = false;
  bool _isLoadingDisplaySettings = true;
  bool _isLoadingShopPrintProfile = true;
  String? _errorMessage;
  int _pdfRevision = 0;
  int _pdfBuildSerial = 0;
  int _shopPrintSyncSerial = 0;
  Timer? _pdfRebuildDebounce;
  Timer? _shopPrintSyncDebounce;
  final Map<String, Timer> _purchaseBillingSaveDebounces = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialTemplateAndBuild();
    });
  }

  Future<void> _loadInitialTemplateAndBuild() async {
    await _loadPurchaseBillingSettings();
    await _loadShopPrintInformationSetup(rebuildPdf: false);
    await _buildPdf();
  }

  Future<void> _loadPurchaseBillingSettings() async {
    if (!mounted) return;
    setState(() => _isLoadingDisplaySettings = true);

    try {
      final settings = <String, PurchaseBillingModel>{};
      for (final metal in BillingMetal.all) {
        settings[metal] = await _billingRepo.fetchForMetal(metal);
      }
      if (!mounted) return;
      _purchaseBillingSettings
        ..clear()
        ..addAll(settings);
      _activeDisplayMetal = _activeMetalKey();
      if (!_hasWorkspaceTemplateSelection) {
        _selectedTemplateId = _configuredTemplateForActiveMetal();
      }
    } catch (_) {
      if (!_hasWorkspaceTemplateSelection) {
        _selectedTemplateId = PrintTemplateRegistry.defaultTemplateId;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDisplaySettings = false);
      }
    }
  }

  @override
  void dispose() {
    _pdfRebuildDebounce?.cancel();
    final shouldFlushShopPrint =
        _shopPrintSyncDebounce?.isActive == true && _shopPrintState != null;
    _shopPrintSyncDebounce?.cancel();
    if (shouldFlushShopPrint) {
      unawaited(_shopPrintRepo.save(_shopPrintState!));
    }
    for (final entry in _purchaseBillingSaveDebounces.entries) {
      entry.value.cancel();
      final latest = _purchaseBillingSettings[entry.key];
      if (latest != null) {
        unawaited(_billingRepo.saveForMetal(latest));
      }
    }
    _purchaseBillingSaveDebounces.clear();
    _pdfBuildSerial++;
    super.dispose();
  }

  Future<void> _buildPdf({bool showLoading = true}) async {
    if (!mounted) return;
    final buildSerial = ++_pdfBuildSerial;
    setState(() {
      if (showLoading) {
        _isBuilding = true;
      }
      _errorMessage = null;
    });

    try {
      final bytes = await CustomerMetalPurchaseInvoiceService.buildInvoiceBytes(
        widget.controller,
        templateId: _selectedTemplateId,
        format: _selectedFormat,
        displaySettings: _purchaseBillingSettings,
        shopProfileOverride: _shopPrintProfile,
        copies: _printCopies,
        includeDuplicateStamp: _includeDuplicateStamp,
        metalScope:
            _selectedFormat == PrintFormat.a4 ? _activeMetalKey() : null,
      );
      if (!mounted || buildSerial != _pdfBuildSerial) return;
      setState(() {
        _pdfBytes = bytes;
        _isBuilding = false;
        _pdfRevision++;
      });
    } catch (error) {
      if (!mounted || buildSerial != _pdfBuildSerial) return;
      setState(() {
        _pdfBytes = null;
        _isBuilding = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _schedulePdfRebuild({
    Duration delay = const Duration(milliseconds: 180),
  }) {
    _pdfRebuildDebounce?.cancel();
    _pdfRebuildDebounce = Timer(delay, () {
      if (mounted) {
        _buildPdf(showLoading: false);
      }
    });
  }

  Future<void> _selectTemplate(String templateId) async {
    final resolvedTemplateId = PrintTemplateRegistry.byId(templateId).id;
    _hasWorkspaceTemplateSelection = true;
    if (_selectedTemplateId == resolvedTemplateId) return;
    setState(() => _selectedTemplateId = resolvedTemplateId);

    try {
      final current = _activePurchaseBillingSettings();
      final updated = current.copyWith(selectedTemplate: resolvedTemplateId);
      _purchaseBillingSettings[current.metal] = updated;
      await _billingRepo.saveForMetal(updated);
    } catch (_) {}

    await _buildPdf();
  }

  Future<void> _loadShopPrintInformationSetup({
    bool rebuildPdf = true,
  }) async {
    if (!mounted) return;
    setState(() => _isLoadingShopPrintProfile = true);

    try {
      final state = await _shopPrintRepo.load();
      final profile = await _shopPrintRepo.buildDocumentProfile(state);
      if (!mounted) return;
      setState(() {
        _shopPrintState = state;
        _shopPrintProfile = profile;
        _isLoadingShopPrintProfile = false;
      });
      if (rebuildPdf) await _buildPdf();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _shopPrintState = null;
        _shopPrintProfile = ShopPrintDocumentProfile.empty;
        _isLoadingShopPrintProfile = false;
      });
      if (rebuildPdf) await _buildPdf();
    }
  }

  Future<void> _setShopPrintFieldEnabled(
    ShopPrintField field,
    bool enabled,
  ) async {
    final state = _shopPrintState;
    if (state == null) return;
    if (!field.isConfigured) {
      _showMissingShopPrintFieldGuidance(field);
      return;
    }

    final enabledIds = {...state.enabledFieldIds};
    if (enabled) {
      enabledIds.add(field.id);
    } else {
      enabledIds.remove(field.id);
    }

    final updatedState = state.copyWith(enabledFieldIds: enabledIds);
    if (!mounted) return;
    setState(() => _shopPrintState = updatedState);
    _scheduleShopPrintProfileSync();
  }

  void _scheduleShopPrintProfileSync({
    Duration delay = const Duration(milliseconds: 180),
  }) {
    _shopPrintSyncDebounce?.cancel();
    final syncSerial = ++_shopPrintSyncSerial;
    _shopPrintSyncDebounce = Timer(delay, () async {
      final state = _shopPrintState;
      if (state == null) return;
      final profile = await _shopPrintRepo.buildDocumentProfile(state);
      if (!mounted || syncSerial != _shopPrintSyncSerial) return;
      await _shopPrintRepo.save(state);
      if (!mounted || syncSerial != _shopPrintSyncSerial) return;
      setState(() => _shopPrintProfile = profile);
      _schedulePdfRebuild(delay: Duration.zero);
    });
  }

  Future<void> _saveShopPrintInformationSetup() async {
    final state = _shopPrintState;
    if (state == null) return;
    await _shopPrintRepo.save(state);
    if (!mounted) return;
    AppFeedback.success(
      context,
      message: 'Business print profile saved.',
    );
  }

  void _showMissingShopPrintFieldGuidance(ShopPrintField field) {
    AppFeedback.warning(
      context,
      message:
          'Add ${field.label} in ${field.sourceSection} before enabling it.',
    );
  }

  Future<void> _selectDisplayMetal(String metal) async {
    if (_activeDisplayMetal == metal) return;
    setState(() => _activeDisplayMetal = metal);
    await _buildPdf();
  }

  Future<PurchaseBillingModel> _togglePurchaseDisplayField(
    String metal,
    PurchaseBillingFieldKey key,
    bool value,
  ) async {
    final current = _purchaseBillingSettings[metal] ??
        PurchaseBillingModel.defaultFor(metal);
    final updated = PurchaseBillingMetalProfiles.setValue(current, key, value);
    setState(() => _purchaseBillingSettings[updated.metal] = updated);
    _schedulePurchaseBillingSave(updated.metal);
    if (updated.metal == _activeMetalKey()) {
      _schedulePdfRebuild();
    }
    return updated;
  }

  Future<PurchaseBillingModel> _togglePurchasePolicyPrintOption(
    String metal,
    _PurchasePolicyPrintKey key,
    bool value,
  ) async {
    final current = _purchaseBillingSettings[metal] ??
        PurchaseBillingModel.defaultFor(metal);
    final updated = _setPurchasePolicyPrintValue(current, key, value);
    setState(() => _purchaseBillingSettings[updated.metal] = updated);
    _schedulePurchaseBillingSave(updated.metal);
    if (updated.metal == _activeMetalKey()) {
      _schedulePdfRebuild();
    }
    return updated;
  }

  void _schedulePurchaseBillingSave(String metal) {
    _purchaseBillingSaveDebounces.remove(metal)?.cancel();
    _purchaseBillingSaveDebounces[metal] = Timer(
      const Duration(milliseconds: 220),
      () async {
        final latest = _purchaseBillingSettings[metal];
        if (latest == null) return;
        await _billingRepo.saveForMetal(latest);
        _purchaseBillingSaveDebounces.remove(metal);
      },
    );
  }

  Future<void> _restoreActivePurchaseBillingSetup() async {
    await _restorePurchaseBillingSetup(_activeMetalKey());
  }

  Future<PurchaseBillingModel> _restorePurchaseBillingSetup(
      String metal) async {
    final restored = await _billingRepo.fetchForMetal(metal);
    if (!mounted) return restored;
    setState(() {
      _purchaseBillingSettings[metal] = restored;
      if (metal == _activeMetalKey() && !_hasWorkspaceTemplateSelection) {
        _selectedTemplateId = _configuredTemplateForActiveMetal();
      }
    });
    if (metal == _activeMetalKey()) {
      await _buildPdf();
    }
    return restored;
  }

  Future<void> _savePurchaseBillingSetup(String metal) async {
    _purchaseBillingSaveDebounces.remove(metal)?.cancel();
    final latest = _purchaseBillingSettings[metal] ??
        PurchaseBillingModel.defaultFor(metal);
    await _billingRepo.saveForMetal(latest);
    if (!mounted) return;
    AppFeedback.success(
      context,
      message: '${_metalLabel(metal)} invoice display profile saved.',
    );
  }

  Future<void> _selectFormat(PrintFormat format) async {
    if (_selectedFormat == format) return;
    setState(() => _selectedFormat = format);
    await _buildPdf();
  }

  void _updatePrintOptions({
    required int copies,
    required bool duplicate,
    bool? useDriverSettings,
  }) {
    final normalizedCopies = copies.clamp(1, 5).toInt();
    setState(() {
      _printCopies = normalizedCopies;
      _includeDuplicateStamp = normalizedCopies > 1 && duplicate;
      _usePrinterDriverSettings =
          useDriverSettings ?? _usePrinterDriverSettings;
    });
    _schedulePdfRebuild();
  }

  Future<bool> _printInvoice({
    Uint8List? invoiceBytes,
    String? invoiceFileName,
    bool showSuccess = true,
  }) async {
    final bytes = invoiceBytes ?? _pdfBytes;
    if (bytes == null || _isPrinting) return false;
    final fileName = invoiceFileName ?? _fileName();

    setState(() => _isPrinting = true);
    try {
      final result = await _printDispatcher.dispatch(
        context: context,
        bytes: bytes,
        documentName:
            fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
        outputFileName: fileName,
        printerPickerTitle: 'Select Purchase Invoice Printer',
        virtualSaveDialogTitle: 'Save Purchase Invoice Print Output As',
        usePrinterSettings: _usePrinterDriverSettings,
      );
      if (!result.completed) {
        if (result == LotusPdfPrintResult.failed && mounted) {
          AppFeedback.error(
            context,
            message: 'Unable to print invoice. Please try again.',
          );
        }
        return false;
      }

      if (!mounted) return true;
      setState(() => _hasPrintedPurchaseInvoice = true);
      if (showSuccess) {
        AppFeedback.success(context, message: 'Invoice sent to printer.');
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<bool> _finalizePurchaseForCompletion() async {
    if (_hasFinalizedPurchaseInvoice) return true;

    final saved = await widget.controller.savePurchase();
    if (!mounted) return saved;

    if (!saved) {
      AppFeedback.error(
        context,
        message: widget.controller.saveErrorMessage ??
            'Purchase could not be saved. Please review the details.',
      );
      return false;
    }

    setState(() => _hasFinalizedPurchaseInvoice = true);
    return true;
  }

  Future<void> _saveAndNewPurchase() async {
    if (_isCompletingPurchase || _isPrinting) return;

    setState(() => _isCompletingPurchase = true);
    final saved = await _finalizePurchaseForCompletion();
    if (!mounted) return;

    if (!saved) {
      setState(() => _isCompletingPurchase = false);
      return;
    }

    Navigator.of(context).pop();
    AppFeedback.success(
      context,
      message: 'Purchase saved successfully. New purchase is ready.',
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _finalizePrintAndNewPurchase() async {
    if (_isCompletingPurchase || _isPrinting) return;

    final bytes = _pdfBytes;
    if (bytes == null || _isBuilding) return;
    final fileName = _fileName();

    setState(() => _isCompletingPurchase = true);
    final saved = await _finalizePurchaseForCompletion();
    if (!mounted) return;

    if (!saved) {
      setState(() => _isCompletingPurchase = false);
      return;
    }

    final printed = await _printInvoice(
      invoiceBytes: bytes,
      invoiceFileName: fileName,
      showSuccess: false,
    );
    if (!mounted) return;

    Navigator.of(context).pop();
    if (printed) {
      AppFeedback.success(
        context,
        message:
            'Purchase saved and printed successfully. New purchase is ready.',
        duration: const Duration(seconds: 3),
      );
    } else {
      AppFeedback.warning(
        context,
        message: 'Purchase saved successfully. Print was not completed.',
        duration: const Duration(seconds: 3),
      );
    }
  }

  List<String> _presentMetalKeys() {
    final keys = <String>[];
    for (final item in widget.controller.items) {
      if (!item.hasContent || keys.contains(item.metal.name)) continue;
      keys.add(item.metal.name);
    }
    return keys.isEmpty ? ['gold'] : keys;
  }

  String _activeMetalKey() {
    final present = _presentMetalKeys();
    final active = _activeDisplayMetal;
    if (active != null && present.contains(active)) return active;
    return present.first;
  }

  PurchaseBillingModel _activePurchaseBillingSettings() {
    final metal = _activeMetalKey();
    return _purchaseBillingSettings[metal] ??
        PurchaseBillingModel.defaultFor(metal);
  }

  String _configuredTemplateForActiveMetal() {
    final configuredTemplate =
        _activePurchaseBillingSettings().selectedTemplate.trim();
    if (configuredTemplate.isEmpty) {
      return PrintTemplateRegistry.defaultTemplateId;
    }
    return PrintTemplateRegistry.byId(configuredTemplate).id;
  }

  String _fileName() {
    final seller = widget.controller.nameCtrl.text.trim().isEmpty
        ? 'customer-metal'
        : widget.controller.nameCtrl.text.trim();
    final cleanSeller = seller
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '')
        .toLowerCase();
    return '${cleanSeller}_${widget.controller.formattedPurchaseNo}_invoice.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PurchaseEntryColors.bodyBg,
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 420,
              color: PurchaseEntryColors.shellBg,
              child: Column(
                children: [
                  _header(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _formatSelector(),
                          const SizedBox(height: 22),
                          PosInvoiceTemplateSelector(
                            selectedTemplateId: _selectedTemplateId,
                            documentType:
                                PrintTemplateDocumentType.purchaseVoucher,
                            title: 'INVOICE DESIGN',
                            onChanged: _selectTemplate,
                          ),
                          const SizedBox(height: 22),
                          _billContextPanel(),
                          const SizedBox(height: 18),
                          _businessPrintProfileSection(),
                          const SizedBox(height: 18),
                          _invoiceDisplaySection(),
                          const SizedBox(height: 18),
                          _printControlsSection(),
                        ],
                      ),
                    ),
                  ),
                  _actions(),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: PurchaseEntryColors.bodyBorder.withValues(alpha: 0.35),
                child: _preview(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellBg,
        border: Border(
          bottom: BorderSide(
            color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: PurchaseEntryColors.shellTitle,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUSTOMER METAL PURCHASE',
                  style: TextStyle(
                    color: PurchaseEntryColors.shellMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Generate Invoice',
                  style: TextStyle(
                    color: PurchaseEntryColors.shellTitle,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatSelector() {
    final format = _selectedFormat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DOCUMENT FORMAT',
          style: TextStyle(
            color: PurchaseEntryColors.shellMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDocumentFormatPicker(format),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PurchaseEntryColors.shellPanel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PurchaseEntryColors.purchaseAccent.withValues(
                  alpha: 0.45,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _FormatIcon(format: format),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            format.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PurchaseEntryColors.shellTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatShortName(format),
                            style: const TextStyle(
                              color: PurchaseEntryColors.purchaseAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: PurchaseEntryColors.purchaseAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FormatDetailPill(
                        icon: Icons.straighten_rounded,
                        label: _formatPaperSpec(format),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FormatDetailPill(
                        icon: Icons.verified_rounded,
                        label: _formatUseCase(format),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDocumentFormatPicker(PrintFormat selectedFormat) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close document format selector',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _DocumentFormatPickerPanel(
              selectedFormat: selectedFormat,
              formatShortName: _formatShortName,
              formatPaperSpec: _formatPaperSpec,
              formatUseCase: _formatUseCase,
              onSelect: (format) {
                _selectFormat(format);
                Navigator.of(dialogContext).pop();
              },
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  String _formatShortName(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return 'A4';
      case PrintFormat.thermal3inch:
        return '80 mm';
      case PrintFormat.thermal2inch:
        return '57 mm';
    }
  }

  String _formatPaperSpec(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return '210 x 297 mm';
      case PrintFormat.thermal3inch:
        return '80 mm roll';
      case PrintFormat.thermal2inch:
        return '57 mm roll';
    }
  }

  String _formatUseCase(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return 'Full invoice';
      case PrintFormat.thermal3inch:
        return 'Counter print';
      case PrintFormat.thermal2inch:
        return 'Compact receipt';
    }
  }

  Widget _billContextPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BILL CONTEXT',
          style: TextStyle(
            color: PurchaseEntryColors.shellMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PurchaseEntryColors.shellPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PurchaseEntryColors.shellBorder),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildProfileChip(
                Icons.move_to_inbox_rounded,
                'Customer Metal',
              ),
              _buildProfileChip(
                Icons.receipt_long_rounded,
                'Purchase Invoice',
              ),
              _buildProfileChip(
                Icons.category_rounded,
                _presentMetalLabel(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PurchaseEntryColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: PurchaseEntryColors.purchaseAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: PurchaseEntryColors.shellTitle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _presentMetalLabel() {
    final metals = widget.controller.items
        .where((item) => item.hasContent)
        .map((item) => item.metal.displayName)
        .toSet()
        .toList(growable: false);
    return metals.isEmpty ? 'No Metal Items' : metals.join(' + ');
  }

  Widget _businessPrintProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BUSINESS PRINT PROFILE',
          style: TextStyle(
            color: PurchaseEntryColors.shellMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        _PurchaseBusinessPrintProfileCard(
          state: _shopPrintState,
          isLoading: _isLoadingShopPrintProfile,
          onConfigure: _showShopPrintProfileDrawer,
          onReload: _loadShopPrintInformationSetup,
        ),
      ],
    );
  }

  void _showShopPrintProfileDrawer() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close business print profile editor',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _PurchaseShopPrintProfileDrawer(
              stateProvider: () => _shopPrintState,
              onFieldChanged: _setShopPrintFieldEnabled,
              onMissingFieldTap: _showMissingShopPrintFieldGuidance,
              onReload: _loadShopPrintInformationSetup,
              onSave: _saveShopPrintInformationSetup,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  Widget _invoiceDisplaySection() {
    if (_selectedFormat != PrintFormat.a4) return const SizedBox.shrink();

    final presentMetals = _presentMetalKeys();
    final activeSettings = _activePurchaseBillingSettings();
    final fields = PurchaseBillingMetalProfiles.fieldsFor(activeSettings.metal);
    final activeFieldCount =
        PurchaseBillingMetalProfiles.activeFieldCount(activeSettings);
    final accent = _metalAccent(activeSettings.metal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INVOICE DISPLAY',
          style: TextStyle(
            color: PurchaseEntryColors.shellMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        if (presentMetals.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final metal in presentMetals) _metalDisplayButton(metal),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _PurchaseDisplayProfileCard(
          model: activeSettings,
          accentColor: accent,
          activeFieldCount: activeFieldCount,
          totalFieldCount: fields.length,
          isLoading: _isLoadingDisplaySettings,
          onConfigure: () => _showPurchaseDisplayDrawer(activeSettings),
          onReload: _restoreActivePurchaseBillingSetup,
        ),
      ],
    );
  }

  Widget _metalDisplayButton(String metal) {
    final selected = _activeMetalKey() == metal;
    final accent = _metalAccent(metal);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _selectDisplayMetal(metal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : PurchaseEntryColors.shellPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent : PurchaseEntryColors.shellBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 15,
              color: selected ? accent : PurchaseEntryColors.shellMuted,
            ),
            const SizedBox(width: 7),
            Text(
              '${_metalLabel(metal)} Invoice',
              style: TextStyle(
                color: selected ? accent : PurchaseEntryColors.shellTitle,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPurchaseDisplayDrawer(PurchaseBillingModel model) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close purchase billing display editor',
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: _PurchaseDisplayProfileDrawer(
              model: model,
              accentColor: _metalAccent(model.metal),
              onFieldChanged: _togglePurchaseDisplayField,
              onPolicyPrintChanged: _togglePurchasePolicyPrintOption,
              onReload: _restorePurchaseBillingSetup,
              onSave: _savePurchaseBillingSetup,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  Color _metalAccent(String metal) {
    switch (metal) {
      case 'gold':
        return PurchaseEntryColors.metalGold;
      case 'silver':
        return PurchaseEntryColors.metalSilver;
      case 'platinum':
        return PurchaseEntryColors.metalPlatinum;
      case 'diamond':
        return PurchaseEntryColors.metalDiamond;
      default:
        return PurchaseEntryColors.purchaseAccent;
    }
  }

  String _metalLabel(String metal) {
    switch (metal) {
      case 'gold':
        return 'GOLD';
      case 'silver':
        return 'SILVER';
      case 'platinum':
        return 'PLATINUM';
      case 'diamond':
        return 'DIAMOND';
      default:
        return metal.toUpperCase();
    }
  }

  String _printRunSummary({
    required int copies,
    required int? totalPages,
  }) {
    final copyLabel = LotusPdfPageCounter.copyLabel(copies);
    if (totalPages == null) return '$copyLabel selected';
    return '$copyLabel selected - ${LotusPdfPageCounter.pageLabel(totalPages)} to print';
  }

  String _copyControlSubtitle({
    required int? totalPages,
    required int? pagesPerCopy,
  }) {
    if (totalPages == null || pagesPerCopy == null) {
      return 'Maximum 5 copies per print run';
    }
    return '${LotusPdfPageCounter.pageLabel(pagesPerCopy)} per copy - ${LotusPdfPageCounter.pageLabel(totalPages)} total';
  }

  Widget _printControlsSection() {
    final copies = _printCopies;
    final duplicateEnabled = _includeDuplicateStamp;
    final useDriverSettings = _usePrinterDriverSettings;
    final totalPages = LotusPdfPageCounter.tryCountPages(_pdfBytes);
    final pagesPerCopy = LotusPdfPageCounter.pagesPerCopy(
      totalPages: totalPages,
      copies: copies,
    );
    final canDecrease = copies > 1;
    final canIncrease = copies < 5;
    final canMarkDuplicate = copies > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRINT CONTROLS',
          style: TextStyle(
            color: PurchaseEntryColors.shellMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PurchaseEntryColors.shellPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: PurchaseEntryColors.purchaseAccent.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: PurchaseEntryColors.purchaseAccent.withValues(
                          alpha: 0.28,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      color: PurchaseEntryColors.purchaseAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Print Run',
                          style: TextStyle(
                            color: PurchaseEntryColors.shellTitle,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _printRunSummary(
                            copies: copies,
                            totalPages: totalPages,
                          ),
                          style: const TextStyle(
                            color: PurchaseEntryColors.shellMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PrintStatusBadge(
                    label: duplicateEnabled ? 'Duplicate On' : 'Original',
                    isActive: duplicateEnabled,
                  ),
                ],
              ),
              const Divider(color: PurchaseEntryColors.shellBorder, height: 24),
              _PrintControlSurface(
                icon: Icons.copy_all_rounded,
                title: 'Copies',
                subtitle: _copyControlSubtitle(
                  totalPages: totalPages,
                  pagesPerCopy: pagesPerCopy,
                ),
                trailing: _CopyStepper(
                  value: copies,
                  canDecrease: canDecrease,
                  canIncrease: canIncrease,
                  onDecrease: () {
                    if (!canDecrease) return;
                    _updatePrintOptions(
                      copies: copies - 1,
                      duplicate: duplicateEnabled,
                      useDriverSettings: useDriverSettings,
                    );
                  },
                  onIncrease: () {
                    if (!canIncrease) return;
                    _updatePrintOptions(
                      copies: copies + 1,
                      duplicate: duplicateEnabled,
                      useDriverSettings: useDriverSettings,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              _PrintControlSurface(
                icon: Icons.verified_user_rounded,
                title: 'Duplicate Mark',
                subtitle: canMarkDuplicate
                    ? 'Stamp second and later copies only'
                    : 'Available when copies are 2 or more',
                trailing: Switch(
                  value: duplicateEnabled,
                  onChanged: canMarkDuplicate
                      ? (value) => _updatePrintOptions(
                            copies: copies,
                            duplicate: value,
                            useDriverSettings: useDriverSettings,
                          )
                      : null,
                  activeThumbColor: PurchaseEntryColors.purchaseAccent,
                  activeTrackColor: PurchaseEntryColors.purchaseAccent
                      .withValues(alpha: 0.32),
                  inactiveThumbColor: PurchaseEntryColors.shellMuted,
                  inactiveTrackColor: PurchaseEntryColors.shellBg,
                ),
              ),
              const SizedBox(height: 10),
              _PrintControlSurface(
                icon: Icons.settings_applications_rounded,
                title: 'Printer Driver Settings',
                subtitle: 'Use saved duplex, paper tray and printer defaults',
                trailing: Switch(
                  value: useDriverSettings,
                  onChanged: (value) => _updatePrintOptions(
                    copies: copies,
                    duplicate: duplicateEnabled,
                    useDriverSettings: value,
                  ),
                  activeThumbColor: PurchaseEntryColors.purchaseAccent,
                  activeTrackColor: PurchaseEntryColors.purchaseAccent
                      .withValues(alpha: 0.32),
                  inactiveThumbColor: PurchaseEntryColors.shellMuted,
                  inactiveTrackColor: PurchaseEntryColors.shellBg,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PrintMetaPill(
                      icon: Icons.description_rounded,
                      label: _formatShortName(_selectedFormat),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrintMetaPill(
                      icon: Icons.layers_rounded,
                      label: pagesPerCopy == null
                          ? (copies == 1 ? 'Single copy' : '$copies copies')
                          : '${LotusPdfPageCounter.pageLabel(pagesPerCopy)}/copy',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrintMetaPill(
                      icon: duplicateEnabled
                          ? Icons.verified_rounded
                          : Icons.lock_open_rounded,
                      label: duplicateEnabled ? 'Stamped' : 'Clean',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrintMetaPill(
                      icon: useDriverSettings
                          ? Icons.settings_rounded
                          : Icons.straighten_rounded,
                      label: useDriverSettings ? 'Driver' : 'App size',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    final canUsePdf = _pdfBytes != null && !_isBuilding;
    final isBusy =
        _isCompletingPurchase || _isPrinting || widget.controller.isSaving;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellBg,
        border: Border(
          top: BorderSide(
            color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: PurchaseEntryColors.shellPanel.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasFinalizedPurchaseInvoice
                ? PurchaseEntryColors.success.withValues(alpha: 0.34)
                : PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.34),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PurchaseInvoiceActionStatus(
                isReady: canUsePdf,
                isFinalized: _hasFinalizedPurchaseInvoice,
                isPrinted: _hasPrintedPurchaseInvoice,
                isBusy: isBusy,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PurchaseInvoiceActionButton(
                      label: _hasFinalizedPurchaseInvoice
                          ? 'NEW PURCHASE'
                          : 'SAVE & NEW',
                      icon: Icons.done_all_rounded,
                      onPressed:
                          canUsePdf && !isBusy ? _saveAndNewPurchase : null,
                      accentColor: PurchaseEntryColors.success,
                      isPrimary: true,
                      isBusy: _isCompletingPurchase && !_isPrinting,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PurchaseInvoiceActionButton(
                      label: _isPrinting ? 'PRINTING...' : 'PRINT & NEW',
                      icon: Icons.print_rounded,
                      onPressed: canUsePdf && !isBusy
                          ? _finalizePrintAndNewPurchase
                          : null,
                      accentColor: PurchaseEntryColors.purchaseAccent,
                      filled: true,
                      isPrimary: true,
                      isBusy: _isPrinting,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview() {
    if (_isBuilding) {
      return const Center(
        child: CircularProgressIndicator(
          color: PurchaseEntryColors.purchaseAccent,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(
            color: PurchaseEntryColors.danger,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final bytes = _pdfBytes;
    if (bytes == null) {
      return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Padding(
        key: ValueKey(
            '$_selectedTemplateId-${_selectedFormat.name}-${_activeMetalKey()}-$_pdfRevision'),
        padding: const EdgeInsets.all(30),
        child: PdfPreview(
          build: (_) async => bytes,
          allowPrinting: false,
          allowSharing: false,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          initialPageFormat: _previewPageFormat(),
        ),
      ),
    );
  }

  PdfPageFormat _previewPageFormat() {
    switch (_selectedFormat) {
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
}

class _PurchaseInvoiceActionStatus extends StatelessWidget {
  final bool isReady;
  final bool isFinalized;
  final bool isPrinted;
  final bool isBusy;

  const _PurchaseInvoiceActionStatus({
    required this.isReady,
    required this.isFinalized,
    required this.isPrinted,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isPrinted
        ? PurchaseEntryColors.purchaseAccent
        : isFinalized
            ? PurchaseEntryColors.success
            : isReady
                ? PurchaseEntryColors.purchaseAccent
                : PurchaseEntryColors.warning;
    final title = isPrinted
        ? 'Invoice Printed'
        : isFinalized
            ? 'Invoice Finalized'
            : isReady
                ? 'Ready to Finalize'
                : 'Preparing Invoice';
    final subtitle = isBusy
        ? 'Working'
        : isPrinted
            ? 'Printed'
            : isFinalized
                ? 'Saved'
                : isReady
                    ? 'Draft'
                    : 'Please wait';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Icon(
            isBusy
                ? Icons.sync_rounded
                : isPrinted
                    ? Icons.local_printshop_rounded
                    : isFinalized
                        ? Icons.verified_rounded
                        : isReady
                            ? Icons.receipt_long_rounded
                            : Icons.hourglass_top_rounded,
            color: accent,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INVOICE COMPLETION',
                style: TextStyle(
                  color: PurchaseEntryColors.shellMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PurchaseEntryColors.shellTitle,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Text(
            subtitle,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PurchaseInvoiceActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool filled;
  final bool isPrimary;
  final bool isBusy;

  const _PurchaseInvoiceActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.accentColor,
    this.filled = false,
    this.isPrimary = false,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = isPrimary ? 52.0 : 42.0;
    final foreground = filled ? Colors.white : accentColor;
    final background = filled ? accentColor : Colors.transparent;
    final disabledColor = PurchaseEntryColors.shellMuted.withValues(
      alpha: 0.60,
    );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: _buttonIcon(foreground),
              label: _buttonLabel(foreground),
              style: ElevatedButton.styleFrom(
                backgroundColor: background,
                foregroundColor: foreground,
                disabledBackgroundColor: accentColor.withValues(alpha: 0.26),
                disabledForegroundColor: disabledColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: _buttonIcon(foreground),
              label: _buttonLabel(foreground),
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                disabledForegroundColor: disabledColor,
                side: BorderSide(
                  color: onPressed == null
                      ? PurchaseEntryColors.shellBorder
                      : accentColor.withValues(alpha: 0.45),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
    );
  }

  Widget _buttonIcon(Color color) {
    if (!isBusy) return Icon(icon, size: 18);
    return SizedBox(
      width: 17,
      height: 17,
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buttonLabel(Color color) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PurchaseBusinessPrintProfileCard extends StatelessWidget {
  final ShopPrintInformationState? state;
  final bool isLoading;
  final VoidCallback onConfigure;
  final Future<void> Function() onReload;

  const _PurchaseBusinessPrintProfileCard({
    required this.state,
    required this.isLoading,
    required this.onConfigure,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || state == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PurchaseEntryColors.shellPanel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PurchaseEntryColors.shellBorder),
        ),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PurchaseEntryColors.success,
                ),
              )
            else
              const Icon(
                Icons.error_outline_rounded,
                color: PurchaseEntryColors.warning,
                size: 18,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isLoading
                    ? 'Loading business print profile...'
                    : 'Business print profile could not be loaded.',
                style: const TextStyle(
                  color: PurchaseEntryColors.shellMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!isLoading)
              TextButton(
                onPressed: () => onReload(),
                child: const Text('Reload'),
              ),
          ],
        ),
      );
    }

    final loadedState = state!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PurchaseEntryColors.success.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: PurchaseEntryColors.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: PurchaseEntryColors.success,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business details on this invoice',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: PurchaseEntryColors.shellTitle,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Controls logo, header, contact and statutory fields',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: PurchaseEntryColors.shellMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: PurchaseEntryColors.shellBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PurchaseBusinessMetricPill(
                        icon: Icons.toggle_on_rounded,
                        label:
                            '${loadedState.enabledCount}/${loadedState.configuredCount} Enabled',
                        color: PurchaseEntryColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PurchaseBusinessMetricPill(
                        icon: Icons.inventory_2_rounded,
                        label: '${loadedState.missingCount} Missing',
                        color: loadedState.missingCount == 0
                            ? PurchaseEntryColors.success
                            : PurchaseEntryColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onConfigure,
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('CONFIGURE'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PurchaseEntryColors.success,
                          side: BorderSide(
                            color: PurchaseEntryColors.success.withValues(
                              alpha: 0.45,
                            ),
                          ),
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => onReload(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('RELOAD'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PurchaseEntryColors.shellMuted,
                        side: const BorderSide(
                          color: PurchaseEntryColors.shellBorder,
                        ),
                        minimumSize: const Size(104, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseBusinessMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PurchaseBusinessMetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseShopPrintProfileDrawer extends StatefulWidget {
  final ShopPrintInformationState? Function() stateProvider;
  final Future<void> Function(ShopPrintField field, bool enabled)
      onFieldChanged;
  final ValueChanged<ShopPrintField> onMissingFieldTap;
  final Future<void> Function() onReload;
  final Future<void> Function() onSave;
  final VoidCallback onClose;

  const _PurchaseShopPrintProfileDrawer({
    required this.stateProvider,
    required this.onFieldChanged,
    required this.onMissingFieldTap,
    required this.onReload,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<_PurchaseShopPrintProfileDrawer> createState() =>
      _PurchaseShopPrintProfileDrawerState();
}

class _PurchaseShopPrintProfileDrawerState
    extends State<_PurchaseShopPrintProfileDrawer> {
  bool _isSaving = false;
  bool _isReloading = false;
  ShopPrintInformationState? _localState;

  @override
  void initState() {
    super.initState();
    _localState = widget.stateProvider();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await widget.onSave();
    if (!mounted) return;
    setState(() => _isSaving = false);
    widget.onClose();
  }

  Future<void> _reload() async {
    setState(() => _isReloading = true);
    await widget.onReload();
    if (!mounted) return;
    setState(() {
      _localState = widget.stateProvider();
      _isReloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width < 760 ? width - 24 : 720.0;

    return Container(
      width: panelWidth,
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PurchaseEntryColors.shellBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 28,
            offset: Offset(-10, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _PurchaseShopPrintDrawerHeader(onClose: widget.onClose),
            Expanded(child: _body()),
            _PurchaseShopPrintDrawerFooter(
              isSaving: _isSaving,
              isReloading: _isReloading,
              onReload: _reload,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final state = _localState ?? widget.stateProvider();
    if (state == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: PurchaseEntryColors.success,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PurchaseShopPrintSummaryStrip(state: state),
        const SizedBox(height: 14),
        for (final group in ShopPrintFieldGroup.values) ...[
          ShopPrintInformationSection(
            group: group,
            fields: state.fields
                .where((field) => field.group == group)
                .toList(growable: false),
            isEnabled: state.isEnabled,
            onChanged: (field, enabled) async {
              final current = _localState ?? widget.stateProvider();
              if (current != null) {
                final enabledIds = {...current.enabledFieldIds};
                if (enabled) {
                  enabledIds.add(field.id);
                } else {
                  enabledIds.remove(field.id);
                }
                setState(() {
                  _localState = current.copyWith(enabledFieldIds: enabledIds);
                });
              }
              await widget.onFieldChanged(field, enabled);
              if (mounted) {
                setState(() => _localState = widget.stateProvider());
              }
            },
            onMissingFieldTap: widget.onMissingFieldTap,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _PurchaseShopPrintDrawerHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _PurchaseShopPrintDrawerHeader({
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
      decoration: const BoxDecoration(
        color: PurchaseEntryColors.shellPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        border:
            Border(bottom: BorderSide(color: PurchaseEntryColors.shellBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: PurchaseEntryColors.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: PurchaseEntryColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUSINESS PRINT PROFILE',
                  style: TextStyle(
                    color: PurchaseEntryColors.shellTitle,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Controls business information with live purchase invoice preview',
                  style: TextStyle(
                    color: PurchaseEntryColors.shellMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: PurchaseEntryColors.shellMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseShopPrintSummaryStrip extends StatelessWidget {
  final ShopPrintInformationState state;

  const _PurchaseShopPrintSummaryStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PurchaseDrawerMetric(
              icon: Icons.toggle_on_rounded,
              label: '${state.enabledCount} Enabled',
              color: PurchaseEntryColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PurchaseDrawerMetric(
              icon: Icons.verified_rounded,
              label: '${state.configuredCount}/${state.fields.length} Ready',
              color: PurchaseEntryColors.purchaseAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PurchaseDrawerMetric(
              icon: state.missingCount == 0
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              label: '${state.missingCount} Missing',
              color: state.missingCount == 0
                  ? PurchaseEntryColors.success
                  : PurchaseEntryColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseDrawerMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PurchaseDrawerMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseShopPrintDrawerFooter extends StatelessWidget {
  final bool isSaving;
  final bool isReloading;
  final VoidCallback onReload;
  final VoidCallback onSave;

  const _PurchaseShopPrintDrawerFooter({
    required this.isSaving,
    required this.isReloading,
    required this.onReload,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isSaving || isReloading ? null : onReload,
              icon: isReloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 17),
              label: Text(isReloading ? 'RELOADING...' : 'RELOAD SAVED'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isSaving || isReloading ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 17),
              label: Text(isSaving ? 'SAVING...' : 'SAVE BUSINESS PROFILE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PurchaseEntryColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentFormatPickerPanel extends StatelessWidget {
  final PrintFormat selectedFormat;
  final String Function(PrintFormat) formatShortName;
  final String Function(PrintFormat) formatPaperSpec;
  final String Function(PrintFormat) formatUseCase;
  final ValueChanged<PrintFormat> onSelect;
  final VoidCallback onClose;

  const _DocumentFormatPickerPanel({
    required this.selectedFormat,
    required this.formatShortName,
    required this.formatPaperSpec,
    required this.formatUseCase,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width < 560 ? width - 24 : 420.0;

    return Container(
      width: panelWidth,
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PurchaseEntryColors.shellBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 28,
            offset: Offset(-10, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: PurchaseEntryColors.purchaseAccent.withValues(
                        alpha: 0.14,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      color: PurchaseEntryColors.purchaseAccent,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOCUMENT FORMAT',
                          style: TextStyle(
                            color: PurchaseEntryColors.shellTitle,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose print paper and receipt size',
                          style: TextStyle(
                            color: PurchaseEntryColors.shellMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: PurchaseEntryColors.shellMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: PurchaseEntryColors.shellBorder, height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemBuilder: (context, index) {
                  final format = PrintFormat.values[index];
                  return _DocumentFormatOptionTile(
                    format: format,
                    selected: format == selectedFormat,
                    shortName: formatShortName(format),
                    paperSpec: formatPaperSpec(format),
                    useCase: formatUseCase(format),
                    onTap: () => onSelect(format),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemCount: PrintFormat.values.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrintControlSurface extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _PrintControlSurface({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellBg.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PurchaseEntryColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: PurchaseEntryColors.purchaseAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PurchaseEntryColors.shellTitle,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PurchaseEntryColors.shellMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _CopyStepper extends StatelessWidget {
  final int value;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _CopyStepper({
    required this.value,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellPanel,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: PurchaseEntryColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: canDecrease,
            onTap: onDecrease,
          ),
          SizedBox(
            width: 38,
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(
                  color: PurchaseEntryColors.purchaseAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: canIncrease,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: icon == Icons.add_rounded ? 'Add copy' : 'Remove copy',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? PurchaseEntryColors.purchaseAccent
                : PurchaseEntryColors.shellMuted.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }
}

class _PrintStatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;

  const _PrintStatusBadge({
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    const accent = PurchaseEntryColors.purchaseAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? accent.withValues(alpha: 0.14)
            : PurchaseEntryColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? accent.withValues(alpha: 0.40)
              : PurchaseEntryColors.shellBorder,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isActive ? accent : PurchaseEntryColors.shellMuted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PrintMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PrintMetaPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PurchaseEntryColors.shellBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: PurchaseEntryColors.shellMuted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PurchaseEntryColors.shellTitle,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseDisplayProfileCard extends StatelessWidget {
  final PurchaseBillingModel model;
  final Color accentColor;
  final int activeFieldCount;
  final int totalFieldCount;
  final bool isLoading;
  final VoidCallback onConfigure;
  final VoidCallback onReload;

  const _PurchaseDisplayProfileCard({
    required this.model,
    required this.accentColor,
    required this.activeFieldCount,
    required this.totalFieldCount,
    required this.isLoading,
    required this.onConfigure,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accentColor.withValues(alpha: 0.05),
          PurchaseEntryColors.shellPanel,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_metalLabel(model.metal)} Display Profile',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PurchaseEntryColors.shellTitle,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Purchase Billing Setup controls',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: PurchaseEntryColors.shellMuted,
                              fontSize: 11,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MetricPill(
                  icon: Icons.view_column_rounded,
                  label: isLoading
                      ? 'Loading Fields'
                      : '$activeFieldCount/$totalFieldCount Fields',
                  color: accentColor,
                ),
              ],
            ),
          ),
          const Divider(color: PurchaseEntryColors.shellBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onConfigure,
                    icon: const Icon(
                      Icons.dashboard_customize_rounded,
                      size: 18,
                    ),
                    label: Text(
                      '$activeFieldCount of $totalFieldCount visible',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor.withValues(alpha: 0.14),
                      foregroundColor: accentColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: accentColor.withValues(alpha: 0.34),
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onReload,
                    icon: const Icon(
                      Icons.settings_backup_restore_rounded,
                      size: 17,
                    ),
                    label: const Text('Reload Saved Purchase Setup'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PurchaseEntryColors.shellMuted,
                      side: const BorderSide(
                        color: PurchaseEntryColors.shellBorder,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
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

  static String _metalLabel(String metal) {
    switch (metal) {
      case 'gold':
        return 'GOLD';
      case 'silver':
        return 'SILVER';
      case 'platinum':
        return 'PLATINUM';
      case 'diamond':
        return 'DIAMOND';
      default:
        return metal.toUpperCase();
    }
  }
}

enum _PurchasePolicyPrintKey {
  sellerDeclaration,
  termsAndConditions,
  payoutPolicy,
  reclaimPolicy,
  footerMessage,
}

class _PurchasePolicyPrintDefinition {
  final _PurchasePolicyPrintKey key;
  final String label;
  final String description;

  const _PurchasePolicyPrintDefinition({
    required this.key,
    required this.label,
    required this.description,
  });
}

const List<_PurchasePolicyPrintDefinition> _purchasePolicyPrintDefinitions = [
  _PurchasePolicyPrintDefinition(
    key: _PurchasePolicyPrintKey.sellerDeclaration,
    label: 'Seller Declaration',
    description: 'Print seller ownership and responsibility declaration.',
  ),
  _PurchasePolicyPrintDefinition(
    key: _PurchasePolicyPrintKey.termsAndConditions,
    label: 'Terms & Conditions',
    description: 'Print purchase terms saved in Billing Setup.',
  ),
  _PurchasePolicyPrintDefinition(
    key: _PurchasePolicyPrintKey.payoutPolicy,
    label: 'Payout Policy',
    description: 'Print valuation, deduction and payout policy.',
  ),
  _PurchasePolicyPrintDefinition(
    key: _PurchasePolicyPrintKey.reclaimPolicy,
    label: 'Seller Reclaim Policy',
    description: 'Print reclaim window and penalty policy.',
  ),
  _PurchasePolicyPrintDefinition(
    key: _PurchasePolicyPrintKey.footerMessage,
    label: 'Footer Message',
    description: 'Print footer acknowledgement at the end of the invoice.',
  ),
];

bool _purchasePolicyPrintValue(
  PurchaseBillingModel model,
  _PurchasePolicyPrintKey key,
) {
  switch (key) {
    case _PurchasePolicyPrintKey.sellerDeclaration:
      return model.printSellerDeclaration;
    case _PurchasePolicyPrintKey.termsAndConditions:
      return model.printTermsAndConditions;
    case _PurchasePolicyPrintKey.payoutPolicy:
      return model.printBuybackPolicy;
    case _PurchasePolicyPrintKey.reclaimPolicy:
      return model.printReturnPolicy;
    case _PurchasePolicyPrintKey.footerMessage:
      return model.printFooterMessage;
  }
}

PurchaseBillingModel _setPurchasePolicyPrintValue(
  PurchaseBillingModel model,
  _PurchasePolicyPrintKey key,
  bool value,
) {
  switch (key) {
    case _PurchasePolicyPrintKey.sellerDeclaration:
      return model.copyWith(printSellerDeclaration: value);
    case _PurchasePolicyPrintKey.termsAndConditions:
      return model.copyWith(printTermsAndConditions: value);
    case _PurchasePolicyPrintKey.payoutPolicy:
      return model.copyWith(printBuybackPolicy: value);
    case _PurchasePolicyPrintKey.reclaimPolicy:
      return model.copyWith(printReturnPolicy: value);
    case _PurchasePolicyPrintKey.footerMessage:
      return model.copyWith(printFooterMessage: value);
  }
}

class _PurchaseDisplayProfileDrawer extends StatefulWidget {
  final PurchaseBillingModel model;
  final Color accentColor;
  final Future<PurchaseBillingModel> Function(
    String metal,
    PurchaseBillingFieldKey key,
    bool value,
  ) onFieldChanged;
  final Future<PurchaseBillingModel> Function(
    String metal,
    _PurchasePolicyPrintKey key,
    bool value,
  ) onPolicyPrintChanged;
  final Future<PurchaseBillingModel> Function(String metal) onReload;
  final Future<void> Function(String metal) onSave;
  final VoidCallback onClose;

  const _PurchaseDisplayProfileDrawer({
    required this.model,
    required this.accentColor,
    required this.onFieldChanged,
    required this.onPolicyPrintChanged,
    required this.onReload,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<_PurchaseDisplayProfileDrawer> createState() =>
      _PurchaseDisplayProfileDrawerState();
}

class _PurchaseDisplayProfileDrawerState
    extends State<_PurchaseDisplayProfileDrawer> {
  late PurchaseBillingModel _model = widget.model;
  final Set<PurchaseBillingFieldKey> _updatingFields = {};
  final Set<_PurchasePolicyPrintKey> _updatingPolicyFields = {};
  final Map<PurchaseBillingFieldKey, int> _fieldUpdateSerials = {};
  final Map<_PurchasePolicyPrintKey, int> _policyUpdateSerials = {};
  bool _isReloading = false;
  bool _isSaving = false;

  @override
  void didUpdateWidget(covariant _PurchaseDisplayProfileDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model && _updatingFields.isEmpty) {
      _model = widget.model;
    }
  }

  Future<void> _setField(PurchaseBillingFieldKey key, bool value) async {
    final previous = _model;
    final requestSerial = (_fieldUpdateSerials[key] ?? 0) + 1;
    _fieldUpdateSerials[key] = requestSerial;
    final optimistic =
        PurchaseBillingMetalProfiles.setValue(previous, key, value);
    setState(() {
      _model = optimistic;
      _updatingFields.add(key);
    });

    try {
      final saved = await widget.onFieldChanged(_model.metal, key, value);
      if (!mounted || _fieldUpdateSerials[key] != requestSerial) return;
      setState(() => _model = saved);
    } catch (_) {
      if (!mounted || _fieldUpdateSerials[key] != requestSerial) return;
      setState(() => _model = previous);
    } finally {
      if (mounted && _fieldUpdateSerials[key] == requestSerial) {
        setState(() => _updatingFields.remove(key));
      }
    }
  }

  Future<void> _setPolicyPrintField(
    _PurchasePolicyPrintKey key,
    bool value,
  ) async {
    final previous = _model;
    final requestSerial = (_policyUpdateSerials[key] ?? 0) + 1;
    _policyUpdateSerials[key] = requestSerial;
    final optimistic = _setPurchasePolicyPrintValue(previous, key, value);
    setState(() {
      _model = optimistic;
      _updatingPolicyFields.add(key);
    });

    try {
      final saved = await widget.onPolicyPrintChanged(_model.metal, key, value);
      if (!mounted || _policyUpdateSerials[key] != requestSerial) return;
      setState(() => _model = saved);
    } catch (_) {
      if (!mounted || _policyUpdateSerials[key] != requestSerial) return;
      setState(() => _model = previous);
    } finally {
      if (mounted && _policyUpdateSerials[key] == requestSerial) {
        setState(() => _updatingPolicyFields.remove(key));
      }
    }
  }

  Future<void> _reload() async {
    setState(() => _isReloading = true);
    final restored = await widget.onReload(_model.metal);
    if (!mounted) return;
    setState(() {
      _model = restored;
      _isReloading = false;
      _updatingFields.clear();
      _updatingPolicyFields.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await widget.onSave(_model.metal);
    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width < 560 ? width - 24 : 430.0;
    final fields = PurchaseBillingMetalProfiles.fieldsFor(_model.metal);

    return Container(
      width: panelWidth,
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PurchaseEntryColors.shellBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 28,
            offset: Offset(-10, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: widget.accentColor,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_PurchaseDisplayProfileCard._metalLabel(_model.metal)} DISPLAY',
                          style: const TextStyle(
                            color: PurchaseEntryColors.shellTitle,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Purchase Billing Setup controls',
                          style: TextStyle(
                            color: PurchaseEntryColors.shellMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: PurchaseEntryColors.shellMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: PurchaseEntryColors.shellBorder, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  const _PurchaseDisplayDrawerSectionTitle(
                    title: 'ITEM DISPLAY',
                    subtitle:
                        'Metal-wise item and seller fields from Purchase Billing Setup',
                  ),
                  const SizedBox(height: 10),
                  for (final field in fields) ...[
                    _PurchaseDisplayToggleTile(
                      field: field,
                      value: PurchaseBillingMetalProfiles.valueFor(
                        _model,
                        field.key,
                      ),
                      accentColor: widget.accentColor,
                      isUpdating: _updatingFields.contains(field.key),
                      onChanged: (value) => _setField(field.key, value),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                  const _PurchaseDisplayDrawerSectionTitle(
                    title: 'POLICY & FOOTER',
                    subtitle:
                        'Control declaration, terms, policies and footer printed on PDF',
                  ),
                  const SizedBox(height: 10),
                  for (final policy in _purchasePolicyPrintDefinitions) ...[
                    _PurchasePolicyPrintToggleTile(
                      definition: policy,
                      value: _purchasePolicyPrintValue(_model, policy.key),
                      accentColor: widget.accentColor,
                      isUpdating: _updatingPolicyFields.contains(policy.key),
                      onChanged: (value) =>
                          _setPolicyPrintField(policy.key, value),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            _PurchaseDisplayDrawerFooter(
              accentColor: widget.accentColor,
              isSaving: _isSaving,
              isReloading: _isReloading,
              onReload: _reload,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseDisplayDrawerFooter extends StatelessWidget {
  final Color accentColor;
  final bool isSaving;
  final bool isReloading;
  final VoidCallback onReload;
  final VoidCallback onSave;

  const _PurchaseDisplayDrawerFooter({
    required this.accentColor,
    required this.isSaving,
    required this.isReloading,
    required this.onReload,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: PurchaseEntryColors.shellBg,
        border: Border(top: BorderSide(color: PurchaseEntryColors.shellBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isSaving || isReloading ? null : onReload,
              icon: isReloading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: accentColor,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.settings_backup_restore_rounded, size: 17),
              label: Text(isReloading ? 'RELOADING...' : 'RELOAD SAVED'),
              style: OutlinedButton.styleFrom(
                foregroundColor: PurchaseEntryColors.shellMuted,
                side: const BorderSide(color: PurchaseEntryColors.shellBorder),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isSaving || isReloading ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 17),
              label: Text(isSaving ? 'SAVING...' : 'SAVE DISPLAY PROFILE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseDisplayDrawerSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PurchaseDisplayDrawerSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: PurchaseEntryColors.shellTitle,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: PurchaseEntryColors.shellMuted,
            fontSize: 10.5,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PurchasePolicyPrintToggleTile extends StatelessWidget {
  final _PurchasePolicyPrintDefinition definition;
  final bool value;
  final Color accentColor;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  const _PurchasePolicyPrintToggleTile({
    required this.definition,
    required this.value,
    required this.accentColor,
    this.isUpdating = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: value
            ? accentColor.withValues(alpha: 0.10)
            : PurchaseEntryColors.shellBg.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? accentColor.withValues(alpha: 0.42)
              : PurchaseEntryColors.shellBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: value ? accentColor : PurchaseEntryColors.shellMuted,
            size: 18,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  definition.label,
                  style: const TextStyle(
                    color: PurchaseEntryColors.shellTitle,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  definition.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PurchaseEntryColors.shellMuted,
                    fontSize: 10.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedOpacity(
            opacity: isUpdating ? 1 : 0,
            duration: const Duration(milliseconds: 140),
            child: SizedBox(
              width: 14,
              height: 14,
              child: isUpdating
                  ? CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 1.7,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeThumbColor: accentColor,
            activeTrackColor: accentColor.withValues(alpha: 0.32),
            inactiveThumbColor: PurchaseEntryColors.shellMuted,
            inactiveTrackColor: PurchaseEntryColors.shellBg,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PurchaseDisplayToggleTile extends StatelessWidget {
  final PurchaseBillingFieldDefinition field;
  final bool value;
  final Color accentColor;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  const _PurchaseDisplayToggleTile({
    required this.field,
    required this.value,
    required this.accentColor,
    this.isUpdating = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: value
            ? accentColor.withValues(alpha: 0.10)
            : PurchaseEntryColors.shellBg.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? accentColor.withValues(alpha: 0.42)
              : PurchaseEntryColors.shellBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: const TextStyle(
                    color: PurchaseEntryColors.shellTitle,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  field.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PurchaseEntryColors.shellMuted,
                    fontSize: 10.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedOpacity(
            opacity: isUpdating ? 1 : 0,
            duration: const Duration(milliseconds: 140),
            child: SizedBox(
              width: 14,
              height: 14,
              child: isUpdating
                  ? CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 1.7,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeThumbColor: accentColor,
            activeTrackColor: accentColor.withValues(alpha: 0.32),
            inactiveThumbColor: PurchaseEntryColors.shellMuted,
            inactiveTrackColor: PurchaseEntryColors.shellBg,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentFormatOptionTile extends StatelessWidget {
  final PrintFormat format;
  final bool selected;
  final String shortName;
  final String paperSpec;
  final String useCase;
  final VoidCallback onTap;

  const _DocumentFormatOptionTile({
    required this.format,
    required this.selected,
    required this.shortName,
    required this.paperSpec,
    required this.useCase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.12)
              : PurchaseEntryColors.shellBg.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? PurchaseEntryColors.purchaseAccent
                : PurchaseEntryColors.shellBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            _FormatIcon(format: format),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? PurchaseEntryColors.purchaseAccent
                          : PurchaseEntryColors.shellTitle,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$shortName  |  $paperSpec  |  $useCase',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PurchaseEntryColors.shellMuted,
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? PurchaseEntryColors.purchaseAccent
                  : PurchaseEntryColors.shellMuted,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatIcon extends StatelessWidget {
  final PrintFormat format;

  const _FormatIcon({required this.format});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.28),
        ),
      ),
      child: Icon(
        format.icon,
        color: PurchaseEntryColors.purchaseAccent,
        size: 21,
      ),
    );
  }
}

class _FormatDetailPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FormatDetailPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PurchaseEntryColors.shellBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: PurchaseEntryColors.shellMuted, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PurchaseEntryColors.shellTitle,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
