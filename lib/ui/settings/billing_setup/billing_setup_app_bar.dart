// =============================================================================
// FILE        : lib/ui/settings/billing_setup/billing_setup_app_bar.dart
// MODULE      : Billing Setup
// DESCRIPTION : Dark-shell AppBar — matches CustomerList & Day Book pattern.
//               ✅ Gold gradient module icon + radar blink live indicator
//               ✅ Gold hover back button
//               ✅ "SYSTEM ONLINE" green blink badge below subtitle
//               ✅ Right-side module badge (BILLING SETUP)
//               ✅ All colors/strings/icons from BillingSetupTheme — zero
//                  hardcoded values in UI.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/settings/billing_setup/billing_setup_theme.dart';

class BillingSetupAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  Size get preferredSize =>
      const Size.fromHeight(BillingSetupStyles.appBarHeight);

  @override
  State<BillingSetupAppBar> createState() => _BillingSetupAppBarState();
}

class _BillingSetupAppBarState extends State<BillingSetupAppBar>
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
      height: BillingSetupStyles.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: BillingSetupColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: BillingSetupColors.shellBorder, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // ── 1. Animated Back Button ───────────────────────────────────────
            _HoverBackButton(onTap: widget.onBack),
            const SizedBox(width: 16),

            // ── 2. Vertical Divider ───────────────────────────────────────────
            _buildVerticalDivider(),
            const SizedBox(width: 16),

            // ── 3. Gradient Module Icon ───────────────────────────────────────
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD700),
                    BillingSetupColors.brandGold,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: BillingSetupColors.brandGold.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                BillingSetupIcons.moduleIcon,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 12),

            // ── 4. Title + Subtitle + Radar ───────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.screenTitle,
                  style: BillingSetupStyles.appBarTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.screenSubtitle,
                  style: BillingSetupStyles.appBarSubtitle,
                ),
                const SizedBox(height: 4),
                _RadarWidget(blinkCtrl: _blinkCtrl),
              ],
            ),

            const Spacer(),

            // ── 5. Right Module Badge ─────────────────────────────────────────
            _buildVerticalDivider(),
            const SizedBox(width: 16),
            _buildModuleBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
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

  Widget _buildModuleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: BillingSetupColors.moduleBadgeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: BillingSetupColors.moduleBadgeBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: BillingSetupColors.brandGold.withOpacity(0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            BillingSetupIcons.moduleIcon,
            color: BillingSetupColors.brandGold,
            size: 15,
          ),
          const SizedBox(width: 7),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BillingSetupStrings.moduleBadge,
                style: BillingSetupStyles.moduleBadgeTitle,
              ),
              Text(
                BillingSetupStrings.hubSub,
                style: BillingSetupStyles.moduleBadgeSub,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOVER BACK BUTTON — exact CustomerList / Day Book pattern
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
                  ? BillingSetupColors.shellBg
                  : BillingSetupColors.shellBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? BillingSetupColors.brandGold
                    : BillingSetupColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: BillingSetupColors.brandGold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              BillingSetupIcons.backArrow,
              color: _isHovered
                  ? BillingSetupColors.brandGold
                  : BillingSetupColors.shellTextTitle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RADAR / SYSTEM ONLINE — exact CustomerList pattern
// ─────────────────────────────────────────────────────────────────────────────
class _RadarWidget extends StatelessWidget {
  final AnimationController blinkCtrl;
  const _RadarWidget({required this.blinkCtrl});

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
              _buildWave(blinkCtrl, 0.0),
              _buildWave(blinkCtrl, 0.5),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: BillingSetupColors.onlineGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: BillingSetupColors.onlineGreen.withOpacity(0.25),
            ),
          ),
          child: Text(
            BillingSetupStrings.systemOnline,
            style: BillingSetupStyles.systemOnlineText,
          ),
        ),
      ],
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
}
