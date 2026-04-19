// =============================================================================
// FILE        : booking_advance_app_bar.dart
// MODULE      : Sales → Booking & Advance
// DESCRIPTION : Dark shell AppBar — exact same as PosAppBar.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';

class BookingAdvanceAppBar extends StatelessWidget implements PreferredSizeWidget {
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
        child: Row(children: [
          _HoverBackButton(onTap: onBack),
          const SizedBox(width: 18),
          _divider(),
          const SizedBox(width: 18),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [BookingAdvanceColors.goldGradientStart, BookingAdvanceColors.brandGold],
                    ),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [BoxShadow(color: BookingAdvanceColors.brandGold.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(BookingAdvanceIcons.moduleIcon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Text(BookingAdvanceStrings.appBarTitle, style: BookingAdvanceStyles.headerTitle),
              ]),
              const SizedBox(height: 5),
              const _RadarWidget(),
            ],
          ),
          const Spacer(),
        ]),
      ),
    );
  }

  Widget _divider() => Container(
    width: 1, height: 32,
    decoration: const BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Colors.transparent, BookingAdvanceColors.shellBorder, Colors.transparent],
    )),
  );
}

class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});
  @override State<_HoverBackButton> createState() => _HoverBackButtonState();
}
class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _h = false;
  @override Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(scale: _h ? 1.05 : 1.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOutBack,
          child: AnimatedContainer(duration: const Duration(milliseconds: 220), width: 42, height: 42, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _h ? BookingAdvanceColors.shellBg : BookingAdvanceColors.shellBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _h ? BookingAdvanceColors.brandGold : BookingAdvanceColors.shellBorder, width: _h ? 1.5 : 1.0),
              boxShadow: _h ? [BoxShadow(color: BookingAdvanceColors.brandGold.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 3))] : [],
            ),
            child: Icon(BookingAdvanceIcons.backArrow,
              color: _h ? BookingAdvanceColors.brandGold : BookingAdvanceColors.shellTextTitle, size: 18),
          )),
      ),
    );
  }
}

class _RadarWidget extends StatefulWidget {
  const _RadarWidget();
  @override State<_RadarWidget> createState() => _RadarWidgetState();
}
class _RadarWidgetState extends State<_RadarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 14, height: 14, child: Stack(alignment: Alignment.center, children: [
        _wave(0.0), _wave(0.5),
        Container(width: 6, height: 6, decoration: const BoxDecoration(
          color: BookingAdvanceColors.onlineGreen, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: BookingAdvanceColors.onlineGreen, blurRadius: 6, spreadRadius: 1)])),
      ])),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: BookingAdvanceColors.onlineGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BookingAdvanceColors.onlineGreen.withOpacity(0.25)),
        ),
        child: const Text(BookingAdvanceStrings.systemOnline,
          style: TextStyle(color: BookingAdvanceColors.onlineGreen, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ),
    ]);
  }
  Widget _wave(double delay) {
    return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
      final v = (_ctrl.value + delay) % 1.0;
      return Opacity(opacity: 1.0 - v, child: Transform.scale(scale: 1.0 + (v * 1.5),
        child: Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: BookingAdvanceColors.onlineGreen.withOpacity(0.5), width: 1.5)))));
    });
  }
}