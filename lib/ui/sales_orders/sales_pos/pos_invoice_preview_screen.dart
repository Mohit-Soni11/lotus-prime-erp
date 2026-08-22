// ==========================================
// FILE: pos_invoice_preview_screen.dart
// TYPE: Full Screen Master UI (The Hub)
// DESCRIPTION: Review, export, and finalization workspace for POS invoices.
// ==========================================

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../logic/sales_orders/sales_pos/pos_invoice_controller.dart';
import '../../../features/print_templates/domain/print_template_registry.dart';
import 'pos_invoice_metal_setup_card.dart';
import 'pos_invoice_template_selector.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

part 'invoice_hub/parts/pos_invoice_hub_actions.dart';
part 'invoice_hub/parts/pos_invoice_hub_controls.dart';
part 'invoice_hub/parts/pos_invoice_hub_export_picker.dart';
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
    final target = await _showInvoiceExportTargetPicker();
    if (target == null) return;
    if (!mounted) return;

    setState(() => _isSavingPdf = true);
    final shouldStartNewSaleAfterExport =
        !_invCtrl.isSavedToDb && !widget.billingCtrl.isCurrentSaleCommitted;

    final path = await _invCtrl.downloadPdf(
      metal: target.metal,
      includeAllMetals: target.includeAllMetals,
    );

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
              '${target.successLabel} exported successfully. POS is ready for the next customer.',
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
        message: '${target.successLabel} exported successfully.',
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
                          _buildFormatGrid(),
                          const SizedBox(height: 24),
                          _buildTemplateSelector(),
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
}
