// =============================================================================
// FILE        : lib/ui/settings/billing_setup/girvi/girvi_billing_screen.dart
// MODULE      : Billing Setup Ã¢â€ â€™ Girvi
// DESCRIPTION : Girvi interest, invoice display, notice and print settings.
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
import 'girvi_invoice_display_editor.dart';

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
  String _selectedInvoiceMetal = GirviBillingMetal.gold;

  // Controllers
  final _interestCtrl = TextEditingController();
  final _graceCtrl = TextEditingController();
  final _reminderCtrl = TextEditingController();
  final _noticeCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _termsHindiCtrl = TextEditingController();
  final _declarationCtrl = TextEditingController();
  final _declarationHindiCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();

  static const Color _accent = BillingSetupColors.girviBrand;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _interestCtrl,
      _graceCtrl,
      _reminderCtrl,
      _noticeCtrl,
      _termsCtrl,
      _termsHindiCtrl,
      _declarationCtrl,
      _declarationHindiCtrl,
      _footerCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final model = await _repo.fetch();
    _model = model;
    _interestCtrl.text = model.defaultInterestRate.toString();
    _graceCtrl.text = model.gracePeriodDays.toString();
    _reminderCtrl.text = model.reminderDays.toString();
    _noticeCtrl.text = model.noticeDays.toString();
    _termsCtrl.text = model.termsAndConditions;
    _termsHindiCtrl.text = model.termsAndConditionsHindi;
    _declarationCtrl.text = model.customerDeclaration;
    _declarationHindiCtrl.text = model.customerDeclarationHindi;
    _footerCtrl.text = model.footerMessage;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = _model.copyWith(
      defaultInterestRate: double.tryParse(_interestCtrl.text.trim()) ??
          _model.defaultInterestRate,
      gracePeriodDays:
          int.tryParse(_graceCtrl.text.trim()) ?? _model.gracePeriodDays,
      reminderDays:
          int.tryParse(_reminderCtrl.text.trim()) ?? _model.reminderDays,
      noticeDays: int.tryParse(_noticeCtrl.text.trim()) ?? _model.noticeDays,
      termsAndConditions: _termsCtrl.text.trim(),
      termsAndConditionsHindi: _termsHindiCtrl.text.trim(),
      customerDeclaration: _declarationCtrl.text.trim(),
      customerDeclarationHindi: _declarationHindiCtrl.text.trim(),
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
          screenSubtitle: 'Interest, invoice display and notice controls',
          onBack: () => Navigator.maybePop(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _GirviIntroPanel(
                    accent: _accent,
                    interestRate: _model.defaultInterestRate,
                    interestType: _model.interestType,
                    autoPrint: _model.autoPrint,
                    invoiceFieldCount: _model.visibleInvoiceFieldCount,
                  ),
                  const SizedBox(height: 18),
                  // Ã¢â€â‚¬Ã¢â€â‚¬ Section 1: Voucher Numbering Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  // Ã¢â€â‚¬Ã¢â€â‚¬ Section 2: Interest Rules Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
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

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Section 3: Reminder & Notice Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
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

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Section 4: Terms & Print Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  _SectionCard(
                    title: 'Invoice Item Display',
                    subtitle:
                        'Choose every item, weight and valuation field separately for each metal',
                    icon: Icons.view_column_outlined,
                    accent: BillingSetupColors.girviBrand,
                    children: [
                      GirviInvoiceDisplayEditor(
                        model: _model,
                        selectedMetal: _selectedInvoiceMetal,
                        onMetalChanged: (metal) => setState(
                          () => _selectedInvoiceMetal = metal,
                        ),
                        onChanged: (updated) =>
                            setState(() => _model = updated),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Customer Receipt Display',
                    subtitle:
                        'Choose customer, loan, payment, KYC and remarks sections',
                    icon: Icons.receipt_long_outlined,
                    accent: BillingSetupColors.grvTerms,
                    children: [
                      GirviInvoiceDocumentEditor(
                        model: _model,
                        onChanged: (updated) =>
                            setState(() => _model = updated),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Terms, Footer & Operations',
                    subtitle:
                        'Customer-facing print text and automatic printing',
                    icon: Icons.article_outlined,
                    accent: BillingSetupColors.grvTerms,
                    children: [
                      _InputField(
                        label: 'Terms & Conditions - English',
                        hint: 'Enter one English condition per line...',
                        ctrl: _termsCtrl,
                        accent: BillingSetupColors.grvTerms,
                        maxLines: 7,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'Terms & Conditions - Hindi',
                        hint:
                            'Enter matching Hindi conditions in the same line order...',
                        ctrl: _termsHindiCtrl,
                        accent: BillingSetupColors.grvTerms,
                        maxLines: 7,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'Customer Declaration - English',
                        hint:
                            'Declaration acknowledged by the customer before signing...',
                        ctrl: _declarationCtrl,
                        accent: BillingSetupColors.grvTerms,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'Customer Declaration - Hindi',
                        hint:
                            'Customer declaration in Hindi for bilingual printing...',
                        ctrl: _declarationHindiCtrl,
                        accent: BillingSetupColors.grvTerms,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'Footer Message',
                        hint:
                            'Optional customer message printed when Footer Message is enabled',
                        ctrl: _footerCtrl,
                        accent: BillingSetupColors.grvTerms,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
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

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Save Button Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
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
  final double interestRate;
  final String interestType;
  final bool autoPrint;
  final int invoiceFieldCount;

  const _GirviIntroPanel({
    required this.accent,
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
                      'Manage interest calculation, reminders, invoice fields and printed terms.',
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
                label: '${interestRate.toStringAsFixed(2)}% $interestType',
                icon: Icons.percent_rounded,
                accent: accent,
              ),
              _SummaryPill(
                label: '$invoiceFieldCount active fields',
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
