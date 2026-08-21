import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/settings/billing_setup/presentation/widgets/billing_metal_intro_panel.dart';
import 'package:lotus_erp/features/settings/billing_setup/sales/application/sales_billing_controller.dart';
import 'package:lotus_erp/features/settings/billing_setup/sales/domain/sales_billing_metal_profile.dart';
import 'package:lotus_erp/features/settings/billing_setup/sales/domain/sales_billing_policy_input.dart';
import 'package:lotus_erp/features/settings/billing_setup/sales/presentation/widgets/sales_billing_metal_selector.dart';
import 'package:lotus_erp/features/settings/billing_setup/sales/presentation/widgets/sales_billing_policy_form.dart';
import 'package:lotus_erp/features/settings/billing_setup/sales/presentation/widgets/sales_billing_visuals.dart';
import 'package:lotus_erp/models/setting/billing_setup/sales_billing_model.dart';
import 'package:lotus_erp/theme/settings/billing_setup/billing_setup_colors.dart';
import 'package:lotus_erp/ui/settings/billing_setup/billing_setup_app_bar.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class SalesBillingWorkspaceScreen extends StatefulWidget {
  const SalesBillingWorkspaceScreen({super.key});

  @override
  State<SalesBillingWorkspaceScreen> createState() =>
      _SalesBillingWorkspaceScreenState();
}

class _SalesBillingWorkspaceScreenState
    extends State<SalesBillingWorkspaceScreen> {
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

  @override
  void initState() {
    super.initState();
    _controller = SalesBillingController()..addListener(_handleStateChanged);
    _controller.load();
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
    final state = _controller.state;
    final input = state.currentInput;
    if (input != null) {
      _syncEditors(state.selectedMetal, input);
    }
  }

  Future<void> _saveCurrent() async {
    final metalName = BillingMetal.displayName(_controller.state.selectedMetal);
    final saved = await _controller.saveCurrent();
    if (!mounted) return;
    if (saved) _forceEditorSync();

    AppFeedback.show(
      context,
      type: saved ? AppFeedbackType.success : AppFeedbackType.error,
      message: saved
          ? '$metalName billing settings saved!'
          : 'Please review the highlighted Sales Billing issues.',
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final model = state.currentSettings;
    final input = state.currentInput;
    final metalName = BillingMetal.displayName(state.selectedMetal);

    return Scaffold(
      backgroundColor: BillingSetupColors.bodyBg,
      appBar: BillingSetupAppBar(
        screenTitle: '$metalName Sales',
        screenSubtitle: state.isLoading
            ? 'Loading settings...'
            : 'Invoice display, return rules and footer copy',
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (model == null || input == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('Sales billing settings are unavailable.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      BillingMetalIntroPanel(
                        metalName: metalName,
                        logoAsset:
                            SalesBillingVisuals.logoAssetFor(model.metal),
                        title: '$metalName sales controls',
                        description:
                            'Fine tune invoice fields, return rules and customer footer copy.',
                        accent: SalesBillingVisuals.accentFor(model.metal),
                        enabledCount:
                            SalesBillingMetalProfiles.activeFieldCount(model),
                        returnMode: model.returnMode,
                        fieldLabel: 'active fields',
                      ),
                      const SizedBox(height: 18),
                      SalesBillingMetalSelector(
                        selectedMetal: state.selectedMetal,
                        dirtyMetals: state.dirtyMetals,
                        onSelected: _controller.selectMetal,
                      ),
                      const SizedBox(height: 18),
                      _ValidationBanner(messages: state.validationMessages),
                      if (state.validationMessages.isNotEmpty)
                        const SizedBox(height: 18),
                      SalesBillingPolicyForm(
                        model: model,
                        input: input,
                        returnWindowController: _returnWindowController,
                        handlingChargeController: _handlingChargeController,
                        buybackRateController: _buybackRateController,
                        purityDeductionController: _purityDeductionController,
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
                        onPrintFooterChanged: _controller.updatePrintFooter,
                        onTemplateChanged: _controller.updateSelectedTemplate,
                      ),
                      const SizedBox(height: 32),
                      _SaveButton(
                        isSaving: state.isSaving,
                        label: 'Save $metalName Settings',
                        accent: SalesBillingVisuals.accentFor(model.metal),
                        onPressed: _saveCurrent,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  final List<String> messages;

  const _ValidationBanner({required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Required',
            style: GoogleFonts.manrope(
              color: const Color(0xFF991B1B),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final message in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: const Color(0xFF7F1D1D),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final String label;
  final Color accent;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isSaving,
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
