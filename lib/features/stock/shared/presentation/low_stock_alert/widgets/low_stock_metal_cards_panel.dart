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
            icon: Icons.notification_important_rounded,
            title: 'Active Low Stock Alerts',
            subtitle:
                'Only stock groups crossing red, yellow or stockout rules appear here.',
            trailing: LowStockStatusPill(
              label: '${cards.length} ALERTS',
              color: InvColors.brandGold,
            ),
          ),
          const SizedBox(height: 16),
          if (cards.isEmpty)
            const LowStockEmptyState(
              title: 'All Watched Stock Healthy',
              subtitle:
                  'Only low, critical and stockout groups will appear here.',
              icon: Icons.check_circle_outline_rounded,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 1320
                    ? (constraints.maxWidth - 32) / 3
                    : constraints.maxWidth >= 880
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
                          actionLabel: 'Review ${card.metalType} Alert',
                          alertMode: true,
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
