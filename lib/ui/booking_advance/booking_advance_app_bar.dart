// =============================================================================
// FILE        : booking_advance_app_bar.dart
// MODULE      : Sales â†’ Booking & Advance
// DESCRIPTION : Dark shell AppBar â€” premium layout with improved spacing.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';

class BookingAdvanceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  const BookingAdvanceAppBar({super.key, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BookingAdvanceStyles.shellPanel,
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _HoverBackButton(onTap: onBack),
            const SizedBox(width: 18),
            _divider(),
            const SizedBox(width: 18),

            // Logo Container
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BookingAdvanceColors.goldGradientStart,
                    BookingAdvanceColors.brandGold
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color:
                          BookingAdvanceColors.brandGold.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: const Icon(BookingAdvanceIcons.moduleIcon,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),

            // Main Title
            const Text(
              BookingAdvanceStrings.appBarTitle,
              style: BookingAdvanceStyles
                  .headerTitle, // Ensure this style has a good font weight and letter spacing
            ),

            // Spacer pushes the radar widget to the far right side
            const Spacer(),

            // System Online Status Badge
            const _RadarWidget(),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1.5,
        height: 32,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            BookingAdvanceColors.shellBorder,
            Colors.transparent
          ],
        )),
      );
}

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
                    ? BookingAdvanceColors.shellBg
                    : BookingAdvanceColors.shellBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _isHovered
                        ? BookingAdvanceColors.brandGold
                        : BookingAdvanceColors.shellBorder,
                    width: _isHovered ? 1.5 : 1.0),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                            color: BookingAdvanceColors.brandGold
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 3))
                      ]
                    : [],
              ),
              child: Icon(BookingAdvanceIcons.backArrow,
                  color: _isHovered
                      ? BookingAdvanceColors.brandGold
                      : BookingAdvanceColors.shellTextTitle,
                  size: 18),
            )),
      ),
    );
  }
}

class _RadarWidget extends StatefulWidget {
  const _RadarWidget();
  @override
  State<_RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<_RadarWidget>
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
        color: BookingAdvanceColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30), // More pill-like and smooth
        border: Border.all(
            color: BookingAdvanceColors.onlineGreen.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
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
                      color: BookingAdvanceColors.onlineGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: BookingAdvanceColors.onlineGreen,
                            blurRadius: 6,
                            spreadRadius: 1)
                      ])),
            ])),
        const SizedBox(width: 8),
        const Text(BookingAdvanceStrings.systemOnline,
            style: TextStyle(
                color: BookingAdvanceColors.onlineGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ]),
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
                              color: BookingAdvanceColors.onlineGreen
                                  .withValues(alpha: 0.5),
                              width: 1.5)))));
        });
  }
}
