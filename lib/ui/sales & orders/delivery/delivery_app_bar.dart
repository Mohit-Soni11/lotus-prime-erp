// =============================================================================
// FILE        : delivery_app_bar.dart
// MODULE      : Sales → Delivery Management
// LAYER       : UI
// DESCRIPTION : Dark shell AppBar — consistent with BookingAdvanceAppBar.
//               Shows module icon (local_shipping), title, online indicator.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/sales/delivery/delivery_theme.dart';

class DeliveryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const DeliveryAppBar({
    super.key,
    required this.onBack,
    required this.onRefresh,
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
          children: [
            _HoverBackButton(onTap: onBack),
            const SizedBox(width: 18),
            _divider(),
            const SizedBox(width: 18),

            // Module icon + title
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          DeliveryColors.goldGradientStart,
                          DeliveryColors.goldGradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: DeliveryColors.brandGold.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      DeliveryIcons.moduleIcon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    DeliveryStrings.appBarTitle,
                    style: DeliveryStyles.headerTitle,
                  ),
                ]),
                const SizedBox(height: 5),
                const _OnlineIndicator(),
              ],
            ),

            const Spacer(),

            // Refresh button
            _HoverIconButton(
              icon: DeliveryIcons.refresh,
              onTap: onRefresh,
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
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

// ── Hover Back Button ──────────────────────────────────────────────────────────
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
                  : DeliveryColors.shellBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    _h ? DeliveryColors.brandGold : DeliveryColors.shellBorder,
                width: _h ? 1.5 : 1.0,
              ),
              boxShadow: _h
                  ? [
                      BoxShadow(
                        color: DeliveryColors.brandGold.withOpacity(0.3),
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

// ── Hover Icon Button ─────────────────────────────────────────────────────────
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _HoverIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _h
                  ? DeliveryColors.brandGold.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _h
                    ? DeliveryColors.brandGold.withOpacity(0.4)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              color:
                  _h ? DeliveryColors.brandGold : DeliveryColors.shellTextMuted,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Online Indicator ──────────────────────────────────────────────────────────
class _OnlineIndicator extends StatefulWidget {
  const _OnlineIndicator();
  @override
  State<_OnlineIndicator> createState() => _OnlineIndicatorState();
}

class _OnlineIndicatorState extends State<_OnlineIndicator>
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
    return Row(children: [
      SizedBox(
        width: 14,
        height: 14,
        child: Stack(alignment: Alignment.center, children: [
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
        ]),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: DeliveryColors.onlineGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: DeliveryColors.onlineGreen.withOpacity(0.25)),
        ),
        child: const Text(
          DeliveryStrings.systemOnline,
          style: TextStyle(
            color: DeliveryColors.onlineGreen,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    ]);
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
                  color: DeliveryColors.onlineGreen.withOpacity(0.5),
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
