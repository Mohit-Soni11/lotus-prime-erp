// =============================================================================
// FILE        : lib/ui/settings/billing_setup/billing_setup_hub_screen.dart
// MODULE      : Billing Setup
// DESCRIPTION : Hub screen — 2 cards only: Sales & Purchase.
//               Each navigates to its Metal Hub (4 metal cards inside).
// REPLACES    : Old 4-card hub (Sales, Purchase, Girvi, Return)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/settings/billing_setup/billing_setup_theme.dart';
import 'billing_setup_app_bar.dart';
import 'sales_metal_hub.dart';
import 'purchase_metal_hub.dart';

class BillingSetupHubScreen extends StatelessWidget {
  const BillingSetupHubScreen({super.key});

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => screen,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 240),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BillingSetupColors.bodyBg,
      appBar: BillingSetupAppBar(
        screenTitle: 'Billing Setup',
        screenSubtitle: 'Configure invoice rules per metal type',
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT MODULE',
                style: BillingSetupStyles.sectionLabel,
              ),
              const SizedBox(height: 16),
              // ── Two cards side by side ────────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(
                          child: _ModuleCard(
                            icon: Icons.point_of_sale_rounded,
                            title: 'Sales Billing',
                            subtitle:
                                'Invoice display, return policy & terms\nper metal type',
                            accent: BillingSetupColors.salesBrand,
                            tag: 'Gold · Silver · Diamond · Platinum',
                            onTap: () =>
                                _navigate(context, const SalesMetalHubScreen()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ModuleCard(
                            icon: Icons.shopping_bag_outlined,
                            title: 'Purchase Billing',
                            subtitle:
                                'Voucher display, return policy & terms\nper metal type',
                            accent: BillingSetupColors.purchaseBrand,
                            tag: 'Gold · Silver · Diamond · Platinum',
                            onTap: () => _navigate(
                                context, const PurchaseMetalHubScreen()),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _ModuleCard(
                        icon: Icons.point_of_sale_rounded,
                        title: 'Sales Billing',
                        subtitle:
                            'Invoice display, return policy & terms per metal type',
                        accent: BillingSetupColors.salesBrand,
                        tag: 'Gold · Silver · Diamond · Platinum',
                        onTap: () =>
                            _navigate(context, const SalesMetalHubScreen()),
                      ),
                      const SizedBox(height: 16),
                      _ModuleCard(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Purchase Billing',
                        subtitle:
                            'Voucher display, return policy & terms per metal type',
                        accent: BillingSetupColors.purchaseBrand,
                        tag: 'Gold · Silver · Diamond · Platinum',
                        onTap: () =>
                            _navigate(context, const PurchaseMetalHubScreen()),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              // ── Info banner ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BillingSetupColors.salesBrand.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: BillingSetupColors.salesBrand.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: BillingSetupColors.salesBrand),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Each metal type has its own invoice display rules, '
                        'return policy and terms. Changes apply to new bills only.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: BillingSetupColors.textBody,
                          height: 1.5,
                        ),
                      ),
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

// =============================================================================
// MODULE CARD
// =============================================================================
class _ModuleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String tag;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.tag,
    required this.onTap,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160));
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
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovered
                    ? widget.accent.withOpacity(0.5)
                    : Colors.grey.shade200,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? widget.accent.withOpacity(0.12)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: _hovered ? 20 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon ─────────────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(_hovered ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, size: 24, color: widget.accent),
                ),
                const SizedBox(height: 16),
                // ── Title ─────────────────────────────────────────────────
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color:
                        _hovered ? widget.accent : BillingSetupColors.textDark,
                  ),
                  child: Text(widget.title),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: BillingSetupColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                // ── Metal tag ─────────────────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: widget.accent.withOpacity(0.2)),
                  ),
                  child: Text(
                    widget.tag,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: widget.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // ── Configure arrow ───────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'Configure',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.accent.withOpacity(_hovered ? 1 : 0.5),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: widget.accent.withOpacity(_hovered ? 1 : 0.5),
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
