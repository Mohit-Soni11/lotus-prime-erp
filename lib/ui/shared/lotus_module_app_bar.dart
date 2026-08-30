import 'package:flutter/material.dart';

import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class LotusModuleAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final IconData icon;
  final String title;

  const LotusModuleAppBar({
    super.key,
    required this.onBack,
    required this.icon,
    required this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<LotusModuleAppBar> createState() => _LotusModuleAppBarState();
}

class _LotusModuleAppBarState extends State<LotusModuleAppBar>
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
      height: widget.preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellPanel,
        border: const Border(
          bottom: BorderSide(color: PurchaseEntryColors.shellBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _AppBarBackButton(onTap: widget.onBack),
            const SizedBox(width: 18),
            const _AppBarDivider(),
            const SizedBox(width: 18),
            _ModuleIcon(icon: widget.icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PurchaseEntryStyles.headerTitle.copyWith(
                  fontSize: 18,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 16),
            _SystemOnlineBadge(controller: _statusController),
          ],
        ),
      ),
    );
  }
}

class _AppBarBackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AppBarBackButton({required this.onTap});

  @override
  State<_AppBarBackButton> createState() => _AppBarBackButtonState();
}

class _AppBarBackButtonState extends State<_AppBarBackButton> {
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
                  ? PurchaseEntryColors.shellBg
                  : PurchaseEntryColors.shellBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? PurchaseEntryColors.brandGold
                    : PurchaseEntryColors.shellBorder,
                width: _isHovered ? 1.5 : 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: PurchaseEntryColors.brandGold
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: _isHovered
                  ? PurchaseEntryColors.brandGold
                  : PurchaseEntryColors.shellTitle,
              size: 20,
            ),
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
      width: 1.5,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            PurchaseEntryColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _ModuleIcon extends StatelessWidget {
  final IconData icon;

  const _ModuleIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PurchaseEntryColors.goldGradStart,
            PurchaseEntryColors.brandGold,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: PurchaseEntryColors.brandGold.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _SystemOnlineBadge extends StatelessWidget {
  final AnimationController controller;

  const _SystemOnlineBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: PurchaseEntryColors.onlineGreen.withValues(alpha: 0.3),
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
                _StatusWave(controller: controller, delay: 0),
                _StatusWave(controller: controller, delay: 0.5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: PurchaseEntryColors.onlineGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: PurchaseEntryColors.onlineGreen,
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
          const Text(
            'SYSTEM ONLINE',
            style: PurchaseEntryStyles.systemOnlineText,
          ),
        ],
      ),
    );
  }
}

class _StatusWave extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _StatusWave({
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
          opacity: 1.0 - value,
          child: Transform.scale(
            scale: 1.0 + value * 1.5,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: PurchaseEntryColors.onlineGreen.withValues(alpha: 0.5),
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
