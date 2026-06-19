// =============================================================================
// FILE        : delivery_tab_bar.dart
// MODULE      : Sales â†’ Delivery Management
// LAYER       : UI
// DESCRIPTION : 4-tab bar: Active Orders | Action Required | Due Ledger |
//               Completed Bills. Dark shell style with badge counts.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../logic/sales_orders/delivery/delivery_management_controller.dart';
import '../../../models/sales_orders/delivery/delivery_enums.dart';
import '../../../theme/sales/delivery/delivery_theme.dart';

class DeliveryTabBar extends StatelessWidget {
  final DeliveryManagementController ctrl;

  const DeliveryTabBar({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.summary;
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: DeliveryColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: DeliveryColors.shellBorder, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _Tab(
            label: DeliveryStrings.tabActiveOrders,
            icon: DeliveryIcons.tabActiveOrders,
            badge: s.totalActive,
            isActive: ctrl.activeTab == DeliveryTab.activeOrders,
            onTap: () => ctrl.switchTab(DeliveryTab.activeOrders),
          ),
          const SizedBox(width: 4),
          _Tab(
            label: DeliveryStrings.tabActionRequired,
            icon: DeliveryIcons.tabActionRequired,
            badge: s.actionRequired,
            isActive: ctrl.activeTab == DeliveryTab.actionRequired,
            badgeColor:
                s.actionRequired > 0 ? DeliveryColors.urgencyOverdue : null,
            onTap: () => ctrl.switchTab(DeliveryTab.actionRequired),
          ),
          const SizedBox(width: 4),
          _Tab(
            label: DeliveryStrings.tabDueLedger,
            icon: DeliveryIcons.tabDueLedger,
            badge: s.dueLedgerCount,
            isActive: ctrl.activeTab == DeliveryTab.dueLedger,
            badgeColor:
                s.dueLedgerCount > 0 ? DeliveryColors.paymentPartial : null,
            onTap: () => ctrl.switchTab(DeliveryTab.dueLedger),
          ),
          const SizedBox(width: 4),
          _Tab(
            label: DeliveryStrings.tabCompleted,
            icon: DeliveryIcons.tabCompleted,
            badge: s.completedCount,
            isActive: ctrl.activeTab == DeliveryTab.completedBills,
            badgeColor: DeliveryColors.paymentPaid,
            onTap: () => ctrl.switchTab(DeliveryTab.completedBills),
          ),
        ]),
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  final String label;
  final IconData icon;
  final int badge;
  final bool isActive;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.badge,
    required this.isActive,
    required this.onTap,
    this.badgeColor,
  });

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? DeliveryColors.brandGold : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: active
                    ? DeliveryColors.brandGold
                    : _hover
                        ? DeliveryColors.shellTextTitle.withValues(alpha: 0.8)
                        : DeliveryColors.shellTextMuted,
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: active
                    ? DeliveryStyles.tabActive
                    : DeliveryStyles.tabInactive.copyWith(
                        color: _hover
                            ? DeliveryColors.shellTextTitle
                                .withValues(alpha: 0.8)
                            : null,
                      ),
              ),
              if (widget.badge > 0) ...[
                const SizedBox(width: 7),
                _Badge(count: widget.badge, color: widget.badgeColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color? color;
  const _Badge({required this.count, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? DeliveryColors.shellTextMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: c,
        ),
      ),
    );
  }
}
