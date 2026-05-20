// -----------------------------------------------------------------------------
// FILE: supplier_list_app_bar.dart
// MODULE: Supplier â†’ Supplier List
// DESCRIPTION: Dark shell app bar â€” premium layout with improved spacing and gold gradient
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../../../theme/stock/supplier/supplier_list/supplier_list_theme.dart';

class SupplierListAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  final String shopName;

  const SupplierListAppBar({
    super.key,
    required this.onBack,
    this.shopName = SupplierListStrings.shopName,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(SupplierListStyles.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SupplierListStyles.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: SupplierListColors.shellPanelBg,
        border: Border(
            bottom:
                BorderSide(color: SupplierListColors.shellBorder, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 4))
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // â”€â”€ 1. Animated Back Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _HoverBackButton(onTap: onBack),
            const SizedBox(width: 18), // Matched spacing

            // â”€â”€ 2. Vertical Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildVerticalDivider(),
            const SizedBox(width: 18),

            // â”€â”€ 3. Premium Gradient Module Icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SupplierListColors.goldGradientStart, // Premium gradient
                    SupplierListColors.brandGold,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: SupplierListColors.brandGold.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(
                SupplierListIcons.moduleIcon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),

            // â”€â”€ 4. Main Title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Text(
              SupplierListStrings.appBarTitle,
              style: SupplierListStyles.appBarTitle,
            ),

            // Spacer pushes everything else to the right
            const Spacer(),

            // â”€â”€ 5. Premium Radar Widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const _RadarStatusWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() => Container(
        width: 1.5, // Thicker divider
        height: 32,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              SupplierListColors.shellBorder,
              Colors.transparent
            ],
          ),
        ),
      );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Animated Back Button
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
              // Changed hover background to match premium layout
              color: _isHovered
                  ? SupplierListColors.shellBg
                  : SupplierListColors.shellBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? SupplierListColors.brandGold
                    : SupplierListColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                          color: SupplierListColors.brandGold
                              .withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 3))
                    ]
                  : [],
            ),
            child: Icon(
              SupplierListIcons.backArrow,
              color: _isHovered
                  ? SupplierListColors.brandGold
                  : SupplierListColors.shellTextTitle,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Radar Animation
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SupplierListColors.onlineGreen
            .withValues(alpha: 0.08), // Using theme color
        borderRadius: BorderRadius.circular(30), // Pill Shape
        border: Border.all(
            color: SupplierListColors.onlineGreen.withValues(alpha: 0.3)),
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
                _buildWave(delay: 0.0),
                _buildWave(delay: 0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: SupplierListColors.onlineGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: SupplierListColors.onlineGreen,
                          blurRadius: 6,
                          spreadRadius: 1)
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(SupplierListStrings.systemOnline,
              style: SupplierListStyles.systemOnlineText),
        ],
      ),
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
                    color:
                        SupplierListColors.onlineGreen.withValues(alpha: 0.5),
                    width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
