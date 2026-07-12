import '../value_objects/gold_purity.dart';
import '../value_objects/gold_weight.dart';
import '../value_objects/money.dart';

enum GoldReceiptSource {
  supplierPurchase,
  customerBuyback,
  karigarReturn,
  internalTransfer,
  openingBalance,
}

enum GoldArticleCategory {
  ring,
  necklace,
  bangle,
  earring,
  pendant,
  bracelet,
  chain,
  mangalsutra,
  coin,
  bullion,
  other,
}

enum GoldMakingChargeMethod {
  perGram,
  perPiece,
  percentageOfMetalValue,
}

final class GoldStoneDetails {
  final String stoneType;
  final int quantity;
  final int totalCaratPoints;
  final Money totalValue;
  final String? certificateNumber;

  const GoldStoneDetails({
    required this.stoneType,
    required this.quantity,
    required this.totalCaratPoints,
    required this.totalValue,
    this.certificateNumber,
  });
}

final class GoldStockReceiptLine {
  final String lineId;
  final GoldArticleCategory category;
  final String itemName;
  final int quantity;
  final GoldWeight grossWeight;
  final GoldWeight stoneWeight;
  final GoldPurity purity;
  final Money ratePerGram;
  final Money makingCharge;
  final GoldMakingChargeMethod makingChargeMethod;
  final String? hallmarkUniqueId;
  final GoldStoneDetails? stoneDetails;

  const GoldStockReceiptLine({
    required this.lineId,
    required this.category,
    required this.itemName,
    required this.quantity,
    required this.grossWeight,
    required this.stoneWeight,
    required this.purity,
    required this.ratePerGram,
    required this.makingCharge,
    required this.makingChargeMethod,
    this.hallmarkUniqueId,
    this.stoneDetails,
  });

  GoldWeight get netWeight => grossWeight - stoneWeight;

  GoldWeight get fineWeight => purity.fineWeightOf(netWeight);

  Money get metalValue => Money(
        paise: (fineWeight.milligrams * ratePerGram.paise / 1000).round(),
        currencyCode: ratePerGram.currencyCode,
      );

  Money get totalMakingCharge {
    return switch (makingChargeMethod) {
      GoldMakingChargeMethod.perGram => Money(
          paise: (netWeight.milligrams * makingCharge.paise / 1000).round(),
          currencyCode: makingCharge.currencyCode,
        ),
      GoldMakingChargeMethod.perPiece =>
        makingCharge.multiplyByQuantity(quantity),
      GoldMakingChargeMethod.percentageOfMetalValue =>
        metalValue.percentageFromBasisPoints(makingCharge.paise),
    };
  }

  Money get totalStoneValue =>
      stoneDetails?.totalValue ??
      Money.zero(currencyCode: ratePerGram.currencyCode);

  Money get totalCost => metalValue + totalMakingCharge + totalStoneValue;
}

final class GoldStockReceipt {
  final String receiptNumber;
  final GoldReceiptSource source;
  final int supplierId;
  final String supplierName;
  final String? supplierInvoiceNumber;
  final String? createdByUserId;
  final DateTime receivedAt;
  final List<GoldStockReceiptLine> lines;

  const GoldStockReceipt({
    required this.receiptNumber,
    required this.source,
    required this.supplierId,
    required this.supplierName,
    required this.receivedAt,
    required this.lines,
    this.supplierInvoiceNumber,
    this.createdByUserId,
  });

  GoldWeight get totalGrossWeight => lines.fold(
        GoldWeight.zero,
        (total, line) => total + line.grossWeight,
      );

  GoldWeight get totalFineWeight => lines.fold(
        GoldWeight.zero,
        (total, line) => total + line.fineWeight,
      );

  Money get totalCost => lines.fold(
        const Money.zero(),
        (total, line) => total + line.totalCost,
      );
}
