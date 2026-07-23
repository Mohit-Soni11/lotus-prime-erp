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
      huidText: _identifier(item),
    );
  }

  static String _metadata(PosStockLookupModel item) {
    final type = item.categoryLabel.trim();
    final company = item.companyName.trim();
    final segment = item.segmentLabel.trim();
    final details = <String>[
      if (type.isNotEmpty) 'Type: $type',
      if (company.isNotEmpty) 'Company: $company',
      if (segment.isNotEmpty) segment,
      if (item.quantity > 1) '${item.quantity} pcs',
    ];
    return details.isEmpty ? item.sku : details.join('  |  ');
  }

  static String _identifier(PosStockLookupModel item) {
    if (item.huids.isNotEmpty) {
      return item.huids.join(', ');
    }
    final huid = item.huid?.trim() ?? '';
    if (huid.isNotEmpty) {
      return huid;
    }
    return item.sku.trim().isEmpty ? '-' : item.sku.trim();
  }
}
