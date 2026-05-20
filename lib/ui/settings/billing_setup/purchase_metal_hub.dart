// =============================================================================
// FILE        : lib/ui/settings/billing_setup/purchase/purchase_metal_hub.dart
// MODULE      : Billing Setup â†’ Purchase
// DESCRIPTION : 4 metal cards â€” Gold, Silver, Diamond, Platinum.
//               Each opens PurchaseMetalSettingsScreen with its metal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/settings/billing_setup/billing_setup_theme.dart';
import 'billing_setup_app_bar.dart';
import 'purchase_metal_settings_screen.dart';

class _MetalCard {
  final String metal;
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final Color bg;

  const _MetalCard({
    required this.metal,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.bg,
  });
}

class PurchaseMetalHubScreen extends StatelessWidget {
  const PurchaseMetalHubScreen({super.key});

  static const List<_MetalCard> _metals = [
    _MetalCard(
      metal: 'gold',
      emoji: 'ðŸ¥‡',
      title: 'Gold',
      subtitle: 'Voucher display, HUID, return\npolicy & T&C for gold purchase',
      accent: Color(0xFFB8860B),
      bg: Color(0xFFFFFBEB),
    ),
    _MetalCard(
      metal: 'silver',
      emoji: 'ðŸ¥ˆ',
      title: 'Silver',
      subtitle:
          'Voucher display, purity, return\npolicy & T&C for silver purchase',
      accent: Color(0xFF6B7280),
      bg: Color(0xFFF9FAFB),
    ),
    _MetalCard(
      metal: 'diamond',
      emoji: 'ðŸ’Ž',
      title: 'Diamond',
      subtitle:
          'Carat, clarity, certification,\nreturn policy & T&C for diamond',
      accent: Color(0xFF0EA5E9),
      bg: Color(0xFFF0F9FF),
    ),
    _MetalCard(
      metal: 'platinum',
      emoji: 'â¬œ',
      title: 'Platinum',
      subtitle:
          'Voucher display, purity, return\npolicy & T&C for platinum purchase',
      accent: Color(0xFF7C3AED),
      bg: Color(0xFFF5F3FF),
    ),
  ];

  void _openMetal(BuildContext context, String metal) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            PurchaseMetalSettingsScreen(metal: metal),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
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
        screenTitle: 'Purchase Billing',
        screenSubtitle: 'Select metal type to configure',
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SELECT METAL TYPE', style: BillingSetupStyles.sectionLabel),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  if (isWide) {
                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _metals
                          .map((m) => _MetalTile(
                                card: m,
                                onTap: () => _openMetal(context, m.metal),
                              ))
                          .toList(),
                    );
                  }
                  return Column(
                    children: _metals
                        .map((m) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _MetalTile(
                                card: m,
                                onTap: () => _openMetal(context, m.metal),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// METAL TILE â€” same design as Sales hub
// =============================================================================
class _MetalTile extends StatefulWidget {
  final _MetalCard card;
  final VoidCallback onTap;
  const _MetalTile({required this.card, required this.onTap});

  @override
  State<_MetalTile> createState() => _MetalTileState();
}

class _MetalTileState extends State<_MetalTile>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
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
    final c = widget.card;
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _hovered ? c.bg : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovered
                    ? c.accent.withValues(alpha: 0.5)
                    : Colors.grey.shade200,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? c.accent.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: _hovered ? 18 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: _hovered ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(c.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              _hovered ? c.accent : BillingSetupColors.textDark,
                        ),
                        child: Text(c.title),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: BillingSetupColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _hovered ? c.accent : Colors.grey.shade400,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
