// -----------------------------------------------------------------------------
// FILE: customer_list_app_bar.dart
// MODULE: Customer → Customer List
// DESCRIPTION: Top app bar matching POS Terminal style.
//              Dark shell + Gold accent + Radar below title.
// -----------------------------------------------------------------------------
 
import 'package:flutter/material.dart';
import '../../../theme/customer/customer_list/customer_list_theme.dart';
 
class CustomerListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final String shopName;
 
  const CustomerListAppBar({
    super.key,
    required this.onBack,
    this.shopName = CustomerListStrings.shopName,
  });
 
  @override
  Size get preferredSize => const Size.fromHeight(CustomerListStyles.appBarHeight);
 
  @override
  Widget build(BuildContext context) {
    return Container(
      height: CustomerListStyles.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: CustomerListColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: CustomerListColors.shellBorder, width: 1),
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
            // 1. ANIMATED BACK BUTTON
            _HoverBackButton(onTap: onBack),
            const SizedBox(width: 20),
 
            // 2. VERTICAL DIVIDER
            _buildVerticalDivider(),
            const SizedBox(width: 20),
 
            // 3. TITLE + RADAR (Radar is back below the title)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Title Row
                Row(
                  children: [
                    Icon(
                      CustomerListIcons.moduleIcon, // Replaced yellow dot with icon
                      color: CustomerListColors.brandGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CustomerListStrings.appBarTitle, // "CLIENT DIRECTORY"
                      style: CustomerListStyles.appBarTitle,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Radar status (Placed exactly where it was before)
                const _RadarStatusWidget(),
              ],
            ),
 
            const Spacer(), // Pushes everything to the left, badge is removed
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
            CustomerListColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED BACK BUTTON (Gold hover - matches POS)
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
            duration: const Duration(milliseconds: 250),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered
                  ? CustomerListColors.bodyPanelBg
                  : CustomerListColors.shellBg,
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
                        color: CustomerListColors.brandGold.withOpacity(0.25),
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
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// RADAR ANIMATION (Same as POS)
// ─────────────────────────────────────────────────────────────────────────────
class _RadarStatusWidget extends StatefulWidget {
  const _RadarStatusWidget();
 
  @override
  State<_RadarStatusWidget> createState() => _RadarStatusWidgetState();
}
 
class _RadarStatusWidgetState extends State<_RadarStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
 
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }
 
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
              _buildWave(delay: 0.0),
              _buildWave(delay: 0.5),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF10B981),
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
            color: const Color(0xFF10B981).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.2),
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
 
  Widget _buildWave({required double delay}) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final val = (_ctrl.value + delay) % 1.0;
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
                  color: const Color(0xFF10B981).withOpacity(0.5),
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