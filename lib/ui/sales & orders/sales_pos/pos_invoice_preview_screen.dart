// ==========================================
// FILE: pos_invoice_preview_screen.dart
// TYPE: Full Screen Master UI (The Hub)
// DESCRIPTION: 2-Panel Invoice Generation Hub.
//               UPGRADED: Tab-based Configuration
//               UPGRADED: Inline Animated Save Button (No SnackBar)
// ==========================================

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';
import '../../../models/sales & orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../logic/sales & orders/sales pos/pos_invoice_controller.dart';

class PosInvoicePreviewScreen extends StatefulWidget {
  final PosBillingController billingCtrl;

  const PosInvoicePreviewScreen({super.key, required this.billingCtrl});

  static Future<void> push(BuildContext context,
      {required PosBillingController billingCtrl}) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) =>
            PosInvoicePreviewScreen(billingCtrl: billingCtrl),
        transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  State<PosInvoicePreviewScreen> createState() =>
      _PosInvoicePreviewScreenState();
}

class _PosInvoicePreviewScreenState extends State<PosInvoicePreviewScreen>
    with TickerProviderStateMixin {
  late PosInvoiceController _invCtrl;
  String _selectedTemplate = 'Standard Modern';

  // Customization Tabs State
  BillingMode _configMode = BillingMode.retail;
  BillType _configType = BillType.normal;

  //  Animation state for the save button.
  bool _isSavingPdf = false;
  bool _isPdfSaved = false;

  @override
  void initState() {
    super.initState();
    _invCtrl = PosInvoiceController(billing: widget.billingCtrl);

    _configMode = widget.billingCtrl.billingMode;
    _configType = widget.billingCtrl.billType;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _invCtrl.generateInvoice();
    });
    _invCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _invCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SalesPosColors.bodyBg,
      body: SafeArea(
        child: Row(
          children: [
            // ================= LEFT PANEL: CONTROLS =================
            Container(
              width: 440,
              decoration: const BoxDecoration(
                color: SalesPosColors.shellBg,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(2, 0))
                ],
              ),
              child: Column(
                children: [
                  _buildHubHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTemplateSelector(),
                          const SizedBox(height: 24),
                          _buildFormatGrid(),
                          const SizedBox(height: 24),
                          _buildCategorizedCustomization(),
                          const SizedBox(height: 24),
                          //  Due date section shown when a balance remains outstanding.
                          _buildDueDateSection(),
                          _buildPrintOptions(),
                        ],
                      ),
                    ),
                  ),
                  _buildActionFooter(),
                ],
              ),
            ),

            // ================= RIGHT PANEL: LIVE PREVIEW =================
            Expanded(
              child: Container(
                color: SalesPosColors.bodyBorder.withValues(alpha: 0.3),
                child: _buildRightPreviewPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: SalesPosColors.shellBorder))),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: SalesPosColors.shellTextTitle, size: 20),
              onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("INVOICE HUB",
                    style: TextStyle(
                        color: SalesPosColors.shellTextTitle,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
                Text("Design, Settings & Print",
                    style: TextStyle(
                        color: SalesPosColors.shellTextMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("INVOICE TEMPLATE",
            style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
              color: SalesPosColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SalesPosColors.shellBorder)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTemplate,
              isExpanded: true,
              dropdownColor: SalesPosColors.shellPanelBg,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: SalesPosColors.brandGold),
              items: ['Standard Modern', 'Classic Bill', 'Minimalist']
                  .map((String value) {
                return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value,
                        style: const TextStyle(
                            color: SalesPosColors.shellTextTitle,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedTemplate = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PAPER SIZE",
            style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Row(
          children: PrintFormat.values.map((fmt) {
            final isSelected = _invCtrl.selectedFormat == fmt;
            return Expanded(
              child: GestureDetector(
                onTap: () => _invCtrl.switchFormat(fmt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? SalesPosColors.brandGold.withValues(alpha: 0.15)
                        : SalesPosColors.shellPanelBg,
                    border: Border.all(
                        color: isSelected
                            ? SalesPosColors.brandGold
                            : SalesPosColors.shellBorder,
                        width: isSelected ? 1.5 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(fmt.icon,
                          color: isSelected
                              ? SalesPosColors.brandGold
                              : SalesPosColors.shellTextMuted,
                          size: 24),
                      const SizedBox(height: 8),
                      Text(fmt.label,
                          style: TextStyle(
                              color: isSelected
                                  ? SalesPosColors.brandGold
                                  : SalesPosColors.shellTextMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorizedCustomization() {
    if (_invCtrl.selectedFormat != PrintFormat.a4) return const SizedBox();

    final activeSettings = _invCtrl.getActiveConfig(_configMode, _configType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("BILL DETAIL SETTINGS",
            style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
              color: SalesPosColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SalesPosColors.shellBorder)),
          child: Column(
            children: [
              Row(
                children: [
                  _buildTab("RETAIL", _configMode == BillingMode.retail,
                      () => setState(() => _configMode = BillingMode.retail),
                      isLeft: true),
                  _buildTab("WHOLESALE", _configMode == BillingMode.wholesale,
                      () => setState(() => _configMode = BillingMode.wholesale),
                      isLeft: false),
                ],
              ),
              const Divider(color: SalesPosColors.shellBorder, height: 1),
              Row(
                children: [
                  _buildTab("Normal Bill", _configType == BillType.normal,
                      () => setState(() => _configType = BillType.normal),
                      isLeft: true, isSub: true),
                  _buildTab("GST Invoice", _configType == BillType.gst,
                      () => setState(() => _configType = BillType.gst),
                      isLeft: false, isSub: true),
                ],
              ),
              const Divider(color: SalesPosColors.shellBorder, height: 1),
              _buildToggleRow(
                  "Show HUID",
                  "Display HUID below items",
                  activeSettings.showHuid,
                  () => _invCtrl.toggleCustomization(
                      'huid', _configMode, _configType)),
              const Divider(color: SalesPosColors.shellBorder, height: 1),
              _buildToggleRow(
                  "Gross Weight",
                  "Show gross weight column",
                  activeSettings.showGrossWt,
                  () => _invCtrl.toggleCustomization(
                      'gw', _configMode, _configType)),
              const Divider(color: SalesPosColors.shellBorder, height: 1),
              _buildToggleRow(
                  "Less Weight",
                  "Show less weight column",
                  activeSettings.showLessWt,
                  () => _invCtrl.toggleCustomization(
                      'lw', _configMode, _configType)),
              const Divider(color: SalesPosColors.shellBorder, height: 1),
              _buildToggleRow(
                  "Making Charge",
                  "Display making/labour cost",
                  activeSettings.showMaking,
                  () => _invCtrl.toggleCustomization(
                      'making', _configMode, _configType)),
              const Divider(color: SalesPosColors.shellBorder, height: 1),
              //  NEW: Exchange Breakdown toggle
              _buildToggleRow(
                "Exchange Breakdown",
                "On: Show metal-wise exchange deduction. Off: Show a consolidated deduction.",
                activeSettings.showExchangeBreakdown,
                () => _invCtrl.toggleCustomization(
                    'exchange', _configMode, _configType),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap,
      {required bool isLeft, bool isSub = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: isActive
                  ? (isSub
                      ? SalesPosColors.shellBg
                      : SalesPosColors.brandGold.withValues(alpha: 0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.only(
                topLeft:
                    isLeft && !isSub ? const Radius.circular(12) : Radius.zero,
                topRight:
                    !isLeft && !isSub ? const Radius.circular(12) : Radius.zero,
              ),
              border: Border(
                bottom: BorderSide(
                    color: isActive && !isSub
                        ? SalesPosColors.brandGold
                        : Colors.transparent,
                    width: 2),
                right: BorderSide(
                    color: isLeft
                        ? SalesPosColors.shellBorder
                        : Colors.transparent),
              )),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: isActive
                        ? (isSub ? Colors.white : SalesPosColors.brandGold)
                        : SalesPosColors.shellTextMuted,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                    fontSize: isSub ? 12 : 13)),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(
      String title, String subtitle, bool value, VoidCallback onTap) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(
              color: SalesPosColors.shellTextTitle,
              fontSize: 13,
              fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              color: SalesPosColors.shellTextMuted, fontSize: 10)),
      trailing: Switch(
        value: value,
        onChanged: (_) => onTap(),
        activeThumbColor: SalesPosColors.brandGold,
        inactiveTrackColor: SalesPosColors.shellBg,
      ),
      onTap: onTap,
    );
  }

  //  Due date picker shown when a balance remains outstanding.
  Widget _buildDueDateSection() {
    final hasDue = (_invCtrl.invoice?.balanceDue ?? 0) > 0.5;
    if (!hasDue) return const SizedBox();

    final dueDate = _invCtrl.dueDate;
    final String dueDateLabel = dueDate != null
        ? "${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}"
        : "Select a due date";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DUE DATE",
            style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  dueDate ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: SalesPosColors.brandGold,
                    onPrimary: Colors.black,
                    surface: SalesPosColors.shellPanelBg,
                    onSurface: SalesPosColors.shellTextTitle,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              await _invCtrl.setDueDate(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: SalesPosColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: dueDate != null
                    ? SalesPosColors.brandGold
                    : SalesPosColors.shellBorder,
                width: dueDate != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: dueDate != null
                      ? SalesPosColors.brandGold
                      : SalesPosColors.shellTextMuted,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Payment Due By",
                        style: TextStyle(
                          color: SalesPosColors.shellTextMuted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dueDateLabel,
                        style: TextStyle(
                          color: dueDate != null
                              ? SalesPosColors.brandGold
                              : SalesPosColors.shellTextTitle,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (dueDate != null)
                  GestureDetector(
                    onTap: () => _invCtrl.setDueDate(null),
                    child: const Icon(Icons.close_rounded,
                        color: SalesPosColors.shellTextMuted, size: 18),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPrintOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PRINT OPTIONS",
            style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: SalesPosColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SalesPosColors.shellBorder)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Number of Copies",
                      style: TextStyle(
                          color: SalesPosColors.shellTextTitle,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: SalesPosColors.brandGold),
                          onPressed: () {
                            if (_invCtrl.printCopies > 1) {
                              _invCtrl.updatePrintOptions(
                                  copies: _invCtrl.printCopies - 1,
                                  duplicate: _invCtrl.includeDuplicateStamp);
                            }
                          }),
                      Text("${_invCtrl.printCopies}",
                          style: const TextStyle(
                              color: SalesPosColors.brandGold,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: SalesPosColors.brandGold),
                          onPressed: () {
                            if (_invCtrl.printCopies < 5) {
                              _invCtrl.updatePrintOptions(
                                  copies: _invCtrl.printCopies + 1,
                                  duplicate: _invCtrl.includeDuplicateStamp);
                            }
                          }),
                    ],
                  )
                ],
              ),
              const Divider(color: SalesPosColors.shellBorder, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mark as Duplicate",
                          style: TextStyle(
                              color: SalesPosColors.shellTextTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Text("Adds a watermark",
                          style: TextStyle(
                              color: SalesPosColors.shellTextMuted,
                              fontSize: 10)),
                    ],
                  ),
                  Switch(
                    value: _invCtrl.includeDuplicateStamp,
                    onChanged: (v) => _invCtrl.updatePrintOptions(
                        copies: _invCtrl.printCopies, duplicate: v),
                    activeThumbColor: SalesPosColors.brandGold,
                    inactiveTrackColor: SalesPosColors.shellBg,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionFooter() {
    final isReady = _invCtrl.genState == InvoiceGenState.ready;
    final bool hasPhone = _invCtrl.invoice?.customerMobile.isNotEmpty ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
          color: SalesPosColors.shellPanelBg,
          border: Border(top: BorderSide(color: SalesPosColors.shellBorder))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isReady && hasPhone
                      ? _invCtrl.openDirectWhatsAppChat
                      : null,
                  icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                  label: const Text("WHATSAPP",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              ),
              const SizedBox(width: 8),

              //  Animated save button workflow
              Expanded(
                child: OutlinedButton(
                  onPressed: (isReady && !_isSavingPdf && !_isPdfSaved)
                      ? () async {
                          setState(() => _isSavingPdf = true);

                          final path = await _invCtrl.downloadPdf();

                          if (path != null && mounted) {
                            setState(() {
                              _isSavingPdf = false;
                              _isPdfSaved = true;
                            });

                            // Return the save button to its default state after three seconds.
                            Future.delayed(const Duration(seconds: 3), () {
                              if (mounted) setState(() => _isPdfSaved = false);
                            });
                          } else {
                            if (mounted) setState(() => _isSavingPdf = false);
                          }
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _isPdfSaved
                          ? SalesPosColors.success
                          : SalesPosColors.shellTextTitle,
                      side: BorderSide(
                          color: _isPdfSaved
                              ? SalesPosColors.success
                              : SalesPosColors.shellBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isSavingPdf
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: SalesPosColors.brandGold))
                        : _isPdfSaved
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                key: ValueKey('saved'),
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 16, color: SalesPosColors.success),
                                  SizedBox(width: 6),
                                  Text("Saved",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: SalesPosColors.success)),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                key: ValueKey('idle'),
                                children: [
                                  Icon(Icons.download_rounded, size: 16),
                                  SizedBox(width: 6),
                                  Text("Save PDF",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ],
                              ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isReady
                  ? () => _invCtrl.printInvoice(_invCtrl.selectedFormat)
                  : null,
              icon: const Icon(Icons.print_rounded, size: 20),
              label: const Text("PRINT NOW",
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: SalesPosColors.brandGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ),

          //  Completion button finalizes the sale and clears the POS.
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isReady
                  ? () async {
                      await _invCtrl.finalizeInvoiceIfNeeded();
                      if (!mounted) return;
                      widget.billingCtrl.clearEntirePOS();
                      // Close the preview screen.
                      Navigator.of(context).pop();
                      // Success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            " Sale completed successfully. The POS is ready for the next customer.",
                          ),
                          backgroundColor: SalesPosColors.success,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: const Text(
                "DONE  -  NEW SALE",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 1.2,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: SalesPosColors.success,
                side: const BorderSide(
                  color: SalesPosColors.success,
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildRightPreviewPanel() {
    if (_invCtrl.genState == InvoiceGenState.generating ||
        _invCtrl.genState == InvoiceGenState.idle) {
      return const Center(
          child: CircularProgressIndicator(color: SalesPosColors.brandGold));
    }
    if (_invCtrl.genState == InvoiceGenState.error) {
      return Center(
          child: Text("Error: ${_invCtrl.errorMessage}",
              style: const TextStyle(color: SalesPosColors.danger)));
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: PdfPreview(
        build: (_) async => _invCtrl.pdfBytes!,
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        initialPageFormat: _getPageFormat(),
      ),
    );
  }

  PdfPageFormat _getPageFormat() {
    switch (_invCtrl.selectedFormat) {
      case PrintFormat.a4:
        return PdfPageFormat.a4;
      case PrintFormat.thermal3inch:
        return const PdfPageFormat(
            80 * PdfPageFormat.mm, 250 * PdfPageFormat.mm);
      case PrintFormat.thermal2inch:
        return const PdfPageFormat(
            57 * PdfPageFormat.mm, 250 * PdfPageFormat.mm);
    }
  }
}
