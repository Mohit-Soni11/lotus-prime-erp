import 'package:flutter/material.dart';

import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'stock_suggestion_tile_frame.dart';

class DefaultStockSuggestionTile extends StatelessWidget {
  final PosStockLookupModel item;
  final VoidCallback onTap;

  const DefaultStockSuggestionTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = switch (item.metal) {
      MetalType.platinum => SalesPosColors.brandPlatinum,
      MetalType.diamond => SalesPosColors.brandDiamond,
      MetalType.gold => SalesPosColors.brandGold,
      MetalType.silver => SalesPosColors.brandSilver,
    };
    return StockSuggestionTileFrame(
      item: item,
      onTap: onTap,
      accentColor: accent,
      huidIconColor: accent,
      metadata: _metadata(item),
      identifiers: _identifiers(item),
    );
  }

  static List<String> _metadata(PosStockLookupModel item) {
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

  static List<String> _identifiers(PosStockLookupModel item) {
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
