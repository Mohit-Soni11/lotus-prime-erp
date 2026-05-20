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
          screenSubtitle: BillingSetupStrings.girviSub,
          onBack: () => Navigator.maybePop(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // â”€â”€ Section 1: Voucher Numbering â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _SectionCard(
                    title: 'Girvi Voucher Numbering',
                    subtitle: 'Ticket prefix aur starting number',
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
                    subtitle: 'Loan par interest ka calculation',
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
                          subtitle: 'Due date ke baad extra days',
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
                    subtitle: 'Customer ko reminder aur notice kab bhejein',
                    icon: Icons.notifications_outlined,
                    accent: BillingSetupColors.grvNotice,
                    children: [
                      Row(children: [
                        Expanded(
                            child: _InputField(
                          label: 'Reminder Days',
                          hint: 'e.g. 15',
                          subtitle: 'Expiry se pehle',
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
                          subtitle: 'Expiry ke baad legal notice',
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
                  _SectionCard(
                    title: 'Terms & Print',
                    subtitle: 'Girvi ticket ke neeche print hoga',
                    icon: Icons.description_outlined,
                    accent: BillingSetupColors.grvTerms,
                    children: [
                      _InputField(
                        label: 'Terms & Conditions',
                        hint: 'Girvi ticket par print hone wali terms...',
                        ctrl: _termsCtrl,
                        accent: BillingSetupColors.grvTerms,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        label: 'Footer Message',
                        hint: 'e.g. Samay par bhagtaan karein.',
                        ctrl: _footerCtrl,
                        accent: BillingSetupColors.grvTerms,
                        maxLines: 2,
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
                            Text('Girvi ticket automatically print ho',
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      )),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      )),
                ],
              )),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              )),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text('Â· $subtitle',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                )),
          ],
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(fontSize: 13, color: const Color(0xFFD1D5DB)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
        ),
      ],
    );
  }
}
