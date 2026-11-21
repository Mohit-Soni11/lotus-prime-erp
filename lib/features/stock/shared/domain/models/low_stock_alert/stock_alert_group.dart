import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'low_stock_alert_models.dart';

/// A metal-level summary of actionable item and purity groups.
class StockAlertGroup {
  final String metalType;
  final List<LowStockStockCard> items;

  StockAlertGroup._(this.metalType, List<LowStockStockCard> items)
      : items = List.unmodifiable(items);

  static List<StockAlertGroup> fromCards(Iterable<LowStockStockCard> cards) {
    final groups = <String, List<LowStockStockCard>>{};
    for (final card in cards) {
      final metal = card.metalType.trim().toUpperCase();
      if (!card.requiresAction || !{'GOLD', 'SILVER'}.contains(metal)) continue;
      groups.putIfAbsent(metal, () => []).add(card);
    }
    final metals = groups.keys.toList()..sort();
    return [
      for (final metal in metals)
        StockAlertGroup._(
          '${metal[0]}${metal.substring(1).toLowerCase()}',
          groups[metal]!
            ..sort((a, b) {
              final severity = _severity(a).compareTo(_severity(b));
              if (severity != 0) return severity;
              final item =
                  a.itemType.toLowerCase().compareTo(b.itemType.toLowerCase());
              return item != 0 ? item : a.gradeLabel.compareTo(b.gradeLabel);
            }),
        )
    ];
  }

  int get stockoutCount => items.where(isOutOfStock).length;
  int get lowStockCount => items.length - stockoutCount;
  static bool isOutOfStock(LowStockStockCard item) =>
      item.availableUnits <= 0 || item.riskLevel == LowStockRiskLevel.stockout;

  static int _severity(LowStockStockCard item) => isOutOfStock(item)
      ? 0
      : item.riskLevel == LowStockRiskLevel.critical
          ? 1
          : 2;

  String get description {
    final count = items.length;
    final groups = '$count item ${count == 1 ? 'group' : 'groups'}';
    if (lowStockCount == 0) {
      return '$groups ${count == 1 ? 'is' : 'are'} out of stock.';
    }
    if (stockoutCount == 0) {
      return '$groups ${count == 1 ? 'is' : 'are'} below the required stock level.';
    }
    return '$groups need replenishment: $stockoutCount out of stock and $lowStockCount low on stock.';
  }

  /// Includes members so a changed item cannot hide behind unchanged counts.
  String get revision => sha256
      .convert(utf8.encode(jsonEncode([
        for (final item in items)
          [
            item.itemType,
            item.gradeLabel,
            item.availableUnits,
            item.availableNetWeight,
            item.unitLabel,
            item.riskLevel,
            item.thresholdUnits,
            item.thresholdNetWeight,
          ],
      ])))
      .toString();
}
