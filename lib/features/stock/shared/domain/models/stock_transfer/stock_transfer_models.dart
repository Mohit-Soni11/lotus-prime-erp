class StockTransferSummary {
  final int availableUnits;
  final int inTransitTransfers;
  final int inTransitUnits;
  final int transferredToday;
  final int receivedToday;
  final double inTransitNetWeight;

  const StockTransferSummary({
    required this.availableUnits,
    required this.inTransitTransfers,
    required this.inTransitUnits,
    required this.transferredToday,
    required this.receivedToday,
    required this.inTransitNetWeight,
  });

  factory StockTransferSummary.empty() {
    return const StockTransferSummary(
      availableUnits: 0,
      inTransitTransfers: 0,
      inTransitUnits: 0,
      transferredToday: 0,
      receivedToday: 0,
      inTransitNetWeight: 0,
    );
  }
}

class StockTransferUnit {
  final int id;
  final int stockItemId;
  final String unitCode;
  final String batchCode;
  final String metalType;
  final String itemType;
  final String itemName;
  final String huid;
  final String supplierName;
  final String currentLocation;
  final double grossWeight;
  final double netWeight;
  final double fineWeight;
  final double purityPercent;
  final double unitCost;

  const StockTransferUnit({
    required this.id,
    required this.stockItemId,
    required this.unitCode,
    required this.batchCode,
    required this.metalType,
    required this.itemType,
    required this.itemName,
    required this.huid,
    required this.supplierName,
    required this.currentLocation,
    required this.grossWeight,
    required this.netWeight,
    required this.fineWeight,
    required this.purityPercent,
    required this.unitCost,
  });

  String get displayName {
    final clean = itemName.trim();
    return clean.isEmpty ? 'Unnamed Stock Unit' : clean.toUpperCase();
  }

  String get trackingCode {
    final cleanHuid = huid.trim();
    return cleanHuid.isNotEmpty ? cleanHuid : unitCode;
  }
}

class StockTransferForm {
  final String fromLocation;
  final String toLocation;
  final String transferType;
  final String carrierName;
  final String authorizedBy;
  final DateTime? expectedDate;
  final String notes;

  const StockTransferForm({
    required this.fromLocation,
    required this.toLocation,
    required this.transferType,
    required this.carrierName,
    required this.authorizedBy,
    required this.expectedDate,
    required this.notes,
  });
}

class StockTransferRecord {
  final int id;
  final String transferNo;
  final String fromLocation;
  final String toLocation;
  final String transferType;
  final String status;
  final String carrierName;
  final String authorizedBy;
  final String notes;
  final int totalUnits;
  final double totalGrossWeight;
  final double totalNetWeight;
  final double totalFineWeight;
  final DateTime createdAt;
  final DateTime? expectedDate;
  final DateTime? receivedAt;
  final DateTime? cancelledAt;

  const StockTransferRecord({
    required this.id,
    required this.transferNo,
    required this.fromLocation,
    required this.toLocation,
    required this.transferType,
    required this.status,
    required this.carrierName,
    required this.authorizedBy,
    required this.notes,
    required this.totalUnits,
    required this.totalGrossWeight,
    required this.totalNetWeight,
    required this.totalFineWeight,
    required this.createdAt,
    required this.expectedDate,
    required this.receivedAt,
    required this.cancelledAt,
  });

  bool get isInTransit => status.toLowerCase() == StockTransferStatus.inTransit;
  bool get isReceived => status.toLowerCase() == StockTransferStatus.received;
  bool get isCancelled => status.toLowerCase() == StockTransferStatus.cancelled;
}

class StockTransferLine {
  final int id;
  final int transferId;
  final int stockUnitId;
  final int stockItemId;
  final String unitCode;
  final String huid;
  final String itemName;
  final String metalType;
  final double grossWeight;
  final double netWeight;
  final double fineWeight;
  final double unitCost;

  const StockTransferLine({
    required this.id,
    required this.transferId,
    required this.stockUnitId,
    required this.stockItemId,
    required this.unitCode,
    required this.huid,
    required this.itemName,
    required this.metalType,
    required this.grossWeight,
    required this.netWeight,
    required this.fineWeight,
    required this.unitCost,
  });
}

class StockTransferCreated {
  final String transferNo;
  final int unitCount;

  const StockTransferCreated({
    required this.transferNo,
    required this.unitCount,
  });
}

class StockTransferStatus {
  StockTransferStatus._();

  static const String inTransit = 'in_transit';
  static const String received = 'received';
  static const String cancelled = 'cancelled';
}
