// =============================================================================
// FILE        : lib/ui/settings/billing_setup/tabs/return_billing_tab.dart
// MODULE      : Billing Setup
// LAYER       : Presentation / UI
// DESCRIPTION : Return & Buyback configuration — 3 sections.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../logic/setting/billing_setup/billing_setup_logic.dart';
import '../../../../repositories/setting/billing_setup/billing_setup_repository.dart';
import '../../../../theme/settings/billing_setup/billing_setup_theme.dart';
import 'billing_setup_app_bar.dart';
import 'billing_section_card.dart';

class ReturnBillingTab extends StatefulWidget {
  const ReturnBillingTab({super.key});

  @override
  State<ReturnBillingTab> createState() => _ReturnBillingTabState();
}

class _ReturnBillingTabState extends State<ReturnBillingTab> {
  late ReturnBillingLogic logic;
  final BillingSetupRepository _repo = BillingSetupRepository();
  bool _loading = true;

  // ── Controllers ─────────────────────────────────────────────────────────
  final _windowCtrl = TextEditingController();
  final _handlingCtrl = TextEditingController();
  final _voucherCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _purityCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();

  // ── Focus Nodes ──────────────────────────────────────────────────────────
  final _windowFocus = FocusNode();
  final _handlingFocus = FocusNode();
  final _voucherFocus = FocusNode();
  final _rateFocus = FocusNode();
  final _purityFocus = FocusNode();
  final _termsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    logic = ReturnBillingLogic();
    _loadData();
  }

  Future<void> _loadData() async {
    final row = await _repo.fetchSettings();
    final m = row != null ? _repo.rowToReturnModel(row) : null;
    logic.init(m);
    final d = m ?? logic.defaults;
    _windowCtrl.text = d.returnWindowDays.toString();
    _handlingCtrl.text = d.handlingChargePercent.toString();
    _voucherCtrl.text = d.returnVoucherPrefix;
    _rateCtrl.text = d.buybackRatePercent.toString();
    _purityCtrl.text = d.buybackPurityDeductPercent.toString();
    _termsCtrl.text = d.terms;
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    logic.dispose();
    for (final c in [
      _windowCtrl,
      _handlingCtrl,
      _voucherCtrl,
      _rateCtrl,
      _purityCtrl,
      _termsCtrl
    ]) c.dispose();
    for (final f in [
      _windowFocus,
      _handlingFocus,
      _voucherFocus,
      _rateFocus,
      _purityFocus,
      _termsFocus
    ]) f.dispose();
    super.dispose();
  }

  Future<void> _saveSection(ReturnSection section) async {
    if (logic.lockedNotifier(section).value) {
      logic.unlockSection(section);
      return;
    }
    final model = logic.buildModel(
      window: _windowCtrl.text,
      handling: _handlingCtrl.text,
      voucher: _voucherCtrl.text,
      rate: _rateCtrl.text,
      purity: _purityCtrl.text,
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
        screenTitle: BillingSetupStrings.returnTitle,
        screenSubtitle: BillingSetupStrings.returnSub,
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
              _buildPolicyCard(),
              const SizedBox(height: 20),
              _buildBuybackCard(),
              const SizedBox(height: 20),
              _buildTermsCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section 1: Return Policy ─────────────────────────────────────────────
  Widget _buildPolicyCard() {
    return ListenableBuilder(
      listenable: Listenable.merge([logic.policyLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.policyLocked.value;
        final bool loading =
            logic.loadingSection.value == ReturnSection.returnPolicy;

        return BillingSectionCard(
          title: BillingSetupStrings.secRetPolicy,
          subtitle: BillingSetupStrings.subRetPolicy,
          sectionIcon: BillingSetupIcons.returnWindow,
          accentColor: BillingSetupColors.retPolicy,
          isLocked: locked,
          isLoading: loading,
          isVerified: true,
          onToggle: () => _saveSection(ReturnSection.returnPolicy),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subRetPolicy),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblRetWindow,
                hint: BillingSetupStrings.hintRetWindow,
                icon: BillingSetupIcons.returnWindow,
                brandColor: BillingSetupColors.retPolicy,
                ctrl: _windowCtrl,
                isLocked: locked,
                focusNode: _windowFocus,
                nextFocus: _handlingFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblHandlingCharge,
                hint: BillingSetupStrings.hintHandlingCharge,
                icon: BillingSetupIcons.handling,
                brandColor: BillingSetupColors.retPolicy,
                ctrl: _handlingCtrl,
                isLocked: locked,
                focusNode: _handlingFocus,
                nextFocus: _voucherFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              )),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: ListenableBuilder(
                listenable: logic.selectedReturnMode,
                builder: (_, __) => BillingDropdownField(
                  label: BillingSetupStrings.lblReturnMode,
                  icon: BillingSetupIcons.returnMode,
                  brandColor: BillingSetupColors.retPolicy,
                  value: logic.selectedReturnMode.value,
                  items: BillingSetupStrings.returnModes,
                  isLocked: locked,
                  onChanged: (v) => logic.selectedReturnMode.value = v!,
                ),
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblRetVoucher,
                hint: BillingSetupStrings.hintRetVoucher,
                icon: BillingSetupIcons.voucherPrefix,
                brandColor: BillingSetupColors.retPolicy,
                ctrl: _voucherCtrl,
                isLocked: locked,
                focusNode: _voucherFocus,
              )),
            ]),
          ],
        );
      },
    );
  }

  // ── Section 2: Buyback ───────────────────────────────────────────────────
  Widget _buildBuybackCard() {
    return ListenableBuilder(
      listenable: Listenable.merge([logic.buybackLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.buybackLocked.value;
        final bool loading =
            logic.loadingSection.value == ReturnSection.buyback;

        return BillingSectionCard(
          title: BillingSetupStrings.secBuyback,
          subtitle: BillingSetupStrings.subBuyback,
          sectionIcon: BillingSetupIcons.buybackRate,
          accentColor: BillingSetupColors.retBuyback,
          isLocked: locked,
          isLoading: loading,
          isVerified: true,
          onToggle: () => _saveSection(ReturnSection.buyback),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subBuyback),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblBuybackRate,
                hint: BillingSetupStrings.hintBuybackRate,
                icon: BillingSetupIcons.buybackRate,
                brandColor: BillingSetupColors.retBuyback,
                ctrl: _rateCtrl,
                isLocked: locked,
                focusNode: _rateFocus,
                nextFocus: _purityFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblPurityDeduct,
                hint: BillingSetupStrings.hintPurityDeduct,
                icon: BillingSetupIcons.purity,
                brandColor: BillingSetupColors.retBuyback,
                ctrl: _purityCtrl,
                isLocked: locked,
                focusNode: _purityFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              )),
            ]),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: logic.selectedKarat,
              builder: (_, __) => BillingDropdownField(
                label: BillingSetupStrings.lblBuybackKarat,
                icon: BillingSetupIcons.karat,
                brandColor: BillingSetupColors.retBuyback,
                value: logic.selectedKarat.value,
                items: BillingSetupStrings.karatOptions,
                isLocked: locked,
                onChanged: (v) => logic.selectedKarat.value = v!,
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Section 3: Terms ─────────────────────────────────────────────────────
  Widget _buildTermsCard() {
    return ListenableBuilder(
      listenable: Listenable.merge([logic.termsLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.termsLocked.value;
        final bool loading = logic.loadingSection.value == ReturnSection.terms;

        return BillingSectionCard(
          title: BillingSetupStrings.secRetTerms,
          subtitle: BillingSetupStrings.subRetTerms,
          sectionIcon: BillingSetupIcons.terms,
          accentColor: BillingSetupColors.retTerms,
          isLocked: locked,
          isLoading: loading,
          isVerified: _termsCtrl.text.isNotEmpty,
          onToggle: () => _saveSection(ReturnSection.terms),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subRetTerms),
            const SizedBox(height: 14),
            BillingInputField(
              label: BillingSetupStrings.lblRetTerms,
              hint: BillingSetupStrings.hintRetTerms,
              icon: BillingSetupIcons.terms,
              brandColor: BillingSetupColors.retTerms,
              ctrl: _termsCtrl,
              isLocked: locked,
              focusNode: _termsFocus,
              maxLines: 4,
            ),
          ],
        );
      },
    );
  }
}
