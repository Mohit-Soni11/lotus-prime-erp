// =============================================================================
// FILE        : lib/ui/settings/billing_setup/shared/billing_setup_app_bar.dart
// MODULE      : Billing Setup
// LAYER       : UI / Shared Components
// DESCRIPTION : Reusable dark shell AppBar for all Billing Setup screens.
//               Exact KarigarAppBar pattern:
//               hover back button | vertical divider | gold dot + title |
//               radar SYSTEM ONLINE badge | module badge (right)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/settings/billing_setup/billing_setup_theme.dart';

class BillingSetupAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String screenTitle;
  final String screenSubtitle;
  final VoidCallback onBack;

  const BillingSetupAppBar({
    super.key,
    required this.screenTitle,
    required this.screenSubtitle,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BillingSetupStyles.shellDecoration,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // ── Back Button ────────────────────────────────────────────────
            _HoverBackButton(onTap: onBack),
            const SizedBox(width: 20),

            // ── Vertical Divider ───────────────────────────────────────────
            _VerticalDivider(),
            const SizedBox(width: 20),

            // ── Title + Radar Badge ────────────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Gold dot
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: BillingSetupColors.brandGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                BillingSetupColors.brandGold.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(screenTitle, style: BillingSetupStyles.shellTitle),
                  ],
                ),
                const SizedBox(height: 5),
                const _RadarStatusBadge(),
              ],
            ),

            const Spacer(),

            // ── Module Badge (right) ───────────────────────────────────────
            _ModuleBadge(subtitle: screenSubtitle),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HOVER BACK BUTTON
// ═════════════════════════════════════════════════════════════════════════════
class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});

  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BillingSetupColors.shellBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered
                    ? BillingSetupColors.brandGold
                    : BillingSetupColors.shellBorder,
                width: _hovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color: BillingSetupColors.brandGold.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(
              BillingSetupIcons.backArrow,
              color: _hovered
                  ? BillingSetupColors.brandGold
                  : BillingSetupColors.shellTextTitle,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VERTICAL DIVIDER
// ═════════════════════════════════════════════════════════════════════════════
class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            BillingSetupColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RADAR STATUS BADGE — Animated radar waves + SYSTEM ONLINE
// ═════════════════════════════════════════════════════════════════════════════
class _RadarStatusBadge extends StatefulWidget {
  const _RadarStatusBadge();

  @override
  State<_RadarStatusBadge> createState() => _RadarStatusBadgeState();
}

class _RadarStatusBadgeState extends State<_RadarStatusBadge>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) {
      _ac.stop();
    } else if (s == AppLifecycleState.resumed) {
      _ac.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ac.dispose();
    super.dispose();
  }

  Widget _wave(double delay, double size) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) {
        final v = (_ac.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - v,
          child: Transform.scale(
            scale: 1.0 + v * 1.5,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: BillingSetupColors.onlineGreen.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Radar waves + solid dot
        SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _wave(0.0, 14),
              _wave(0.5, 14),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: BillingSetupColors.onlineGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: BillingSetupColors.onlineGreen,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // SYSTEM ONLINE pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: BillingSetupColors.onlineGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: BillingSetupColors.onlineGreen.withOpacity(0.2),
            ),
          ),
          child: Text(
            BillingSetupStrings.systemOnline,
            style: GoogleFonts.inter(
              color: BillingSetupColors.onlineGreen,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODULE BADGE (right side)
// ═════════════════════════════════════════════════════════════════════════════
class _ModuleBadge extends StatelessWidget {
  final String subtitle;
  const _ModuleBadge({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BillingSetupColors.moduleBadgeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BillingSetupColors.moduleBadgeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon box
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: BillingSetupColors.brandGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              BillingSetupIcons.moduleIcon,
              color: BillingSetupColors.brandGold,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                BillingSetupStrings.moduleBadge,
                style: GoogleFonts.inter(
                  color: BillingSetupColors.shellTextTitle,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: BillingSetupColors.shellTextMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
