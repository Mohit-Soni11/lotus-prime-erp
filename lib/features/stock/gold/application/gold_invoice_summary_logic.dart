import 'package:lotus_erp/features/stock/shared/application/stock_intake_valuation_controller.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/features/stock/gold/domain/models/gold_item_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';

class GoldInvoiceLineSnapshot {
  final String id;
  final String itemName;
  final String categoryLabel;
  final String purityLabel;
  final int pieces;
  final double grossWeight;
  final double netWeight;
  final double fineWeight;
  final double totalPurityPercent;
  final double ratePerGram;
  final double makingValue;
  final double makingAmount;
  final MakingChargesType makingType;
  final double totalAmount;

  const GoldInvoiceLineSnapshot({
    required this.id,
    required this.itemName,
    required this.categoryLabel,
    required this.purityLabel,
    required this.pieces,
    required this.grossWeight,
    required this.netWeight,
    required this.fineWeight,
    required this.totalPurityPercent,
    required this.ratePerGram,
    required this.makingValue,
    required this.makingAmount,
    required this.makingType,
    required this.totalAmount,
  });

  String get makingTypeLabel {
    return switch (makingType) {
      MakingChargesType.perGram => 'Per Gram',
      MakingChargesType.flat => 'Flat',
      MakingChargesType.percent => 'Percent',
    };
  }
}

class GoldInvoiceSummaryData {
  final List<GoldInvoiceLineSnapshot> items;
  final StockIntakeValuationSnapshot valuationSnapshot;
  final bool gstEnabled;
  final int rowCount;
  final int totalPieces;
  final double totalGrossWeight;
  final double totalFineWeight;
  final double totalMakingAmount;
  final double itemSnapshotAmount;
  final double invoiceSubtotal;
  final double invoiceGstAmount;
  final double finalBillAmount;
  final bool hasRateVariance;

  const GoldInvoiceSummaryData({
    required this.items,
    required this.valuationSnapshot,
    required this.gstEnabled,
    required this.rowCount,
    required this.totalPieces,
    required this.totalGrossWeight,
    required this.totalFineWeight,
    required this.totalMakingAmount,
    required this.itemSnapshotAmount,
    required this.invoiceSubtotal,
    required this.invoiceGstAmount,
    required this.finalBillAmount,
    required this.hasRateVariance,
  });

  bool get hasItems => items.isNotEmpty;

  factory GoldInvoiceSummaryData.fromController(GoldStockController ctrl) {
    final valuationSnapshot = ctrl.valuationSnapshot;
    final rows = ctrl.enteredGoldRows;
    final items = rows.map((row) => _mapRow(row)).toList(growable: false);

    final itemSnapshotAmount = items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalAmount,
    );

    final hasRateVariance = valuationSnapshot.ratePerGram > 0 &&
        items.any(
          (item) =>
              (item.ratePerGram - valuationSnapshot.ratePerGram).abs() > 0.0001,
        );

    return GoldInvoiceSummaryData(
      items: items,
      valuationSnapshot: valuationSnapshot,
      gstEnabled: ctrl.gstEnabled,
      rowCount: items.length,
      totalPieces: ctrl.totalQuantity,
      totalGrossWeight: ctrl.totalGrossWeight,
      totalFineWeight: valuationSnapshot.fineWeight,
      totalMakingAmount: ctrl.totalMakingAmount,
      itemSnapshotAmount: itemSnapshotAmount,
      invoiceSubtotal: valuationSnapshot.subtotalAmount,
      invoiceGstAmount: valuationSnapshot.gstAmount,
      finalBillAmount: valuationSnapshot.totalAmount,
      hasRateVariance: hasRateVariance,
    );
  }

  static GoldInvoiceLineSnapshot _mapRow(GoldItemModel row) {
    return GoldInvoiceLineSnapshot(
      id: row.id,
      itemName: row.itemName,
      categoryLabel: row.categoryLabel,
      purityLabel: row.purityLabel,
      pieces: row.pieces,
      grossWeight: row.grossWeight,
      netWeight: row.netWeight,
      fineWeight: row.fineWeight,
      totalPurityPercent: row.totalPurityPercent,
      ratePerGram: row.purchaseRate,
      makingValue: row.makingValue,
      makingAmount: row.makingAmount,
      makingType: row.makingChargesType,
      totalAmount: row.totalAmount,
    );
  }
}
