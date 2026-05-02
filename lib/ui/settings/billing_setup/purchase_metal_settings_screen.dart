// =============================================================================
// FILE        : lib/ui/settings/billing_setup/purchase/purchase_metal_settings_screen.dart
// MODULE      : Billing Setup → Purchase
// DESCRIPTION : Settings screen for one metal — purchase side.
//               3 sections: Voucher Display | Return Policy | Terms & Template
//               Single scrollable screen. One Save button. No lock/unlock.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/setting/billing_setup/purchase_billing_model.dart';
import '../../../../models/setting/billing_setup/sales_billing_model.dart';
import '../../../repositories/setting/billing_setup/purchase_billing_repo.dart';
import '../../../../theme/settings/billing_setup/billing_setup_theme.dart';
import 'billing_setup_app_bar.dart';

class PurchaseMetalSettingsScreen extends StatefulWidget {
  final String metal;
  const PurchaseMetalSettingsScreen({super.key, required this.metal});

  @override
  State<PurchaseMetalSettingsScreen> createState() =>
      _PurchaseMetalSettingsScreenState();
}

class _PurchaseMetalSettingsScreenState
    extends State<PurchaseMetalSettingsScreen> {
  final PurchaseBillingRepo _repo = PurchaseBillingRepo();
  late PurchaseBillingModel _model;
  bool _loading = true;
  bool _saving = false;

  final _returnWindowCtrl = TextEditingController();
  final _purityDeductCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();

  Color get _accent => _metalAccent(widget.metal);
  String get _metalDisplay => BillingMetal.displayName(widget.metal);
  String get _metalEmoji => BillingMetal.emoji(widget.metal);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _returnWindowCtrl.dispose();
    _purityDeductCtrl.dispose();
    _termsCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final model = await _repo.fetchForMetal(widget.metal);
    _model = model;
    _returnWindowCtrl.text = model.returnWindowDays.toString();
    _purityDeductCtrl.text = model.purityDeductPercent.toString();
    _termsCtrl.text = model.termsAndConditions;
    _footerCtrl.text = model.footerMessage;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = _model.copyWith(
      returnWindowDays: int.tryParse(_returnWindowCtrl.text.trim()) ??
          _model.returnWindowDays,
      purityDeductPercent: double.tryParse(_purityDeductCtrl.text.trim()) ??
          _model.purityDeductPercent,
      termsAndConditions: _termsCtrl.text.trim(),
      footerMessage: _footerCtrl.text.trim(),
    );
    final ok = await _repo.saveForMetal(updated);
    if (mounted) {
      setState(() {
        _saving = false;
        if (ok) _model = updated;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            ok
                ? '$_metalDisplay purchase settings saved!'
                : 'Save failed. Please try again.',
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

  void _toggle(PurchaseBillingModel Function(PurchaseBillingModel) updater) {
    setState(() => _model = updater(_model));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: BillingSetupColors.bodyBg,
        appBar: BillingSetupAppBar(
          screenTitle: '$_metalEmoji $_metalDisplay Purchase',
          screenSubtitle: 'Loading settings...',
          onBack: () => Navigator.maybePop(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: BillingSetupColors.bodyBg,
      appBar: BillingSetupAppBar(
        screenTitle: '$_metalEmoji $_metalDisplay Purchase',
        screenSubtitle: 'Voucher display · Return policy · Terms',
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
                  // ── SECTION 1: Voucher Item Display ─────────────────────
                  _SectionCard(
                    title: 'Purchase Voucher Display',
                    subtitle:
                        'What appears on each line item of the purchase voucher',
                    icon: Icons.receipt_outlined,
                    accent: _accent,
                    children: _buildDisplayToggles(),
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION 2: Return Policy ─────────────────────────────
                  _SectionCard(
                    title: 'Purchase Return Policy',
                    subtitle: 'Rules for returning purchased items to supplier',
                    icon: Icons.assignment_return_outlined,
                    accent: _accent,
                    children: _buildReturnSection(),
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION 3: Terms & Template ──────────────────────────
                  _SectionCard(
                    title: 'Terms & Template',
                    subtitle:
                        'Printed at the bottom of every $_metalDisplay purchase voucher',
                    icon: Icons.description_outlined,
                    accent: _accent,
                    children: _buildTermsSection(),
                  ),
                  const SizedBox(height: 32),

                  // ── SAVE BUTTON ──────────────────────────────────────────
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
                          : Text(
                              'Save $_metalDisplay Purchase Settings',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

  // ── DISPLAY TOGGLES — per metal ────────────────────────────────────────────
  List<Widget> _buildDisplayToggles() {
    final metal = widget.metal;
    final List<Widget> toggles = [];

    void addToggle(
      String label,
      String subtitle,
      bool value,
      void Function(bool) onChanged,
    ) {
      toggles.add(_ToggleRow(
        label: label,
        subtitle: subtitle,
        value: value,
        accent: _accent,
        onChanged: onChanged,
      ));
    }

    // Common to all metals
    if (metal != BillingMetal.diamond) {
      addToggle(
          'Gross Weight',
          'Total weight before deductions',
          _model.showGrossWeight,
          (v) => _toggle((m) => m.copyWith(showGrossWeight: v)));

      addToggle(
          'Less / Stone Weight',
          'Weight deducted (stone, beading etc.)',
          _model.showLessWeight,
          (v) => _toggle((m) => m.copyWith(showLessWeight: v)));

      addToggle('Net Weight', 'Weight after deductions', _model.showNetWeight,
          (v) => _toggle((m) => m.copyWith(showNetWeight: v)));

      addToggle('Purity / Tunch', 'e.g. 22KT, 925, 950PT', _model.showPurity,
          (v) => _toggle((m) => m.copyWith(showPurity: v)));

      addToggle('Rate (₹/g)', 'Purchase rate per gram', _model.showRate,
          (v) => _toggle((m) => m.copyWith(showRate: v)));

      addToggle(
          'Fine Weight',
          'Calculated: net wt × purity %',
          _model.showFineWeight,
          (v) => _toggle((m) => m.copyWith(showFineWeight: v)));
    }

    // Gold specific
    if (metal == BillingMetal.gold) {
      addToggle(
          'HUID Number',
          'BIS Hallmark HUID — mandatory for gold purchase',
          _model.showHuid,
          (v) => _toggle((m) => m.copyWith(showHuid: v)));
    }

    // Diamond specific
    if (metal == BillingMetal.diamond) {
      addToggle(
          'Diamond Carats',
          'Total diamond weight in carats',
          _model.showDiamondCarats,
          (v) => _toggle((m) => m.copyWith(showDiamondCarats: v)));

      addToggle(
          'Clarity Grade',
          'VVS1, VS1, SI1 etc.',
          _model.showDiamondClarity,
          (v) => _toggle((m) => m.copyWith(showDiamondClarity: v)));

      addToggle(
          'Certification Number',
          'GIA / IGI / HRD certificate no.',
          _model.showCertificationNo,
          (v) => _toggle((m) => m.copyWith(showCertificationNo: v)));

      addToggle('Rate (₹/ct)', 'Purchase rate per carat', _model.showRate,
          (v) => _toggle((m) => m.copyWith(showRate: v)));

      addToggle(
          'Stone Details',
          'Stone type, setting, pieces',
          _model.showStoneDetails,
          (v) => _toggle((m) => m.copyWith(showStoneDetails: v)));

      addToggle(
          'Stone Value',
          'Stone value as separate line',
          _model.showStoneValue,
          (v) => _toggle((m) => m.copyWith(showStoneValue: v)));
    }

    // Non-diamond stone details
    if (metal != BillingMetal.diamond) {
      addToggle(
          'Stone Details',
          'Stone type, carats, pieces',
          _model.showStoneDetails,
          (v) => _toggle((m) => m.copyWith(showStoneDetails: v)));

      addToggle(
          'Stone Value',
          'Stone value as separate line',
          _model.showStoneValue,
          (v) => _toggle((m) => m.copyWith(showStoneValue: v)));
    }

    // Seller details
    addToggle(
        'Supplier / Seller Details',
        'Name, mobile, city on voucher',
        _model.showSupplierDetails,
        (v) => _toggle((m) => m.copyWith(showSupplierDetails: v)));

    addToggle(
        'PAN Number',
        'Required for transactions above ₹2 lakh',
        _model.showPanNumber,
        (v) => _toggle((m) => m.copyWith(showPanNumber: v)));

    // GST
    addToggle(
        'GST Breakup',
        'Show CGST + SGST lines separately',
        _model.showGstBreakup,
        (v) => _toggle((m) => m.copyWith(showGstBreakup: v)));

    addToggle('HSN Code', 'Show HSN code on voucher', _model.showHsnCode,
        (v) => _toggle((m) => m.copyWith(showHsnCode: v)));

    addToggle('Total Value', 'Final total amount', _model.showTotalValue,
        (v) => _toggle((m) => m.copyWith(showTotalValue: v)));

    return toggles;
  }

  // ── RETURN POLICY SECTION ─────────────────────────────────────────────────
  List<Widget> _buildReturnSection() {
    return [
      _InputField(
        label: 'Return Window (Days)',
        hint: 'e.g. 3',
        subtitle: '0 = No return allowed',
        ctrl: _returnWindowCtrl,
        accent: _accent,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      const SizedBox(height: 14),
      _DropdownField(
        label: 'Return Mode',
        value: _model.returnMode,
        items: PurchaseReturnModeOptions.all,
        accent: _accent,
        onChanged: (v) =>
            setState(() => _model = _model.copyWith(returnMode: v)),
      ),
      const SizedBox(height: 14),
      _InputField(
        label: 'Purity Deduction %',
        hint: 'e.g. 2',
        subtitle: 'Deducted for testing/refining loss',
        ctrl: _purityDeductCtrl,
        accent: _accent,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ];
  }

  // ── TERMS & TEMPLATE SECTION ──────────────────────────────────────────────
  List<Widget> _buildTermsSection() {
    return [
      _InputField(
        label: 'Terms & Conditions',
        hint: 'Enter terms printed on $_metalDisplay purchase vouchers...',
        ctrl: _termsCtrl,
        accent: _accent,
        maxLines: 5,
      ),
      const SizedBox(height: 14),
      _InputField(
        label: 'Footer Message',
        hint: 'e.g. Thank you for your supply.',
        ctrl: _footerCtrl,
        accent: _accent,
        maxLines: 2,
      ),
      const SizedBox(height: 14),
      _DropdownField(
        label: 'Print Template',
        value: _model.selectedTemplate,
        items: TemplateOptions.all,
        accent: _accent,
        helperText: 'More templates can be added in future',
        onChanged: (v) =>
            setState(() => _model = _model.copyWith(selectedTemplate: v)),
      ),
    ];
  }
}

// =============================================================================
// HELPERS
// =============================================================================
Color _metalAccent(String metal) {
  switch (metal) {
    case 'gold':
      return const Color(0xFFB8860B);
    case 'silver':
      return const Color(0xFF6B7280);
    case 'diamond':
      return const Color(0xFF0EA5E9);
    case 'platinum':
      return const Color(0xFF7C3AED);
    default:
      return const Color(0xFF6B7280);
  }
}

// =============================================================================
// SHARED WIDGETS (same as Sales screen)
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
            color: Colors.black.withOpacity(0.04),
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
              color: accent.withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
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
                  ),
                ),
              ],
            ),
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

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    )),
                Text(subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accent,
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
            Text('· $subtitle',
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
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827), // ✅ Fixed: dark black text visible
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
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
  final String? helperText;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.accent,
    required this.onChanged,
    this.helperText,
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
          value: items.contains(value) ? value : items.first,
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
            helperText: helperText,
            helperStyle:
                GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
          ),
        ),
      ],
    );
  }
}
