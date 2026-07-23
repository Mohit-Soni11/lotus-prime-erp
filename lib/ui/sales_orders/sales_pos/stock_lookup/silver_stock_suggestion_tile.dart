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
      huidText: _silverIdentifier(item),
    );
  }

  static String _silverMetadata(PosStockLookupModel item) {
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

  static String _silverIdentifier(PosStockLookupModel item) {
    final huid = item.huid?.trim() ?? '';
    if (huid.isNotEmpty) {
      return huid;
    }
    if (item.huids.isNotEmpty) {
      return item.huids.join(', ');
    }
    return item.sku.trim().isEmpty ? '-' : item.sku.trim();
  }
}
