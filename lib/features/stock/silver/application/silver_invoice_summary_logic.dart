import 'package:lotus_erp/features/stock/shared/application/stock_intake_valuation_controller.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/features/stock/silver/domain/models/silver_item_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';

// ✨ Added Missing Snapshot Class to bridge the logic
class SilverInvoiceLineSnapshot {
  final String id;
  final String itemName;
  final String companyLabel;
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

  const SilverInvoiceLineSnapshot({
    required this.id,
    required this.itemName,
    required this.companyLabel,
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

class SilverInvoiceSummaryData {
  final List<SilverInvoiceLineSnapshot> items;
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

  const SilverInvoiceSummaryData({
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

  factory SilverInvoiceSummaryData.fromController(SilverStockController ctrl) {
    final valuationSnapshot = ctrl.valuationSnapshot;
    final rows = ctrl.enteredSilverRows;
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

    return SilverInvoiceSummaryData(
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

  static SilverInvoiceLineSnapshot _mapRow(SilverItemModel row) {
    return SilverInvoiceLineSnapshot(
      id: row.id,
      itemName: row.itemName,
      companyLabel:
          row.companyLabel.isEmpty ? 'Local / Unbranded' : row.companyLabel,
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
