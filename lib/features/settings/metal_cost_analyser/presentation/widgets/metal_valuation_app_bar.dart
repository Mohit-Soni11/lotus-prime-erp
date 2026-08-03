import 'package:flutter/material.dart';

import 'metal_valuation_tokens.dart';

class MetalValuationAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;

  const MetalValuationAppBar({
    super.key,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<MetalValuationAppBar> createState() => _MetalValuationAppBarState();
}

class _MetalValuationAppBarState extends State<MetalValuationAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _statusController;

  @override
  void initState() {
    super.initState();
    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: MetalValuationColors.shell,
        border: Border(
          bottom: BorderSide(color: MetalValuationColors.shellBorder),
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
            _ShellIconButton(
              tooltip: 'Back',
              icon: Icons.arrow_back_rounded,
              onTap: widget.onBack,
            ),
            const SizedBox(width: 18),
            Container(
              width: 1,
              height: 32,
              color: MetalValuationColors.shellBorder,
            ),
            const SizedBox(width: 18),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF7D65A),
                    MetalValuationColors.goldDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: MetalValuationColors.gold.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 14),
            Text('METAL VALUATION DESK', style: MetalValuationText.shellTitle),
            const Spacer(),
            _OnlineBadge(controller: _statusController),
          ],
        ),
      ),
    );
  }
}

class _ShellIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _ShellIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ShellIconButton> createState() => _ShellIconButtonState();
}

class _ShellIconButtonState extends State<_ShellIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
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
                  ? const Color(0xFF111827)
                  : MetalValuationColors.shellBorder.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered
                    ? MetalValuationColors.gold
                    : MetalValuationColors.shellBorder,
              ),
            ),
            child: Icon(
              widget.icon,
              color: _hovered ? MetalValuationColors.gold : Colors.white,
              size: 20,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MetalValuationColors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: MetalValuationColors.green.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _Pulse(controller: controller, delay: 0),
                _Pulse(controller: controller, delay: 0.5),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: MetalValuationColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SYSTEM ONLINE',
            style: MetalValuationText.label.copyWith(
              color: MetalValuationColors.green,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pulse extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _Pulse({required this.controller, required this.delay});

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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: MetalValuationColors.green.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
