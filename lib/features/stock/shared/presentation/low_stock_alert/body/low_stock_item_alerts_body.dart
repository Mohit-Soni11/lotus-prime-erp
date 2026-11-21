import 'package:flutter/material.dart';
import '../../../application/low_stock_alert_controller.dart';
import '../../../domain/models/low_stock_alert/stock_alert_group.dart';
import '../../../../../../theme/stock/inventory/inventory_theme.dart';
import '../widgets/stock_alert_item_tile.dart';

/// Notification drill-down: only affected items of the selected metal.
class LowStockItemAlertsBody extends StatelessWidget {
  final LowStockAlertController controller;
  final String metalType;
  const LowStockItemAlertsBody(
      {super.key, required this.controller, required this.metalType});

  @override
  Widget build(BuildContext context) {
    final groups = StockAlertGroup.fromCards(controller.alertItemTypeCards);
    final group = groups
        .where(
            (group) => group.metalType.toLowerCase() == metalType.toLowerCase())
        .firstOrNull;
    return RefreshIndicator(
      onRefresh: controller.load,
      color: InvColors.brandGold,
      child: CustomScrollView(
        key: PageStorageKey('stock-alert-items:$metalType'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$metalType stock alerts',
                  style: const TextStyle(
                      color: InvColors.textDark,
                      fontSize: 23,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  group?.description ??
                      'Review items that are out of stock or below their required stock levels.',
                  style:
                      const TextStyle(color: InvColors.textBody, fontSize: 14)),
            ]),
          )),
          if (controller.isLoading)
            const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                    child:
                        CircularProgressIndicator(color: InvColors.brandGold)))
          else if (controller.errorMessage != null)
            const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Stock details could not be loaded. Use Refresh to try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: InvColors.danger)))))
          else if (group == null)
            SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                            'No active $metalType stock alerts. All monitored items meet their stock levels.',
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: InvColors.textBody)))))
          else
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverList.separated(
                  itemCount: group.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) =>
                      StockAlertItemTile(item: group.items[index]),
                )),
        ],
      ),
    );
  }
}
