import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/girvi/girvi_theme.dart';

class NoticeAuctionAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefreshTap;

  const NoticeAuctionAppBar({
    super.key,
    required this.onBack,
    required this.onRefreshTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<NoticeAuctionAppBar> createState() => _NoticeAuctionAppBarState();
}

class _NoticeAuctionAppBarState extends State<NoticeAuctionAppBar>
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
            _HeaderIconButton(
              icon: GirviIcons.backArrow,
              tooltip: 'Back',
              onTap: widget.onBack,
            ),
            const SizedBox(width: 18),
            _HeaderDivider(),
            const SizedBox(width: 18),
            Container(
              width: 34,
              height: 34,
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
                GirviIcons.warning,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              GirviStrings.noticeTitle.toUpperCase(),
              style: GirviStyles.shellTitle.copyWith(
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            _HeaderIconButton(
              icon: GirviIcons.refresh,
              tooltip: 'Refresh',
              onTap: widget.onRefreshTap,
            ),
            const SizedBox(width: 16),
            _HeaderDivider(),
            const SizedBox(width: 16),
            _OnlineBadge(controller: _pulseController),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered
                  ? GirviColors.shellBg
                  : GirviColors.shellBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    _hovered ? GirviColors.brandGold : GirviColors.shellBorder,
                width: _hovered ? 1.4 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: GirviColors.brandGold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              widget.icon,
              color:
                  _hovered ? GirviColors.brandGold : GirviColors.shellTextTitle,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.5,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            GirviColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  final AnimationController controller;

  const _OnlineBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GirviColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: GirviColors.onlineGreen.withValues(alpha: 0.3),
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
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
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
        final value = (controller.value + delay) % 1;
        return Opacity(
          opacity: 1 - value,
          child: Transform.scale(
            scale: 1 + value * 1.5,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: GirviColors.onlineGreen.withValues(alpha: 0.5),
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
