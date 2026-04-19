// -----------------------------------------------------------------------------
// FILE: supplier_list_app_bar.dart
// MODULE: Supplier → Supplier List
// DESCRIPTION: Dark shell app bar — identical pattern to CustomerListAppBar.
//              Animated back button + Radar status widget.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../../../theme/stock/supplier/supplier_list/supplier_list_theme.dart';

class SupplierListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final String shopName;

  const SupplierListAppBar({
    super.key,
    required this.onBack,
    this.shopName = SupplierListStrings.shopName,
  });

  @override
  Size get preferredSize => const Size.fromHeight(SupplierListStyles.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SupplierListStyles.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: SupplierListColors.shellPanelBg,
        border: Border(bottom: BorderSide(color: SupplierListColors.shellBorder, width: 1)),
        boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _HoverBackButton(onTap: onBack),
            const SizedBox(width: 20),
            _buildVerticalDivider(),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(SupplierListIcons.moduleIcon,
                        color: SupplierListColors.brandGold, size: 20),
                    const SizedBox(width: 8),
                    Text(SupplierListStrings.appBarTitle,
                        style: SupplierListStyles.appBarTitle),
                  ],
                ),
                const SizedBox(height: 5),
                const _RadarStatusWidget(),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() => Container(
    width: 1, height: 32,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, SupplierListColors.shellBorder, Colors.transparent],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Back Button
// ─────────────────────────────────────────────────────────────────────────────
class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});
  @override State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 42, height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered ? SupplierListColors.bodyPanelBg : SupplierListColors.shellBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered ? SupplierListColors.brandGold : SupplierListColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [BoxShadow(color: SupplierListColors.brandGold.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 3))]
                  : [],
            ),
            child: Icon(
              SupplierListIcons.backArrow,
              color: _isHovered ? SupplierListColors.brandGold : SupplierListColors.shellTextTitle,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Radar Animation
// ─────────────────────────────────────────────────────────────────────────────
class _RadarStatusWidget extends StatefulWidget {
  const _RadarStatusWidget();
  @override State<_RadarStatusWidget> createState() => _RadarStatusWidgetState();
}

class _RadarStatusWidgetState extends State<_RadarStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14, height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildWave(delay: 0.0),
              _buildWave(delay: 0.5),
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0xFF10B981), blurRadius: 6, spreadRadius: 1)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
          ),
          child: const Text(SupplierListStrings.systemOnline,
              style: SupplierListStyles.systemOnlineText),
        ),
      ],
    );
  }

  Widget _buildWave({required double delay}) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final val = (_ctrl.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - val,
          child: Transform.scale(
            scale: 1.0 + (val * 1.5),
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }
}