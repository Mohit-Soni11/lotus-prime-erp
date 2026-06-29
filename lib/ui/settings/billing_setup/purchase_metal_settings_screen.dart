// =============================================================================
// FILE        : lib/ui/settings/billing_setup/purchase/purchase_metal_settings_screen.dart
// MODULE      : Billing Setup â†’ Purchase
// DESCRIPTION : Settings screen for one metal â€” purchase side.
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
import 'package:lotus_erp/core/feedback/app_feedback.dart';

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
  final _returnPolicyCtrl = TextEditingController();
  final _buybackPolicyCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();

  Color get _accent => _metalAccent(widget.metal);
  String get _metalDisplay => BillingMetal.displayName(widget.metal);
  String get _metalLogoAsset => _metalLogoFor(widget.metal);

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
    _returnPolicyCtrl.dispose();
    _buybackPolicyCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final model = await _repo.fetchForMetal(widget.metal);
    _model = model;
    _returnWindowCtrl.text = model.returnWindowDays.toString();
    _purityDeductCtrl.text = model.purityDeductPercent.toString();
    _termsCtrl.text = model.termsAndConditions;
    _returnPolicyCtrl.text = model.returnPolicyText;
    _buybackPolicyCtrl.text = model.buybackPolicyText;
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
      returnPolicyText: _returnPolicyCtrl.text.trim(),
      buybackPolicyText: _buybackPolicyCtrl.text.trim(),
      footerMessage: _footerCtrl.text.trim(),
    );
    final ok = await _repo.saveForMetal(updated);
    if (mounted) {
      setState(() {
        _saving = false;
        if (ok) _model = updated;
      });
      AppFeedback.show(
        context,
        type: ok ? AppFeedbackType.success : AppFeedbackType.error,
        message: ok
            ? '$_metalDisplay purchase settings saved!'
            : 'Save failed. Please try again.',
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _toggle(PurchaseBillingModel Function(PurchaseBillingModel) updater) {
    setState(() => _model = updater(_model));
  }

  int get _enabledDisplayCount {
    final values = [
      _model.showGrossWeight,
      _model.showLessWeight,
      _model.showNetWeight,
      _model.showPurity,
      _model.showRate,
      _model.showFineWeight,
      _model.showTotalValue,
      _model.showStoneDetails,
      _model.showStoneValue,
      _model.showHuid,
      _model.showSupplierDetails,
      _model.showPanNumber,
      _model.showDiamondCarats,
      _model.showDiamondClarity,
      _model.showCertificationNo,
      _model.showGstBreakup,
      _model.showHsnCode,
    ];
    return values.where((value) => value).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: BillingSetupColors.bodyBg,
        appBar: BillingSetupAppBar(
          screenTitle: '$_metalDisplay Purchase',
          screenSubtitle: 'Loading settings...',
          onBack: () => Navigator.maybePop(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: BillingSetupColors.bodyBg,
      appBar: BillingSetupAppBar(
        screenTitle: '$_metalDisplay Purchase',
        screenSubtitle: 'Voucher display, supplier returns and footer copy',
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
                  _MetalIntroPanel(
                    metalName: _metalDisplay,
                    logoAsset: _metalLogoAsset,
                    accent: _accent,
                    enabledCount: _enabledDisplayCount,
                    returnMode: _model.returnMode,
                  ),
                  const SizedBox(height: 18),
                  // â”€â”€ SECTION 1: Voucher Item Display â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _SectionCard(
                    title: 'Purchase Voucher Display',
                    subtitle: 'Choose the fields printed on each purchase row',
                    icon: Icons.receipt_outlined,
                    accent: _accent,
                    children: [
                      _ToggleGrid(children: _buildDisplayToggles()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // â”€â”€ SECTION 2: Return Policy â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _SectionCard(
                    title: 'Return & Buyback Policy',
                    subtitle:
                        'Supplier return rules, purity deductions and notes',
                    icon: Icons.assignment_return_outlined,
                    accent: _accent,
                    children: _buildReturnSection(),
                  ),
                  const SizedBox(height: 20),

                  // â”€â”€ SECTION 3: Terms & Template â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  _SectionCard(
                    title: 'Terms & Conditions',
                    subtitle:
                        'Footer copy printed on every $_metalDisplay purchase voucher',
                    icon: Icons.article_outlined,
                    accent: _accent,
                    children: _buildTermsSection(),
                  ),
                  const SizedBox(height: 32),

                  // â”€â”€ SAVE BUTTON â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ DISPLAY TOGGLES â€” per metal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

      addToggle('Rate (Rs/g)', 'Purchase rate per gram', _model.showRate,
          (v) => _toggle((m) => m.copyWith(showRate: v)));

      addToggle(
          'Fine Weight',
          'Calculated from net weight and purity',
          _model.showFineWeight,
          (v) => _toggle((m) => m.copyWith(showFineWeight: v)));
    }

    // Gold specific
    if (metal == BillingMetal.gold) {
      addToggle('HUID Number', 'BIS Hallmark HUID for compliant gold purchase',
          _model.showHuid, (v) => _toggle((m) => m.copyWith(showHuid: v)));
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

      addToggle('Rate (Rs/ct)', 'Purchase rate per carat', _model.showRate,
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
        'Required for transactions above Rs 2 lakh',
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

  // â”€â”€ RETURN POLICY SECTION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      const SizedBox(height: 14),
      _responsiveFieldPair(
        first: _InputField(
          label: 'Return Policy Note',
          hint:
              'e.g. Supplier returns accepted within the selected window after quality check.',
          subtitle: 'Supplier-facing return note',
          ctrl: _returnPolicyCtrl,
          accent: _accent,
          maxLines: 4,
        ),
        second: _InputField(
          label: 'Buyback Policy Note',
          hint:
              'e.g. Buyback settlement depends on purity, rate agreement and inspection.',
          subtitle: 'Purchase buyback terms',
          ctrl: _buybackPolicyCtrl,
          accent: _accent,
          maxLines: 4,
        ),
      ),
    ];
  }

  Widget _responsiveFieldPair({
    required Widget first,
    required Widget second,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            children: [
              first,
              const SizedBox(height: 14),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  // â”€â”€ TERMS & TEMPLATE SECTION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

String _metalLogoFor(String metal) {
  switch (metal) {
    case BillingMetal.gold:
      return 'lib/logo/gold.jpeg';
    case BillingMetal.silver:
      return 'lib/logo/silver and platinum .jpeg';
    case BillingMetal.diamond:
      return 'lib/logo/diamond .jpeg';
    case BillingMetal.platinum:
      return 'lib/logo/silver and platinum .jpeg';
    default:
      return 'lib/logo/gold.jpeg';
  }
}

// =============================================================================
// SHARED WIDGETS (same as Sales screen)
// =============================================================================

class _MetalIntroPanel extends StatelessWidget {
  final String metalName;
  final String logoAsset;
  final Color accent;
  final int enabledCount;
  final String returnMode;

  const _MetalIntroPanel({
    required this.metalName,
    required this.logoAsset,
    required this.accent,
    required this.enabledCount,
    required this.returnMode,
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
          final isCompact = constraints.maxWidth < 680;
          final titleBlock = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: accent.withValues(alpha: 0.10),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: accent,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$metalName purchase controls',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fine tune voucher fields, supplier return rules and purchase footer copy.',
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
                label: '$enabledCount active fields',
                icon: Icons.check_circle_rounded,
                accent: accent,
              ),
              _SummaryPill(
                label: returnMode,
                icon: Icons.assignment_return_rounded,
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

class _ToggleGrid extends StatelessWidget {
  final List<Widget> children;

  const _ToggleGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820
            ? 3
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        const gap = 12.0;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
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
            child: Row(
              children: [
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
                          ))
                    ],
                  ),
                ),
              ],
            ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? accent.withValues(alpha: 0.07) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              value ? accent.withValues(alpha: 0.24) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    )),
              ),
              Transform.scale(
                scale: 0.82,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: accent,
                  inactiveThumbColor: const Color(0xFF9CA3AF),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.3,
                color: const Color(0xFF6B7280),
              )),
          const SizedBox(height: 10),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: value ? accent : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
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
        Row(
          children: [
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
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            )),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : items.first,
          dropdownColor: Colors.white,
          iconEnabledColor: const Color(0xFF374151),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        )),
                  ))
              .toList(),
          onChanged: onChanged,
          style:
              GoogleFonts.inter(fontSize: 15, color: const Color(0xFF111827)),
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
