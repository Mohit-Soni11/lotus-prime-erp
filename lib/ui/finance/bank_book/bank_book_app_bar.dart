// =============================================================================
// FILE        : bank_book_app_bar.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : UI
// DESCRIPTION : Dark-shell AppBar — matches Cash Book & Sales POS pattern.
//               ✅ Radar-blink live indicator
//               ✅ Gold hover back button
//               ✅ Shop name from session
//               ✅ Sync button + Add Entry button
//               ✅ Add Account button
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/finance/bank_book/bank_book_theme.dart';
import '../../../logic/finance/bank_book/bank_book_controller.dart';
import '../../../repositories/setting/shop_setup/shop_session_manager.dart';
import '../../../repositories/setting/shop_setup/shop_setup_repository.dart';

class BankBookAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback       onBack;
  final BankBookController ctrl;
  final VoidCallback       onAddEntry;
  final VoidCallback       onSyncBills;
  final VoidCallback       onAddAccount;

  const BankBookAppBar({
    super.key,
    required this.onBack,
    required this.ctrl,
    required this.onAddEntry,
    required this.onSyncBills,
    required this.onAddAccount,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  State<BankBookAppBar> createState() => _BankBookAppBarState();
}

class _BankBookAppBarState extends State<BankBookAppBar>
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
        color: BankBookColors.shellPanel,
        border: Border(
          bottom: BorderSide(color: BankBookColors.shellBorder, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [

            // ── Back Button ─────────────────────────────────────────────────
            _HoverBackButton(onTap: widget.onBack),
            const SizedBox(width: 16),

            // ── Vertical Divider ────────────────────────────────────────────
            _vertDivider(),
            const SizedBox(width: 16),

            // ── Module Icon + Title ─────────────────────────────────────────
            Container(
              width:  36,
              height: 36,
              decoration: BoxDecoration(
                color:        BankBookColors.brandGoldLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: BankBookColors.brandGold.withOpacity(0.3)),
              ),
              child: const Icon(
                BankBookIcons.moduleIcon,
                color: BankBookColors.brandGold,
                size:  18,
              ),
            ),
            const SizedBox(width: 12),

            Column(
              mainAxisAlignment:  MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(BankBookStrings.moduleTitle, style: BankBookStyles.appBarTitle),
                if (_shopName.isNotEmpty)
                  Text(_shopName, style: const TextStyle(
                    fontSize:   11,
                    color:      BankBookColors.shellMuted,
                    fontWeight: FontWeight.w500,
                  )),
              ],
            ),

            const Spacer(),

            // ── Live Indicator ──────────────────────────────────────────────
            AnimatedBuilder(
              animation: _blinkAnim,
              builder: (_, __) => Opacity(
                opacity: _blinkAnim.value,
                child: Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(
                      color: BankBookColors.creditAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('LIVE', style: TextStyle(
                    fontSize:      10,
                    fontWeight:    FontWeight.w800,
                    color:         BankBookColors.creditAccent,
                    letterSpacing: 1.2,
                  )),
                ]),
              ),
            ),

            const SizedBox(width: 20),

            // ── Add Account Button ──────────────────────────────────────────
            _AppBarIconBtn(
              icon:    BankBookIcons.addAccount,
              tooltip: BankBookStrings.addAccount,
              onTap:   widget.onAddAccount,
            ),
            const SizedBox(width: 8),

            // ── Sync Button ─────────────────────────────────────────────────
            _AppBarIconBtn(
              icon:    BankBookIcons.sync,
              tooltip: BankBookStrings.syncBills,
              onTap:   widget.onSyncBills,
            ),
            const SizedBox(width: 8),

            // ── Add Entry Button ────────────────────────────────────────────
            GestureDetector(
              onTap: widget.onAddEntry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:        BankBookColors.brandGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(BankBookIcons.addEntry, size: 16, color: Color(0xFF111827)),
                  SizedBox(width: 6),
                  Text('Add Entry', style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w800,
                    color:      Color(0xFF111827),
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
    width: 1, height: 30, color: BankBookColors.shellBorder);
}

// ── Hover Back Button ──────────────────────────────────────────────────────────

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
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _hovered
                ? BankBookColors.brandGoldLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? BankBookColors.brandGold.withOpacity(0.4)
                  : BankBookColors.shellBorder,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size:  16,
            color: _hovered
                ? BankBookColors.brandGold
                : BankBookColors.shellMuted,
          ),
        ),
      ),
    );
  }
}

// ── Icon Button ────────────────────────────────────────────────────────────────

class _AppBarIconBtn extends StatefulWidget {
  final IconData     icon;
  final String       tooltip;
  final VoidCallback onTap;
  const _AppBarIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

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
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _hovered
                  ? BankBookColors.brandGoldLight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered
                    ? BankBookColors.brandGold.withOpacity(0.4)
                    : BankBookColors.shellBorder,
              ),
            ),
            child: Icon(widget.icon,
                size: 18, color: BankBookColors.shellMuted),
          ),
        ),
      ),
    );
  }
}