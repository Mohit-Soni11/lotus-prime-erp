// ==========================================
// FILE: pos_invoice_preview_screen.dart
// TYPE: Full Screen Master UI (The Hub)
// DESCRIPTION: Review, export, and finalization workspace for POS invoices.
// ==========================================

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../logic/sales_orders/sales_pos/pos_invoice_controller.dart';
import '../../../features/print_templates/domain/print_template_registry.dart';
import '../../../core/pdf/lotus_pdf_page_counter.dart';
import '../../../core/printing/lotus_pdf_print_dispatcher.dart';
import 'pos_invoice_metal_setup_card.dart';
import 'pos_invoice_template_selector.dart';
import 'invoice_hub/pos_invoice_cached_pdf_pane.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

part 'invoice_hub/parts/pos_invoice_hub_actions.dart';
part 'invoice_hub/parts/pos_invoice_hub_controls.dart';
part 'invoice_hub/parts/pos_invoice_hub_header.dart';
part 'invoice_hub/parts/pos_invoice_hub_preview.dart';

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
  late final bool _wasSaleCommittedOnOpen;

  bool _isSavingPdf = false;
  bool _isPdfSaved = false;
  bool _isPrintingInvoice = false;
  bool _hasPrintedInvoice = false;

  @override
  void initState() {
    super.initState();
    _wasSaleCommittedOnOpen = widget.billingCtrl.isCurrentSaleCommitted;
    _invCtrl = PosInvoiceController(billing: widget.billingCtrl);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _invCtrl.generateInvoice();
    });
    _invCtrl.addListener(_handleInvoiceControllerChanged);
  }

  void _handleInvoiceControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _setInvoicePrintState({
    bool? isPrinting,
    bool? hasPrinted,
  }) {
    if (!mounted) return;
    setState(() {
      if (isPrinting != null) _isPrintingInvoice = isPrinting;
      if (hasPrinted != null) _hasPrintedInvoice = hasPrinted;
    });
  }

  @override
  void dispose() {
    if (!_wasSaleCommittedOnOpen && !_invCtrl.isSavedToDb) {
      widget.billingCtrl.releaseUncommittedInvoicePreview();
    }
    _invCtrl.removeListener(_handleInvoiceControllerChanged);
    _invCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportPdf() async {
    setState(() => _isSavingPdf = true);
    final shouldStartNewSaleAfterExport = !_invCtrl.isIssuedPdfSaved &&
        !widget.billingCtrl.isCurrentSaleCommitted;

    String? path;
    try {
      path = await _invCtrl.downloadPdf();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSavingPdf = false);
      AppFeedback.error(
        context,
        message: 'Invoice PDF could not be saved. Please try again.',
      );
      return;
    }

    if (path != null && mounted) {
      if (shouldStartNewSaleAfterExport) {
        setState(() => _isSavingPdf = false);
        widget.billingCtrl.clearEntirePOS();
        Navigator.of(context).pop();
        if (!mounted) return;
        AppFeedback.show(
          context,
          type: AppFeedbackType.success,
          message:
              'Invoice PDF exported successfully. POS is ready for the next customer.',
          duration: const Duration(seconds: 3),
        );
        return;
      }

      setState(() {
        _isSavingPdf = false;
        _isPdfSaved = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isPdfSaved = false);
      });
      AppFeedback.success(
        context,
        message: 'Invoice PDF exported successfully.',
      );
      return;
    }

    if (mounted) {
      setState(() => _isSavingPdf = false);
    }
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
                          if (_invCtrl.isIssuedPdfSaved) ...[
                            const Text(
                              'ISSUED PDF SAVED',
                              style: TextStyle(
                                color: SalesPosColors.success,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Preview, print, share and export now use this saved invoice.',
                              style: TextStyle(
                                color: SalesPosColors.shellTextTitle,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          Opacity(
                            opacity: _invCtrl.isIssuedPdfSaved ? 0.55 : 1,
                            child: AbsorbPointer(
                              absorbing: _invCtrl.isIssuedPdfSaved,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFormatGrid(),
                                  const SizedBox(height: 24),
                                  _buildTemplateSelector(),
                                  const SizedBox(height: 24),
                                  _buildCategorizedCustomization(),
                                  const SizedBox(height: 24),
                                  _buildDueDateSection(),
                                  _buildPrintOptions(),
                                ],
                              ),
                            ),
                          ),
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
}
