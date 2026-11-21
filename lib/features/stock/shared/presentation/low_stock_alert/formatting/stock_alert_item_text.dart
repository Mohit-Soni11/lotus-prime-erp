import '../../../domain/models/low_stock_alert/low_stock_alert_models.dart';

abstract final class StockAlertItemText {
  static String itemName(LowStockStockCard item) {
    final name = item.itemType.trim();
    if (name.isEmpty || name.toLowerCase() == LowStockConstants.anyItemKey) {
      return 'Other items';
    }
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  static String grade(String value) => value
      .replaceAll(RegExp(r'\s*\(\s*'), ' · ')
      .replaceAll(')', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^\s*·\s*|\s*·\s*$'), '')
      .trim();

  static String availability(LowStockStockCard item) {
    final count = item.availableUnits;
    final unit = switch (item.unitLabel.trim().toLowerCase()) {
      '' || 'pcs' || 'piece' || 'pieces' => count == 1 ? 'piece' : 'pieces',
      'set' || 'sets' => count == 1 ? 'set' : 'sets',
      'packet' || 'packets' => count == 1 ? 'packet' : 'packets',
      _ => item.unitLabel.trim(),
    };
    return '$count $unit available';
  }
}
