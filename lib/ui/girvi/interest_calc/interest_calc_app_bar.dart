// =============================================================================
// FILE        : interest_calc_app_bar.dart
// MODULE      : Girvi / Pawn
// LAYER       : UI / Component
// DESCRIPTION : Premium Dark shell AppBar for the Interest Calculator screen.
//               Zero hardcoded colors, styles, icons or strings.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/girvi/girvi_theme.dart';

class InterestCalcAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;

  const InterestCalcAppBar({
    super.key,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  State<InterestCalcAppBar> createState() => _InterestCalcAppBarState();
}

class _InterestCalcAppBarState extends State<InterestCalcAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: GirviColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: GirviColors.shellBorder, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: GirviColors.shadowMedium,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 1. Animated Back Button ──────────────────────────────────────
            _HoverBackButton(onTap: widget.onBack),
            const SizedBox(width: 18),

            // ── 2. Vertical Divider ──────────────────────────────────────────
            _buildVerticalDivider(),
            const SizedBox(width: 18),

            // ── 3. Premium Gradient Module Icon ──────────────────────────────
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    GirviColors.goldGradientStart, // Premium gradient
                    GirviColors.brandGold,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: GirviColors.brandGold.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(
                GirviIcons.calculator, // Specific Calculator Icon
                color: GirviColors.cardBg,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),

            // ── 4. Main Title ────────────────────────────────────────────────
            Text(
              GirviStrings.calcTitle.toUpperCase(),
              style: GirviStyles.shellTitle.copyWith(
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),

            // Spacer pushes everything else to the right
            const Spacer(),

            // ── 5. Premium Radar Widget ──────────────────────────────────────
            _RadarWidget(blinkCtrl: _blinkCtrl),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1.5,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            GirviColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE APP BAR COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});

  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered
                  ? GirviColors.shellBg
                  : GirviColors.shellBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? GirviColors.brandGold
                    : GirviColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: GirviColors.brandGold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              GirviIcons.backArrow,
              color: _isHovered
                  ? GirviColors.brandGold
                  : GirviColors.shellTextTitle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarWidget extends StatelessWidget {
  final AnimationController blinkCtrl;
  const _RadarWidget({required this.blinkCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GirviColors.onlineGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: GirviColors.onlineGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildWave(blinkCtrl, 0.0),
                _buildWave(blinkCtrl, 0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: GirviColors.onlineGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: GirviColors.onlineGreen,
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
          Text(
            GirviStrings.systemOnline,
            style: GoogleFonts.inter(
              color: GirviColors.onlineGreen,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWave(AnimationController ctrl, double delay) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final val = (ctrl.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - val,
          child: Transform.scale(
            scale: 1.0 + (val * 1.5),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: GirviColors.onlineGreen.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
