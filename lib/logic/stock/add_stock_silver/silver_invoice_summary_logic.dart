import 'package:lotus_erp/logic/stock/add_stock_silver/silver_payment_controller.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/models/stock/stock_item_model/add_stock_silver/silver_item_model.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';

// ✨ Added Missing Snapshot Class to bridge the logic
class SilverPaymentSnapshot {
  final PaymentMode paymentMode;
  final DueReturnType settlementPreference;
  final double ratePerKg;
  final double ratePerGram;
  final double fineValueAmount;
  final double totalMakingAmount;
  final double subtotalAmount;
  final double gstPercent;
  final double appliedGstAmount;
  final double totalBillAmount;
  final double cashPaid;
  final double upiPaid;
  final double bankingPaid;
  final double cardPaid;
  final double cashBankPaidTotal;
  final double totalPaidValue;
  final double dueAmount;
  final double returnAmount;
  final bool hasDue;
  final bool hasReturn;
  final bool isSettled;
  final double metalGrossWeight;
  final double metalPurity;
  final double metalFineCalculated;
  final double metalPaidValue;
  final double metalFineShortage;
  final double metalFineExcess;
  final double metalFineShortageValue;
  final double metalFineExcessValue;
  final double metalFineEquivalentCash;
  final double cashTargetAmount;
  final String balanceLabel;

  const SilverPaymentSnapshot({
    required this.paymentMode,
    required this.settlementPreference,
    required this.ratePerKg,
    required this.ratePerGram,
    required this.fineValueAmount,
    required this.totalMakingAmount,
    required this.subtotalAmount,
    required this.gstPercent,
    required this.appliedGstAmount,
    required this.totalBillAmount,
    required this.cashPaid,
    required this.upiPaid,
    required this.bankingPaid,
    required this.cardPaid,
    required this.cashBankPaidTotal,
    required this.totalPaidValue,
    required this.dueAmount,
    required this.returnAmount,
    required this.hasDue,
    required this.hasReturn,
    required this.isSettled,
    required this.metalGrossWeight,
    required this.metalPurity,
    required this.metalFineCalculated,
    required this.metalPaidValue,
    required this.metalFineShortage,
    required this.metalFineExcess,
    required this.metalFineShortageValue,
    required this.metalFineExcessValue,
    required this.metalFineEquivalentCash,
    required this.cashTargetAmount,
    required this.balanceLabel,
  });
}

class SilverInvoiceLineSnapshot {
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

  const SilverInvoiceLineSnapshot({
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

class SilverInvoiceSummaryData {
  final List<SilverInvoiceLineSnapshot> items;
  final SilverPaymentSnapshot paymentSnapshot;
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
    required this.paymentSnapshot,
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
    final paymentSnapshot = ctrl.paymentSnapshot;
    final rows = ctrl.enteredSilverRows;
    final items = rows.map((row) => _mapRow(row)).toList(growable: false);

    final itemSnapshotAmount = items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalAmount,
    );

    final hasRateVariance = paymentSnapshot.ratePerGram > 0 &&
        items.any(
          (item) =>
              (item.ratePerGram - paymentSnapshot.ratePerGram).abs() > 0.0001,
        );

    return SilverInvoiceSummaryData(
      items: items,
      paymentSnapshot: paymentSnapshot,
      gstEnabled: ctrl.gstEnabled,
      rowCount: items.length,
      totalPieces: ctrl.totalQuantity,
      totalGrossWeight: ctrl.totalGrossWeight,
      totalFineWeight: ctrl.totalFineWeight,
      totalMakingAmount: ctrl.totalMakingAmount,
      itemSnapshotAmount: itemSnapshotAmount,
      invoiceSubtotal: paymentSnapshot.subtotalAmount,
      invoiceGstAmount: paymentSnapshot.appliedGstAmount,
      finalBillAmount: paymentSnapshot.totalBillAmount,
      hasRateVariance: hasRateVariance,
    );
  }

  static SilverInvoiceLineSnapshot _mapRow(SilverItemModel row) {
    return SilverInvoiceLineSnapshot(
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
