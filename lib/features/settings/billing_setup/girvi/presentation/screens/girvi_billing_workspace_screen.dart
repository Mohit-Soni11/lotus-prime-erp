import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/application/girvi_billing_controller.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/domain/girvi_billing_policy_input.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/presentation/widgets/girvi_billing_intro_panel.dart';
import 'package:lotus_erp/features/settings/billing_setup/girvi/presentation/widgets/girvi_billing_policy_form.dart';
import 'package:lotus_erp/theme/settings/billing_setup/billing_setup_colors.dart';
import 'package:lotus_erp/theme/settings/billing_setup/billing_setup_strings.dart';
import 'package:lotus_erp/ui/settings/billing_setup/billing_setup_app_bar.dart';

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

  Future<void> _save() async {
    final saved = await _controller.save();
    if (!mounted) return;
    if (saved) _syncEditors(_controller.state.input);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Girvi settings saved!'
                : 'Please review the highlighted Girvi Billing issues.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor:
              saved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      backgroundColor: BillingSetupColors.bodyBg,
      appBar: BillingSetupAppBar(
        screenTitle: BillingSetupStrings.girviTitle,
        screenSubtitle: 'Interest, invoice display and notice controls',
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
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      GirviBillingIntroPanel(
                        accent: BillingSetupColors.girviBrand,
                        interestRate: state.model.defaultInterestRate,
                        interestType: state.model.interestType,
                        autoPrint: state.model.autoPrint,
                        invoiceFieldCount: state.model.visibleInvoiceFieldCount,
                      ),
                      const SizedBox(height: 18),
                      _ValidationBanner(
                        messages: state.validationMessages,
                      ),
                      if (state.validationMessages.isNotEmpty)
                        const SizedBox(height: 18),
                      GirviBillingPolicyForm(
                        model: state.model,
                        input: state.input,
                        selectedInvoiceMetal: state.selectedInvoiceMetal,
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
                        onInputChanged: _controller.updateInput,
                        onModelChanged: _controller.updateModel,
                        onInvoiceMetalChanged: _controller.selectInvoiceMetal,
                        onInterestTypeChanged: _controller.updateInterestType,
                        onDefaultDurationChanged:
                            _controller.updateDefaultDuration,
                        onTemplateChanged: _controller.updateSelectedTemplate,
                        onAutoPrintChanged: _controller.updateAutoPrint,
                      ),
                      const SizedBox(height: 32),
                      _SaveButton(
                        isSaving: state.isSaving,
                        onPressed: _save,
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
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isSaving,
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
          backgroundColor: BillingSetupColors.girviBrand,
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
                'Save Girvi Settings',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
