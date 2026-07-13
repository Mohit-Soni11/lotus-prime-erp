// =============================================================================
// FILE        : Gold_app_bar.dart
// MODULE      : Stock & Inventory (Gold)
// LAYER       : UI / Components
// DESCRIPTION : Premium App Bar for Gold Stock module.
//               âœ… 100% Isolated Gold Theme.
//               âœ… Stepper Removed completely (Purity/Items/Save).
//               âœ… SYSTEM ONLINE green dot radar widget.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_gold/gold_stock_theme.dart';

class GoldAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final GoldStockController ctrl;

  const GoldAppBar({
    super.key,
    required this.onBack,
    required this.ctrl,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(70.0); // Strict 70px height, no stepper

  @override
  State<GoldAppBar> createState() => _GoldAppBarState();
}

class _GoldAppBarState extends State<GoldAppBar>
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
        color: GoldStockColors.shellBg,
        border: Border(
          bottom: BorderSide(
            color: GoldStockColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // â”€â”€ BACK BUTTON â”€â”€
          _buildBackButton(),
          const SizedBox(width: 16),

          // â”€â”€ TITLE â”€â”€
          Expanded(
            child: Text(
              GoldStockStrings.headerTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoldStockStyles.shellTitle,
            ),
          ),

          const SizedBox(width: 16),

          // â”€â”€ SYSTEM ONLINE RADAR â”€â”€
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: _buildSystemOnlineBadge(),
          ),
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
        splashColor: GoldStockColors.brandGold.withValues(alpha: 0.2),
        highlightColor: GoldStockColors.brandGold.withValues(alpha: 0.1),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GoldStockColors.goldSurfaceBg.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: GoldStockColors.borderLight.withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(
            GoldStockIcons.backArrow,
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
        color: GoldStockColors.shellBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GoldStockColors.success.withValues(alpha: 0.3),
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
                    color: GoldStockColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: GoldStockColors.success,
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
          Flexible(
            child: Text(
              GoldStockStrings.systemOnline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoldStockStyles.tagLine.copyWith(
                color: GoldStockColors.success,
                fontWeight: FontWeight.w800,
              ),
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
                  color: GoldStockColors.success.withValues(alpha: 0.5),
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
