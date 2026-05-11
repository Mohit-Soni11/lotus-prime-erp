// =============================================================================
// FILE        : silver_purity_step.dart
// MODULE      : Stock & Inventory (Silver)
// LAYER       : UI / Step
// DESCRIPTION : Purity selection step for Silver Add Stock.
//               ✅ 100% Isolated — uses only SilverStock theme.
//               ✅ Silver purity presets: 999, 925 (Sterling), 800, 700, Custom.
//               ✅ Side panel shows current silver stock by purity.
//               ✅ "Continue to Item Entry" → unlocks items step.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../logic/stock/add_stock_controller.dart';
import '../../../../theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

class SilverPurityStep extends StatefulWidget {
  final AddStockController ctrl;

  const SilverPurityStep({super.key, required this.ctrl});

  @override
  State<SilverPurityStep> createState() => _SilverPurityStepState();
}

class _SilverPurityStepState extends State<SilverPurityStep>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _customCtrl;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Silver purity presets
  static const List<_SilverPurityOption> _presets = [
    _SilverPurityOption('999 (Pure)', '99.9% Fine Silver', Icons.stars_rounded),
    _SilverPurityOption(
        '925 (Sterling)', '92.5% Sterling', Icons.verified_rounded),
    _SilverPurityOption('800', '80.0% Common Silver', Icons.toll_rounded),
    _SilverPurityOption('700', '70.0% Low Grade', Icons.circle_outlined),
    _SilverPurityOption('Custom', 'Enter custom grade', Icons.edit_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _customCtrl = TextEditingController(
      text: widget.ctrl.isCustomPurity ? widget.ctrl.purityDisplay : '',
    );
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final main = _buildMainPanel();
              final side = _buildSidePanel();

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: main),
                    const SizedBox(width: 18),
                    SizedBox(width: 310, child: side),
                  ],
                );
              }
              return Column(children: [
                main,
                const SizedBox(height: 18),
                side,
              ]);
            },
          ),
        ),
      ),
    );
  }

  // ── MAIN PANEL ────────────────────────────────────────────────
  Widget _buildMainPanel() {
    final ctrl = widget.ctrl;

    return Container(
      decoration:
          SilverStockStyles.cardWithAccent(SilverStockColors.brandSilver),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── GRADIENT BANNER ─────────────────────────────────
          _buildGradientBanner(),
          const SizedBox(height: 24),

          // ── TITLE ────────────────────────────────────────────
          Text(
            'Purity / Grade Selection',
            style: SilverStockStyles.pageTitle,
          ),
          const SizedBox(height: 6),
          Text(
            'Select the base purity for this silver batch. '
            'All items in this session will inherit this purity grade. '
            'This setting is locked once you proceed to item entry.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.6,
              color: SilverStockColors.textBody,
            ),
          ),
          const SizedBox(height: 24),

          // ── PURITY CHIPS ─────────────────────────────────────
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _presets.map((preset) {
              final isCustom = preset.value == 'Custom';
              final isSelected = isCustom
                  ? ctrl.isCustomPurity
                  : ctrl.purityDisplay == preset.value;

              return _PurityChip(
                preset: preset,
                isSelected: isSelected,
                onTap: () {
                  ctrl.setPurity(preset.value);
                  if (isCustom) {
                    // Clear custom text when switching to custom
                    _customCtrl.clear();
                  }
                  setState(() {});
                },
              );
            }).toList(),
          ),

          // ── CUSTOM INPUT ─────────────────────────────────────
          if (ctrl.isCustomPurity) ...[
            const SizedBox(height: 20),
            Text(
              SilverStockStrings.purityCustomLabel,
              style: SilverStockStyles.inputLabel,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customCtrl,
              onChanged: ctrl.setCustomPurity,
              style: SilverStockStyles.inputText,
              decoration: InputDecoration(
                hintText: SilverStockStrings.purityCustomHint,
                hintStyle: SilverStockStyles.fieldHint,
                prefixIcon: const Icon(
                  Icons.tune_rounded,
                  color: SilverStockColors.brandSilver,
                  size: 18,
                ),
                filled: true,
                fillColor: SilverStockColors.inputBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: SilverStockColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: SilverStockColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: SilverStockColors.brandSilver, width: 1.5),
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // ── CONTINUE BUTTON ──────────────────────────────────
          ListenableBuilder(
            listenable: ctrl,
            builder: (_, __) => SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: ctrl.canProceedFromPurity ? ctrl.nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SilverStockColors.brandSilver,
                  disabledBackgroundColor: SilverStockColors.inputBgLocked,
                  foregroundColor: Colors.white,
                  elevation: ctrl.canProceedFromPurity ? 2 : 0,
                  shadowColor: SilverStockColors.brandSilver.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white),
                label: Text(
                  SilverStockStrings.btnNextItems,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Hint if nothing selected
          ListenableBuilder(
            listenable: ctrl,
            builder: (_, __) {
              if (ctrl.canProceedFromPurity) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Please select a purity grade above to continue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: SilverStockColors.textMuted,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── GRADIENT BANNER ──────────────────────────────────────────
  Widget _buildGradientBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDDE7ED), Color(0xFF8BA1AF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Logo / Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2F3A).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'lib/logo/silver and platinum .jpeg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.toll_rounded,
                color: Color(0xFF1A2F3A),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Silver — Stock Intake',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2F3A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sterling presets, higher quantity entry and clean racks',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: const Color(0xFF1A2F3A).withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
          // Quick tag badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2F3A).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '999 · 925 · 800',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A2F3A),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SIDE PANEL ────────────────────────────────────────────────
  Widget _buildSidePanel() {
    final ctrl = widget.ctrl;

    return Container(
      decoration: SilverStockStyles.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: SilverStockColors.brandSilver.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_rounded,
                  size: 15, color: SilverStockColors.brandSilver),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Current Stock by Purity',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: SilverStockColors.textDark,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            'Available Silver inventory, grouped by purity grade.',
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.5,
              color: SilverStockColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),

          // Stock list
          ListenableBuilder(
            listenable: ctrl,
            builder: (_, __) {
              if (ctrl.isLoadingStockSummary) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SilverStockColors.brandSilver,
                      ),
                    ),
                  ),
                );
              }

              if (ctrl.purityStockSummary.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SilverStockColors.brandSilverLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: SilverStockColors.brandSilver.withOpacity(0.18)),
                  ),
                  child: Column(children: [
                    Icon(Icons.inventory_outlined,
                        size: 28,
                        color: SilverStockColors.brandSilver.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'No Silver stock on record.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SilverStockColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Items added in this batch will appear here on your next session.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        height: 1.5,
                        color: SilverStockColors.textHint,
                      ),
                    ),
                  ]),
                );
              }

              return Column(
                children: ctrl.purityStockSummary.entries.map((e) {
                  return _PurityStockRow(purity: e.key, grams: e.value);
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: SilverStockColors.borderLight),
          const SizedBox(height: 16),

          // Guidelines
          Text(
            'Batch Guidelines',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SilverStockColors.brandSilver,
            ),
          ),
          const SizedBox(height: 10),
          _guideline(
              'Purity is locked at batch level — select carefully before proceeding.'),
          _guideline(
              'Each item row supports individual HUID, company name and quantity.'),
          _guideline(
              'Use "Same supplier for all" to pre-fill supplier across every row.'),
        ],
      ),
    );
  }

  Widget _guideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SilverStockColors.brandSilver,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.5,
                    color: SilverStockColors.textBody)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PURITY CHIP WIDGET
// ════════════════════════════════════════════════════════════════════════════
class _PurityChip extends StatelessWidget {
  final _SilverPurityOption preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PurityChip({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: SilverStockColors.brandSilver.withOpacity(0.12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? SilverStockColors.brandSilver.withOpacity(0.11)
              : SilverStockColors.inputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? SilverStockColors.brandSilver
                : SilverStockColors.borderLight,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SilverStockColors.brandSilver.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            preset.icon,
            size: 16,
            color: isSelected
                ? SilverStockColors.brandSilver
                : SilverStockColors.textMuted,
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              preset.value,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? SilverStockColors.brandSilver
                    : SilverStockColors.textDark,
              ),
            ),
            Text(
              preset.subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isSelected
                    ? SilverStockColors.brandSilver.withOpacity(0.75)
                    : SilverStockColors.textMuted,
              ),
            ),
          ]),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_rounded,
                size: 16, color: SilverStockColors.brandSilver),
          ],
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PURITY STOCK ROW
// ════════════════════════════════════════════════════════════════════════════
class _PurityStockRow extends StatelessWidget {
  final String purity;
  final double grams;

  const _PurityStockRow({required this.purity, required this.grams});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SilverStockColors.brandSilverLight,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: SilverStockColors.brandSilver.withOpacity(0.18)),
      ),
      child: Row(children: [
        Expanded(
          child: Text(purity,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SilverStockColors.textDark)),
        ),
        Text(
          '${grams.toStringAsFixed(3)} g',
          style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: SilverStockColors.brandSilver),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DATA CLASS
// ════════════════════════════════════════════════════════════════════════════
class _SilverPurityOption {
  final String value;
  final String subtitle;
  final IconData icon;

  const _SilverPurityOption(this.value, this.subtitle, this.icon);
}
