// =============================================================================
// FILE        : lib/ui/settings/billing_setup/tabs/sales_billing_tab.dart
// MODULE      : Billing Setup
// LAYER       : Presentation / UI
// DESCRIPTION : Sales Billing configuration — 6 sections.
//               Lock/edit/save per section. Loads from DB on init.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../logic/setting/billing_setup/billing_setup_logic.dart';
import '../../../../repositories/setting/billing_setup/billing_setup_repository.dart';
import '../../../../theme/settings/billing_setup/billing_setup_theme.dart';
import 'billing_setup_app_bar.dart';
import 'billing_section_card.dart';

class SalesBillingTab extends StatefulWidget {
  const SalesBillingTab({super.key});

  @override
  State<SalesBillingTab> createState() => _SalesBillingTabState();
}

class _SalesBillingTabState extends State<SalesBillingTab> {
  late SalesBillingLogic logic;
  final BillingSetupRepository _repo = BillingSetupRepository();
  bool _loading = true;

  // ── Controllers ─────────────────────────────────────────────────────────
  final _prefixCtrl = TextEditingController();
  final _startNoCtrl = TextEditingController();
  final _estPrefixCtrl = TextEditingController();
  final _estDaysCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _creditDaysCtrl = TextEditingController();
  final _minAdvanceCtrl = TextEditingController();
  final _maxDiscCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();

  // ── Focus Nodes ──────────────────────────────────────────────────────────
  final _prefixFocus = FocusNode();
  final _startNoFocus = FocusNode();
  final _estPrefixFocus = FocusNode();
  final _estDaysFocus = FocusNode();
  final _upiFocus = FocusNode();
  final _creditFocus = FocusNode();
  final _advanceFocus = FocusNode();
  final _discountFocus = FocusNode();
  final _termsFocus = FocusNode();
  final _footerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    logic = SalesBillingLogic();
    _loadData();
  }

  Future<void> _loadData() async {
    final row = await _repo.fetchSettings();
    final m = row != null ? _repo.rowToSalesModel(row) : null;
    logic.init(m);
    if (m != null) {
      _prefixCtrl.text = m.invoicePrefix;
      _startNoCtrl.text = m.startingNumber.toString();
      _estPrefixCtrl.text = m.estimatePrefix;
      _estDaysCtrl.text = m.estimateValidityDays.toString();
      _upiCtrl.text = m.upiId;
      _creditDaysCtrl.text = m.defaultCreditDays.toString();
      _minAdvanceCtrl.text = m.minAdvancePercent.toString();
      _maxDiscCtrl.text = m.maxDiscountPercent.toString();
      _termsCtrl.text = m.terms;
      _footerCtrl.text = m.footerMsg;
    } else {
      _prefixCtrl.text = logic.defaults.invoicePrefix;
      _estPrefixCtrl.text = logic.defaults.estimatePrefix;
      _startNoCtrl.text = logic.defaults.startingNumber.toString();
      _estDaysCtrl.text = logic.defaults.estimateValidityDays.toString();
      _creditDaysCtrl.text = logic.defaults.defaultCreditDays.toString();
      _minAdvanceCtrl.text = logic.defaults.minAdvancePercent.toString();
      _maxDiscCtrl.text = logic.defaults.maxDiscountPercent.toString();
      _termsCtrl.text = logic.defaults.terms;
      _footerCtrl.text = logic.defaults.footerMsg;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    logic.dispose();
    for (final c in [
      _prefixCtrl,
      _startNoCtrl,
      _estPrefixCtrl,
      _estDaysCtrl,
      _upiCtrl,
      _creditDaysCtrl,
      _minAdvanceCtrl,
      _maxDiscCtrl,
      _termsCtrl,
      _footerCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _prefixFocus,
      _startNoFocus,
      _estPrefixFocus,
      _estDaysFocus,
      _upiFocus,
      _creditFocus,
      _advanceFocus,
      _discountFocus,
      _termsFocus,
      _footerFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Save helper ──────────────────────────────────────────────────────────
  Future<void> _saveSection(BillingSection section) async {
    if (logic.lockedNotifier(section).value) {
      logic.unlockSection(section);
      return;
    }
    final model = logic.buildModel(
      prefix: _prefixCtrl.text,
      startNo: _startNoCtrl.text,
      estPrefix: _estPrefixCtrl.text,
      estDays: _estDaysCtrl.text,
      upiId: _upiCtrl.text,
      creditDays: _creditDaysCtrl.text,
      minAdvance: _minAdvanceCtrl.text,
      maxDiscount: _maxDiscCtrl.text,
      terms: _termsCtrl.text,
      footerMsg: _footerCtrl.text,
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

  // ── Build ────────────────────────────────────────────────────────────────
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
        screenTitle: BillingSetupStrings.salesTitle,
        screenSubtitle: BillingSetupStrings.salesSub,
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: BillingSetupStyles.pagePadding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 55,
                      child: Column(children: [
                        const SizedBox(height: 24),
                        _buildInvoiceCard(),
                        const SizedBox(height: 20),
                        _buildPaymentCard(),
                        const SizedBox(height: 20),
                        _buildDiscountCard(),
                      ]),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 45,
                      child: Column(children: [
                        const SizedBox(height: 24),
                        _buildDisplayCard(),
                        const SizedBox(height: 20),
                        _buildTermsCard(),
                      ]),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  const SizedBox(height: 24),
                  _buildInvoiceCard(),
                  const SizedBox(height: 20),
                  _buildPaymentCard(),
                  const SizedBox(height: 20),
                  _buildDiscountCard(),
                  const SizedBox(height: 20),
                  _buildDisplayCard(),
                  const SizedBox(height: 20),
                  _buildTermsCard(),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Section 1: Invoice Numbering ─────────────────────────────────────────
  Widget _buildInvoiceCard() {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [logic.invoiceNoLocked, logic.estimateLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.invoiceNoLocked.value;
        final bool loading =
            logic.loadingSection.value == BillingSection.invoiceNo;

        return BillingSectionCard(
          title: BillingSetupStrings.secInvoiceNo,
          subtitle: BillingSetupStrings.subInvoiceNo,
          sectionIcon: BillingSetupIcons.invoiceNo,
          accentColor: BillingSetupColors.salesInvoice,
          isLocked: locked,
          isLoading: loading,
          isVerified: _prefixCtrl.text.isNotEmpty,
          onToggle: () => _saveSection(BillingSection.invoiceNo),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subInvoiceNo),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblInvoicePrefix,
                hint: BillingSetupStrings.hintInvoicePrefix,
                icon: BillingSetupIcons.invoiceNo,
                brandColor: BillingSetupColors.salesInvoice,
                ctrl: _prefixCtrl,
                isLocked: locked,
                focusNode: _prefixFocus,
                nextFocus: _startNoFocus,
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblStartingNo,
                hint: BillingSetupStrings.hintStartingNo,
                icon: BillingSetupIcons.invoiceNo,
                brandColor: BillingSetupColors.salesInvoice,
                ctrl: _startNoCtrl,
                isLocked: locked,
                focusNode: _startNoFocus,
                nextFocus: _estPrefixFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
            ]),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: logic.yearlyReset,
              builder: (_, __) => BillingToggleRow(
                label: BillingSetupStrings.lblYearlyReset,
                icon: BillingSetupIcons.estimate,
                accentColor: BillingSetupColors.salesInvoice,
                value: logic.yearlyReset.value,
                isLocked: locked,
                onChanged: (v) => logic.yearlyReset.value = v,
              ),
            ),
            const BillingSectionLabel(BillingSetupStrings.subEstimate),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblEstimatePrefix,
                hint: BillingSetupStrings.hintEstimatePrefix,
                icon: BillingSetupIcons.estimate,
                brandColor: BillingSetupColors.salesEstimate,
                ctrl: _estPrefixCtrl,
                isLocked: locked,
                focusNode: _estPrefixFocus,
                nextFocus: _estDaysFocus,
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblEstValidity,
                hint: BillingSetupStrings.hintEstValidity,
                icon: BillingSetupIcons.creditDays,
                brandColor: BillingSetupColors.salesEstimate,
                ctrl: _estDaysCtrl,
                isLocked: locked,
                focusNode: _estDaysFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
            ]),
          ],
        );
      },
    );
  }

  // ── Section 2: Payment Settings ──────────────────────────────────────────
  Widget _buildPaymentCard() {
    return ListenableBuilder(
      listenable: Listenable.merge([logic.paymentLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.paymentLocked.value;
        final bool loading =
            logic.loadingSection.value == BillingSection.payment;

        return BillingSectionCard(
          title: BillingSetupStrings.secPayment,
          subtitle: BillingSetupStrings.subPayment,
          sectionIcon: BillingSetupIcons.payment,
          accentColor: BillingSetupColors.salesPayment,
          isLocked: locked,
          isLoading: loading,
          isVerified: true,
          onToggle: () => _saveSection(BillingSection.payment),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subPayment),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: logic.selectedPayMode,
              builder: (_, __) => BillingDropdownField(
                label: BillingSetupStrings.lblPayMode,
                icon: BillingSetupIcons.payment,
                brandColor: BillingSetupColors.salesPayment,
                value: logic.selectedPayMode.value,
                items: BillingSetupStrings.paymentModes,
                isLocked: locked,
                onChanged: (v) => logic.selectedPayMode.value = v!,
              ),
            ),
            const SizedBox(height: 14),
            BillingInputField(
              label: BillingSetupStrings.lblUpiId,
              hint: BillingSetupStrings.hintUpiId,
              icon: BillingSetupIcons.upi,
              brandColor: BillingSetupColors.salesPayment,
              ctrl: _upiCtrl,
              isLocked: locked,
              focusNode: _upiFocus,
              nextFocus: _creditFocus,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblCreditDays,
                hint: BillingSetupStrings.hintCreditDays,
                icon: BillingSetupIcons.creditDays,
                brandColor: BillingSetupColors.salesPayment,
                ctrl: _creditDaysCtrl,
                isLocked: locked,
                focusNode: _creditFocus,
                nextFocus: _advanceFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblMinAdvance,
                hint: BillingSetupStrings.hintMinAdvance,
                icon: BillingSetupIcons.advance,
                brandColor: BillingSetupColors.salesPayment,
                ctrl: _minAdvanceCtrl,
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

  // ── Section 3: Discount & Rounding ───────────────────────────────────────
  Widget _buildDiscountCard() {
    return ListenableBuilder(
      listenable:
          Listenable.merge([logic.discountLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.discountLocked.value;
        final bool loading =
            logic.loadingSection.value == BillingSection.discount;

        return BillingSectionCard(
          title: BillingSetupStrings.secDiscount,
          subtitle: BillingSetupStrings.subDiscount,
          sectionIcon: BillingSetupIcons.discount,
          accentColor: BillingSetupColors.salesDiscount,
          isLocked: locked,
          isLoading: loading,
          isVerified: true,
          onToggle: () => _saveSection(BillingSection.discount),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subDiscount),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: logic.allowDiscount,
              builder: (_, __) => BillingToggleRow(
                label: BillingSetupStrings.lblAllowDiscount,
                subtitle: 'Staff ko discount dene ka permission',
                icon: BillingSetupIcons.discount,
                accentColor: BillingSetupColors.salesDiscount,
                value: logic.allowDiscount.value,
                isLocked: locked,
                onChanged: (v) => logic.allowDiscount.value = v,
              ),
            ),
            const SizedBox(height: 14),
            BillingInputField(
              label: BillingSetupStrings.lblMaxDiscount,
              hint: BillingSetupStrings.hintMaxDiscount,
              icon: BillingSetupIcons.discount,
              brandColor: BillingSetupColors.salesDiscount,
              ctrl: _maxDiscCtrl,
              isLocked: locked,
              focusNode: _discountFocus,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: logic.selectedRounding,
              builder: (_, __) => BillingDropdownField(
                label: BillingSetupStrings.lblRounding,
                icon: BillingSetupIcons.rounding,
                brandColor: BillingSetupColors.salesDiscount,
                value: logic.selectedRounding.value,
                items: BillingSetupStrings.roundingRules,
                isLocked: locked,
                onChanged: (v) => logic.selectedRounding.value = v!,
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Section 4: Invoice Display ────────────────────────────────────────────
  Widget _buildDisplayCard() {
    return ListenableBuilder(
      listenable: Listenable.merge([logic.displayLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.displayLocked.value;
        final bool loading =
            logic.loadingSection.value == BillingSection.display;

        return BillingSectionCard(
          title: BillingSetupStrings.secDisplay,
          subtitle: BillingSetupStrings.subDisplay,
          sectionIcon: BillingSetupIcons.huid,
          accentColor: BillingSetupColors.salesDisplay,
          isLocked: locked,
          isLoading: loading,
          isVerified: true,
          onToggle: () => _saveSection(BillingSection.display),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subDisplay),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: logic.showMaking,
              builder: (_, __) => BillingToggleRow(
                label: BillingSetupStrings.lblShowMaking,
                subtitle: 'Alag line item ya price mein include',
                icon: BillingSetupIcons.makingCharge,
                accentColor: BillingSetupColors.salesDisplay,
                value: logic.showMaking.value,
                isLocked: locked,
                onChanged: (v) => logic.showMaking.value = v,
              ),
            ),
            const SizedBox(height: 10),
            ListenableBuilder(
              listenable: logic.showHuid,
              builder: (_, __) => BillingToggleRow(
                label: BillingSetupStrings.lblShowHuid,
                subtitle: 'BIS/Hallmark HUID — government requirement',
                icon: BillingSetupIcons.huid,
                accentColor: BillingSetupColors.salesDisplay,
                value: logic.showHuid.value,
                isLocked: locked,
                onChanged: (v) => logic.showHuid.value = v,
              ),
            ),
            const SizedBox(height: 10),
            ListenableBuilder(
              listenable: logic.showOldGold,
              builder: (_, __) => BillingToggleRow(
                label: BillingSetupStrings.lblShowOldGold,
                subtitle: 'Exchange mein purana sona diya ho toh',
                icon: BillingSetupIcons.oldGold,
                accentColor: BillingSetupColors.salesDisplay,
                value: logic.showOldGold.value,
                isLocked: locked,
                onChanged: (v) => logic.showOldGold.value = v,
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Section 5: Terms & Footer ─────────────────────────────────────────────
  Widget _buildTermsCard() {
    return ListenableBuilder(
      listenable: Listenable.merge([logic.termsLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.termsLocked.value;
        final bool loading = logic.loadingSection.value == BillingSection.terms;

        return BillingSectionCard(
          title: BillingSetupStrings.secSalesTerms,
          subtitle: BillingSetupStrings.subSalesTerms,
          sectionIcon: BillingSetupIcons.terms,
          accentColor: BillingSetupColors.salesTerms,
          isLocked: locked,
          isLoading: loading,
          isVerified: _termsCtrl.text.isNotEmpty,
          onToggle: () => _saveSection(BillingSection.terms),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subSalesTerms),
            const SizedBox(height: 14),
            BillingInputField(
              label: BillingSetupStrings.lblSalesTerms,
              hint: BillingSetupStrings.hintSalesTerms,
              icon: BillingSetupIcons.terms,
              brandColor: BillingSetupColors.salesTerms,
              ctrl: _termsCtrl,
              isLocked: locked,
              focusNode: _termsFocus,
              nextFocus: _footerFocus,
              maxLines: 4,
            ),
            const SizedBox(height: 14),
            BillingInputField(
              label: BillingSetupStrings.lblFooterMsg,
              hint: BillingSetupStrings.hintFooterMsg,
              icon: BillingSetupIcons.footer,
              brandColor: BillingSetupColors.salesTerms,
              ctrl: _footerCtrl,
              isLocked: locked,
              focusNode: _footerFocus,
              maxLines: 2,
            ),
          ],
        );
      },
    );
  }
}
