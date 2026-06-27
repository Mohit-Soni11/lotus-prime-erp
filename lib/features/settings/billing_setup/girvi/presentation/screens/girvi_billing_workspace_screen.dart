import 'package:flutter/material.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/application/girvi_billing_controller.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/domain/girvi_billing_policy_input.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/presentation/widgets/girvi_billing_header.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/presentation/widgets/girvi_billing_policy_form.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/presentation/widgets/girvi_billing_summary_panel.dart';
import 'package:lotus_erp/features/settings/billing_setup/presentation/theme/billing_setup_design_tokens.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';

class GirviBillingWorkspaceScreen extends StatefulWidget {
  const GirviBillingWorkspaceScreen({super.key});

  @override
  State<GirviBillingWorkspaceScreen> createState() =>
      _GirviBillingWorkspaceScreenState();
}

class _GirviBillingWorkspaceScreenState
    extends State<GirviBillingWorkspaceScreen> {
  late final GirviBillingController _controller;
  final _prefixController = TextEditingController();
  final _startingNumberController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _gracePeriodController = TextEditingController();
  final _reminderDaysController = TextEditingController();
  final _noticeDaysController = TextEditingController();
  final _termsController = TextEditingController();
  final _termsHindiController = TextEditingController();
  final _declarationController = TextEditingController();
  final _declarationHindiController = TextEditingController();
  final _footerController = TextEditingController();
  bool _initialSyncDone = false;

  @override
  void initState() {
    super.initState();
    _controller = GirviBillingController()..addListener(_handleStateChanged);
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleStateChanged)
      ..dispose();
    _prefixController.dispose();
    _startingNumberController.dispose();
    _interestRateController.dispose();
    _gracePeriodController.dispose();
    _reminderDaysController.dispose();
    _noticeDaysController.dispose();
    _termsController.dispose();
    _termsHindiController.dispose();
    _declarationController.dispose();
    _declarationHindiController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _handleStateChanged() {
    final state = _controller.state;
    if (!_initialSyncDone && !state.isLoading) {
      _syncEditors(state.input);
      _initialSyncDone = true;
    }
    if (mounted) setState(() {});
  }

  void _syncEditors(GirviBillingPolicyInput input) {
    _prefixController.text = input.girviPrefix;
    _startingNumberController.text = input.startingNumber;
    _interestRateController.text = input.defaultInterestRate;
    _gracePeriodController.text = input.gracePeriodDays;
    _reminderDaysController.text = input.reminderDays;
    _noticeDaysController.text = input.noticeDays;
    _termsController.text = input.termsAndConditions;
    _termsHindiController.text = input.termsAndConditionsHindi;
    _declarationController.text = input.customerDeclaration;
    _declarationHindiController.text = input.customerDeclarationHindi;
    _footerController.text = input.footerMessage;
  }

  void _forceEditorSync() {
    _syncEditors(_controller.state.input);
  }

  Future<void> _save() async {
    final saved = await _controller.save();
    if (!mounted) return;
    if (saved) _forceEditorSync();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Girvi billing settings saved.'
                : 'Please review the highlighted Girvi Billing issues.',
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

    return Scaffold(
      backgroundColor: BillingSetupDesignTokens.canvas,
      bottomNavigationBar: state.isLoading
          ? null
          : _ActionBar(
              isSaving: state.isSaving,
              isDirty: state.isDirty,
              onDiscard: () {
                _controller.discardChanges();
                _forceEditorSync();
              },
              onReset: () {
                _controller.resetToDefaults();
                _forceEditorSync();
              },
              onSave: _save,
            ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GirviBillingHeader(
                onBack: () => Navigator.maybePop(context),
              ),
            ),
            if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 110),
                sliver: SliverToBoxAdapter(
                  child: _WorkspaceBody(
                    controller: _controller,
                    model: state.model,
                    input: state.input,
                    prefixController: _prefixController,
                    startingNumberController: _startingNumberController,
                    interestRateController: _interestRateController,
                    gracePeriodController: _gracePeriodController,
                    reminderDaysController: _reminderDaysController,
                    noticeDaysController: _noticeDaysController,
                    termsController: _termsController,
                    termsHindiController: _termsHindiController,
                    declarationController: _declarationController,
                    declarationHindiController: _declarationHindiController,
                    footerController: _footerController,
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
  final GirviBillingController controller;
  final GirviBillingModel model;
  final GirviBillingPolicyInput input;
  final TextEditingController prefixController;
  final TextEditingController startingNumberController;
  final TextEditingController interestRateController;
  final TextEditingController gracePeriodController;
  final TextEditingController reminderDaysController;
  final TextEditingController noticeDaysController;
  final TextEditingController termsController;
  final TextEditingController termsHindiController;
  final TextEditingController declarationController;
  final TextEditingController declarationHindiController;
  final TextEditingController footerController;

  const _WorkspaceBody({
    required this.controller,
    required this.model,
    required this.input,
    required this.prefixController,
    required this.startingNumberController,
    required this.interestRateController,
    required this.gracePeriodController,
    required this.reminderDaysController,
    required this.noticeDaysController,
    required this.termsController,
    required this.termsHindiController,
    required this.declarationController,
    required this.declarationHindiController,
    required this.footerController,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1180;
    final validation = _ValidationBanner(
      messages: controller.state.validationMessages,
    );
    final form = GirviBillingPolicyForm(
      model: model,
      input: input,
      selectedInvoiceMetal: controller.state.selectedInvoiceMetal,
      prefixController: prefixController,
      startingNumberController: startingNumberController,
      interestRateController: interestRateController,
      gracePeriodController: gracePeriodController,
      reminderDaysController: reminderDaysController,
      noticeDaysController: noticeDaysController,
      termsController: termsController,
      termsHindiController: termsHindiController,
      declarationController: declarationController,
      declarationHindiController: declarationHindiController,
      footerController: footerController,
      onInputChanged: controller.updateInput,
      onModelChanged: controller.updateModel,
      onInvoiceMetalChanged: controller.selectInvoiceMetal,
      onInterestTypeChanged: controller.updateInterestType,
      onDefaultDurationChanged: controller.updateDefaultDuration,
      onTemplateChanged: controller.updateSelectedTemplate,
      onAutoPrintChanged: controller.updateAutoPrint,
    );

    if (!isDesktop) {
      return Column(
        children: [
          validation,
          if (controller.state.validationMessages.isNotEmpty)
            const SizedBox(height: 16),
          form,
          const SizedBox(height: 16),
          GirviBillingSummaryPanel(model: model, input: input),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        GirviBillingSummaryPanel(
          model: model,
          input: input,
          width: 318,
        ),
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
                  label: const Text('Save Girvi Settings'),
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
