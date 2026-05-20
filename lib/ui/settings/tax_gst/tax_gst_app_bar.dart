// ============================================================
// FILE    : lib/ui/settings/tax_gst/tax_gst_app_bar.dart
// MODULE  : Tax & GST Configuration
// AUTHOR  : Lotus Prime ERP
// VERSION : 1.0.0
// DESC    : Dark-shell AppBar with:
//           â€¢ Animated gold-hover back button
//           â€¢ GST-green gradient module icon
//           â€¢ Title + live pulse blink dot
//           â€¢ Module badge (TAX & GST)
//           All text/color/icon from theme layer only.
// ============================================================

import 'package:flutter/material.dart';
import '../../../theme/settings/tax_gst/tax_gst_theme.dart';

class TaxGstAppBar extends StatefulWidget implements PreferredSizeWidget {
  const TaxGstAppBar({super.key, required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Size get preferredSize => const Size.fromHeight(TaxGstStyles.appBarHeight);

  @override
  State<TaxGstAppBar> createState() => _TaxGstAppBarState();
}

class _TaxGstAppBarState extends State<TaxGstAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: TaxGstStyles.animPulse,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TaxGstStyles.appBarHeight,
      decoration: const BoxDecoration(
        color: TaxGstColors.shellSurface,
        border: Border(
          bottom: BorderSide(
            color: TaxGstColors.shellBorder,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              // â”€â”€ Back Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _AnimatedBackButton(onTap: widget.onBackPressed),

              const SizedBox(width: 14),

              // â”€â”€ Vertical Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                width: 1,
                height: 28,
                color: TaxGstColors.shellBorder,
              ),

              const SizedBox(width: 14),

              // â”€â”€ Module Icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                width: TaxGstStyles.moduleIconSize,
                height: TaxGstStyles.moduleIconSize,
                decoration: BoxDecoration(
                  gradient: TaxGstColors.moduleIconGradient,
                  borderRadius:
                      BorderRadius.circular(TaxGstStyles.radiusBadge + 1),
                  boxShadow: [
                    BoxShadow(
                      color: TaxGstColors.accentPrimary.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  TaxGstIcons.moduleHeader,
                  color: Colors.white,
                  size: 16,
                ),
              ),

              const SizedBox(width: 12),

              // â”€â”€ Title + Pulse â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TaxGstStrings.appBarTitle,
                      style: TaxGstStyles.appBarTitle(context),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        // Animated pulse dot
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Opacity(
                            opacity: _pulseAnim.value,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: TaxGstColors.onlinePulse,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          TaxGstStrings.systemOnlineLabel,
                          style: TaxGstStyles.appBarSubtitle(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // â”€â”€ Module Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: TaxGstColors.shellBadgeBg,
                  borderRadius: BorderRadius.circular(TaxGstStyles.radiusBadge),
                  border: Border.all(
                    color: TaxGstColors.shellBadgeBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      TaxGstIcons.moduleHeader,
                      size: 11,
                      color: TaxGstColors.accentPrimary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      TaxGstStrings.moduleBadgeLabel,
                      style: TaxGstStyles.badgeText(context),
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

// â”€â”€ Animated Back Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AnimatedBackButton extends StatefulWidget {
  const _AnimatedBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<_AnimatedBackButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl;
  late final Animation<Color?> _iconColorAnim;
  late final Animation<Color?> _bgColorAnim;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: TaxGstStyles.animFast,
    );
    _iconColorAnim = ColorTween(
      begin: TaxGstColors.shellBackBtn,
      end: TaxGstColors.shellBackBtnHover,
    ).animate(_hoverCtrl);
    _bgColorAnim = ColorTween(
      begin: Colors.transparent,
      end: TaxGstColors.shellBackBtnHoverBg,
    ).animate(_hoverCtrl);
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _hoverCtrl.forward(),
      onExit: (_) => _hoverCtrl.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverCtrl,
          builder: (_, __) => Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _bgColorAnim.value,
              borderRadius: BorderRadius.circular(TaxGstStyles.radiusChip),
              border: Border.all(
                color: _iconColorAnim.value?.withValues(alpha: 0.3) ??
                    Colors.transparent,
                width: 1,
              ),
            ),
            child: Icon(
              TaxGstIcons.backArrow,
              size: 17,
              color: _iconColorAnim.value,
            ),
          ),
        ),
      ),
    );
  }
}
