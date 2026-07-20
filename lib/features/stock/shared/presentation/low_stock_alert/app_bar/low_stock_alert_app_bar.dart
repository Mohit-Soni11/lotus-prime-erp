import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockAlertAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final String title;
  final IconData icon;

  const LowStockAlertAppBar({
    super.key,
    required this.onBack,
    required this.onRefresh,
    this.title = 'LOW STOCK ALERTS',
    this.icon = Icons.notification_important_rounded,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<LowStockAlertAppBar> createState() => _LowStockAlertAppBarState();
}

class _LowStockAlertAppBarState extends State<LowStockAlertAppBar>
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
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: InvColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: InvColors.shellBorder),
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
            _ShellButton(icon: Icons.arrow_back_rounded, onTap: widget.onBack),
            const SizedBox(width: 18),
            const _Divider(),
            const SizedBox(width: 18),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: InvColors.brandGold,
                borderRadius: BorderRadius.circular(11),
                boxShadow: const [
                  BoxShadow(
                    color: InvColors.brandGoldGlow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              widget.title.toUpperCase(),
              style: InvStyles.shellTitle.copyWith(
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            _ShellButton(icon: Icons.refresh_rounded, onTap: widget.onRefresh),
            const SizedBox(width: 14),
            _OnlineBadge(pulse: _pulse),
          ],
        ),
      ),
    );
  }
}

class _ShellButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ShellButton({required this.icon, required this.onTap});

  @override
  State<_ShellButton> createState() => _ShellButtonState();
}

class _ShellButtonState extends State<_ShellButton> {
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1.5, height: 32, color: InvColors.shellBorder);
  }
}

class _OnlineBadge extends StatelessWidget {
  final AnimationController pulse;

  const _OnlineBadge({required this.pulse});

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
                _PulseWave(animation: pulse, delay: 0),
                _PulseWave(animation: pulse, delay: 0.5),
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
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseWave extends StatelessWidget {
  final Animation<double> animation;
  final double delay;

  const _PulseWave({required this.animation, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final value = (animation.value + delay) % 1.0;
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
