import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/girvi/girvi_theme.dart';

class GirviListAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;

  const GirviListAppBar({
    super.key,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<GirviListAppBar> createState() => _GirviListAppBarState();
}

class _GirviListAppBarState extends State<GirviListAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: GirviColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: GirviColors.shellBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: GirviColors.shadowMedium,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _LedgerBackButton(onTap: widget.onBack),
            const SizedBox(width: 18),
            const _AppBarDivider(),
            const SizedBox(width: 18),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    GirviColors.goldGradientStart,
                    GirviColors.brandGold,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: GirviColors.brandGold.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                GirviIcons.list,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GirviStrings.listTitle,
                  style: GirviStyles.shellTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Loan control register',
                  style: GirviStyles.shellMuted,
                ),
              ],
            ),
            const Spacer(),
            _SystemStatusBadge(controller: _pulseController),
          ],
        ),
      ),
    );
  }
}

class _LedgerBackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _LedgerBackButton({required this.onTap});

  @override
  State<_LedgerBackButton> createState() => _LedgerBackButtonState();
}

class _LedgerBackButtonState extends State<_LedgerBackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered
                ? GirviColors.shellBg
                : GirviColors.shellBorder.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? GirviColors.brandGold : GirviColors.shellBorder,
            ),
          ),
          child: Icon(
            GirviIcons.backArrow,
            color:
                _hovered ? GirviColors.brandGold : GirviColors.shellTextTitle,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _AppBarDivider extends StatelessWidget {
  const _AppBarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: GirviColors.shellBorder.withValues(alpha: 0.75),
    );
  }
}

class _SystemStatusBadge extends StatelessWidget {
  final AnimationController controller;

  const _SystemStatusBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: GirviColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: GirviColors.onlineGreen.withValues(alpha: 0.24),
        ),
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
                _PulseRing(controller: controller, delay: 0),
                _PulseRing(controller: controller, delay: 0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: GirviColors.onlineGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            GirviStrings.systemOnline,
            style: GoogleFonts.inter(
              color: GirviColors.onlineGreen,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _PulseRing({
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final value = (controller.value + delay) % 1.0;
        return Opacity(
          opacity: 1 - value,
          child: Transform.scale(
            scale: 1 + (value * 1.45),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: GirviColors.onlineGreen.withValues(alpha: 0.46),
                  width: 1.4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
