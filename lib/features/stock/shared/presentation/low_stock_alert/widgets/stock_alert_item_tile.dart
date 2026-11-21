import 'package:flutter/material.dart';
import '../../../domain/models/low_stock_alert/low_stock_alert_models.dart';
import '../../../domain/models/low_stock_alert/stock_alert_group.dart';
import '../../../../../../theme/stock/inventory/inventory_theme.dart';
import '../formatting/stock_alert_item_text.dart';

class StockAlertItemTile extends StatelessWidget {
  final LowStockStockCard item;
  const StockAlertItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final out = StockAlertGroup.isOutOfStock(item);
    final color = out ? InvColors.danger : InvColors.warning;
    final grade = StockAlertItemText.grade(item.gradeLabel);
    final status = out
        ? 'Out of stock'
        : item.riskLevel == LowStockRiskLevel.critical
            ? 'Critical stock'
            : 'Low stock';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: InvColors.cardBg,
          border: Border.all(color: InvColors.cardBorder),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Text(StockAlertItemText.itemName(item),
                  style: const TextStyle(
                      color: InvColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(status,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 6),
        Text([item.metalType, if (grade.isNotEmpty) grade].join(' · '),
            style: const TextStyle(color: InvColors.textBody, fontSize: 13)),
        const SizedBox(height: 14),
        Row(children: [
          Icon(Icons.inventory_2_outlined, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(StockAlertItemText.availability(item),
                  style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600))),
        ]),
      ]),
    );
  }
}
