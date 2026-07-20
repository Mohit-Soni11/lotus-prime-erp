import 'package:flutter/material.dart';

import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_alert_widgets.dart';
import 'package:lotus_erp/features/stock/shared/presentation/low_stock_alert/widgets/low_stock_smart_card.dart';
import 'package:lotus_erp/theme/stock/inventory/inventory_theme.dart';

class LowStockMetalCardsPanel extends StatelessWidget {
  final List<LowStockStockCard> cards;
  final ValueChanged<LowStockStockCard> onOpenMetal;

  const LowStockMetalCardsPanel({
    super.key,
    required this.cards,
    required this.onOpenMetal,
  });

  @override
  Widget build(BuildContext context) {
    return LowStockPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LowStockSectionHeader(
            icon: Icons.dashboard_customize_rounded,
            title: 'Low Stock Smart Cards',
            subtitle:
                'Only low, critical and stock-out inventory appears here.',
            trailing: LowStockStatusPill(
              label: '${cards.length} ALERTS',
              color: InvColors.brandGold,
            ),
          ),
          const SizedBox(height: 16),
          if (cards.isEmpty)
            const LowStockEmptyState(
              title: 'No Low Stock Card Available',
              subtitle: 'All watched inventory is currently healthy.',
              icon: Icons.inventory_2_outlined,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 960
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final card in cards)
                      SizedBox(
                        width: width,
                        child: LowStockSmartCard(
                          card: card,
                          actionLabel: 'Open ${card.metalType} Alerts',
                          onTap: () => onOpenMetal(card),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
