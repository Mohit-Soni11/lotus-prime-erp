// ==========================================
// FILE: pos_app_bar.dart
// TYPE: Smart UI Component
// AUTHOR: Senior System Architect
// DESCRIPTION: Top navigation, Radar Status and System Badge.
//              ✅ Hover animation & Golden Glow added to Back Button.
//              🚀 FIXED: Smart Title Filter added to override old Parent titles.
// ==========================================

import 'package:flutter/material.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'system_login_badge.dart';
import '../../../repositories/setting/shop_setup/shop_session_manager.dart';
import '../../../repositories/setting/shop_setup/shop_setup_repository.dart';

class PosAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String userName;
  final String userRole;
  final String userInitials;
  final VoidCallback onBack;

  const PosAppBar({
    super.key,
    required this.title,
    required this.userName,
    required this.userRole,
    required this.userInitials,
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
            _shopDisplayName = data['basic_info']['display_name']?.toString() ?? "";
          });
        }
      }
    } catch (e) {
      debugPrint("AppBar Fetch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 SMART FILTER: Overriding the old hardcoded parent title
    String displayContext = widget.title.toUpperCase();
    if (displayContext.contains("POS TERMINAL") || displayContext.contains("LOTUS")) {
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
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _HoverBackButton(onTap: widget.onBack),
            const SizedBox(width: 20),
            _buildVerticalDivider(),
            const SizedBox(width: 20),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: SalesPosColors.brandGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: SalesPosColors.brandGold.withOpacity(0.6),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // 🚀 IDENTITY: Real Name from Database (e.g. RIYANSH JEWELLERS)
                    if (_shopDisplayName.isNotEmpty) ...[
                      Text(
                        _shopDisplayName.toUpperCase(),
                        style: SalesPosStyles.headerTitle.copyWith(
                          fontSize: 13,
                          color: SalesPosStyles.headerTitle.color?.withOpacity(0.7) ?? Colors.white70,
                          letterSpacing: 0.8,
                        ),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          "•",
                          style: TextStyle(color: SalesPosColors.brandGold, fontSize: 18),
                        ),
                      ),
                    ],
                    
                    // 🚀 CONTEXT: Forced to "NEW SALES" dynamically
                    Text(
                      displayContext, 
                      style: SalesPosStyles.headerTitle.copyWith(
                        fontSize: 17,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const RadarStatusWidget(),
              ],
            ),

            const Spacer(),

            SystemLoginBadge(
              userName: widget.userName,
              userRole: widget.userRole,
              userInitials: widget.userInitials,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
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
            curve: Curves.easeOut,
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SalesPosColors.bodyPanelBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered ? SalesPosColors.brandGold : SalesPosColors.bodyBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: SalesPosColors.brandGold.withOpacity(0.25), 
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  )
              ],
            ),
            child: Icon(
              Icons.arrow_back_rounded, 
              color: _isHovered ? SalesPosColors.brandGold : SalesPosColors.textDark,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

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
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
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
    return Row(
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
                  color: SalesPosColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SalesPosColors.success,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: SalesPosColors.success.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SalesPosColors.success.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Text(
            "SYSTEM ONLINE", 
            style: TextStyle(
              color: SalesPosColors.success,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
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
                  color: SalesPosColors.success.withOpacity(0.5),
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