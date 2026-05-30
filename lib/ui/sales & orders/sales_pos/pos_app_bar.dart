// ==========================================
// FILE: pos_app_bar.dart
// TYPE: Smart UI Component
// AUTHOR: Senior System Architect
// DESCRIPTION: Top navigation, Radar Status and System Badge.
//               Premium layout with branded icon treatment.
//               Removed System Admin Login Badge.
//               Perfectly positioned Shop Name & New Sales Title.
// ==========================================

import 'package:flutter/material.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../repositories/setting/shop_setup/shop_session_manager.dart';
import '../../../repositories/setting/shop_setup/shop_setup_repository.dart';

class PosAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const PosAppBar({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  State<PosAppBar> createState() => _PosAppBarState();
}

class _PosAppBarState extends State<PosAppBar> {
  String _shopDisplayName = "";

  @override
  void initState() {
    super.initState();
    _fetchShopName();
  }

  Future<void> _fetchShopName() async {
    try {
      final String tenantId = await ShopSessionManager.getPermanentTenantId();
      final repo = ShopSetupRepository();
      final data = await repo.fetchExistingSetup(tenantId);

      if (data != null && data['basic_info'] != null) {
        if (mounted) {
          setState(() {
            _shopDisplayName =
                data['basic_info']['display_name']?.toString() ?? "";
          });
        }
      }
    } catch (e) {
      debugPrint("AppBar Fetch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    //  Use the contextual title for this POS screen.
    String displayContext = widget.title.toUpperCase();
    if (displayContext.contains("POS TERMINAL") ||
        displayContext.contains("LOTUS")) {
      displayContext = "NEW SALES";
    }

    return Container(
      width: double.infinity,
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: SalesPosColors.shellPanelBg,
        border: const Border(
          bottom: BorderSide(
            color: SalesPosColors.shellBorder,
            width: 1,
          ),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //  1. Animated back button 
            _HoverBackButton(onTap: widget.onBack),
            const SizedBox(width: 18),

            //  2. Vertical Divider 
            _buildVerticalDivider(),
            const SizedBox(width: 18),

            //  3. Module icon for New Sales 
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SalesPosColors.goldGradientStart,
                    SalesPosColors.brandGold,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: SalesPosColors.brandGold.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(
                Icons
                    .point_of_sale_rounded, // Premium icon representing Sales/POS
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),

            //  4. Main title 
            if (_shopDisplayName.isNotEmpty) ...[
              Text(
                _shopDisplayName.toUpperCase(),
                style: SalesPosStyles.headerTitle.copyWith(
                  fontSize: 14,
                  color: SalesPosStyles.headerTitle.color
                          ?.withValues(alpha: 0.8) ??
                      Colors.white70,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  " - ",
                  style:
                      TextStyle(color: SalesPosColors.brandGold, fontSize: 18),
                ),
              ),
            ],

            Text(
              displayContext,
              style: SalesPosStyles.headerTitle,
            ),

            // Spacer pushes the radar widget to the far right side
            const Spacer(),

            //  5. System online status badge 
            const RadarStatusWidget(),
          ],
        ),
      ),
    );
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
            SalesPosColors.shellBorder,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// 
// HOVER BACK BUTTON
// 
class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});
  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
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
            duration: const Duration(milliseconds: 250),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered
                  ? SalesPosColors.shellBg
                  : SalesPosColors.shellBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? SalesPosColors.brandGold
                    : SalesPosColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: SalesPosColors.brandGold.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Icon(
              SalesPosIcons.backArrow,
              color: _isHovered
                  ? SalesPosColors.brandGold
                  : SalesPosColors.shellTextTitle,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// 
// RADAR STATUS (Updated to Match the Premium Pill Shape exactly)
// 
class RadarStatusWidget extends StatefulWidget {
  const RadarStatusWidget({super.key});
  @override
  State<RadarStatusWidget> createState() => _RadarStatusWidgetState();
}

class _RadarStatusWidgetState extends State<RadarStatusWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SalesPosColors.onlineIndicator.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30), // Pill Shape
        border: Border.all(
          color: SalesPosColors.onlineIndicator.withValues(alpha: 0.3),
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
                _buildWave(delay: 0.0, size: 14),
                _buildWave(delay: 0.5, size: 14),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: SalesPosColors.onlineIndicator,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SalesPosColors.onlineIndicator,
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "SYSTEM ONLINE",
            style: TextStyle(
              color: SalesPosColors.onlineIndicator,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWave({required double delay, required double size}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double currentVal = (_controller.value + delay) % 1.0;
        final double scale = 1.0 + (currentVal * 1.5);
        final double opacity = 1.0 - currentVal;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SalesPosColors.onlineIndicator.withValues(alpha: 0.5),
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
