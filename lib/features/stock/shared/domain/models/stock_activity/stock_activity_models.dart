import 'package:drift/drift.dart' show QueryRow;

class StockActivitySummary {
  final int totalMovements;
  final int stockAdded;
  final int stockSold;
  final int stockRestored;
  final double addedWeight;
  final double soldWeight;

  const StockActivitySummary({
    required this.totalMovements,
    required this.stockAdded,
    required this.stockSold,
    required this.stockRestored,
    required this.addedWeight,
    required this.soldWeight,
  });

  factory StockActivitySummary.empty() {
    return const StockActivitySummary(
      totalMovements: 0,
      stockAdded: 0,
      stockSold: 0,
      stockRestored: 0,
      addedWeight: 0,
      soldWeight: 0,
    );
  }
}

class StockMetalActivitySummary {
  final String metal;
  final int inwardQuantity;
  final int outwardQuantity;
  final int restoredQuantity;
  final double inwardWeight;
  final double outwardWeight;
  final double restoredWeight;

  const StockMetalActivitySummary({
    required this.metal,
    required this.inwardQuantity,
    required this.outwardQuantity,
    required this.restoredQuantity,
    required this.inwardWeight,
    required this.outwardWeight,
    required this.restoredWeight,
  });

  factory StockMetalActivitySummary.empty(String metal) {
    return StockMetalActivitySummary(
      metal: metal,
      inwardQuantity: 0,
      outwardQuantity: 0,
      restoredQuantity: 0,
      inwardWeight: 0,
      outwardWeight: 0,
      restoredWeight: 0,
    );
  }

  factory StockMetalActivitySummary.fromRow(QueryRow row) {
    return StockMetalActivitySummary(
      metal: row.read<String>('metal_type'),
      inwardQuantity: row.read<int>('inward_quantity'),
      outwardQuantity: row.read<int>('outward_quantity'),
      restoredQuantity: row.read<int>('restored_quantity'),
      inwardWeight: row.read<double>('inward_weight'),
      outwardWeight: row.read<double>('outward_weight'),
      restoredWeight: row.read<double>('restored_weight'),
    );
  }

  int get netOutwardQuantity => outwardQuantity - restoredQuantity;
  double get netOutwardWeight => outwardWeight - restoredWeight;
  bool get hasMovement =>
      inwardQuantity != 0 ||
      outwardQuantity != 0 ||
      restoredQuantity != 0 ||
      inwardWeight != 0 ||
      outwardWeight != 0 ||
      restoredWeight != 0;
}

class StockActivityRecord {
  final int id;
  final int stockItemId;
  final String movementType;
  final String sourceType;
  final String sourceId;
  final String sourceNumber;
  final String sku;
  final String metalType;
  final String itemName;
  final String batchCode;
  final String unitCode;
  final String huid;
  final String supplierName;
  final String taxType;
  final String unitStatus;
  final int quantityDelta;
  final double grossWeightDelta;
  final double netWeightDelta;
  final double fineWeightDelta;
  final String reason;
  final DateTime occurredAt;

  const StockActivityRecord({
    required this.id,
    required this.stockItemId,
    required this.movementType,
    required this.sourceType,
    required this.sourceId,
    required this.sourceNumber,
    required this.sku,
    required this.metalType,
    required this.itemName,
    required this.batchCode,
    required this.unitCode,
    required this.huid,
    required this.supplierName,
    required this.taxType,
    required this.unitStatus,
    required this.quantityDelta,
    required this.grossWeightDelta,
    required this.netWeightDelta,
    required this.fineWeightDelta,
    required this.reason,
    required this.occurredAt,
  });

  factory StockActivityRecord.fromRow(QueryRow row) {
    return StockActivityRecord(
      id: row.read<int>('id'),
      stockItemId: row.read<int>('stock_item_id'),
      movementType: row.read<String>('movement_type'),
      sourceType: row.read<String>('source_type'),
      sourceId: row.read<String>('source_id'),
      sourceNumber: row.readNullable<String>('source_number') ?? '',
      sku: row.read<String>('sku_snapshot'),
      metalType: row.read<String>('metal_type_snapshot'),
      itemName: row.read<String>('item_name_snapshot'),
      batchCode: row.readNullable<String>('batch_code') ?? '',
      unitCode: row.readNullable<String>('unit_code') ?? '',
      huid: row.readNullable<String>('huid') ?? '',
      supplierName: row.readNullable<String>('supplier_name') ?? '',
      taxType: row.readNullable<String>('tax_type') ?? '',
      unitStatus: row.readNullable<String>('unit_status') ?? '',
      quantityDelta: row.read<int>('quantity_delta'),
      grossWeightDelta: row.read<double>('gross_weight_delta'),
      netWeightDelta: row.read<double>('net_weight_delta'),
      fineWeightDelta: row.read<double>('fine_weight_delta'),
      reason: row.readNullable<String>('reason') ?? '',
      occurredAt: row.read<DateTime>('occurred_at'),
    );
  }

  bool get isPurchase => movementType.toUpperCase() == 'IN';
  bool get isSale => movementType.toUpperCase() == 'SALE';
  bool get isRestore => movementType.toUpperCase() == 'SALE_RESTORE';

  String get businessTitle {
    if (isPurchase) return 'Stock Added';
    if (isSale) return 'Sold Through POS';
    if (isRestore) return 'Sale Restored';
    return 'Stock Movement';
  }

  String get sourceLabel {
    if (sourceNumber.trim().isNotEmpty) return sourceNumber.trim();
    if (sourceId.trim().isNotEmpty) return sourceId.trim();
    return 'Not recorded';
  }

  String get trackingLabel {
    if (huid.trim().isNotEmpty) return huid.trim();
    if (unitCode.trim().isNotEmpty) return unitCode.trim();
    if (sku.trim().isNotEmpty) return sku.trim();
    return 'Weight tracked';
  }
}
