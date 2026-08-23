import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../features/print_templates/domain/print_template_registry.dart';
import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../logic/purchase/purchase_voucher_print_service.dart';
import '../../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../repositories/setting/billing_setup/purchase_billing_repo.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import '../../sales_orders/sales_pos/pos_invoice_template_selector.dart';

class PurchaseVoucherWorkspaceScreen extends StatefulWidget {
  final PurchaseEntryController controller;

  const PurchaseVoucherWorkspaceScreen({
    super.key,
    required this.controller,
  });

  static Future<void> push(
    BuildContext context, {
    required PurchaseEntryController controller,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: PurchaseVoucherWorkspaceScreen(controller: controller),
        ),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  @override
  State<PurchaseVoucherWorkspaceScreen> createState() =>
      _PurchaseVoucherWorkspaceScreenState();
}

class _PurchaseVoucherWorkspaceScreenState
    extends State<PurchaseVoucherWorkspaceScreen> {
  final PurchaseBillingRepo _billingRepo = PurchaseBillingRepo();

  bool _isPrinting = false;
  bool _isExporting = false;
  bool _isLoadingSetup = true;
  int _previewSerial = 0;
  int _printCopies = 1;
  bool _includeDuplicateStamp = false;
  bool _usePrinterDriverSettings = true;
  PrintFormat _selectedFormat = PrintFormat.a4;
  String _selectedTemplateId = PrintTemplateRegistry.defaultTemplateId;
  PurchaseMetalType? _activeMetal;
  Map<PurchaseMetalType, PurchaseBillingModel> _settingsByMetal = {};

  PurchaseEntryController get _ctrl => widget.controller;

  String _money(double value) => 'Rs. ${value.toStringAsFixed(2)}';

  List<PurchaseMetalType> get _presentMetals {
    const ordered = [
      PurchaseMetalType.gold,
      PurchaseMetalType.silver,
      PurchaseMetalType.platinum,
      PurchaseMetalType.diamond,
    ];
    final present = _ctrl.items
        .where((item) => item.hasContent)
        .map((item) => item.metal)
        .toSet();
    return ordered.where(present.contains).toList(growable: false);
  }

  PurchaseMetalType? get _effectiveActiveMetal {
    final metals = _presentMetals;
    if (metals.isEmpty) return null;
    if (_activeMetal != null && metals.contains(_activeMetal)) {
      return _activeMetal;
    }
    return metals.first;
  }

  @override
  void initState() {
    super.initState();
    _loadBillingSetup();
  }

  Future<void> _loadBillingSetup({PurchaseMetalType? preferredMetal}) async {
    setState(() => _isLoadingSetup = true);
    final metals = _presentMetals;
    final settings = <PurchaseMetalType, PurchaseBillingModel>{};
    for (final metal in metals) {
      settings[metal] =
          await _billingRepo.fetchForMetal(_billingMetalFor(metal));
    }

    final activeMetal =
        preferredMetal != null && metals.contains(preferredMetal)
            ? preferredMetal
            : metals.isEmpty
                ? null
                : metals.first;
    final configuredTemplate = activeMetal == null
        ? ''
        : settings[activeMetal]?.selectedTemplate ?? '';

    if (!mounted) return;
    setState(() {
      _settingsByMetal = settings;
      _activeMetal = activeMetal;
      if (configuredTemplate.trim().isNotEmpty) {
        _selectedTemplateId =
            PrintTemplateRegistry.byId(configuredTemplate.trim()).id;
      }
      _isLoadingSetup = false;
      _previewSerial++;
    });
  }

  String _billingMetalFor(PurchaseMetalType metal) {
    switch (metal) {
      case PurchaseMetalType.gold:
        return BillingMetal.gold;
      case PurchaseMetalType.silver:
        return BillingMetal.silver;
      case PurchaseMetalType.platinum:
        return BillingMetal.platinum;
      case PurchaseMetalType.diamond:
        return BillingMetal.diamond;
    }
  }

  String get _fileName {
    final seller = _ctrl.nameCtrl.text.trim().isEmpty
        ? 'customer-metal-purchase'
        : _ctrl.nameCtrl.text.trim();
    final cleanSeller = seller
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '')
        .toLowerCase();
    return '${cleanSeller}_${_ctrl.formattedPurchaseNo}.pdf';
  }

  Future<Uint8List> _buildPdf(PdfPageFormat _) {
    return PurchaseVoucherPrintService.buildDraftBytes(
      _ctrl,
      settingsOverride: _settingsByMetal.isEmpty ? null : _settingsByMetal,
      selectedTemplateId: _selectedTemplateId,
      pageFormat: _pageFormat(),
      copies: _printCopies,
      includeDuplicateStamp: _includeDuplicateStamp,
    );
  }

  Future<void> _printVoucher() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      await PurchaseVoucherPrintService.printDraft(
        _ctrl,
        settingsOverride: _settingsByMetal.isEmpty ? null : _settingsByMetal,
        selectedTemplateId: _selectedTemplateId,
        pageFormat: _pageFormat(),
        copies: _printCopies,
        includeDuplicateStamp: _includeDuplicateStamp,
      );
      if (!mounted) return;
      AppFeedback.success(
        context,
        message: 'Purchase voucher sent to printer.',
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: 'Purchase voucher print failed. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _exportVoucher() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final bytes = await PurchaseVoucherPrintService.buildDraftBytes(
        _ctrl,
        settingsOverride: _settingsByMetal.isEmpty ? null : _settingsByMetal,
        selectedTemplateId: _selectedTemplateId,
        pageFormat: _pageFormat(),
        copies: _printCopies,
        includeDuplicateStamp: _includeDuplicateStamp,
      );
      await Printing.sharePdf(bytes: bytes, filename: _fileName);
      if (!mounted) return;
      AppFeedback.success(
        context,
        message: 'Purchase voucher PDF is ready to export.',
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: 'Purchase voucher export failed. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PurchaseEntryColors.bodyBg,
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 430,
              child: _buildControlPanel(),
            ),
            Expanded(child: _buildPreviewPanel()),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: PurchaseEntryColors.shellBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 18,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormatGrid(),
                  const SizedBox(height: 16),
                  PosInvoiceTemplateSelector(
                    selectedTemplateId: _selectedTemplateId,
                    documentType: PrintTemplateDocumentType.purchaseVoucher,
                    title: 'VOUCHER DESIGN',
                    onChanged: _selectTemplate,
                  ),
                  const SizedBox(height: 16),
                  _buildVoucherContext(),
                  const SizedBox(height: 16),
                  _buildVoucherDisplay(),
                  const SizedBox(height: 16),
                  _WorkspaceCard(
                    title: 'DOCUMENT SETUP',
                    subtitle: 'Customer old-metal acquisition voucher',
                    icon: PurchaseEntryIcons.invoiceOutline,
                    children: [
                      _metric('Voucher No.', _ctrl.formattedPurchaseNo),
                      _metric('Format', 'A4 professional voucher'),
                      _metric('Seller', _ctrl.nameCtrl.text.trim()),
                      _metric('Items',
                          '${_ctrl.items.where((i) => i.hasContent).length}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _WorkspaceCard(
                    title: 'VALUATION SUMMARY',
                    subtitle: 'Assessed value and payout status',
                    icon: PurchaseEntryIcons.purchaseHeader,
                    children: [
                      _metric(
                        'Assessed Metal Value',
                        _money(_ctrl.grossPurchaseAmount),
                      ),
                      _metric('Seller Payable', _money(_ctrl.grandTotal)),
                      _metric('Payout Released', _money(_ctrl.totalPaid)),
                      _metric(_balanceLabel(), _money(_ctrl.balanceDue.abs())),
                      if (_ctrl.hasPendingSellerPayout &&
                          _ctrl.payoutCommitmentDate != null)
                        _metric(
                          'Payout Commitment',
                          PurchaseEntryController.formatDisplayDate(
                            _ctrl.payoutCommitmentDate!,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPrintControls(),
                ],
              ),
            ),
          ),
          _buildFooterActions(),
        ],
      ),
    );
  }

  void _selectTemplate(String templateId) {
    setState(() {
      _selectedTemplateId = PrintTemplateRegistry.byId(templateId).id;
      _previewSerial++;
    });
  }

  void _selectFormat(PrintFormat format) {
    setState(() {
      _selectedFormat = format;
      _previewSerial++;
    });
  }

  Future<void> _selectMetal(PurchaseMetalType metal) async {
    setState(() {
      _activeMetal = metal;
      final template = _settingsByMetal[metal]?.selectedTemplate.trim() ?? '';
      if (template.isNotEmpty) {
        _selectedTemplateId = PrintTemplateRegistry.byId(template).id;
      }
      _previewSerial++;
    });
  }

  Future<void> _restoreActiveMetalSetup() async {
    final metal = _effectiveActiveMetal;
    if (metal == null) return;
    await _loadBillingSetup(preferredMetal: metal);
  }

  void _toggleActiveMetalField(String key) {
    final metal = _effectiveActiveMetal;
    if (metal == null) return;
    final current = _settingsByMetal[metal] ??
        PurchaseBillingModel.defaultFor(_billingMetalFor(metal));
    final updated = _copySettingWithToggle(current, key);
    setState(() {
      _settingsByMetal = {
        ..._settingsByMetal,
        metal: updated,
      };
      _previewSerial++;
    });
  }

  PurchaseBillingModel _copySettingWithToggle(
    PurchaseBillingModel settings,
    String key,
  ) {
    switch (key) {
      case 'gross':
        return settings.copyWith(showGrossWeight: !settings.showGrossWeight);
      case 'less':
        return settings.copyWith(showLessWeight: !settings.showLessWeight);
      case 'net':
        return settings.copyWith(showNetWeight: !settings.showNetWeight);
      case 'purity':
        return settings.copyWith(showPurity: !settings.showPurity);
      case 'fine':
        return settings.copyWith(showFineWeight: !settings.showFineWeight);
      case 'rate':
        return settings.copyWith(showRate: !settings.showRate);
      case 'value':
        return settings.copyWith(showTotalValue: !settings.showTotalValue);
      case 'huid':
        return settings.copyWith(showHuid: !settings.showHuid);
      case 'pan':
        return settings.copyWith(showPanNumber: !settings.showPanNumber);
      default:
        return settings;
    }
  }

  Widget _buildFormatGrid() {
    return _WorkspaceCard(
      title: 'DOCUMENT FORMAT',
      subtitle: 'Choose paper format for voucher preview',
      icon: Icons.description_rounded,
      children: [
        const SizedBox(height: 4),
        Row(
          children: PrintFormat.values.map((format) {
            final isSelected = _selectedFormat == format;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _selectFormat(format),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? PurchaseEntryColors.purchaseAccent
                              .withValues(alpha: 0.14)
                          : PurchaseEntryColors.shellBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? PurchaseEntryColors.purchaseAccent
                            : PurchaseEntryColors.shellBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          format.icon,
                          color: isSelected
                              ? PurchaseEntryColors.purchaseAccent
                              : PurchaseEntryColors.shellMuted,
                          size: 19,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatShortName(format),
                          style: TextStyle(
                            color: isSelected
                                ? PurchaseEntryColors.purchaseAccent
                                : PurchaseEntryColors.shellTitle,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 10),
        _OptionLine(_formatUseCase(_selectedFormat)),
      ],
    );
  }

  Widget _buildVoucherContext() {
    final metals = _presentMetals;
    final metalLabel = metals.isEmpty
        ? 'No Metal Items'
        : metals.map((metal) => metal.displayName).join(' + ');

    return _WorkspaceCard(
      title: 'VOUCHER CONTEXT',
      subtitle: 'Customer metal purchase document profile',
      icon: Icons.tune_rounded,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const _ContextChip(Icons.person_rounded, 'Customer Seller'),
            const _ContextChip(Icons.receipt_long_rounded, 'Purchase Voucher'),
            _ContextChip(Icons.category_rounded, metalLabel),
          ],
        ),
      ],
    );
  }

  Widget _buildVoucherDisplay() {
    final metals = _presentMetals;
    final activeMetal = _effectiveActiveMetal;

    if (_isLoadingSetup) {
      return const _WorkspaceCard(
        title: 'VOUCHER DISPLAY',
        subtitle: 'Loading purchase billing setup',
        icon: Icons.view_column_rounded,
        children: [
          _OptionLine('Loading saved metal display profile...'),
        ],
      );
    }

    if (metals.isEmpty || activeMetal == null) {
      return const _WorkspaceCard(
        title: 'VOUCHER DISPLAY',
        subtitle: 'Metal-wise print controls',
        icon: Icons.view_column_rounded,
        children: [
          _OptionLine('Add purchase items to load metal-wise controls.'),
        ],
      );
    }

    final settings = _settingsByMetal[activeMetal] ??
        PurchaseBillingModel.defaultFor(_billingMetalFor(activeMetal));
    final fields = _displayFields(settings);
    final enabledCount = fields.where((field) => field.enabled).length;

    return _WorkspaceCard(
      title: 'VOUCHER DISPLAY',
      subtitle: '${activeMetal.displayName} purchase billing setup controls',
      icon: Icons.view_column_rounded,
      children: [
        if (metals.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metals.map((metal) {
              return _MetalSelectorChip(
                label: '${metal.displayName} Voucher',
                selected: metal == activeMetal,
                onTap: () => _selectMetal(metal),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: _SmallMetricPill(
                icon: Icons.view_column_rounded,
                label: '$enabledCount/${fields.length} Fields',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SmallMetricPill(
                icon: Icons.description_outlined,
                label: PrintTemplateRegistry.labelFor(_selectedTemplateId),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fields
              .map(
                (field) => _TogglePill(
                  label: field.label,
                  selected: field.enabled,
                  onTap: () => _toggleActiveMetalField(field.key),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        _ProfileActionRow(onReload: _restoreActiveMetalSetup),
      ],
    );
  }

  Widget _buildPrintControls() {
    final canDecrease = _printCopies > 1;
    final canIncrease = _printCopies < 5;

    return _WorkspaceCard(
      title: 'PRINT CONTROLS',
      subtitle: 'Copies, duplicate mark and printer driver settings',
      icon: PurchaseEntryIcons.printVoucher,
      children: [
        _PrintOptionSurface(
          icon: Icons.layers_rounded,
          title: 'Print Copies',
          subtitle: _printCopies == 1 ? 'Single copy' : '$_printCopies copies',
          trailing: _CopyStepper(
            value: _printCopies,
            canDecrease: canDecrease,
            canIncrease: canIncrease,
            onDecrease: () => setState(() {
              _printCopies = (_printCopies - 1).clamp(1, 5).toInt();
              if (_printCopies == 1) _includeDuplicateStamp = false;
              _previewSerial++;
            }),
            onIncrease: () => setState(() {
              _printCopies = (_printCopies + 1).clamp(1, 5).toInt();
              _previewSerial++;
            }),
          ),
        ),
        const SizedBox(height: 10),
        _PrintOptionSurface(
          icon: Icons.verified_rounded,
          title: 'Duplicate Stamp',
          subtitle: 'Mark additional copies as duplicate',
          trailing: Switch(
            value: _includeDuplicateStamp,
            onChanged: _printCopies > 1
                ? (value) => setState(() {
                      _includeDuplicateStamp = value;
                      _previewSerial++;
                    })
                : null,
            activeThumbColor: PurchaseEntryColors.purchaseAccent,
          ),
        ),
        const SizedBox(height: 10),
        _PrintOptionSurface(
          icon: Icons.settings_applications_rounded,
          title: 'Printer Driver Settings',
          subtitle: 'Use saved duplex, tray and printer defaults',
          trailing: Switch(
            value: _usePrinterDriverSettings,
            onChanged: (value) => setState(() {
              _usePrinterDriverSettings = value;
              _previewSerial++;
            }),
            activeThumbColor: PurchaseEntryColors.purchaseAccent,
          ),
        ),
      ],
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

  String _formatUseCase(PrintFormat format) {
    switch (format) {
      case PrintFormat.a4:
        return 'A4 professional voucher for records and seller signature.';
      case PrintFormat.thermal3inch:
        return 'Counter receipt option. A4 voucher layout remains the default.';
      case PrintFormat.thermal2inch:
        return 'Compact receipt option. A4 voucher layout remains the default.';
    }
  }

  List<_DisplayField> _displayFields(PurchaseBillingModel settings) {
    return [
      _DisplayField('gross', 'Gross', settings.showGrossWeight),
      _DisplayField('less', 'Less', settings.showLessWeight),
      _DisplayField('net', 'Net', settings.showNetWeight),
      _DisplayField('purity', 'Purity', settings.showPurity),
      _DisplayField('fine', 'Fine', settings.showFineWeight),
      _DisplayField('rate', 'Rate', settings.showRate),
      _DisplayField('value', 'Value', settings.showTotalValue),
      _DisplayField('huid', 'HUID', settings.showHuid),
      _DisplayField('pan', 'PAN / ID', settings.showPanNumber),
    ];
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: const BoxDecoration(
        color: PurchaseEntryColors.shellPanel,
        border: Border(
          bottom: BorderSide(color: PurchaseEntryColors.shellBorder),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to purchase entry',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              PurchaseEntryIcons.backArrow,
              color: PurchaseEntryColors.shellTitle,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PURCHASE VOUCHER WORKSPACE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: PurchaseEntryColors.shellTitle,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Review the voucher before printing',
                  style: TextStyle(
                    color: PurchaseEntryColors.shellMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      color: PurchaseEntryColors.bodyBorder.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(28),
      child: PdfPreview(
        key: ValueKey(
          'purchase-voucher-preview-$_previewSerial-$_selectedTemplateId-${_selectedFormat.name}',
        ),
        build: _buildPdf,
        pdfFileName: _fileName,
        initialPageFormat: _pageFormat(),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        maxPageWidth: 900,
      ),
    );
  }

  PdfPageFormat _pageFormat() {
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

  Widget _buildFooterActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: const BoxDecoration(
        color: PurchaseEntryColors.shellPanel,
        border: Border(top: BorderSide(color: PurchaseEntryColors.shellBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusStrip(
            isPending: _ctrl.hasPendingSellerPayout,
            isExcess: _ctrl.hasSellerPayoutExcess,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WorkspaceActionButton(
                  label: _isExporting ? 'Exporting' : 'Export PDF',
                  icon: Icons.download_rounded,
                  onPressed: _isExporting ? null : _exportVoucher,
                  isBusy: _isExporting,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WorkspaceActionButton(
                  label: _isPrinting ? 'Printing' : 'Print Voucher',
                  icon: Icons.print_rounded,
                  onPressed: _isPrinting ? null : _printVoucher,
                  isBusy: _isPrinting,
                  filled: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _balanceLabel() {
    if (_ctrl.hasSellerPayoutExcess) return 'Payout Excess';
    if (_ctrl.hasPendingSellerPayout) return 'Pending Seller Payout';
    return 'Payout Status';
  }

  Widget _metric(String label, String value) {
    final display = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: PurchaseEntryColors.shellMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              display,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: PurchaseEntryColors.shellTitle,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const _WorkspaceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PurchaseEntryColors.shellBorder),
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
                  color: PurchaseEntryColors.purchaseAccent
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: PurchaseEntryColors.purchaseAccent
                        .withValues(alpha: 0.34),
                  ),
                ),
                child: Icon(
                  icon,
                  color: PurchaseEntryColors.purchaseAccent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PurchaseEntryColors.shellTitle,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PurchaseEntryColors.shellMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _OptionLine extends StatelessWidget {
  final String text;

  const _OptionLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: PurchaseEntryColors.purchaseAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: PurchaseEntryColors.shellTitle,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContextChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
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
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetalSelectorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MetalSelectorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.14)
              : PurchaseEntryColors.shellBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? PurchaseEntryColors.purchaseAccent
                : PurchaseEntryColors.shellBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.receipt_long_rounded,
              size: 15,
              color: selected
                  ? PurchaseEntryColors.purchaseAccent
                  : PurchaseEntryColors.shellMuted,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? PurchaseEntryColors.purchaseAccent
                    : PurchaseEntryColors.shellTitle,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallMetricPill({
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

class _TogglePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.14)
              : PurchaseEntryColors.shellBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? PurchaseEntryColors.purchaseAccent
                : PurchaseEntryColors.shellBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? PurchaseEntryColors.purchaseAccent
                : PurchaseEntryColors.shellMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  final VoidCallback onReload;

  const _ProfileActionRow({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onReload,
      icon: const Icon(Icons.refresh_rounded, size: 16),
      label: const Text('Reload Saved Billing Setup'),
      style: OutlinedButton.styleFrom(
        foregroundColor: PurchaseEntryColors.purchaseAccent,
        side: BorderSide(
          color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.55),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}

class _PrintOptionSurface extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _PrintOptionSurface({
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
                    fontSize: 13,
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
    return InkWell(
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
    );
  }
}

class _DisplayField {
  final String key;
  final String label;
  final bool enabled;

  const _DisplayField(this.key, this.label, this.enabled);
}

class _StatusStrip extends StatelessWidget {
  final bool isPending;
  final bool isExcess;

  const _StatusStrip({
    required this.isPending,
    required this.isExcess,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExcess
        ? PurchaseEntryColors.warning
        : isPending
            ? PurchaseEntryColors.purchaseAccent
            : PurchaseEntryColors.success;
    final title = isExcess
        ? 'Payout Excess'
        : isPending
            ? 'Pending Seller Payout'
            : 'Ready to Print';
    final subtitle = isExcess
        ? 'Review released payout before saving'
        : isPending
            ? 'Remaining payout is tracked with commitment date'
            : 'Voucher is fully settled';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? PurchaseEntryIcons.dueWarning : Icons.verified_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
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
    );
  }
}

class _WorkspaceActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isBusy;
  final bool filled;

  const _WorkspaceActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isBusy = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.black : PurchaseEntryColors.shellTitle;
    final background =
        filled ? PurchaseEntryColors.purchaseAccent : Colors.transparent;

    return SizedBox(
      height: 48,
      child: filled
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: _icon(foreground),
              label: _label(foreground),
              style: ElevatedButton.styleFrom(
                backgroundColor: background,
                foregroundColor: foreground,
                disabledBackgroundColor:
                    PurchaseEntryColors.shellBorder.withValues(alpha: 0.60),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: _icon(foreground),
              label: _label(foreground),
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                disabledForegroundColor: PurchaseEntryColors.shellMuted,
                side: BorderSide(
                  color: PurchaseEntryColors.shellTitle.withValues(alpha: 0.28),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
    );
  }

  Widget _icon(Color color) {
    if (!isBusy) {
      return Icon(icon, color: color, size: 18);
    }
    return SizedBox(
      width: 17,
      height: 17,
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: 2,
      ),
    );
  }

  Widget _label(Color color) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
