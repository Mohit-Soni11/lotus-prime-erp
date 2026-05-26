import 'package:lotus_erp/logic/stock/add_stock_gold/gold_payment_controller.dart';
import 'package:lotus_erp/logic/stock/add_stock_gold/gold_stock_controller.dart';
import 'package:lotus_erp/models/stock/stock_item_model/add_stock_gold/gold_item_model.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';

// ✨ Added Missing Snapshot Class to bridge the logic
class GoldPaymentSnapshot {
  final PaymentMode paymentMode;
  final DueReturnType settlementPreference;
  final GoldDiscountMode discountMode;
  final double ratePer10g;
  final double ratePerGram;
  final double grossFineWeight;
  final double payableFineWeight;
  final double fineDiscountWeight;
  final double cashDiscountAmount;
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
  final double previousSupplierDue;
  final double previousSupplierDueAdjustment;
  final double previousSupplierDueFineEquivalent;
  final String balanceLabel;

  const GoldPaymentSnapshot({
    required this.paymentMode,
    required this.settlementPreference,
    required this.discountMode,
    required this.ratePer10g,
    required this.ratePerGram,
    required this.grossFineWeight,
    required this.payableFineWeight,
    required this.fineDiscountWeight,
    required this.cashDiscountAmount,
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
    required this.previousSupplierDue,
    required this.previousSupplierDueAdjustment,
    required this.previousSupplierDueFineEquivalent,
    required this.balanceLabel,
  });
}

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
  final GoldPaymentSnapshot paymentSnapshot;
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

  factory GoldInvoiceSummaryData.fromController(GoldStockController ctrl) {
    final paymentSnapshot = ctrl.paymentSnapshot;
    final rows = ctrl.enteredGoldRows;
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

    return GoldInvoiceSummaryData(
      items: items,
      paymentSnapshot: paymentSnapshot,
      gstEnabled: ctrl.gstEnabled,
      rowCount: items.length,
      totalPieces: ctrl.totalQuantity,
      totalGrossWeight: ctrl.totalGrossWeight,
      totalFineWeight: paymentSnapshot.payableFineWeight,
      totalMakingAmount: ctrl.totalMakingAmount,
      itemSnapshotAmount: itemSnapshotAmount,
      invoiceSubtotal: paymentSnapshot.subtotalAmount,
      invoiceGstAmount: paymentSnapshot.appliedGstAmount,
      finalBillAmount: paymentSnapshot.totalBillAmount,
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
