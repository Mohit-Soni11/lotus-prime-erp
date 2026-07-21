// =============================================================================
// FILE        : lib/ui/settings/metal_costing/metal_costing_hub_screen.dart
// MODULE      : Metal Costing Analysis
// LAYER       : UI / Presentation
// DESCRIPTION : Level 1 â€” Metal cards (Gold, Silver, Platinum, Diamond).
//               Stock DB se dynamically purity count + profit show karta hai.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/settings/metal_costing/metal_costing_theme.dart';
import '../../../logic/setting/metal_costing/metal_costing_controller.dart';
import '../../../models/setting/metal_costing/metal_costing_model.dart';
import 'metal_cost_analyser_screen.dart';
import 'metal_costing_app_bar.dart';
import 'metal_costing_purity_screen.dart';

// â”€â”€ Metal meta for display â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MetalMeta {
  final String key;
  final String label;
  final IconData icon;
  final Color accent;
  final Color cardBg;

  const _MetalMeta({
    required this.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.cardBg,
  });
}

const List<_MetalMeta> _metals = [
  _MetalMeta(
    key: 'Gold',
    label: 'Gold',
    icon: MetalCostingIcons.goldIcon,
    accent: MetalCostingColors.goldBrand,
    cardBg: MetalCostingColors.goldCard,
  ),
  _MetalMeta(
    key: 'Silver',
    label: 'Silver',
    icon: MetalCostingIcons.silverIcon,
    accent: MetalCostingColors.silverBrand,
    cardBg: MetalCostingColors.silverCard,
  ),
  _MetalMeta(
    key: 'Platinum',
    label: 'Platinum',
    icon: MetalCostingIcons.platinumIcon,
    accent: MetalCostingColors.platinumBrand,
    cardBg: MetalCostingColors.platinumCard,
  ),
  _MetalMeta(
    key: 'Diamond',
    label: 'Diamond',
    icon: MetalCostingIcons.diamondIcon,
    accent: MetalCostingColors.diamondBrand,
    cardBg: MetalCostingColors.diamondCard,
  ),
];

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// HUB SCREEN
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class MetalCostingHubScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const MetalCostingHubScreen({super.key, this.onBack});

  @override
  State<MetalCostingHubScreen> createState() => _MetalCostingHubScreenState();
}

class _MetalCostingHubScreenState extends State<MetalCostingHubScreen> {
  late MetalCostingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = MetalCostingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmtAmount(double v) =>
      'â‚¹${v.abs().toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{2})+\d$)'),
            (m) => '${m[1]},',
          )}';

  void _navigate(BuildContext context, _MetalMeta meta, MetalSummary? summary) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => MetalCostingPurityScreen(
          metalMeta: meta,
          summary: summary,
          controller: _ctrl,
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  void _openCostAudit(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => MetalCostAnalyserScreen(
          onBack: () => Navigator.maybePop(context),
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
    return Scaffold(
      backgroundColor: MetalCostingColors.bodyBg,
      appBar: MetalCostingAppBar(
        screenTitle: MetalCostingStrings.hubTitle,
        screenSubtitle: MetalCostingStrings.hubSub,
        onBack: widget.onBack ?? () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _ctrl.refresh,
          color: MetalCostingColors.brandGold,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              if (_ctrl.state == MetalCostingState.loading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: MetalCostingColors.brandGold,
                  ),
                );
              }
              if (_ctrl.state == MetalCostingState.error) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(MetalCostingIcons.warningIcon,
                          color: MetalCostingColors.danger, size: 40),
                      const SizedBox(height: 12),
                      Text('Error loading data',
                          style: MetalCostingStyles.cardTitle),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _ctrl.refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: MetalCostingStyles.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      MetalCostingStrings.selectMetal,
                      style: MetalCostingStyles.sectionLabel,
                    ),
                    const SizedBox(height: 16),
                    _buildGrid(context),
                    const SizedBox(height: 24),
                    _ValuationActionCard(
                      onTap: () => _openCostAudit(context),
                    ),
                    const SizedBox(height: 24),
                    _buildInfoBanner(),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            children: _metals.map((meta) {
              final summary = _ctrl.getSummaryByMetal(meta.key);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _MetalCard(
                    meta: meta,
                    summary: summary,
                    fmtAmount: _fmtAmount,
                    onTap: () => _navigate(context, meta, summary),
                  ),
                ),
              );
            }).toList(),
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _metals.map((meta) {
            final summary = _ctrl.getSummaryByMetal(meta.key);
            return _MetalCard(
              meta: meta,
              summary: summary,
              fmtAmount: _fmtAmount,
              onTap: () => _navigate(context, meta, summary),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MetalCostingColors.goldBrand.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(MetalCostingStyles.rCard),
        border: Border.all(
          color: MetalCostingColors.goldBrand.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(MetalCostingIcons.infoIcon,
              size: 18, color: MetalCostingColors.goldBrand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              MetalCostingStrings.infoText,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: MetalCostingColors.textBody,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// METAL CARD (animated hover â€” exact BillingSetup HubCard pattern)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _MetalCard extends StatefulWidget {
  final _MetalMeta meta;
  final MetalSummary? summary;
  final String Function(double) fmtAmount;
  final VoidCallback onTap;

  const _MetalCard({
    required this.meta,
    required this.summary,
    required this.fmtAmount,
    required this.onTap,
  });

  @override
  State<_MetalCard> createState() => _MetalCardState();
}

class _MetalCardState extends State<_MetalCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _arrow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.025)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _arrow = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onEnter(_) {
    setState(() => _hovered = true);
    _ctrl.forward();
  }

  void _onExit(_) {
    setState(() => _hovered = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.meta.accent;
    final summary = widget.summary;
    final total = summary?.totalProfit1 ?? 0.0;
    final pCount = summary?.purities.length ?? 0;
    final iCount = summary?.allItems.length ?? 0;

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: MetalCostingStyles.metalCard(
              accent: color,
              hovered: _hovered,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // â”€â”€ Top: icon + purity count badge â”€â”€
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: _hovered ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                color.withValues(alpha: _hovered ? 0.4 : 0.2)),
                      ),
                      child: Icon(widget.meta.icon, size: 22, color: color),
                    ),
                    if (pCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '$pCount purity',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // â”€â”€ Bottom: name + profit + analyse arrow â”€â”€
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _hovered ? color : MetalCostingColors.textDark,
                      ),
                      child: Text(widget.meta.label),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      iCount > 0
                          ? '$iCount items Â· ${widget.fmtAmount(total)} profit'
                          : 'No items in stock',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: MetalCostingColors.textMuted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _arrow,
                      builder: (_, __) => Row(
                        children: [
                          Opacity(
                            opacity: 0.4 + (_arrow.value * 0.6),
                            child: Text(
                              MetalCostingStrings.configure,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.translate(
                            offset: Offset((-1 + _arrow.value) * 4, 0),
                            child: Icon(
                              MetalCostingIcons.navArrow,
                              size: 11,
                              color: color,
                            ),
                          ),
                        ],
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

class _ValuationActionCard extends StatefulWidget {
  final VoidCallback onTap;

  const _ValuationActionCard({required this.onTap});

  @override
  State<_ValuationActionCard> createState() => _ValuationActionCardState();
}

class _ValuationActionCardState extends State<_ValuationActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const accent = MetalCostingColors.goldBrand;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: MetalCostingStyles.metalCard(
            accent: accent,
            hovered: _hovered,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: _hovered ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: _hovered ? 0.45 : 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.price_check_rounded,
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Cost Audit',
                      style: MetalCostingStyles.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available stock cost, valuation fine and sold profit audit.',
                      style: MetalCostingStyles.cardSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: _hovered ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      MetalCostingIcons.navArrow,
                      color: accent,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Export _MetalMeta so purity screen can use it
typedef MetalCardMeta = _MetalMeta;
