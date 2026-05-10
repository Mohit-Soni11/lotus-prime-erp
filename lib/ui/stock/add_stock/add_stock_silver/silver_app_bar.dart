// =============================================================================
// FILE        : silver_app_bar.dart
// MODULE      : Stock & Inventory (Silver)
// LAYER       : UI / Components
// DESCRIPTION : Premium App Bar for Silver Stock module.
//               ✅ 100% Isolated Silver Theme.
//               ✅ Stepper Removed completely (Purity/Items/Save).
//               ✅ SYSTEM ONLINE green dot radar widget.
// =============================================================================

import 'package:flutter/material.dart';
import '/logic/stock/add_stock_controller.dart';
import '../../../../theme/stock/add_stock/add_stock_silver/silver_stock_theme.dart';

class SilverAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final AddStockController ctrl;

  const SilverAppBar({
    super.key,
    required this.onBack,
    required this.ctrl,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(70.0); // Strict 70px height, no stepper

  @override
  State<SilverAppBar> createState() => _SilverAppBarState();
}

class _SilverAppBarState extends State<SilverAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: SilverStockColors.shellBg,
        border: Border(
          bottom: BorderSide(
            color: SilverStockColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // ── BACK BUTTON ──
          _buildBackButton(),
          const SizedBox(width: 16),

          // ── TITLE ──
          Text(
            SilverStockStrings.headerTitle,
            style: SilverStockStyles.shellTitle,
          ),

          const Spacer(),

          // ── SYSTEM ONLINE RADAR ──
          _buildSystemOnlineBadge(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onBack,
        borderRadius: BorderRadius.circular(10),
        splashColor: SilverStockColors.brandSilver.withOpacity(0.2),
        highlightColor: SilverStockColors.brandSilver.withOpacity(0.1),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SilverStockColors.silverSurfaceBg.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: SilverStockColors.borderLight.withOpacity(0.2),
            ),
          ),
          child: const Icon(
            SilverStockIcons.backArrow,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSystemOnlineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: SilverStockColors.shellBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SilverStockColors.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildWave(0.0),
                _buildWave(0.5),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: SilverStockColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SilverStockColors.success,
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
          Text(
            SilverStockStrings.systemOnline,
            style: SilverStockStyles.tagLine.copyWith(
              color: SilverStockColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWave(double delay) {
    return AnimatedBuilder(
      animation: _blinkCtrl,
      builder: (_, __) {
        final val = (_blinkCtrl.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - val,
          child: Transform.scale(
            scale: 1.0 + (val * 1.5),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SilverStockColors.success.withOpacity(0.5),
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
