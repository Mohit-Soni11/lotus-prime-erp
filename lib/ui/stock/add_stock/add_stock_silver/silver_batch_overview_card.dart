// =============================================================================
// FILE        : silver_batch_overview_card.dart
// MODULE      : Stock & Inventory — Silver
// LAYER       : UI / Component
// DESCRIPTION : Compact Batch Overview card for Silver Add Stock (Step 2).
//               ✅ Animated GST / NORMAL toggle pill.
//               ✅ Live reactive stats via ListenableBuilder.
//               ✅ Shows purity, pieces, gross / net weight only.
//               ✅ Colorful semantic icons from SilverStockColors accent palette.
//               ✅ 100% Silver-themed — zero Gold/POS color imports.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../logic/stock/add_stock_silver/silver_stock_controller.dart';
import '../../../../theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

class SilverBatchOverviewCard extends StatefulWidget {
  final SilverStockController ctrl;

  const SilverBatchOverviewCard({super.key, required this.ctrl});

  @override
  State<SilverBatchOverviewCard> createState() =>
      _SilverBatchOverviewCardState();
}

class _SilverBatchOverviewCardState extends State<SilverBatchOverviewCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    Future.microtask(() {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ListenableBuilder(
          listenable: widget.ctrl,
          builder: (_, __) => _buildCard(),
        ),
      ),
    );
  }

  // ── MAIN CARD ────────────────────────────────────────────────
  Widget _buildCard() {
    final ctrl = widget.ctrl;
    final isGst = ctrl.gstEnabled;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SilverStockColors.panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SilverStockColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: SilverStockColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderRow(isGst, ctrl),
          const SizedBox(height: 14),
          _buildGradientDivider(isGst),
          const SizedBox(height: 14),
          _buildIdentityRow(ctrl),
          const SizedBox(height: 16),
          _buildStatsGrid(ctrl),
        ],
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────
  Widget _buildHeaderRow(bool isGst, SilverStockController ctrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon badge — purple (inventory accent)
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: SilverStockColors.accentInventory.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: SilverStockColors.accentInventory.withOpacity(0.25),
            ),
          ),
          child: const Icon(
            SilverStockIcons.inventory,
            size: 17,
            color: SilverStockColors.accentInventory,
          ),
        ),
        const SizedBox(width: 12),

        // Title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                SilverStockStrings.batchOverview,
                style: SilverStockStyles.panelHeader,
              ),
              const SizedBox(height: 2),
              Text(
                SilverStockStrings.batchInsights,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: SilverStockColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // GST / NORMAL toggle pill
        _GstNormalToggle(
          isGst: isGst,
          onToggle: (value) => ctrl.toggleGst(value),
        ),
      ],
    );
  }

  // ── GRADIENT DIVIDER ─────────────────────────────────────────
  Widget _buildGradientDivider(bool isGst) {
    final accentColor =
        isGst ? SilverStockColors.success : SilverStockColors.brandSilver;
    return Container(
      height: 1.5,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.55),
            accentColor.withOpacity(0.18),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // ── IDENTITY ROW ─────────────────────────────────────────────
  Widget _buildIdentityRow(SilverStockController ctrl) {
    final purity = ctrl.purityDisplay.trim().isEmpty
        ? 'Purity Not Set'
        : ctrl.purityDisplay;

    return Row(
      children: [
        // Silver circle orb
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFDDE7ED), SilverStockColors.brandSilver],
            ),
            boxShadow: [
              BoxShadow(
                color: SilverStockColors.brandSilver.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.water_drop_rounded,
              size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),

        Text(
          'Silver',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: SilverStockColors.textDark,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SilverStockColors.textMuted,
            ),
          ),
        ),

        // Purity badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: SilverStockColors.brandSilver.withOpacity(0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SilverStockColors.brandSilver.withOpacity(0.28),
            ),
          ),
          child: Text(
            purity,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: SilverStockColors.brandSilver,
              letterSpacing: 0.3,
            ),
          ),
        ),

        const Spacer(),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: SilverStockColors.inputBgLocked,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SilverStockColors.borderLight),
          ),
          child: Text(
            '1 Batch',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SilverStockColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  // ── STATS GRID — 3 tiles only (Est Cost & Est Sale removed) ──
  Widget _buildStatsGrid(SilverStockController ctrl) {
    final stats = [
      _StatTile(
        label: SilverStockStrings.overviewPieces,
        value: ctrl.totalQuantity.toString(),
        icon: SilverStockIcons.quantity,
        iconColor: SilverStockColors.accentInventory, // Purple
      ),
      _StatTile(
        label: SilverStockStrings.overviewGross,
        value: '${ctrl.totalGrossWeight.toStringAsFixed(3)} g',
        icon: SilverStockIcons.weight,
        iconColor: SilverStockColors.accentMetal, // Steel blue
      ),
      _StatTile(
        label: SilverStockStrings.overviewNet,
        value: '${ctrl.totalNetWeight.toStringAsFixed(3)} g',
        icon: SilverStockIcons.netWeight,
        iconColor: SilverStockColors.accentMetal, // Steel blue
      ),
    ];

    return Row(
      children: [
        Expanded(child: stats[0]),
        const SizedBox(width: 8),
        Expanded(child: stats[1]),
        const SizedBox(width: 8),
        Expanded(child: stats[2]),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// GST / NORMAL ANIMATED TOGGLE PILL
// ════════════════════════════════════════════════════════════════
class _GstNormalToggle extends StatelessWidget {
  final bool isGst;
  final ValueChanged<bool> onToggle;

  const _GstNormalToggle({required this.isGst, required this.onToggle});

  Color get _accentColor =>
      isGst ? SilverStockColors.success : SilverStockColors.brandSilver;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isGst),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isGst
              ? SilverStockColors.success.withOpacity(0.07)
              : SilverStockColors.brandSilver.withOpacity(0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _accentColor.withOpacity(0.36),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentColor,
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.45),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
                color: _accentColor,
              ),
              child: Text(isGst ? 'GST BILL' : 'NORMAL'),
            ),
            const SizedBox(width: 7),
            Icon(Icons.swap_horiz_rounded,
                size: 14, color: _accentColor.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// STAT TILE — individual compact stat cell
// ════════════════════════════════════════════════════════════════
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor; // Specific semantic color per tile

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SilverStockColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SilverStockColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Colored icon mini-badge
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: SilverStockColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: SilverStockColors.textDark,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
