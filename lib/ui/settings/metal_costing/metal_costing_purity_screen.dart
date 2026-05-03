// =============================================================================
// FILE        : lib/ui/settings/metal_costing/metal_costing_purity_screen.dart
// MODULE      : Metal Costing Analysis
// LAYER       : UI / Presentation
// DESCRIPTION : Level 2 — Purity cards (18K, 22K, 24K etc.) for one metal.
//               Stock DB se dynamically banata hai jo bhi purity stock mein hai.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/settings/metal_costing/metal_costing_theme.dart';
import '../../../logic/setting/metal_costing/metal_costing_controller.dart';
import '../../../models/setting/metal_costing/metal_costing_model.dart';
import 'metal_costing_app_bar.dart';
import 'metal_costing_hub_screen.dart';
import 'metal_costing_item_screen.dart';

class MetalCostingPurityScreen extends StatelessWidget {
  final MetalCardMeta metalMeta;
  final MetalSummary? summary;
  final MetalCostingController controller;

  const MetalCostingPurityScreen({
    super.key,
    required this.metalMeta,
    required this.summary,
    required this.controller,
  });

  String _fmt(double v) => '₹${v.abs().toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+\d$)'),
        (m) => '${m[1]},',
      )}';

  void _navigate(BuildContext context, PuritySummary ps) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => MetalCostingItemScreen(
          metalMeta: metalMeta,
          puritySummary: ps,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purities = summary?.purities ?? [];

    return Scaffold(
      backgroundColor: MetalCostingColors.bodyBg,
      appBar: MetalCostingAppBar(
        screenTitle: '${metalMeta.label.toUpperCase()} ANALYSIS',
        screenSubtitle: 'Purity wise breakdown',
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: MetalCostingStyles.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              Text(
                '${metalMeta.label.toUpperCase()} — PURITY WISE ANALYSIS',
                style: MetalCostingStyles.sectionLabel,
              ),
              const SizedBox(height: 16),
              if (purities.isEmpty)
                _EmptyState(metalName: metalMeta.label)
              else
                ...purities.map((ps) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PurityCard(
                        ps: ps,
                        accent: metalMeta.accent,
                        cardBg: metalMeta.cardBg,
                        fmt: _fmt,
                        onTap: () => _navigate(context, ps),
                      ),
                    )),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String metalName;
  const _EmptyState({required this.metalName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            Icon(MetalCostingIcons.itemCount,
                size: 48, color: MetalCostingColors.textHint),
            const SizedBox(height: 16),
            Text(
              'No $metalName items in stock',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MetalCostingColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add stock items to see analysis here',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: MetalCostingColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PURITY CARD
// ═════════════════════════════════════════════════════════════════════════════
class _PurityCard extends StatefulWidget {
  final PuritySummary ps;
  final Color accent;
  final Color cardBg;
  final String Function(double) fmt;
  final VoidCallback onTap;

  const _PurityCard({
    required this.ps,
    required this.accent,
    required this.cardBg,
    required this.fmt,
    required this.onTap,
  });

  @override
  State<_PurityCard> createState() => _PurityCardState();
}

class _PurityCardState extends State<_PurityCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.02)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ps = widget.ps;
    final accent = widget.accent;
    final profit = ps.totalProfit1;
    final isPos = profit >= 0;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: MetalCostingColors.cardBg,
              borderRadius: BorderRadius.circular(MetalCostingStyles.rCard),
              border: Border.all(
                color: _hovered
                    ? accent.withOpacity(0.6)
                    : MetalCostingColors.cardBorder,
                width: _hovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? accent.withOpacity(0.12)
                      : MetalCostingColors.shadowLight,
                  blurRadius: _hovered ? 18 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(MetalCostingIcons.purityIcon,
                              size: 18, color: accent),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 150),
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _hovered
                                    ? accent
                                    : MetalCostingColors.textDark,
                              ),
                              child: Text(ps.purity),
                            ),
                            Text(
                              '${ps.items.length} items · '
                              '${ps.soldItems.length} ${MetalCostingStrings.soldItems} · '
                              '${ps.inStockItems.length} ${MetalCostingStrings.inStock}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: MetalCostingColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        MetalCostingStrings.viewItems,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Stats row ──
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: MetalCostingStrings.profitSold,
                        value: ps.soldItems.isEmpty
                            ? '—'
                            : '${isPos ? "+" : "−"}${widget.fmt(profit)}',
                        valueColor: ps.soldItems.isEmpty
                            ? MetalCostingColors.textMuted
                            : isPos
                                ? MetalCostingColors.profitGreen
                                : MetalCostingColors.lossRed,
                        bg: ps.soldItems.isEmpty
                            ? MetalCostingColors.inputBg
                            : isPos
                                ? MetalCostingColors.profitGreenBg
                                : MetalCostingColors.lossRedBg,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: MetalCostingStrings.stockValue,
                        value: ps.inStockItems.isEmpty
                            ? '—'
                            : widget.fmt(ps.totalStockValue),
                        valueColor: MetalCostingColors.textDark,
                        bg: MetalCostingColors.inputBg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat Box ──────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color bg;

  const _StatBox({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MetalCostingStyles.rInner),
        border: Border.all(color: MetalCostingColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: MetalCostingColors.textHint,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
