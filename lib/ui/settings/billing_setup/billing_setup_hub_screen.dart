// =============================================================================
// FILE        : lib/ui/settings/billing_setup/billing_setup_hub_screen.dart
// MODULE      : Billing Setup
// DESCRIPTION : Hub screen - Sales, Purchase and Girvi billing cards.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/settings/billing_setup/girvi/presentation/screens/girvi_billing_workspace_screen.dart';
import '../../../theme/settings/billing_setup/billing_setup_colors.dart';
import '../../../theme/settings/billing_setup/billing_setup_strings.dart';
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
        screenTitle: BillingSetupStrings.hubTitle,
        screenSubtitle: BillingSetupStrings.hubSub,
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SELECT MODULE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: BillingSetupColors.textMuted,
                  )),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _ModuleCard(
                    icon: Icons.point_of_sale_rounded,
                    title: BillingSetupStrings.cardSalesTitle,
                    subtitle: BillingSetupStrings.cardSalesSub,
                    accent: BillingSetupColors.salesBrand,
                    tag: BillingSetupStrings.cardSalesTag,
                    onTap: () =>
                        _navigate(context, const SalesMetalHubScreen()),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _ModuleCard(
                    icon: Icons.shopping_bag_outlined,
                    title: BillingSetupStrings.cardPurchaseTitle,
                    subtitle: BillingSetupStrings.cardPurchaseSub,
                    accent: BillingSetupColors.purchaseBrand,
                    tag: BillingSetupStrings.cardPurchaseTag,
                    onTap: () =>
                        _navigate(context, const PurchaseMetalHubScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _ModuleCard(
                  icon: Icons.lock_outline_rounded,
                  title: BillingSetupStrings.cardGirviTitle,
                  subtitle: BillingSetupStrings.cardGirviSub,
                  accent: BillingSetupColors.girviBrand,
                  tag: 'Interest - Notice - Terms',
                  onTap: () =>
                      _navigate(context, const GirviBillingWorkspaceScreen()),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BillingSetupColors.salesBrand.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          BillingSetupColors.salesBrand.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: BillingSetupColors.salesBrand),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        BillingSetupStrings.hubInfoNote,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovered
                    ? widget.accent.withValues(alpha: 0.5)
                    : Colors.grey.shade200,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? widget.accent.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: _hovered ? 20 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        widget.accent.withValues(alpha: _hovered ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, size: 22, color: widget.accent),
                ),
                const SizedBox(height: 12),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color:
                        _hovered ? widget.accent : BillingSetupColors.textDark,
                  ),
                  child: Text(widget.title),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: BillingSetupColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: widget.accent.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    widget.tag,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: widget.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Text(
                    BillingSetupStrings.configureLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          widget.accent.withValues(alpha: _hovered ? 1 : 0.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 11,
                      color:
                          widget.accent.withValues(alpha: _hovered ? 1 : 0.5)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
