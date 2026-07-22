import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';

class StockRowEntry {
  final String id;

  String itemName = '';
  String description = '';
  StockSubCategory subCategory = StockSubCategory.ring;
  String subCategoryLabel = '';
  String companyLabel = '';
  String segmentLabel = '';
  String huid = '';
  List<String> huids = [];
  String hsnCode;

  double grossWeight = 0.0;
  double stoneWeight = 0.0;
  double stoneValue = 0.0;
  double touchPercent = 0.0;
  double wastageFineWeight = 0.0;
  double valuationFineWeight = 0.0;
  String purityLabel = '';

  StoneType stoneType = StoneType.none;
  double stoneCarats = 0.0;
  int stonePieces = 0;

  double purchaseRate = 0.0;
  double purchasePriceOverride = 0.0;
  double makingCharges = 0.0;
  MakingChargesType makingChargesType = MakingChargesType.perGram;
  double mrp = 0.0;
  double gstRate = 3.0;

  int quantity = 1;
  String quantityMode = 'PIECES';
  int packetCount = 0;
  int piecesPerPacket = 1;
  String location = '';

  int? supplierId;
  String supplierName = '';

  StockRowEntry({required this.id, required this.hsnCode});

  double get netWeight =>
      (grossWeight - stoneWeight).clamp(0.0, double.infinity);

  double get lessWeight => stoneWeight;

  set lessWeight(double value) => stoneWeight = value;

  double resolveTouch(double fallbackTouch) {
    final value = touchPercent > 0 ? touchPercent : fallbackTouch;
    return value.clamp(0.0, 100.0);
  }

  double fineWeight(double fallbackTouch) =>
      netWeight * (resolveTouch(fallbackTouch) / 100.0);

  double valuationFine(double fallbackTouch) {
    if (valuationFineWeight > 0) {
      return valuationFineWeight;
    }
    return fineWeight(fallbackTouch) + wastageFineWeight;
  }

  double labourAmount({
    required double metalAmount,
    required double fallbackTouch,
  }) {
    return switch (makingChargesType) {
      MakingChargesType.perGram => netWeight * makingCharges,
      MakingChargesType.flat => makingCharges,
      MakingChargesType.percent => metalAmount * makingCharges / 100.0,
    };
  }

  double get costPrice {
    final metalCost = netWeight * purchaseRate;
    final making = switch (makingChargesType) {
      MakingChargesType.perGram => netWeight * makingCharges,
      MakingChargesType.flat => makingCharges,
      MakingChargesType.percent => metalCost * makingCharges / 100.0,
    };
    return metalCost + stoneValue + making;
  }

  double get resolvedCostPrice =>
      purchasePriceOverride > 0 ? purchasePriceOverride : costPrice;

  double get totalCostValue => resolvedCostPrice * quantity;

  double get totalSellingValue =>
      ((mrp > 0 ? mrp : resolvedCostPrice) * quantity);

  bool get hasAnyInput {
    return itemName.trim().isNotEmpty ||
        description.trim().isNotEmpty ||
        companyLabel.trim().isNotEmpty ||
        segmentLabel.trim().isNotEmpty ||
        huid.trim().isNotEmpty ||
        huids.any((value) => value.trim().isNotEmpty) ||
        grossWeight > 0 ||
        stoneWeight > 0 ||
        stoneValue > 0 ||
        touchPercent > 0 ||
        wastageFineWeight > 0 ||
        valuationFineWeight > 0 ||
        stoneCarats > 0 ||
        stonePieces > 0 ||
        purchaseRate > 0 ||
        makingCharges > 0 ||
        mrp > 0 ||
        quantity != 1 ||
        location.trim().isNotEmpty ||
        supplierName.trim().isNotEmpty;
  }
}

enum AddStockStep { purity, items }
