class StockSearchSummary {
  final int totalUnits;
  final int availableUnits;
  final int soldUnits;
  final double grossWeight;
  final double netWeight;
  final double stockValue;

  const StockSearchSummary({
    required this.totalUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.grossWeight,
    required this.netWeight,
    required this.stockValue,
  });

  factory StockSearchSummary.empty() {
    return const StockSearchSummary(
      totalUnits: 0,
      availableUnits: 0,
      soldUnits: 0,
      grossWeight: 0,
      netWeight: 0,
      stockValue: 0,
    );
  }
}

class StockSearchResult {
  final int id;
  final int? stockItemId;
  final int? purchaseVoucherId;
  final String batchCode;
  final String unitCode;
  final int pieceNo;
  final String metalType;
  final String itemType;
  final String segment;
  final String itemName;
  final String huid;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double purityPercent;
  final double actualFineWeight;
  final double valuationFineWeight;
  final double ratePerGram;
  final double makingAmount;
  final double unitCost;
  final int? supplierId;
  final String supplierName;
  final String status;
  final DateTime? createdAt;
  final DateTime? soldAt;
  final String voucherNo;
  final String supplierInvoiceNo;
  final String taxType;
  final String soldBillNo;
  final String soldCustomerName;
  final DateTime? soldBillDate;
  final double soldBillAmount;
  final double soldProfitAmount;

  const StockSearchResult({
    required this.id,
    required this.stockItemId,
    required this.purchaseVoucherId,
    required this.batchCode,
    required this.unitCode,
    required this.pieceNo,
    required this.metalType,
    required this.itemType,
    required this.segment,
    required this.itemName,
    required this.huid,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.purityPercent,
    required this.actualFineWeight,
    required this.valuationFineWeight,
    required this.ratePerGram,
    required this.makingAmount,
    required this.unitCost,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.createdAt,
    required this.soldAt,
    required this.voucherNo,
    required this.supplierInvoiceNo,
    required this.taxType,
    required this.soldBillNo,
    required this.soldCustomerName,
    required this.soldBillDate,
    required this.soldBillAmount,
    required this.soldProfitAmount,
  });

  bool get isAvailable => status.toLowerCase() == 'available';

  bool get isSold => status.toLowerCase() == 'sold';

  bool get hasHuid => huid.trim().isNotEmpty;

  String get displayName {
    final cleaned = itemName.trim();
    return cleaned.isEmpty ? 'Unnamed Stock Unit' : cleaned.toUpperCase();
  }

  String get trackingLabel => hasHuid ? 'HUID Linked' : 'Weight Tracked';

  String get sourceInvoice {
    if (supplierInvoiceNo.trim().isNotEmpty) return supplierInvoiceNo;
    if (voucherNo.trim().isNotEmpty) return voucherNo;
    return 'Not recorded';
  }

  String get inventoryBatchCode {
    if (batchCode.trim().isNotEmpty) return batchCode.trim();
    if (voucherNo.trim().isNotEmpty) return voucherNo.trim();
    return '';
  }
}
