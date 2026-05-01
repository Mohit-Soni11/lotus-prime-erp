// =============================================================================
// FILE        : lib/ui/settings/billing_setup/tabs/girvi_billing_tab.dart
// MODULE      : Billing Setup
// LAYER       : Presentation / UI
// DESCRIPTION : Girvi Billing configuration — 4 sections.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../logic/setting/billing_setup/billing_setup_logic.dart';
import '../../../../repositories/setting/billing_setup/billing_setup_repository.dart';
import '../../../../theme/settings/billing_setup/billing_setup_theme.dart';
import 'billing_setup_app_bar.dart';
import 'billing_section_card.dart';

class GirviBillingTab extends StatefulWidget {
  const GirviBillingTab({super.key});

  @override
  State<GirviBillingTab> createState() => _GirviBillingTabState();
}

class _GirviBillingTabState extends State<GirviBillingTab> {
  late GirviBillingLogic logic;
  final BillingSetupRepository _repo = BillingSetupRepository();
  bool _loading = true;

  // ── Controllers ─────────────────────────────────────────────────────────
  final _prefixCtrl = TextEditingController();
  final _startNoCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();
  final _graceCtrl = TextEditingController();
  final _reminderCtrl = TextEditingController();
  final _noticeCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();

  // ── Focus Nodes ──────────────────────────────────────────────────────────
  final _prefixFocus = FocusNode();
  final _startNoFocus = FocusNode();
  final _interestFocus = FocusNode();
  final _graceFocus = FocusNode();
  final _reminderFocus = FocusNode();
  final _noticeFocus = FocusNode();
  final _termsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    logic = GirviBillingLogic();
    _loadData();
  }

  Future<void> _loadData() async {
    final row = await _repo.fetchSettings();
    final m = row != null ? _repo.rowToGirviModel(row) : null;
    logic.init(m);
    final d = m ?? logic.defaults;
    _prefixCtrl.text = d.girviPrefix;
    _startNoCtrl.text = d.startingNumber.toString();
    _interestCtrl.text = d.defaultInterestRate.toString();
    _graceCtrl.text = d.gracePeriodDays.toString();
    _reminderCtrl.text = d.reminderDays.toString();
    _noticeCtrl.text = d.noticeDays.toString();
    _termsCtrl.text = d.terms;
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    logic.dispose();
    for (final c in [
      _prefixCtrl,
      _startNoCtrl,
      _interestCtrl,
      _graceCtrl,
      _reminderCtrl,
      _noticeCtrl,
      _termsCtrl
    ]) {
      c.dispose();
    }
    for (final f in [
      _prefixFocus,
      _startNoFocus,
      _interestFocus,
      _graceFocus,
      _reminderFocus,
      _noticeFocus,
      _termsFocus
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSection(GirviSection section) async {
    if (logic.lockedNotifier(section).value) {
      logic.unlockSection(section);
      return;
    }
    final model = logic.buildModel(
      prefix: _prefixCtrl.text,
      startNo: _startNoCtrl.text,
      interestRate: _interestCtrl.text,
      grace: _graceCtrl.text,
      reminder: _reminderCtrl.text,
      notice: _noticeCtrl.text,
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
        screenTitle: BillingSetupStrings.girviTitle,
        screenSubtitle: BillingSetupStrings.girviSub,
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
              _buildVoucherCard(),
              const SizedBox(height: 20),
              _buildInterestCard(),
              const SizedBox(height: 20),
              _buildNoticeCard(),
              const SizedBox(height: 20),
              _buildTermsCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCard() {
    return ListenableBuilder(
      listenable: Listenable.merge([logic.voucherLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.voucherLocked.value;
        final bool loading = logic.loadingSection.value == GirviSection.voucher;

        return BillingSectionCard(
          title: BillingSetupStrings.secGrvVoucher,
          subtitle: BillingSetupStrings.subGrvVoucher,
          sectionIcon: BillingSetupIcons.girviTicket,
          accentColor: BillingSetupColors.grvVoucher,
          isLocked: locked,
          isLoading: loading,
          isVerified: _prefixCtrl.text.isNotEmpty,
          onToggle: () => _saveSection(GirviSection.voucher),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subGrvVoucher),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblGrvPrefix,
                hint: BillingSetupStrings.hintGrvPrefix,
                icon: BillingSetupIcons.girviTicket,
                brandColor: BillingSetupColors.grvVoucher,
                ctrl: _prefixCtrl,
                isLocked: locked,
                focusNode: _prefixFocus,
                nextFocus: _startNoFocus,
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblGrvStartNo,
                hint: BillingSetupStrings.hintGrvStartNo,
                icon: BillingSetupIcons.girviTicket,
                brandColor: BillingSetupColors.grvVoucher,
                ctrl: _startNoCtrl,
                isLocked: locked,
                focusNode: _startNoFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
            ]),
          ],
        );
      },
    );
  }

  Widget _buildInterestCard() {
    return ListenableBuilder(
      listenable:
          Listenable.merge([logic.interestLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.interestLocked.value;
        final bool loading =
            logic.loadingSection.value == GirviSection.interest;

        return BillingSectionCard(
          title: BillingSetupStrings.secGrvInterest,
          subtitle: BillingSetupStrings.subGrvInterest,
          sectionIcon: BillingSetupIcons.interestRate,
          accentColor: BillingSetupColors.grvInterest,
          isLocked: locked,
          isLoading: loading,
          isVerified: true,
          onToggle: () => _saveSection(GirviSection.interest),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subGrvInterest),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblInterestRate,
                hint: BillingSetupStrings.hintInterestRate,
                icon: BillingSetupIcons.interestRate,
                brandColor: BillingSetupColors.grvInterest,
                ctrl: _interestCtrl,
                isLocked: locked,
                focusNode: _interestFocus,
                nextFocus: _graceFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: ListenableBuilder(
                listenable: logic.selectedInterestType,
                builder: (_, __) => BillingDropdownField(
                  label: BillingSetupStrings.lblInterestType,
                  icon: BillingSetupIcons.interestType,
                  brandColor: BillingSetupColors.grvInterest,
                  value: logic.selectedInterestType.value,
                  items: BillingSetupStrings.interestTypes,
                  isLocked: locked,
                  onChanged: (v) => logic.selectedInterestType.value = v!,
                ),
              )),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblGracePeriod,
                hint: BillingSetupStrings.hintGracePeriod,
                icon: BillingSetupIcons.gracePeriod,
                brandColor: BillingSetupColors.grvInterest,
                ctrl: _graceCtrl,
                isLocked: locked,
                focusNode: _graceFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: ListenableBuilder(
                listenable: logic.selectedDuration,
                builder: (_, __) => BillingDropdownField(
                  label: BillingSetupStrings.lblGrvDuration,
                  icon: BillingSetupIcons.duration,
                  brandColor: BillingSetupColors.grvInterest,
                  value: logic.selectedDuration.value,
                  items: BillingSetupStrings.girviDurations,
                  isLocked: locked,
                  onChanged: (v) => logic.selectedDuration.value = v!,
                ),
              )),
            ]),
          ],
        );
      },
    );
  }

  Widget _buildNoticeCard() {
    return ListenableBuilder(
      listenable: Listenable.merge([logic.noticeLocked, logic.loadingSection]),
      builder: (_, __) {
        final bool locked = logic.noticeLocked.value;
        final bool loading = logic.loadingSection.value == GirviSection.notice;

        return BillingSectionCard(
          title: BillingSetupStrings.secGrvNotice,
          subtitle: BillingSetupStrings.subGrvNotice,
          sectionIcon: BillingSetupIcons.notice,
          accentColor: BillingSetupColors.grvNotice,
          isLocked: locked,
          isLoading: loading,
          isVerified: true,
          onToggle: () => _saveSection(GirviSection.notice),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subGrvNotice),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblReminderDays,
                hint: BillingSetupStrings.hintReminderDays,
                icon: BillingSetupIcons.reminder,
                brandColor: BillingSetupColors.grvNotice,
                ctrl: _reminderCtrl,
                isLocked: locked,
                focusNode: _reminderFocus,
                nextFocus: _noticeFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: BillingInputField(
                label: BillingSetupStrings.lblNoticeDays,
                hint: BillingSetupStrings.hintNoticeDays,
                icon: BillingSetupIcons.notice,
                brandColor: BillingSetupColors.grvNotice,
                ctrl: _noticeCtrl,
                isLocked: locked,
                focusNode: _noticeFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            logic.loadingSection.value == GirviSection.termsAndPrint;

        return BillingSectionCard(
          title: BillingSetupStrings.secGrvTerms,
          subtitle: BillingSetupStrings.subGrvTerms,
          sectionIcon: BillingSetupIcons.terms,
          accentColor: BillingSetupColors.grvTerms,
          isLocked: locked,
          isLoading: loading,
          isVerified: _termsCtrl.text.isNotEmpty,
          onToggle: () => _saveSection(GirviSection.termsAndPrint),
          children: [
            const BillingSectionLabel(BillingSetupStrings.subGrvTerms),
            const SizedBox(height: 14),
            BillingInputField(
              label: BillingSetupStrings.lblGrvTerms,
              hint: BillingSetupStrings.hintGrvTerms,
              icon: BillingSetupIcons.terms,
              brandColor: BillingSetupColors.grvTerms,
              ctrl: _termsCtrl,
              isLocked: locked,
              focusNode: _termsFocus,
              maxLines: 4,
            ),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: logic.autoPrint,
              builder: (_, __) => BillingToggleRow(
                label: BillingSetupStrings.lblGrvAutoPrint,
                icon: BillingSetupIcons.autoPrint,
                accentColor: BillingSetupColors.grvTerms,
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
