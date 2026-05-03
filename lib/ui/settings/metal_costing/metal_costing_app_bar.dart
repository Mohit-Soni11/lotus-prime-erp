// =============================================================================
// FILE        : lib/ui/settings/metal_costing/metal_costing_app_bar.dart
// MODULE      : Metal Costing Analysis
// LAYER       : UI / Shared
// DESCRIPTION : Reusable dark shell AppBar — exact BillingSetupAppBar pattern.
//               Back button | divider | gold dot + title | SYSTEM ONLINE | badge
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/settings/metal_costing/metal_costing_theme.dart';

class MetalCostingAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String screenTitle;
  final String screenSubtitle;
  final VoidCallback onBack;

  const MetalCostingAppBar({
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
      decoration: MetalCostingStyles.shellDecoration,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _HoverBackButton(onTap: onBack),
            const SizedBox(width: 20),
            _VerticalDivider(),
            const SizedBox(width: 20),
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
                        color: MetalCostingColors.brandGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                MetalCostingColors.brandGold.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(screenTitle, style: MetalCostingStyles.shellTitle),
                  ],
                ),
                const SizedBox(height: 5),
                const _RadarStatusBadge(),
              ],
            ),
            const Spacer(),
            _ModuleBadge(subtitle: screenSubtitle),
          ],
        ),
      ),
    );
  }
}

// ── Hover Back Button ─────────────────────────────────────────────────────────
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
              color: MetalCostingColors.shellBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered
                    ? MetalCostingColors.brandGold
                    : MetalCostingColors.shellBorder,
                width: _hovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color: MetalCostingColors.brandGold.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(
              MetalCostingIcons.backArrow,
              color: _hovered
                  ? MetalCostingColors.brandGold
                  : MetalCostingColors.shellTextTitle,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Vertical Divider ──────────────────────────────────────────────────────────
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
            MetalCostingColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ── Radar Status Badge ────────────────────────────────────────────────────────
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
                  color: MetalCostingColors.onlineGreen.withOpacity(0.5),
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
                  color: MetalCostingColors.onlineGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MetalCostingColors.onlineGreen,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: MetalCostingColors.onlineGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: MetalCostingColors.onlineGreen.withOpacity(0.2),
            ),
          ),
          child: Text(
            MetalCostingStrings.systemOnline,
            style: GoogleFonts.inter(
              color: MetalCostingColors.onlineGreen,
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

// ── Module Badge ──────────────────────────────────────────────────────────────
class _ModuleBadge extends StatelessWidget {
  final String subtitle;
  const _ModuleBadge({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: MetalCostingColors.moduleBadgeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MetalCostingColors.moduleBadgeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: MetalCostingColors.brandGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              MetalCostingIcons.moduleIcon,
              color: MetalCostingColors.brandGold,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                MetalCostingStrings.moduleBadge,
                style: GoogleFonts.inter(
                  color: MetalCostingColors.shellTextTitle,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: MetalCostingColors.shellTextMuted,
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
