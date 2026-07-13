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
  Size get preferredSize => const Size.fromHeight(70);

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
    final title = _moduleTitle();
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: GoldStockColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(
            color: GoldStockColors.shellBorder,
            width: 1,
          ),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildBackButton(),
            const SizedBox(width: 18),
            _buildVerticalDivider(),
            const SizedBox(width: 18),
            _buildModuleIcon(),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoldStockStyles.shellTitle.copyWith(
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: _buildSystemOnlineBadge(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleIcon() {
    final tone = _moduleTone();
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withValues(alpha: 0.42),
            tone,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        _moduleIcon(),
        color: Colors.white,
        size: 18,
      ),
    );
  }

  String _moduleTitle() {
    final purity = widget.ctrl.purityDisplay.trim().toUpperCase();
    if (purity.isEmpty) {
      return GoldStockStrings.headerTitle;
    }

    final normalized = purity.replaceAll('KT', 'K');
    if (normalized.contains('24K') || normalized.contains('999')) {
      return '24KT Fine Gold Stock';
    }
    if (normalized.contains('22K') || normalized.contains('916')) {
      return '22KT Hallmark Gold Stock';
    }
    if (normalized.contains('18K') || normalized.contains('750')) {
      return '18KT Studded Gold Stock';
    }
    if (normalized.contains('14K') || normalized.contains('585')) {
      return '14KT Lightweight Gold Stock';
    }
    if (normalized.contains('9K') || normalized.contains('375')) {
      return '9KT Low Karat Gold Stock';
    }
    return '$purity Gold Stock';
  }

  IconData _moduleIcon() {
    final purity = widget.ctrl.purityDisplay.trim().toUpperCase();
    final normalized = purity.replaceAll('KT', 'K');
    if (normalized.contains('22K') || normalized.contains('916')) {
      return Icons.verified_rounded;
    }
    if (normalized.contains('18K') || normalized.contains('750')) {
      return Icons.diamond_rounded;
    }
    if (normalized.contains('14K') || normalized.contains('585')) {
      return Icons.auto_awesome_rounded;
    }
    if (normalized.contains('9K') || normalized.contains('375')) {
      return Icons.category_rounded;
    }
    if (purity.isNotEmpty &&
        !(normalized.contains('24K') || normalized.contains('999'))) {
      return Icons.tune_rounded;
    }
    return Icons.workspace_premium_rounded;
  }

  Color _moduleTone() {
    final purity = widget.ctrl.purityDisplay.trim().toUpperCase();
    final normalized = purity.replaceAll('KT', 'K');
    if (normalized.contains('18K') || normalized.contains('750')) {
      return const Color(0xFF2563EB);
    }
    if (normalized.contains('14K') || normalized.contains('585')) {
      return const Color(0xFF0F8A72);
    }
    if (normalized.contains('9K') || normalized.contains('375')) {
      return const Color(0xFF8B5CF6);
    }
    if (purity.isNotEmpty &&
        !(normalized.contains('24K') ||
            normalized.contains('999') ||
            normalized.contains('22K') ||
            normalized.contains('916'))) {
      return const Color(0xFF64748B);
    }
    return GoldStockColors.brandGold;
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1.5,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            GoldStockColors.shellBorder,
            Colors.transparent,
          ],
        ),
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
        color: GoldStockColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
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
