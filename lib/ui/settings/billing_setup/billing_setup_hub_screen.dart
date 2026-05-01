// =============================================================================
// FILE        : lib/ui/settings/billing_setup/billing_setup_hub_screen.dart
// MODULE      : Billing Setup
// LAYER       : Presentation / UI
// DESCRIPTION : Hub screen — 4 animated cards. Each navigates to its
//               own billing config tab screen. Dark AppBar + warm body.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/settings/billing_setup/billing_setup_theme.dart';
import 'billing_setup_app_bar.dart';
import 'sales_billing_tab.dart';
import 'purchase_billing_tab.dart';
import 'girvi_billing_tab.dart';
import 'return_billing_tab.dart';

// ── Card meta data model ──────────────────────────────────────────────────────
class _CardMeta {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String count;
  final Widget screen;

  const _CardMeta({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.screen,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// HUB SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class BillingSetupHubScreen extends StatelessWidget {
  const BillingSetupHubScreen({super.key});

  static final List<_CardMeta> _cards = [
    _CardMeta(
      icon: BillingSetupIcons.salesCard,
      accent: BillingSetupColors.salesBrand,
      title: BillingSetupStrings.cardSalesTitle,
      subtitle: BillingSetupStrings.cardSalesSub,
      count: BillingSetupStrings.cardSalesCount,
      screen: const SalesBillingTab(),
    ),
    _CardMeta(
      icon: BillingSetupIcons.purchaseCard,
      accent: BillingSetupColors.purchaseBrand,
      title: BillingSetupStrings.cardPurchaseTitle,
      subtitle: BillingSetupStrings.cardPurchaseSub,
      count: BillingSetupStrings.cardPurchaseCount,
      screen: const PurchaseBillingTab(),
    ),
    _CardMeta(
      icon: BillingSetupIcons.girviCard,
      accent: BillingSetupColors.girviBrand,
      title: BillingSetupStrings.cardGirviTitle,
      subtitle: BillingSetupStrings.cardGirviSub,
      count: BillingSetupStrings.cardGirviCount,
      screen: const GirviBillingTab(),
    ),
    _CardMeta(
      icon: BillingSetupIcons.returnCard,
      accent: BillingSetupColors.returnBrand,
      title: BillingSetupStrings.cardReturnTitle,
      subtitle: BillingSetupStrings.cardReturnSub,
      count: BillingSetupStrings.cardReturnCount,
      screen: const ReturnBillingTab(),
    ),
  ];

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => screen,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BillingSetupColors.bodyBg,
      appBar: BillingSetupAppBar(
        screenTitle: BillingSetupStrings.hubTitle,
        screenSubtitle: BillingSetupStrings.hubSub,
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: BillingSetupStyles.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              _buildSectionLabel(),
              const SizedBox(height: 16),
              _buildGrid(context),
              const SizedBox(height: 28),
              _buildInfoBanner(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel() {
    return Text(
      'SELECT A MODULE TO CONFIGURE',
      style: BillingSetupStyles.sectionLabel,
    );
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            children: _cards
                .map((card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _HubCard(
                          card: card,
                          onTap: () => _navigate(context, card.screen),
                        ),
                      ),
                    ))
                .toList(),
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.05,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _cards
              .map((card) => _HubCard(
                    card: card,
                    onTap: () => _navigate(context, card.screen),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BillingSetupColors.salesBrand.withOpacity(0.05),
        borderRadius: BorderRadius.circular(BillingSetupStyles.rCard),
        border: Border.all(
          color: BillingSetupColors.salesBrand.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            BillingSetupIcons.infoIcon,
            size: 18,
            color: BillingSetupColors.salesBrand,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Each module has its own invoice number series, payment rules '
              'and terms & conditions. Changes apply to new bills only — '
              'existing records are not affected.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: BillingSetupColors.textBody,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HUB CARD — Animated hover card
// ═════════════════════════════════════════════════════════════════════════════
class _HubCard extends StatefulWidget {
  final _CardMeta card;
  final VoidCallback onTap;
  const _HubCard({required this.card, required this.onTap});

  @override
  State<_HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<_HubCard>
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
    final color = widget.card.accent;
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
            decoration: BillingSetupStyles.hubCard(
              accent: color,
              hovered: _hovered,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Top: icon + count badge ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(_hovered ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: color.withOpacity(_hovered ? 0.4 : 0.2),
                        ),
                      ),
                      child: Icon(widget.card.icon, size: 22, color: color),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        widget.card.count,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Bottom: title + subtitle + configure arrow ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _hovered ? color : BillingSetupColors.textDark,
                      ),
                      child: Text(widget.card.title, maxLines: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.card.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: BillingSetupColors.textMuted,
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
                              BillingSetupStrings.configure,
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
                              BillingSetupIcons.navArrow,
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
