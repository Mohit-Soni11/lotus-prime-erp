import 'dart:async';

import 'package:flutter/material.dart';

import '../../../features/settings/billing_setup/sales/application/sales_billing_controller.dart';
import '../../../features/settings/billing_setup/sales/domain/sales_billing_policy_input.dart';
import '../../../features/settings/billing_setup/sales/presentation/widgets/sales_billing_policy_form.dart';
import '../../../logic/sales_orders/sales_pos/pos_invoice_controller.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../theme/settings/billing_setup/billing_setup_colors.dart';

class PosSalesBillingProfileDrawer extends StatefulWidget {
  final MetalType metal;
  final PosInvoiceController invoiceController;
  final Color accentColor;
  final VoidCallback onClose;

  const PosSalesBillingProfileDrawer({
    super.key,
    required this.metal,
    required this.invoiceController,
    required this.accentColor,
    required this.onClose,
  });

  @override
  State<PosSalesBillingProfileDrawer> createState() =>
      _PosSalesBillingProfileDrawerState();
}

class _PosSalesBillingProfileDrawerState
    extends State<PosSalesBillingProfileDrawer> {
  late final SalesBillingController _controller;
  final _returnWindowController = TextEditingController();
  final _handlingChargeController = TextEditingController();
  final _buybackRateController = TextEditingController();
  final _purityDeductionController = TextEditingController();
  final _termsController = TextEditingController();
  final _returnPolicyController = TextEditingController();
  final _buybackPolicyController = TextEditingController();
  final _footerController = TextEditingController();

  String? _syncedMetal;
  SalesBillingModel? _lastPreviewModel;

  @override
  void initState() {
    super.initState();
    _controller = SalesBillingController()..addListener(_handleStateChanged);
    _controller.selectMetal(widget.metal.name);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleStateChanged)
      ..dispose();
    _returnWindowController.dispose();
    _handlingChargeController.dispose();
    _buybackRateController.dispose();
    _purityDeductionController.dispose();
    _termsController.dispose();
    _returnPolicyController.dispose();
    _buybackPolicyController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _handleStateChanged() {
    final state = _controller.state;
    final input = state.currentInput;
    if (input != null && _syncedMetal != state.selectedMetal) {
      _syncEditors(state.selectedMetal, input);
    }

    final model = state.currentSettings;
    if (model != null && !identical(model, _lastPreviewModel)) {
      _lastPreviewModel = model;
      unawaited(widget.invoiceController.applySalesBillingSetupModel(model));
    }

    if (mounted) setState(() {});
  }

  void _syncEditors(String metal, SalesBillingPolicyInput input) {
    _syncedMetal = metal;
    _returnWindowController.text = input.returnWindowDays;
    _handlingChargeController.text = input.handlingChargePercent;
    _buybackRateController.text = input.buybackRatePercent;
    _purityDeductionController.text = input.buybackPurityDeductPercent;
    _termsController.text = input.termsAndConditions;
    _returnPolicyController.text = input.returnPolicyText;
    _buybackPolicyController.text = input.buybackPolicyText;
    _footerController.text = input.footerMessage;
  }

  void _forceEditorSync() {
    _syncedMetal = null;
    final input = _controller.state.currentInput;
    if (input != null) {
      _syncEditors(_controller.state.selectedMetal, input);
    }
  }

  Future<void> _saveCurrent() async {
    final saved = await _controller.saveCurrent();
    if (!mounted) return;
    if (saved) {
      _forceEditorSync();
      final model = _controller.state.currentSettings;
      if (model != null) {
        await widget.invoiceController.applySalesBillingSetupModel(model);
        if (!mounted) return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          saved
              ? '${widget.metal.displayName} display profile saved.'
              : 'Please review the highlighted display profile issues.',
        ),
      ),
    );

    if (saved) {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width < 760 ? width - 24 : 720.0;
    final state = _controller.state;
    final model = state.currentSettings;
    final input = state.currentInput;

    return Container(
      width: panelWidth,
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      decoration: BoxDecoration(
        color: BillingSetupColors.bodyBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SalesPosColors.shellBorder),
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
            _DrawerHeader(
              metal: widget.metal,
              accentColor: widget.accentColor,
              isDirty: state.isCurrentDirty,
              onClose: widget.onClose,
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : model == null || input == null
                      ? const Center(
                          child: Text('Sales billing profile is unavailable.'),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (state.validationMessages.isNotEmpty) ...[
                              _ValidationBanner(
                                messages: state.validationMessages,
                              ),
                              const SizedBox(height: 14),
                            ],
                            SalesBillingPolicyForm(
                              model: model,
                              input: input,
                              returnWindowController: _returnWindowController,
                              handlingChargeController:
                                  _handlingChargeController,
                              buybackRateController: _buybackRateController,
                              purityDeductionController:
                                  _purityDeductionController,
                              termsController: _termsController,
                              returnPolicyController: _returnPolicyController,
                              buybackPolicyController: _buybackPolicyController,
                              footerController: _footerController,
                              onInputChanged: _controller.updateCurrentInput,
                              onReturnModeChanged: _controller.updateReturnMode,
                              onFieldChanged: _controller.toggleField,
                              onPrintTermsChanged: _controller.updatePrintTerms,
                              onPrintReturnPolicyChanged:
                                  _controller.updatePrintReturnPolicy,
                              onPrintBuybackPolicyChanged:
                                  _controller.updatePrintBuybackPolicy,
                              onPrintFooterChanged:
                                  _controller.updatePrintFooter,
                            ),
                          ],
                        ),
            ),
            _DrawerFooter(
              accentColor: widget.accentColor,
              isSaving: state.isSaving,
              onReload: _controller.discardCurrentChanges,
              onSave: _saveCurrent,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final MetalType metal;
  final Color accentColor;
  final bool isDirty;
  final VoidCallback onClose;

  const _DrawerHeader({
    required this.metal,
    required this.accentColor,
    required this.isDirty,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
      decoration: const BoxDecoration(
        color: SalesPosColors.shellPanelBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: SalesPosColors.shellBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.tune_rounded, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${metal.displayName.toUpperCase()} DISPLAY PROFILE',
                  style: const TextStyle(
                    color: SalesPosColors.shellTextTitle,
                    fontSize: SalesPosStyles.fontInput,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Sales Billing Setup controls with live invoice preview',
                  style: TextStyle(
                    color: SalesPosColors.shellTextMuted,
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isDirty)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: accentColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                'Unsaved',
                style: TextStyle(
                  color: accentColor,
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: SalesPosColors.shellTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  final Color accentColor;
  final bool isSaving;
  final VoidCallback onReload;
  final VoidCallback onSave;

  const _DrawerFooter({
    required this.accentColor,
    required this.isSaving,
    required this.onReload,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onReload,
              icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
              label: const Text('Reload Saved'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SalesPosColors.shellTextTitle,
                side: const BorderSide(color: Color(0xFFD6DEE8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save Master Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
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

class _ValidationBanner extends StatelessWidget {
  final List<String> messages;

  const _ValidationBanner({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Required',
            style: TextStyle(
              color: Color(0xFF9F1239),
              fontSize: SalesPosStyles.fontLabel,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final message in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF9F1239),
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
