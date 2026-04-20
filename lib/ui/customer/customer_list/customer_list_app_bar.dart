// =============================================================================
// FILE: customer_list_app_bar.dart
// MODULE: Customer → Customer List
// LAYER: UI
// DESCRIPTION: Dark-shell AppBar — matches Day Book & POS Terminal pattern exactly.
//              ✅ Gold gradient module icon + radar blink live indicator
//              ✅ Gold hover back button
//              ✅ Right-side actions (Add, Refresh, Export) mapped to hover buttons
//              ✅ Stateful widget setup for radar animation matching DayBook
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';
// import '../../../logic/customer/customer_list/customer_list_controller.dart'; // Uncomment when ready

class CustomerListAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final String shopName;
  // final CustomerListController ctrl; // Uncomment when controller is linked

  const CustomerListAppBar({
    super.key,
    required this.onBack,
    this.shopName = CustomerListStrings.shopName,
    // required this.ctrl,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(CustomerListStyles.appBarHeight);

  @override
  State<CustomerListAppBar> createState() => _CustomerListAppBarState();
}

class _CustomerListAppBarState extends State<CustomerListAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkCtrl;

  @override
  void initState() {
    super.initState();
    // Animation controller for the Radar blink (Exactly like Day Book)
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
    // return ListenableBuilder(
    //   listenable: widget.ctrl,
    //   builder: (_, __) {
    return Container(
      width: double.infinity,
      height: CustomerListStyles.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: CustomerListColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: CustomerListColors.shellBorder, width: 1.0),
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
            // ── 1. Animated Back Button ──────────────────────────────────────
            _HoverBackButton(onTap: widget.onBack),
            const SizedBox(width: 16),

            // ── 2. Vertical Divider ──────────────────────────────────────────
            _buildVerticalDivider(),
            const SizedBox(width: 16),

            // ── 3. Gradient Module Icon + Title + Radar ──────────────────────
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD700), // Simulated goldGradStart
                    CustomerListColors.brandGold,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: CustomerListColors.brandGold.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Icon(
                CustomerListIcons.moduleIcon,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 12),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CustomerListStrings.appBarTitle,
                  style: CustomerListStyles.appBarTitle,
                ),
                const SizedBox(height: 4),
                _RadarWidget(blinkCtrl: _blinkCtrl),
              ],
            ),

            const Spacer(),

            // ── 4. Right Side Actions (Mapped from CustomerListIcons) ────────
            _buildVerticalDivider(),
            const SizedBox(width: 12),
            const _ActionButtons(), // Using available icons instead of PDF/Excel
          ],
        ),
      ),
    );
    //   },
    // );
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
            CustomerListColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTONS (Replaces Export buttons from Day Book)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  // final CustomerListController ctrl; // Pass this when ready
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconBtn(
          icon: CustomerListIcons.refresh,
          tooltip: CustomerListStrings.btnRefresh,
          onTap: () {}, // Link to ctrl.refresh() later
        ),
        const SizedBox(width: 6),
        _IconBtn(
          icon: CustomerListIcons.export,
          tooltip:
              'Export Data', // You can add this string to CustomerListStrings later
          onTap: () {},
        ),
        const SizedBox(width: 6),
        _IconBtn(
          icon: CustomerListIcons.addCustomer,
          tooltip: CustomerListStrings.btnAddNew,
          onTap: () {},
        ),
      ],
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered
                  ? CustomerListColors
                      .brandGoldLight // Found this in your theme!
                  : CustomerListColors.shellBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHovered
                    ? CustomerListColors.brandGold
                    : CustomerListColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              color: _isHovered
                  ? CustomerListColors.brandGold
                  : CustomerListColors.shellTextMuted,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED BACK BUTTON (Exact Day Book Pattern)
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
                  ? CustomerListColors.shellBg
                  : CustomerListColors.shellBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? CustomerListColors.brandGold
                    : CustomerListColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: CustomerListColors.brandGold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              CustomerListIcons.backArrow,
              color: _isHovered
                  ? CustomerListColors.brandGold
                  : CustomerListColors.shellTextTitle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RADAR / ONLINE WIDGET (Exact Day Book Pattern)
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
                  color: CustomerListColors.onlineGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CustomerListColors.onlineGreen,
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
            color: CustomerListColors.onlineGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CustomerListColors.onlineGreen.withOpacity(0.25),
            ),
          ),
          child: const Text(
            CustomerListStrings.systemOnline,
            style: CustomerListStyles.systemOnlineText,
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
                  color: CustomerListColors.onlineGreen.withOpacity(0.5),
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
