import 'package:flutter/foundation.dart';

@immutable
class SupplierStockBatch {
  const SupplierStockBatch({
    required this.code,
    required this.metalTypes,
    required this.itemNames,
    required this.totalUnits,
    required this.availableUnits,
  });

  final String code;
  final String metalTypes;
  final String itemNames;
  final int totalUnits;
  final int availableUnits;

  bool get isActive => availableUnits > 0;
  String get statusLabel => isActive ? 'ACTIVE' : 'CLOSED';
}
