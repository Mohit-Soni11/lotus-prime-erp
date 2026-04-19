// =============================================================================
// FILE        : cash_book_app_bar.dart
// MODULE      : Accounts / Cash Book
// LAYER       : UI
// DESCRIPTION : Dark-shell AppBar — matches Purchase Entry & Sales POS pattern.
//               ✅ Radar-blink live indicator
//               ✅ Gold hover back button
//               ✅ Shop name from session
//               ✅ Sync button + PDF export
//               ✅ Add Entry FAB-style button
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/finance/cash_book/cash_book_theme.dart';
import '../../../logic/finance/cash_book/cash_book_controller.dart';
import '../../../repositories/setting/shop_setup/shop_session_manager.dart';
import '../../../repositories/setting/shop_setup/shop_setup_repository.dart';

class CashBookAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback        onBack;
  final CashBookController  ctrl;
  final VoidCallback        onAddEntry;
  final VoidCallback        onSyncBills;

  const CashBookAppBar({
    super.key,
    required this.onBack,
    required this.ctrl,
    required this.onAddEntry,
    required this.onSyncBills,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  State<CashBookAppBar> createState() => _CashBookAppBarState();
}

class _CashBookAppBarState extends State<CashBookAppBar>
    with SingleTickerProviderStateMixin {

  String _shopName = '';
  late AnimationController _blinkCtrl;
  late Animation<double>   _blinkAnim;

  @override
  void initState() {
    super.initState();
    _fetchShopName();

    _blinkCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
  }

  Future<void> _fetchShopName() async {
    try {
      final tenantId = await ShopSessionManager.getPermanentTenantId();
      final data     = await ShopSetupRepository().fetchExistingSetup(tenantId);
      if (data != null && data['basic_info'] != null && mounted) {
        setState(() {
          _shopName = data['basic_info']['display_name']?.toString() ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      height:  70.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: CashBookColors.shellPanel,
        border: Border(
          bottom: BorderSide(color: CashBookColors.shellBorder, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [

            // ── Back Button ────────────────────────────────────────────────
            _HoverBackButton(onTap: widget.onBack),
            const SizedBox(width: 16),

            // ── Vertical Divider ───────────────────────────────────────────
            _vertDivider(),
            const SizedBox(width: 16),

            // ── Module Icon + Title ────────────────────────────────────────
            Container(
              width:  36,
              height: 36,
              decoration: BoxDecoration(
                color:        CashBookColors.brandGoldLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CashBookColors.brandGold.withOpacity(0.3)),
              ),
              child: const Icon(
                CashBookIcons.moduleIcon,
                color: CashBookColors.brandGold,
                size:  18,
              ),
            ),
            const SizedBox(width: 12),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(CashBookStrings.moduleTitle,   style: CashBookStyles.appBarTitle),
                if (_shopName.isNotEmpty)
                  Text(_shopName, style: TextStyle(
                    fontSize:   11,
                    color:      CashBookColors.shellMuted,
                    fontWeight: FontWeight.w500,
                  )),
              ],
            ),

            const Spacer(),

            // ── Live Indicator ─────────────────────────────────────────────
            AnimatedBuilder(
              animation: _blinkAnim,
              builder: (_, __) => Opacity(
                opacity: _blinkAnim.value,
                child: Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(
                      color: CashBookColors.incomeAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('LIVE', style: TextStyle(
                    fontSize:      10,
                    fontWeight:    FontWeight.w800,
                    color:         CashBookColors.incomeAccent,
                    letterSpacing: 1.2,
                  )),
                ]),
              ),
            ),

            const SizedBox(width: 20),

            // ── Sync Bills Button ──────────────────────────────────────────
            _AppBarIconBtn(
              icon:    CashBookIcons.sync,
              tooltip: CashBookStrings.syncBills,
              onTap:   widget.onSyncBills,
            ),
            const SizedBox(width: 8),

            // ── Add Entry Button ───────────────────────────────────────────
            GestureDetector(
              onTap: widget.onAddEntry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:        CashBookColors.brandGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(CashBookIcons.addEntry, size: 16, color: Color(0xFF111827)),
                  const SizedBox(width: 6),
                  Text('Add Entry', style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w800,
                    color:      const Color(0xFF111827),
                  )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vertDivider() => Container(
    width: 1, height: 30,
    color: CashBookColors.shellBorder,
  );
}

// ── Hover Back Button ─────────────────────────────────────────────────────────

class _HoverBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverBackButton({required this.onTap});

  @override
  State<_HoverBackButton> createState() => _HoverBackButtonState();
}

class _HoverBackButtonState extends State<_HoverBackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter:  (_) => setState(() => _hovered = true),
      onExit:   (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width:  36, height: 36,
          decoration: BoxDecoration(
            color:        _hovered
                ? CashBookColors.brandGoldLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? CashBookColors.brandGold.withOpacity(0.4)
                  : CashBookColors.shellBorder,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size:  16,
            color: _hovered
                ? CashBookColors.brandGold
                : CashBookColors.shellMuted,
          ),
        ),
      ),
    );
  }
}

// ── Icon Button ────────────────────────────────────────────────────────────────

class _AppBarIconBtn extends StatefulWidget {
  final IconData icon;
  final String   tooltip;
  final VoidCallback onTap;
  const _AppBarIconBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_AppBarIconBtn> createState() => _AppBarIconBtnState();
}

class _AppBarIconBtnState extends State<_AppBarIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter:  (_) => setState(() => _hovered = true),
        onExit:   (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color:        _hovered
                  ? CashBookColors.brandGoldLight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered
                    ? CashBookColors.brandGold.withOpacity(0.4)
                    : CashBookColors.shellBorder,
              ),
            ),
            child: Icon(widget.icon, size: 18, color: CashBookColors.shellMuted),
          ),
        ),
      ),
    );
  }
}
