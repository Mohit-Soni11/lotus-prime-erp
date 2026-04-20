// =============================================================================
// FILE        : delivery_order_list.dart
// MODULE      : Sales → Delivery Management
// LAYER       : UI
// DESCRIPTION : Left panel — search bar + scrollable list of DeliveryOrderCards.
//               Shows empty state when list is empty.
//               ListenableBuilder for zero-lag updates.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../logic/sales & orders/delivery/delivery_management_controller.dart';
import '../../../models/sales & orders/delivery/delivery_enums.dart';
import '../../../theme/sales/delivery/delivery_theme.dart';

import 'delivery_order_card.dart';

class DeliveryOrderList extends StatelessWidget {
  final DeliveryManagementController ctrl;

  const DeliveryOrderList({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _SearchBar(ctrl: ctrl),
      Expanded(
        child: ListenableBuilder(
          listenable: ctrl,
          builder: (_, __) {
            if (ctrl.isLoading) return _LoadingState();
            final list = ctrl.currentList;
            if (list.isEmpty) return _EmptyState(tab: ctrl.activeTab);
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final order = list[i];
                return DeliveryOrderCard(
                  order: order,
                  isSelected: ctrl.selectedOrder?.id == order.id,
                  onTap: () => ctrl.selectOrder(order),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final DeliveryManagementController ctrl;
  const _SearchBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: DeliveryColors.bodyBg,
      child: Row(children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: DeliveryColors.bodyPanelBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DeliveryColors.bodyBorder),
              boxShadow: const [
                BoxShadow(color: DeliveryColors.shadowLight, blurRadius: 4),
              ],
            ),
            child: TextField(
              controller: ctrl.searchCtrl,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.bodyTextMain,
              ),
              decoration: InputDecoration(
                hintText: DeliveryStrings.searchHint,
                hintStyle: TextStyle(
                  color: DeliveryColors.bodyTextMuted.withOpacity(0.6),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  DeliveryIcons.search,
                  size: 18,
                  color: DeliveryColors.bodyTextMuted,
                ),
                suffixIcon: ListenableBuilder(
                  listenable: ctrl.searchCtrl,
                  builder: (_, __) => ctrl.searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(DeliveryIcons.close,
                              size: 16, color: DeliveryColors.bodyTextMuted),
                          onPressed: ctrl.clearSearch,
                        )
                      : const SizedBox.shrink(),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final DeliveryTab tab;
  const _EmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    final msg = switch (tab) {
      DeliveryTab.activeOrders => DeliveryStrings.emptyActiveOrders,
      DeliveryTab.actionRequired => DeliveryStrings.emptyActionRequired,
      DeliveryTab.dueLedger => DeliveryStrings.emptyDueLedger,
      DeliveryTab.completedBills => DeliveryStrings.emptyCompleted,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              DeliveryIcons.emptyState,
              size: 56,
              color: DeliveryColors.bodyTextMuted.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              msg,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DeliveryColors.bodyTextMuted.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              DeliveryStrings.emptySubtitle,
              style: TextStyle(
                fontSize: 12,
                color: DeliveryColors.bodyTextMuted.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading State ─────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 5,
      itemBuilder: (_, i) => _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DeliveryColors.bodyPanelBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DeliveryColors.bodyBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _shimBox(80, 12),
              const Spacer(),
              _shimBox(60, 20),
            ]),
            const SizedBox(height: 10),
            _shimBox(200, 14),
            const SizedBox(height: 6),
            _shimBox(150, 12),
          ],
        ),
      ),
    );
  }

  Widget _shimBox(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: DeliveryColors.bodyBorder.withOpacity(_anim.value + 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
      );
}
