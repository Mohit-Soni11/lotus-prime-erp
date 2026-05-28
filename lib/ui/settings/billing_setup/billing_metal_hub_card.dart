import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/settings/billing_setup/billing_setup_theme.dart';

class BillingMetalHubData {
  final String metal;
  final String title;
  final String subtitle;
  final String actionLabel;
  final List<String> badges;
  final IconData fallbackIcon;
  final Color accent;
  final Color surface;
  final String logoAsset;

  const BillingMetalHubData({
    required this.metal,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.badges,
    required this.fallbackIcon,
    required this.accent,
    required this.surface,
    required this.logoAsset,
  });
}

class BillingMetalHubCard extends StatefulWidget {
  final BillingMetalHubData data;
  final AnimationController animationController;
  final double delay;
  final VoidCallback onTap;

  const BillingMetalHubCard({
    super.key,
    required this.data,
    required this.animationController,
    required this.delay,
    required this.onTap,
  });

  @override
  State<BillingMetalHubCard> createState() => _BillingMetalHubCardState();
}

class _BillingMetalHubCardState extends State<BillingMetalHubCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(
          widget.delay.clamp(0.0, 0.85),
          (widget.delay + 0.34).clamp(0.1, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(
          widget.delay.clamp(0.0, 0.85),
          (widget.delay + 0.34).clamp(0.1, 1.0),
          curve: Curves.easeOut,
        ),
      ),
    );

    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: fade,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            scale: _hovered ? 1.012 : 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(22),
                splashColor: data.accent.withValues(alpha: 0.08),
                highlightColor: data.accent.withValues(alpha: 0.04),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 174,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: data.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color:
                          data.accent.withValues(alpha: _hovered ? 0.36 : 0.2),
                      width: _hovered ? 1.5 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: data.accent
                            .withValues(alpha: _hovered ? 0.15 : 0.08),
                        blurRadius: _hovered ? 22 : 14,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _MetalLogo(data: data),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: BillingSetupColors.textDark,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                    color: BillingSetupColors.textBody,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: data.badges
                            .map((label) =>
                                _Badge(label: label, accent: data.accent))
                            .toList(),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            data.actionLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: data.accent,
                              letterSpacing: 0,
                            ),
                          ),
                          const Spacer(),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: data.accent
                                  .withValues(alpha: _hovered ? 0.16 : 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: data.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetalLogo extends StatelessWidget {
  final BillingMetalHubData data;

  const _MetalLogo({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: data.accent.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          data.logoAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: data.accent.withValues(alpha: 0.12),
            child: Icon(data.fallbackIcon, color: data.accent, size: 26),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color accent;

  const _Badge({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: BillingSetupColors.textBody,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
