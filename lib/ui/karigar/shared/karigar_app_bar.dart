// =============================================================================
// FILE        : karigar_app_bar.dart
// MODULE      : Karigar
// LAYER       : UI / Shared Components
// DESCRIPTION : Reusable dark shell AppBar for all Karigar module screens.
//               Matches AddStock / POS AppBar pattern exactly:
//               hover back button, gold dot, radar badge, module badge.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/karigar/karigar_theme.dart';

class KarigarAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String screenTitle;
  final String screenSubtitle;
  final VoidCallback onBack;

  const KarigarAppBar({
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
      decoration: KarigarStyles.shellDecoration,
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          _HoverBackButton(onTap: onBack),
          const SizedBox(width: 20),
          _VerticalDivider(),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: KarigarColors.brandGold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: KarigarColors.brandGold.withValues(alpha: 0.6),
                        blurRadius: 6,
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(screenTitle, style: KarigarStyles.shellTitle),
              ]),
              const SizedBox(height: 5),
              const _RadarStatusBadge(),
            ],
          ),
          const Spacer(),
          _ModuleBadge(subtitle: screenSubtitle),
        ]),
      ),
    );
  }
}

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
              color: KarigarColors.shellBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered
                    ? KarigarColors.brandGold
                    : KarigarColors.shellBorder,
                width: _hovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color: KarigarColors.brandGold.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(
              KarigarIcons.backArrow,
              color: _hovered
                  ? KarigarColors.brandGold
                  : KarigarColors.shellTextTitle,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

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
            KarigarColors.shellBorder,
            Colors.transparent
          ],
        ),
      ),
    );
  }
}

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
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
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
                  color: KarigarColors.onlineGreen.withValues(alpha: 0.5),
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
    return Row(children: [
      SizedBox(
        width: 14,
        height: 14,
        child: Stack(alignment: Alignment.center, children: [
          _wave(0.0, 14),
          _wave(0.5, 14),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: KarigarColors.onlineGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: KarigarColors.onlineGreen,
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ],
            ),
          ),
        ]),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: KarigarColors.onlineGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: KarigarColors.onlineGreen.withValues(alpha: 0.2)),
        ),
        child: Text(
          KarigarStrings.systemOnline,
          style: GoogleFonts.inter(
            color: KarigarColors.onlineGreen,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    ]);
  }
}

class _ModuleBadge extends StatelessWidget {
  final String subtitle;
  const _ModuleBadge({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KarigarColors.moduleBadgeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KarigarColors.moduleBadgeBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: KarigarColors.brandGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(KarigarIcons.moduleIcon,
              color: KarigarColors.brandGold, size: 14),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(KarigarStrings.moduleBadge,
                style: GoogleFonts.inter(
                  color: KarigarColors.shellTextTitle,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                )),
            Text(subtitle,
                style: GoogleFonts.inter(
                  color: KarigarColors.shellTextMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                )),
          ],
        ),
      ]),
    );
  }
}
