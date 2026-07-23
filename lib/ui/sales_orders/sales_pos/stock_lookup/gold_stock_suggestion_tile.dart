import 'package:flutter/material.dart';

import '../../../../models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'stock_suggestion_tile_frame.dart';

class GoldStockSuggestionTile extends StatelessWidget {
  final PosStockLookupModel item;
  final VoidCallback onTap;

  const GoldStockSuggestionTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StockSuggestionTileFrame(
      item: item,
      onTap: onTap,
      accentColor: SalesPosColors.brandGold,
      huidIconColor: SalesPosColors.brandGold,
      metadata: _goldMetadata(item),
      identifiers: _goldHuidValues(item),
    );
  }

  static List<String> _goldMetadata(PosStockLookupModel item) {
    final type = item.categoryLabel.trim();
    final company = item.companyName.trim();
    final segment = item.segmentLabel.trim();
    return <String>[
      if (type.isNotEmpty) type,
      if (company.isNotEmpty) company,
      if (segment.isNotEmpty) segment,
      if (item.quantity > 1) '${item.quantity} pcs',
    ];
  }

  static List<String> _goldHuidValues(PosStockLookupModel item) {
    if (item.huids.isNotEmpty) {
      return item.huids;
    }
    final huid = item.huid?.trim() ?? '';
    if (huid.isNotEmpty) {
      return [huid];
    }
    return const [];
  }
}
