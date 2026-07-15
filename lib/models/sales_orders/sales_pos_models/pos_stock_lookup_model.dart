// ==========================================
// FILE: pos_stock_lookup_model.dart
// TYPE: Data Model
// DESCRIPTION: POS-friendly stock lookup result used by HUID and description
//              suggestions. Keeps the row autofill logic separate from the
//              database entity.
// ==========================================

import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';

class PosStockLookupModel {
  final int stockItemId;
  final int? stockUnitId;
  final String sku;
  final String itemName;
  final String description;
  final String? huid;
  final List<String> huids;
  final String purity;
  final MetalType metal;
  final String categoryLabel;
  final String segmentLabel;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double unitCost;
  final int quantity;
  final String status;

  const PosStockLookupModel({
    required this.stockItemId,
    this.stockUnitId,
    required this.sku,
    required this.itemName,
    required this.description,
    required this.huid,
    this.huids = const [],
    required this.purity,
    required this.metal,
    required this.categoryLabel,
    this.segmentLabel = '',
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    this.unitCost = 0.0,
    required this.quantity,
    required this.status,
  });

  String get displayTitle => itemName.trim().isEmpty ? sku : itemName.trim();

  String get displaySubtitle {
    final parts = <String>[
      categoryLabel,
      if (segmentLabel.trim().isNotEmpty) segmentLabel.trim(),
      if (huids.isNotEmpty)
        'HUID ${huids.join(', ')}'
      else if (huid != null && huid!.trim().isNotEmpty)
        'HUID ${huid!.trim()}',
      if (quantity > 1) '$quantity pcs set',
      if (purity.trim().isNotEmpty) purity.trim(),
      'GW ${grossWeight.toStringAsFixed(3)}',
      if (unitCost > 0) 'Cost Rs ${unitCost.toStringAsFixed(2)}',
    ];
    return parts.join(' | ');
  }
}
