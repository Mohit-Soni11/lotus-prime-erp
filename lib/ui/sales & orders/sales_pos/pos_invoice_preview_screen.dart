// ==========================================
// FILE: pos_invoice_preview_screen.dart
// TYPE: Full Screen Master UI (The Hub)
// DESCRIPTION: Review, export, and finalization workspace for POS invoices.
// ==========================================

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';
import '../../../models/sales & orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../logic/sales & orders/sales pos/pos_invoice_controller.dart';
import 'pos_invoice_metal_setup_card.dart';

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

  bool _isSavingPdf = false;
  bool _isPdfSaved = false;

  @override
  void initState() {
    super.initState();
    _invCtrl = PosInvoiceController(billing: widget.billingCtrl);

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
                Text("Review, Export & Finalize",
                    style: TextStyle(
                        color: SalesPosColors.shellTextMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
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

    final metals = _invCtrl.presentMetals;
    final billingModeLabel =
        widget.billingCtrl.billingMode == BillingMode.wholesale
            ? "Wholesale"
            : "Retail";
    final billTypeLabel = widget.billingCtrl.billType == BillType.gst
        ? "GST Invoice"
        : "Normal Bill";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("INVOICE PROFILE",
            style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: SalesPosColors.shellPanelBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SalesPosColors.shellBorder)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildProfileChip(Icons.storefront_rounded, billingModeLabel),
                  _buildProfileChip(
                      Icons.receipt_long_rounded, billTypeLabel),
                  _buildProfileChip(
                    Icons.category_rounded,
                    metals.isEmpty
                        ? "No Metal Items"
                        : metals.map((metal) => metal.displayName).join(" + "),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "This profile is detected automatically from the active POS bill.",
                style: TextStyle(
                    color: SalesPosColors.shellTextMuted.withValues(alpha: 0.9),
                    fontSize: 10,
                    height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text("METAL BILLING SETUP",
            style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        if (metals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: SalesPosColors.shellPanelBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SalesPosColors.shellBorder)),
            child: const Text(
              "Add invoice items to load metal-specific billing controls.",
              style:
                  TextStyle(color: SalesPosColors.shellTextMuted, fontSize: 12),
            ),
          )
        else
          ...[
            _buildMetalInvoiceSelector(metals),
            const SizedBox(height: 12),
            if (_invCtrl.effectiveActiveMetal != null)
              _buildMetalBillingSetupCard(_invCtrl.effectiveActiveMetal!),
          ],
      ],
    );
  }

  Widget _buildProfileChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: SalesPosColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.shellBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: SalesPosColors.brandGold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: SalesPosColors.shellTextTitle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetalInvoiceSelector(List<MetalType> metals) {
    if (metals.length <= 1) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metals.map(_buildMetalInvoiceButton).toList(),
    );
  }

  Widget _buildMetalInvoiceButton(MetalType metal) {
    final isSelected = _invCtrl.effectiveActiveMetal == metal;
    final color = _metalColor(metal);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _invCtrl.setActivePrintMetal(metal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.16)
              : SalesPosColors.shellPanelBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : SalesPosColors.shellBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 15,
              color: isSelected ? color : SalesPosColors.shellTextMuted,
            ),
            const SizedBox(width: 7),
            Text(
              "${metal.displayName} Invoice",
              style: TextStyle(
                color: isSelected ? color : SalesPosColors.shellTextTitle,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetalBillingSetupCard(MetalType metal) {
    return PosInvoiceMetalSetupCard(
      metal: metal,
      controller: _invCtrl,
      accentColor: _metalColor(metal),
    );
  }

  Color _metalColor(MetalType metal) {
    switch (metal) {
      case MetalType.gold:
        return SalesPosColors.brandGold;
      case MetalType.silver:
        return SalesPosColors.brandSilver;
      case MetalType.platinum:
        return SalesPosColors.brandPlatinum;
      case MetalType.diamond:
        return SalesPosColors.brandDiamond;
    }
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
        const Text("OUTPUT OPTIONS",
            style: TextStyle(
                color: SalesPosColors.shellTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
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
                  const Text("Copies",
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
                      Text("Duplicate Stamp",
                          style: TextStyle(
                              color: SalesPosColors.shellTextTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Text("Applies a duplicate watermark",
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
    final bool isFinalized =
        _invCtrl.isSavedToDb || widget.billingCtrl.isCurrentSaleCommitted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
          color: SalesPosColors.shellPanelBg,
          border: Border(top: BorderSide(color: SalesPosColors.shellBorder))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWorkflowStatus(isReady: isReady, isFinalized: isFinalized),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isReady && hasPhone
                      ? _invCtrl.openDirectWhatsAppChat
                      : null,
                  icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                  label: const Text("Send WhatsApp",
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

              Expanded(
                child: OutlinedButton(
                  onPressed: (isReady && !_isSavingPdf)
                      ? () async {
                          setState(() => _isSavingPdf = true);

                          final path = await _invCtrl.downloadPdf();

                          if (path != null && mounted) {
                            setState(() {
                              _isSavingPdf = false;
                              _isPdfSaved = true;
                            });

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
                                  Text("Exported",
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
                                  Text("Export PDF",
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: ElevatedButton.icon(
                onPressed: isReady
                    ? () => _invCtrl.printInvoice(_invCtrl.selectedFormat)
                    : null,
                icon: const Icon(Icons.print_rounded, size: 20),
                label: Text(isFinalized ? "PRINT INVOICE" : "FINALIZE & PRINT",
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1.1)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: SalesPosColors.brandGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isReady
                  ? () async {
                      await _invCtrl.finalizeInvoiceIfNeeded();
                      if (!mounted) return;
                      widget.billingCtrl.clearEntirePOS();
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Invoice finalized successfully. The POS is ready for the next customer.",
                          ),
                          backgroundColor: SalesPosColors.success,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.done_all_rounded, size: 20),
              label: const Text(
                "FINISH & NEW SALE",
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

  Widget _buildWorkflowStatus({
    required bool isReady,
    required bool isFinalized,
  }) {
    final Color color = !isReady
        ? SalesPosColors.shellTextMuted
        : isFinalized
            ? SalesPosColors.success
            : SalesPosColors.brandGold;
    final IconData icon = !isReady
        ? Icons.hourglass_top_rounded
        : isFinalized
            ? Icons.verified_rounded
            : Icons.edit_note_rounded;
    final String title = !isReady
        ? "Preparing Invoice"
        : isFinalized
            ? "Finalized Invoice"
            : "Draft Invoice";
    final String status = !isReady
        ? "Generating preview"
        : isFinalized
            ? "Record saved"
            : "Review pending";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                title,
                key: ValueKey(title),
                style: const TextStyle(
                  color: SalesPosColors.shellTextTitle,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
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

    final previewKey = ValueKey(
      '${_invCtrl.selectedFormat.name}-${_invCtrl.effectiveActiveMetal?.name ?? 'all'}-${_invCtrl.pdfBytes?.length ?? 0}',
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Padding(
        key: previewKey,
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
