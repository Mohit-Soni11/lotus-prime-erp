// =============================================================================
// FILE        : lib/ui/settings/billing_setup/girvi/girvi_billing_screen.dart
// MODULE      : Billing Setup â†’ Girvi
// DESCRIPTION : Single scrollable screen. 4 sections:
//               Voucher | Interest | Notice Period | Terms & Print
//               One Save button. No lock/unlock.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/setting/billing_setup/girvi_billing_model.dart';
import '../../../../repositories/setting/billing_setup/girvi_billing_repo.dart';
import '../../../../theme/settings/billing_setup/billing_setup_colors.dart';
import '../../../../theme/settings/billing_setup/billing_setup_strings.dart';
import 'billing_setup_app_bar.dart';

class GirviBillingScreen extends StatefulWidget {
  const GirviBillingScreen({super.key});

  @override
  State<GirviBillingScreen> createState() => _GirviBillingScreenState();
}

class _GirviBillingScreenState extends State<GirviBillingScreen> {
  final GirviBillingRepo _repo = GirviBillingRepo();
  late GirviBillingModel _model;
  bool _loading = true;
  bool _saving = false;

  // Controllers
  final _prefixCtrl = TextEditingController();
  final _startNoCtrl = TextEditingController();
  final _interestCtrl = TextEditingController();
  final _graceCtrl = TextEditingController();
  final _reminderCtrl = TextEditingController();
  final _noticeCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();

  static const Color _accent = BillingSetupColors.girviBrand;

  String get _ticketPreview {
    final prefix =
        _prefixCtrl.text.trim().isEmpty ? 'GRV-' : _prefixCtrl.text.trim();
    final number = int.tryParse(_startNoCtrl.text.trim()) ?? 1;
    return '$prefix${number.toString().padLeft(4, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _prefixCtrl,
      _startNoCtrl,
      _interestCtrl,
      _graceCtrl,
      _reminderCtrl,
      _noticeCtrl,
      _termsCtrl,
      _footerCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final model = await _repo.fetch();
    _model = model;
    _prefixCtrl.text = model.girviPrefix;
    _startNoCtrl.text = model.startingNumber.toString();
    _interestCtrl.text = model.defaultInterestRate.toString();
    _graceCtrl.text = model.gracePeriodDays.toString();
    _reminderCtrl.text = model.reminderDays.toString();
    _noticeCtrl.text = model.noticeDays.toString();
    _termsCtrl.text = model.termsAndConditions;
    _footerCtrl.text = model.footerMessage;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = _model.copyWith(
      girviPrefix: _prefixCtrl.text.trim(),
      startingNumber:
          int.tryParse(_startNoCtrl.text.trim()) ?? _model.startingNumber,
      defaultInterestRate: double.tryParse(_interestCtrl.text.trim()) ??
          _model.defaultInterestRate,
      gracePeriodDays:
          int.tryParse(_graceCtrl.text.trim()) ?? _model.gracePeriodDays,
      reminderDays:
          int.tryParse(_reminderCtrl.text.trim()) ?? _model.reminderDays,
      noticeDays: int.tryParse(_noticeCtrl.text.trim()) ?? _model.noticeDays,
      termsAndConditions: _termsCtrl.text.trim(),
      footerMessage: _footerCtrl.text.trim(),
    );
    final ok = await _repo.save(updated);
    if (mounted) {
      setState(() {
        _saving = false;
        if (ok) _model = updated;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            ok ? 'Girvi settings saved!' : BillingSetupStrings.saveFailed,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor:
              ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: BillingSetupColors.bodyBg,
        appBar: BillingSetupAppBar(
          screenTitle: BillingSetupStrings.girviTitle,
          screenSubtitle:
              'Ticket numbering, interest rules and notice controls',
          onBack: () => Navigator.maybePop(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: BillingSetupColors.bodyBg,
      appBar: BillingSetupAppBar(
        screenTitle: BillingSetupStrings.girviTitle,
        screenSubtitle: 'Ticket numbering, interest rules and notice controls',
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _GirviIntroPanel(
                    accent: _accent,
                    ticketPreview: _ticketPreview,
                    interestRate: _model.defaultInterestRate,
                    interestType: _model.interestType,
                    autoPrint: _model.autoPrint,
                    invoiceFieldCount: _model.visibleInvoiceFieldCount,
                  ),
                  const SizedBox(height: 18),
                  // â”€â”€ Section 1: Voucher Numbering â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _SectionCard(
                    title: 'Ticket Numbering',
                    subtitle:
                        'Configure the pledge ticket prefix and next number',
                    icon: Icons.confirmation_number_outlined,
                    accent: _accent,
                    children: [
                      Row(children: [
                        Expanded(
                            child: _InputField(
                          label: 'Voucher Prefix',
                          hint: 'e.g. GRV-',
                          ctrl: _prefixCtrl,
                          accent: _accent,
                        )),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _InputField(
                          label: 'Starting Number',
                          hint: 'e.g. 1',
                          ctrl: _startNoCtrl,
                          accent: _accent,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        )),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // â”€â”€ Section 2: Interest Rules â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _SectionCard(
                    title: 'Interest Rules',
                    subtitle: 'Define how pledge interest is calculated',
                    icon: Icons.percent_rounded,
                    accent: BillingSetupColors.grvInterest,
                    children: [
                      Row(children: [
                        Expanded(
                            child: _InputField(
                          label: 'Interest Rate (% / month)',
                          hint: 'e.g. 1.5',
                          ctrl: _interestCtrl,
                          accent: BillingSetupColors.grvInterest,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        )),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _DropdownField(
                          label: 'Interest Type',
                          value: _model.interestType,
                          items: BillingSetupStrings.interestTypes,
                          accent: BillingSetupColors.grvInterest,
                          onChanged: (v) => setState(
                              () => _model = _model.copyWith(interestType: v)),
                        )),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: _InputField(
                          label: 'Grace Period (Days)',
                          hint: 'e.g. 3',
                          subtitle: 'Extra days after due date',
                          ctrl: _graceCtrl,
                          accent: BillingSetupColors.grvInterest,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        )),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _DropdownField(
                          label: 'Default Loan Duration',
                          value: _model.defaultDuration,
                          items: BillingSetupStrings.girviDurations,
                          accent: BillingSetupColors.grvInterest,
                          onChanged: (v) => setState(() =>
                              _model = _model.copyWith(defaultDuration: v)),
                        )),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // â”€â”€ Section 3: Reminder & Notice â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _SectionCard(
                    title: 'Reminder & Notice Period',
                    subtitle: 'Set reminder timing and legal notice window',
                    icon: Icons.notifications_outlined,
                    accent: BillingSetupColors.grvNotice,
                    children: [
                      Row(children: [
                        Expanded(
                            child: _InputField(
                          label: 'Reminder Days',
                          hint: 'e.g. 15',
                          subtitle: 'Before maturity',
                          ctrl: _reminderCtrl,
                          accent: BillingSetupColors.grvNotice,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        )),
                        const SizedBox(width: 14),
                        Expanded(
                            child: _InputField(
                          label: 'Notice Days',
                          hint: 'e.g. 30',
                          subtitle: 'After maturity',
                          ctrl: _noticeCtrl,
                          accent: BillingSetupColors.grvNotice,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        )),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // â”€â”€ Section 4: Terms & Print â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  const _SectionCard(
                    title: 'Invoice Item Display',
                    subtitle: 'Fixed customer-safe Girvi invoice format',
                    icon: Icons.view_column_outlined,
                    accent: BillingSetupColors.girviBrand,
                    children: [_GirviCustomerInvoiceFormat()],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Terms & Operations',
                    subtitle: 'Saved for internal notices and Girvi operations',
                    icon: Icons.article_outlined,
                    accent: BillingSetupColors.grvTerms,
                    children: [
                      _InputField(
                        label: 'Terms & Conditions',
                        hint: 'Enter internal Girvi terms...',
                        ctrl: _termsCtrl,
                        accent: BillingSetupColors.grvTerms,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'Footer Message',
                        hint: 'Optional internal note...',
                        ctrl: _footerCtrl,
                        accent: BillingSetupColors.grvTerms,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      // Auto Print toggle
                      Row(children: [
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Auto Print',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: BillingSetupColors.textDark,
                                )),
                            Text(
                                'Print the pledge ticket immediately after saving',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: BillingSetupColors.textMuted,
                                )),
                          ],
                        )),
                        Switch(
                          value: _model.autoPrint,
                          onChanged: (v) => setState(
                              () => _model = _model.copyWith(autoPrint: v)),
                          activeThumbColor: BillingSetupColors.grvTerms,
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // â”€â”€ Save Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Save Girvi Settings',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              )),
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _GirviIntroPanel extends StatelessWidget {
  final Color accent;
  final String ticketPreview;
  final double interestRate;
  final String interestType;
  final bool autoPrint;
  final int invoiceFieldCount;

  const _GirviIntroPanel({
    required this.accent,
    required this.ticketPreview,
    required this.interestRate,
    required this.interestType,
    required this.autoPrint,
    required this.invoiceFieldCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          final titleBlock = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.16)),
                ),
                child: Icon(Icons.security_rounded, color: accent, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Girvi billing controls',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage pledge ticket numbering, interest calculation, reminders and printed terms.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.35,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final pills = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _SummaryPill(
                label: ticketPreview,
                icon: Icons.confirmation_number_rounded,
                accent: accent,
              ),
              _SummaryPill(
                label: '${interestRate.toStringAsFixed(2)}% $interestType',
                icon: Icons.percent_rounded,
                accent: accent,
              ),
              _SummaryPill(
                label: '$invoiceFieldCount fixed columns',
                icon: Icons.view_column_outlined,
                accent: accent,
              ),
              _SummaryPill(
                label: autoPrint ? 'Auto print on' : 'Auto print off',
                icon: Icons.print_rounded,
                accent: accent,
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 14),
                pills,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 14),
              pills,
            ],
          );
        },
      ),
    );
  }
}

class _GirviCustomerInvoiceFormat extends StatelessWidget {
  const _GirviCustomerInvoiceFormat();

  static const _items = <(IconData, String, String)>[
    (
      Icons.view_column_outlined,
      '9 fixed item columns',
      'S/N, Metal, Item, Pcs, HUID, Purity, Gross, Less and Net',
    ),
    (
      Icons.percent_rounded,
      'Loan details',
      'Loan amount and monthly interest percentage only',
    ),
    (
      Icons.photo_camera_outlined,
      'Item photos',
      'Attached pledged-item photos are included automatically',
    ),
    (
      Icons.visibility_off_outlined,
      'Internal valuation protected',
      'Valuation purity, fine weight, rate and value never print',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _items
          .map(
            (item) => Container(
              width: 330,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BillingSetupColors.girviBrand.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: BillingSetupColors.girviBrand.withValues(alpha: 0.16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.$1,
                    color: BillingSetupColors.girviBrand,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        Text(
                          item.$3,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: BillingSetupColors.girviBrand,
                    size: 17,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// Legacy editor retained so older setup code remains source-compatible.
// ignore: unused_element
class _GirviInvoiceDisplayEditor extends StatelessWidget {
  const _GirviInvoiceDisplayEditor({
    required this.model,
    required this.onChanged,
  });

  final GirviBillingModel model;
  final ValueChanged<GirviBillingModel> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <_GirviDisplayOption>[
      _option('Metal', 'Gold, silver or other metal', Icons.category_outlined,
          model.showMetal, (v) => model.copyWith(showMetal: v)),
      _option('Pieces', 'Pledged item quantity', Icons.numbers_rounded,
          model.showPieces, (v) => model.copyWith(showPieces: v)),
      _option('Gross Weight', 'Total item weight', Icons.scale_outlined,
          model.showGrossWeight, (v) => model.copyWith(showGrossWeight: v)),
      _option(
          'Less Weight',
          'Stone and non-metal deduction',
          Icons.remove_circle_outline_rounded,
          model.showLessWeight,
          (v) => model.copyWith(showLessWeight: v)),
      _option('Net Weight', 'Weight after deductions', Icons.balance_outlined,
          model.showNetWeight, (v) => model.copyWith(showNetWeight: v)),
      _option(
          'Entered Purity',
          'Purity recorded at entry',
          Icons.diamond_outlined,
          model.showPurity,
          (v) => model.copyWith(showPurity: v)),
      _option(
          'Valuation Purity',
          'Purity used for valuation',
          Icons.verified_outlined,
          model.showValuationPurity,
          (v) => model.copyWith(showValuationPurity: v)),
      _option(
          'Fine Weight',
          'Purity-adjusted weight',
          Icons.monitor_weight_outlined,
          model.showFineWeight,
          (v) => model.copyWith(showFineWeight: v)),
      _option('Rate / Gram', 'Valuation rate used', Icons.trending_up_rounded,
          model.showRate, (v) => model.copyWith(showRate: v)),
      _option(
          'HUID',
          'Hallmark identification number',
          Icons.fingerprint_rounded,
          model.showHuid,
          (v) => model.copyWith(showHuid: v)),
      _option('Item Value', 'Calculated pledged value', Icons.payments_outlined,
          model.showTotalValue, (v) => model.copyWith(showTotalValue: v)),
      _option(
          'Item Photos',
          'Attached pledged item photos',
          Icons.photo_camera_outlined,
          model.showItemPhotos,
          (v) => model.copyWith(showItemPhotos: v)),
      _option('KYC Details', 'Proof type and card number', Icons.badge_outlined,
          model.showKycDetails, (v) => model.copyWith(showKycDetails: v)),
      _option(
          'Disbursement Split',
          'Cash, UPI, Bank and Cheque',
          Icons.account_balance_wallet_outlined,
          model.showDisbursementDetails,
          (v) => model.copyWith(showDisbursementDetails: v)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 620
                ? 2
                : 1;
        const gap = 10.0;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: options
              .map(
                (option) => SizedBox(
                  width: width,
                  child: _GirviDisplayTile(
                    option: option,
                    accent: BillingSetupColors.girviBrand,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  _GirviDisplayOption _option(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    GirviBillingModel Function(bool value) update,
  ) {
    return _GirviDisplayOption(
      title: title,
      subtitle: subtitle,
      icon: icon,
      value: value,
      onChanged: (enabled) => onChanged(update(enabled)),
    );
  }
}

class _GirviDisplayTile extends StatelessWidget {
  const _GirviDisplayTile({
    required this.option,
    required this.accent,
  });

  final _GirviDisplayOption option;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: option.value
            ? accent.withValues(alpha: 0.06)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: option.value
              ? accent.withValues(alpha: 0.2)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(
            option.icon,
            color: option.value ? accent : const Color(0xFF9CA3AF),
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF374151),
                  ),
                ),
                Text(
                  option.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: option.value,
            onChanged: option.onChanged,
            activeThumbColor: accent,
          ),
        ],
      ),
    );
  }
}

class _GirviDisplayOption {
  const _GirviDisplayOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
}

// ignore: unused_element
class _PrintContentToggle extends StatelessWidget {
  const _PrintContentToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF374151),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: accent,
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;

  const _SummaryPill({
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.16)),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.3,
                        color: const Color(0xFF6B7280),
                      )),
                ],
              )),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final String? subtitle;
  final TextEditingController ctrl;
  final Color accent;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  const _InputField({
    required this.label,
    required this.hint,
    required this.ctrl,
    required this.accent,
    this.subtitle,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              )),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Text('- $subtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  )),
            ),
          ],
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(fontSize: 13, color: const Color(0xFFD1D5DB)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Color accent;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            )),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : items.first,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          style:
              GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827)),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }
}
