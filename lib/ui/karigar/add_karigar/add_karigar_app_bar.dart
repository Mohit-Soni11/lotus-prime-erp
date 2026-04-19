// =============================================================================
// FILE        : add_karigar_app_bar.dart
// MODULE      : Karigar → Add Karigar
// LAYER       : UI / Component
// DESCRIPTION : Dark shell AppBar for the Add Karigar screen.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/karigar/add_karigar/add_karigar_theme.dart';

class AddKarigarAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  const AddKarigarAppBar({super.key, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: AddKarigarStyles.shellDecoration,
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          _HoverBackButton(onTap: onBack),
          const SizedBox(width: 20),
          _Divider(),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    color: AddKarigarColors.brandGold,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: AddKarigarColors.brandGold.withOpacity(0.6),
                      blurRadius: 6,
                    )],
                  ),
                ),
                const SizedBox(width: 8),
                Text(AddKarigarStrings.screenTitle,
                    style: AddKarigarStyles.shellTitle),
              ]),
              const SizedBox(height: 5),
              const _RadarBadge(),
            ],
          ),
          const Spacer(),
          _ModuleBadge(),
        ]),
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
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 42, height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AddKarigarColors.shellBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? AddKarigarColors.brandGold : AddKarigarColors.shellBorder,
              width: _hovered ? 1.5 : 1.0,
            ),
            boxShadow: _hovered ? [BoxShadow(
              color: AddKarigarColors.brandGold.withOpacity(0.25),
              blurRadius: 12, offset: const Offset(0, 3),
            )] : [],
          ),
          child: Icon(
            AddKarigarIcons.backArrow,
            color: _hovered ? AddKarigarColors.brandGold : AddKarigarColors.shellTextTitle,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 32,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, AddKarigarColors.shellBorder, Colors.transparent],
      ),
    ),
  );
}

class _RadarBadge extends StatefulWidget {
  const _RadarBadge();
  @override
  State<_RadarBadge> createState() => _RadarBadgeState();
}

class _RadarBadgeState extends State<_RadarBadge>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) _ac.stop();
    else if (s == AppLifecycleState.resumed) _ac.repeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ac.dispose();
    super.dispose();
  }

  Widget _wave(double delay) => AnimatedBuilder(
    animation: _ac,
    builder: (_, __) {
      final v = (_ac.value + delay) % 1.0;
      return Opacity(
        opacity: 1.0 - v,
        child: Transform.scale(
          scale: 1.0 + v * 1.5,
          child: Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5), width: 1.5),
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 14, height: 14,
        child: Stack(alignment: Alignment.center, children: [
          _wave(0.0), _wave(0.5),
          Container(width: 6, height: 6,
            decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle)),
        ]),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF00E676).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00E676).withOpacity(0.2)),
        ),
        child: Text(AddKarigarStrings.systemOnline, style: GoogleFonts.inter(
          color: const Color(0xFF00E676), fontSize: 9.5,
          fontWeight: FontWeight.w700, letterSpacing: 0.8,
        )),
      ),
    ]);
  }
}

class _ModuleBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AddKarigarColors.moduleBadgeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AddKarigarColors.moduleBadgeBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AddKarigarColors.brandGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(AddKarigarIcons.moduleIcon,
              color: AddKarigarColors.brandGold, size: 14),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(AddKarigarStrings.moduleBadge, style: GoogleFonts.inter(
            color: AddKarigarColors.shellTextTitle, fontSize: 12,
            fontWeight: FontWeight.w700, letterSpacing: 0.3,
          )),
          Text(AddKarigarStrings.screenSub, style: GoogleFonts.inter(
            color: AddKarigarColors.shellTextMuted, fontSize: 10,
          )),
        ]),
      ]),
    );
  }
}
