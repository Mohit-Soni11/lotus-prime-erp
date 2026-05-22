// =============================================================================
// FILE        : lib/ui/settings/metal_rate/metal_rate_app_bar.dart
// MODULE      : Metal Rate Setting
// LAYER       : UI / Shared
// DESCRIPTION : Reusable premium shell app bar with live status animation.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../theme/settings/metal_rate/metal_rate_theme.dart';

class MetalRateAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String screenTitle;
  final VoidCallback onBack;

  const MetalRateAppBar({
    super.key,
    required this.screenTitle,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(MetalRateStyles.appBarHeight);

  @override
  State<MetalRateAppBar> createState() => _MetalRateAppBarState();
}

class _MetalRateAppBarState extends State<MetalRateAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MetalRateStyles.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: MetalRateStyles.shellDecoration,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _HoverBackButton(onTap: widget.onBack),
            const SizedBox(width: 18),
            const _VerticalDivider(),
            const SizedBox(width: 18),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [MetalRateColors.gold, MetalRateColors.teal],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: MetalRateColors.gold.withValues(alpha: 0.42),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                MetalRateIcons.moduleIcon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                widget.screenTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MetalRateStyles.appBarTitle,
              ),
            ),
            const Spacer(),
            _RadarStatus(controller: _pulseCtrl),
          ],
        ),
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
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? MetalRateColors.shellBg
                  : MetalRateColors.shellBorder.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered
                    ? MetalRateColors.gold
                    : MetalRateColors.shellBorder,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color: MetalRateColors.gold.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(
              MetalRateIcons.backArrow,
              color: _hovered
                  ? MetalRateColors.gold
                  : MetalRateColors.shellTextTitle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

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
            MetalRateColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _RadarStatus extends StatelessWidget {
  final AnimationController controller;

  const _RadarStatus({required this.controller});

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
              _Wave(controller: controller, delay: 0),
              _Wave(controller: controller, delay: 0.5),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: MetalRateColors.onlineGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MetalRateColors.onlineGreen,
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
            color: MetalRateColors.onlineGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: MetalRateColors.onlineGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            MetalRateStrings.systemOnline,
            style: MetalRateStyles.systemOnline,
          ),
        ),
      ],
    );
  }
}

class _Wave extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _Wave({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final value = (controller.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - value,
          child: Transform.scale(
            scale: 1.0 + (value * 1.5),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: MetalRateColors.onlineGreen.withValues(alpha: 0.5),
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
