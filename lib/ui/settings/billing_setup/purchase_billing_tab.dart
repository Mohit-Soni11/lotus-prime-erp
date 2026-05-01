// =============================================================================
// FILE        : lib/ui/settings/billing_setup/tabs/purchase_billing_tab.dart
// MODULE      : Billing Setup
// LAYER       : Presentation / UI
// DESCRIPTION : Purchase Billing configuration — 4 sections.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../logic/setting/billing_setup/billing_setup_logic.dart';
import '../../../../repositories/setting/billing_setup/billing_setup_repository.dart';
import '../../../../theme/settings/billing_setup/billing_setup_theme.dart';
import 'billing_setup_app_bar.dart';
import 'billing_section_card.dart';

class PurchaseBillingTab extends StatefulWidget {
  const PurchaseBillingTab({super.key});

  @override
  State<PurchaseBillingTab> createState() => _PurchaseBillingTabState();
}

class _PurchaseBillingTabState extends State<PurchaseBillingTab> {
  late PurchaseBillingLogic logic;
  final BillingSetupRepository _repo = BillingSetupRepository();
  bool _loading = true;

  // ── Controllers ─────────────────────────────────────────────────────────
  final _prefixCtrl = TextEditingController();
  final _startNoCtrl = TextEditingController();
  final _payDaysCtrl = TextEditingController();
  final _advanceCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();

  // ── Focus Nodes ──────────────────────────────────────────────────────────
  final _prefixFocus = FocusNode();
  final _startNoFocus = FocusNode();
  final _payDaysFocus = FocusNode();
  final _advanceFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _termsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    logic = PurchaseBillingLogic();
    _loadData();
  }

  Future<void> _loadData() async {
    final row = await _repo.fetchSettings();
    final m = row != null ? _repo.rowToPurchaseModel(row) : null;
    logic.init(m);
    if (m != null) {
      _prefixCtrl.text = m.invoicePrefix;
      _startNoCtrl.text = m.startingNumber.toString();
      _payDaysCtrl.text = m.defaultPaymentDays.toString();
      _advanceCtrl.text = m.advancePercent.toString();
      _weightCtrl.text = m.weightTolerancePercent.toString();
      _termsCtrl.text = m.terms;
    } else {
      _prefixCtrl.text = logic.defaults.invoicePrefix;
      _startNoCtrl.text = logic.defaults.startingNumber.toString();
      _payDaysCtrl.text = logic.defaults.defaultPaymentDays.toString();
      _advanceCtrl.text = logic.defaults.advancePercent.toString();
      _weightCtrl.text = logic.defaults.weightTolerancePercent.toString();
      _termsCtrl.text = logic.defaults.terms;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    logic.dispose();
    for (final c in [
      _prefixCtrl,
      _startNoCtrl,
      _payDaysCtrl,
      _advanceCtrl,
      _weightCtrl,
      _termsCtrl
    ]) c.dispose();
    for (final f in [
      _prefixFocus,
      _startNoFocus,
      _payDaysFocus,
      _advanceFocus,
      _weightFocus,
      _termsFocus
    ]) f.dispose();
    super.dispose();
  }

  Future<void> _saveSection(PurchaseSection section) async {
    if (logic.lockedNotifier(section).value) {
      logic.unlockSection(section);
      return;
    }
    final model = logic.buildModel(
      prefix: _prefixCtrl.text,
      startNo: _startNoCtrl.text,
      payDays: _payDaysCtrl.text,
      advance: _advanceCtrl.text,
      weightTol: _weightCtrl.text,
      terms: _termsCtrl.text,
    );
    final ok = await logic.saveSection(section: section, model: model);
    if (mounted) _showSnack(ok);
  }

  void _showSnack(bool ok) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          ok ? BillingSetupStrings.msgSaved : BillingSetupStrings.msgFixErrors,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor:
            ok ? BillingSetupColors.saveBtn : BillingSetupColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BillingSetupStyles.rBtn)),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: BillingSetupColors.bodyBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: BillingSetupColors.bodyBg,
      appBar: BillingSetupAppBar(
        screenTitle: BillingSetupStrings.purchaseTitle,
        screenSubtitle: BillingSetupStrings.purchaseSub,
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: BillingSetupStyles.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildInvoiceCard(),
              const SizedBox(height: 20),
              _buildPaymentCard(),
              const SizedBox(height: 20),
              _buildItemRulesCard(),
              const SizedBox(height: 20),
              _buildTermsCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard() {
    return ListenableBuilder(
      listenable:
          Listenable.merge([logic.invoiceNoLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.invoiceNoLocked.value;
        final bool loading =
            logic.loadingSection.value == PurchaseSection.invoiceNo;

        return BillingSectionCard(
          title: BillingSetupStrings.secPurInvoice,
          subtitle: BillingSetupStrings.subPurInvoice,
          sectionIcon: BillingSetupIcons.invoiceNo,
          accentColor: BillingSetupColors.purInvoice,
          isLocked: locked,
          isLoading: loading,
          isVerified: _prefixCtrl.text.isNotEmpty,
          onToggle: () => _saveSection(PurchaseSection.invoiceNo),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subPurInvoice),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblPurPrefix,
                hint: BillingSetupStrings.hintPurPrefix,
                icon: BillingSetupIcons.invoiceNo,
                brandColor: BillingSetupColors.purInvoice,
                ctrl: _prefixCtrl,
                isLocked: locked,
                focusNode: _prefixFocus,
                nextFocus: _startNoFocus,
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblPurStartNo,
                hint: BillingSetupStrings.hintPurStartNo,
                icon: BillingSetupIcons.invoiceNo,
                brandColor: BillingSetupColors.purInvoice,
                ctrl: _startNoCtrl,
                isLocked: locked,
                focusNode: _startNoFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
            ]),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: logic.yearlyReset,
              builder: (_, __) => BillingToggleRow(
                label: BillingSetupStrings.lblPurYearReset,
                icon: BillingSetupIcons.estimate,
                accentColor: BillingSetupColors.purInvoice,
                value: logic.yearlyReset.value,
                isLocked: locked,
                onChanged: (v) => logic.yearlyReset.value = v,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentCard() {
    return ListenableBuilder(
      listenable:
          Listenable.merge([logic.paymentTermsLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.paymentTermsLocked.value;
        final bool loading =
            logic.loadingSection.value == PurchaseSection.paymentTerms;

        return BillingSectionCard(
          title: BillingSetupStrings.secPurPayment,
          subtitle: BillingSetupStrings.subPurPayment,
          sectionIcon: BillingSetupIcons.payment,
          accentColor: BillingSetupColors.purPayment,
          isLocked: locked,
          isLoading: loading,
          isVerified: true,
          onToggle: () => _saveSection(PurchaseSection.paymentTerms),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subPurPayment),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: logic.selectedPayMode,
              builder: (_, __) => BillingDropdownField(
                label: BillingSetupStrings.lblPurPayMode,
                icon: BillingSetupIcons.payment,
                brandColor: BillingSetupColors.purPayment,
                value: logic.selectedPayMode.value,
                items: BillingSetupStrings.purchasePayModes,
                isLocked: locked,
                onChanged: (v) => logic.selectedPayMode.value = v!,
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblPurPayDays,
                hint: BillingSetupStrings.hintPurPayDays,
                icon: BillingSetupIcons.payDays,
                brandColor: BillingSetupColors.purPayment,
                ctrl: _payDaysCtrl,
                isLocked: locked,
                focusNode: _payDaysFocus,
                nextFocus: _advanceFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblPurAdvance,
                hint: BillingSetupStrings.hintPurAdvance,
                icon: BillingSetupIcons.advance,
                brandColor: BillingSetupColors.purPayment,
                ctrl: _advanceCtrl,
                isLocked: locked,
                focusNode: _advanceFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
            ]),
          ],
        );
      },
    );
  }

  Widget _buildItemRulesCard() {
    return ListenableBuilder(
      listenable:
          Listenable.merge([logic.itemRulesLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.itemRulesLocked.value;
        final bool loading =
            logic.loadingSection.value == PurchaseSection.itemRules;

        return BillingSectionCard(
          title: BillingSetupStrings.secPurItem,
          subtitle: BillingSetupStrings.subPurItem,
          sectionIcon: BillingSetupIcons.weight,
          accentColor: BillingSetupColors.purItem,
          isLocked: locked,
          isLoading: loading,
          isVerified: true,
          onToggle: () => _saveSection(PurchaseSection.itemRules),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subPurItem),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblWeightTolerance,
                hint: BillingSetupStrings.hintWeightTol,
                icon: BillingSetupIcons.weight,
                brandColor: BillingSetupColors.purItem,
                ctrl: _weightCtrl,
                isLocked: locked,
                focusNode: _weightFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: ListenableBuilder(
                listenable: logic.selectedKarat,
                builder: (_, __) => BillingDropdownField(
                  label: BillingSetupStrings.lblPurKarat,
                  icon: BillingSetupIcons.karat,
                  brandColor: BillingSetupColors.purItem,
                  value: logic.selectedKarat.value,
                  items: BillingSetupStrings.karatOptions,
                  isLocked: locked,
                  onChanged: (v) => logic.selectedKarat.value = v!,
                ),
              )),
            ]),
          ],
        );
      },
    );
  }

  Widget _buildTermsCard() {
    return ListenableBuilder(
      listenable: Listenable.merge([logic.termsLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.termsLocked.value;
        final bool loading =
            logic.loadingSection.value == PurchaseSection.termsAndPrint;

        return BillingSectionCard(
          title: BillingSetupStrings.secPurTerms,
          subtitle: BillingSetupStrings.subPurTerms,
          sectionIcon: BillingSetupIcons.terms,
          accentColor: BillingSetupColors.purTerms,
          isLocked: locked,
          isLoading: loading,
          isVerified: _termsCtrl.text.isNotEmpty,
          onToggle: () => _saveSection(PurchaseSection.termsAndPrint),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subPurTerms),
            const SizedBox(height: 14),
            BillingInputField(
              label: BillingSetupStrings.lblPurTerms,
              hint: BillingSetupStrings.hintPurTerms,
              icon: BillingSetupIcons.terms,
              brandColor: BillingSetupColors.purTerms,
              ctrl: _termsCtrl,
              isLocked: locked,
              focusNode: _termsFocus,
              maxLines: 4,
            ),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: logic.autoPrint,
              builder: (_, __) => BillingToggleRow(
                label: BillingSetupStrings.lblPurAutoPrint,
                icon: BillingSetupIcons.autoPrint,
                accentColor: BillingSetupColors.purTerms,
                value: logic.autoPrint.value,
                isLocked: locked,
                onChanged: (v) => logic.autoPrint.value = v,
              ),
            ),
          ],
        );
      },
    );
  }
}
