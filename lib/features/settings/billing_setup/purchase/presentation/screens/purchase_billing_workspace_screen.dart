import 'package:flutter/material.dart';

import '../../../../../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../presentation/theme/billing_setup_design_tokens.dart';
import '../../application/purchase_billing_controller.dart';
import '../../domain/purchase_billing_policy_input.dart';
import '../widgets/purchase_billing_header.dart';
import '../widgets/purchase_billing_metal_selector.dart';
import '../widgets/purchase_billing_policy_form.dart';
import '../widgets/purchase_billing_summary_panel.dart';

class PurchaseBillingWorkspaceScreen extends StatefulWidget {
  const PurchaseBillingWorkspaceScreen({super.key});

  @override
  State<PurchaseBillingWorkspaceScreen> createState() =>
      _PurchaseBillingWorkspaceScreenState();
}

class _PurchaseBillingWorkspaceScreenState
    extends State<PurchaseBillingWorkspaceScreen> {
  late final PurchaseBillingController _controller;
  final _returnWindowController = TextEditingController();
  final _purityDeductionController = TextEditingController();
  final _termsController = TextEditingController();
  final _returnPolicyController = TextEditingController();
  final _buybackPolicyController = TextEditingController();
  final _footerController = TextEditingController();
  String? _syncedMetal;

  @override
  void initState() {
    super.initState();
    _controller = PurchaseBillingController()..addListener(_handleStateChanged);
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleStateChanged)
      ..dispose();
    _returnWindowController.dispose();
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

  void _syncEditors(String metal, PurchaseBillingPolicyInput input) {
    _syncedMetal = metal;
    _returnWindowController.text = input.returnWindowDays;
    _purityDeductionController.text = input.purityDeductPercent;
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? '$metalName purchase billing settings saved.'
                : 'Please review the highlighted Purchase Billing issues.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              saved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final model = state.currentSettings;
    final input = state.currentInput;

    return Scaffold(
      backgroundColor: BillingSetupDesignTokens.canvas,
      bottomNavigationBar: model == null || input == null || state.isLoading
          ? null
          : _ActionBar(
              isSaving: state.isSaving,
              isDirty: state.isCurrentDirty,
              onDiscard: () {
                _controller.discardCurrentChanges();
                _forceEditorSync();
              },
              onReset: () {
                _controller.resetCurrentToDefaults();
                _forceEditorSync();
              },
              onSave: _saveCurrent,
            ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PurchaseBillingHeader(
                onBack: () => Navigator.maybePop(context),
              ),
            ),
            if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (model == null || input == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('Purchase billing settings are unavailable.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 110),
                sliver: SliverToBoxAdapter(
                  child: _WorkspaceBody(
                    controller: _controller,
                    model: model,
                    input: input,
                    returnWindowController: _returnWindowController,
                    purityDeductionController: _purityDeductionController,
                    termsController: _termsController,
                    returnPolicyController: _returnPolicyController,
                    buybackPolicyController: _buybackPolicyController,
                    footerController: _footerController,
                    onInputChanged: _controller.updateCurrentInput,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceBody extends StatelessWidget {
  final PurchaseBillingController controller;
  final PurchaseBillingModel model;
  final PurchaseBillingPolicyInput input;
  final TextEditingController returnWindowController;
  final TextEditingController purityDeductionController;
  final TextEditingController termsController;
  final TextEditingController returnPolicyController;
  final TextEditingController buybackPolicyController;
  final TextEditingController footerController;
  final ValueChanged<PurchaseBillingPolicyInput> onInputChanged;

  const _WorkspaceBody({
    required this.controller,
    required this.model,
    required this.input,
    required this.returnWindowController,
    required this.purityDeductionController,
    required this.termsController,
    required this.returnPolicyController,
    required this.buybackPolicyController,
    required this.footerController,
    required this.onInputChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1180;
    final form = PurchaseBillingPolicyForm(
      model: model,
      input: input,
      returnWindowController: returnWindowController,
      purityDeductionController: purityDeductionController,
      termsController: termsController,
      returnPolicyController: returnPolicyController,
      buybackPolicyController: buybackPolicyController,
      footerController: footerController,
      onInputChanged: onInputChanged,
      onReturnModeChanged: controller.updateReturnMode,
      onFieldChanged: controller.toggleField,
      onTemplateChanged: controller.updateSelectedTemplate,
    );
    final validation = _ValidationBanner(
      messages: controller.state.validationMessages,
    );

    if (!isDesktop) {
      return Column(
        children: [
          PurchaseBillingMetalSelector(
            selectedMetal: controller.state.selectedMetal,
            dirtyMetals: controller.state.dirtyMetals,
            onSelected: controller.selectMetal,
          ),
          const SizedBox(height: 16),
          validation,
          if (controller.state.validationMessages.isNotEmpty)
            const SizedBox(height: 16),
          form,
          const SizedBox(height: 16),
          PurchaseBillingSummaryPanel(model: model, input: input),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PurchaseBillingMetalSelector(
          selectedMetal: controller.state.selectedMetal,
          dirtyMetals: controller.state.dirtyMetals,
          onSelected: controller.selectMetal,
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: [
              validation,
              if (controller.state.validationMessages.isNotEmpty)
                const SizedBox(height: 16),
              form,
            ],
          ),
        ),
        const SizedBox(width: 18),
        PurchaseBillingSummaryPanel(model: model, input: input),
      ],
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Required',
            style: TextStyle(
              color: Color(0xFF991B1B),
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
                style: const TextStyle(
                  color: Color(0xFF7F1D1D),
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

class _ActionBar extends StatelessWidget {
  final bool isSaving;
  final bool isDirty;
  final VoidCallback onDiscard;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const _ActionBar({
    required this.isSaving,
    required this.isDirty,
    required this.onDiscard,
    required this.onReset,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: BillingSetupDesignTokens.border),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final status = Text(
              isDirty ? 'Unsaved changes' : 'No pending changes',
              style: TextStyle(
                color: isDirty
                    ? const Color(0xFFB45309)
                    : BillingSetupDesignTokens.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            );
            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: isSaving ? null : onDiscard,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Discard'),
                ),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Reset Defaults'),
                ),
                FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save Current Metal'),
                ),
              ],
            );

            if (constraints.maxWidth < 680) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  status,
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }

            return Row(
              children: [
                status,
                const Spacer(),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}
