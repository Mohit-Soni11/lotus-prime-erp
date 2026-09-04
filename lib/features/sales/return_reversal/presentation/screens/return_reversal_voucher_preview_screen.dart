import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:lotus_erp/core/feedback/app_feedback.dart';
import 'package:lotus_erp/core/pdf/lotus_pdf_page_counter.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/pdf/return_reversal_voucher_pdf_service.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/pdf/return_reversal_voucher_preview_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/application/return_reversal_controller.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'package:lotus_erp/ui/sales_orders/sales_pos/pos_invoice_template_selector.dart';

part 'voucher_hub/parts/return_reversal_voucher_hub_actions.dart';
part 'voucher_hub/parts/return_reversal_voucher_hub_controls.dart';
part 'voucher_hub/parts/return_reversal_voucher_hub_header.dart';
part 'voucher_hub/parts/return_reversal_voucher_hub_preview.dart';

class ReturnReversalVoucherPreviewScreen extends StatefulWidget {
  final ReturnReversalController controller;

  const ReturnReversalVoucherPreviewScreen({
    super.key,
    required this.controller,
  });

  static Future<void> push(
    BuildContext context, {
    required ReturnReversalController controller,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (ctx, anim, _) {
          return ReturnReversalVoucherPreviewScreen(controller: controller);
        },
        transitionsBuilder: (ctx, anim, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  State<ReturnReversalVoucherPreviewScreen> createState() =>
      _ReturnReversalVoucherPreviewScreenState();
}

class _ReturnReversalVoucherPreviewScreenState
    extends State<ReturnReversalVoucherPreviewScreen>
    with TickerProviderStateMixin {
  late final ReturnReversalVoucherPreviewController _voucherCtrl;
  bool _isSavingPdf = false;
  bool _isPdfSaved = false;
  bool _isPrintingVoucher = false;
  bool _hasPrintedVoucher = false;
  bool _isCompletingWorkspace = false;

  @override
  void initState() {
    super.initState();
    _voucherCtrl = ReturnReversalVoucherPreviewController(
      deskController: widget.controller,
    );
    _voucherCtrl.addListener(_handleVoucherControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _voucherCtrl.generateVoucher();
    });
  }

  void _handleVoucherControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _setVoucherPrintState({
    bool? isPrinting,
    bool? hasPrinted,
  }) {
    if (!mounted) return;
    setState(() {
      if (isPrinting != null) _isPrintingVoucher = isPrinting;
      if (hasPrinted != null) _hasPrintedVoucher = hasPrinted;
    });
  }

  void _setVoucherSavingState({
    bool? isSaving,
    bool? isSaved,
  }) {
    if (!mounted) return;
    setState(() {
      if (isSaving != null) _isSavingPdf = isSaving;
      if (isSaved != null) _isPdfSaved = isSaved;
    });
  }

  void _setWorkspaceCompletionState(bool isCompleting) {
    if (!mounted) return;
    setState(() => _isCompletingWorkspace = isCompleting);
  }

  @override
  void dispose() {
    _voucherCtrl.removeListener(_handleVoucherControllerChanged);
    _voucherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceDocument = widget.controller.state.selectedSourceDocument;
    if (sourceDocument == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).maybePop();
        AppFeedback.error(
          context,
          message: 'Select a return or cancellation source first.',
        );
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: SalesPosColors.bodyBg,
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 440,
              decoration: const BoxDecoration(
                color: SalesPosColors.shellBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHubHeader(sourceDocument),
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
                          _buildVoucherContext(sourceDocument),
                          const SizedBox(height: 24),
                          _buildDocumentSelector(),
                          if (_voucherCtrl.showsInvoiceMetalScope) ...[
                            const SizedBox(height: 24),
                            _buildInvoiceMetalScope(),
                          ],
                          const SizedBox(height: 24),
                          _buildPrintOptions(),
                        ],
                      ),
                    ),
                  ),
                  _buildActionFooter(),
                ],
              ),
            ),
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
