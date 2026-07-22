import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';

final class AddStockSkuGenerator {
  const AddStockSkuGenerator._();

  static String generate({
    required StockCategory metal,
    required int index,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final prefix = metal.label.length >= 4
        ? metal.label.substring(0, 4).toUpperCase()
        : metal.label.toUpperCase();
    final datePart =
        '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
    final uniquePart = timestamp.microsecondsSinceEpoch % 99999;
    return '$prefix-$datePart-${uniquePart + index}';
  }
}
