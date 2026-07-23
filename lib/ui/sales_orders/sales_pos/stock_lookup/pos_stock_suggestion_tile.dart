import 'package:flutter/material.dart';

import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import 'default_stock_suggestion_tile.dart';
import 'gold_stock_suggestion_tile.dart';
import 'silver_stock_suggestion_tile.dart';

class PosStockSuggestionTile extends StatelessWidget {
  final PosStockLookupModel item;
  final VoidCallback onTap;

  const PosStockSuggestionTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return switch (item.metal) {
      MetalType.gold => GoldStockSuggestionTile(item: item, onTap: onTap),
      MetalType.silver => SilverStockSuggestionTile(item: item, onTap: onTap),
      MetalType.platinum || MetalType.diamond => DefaultStockSuggestionTile(
          item: item,
          onTap: onTap,
        ),
    };
  }
}
