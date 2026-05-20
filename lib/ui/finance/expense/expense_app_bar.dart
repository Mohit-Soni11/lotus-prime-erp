// =============================================================================
// FILE        : expense_app_bar.dart
// MODULE      : Expense Entry
// LAYER       : UI
// DESCRIPTION : Dark-shell AppBar â€” matches Cash Book & Purchase Entry pattern.
//               âœ… Radar-blink live indicator
//               âœ… Gold hover back button
//               âœ… Shop name from session
//               âœ… Sort dropdown + Add Expense CTA button
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/finance/expense/expense_theme.dart';
import '../../../logic/finance/expense/expense_controller.dart';
import '../../../models/finance/expense/expense_enums.dart';
import '../../../repositories/setting/shop_setup/shop_session_manager.dart';
import '../../../repositories/setting/shop_setup/shop_setup_repository.dart';

class ExpenseAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final ExpenseController ctrl;
  final VoidCallback onAddExpense;

  const ExpenseAppBar({
    super.key,
    required this.onBack,
    required this.ctrl,
    required this.onAddExpense,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  State<ExpenseAppBar> createState() => _ExpenseAppBarState();
}

class _ExpenseAppBarState extends State<ExpenseAppBar>
    with SingleTickerProviderStateMixin {
  String _shopName = '';
  late AnimationController _blinkCtrl;
  late Animation<double> _blinkAnim;

  @override
  void initState() {
    super.initState();
    _fetchShopName();

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
  }

  Future<void> _fetchShopName() async {
    try {
      final tenantId = await ShopSessionManager.getPermanentTenantId();
      final data = await ShopSetupRepository().fetchExistingSetup(tenantId);
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
      width: double.infinity,
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: const BoxDecoration(
        color: ExpenseColors.shellPanel,
        border: Border(
          bottom: BorderSide(color: ExpenseColors.shellBorder, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.ctrl,
          builder: (_, __) => Row(
            children: [
              // â”€â”€ Back Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _HoverBackButton(onTap: widget.onBack),
              const SizedBox(width: 16),

              // â”€â”€ Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _vertDivider(),
              const SizedBox(width: 16),

              // â”€â”€ Module Icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ExpenseColors.moduleAccentLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: ExpenseColors.moduleAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  ExpenseIcons.moduleIcon,
                  color: ExpenseColors.moduleAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // â”€â”€ Title + Shop Name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ExpenseStrings.moduleTitle,
                      style: ExpenseStyles.appBarTitle),
                  if (_shopName.isNotEmpty)
                    Text(_shopName, style: ExpenseStyles.appBarSubtitle),
                ],
              ),

              const Spacer(),

              // â”€â”€ Live Indicator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              AnimatedBuilder(
                animation: _blinkAnim,
                builder: (_, __) => Opacity(
                  opacity: _blinkAnim.value,
                  child: Row(children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: ExpenseColors.moduleAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ExpenseColors.moduleAccent,
                          letterSpacing: 1.2,
                        )),
                  ]),
                ),
              ),

              const SizedBox(width: 20),
              _vertDivider(),
              const SizedBox(width: 16),

              // â”€â”€ Sort Dropdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _SortDropdown(ctrl: widget.ctrl),

              const SizedBox(width: 12),

              // â”€â”€ Add Expense Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              GestureDetector(
                onTap: widget.onAddExpense,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: ExpenseColors.moduleAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(ExpenseIcons.addExpense,
                        size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(ExpenseStrings.addExpense,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vertDivider() => Container(
        width: 1,
        height: 30,
        color: ExpenseColors.shellBorder,
      );
}

// â”€â”€ Sort Dropdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SortDropdown extends StatelessWidget {
  final ExpenseController ctrl;
  const _SortDropdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: ExpenseColors.shellBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ExpenseColors.shellBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ExpenseSortOrder>(
          value: ctrl.sortOrder,
          isDense: true,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ExpenseColors.shellMuted,
          ),
          dropdownColor: ExpenseColors.shellPanel,
          icon: const Icon(Icons.unfold_more_rounded,
              size: 14, color: ExpenseColors.shellMuted),
          items: ExpenseSortOrder.values
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.displayLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ExpenseColors.shellMuted,
                          fontWeight: FontWeight.w500,
                        )),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) ctrl.setSortOrder(v);
          },
        ),
      ),
    );
  }
}

// â”€â”€ Hover Back Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                _hovered ? ExpenseColors.moduleAccentLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? ExpenseColors.moduleAccent.withValues(alpha: 0.4)
                  : ExpenseColors.shellBorder,
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: _hovered
                ? ExpenseColors.moduleAccent
                : ExpenseColors.shellMuted,
          ),
        ),
      ),
    );
  }
}
