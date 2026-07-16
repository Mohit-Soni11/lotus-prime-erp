part of '../stock_summary_screen.dart';

class _StockSummaryAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _StockSummaryAppBar({
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<_StockSummaryAppBar> createState() => _StockSummaryAppBarState();
}

class _StockSummaryAppBarState extends State<_StockSummaryAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: InvColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: InvColors.shellBorder, width: 1),
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
            _SummaryShellButton(
              icon: Icons.arrow_back_rounded,
              onTap: widget.onBack,
            ),
            const SizedBox(width: 18),
            _SummaryAppBarDivider(),
            const SizedBox(width: 18),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD76A), InvColors.brandGold],
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: InvColors.brandGold.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.dashboard_customize_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'STOCK SUMMARY',
              style: InvStyles.shellTitle.copyWith(
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            _SummaryShellButton(
              icon: Icons.refresh_rounded,
              onTap: widget.onRefresh,
            ),
            const SizedBox(width: 14),
            _SummaryOnlineBadge(pulse: _pulse),
          ],
        ),
      ),
    );
  }
}

class _SummaryShellButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryShellButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SummaryShellButton> createState() => _SummaryShellButtonState();
}

class _SummaryShellButtonState extends State<_SummaryShellButton> {
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
                ? InvColors.shellBg
                : InvColors.shellBorder.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _hovered ? InvColors.brandGold : InvColors.shellBorder,
              width: _hovered ? 1.5 : 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: _hovered ? InvColors.brandGold : InvColors.shellTextTitle,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _SummaryAppBarDivider extends StatelessWidget {
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
            InvColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _SummaryOnlineBadge extends StatelessWidget {
  final AnimationController pulse;

  const _SummaryOnlineBadge({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: InvColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: InvColors.onlineGreen.withValues(alpha: 0.3),
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
                _SummaryPulseWave(animation: pulse, delay: 0),
                _SummaryPulseWave(animation: pulse, delay: 0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: InvColors.onlineGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SYSTEM ONLINE',
            style: GoogleFonts.inter(
              color: InvColors.onlineGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPulseWave extends StatelessWidget {
  final AnimationController animation;
  final double delay;

  const _SummaryPulseWave({
    required this.animation,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final value = (animation.value + delay) % 1;
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
                  color: InvColors.onlineGreen.withValues(alpha: 0.5),
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
