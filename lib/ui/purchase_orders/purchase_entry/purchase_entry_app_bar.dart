// =============================================================================
// FILE        : purchase_entry_app_bar.dart
// MODULE      : Purchase Entry
// LAYER       : UI
// DESCRIPTION : Dark-shell AppBar matching Sales POS design language.
//               âœ… Removed System Login Badge
//               âœ… Added correct Purchase premium gradient icon
//               âœ… Updated positioning and System Online Radar with neon green
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_session_manager.dart';
import 'package:lotus_erp/repositories/setting/shop_setup/shop_setup_repository.dart';
import '../../../core/logging/app_logger.dart';

class PurchaseEntryAppBar extends StatefulWidget
    implements PreferredSizeWidget {
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
      final repo = ShopSetupRepository();
      final data = await repo.fetchExistingSetup(tenantId);
      if (data != null && data['basic_info'] != null && mounted) {
        setState(() {
          _shopName = data['basic_info']['display_name']?.toString() ?? '';
        });
      }
    } catch (e) {
      AppLogger.debug('PurchaseAppBar fetch error: $e');
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
            // â”€â”€ 1. Hover Back Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _HoverBackButton(onTap: widget.onBack),
            const SizedBox(width: 18),

            // â”€â”€ 2. Vertical Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _verticalDivider(),
            const SizedBox(width: 18),

            // â”€â”€ 3. Premium Gradient Module Icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
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
              child: const Icon(
                PurchaseEntryIcons.purchaseHeader, // Correct Purchase Icon
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),

            // â”€â”€ 4. Perfectly Aligned Main Title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_shopName.isNotEmpty) ...[
              Text(
                _shopName.toUpperCase(),
                style: PurchaseEntryStyles.headerTitle.copyWith(
                  fontSize: 14,
                  color: PurchaseEntryStyles.headerTitle.color
                          ?.withValues(alpha: 0.8) ??
                      Colors.white70,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  'â€¢',
                  style: TextStyle(
                    color: PurchaseEntryColors.brandGold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],

            Text(
              PurchaseEntryStrings.screenTitle,
              style: PurchaseEntryStyles.headerTitle,
            ),

            // Spacer pushes everything else to the right
            const Spacer(),

            // â”€â”€ 5. System Online Radar Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const _RadarStatusWidget(),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() => Container(
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

// â”€â”€ Hover Back Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
              color: _isHovered
                  ? PurchaseEntryColors.shellBg
                  : PurchaseEntryColors.shellBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? PurchaseEntryColors.brandGold
                    : PurchaseEntryColors.shellBorder,
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color:
                        PurchaseEntryColors.brandGold.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(
              PurchaseEntryIcons.backArrow,
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

// â”€â”€ Radar Status Widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.onlineGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30), // Pill shape
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
                _wave(0.0),
                _wave(0.5),
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
            PurchaseEntryStrings.systemOnline,
            style: PurchaseEntryStyles.systemOnlineText,
          ),
        ],
      ),
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
