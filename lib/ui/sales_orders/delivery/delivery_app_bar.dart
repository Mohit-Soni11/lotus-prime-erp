// =============================================================================
// FILE        : delivery_app_bar.dart
// MODULE      : Sales â†’ Delivery Management
// LAYER       : UI
// DESCRIPTION : Dark shell AppBar â€” premium layout.
//               Removed inline refresh button as requested.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/sales/delivery/delivery_theme.dart';

class DeliveryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  // NOTE: Removed onRefresh parameter

  const DeliveryAppBar({
    super.key,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: DeliveryStyles.shellPanel,
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // â”€â”€ 1. Hover Back Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _HoverBackButton(onTap: onBack),
            const SizedBox(width: 18),

            // â”€â”€ 2. Vertical Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildDivider(),
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
                    DeliveryColors.goldGradientStart,
                    DeliveryColors.goldGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: DeliveryColors.brandGold.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                DeliveryIcons.moduleIcon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),

            // â”€â”€ 4. Main Title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const Text(
              DeliveryStrings.appBarTitle,
              style: DeliveryStyles.headerTitle,
            ),

            // Spacer pushes everything else to the right
            const Spacer(),

            // â”€â”€ 5. System Online Radar Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const _RadarStatusWidget(),

            // Removed: Refresh Icon Button
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(
        width: 1.5,
        height: 32,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              DeliveryColors.shellBorder,
              Colors.transparent,
            ],
          ),
        ),
      );
}

// â”€â”€ Hover Back Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});
  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _h ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _h
                  ? DeliveryColors.shellBg
                  : DeliveryColors.shellBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    _h ? DeliveryColors.brandGold : DeliveryColors.shellBorder,
                width: _h ? 1.5 : 1.0,
              ),
              boxShadow: _h
                  ? [
                      BoxShadow(
                        color: DeliveryColors.brandGold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Icon(
              DeliveryIcons.backArrow,
              color:
                  _h ? DeliveryColors.brandGold : DeliveryColors.shellTextTitle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Radar Status Widget (Pill Shape matched) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
        color: DeliveryColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: DeliveryColors.onlineGreen.withValues(alpha: 0.3)),
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
                _wave(0.0),
                _wave(0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: DeliveryColors.onlineGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DeliveryColors.onlineGreen,
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            DeliveryStrings.systemOnline,
            style: TextStyle(
              color: DeliveryColors.onlineGreen,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wave(double delay) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final v = (_ctrl.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - v,
          child: Transform.scale(
            scale: 1.0 + (v * 1.5),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: DeliveryColors.onlineGreen.withValues(alpha: 0.5),
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
