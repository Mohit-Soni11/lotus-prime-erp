// =============================================================================
// FILE        : purchase_entry_app_bar.dart
// MODULE      : Purchase Entry
// LAYER       : UI
// DESCRIPTION : Dark-shell AppBar matching Sales POS design language.
//               ✅ Radar blink animation
//               ✅ Gold hover back button
//               ✅ Shop name from DB
//               ✅ System Login Badge
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_session_manager.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_setup_repository.dart';
import 'package:lotus_erp/ui/sales%20%26%20orders/sales_pos/system_login_badge.dart';

class PurchaseEntryAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;

  const PurchaseEntryAppBar({super.key, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  State<PurchaseEntryAppBar> createState() => _PurchaseEntryAppBarState();
}

class _PurchaseEntryAppBarState extends State<PurchaseEntryAppBar> {
  String _shopName = '';

  @override
  void initState() {
    super.initState();
    _fetchShopName();
  }

  Future<void> _fetchShopName() async {
    try {
      final tenantId = await ShopSessionManager.getPermanentTenantId();
      final repo     = ShopSetupRepository();
      final data     = await repo.fetchExistingSetup(tenantId);
      if (data != null && data['basic_info'] != null && mounted) {
        setState(() {
          _shopName = data['basic_info']['display_name']?.toString() ?? '';
        });
      }
    } catch (e) {
      debugPrint('PurchaseAppBar fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.shellPanel,
        border: const Border(
          bottom: BorderSide(color: PurchaseEntryColors.shellBorder, width: 1),
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
            _verticalDivider(),
            const SizedBox(width: 20),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Purchase accent dot (sky blue — different from gold Sales dot)
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        color: PurchaseEntryColors.purchaseAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: PurchaseEntryColors.purchaseAccent.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    if (_shopName.isNotEmpty) ...[
                      Text(
                        _shopName.toUpperCase(),
                        style: PurchaseEntryStyles.headerTitle.copyWith(
                          fontSize: 13,
                          color: PurchaseEntryStyles.headerTitle.color?.withOpacity(0.7),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: PurchaseEntryColors.brandGold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],

                    Text(
                      PurchaseEntryStrings.screenTitle,
                      style: PurchaseEntryStyles.headerTitle.copyWith(
                        fontSize: 17,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const _RadarStatusWidget(),
              ],
            ),

            const Spacer(),

            SystemLoginBadge(
              userName: 'System Admin',
              userRole: 'Owner',
              userInitials: 'SA',
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() => Container(
        width: 1,
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

// ── Hover Back Button ────────────────────────────────────────────────────────
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
      onExit:  (_) => setState(() => _isHovered = false),
      cursor:  SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale:    _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve:    Curves.easeOutBack,
          child: AnimatedContainer(
            duration:  const Duration(milliseconds: 250),
            curve:     Curves.easeOut,
            width: 42, height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:         PurchaseEntryColors.bodyPanel,
              borderRadius:  BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? PurchaseEntryColors.brandGold
                    : PurchaseEntryColors.bodyBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color:      PurchaseEntryColors.brandGold.withOpacity(0.25),
                    blurRadius: 12,
                    offset:     const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(
              PurchaseEntryIcons.backArrow,
              color: _isHovered
                  ? PurchaseEntryColors.brandGold
                  : PurchaseEntryColors.textDark,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Radar Status Widget ──────────────────────────────────────────────────────
class _RadarStatusWidget extends StatefulWidget {
  const _RadarStatusWidget();
  @override
  State<_RadarStatusWidget> createState() => _RadarStatusWidgetState();
}

class _RadarStatusWidgetState extends State<_RadarStatusWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _ctrl.stop();
    } else if (state == AppLifecycleState.resumed) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14, height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _wave(0.0),
              _wave(0.5),
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: PurchaseEntryColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: PurchaseEntryColors.success,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: PurchaseEntryColors.success.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: PurchaseEntryColors.success.withOpacity(0.2),
            ),
          ),
          child: const Text(
            PurchaseEntryStrings.systemOnline,
            style: TextStyle(
              color: PurchaseEntryColors.success,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _wave(double delay) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final v = (_ctrl.value + delay) % 1.0;
        return Opacity(
          opacity: 1.0 - v,
          child: Transform.scale(
            scale: 1.0 + v * 1.5,
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: PurchaseEntryColors.success.withOpacity(0.5),
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
