import 'package:flutter/material.dart';

import '../../../../models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'stock_suggestion_tile_frame.dart';

class SilverStockSuggestionTile extends StatelessWidget {
  final PosStockLookupModel item;
  final VoidCallback onTap;

  const SilverStockSuggestionTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StockSuggestionTileFrame(
      item: item,
      onTap: onTap,
      accentColor: SalesPosColors.brandSilver,
      huidIconColor: SalesPosColors.brandSilver,
      metadata: _silverMetadata(item),
      identifiers: _silverIdentifiers(item),
    );
  }

  static List<String> _silverMetadata(PosStockLookupModel item) {
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

  static List<String> _silverIdentifiers(PosStockLookupModel item) {
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
