// ==========================================
// FILE: pos_stock_lookup_model.dart
// TYPE: Data Model
// DESCRIPTION: POS-friendly stock lookup result used by HUID and description
//              suggestions. Keeps the row autofill logic separate from the
//              database entity.
// ==========================================

import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';

class PosStockLookupModel {
  final int stockItemId;
  final String sku;
  final String itemName;
  final String description;
  final String? huid;
  final String purity;
  final MetalType metal;
  final String categoryLabel;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final int quantity;
  final String status;

  const PosStockLookupModel({
    required this.stockItemId,
    required this.sku,
    required this.itemName,
    required this.description,
    required this.huid,
    required this.purity,
    required this.metal,
    required this.categoryLabel,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.quantity,
    required this.status,
  });

  String get displayTitle => itemName.trim().isEmpty ? sku : itemName.trim();

  String get displaySubtitle {
    final parts = <String>[
      categoryLabel,
      if (huid != null && huid!.trim().isNotEmpty) 'HUID ${huid!.trim()}',
      if (purity.trim().isNotEmpty) purity.trim(),
      'GW ${grossWeight.toStringAsFixed(3)}',
    ];
    return parts.join(' • ');
  }
}
