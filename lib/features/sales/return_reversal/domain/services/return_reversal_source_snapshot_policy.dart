import '../models/return_reversal_source_document.dart';

/// Rejects a posted action when its reviewed source changed meanwhile.
class ReturnReversalSourceSnapshotPolicy {
  const ReturnReversalSourceSnapshotPolicy();

  bool matches(
    ReturnReversalSourceDocument reviewed,
    ReturnReversalSourceDocument current,
  ) {
    if (reviewed.id != current.id ||
        reviewed.type != current.type ||
        reviewed.documentNo != current.documentNo ||
        reviewed.customerId != current.customerId ||
        reviewed.customerName != current.customerName ||
        reviewed.mobile != current.mobile ||
        reviewed.address != current.address ||
        reviewed.documentDate != current.documentDate ||
        reviewed.lineItems.length != current.lineItems.length ||
        reviewed.reversalStatus != current.reversalStatus ||
        reviewed.reversalVoucherNo != current.reversalVoucherNo ||
        reviewed.reversedLineCount != current.reversedLineCount ||
        !_sameMoney(reviewed.grossValue, current.grossValue) ||
        !_sameMoney(reviewed.finalAmount, current.finalAmount) ||
        !_sameMoney(reviewed.paidAmount, current.paidAmount) ||
        !_sameMoney(reviewed.cashPaid, current.cashPaid) ||
        !_sameMoney(reviewed.upiPaid, current.upiPaid) ||
        !_sameMoney(reviewed.cardPaid, current.cardPaid) ||
        !_sameMoney(reviewed.advancePaid, current.advancePaid) ||
        !_sameMoney(reviewed.dueAmount, current.dueAmount) ||
        !_sameMoney(reviewed.discountAmount, current.discountAmount) ||
        !_sameMoney(reviewed.taxableAmount, current.taxableAmount) ||
        !_sameMoney(reviewed.cgstAmount, current.cgstAmount) ||
        !_sameMoney(reviewed.sgstAmount, current.sgstAmount) ||
        !_sameMoney(reviewed.igstAmount, current.igstAmount) ||
        !_sameMoney(reviewed.gstAmount, current.gstAmount) ||
        !_sameMoney(reviewed.makingTotal, current.makingTotal) ||
        !_sameMoney(reviewed.roundOffAmount, current.roundOffAmount) ||
        !_sameMoney(reviewed.tradeInDeduction, current.tradeInDeduction) ||
        !_sameWeight(reviewed.netWeight, current.netWeight) ||
        reviewed.paymentStatus != current.paymentStatus ||
        reviewed.billingMode != current.billingMode ||
        reviewed.gstPricingMode != current.gstPricingMode) {
      return false;
    }

    for (var index = 0; index < reviewed.lineItems.length; index++) {
      final oldLine = reviewed.lineItems[index];
      final newLine = current.lineItems[index];
      if (oldLine.lineNo != newLine.lineNo ||
          oldLine.sourceLineId != newLine.sourceLineId ||
          oldLine.description != newLine.description ||
          oldLine.metalType != newLine.metalType ||
          oldLine.hsnCode != newLine.hsnCode ||
          oldLine.purity != newLine.purity ||
          oldLine.huidNumber != newLine.huidNumber ||
          oldLine.quantity != newLine.quantity ||
          oldLine.quantityUnitCode != newLine.quantityUnitCode ||
          oldLine.lessWeightPerPiece != newLine.lessWeightPerPiece ||
          oldLine.linkedStockItemId != newLine.linkedStockItemId ||
          oldLine.linkedStockUnitId != newLine.linkedStockUnitId ||
          oldLine.linkedStockSku != newLine.linkedStockSku ||
          oldLine.status != newLine.status ||
          oldLine.reversalStatus != newLine.reversalStatus ||
          oldLine.reversalVoucherNo != newLine.reversalVoucherNo ||
          oldLine.reversalDate != newLine.reversalDate ||
          !_sameWeight(oldLine.grossWeight, newLine.grossWeight) ||
          !_sameWeight(oldLine.lessWeight, newLine.lessWeight) ||
          !_sameWeight(oldLine.netWeight, newLine.netWeight) ||
          !_sameWeight(oldLine.fineWeight, newLine.fineWeight) ||
          !_sameMoney(oldLine.rate, newLine.rate) ||
          !_sameMoney(oldLine.value, newLine.value) ||
          oldLine.makingChargeType != newLine.makingChargeType ||
          !_sameMoney(oldLine.makingChargeInput, newLine.makingChargeInput) ||
          !_sameMoney(oldLine.makingAmount, newLine.makingAmount) ||
          !_sameMoney(oldLine.discountAmount, newLine.discountAmount) ||
          !_sameMoney(oldLine.taxableAmount, newLine.taxableAmount) ||
          !_sameMoney(oldLine.gstAmount, newLine.gstAmount) ||
          !_sameMoney(oldLine.invoiceValue, newLine.invoiceValue)) {
        return false;
      }
    }
    return true;
  }

  bool _sameMoney(double left, double right) => (left - right).abs() < 0.005;
  bool _sameWeight(double left, double right) => (left - right).abs() < 0.0001;
}
