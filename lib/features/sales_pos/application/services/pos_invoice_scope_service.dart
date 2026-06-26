import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';

class PosInvoiceScopeService {
  const PosInvoiceScopeService();

  List<MetalType> collectMetals(PosInvoiceModel invoice) {
    final present = <MetalType>{
      ...invoice.saleItems.map((item) => item.metal),
      ...invoice.oldGoldItems.map((item) => item.metal),
    };
    const ordered = [
      MetalType.gold,
      MetalType.silver,
      MetalType.platinum,
      MetalType.diamond,
    ];
    return ordered.where(present.contains).toList();
  }

  List<PosInvoiceModel> scopedInvoicesForAllMetals(PosInvoiceModel source) {
    final metals = collectMetals(source);
    if (metals.isEmpty) return [source];

    return metals
        .map((metal) => scopedInvoiceForMetal(source, metal))
        .toList(growable: false);
  }

  PosInvoiceModel scopedInvoiceForMetal(
    PosInvoiceModel source,
    MetalType? metal,
  ) {
    if (metal == null) return source;

    final scopedSaleItems = source.saleItems
        .where((item) => item.metal == metal)
        .toList(growable: false);
    final scopedOldItems = source.oldGoldItems
        .where((item) => item.metal == metal)
        .toList(growable: false);

    if (scopedSaleItems.isEmpty && scopedOldItems.isEmpty) {
      return source;
    }

    final scopedGrossAmount =
        scopedSaleItems.fold(0.0, (sum, item) => sum + item.totalValue);
    final grossRatio = source.grossAmount.abs() <= 0.005
        ? 0.0
        : scopedGrossAmount / source.grossAmount;
    final scopedDiscount = source.discountAmount * grossRatio;
    final scopedTaxable = scopedGrossAmount - scopedDiscount;
    final safeTaxable = scopedTaxable < 0 ? 0.0 : scopedTaxable;
    final taxRatio = source.taxableAmount.abs() <= 0.005
        ? grossRatio
        : safeTaxable / source.taxableAmount;
    final scopedGst = source.totalGst * taxRatio;
    final scopedGrandTotal = safeTaxable + scopedGst;
    final scopedExchangeDeduction =
        source.oldGoldMode == OldGoldAdjustMode.cashAdjust
            ? scopedOldItems.fold(0.0, (sum, item) => sum + item.totalValue)
            : 0.0;
    final scopedNetPayable = source.billingMode == BillingMode.wholesale
        ? scopedGrandTotal
        : scopedGrandTotal - scopedExchangeDeduction;
    final paymentRatio = source.netPayable.abs() <= 0.005
        ? grossRatio
        : scopedNetPayable / source.netPayable;
    final cashPaid = _splitPayment(source.cashPaid, paymentRatio);
    final upiPaid = _splitPayment(source.upiPaid, paymentRatio);
    final cardPaid = _splitPayment(source.cardPaid, paymentRatio);
    final advancePaid = _splitPayment(source.advancePaid, paymentRatio);
    final scopedPaid = cashPaid + upiPaid + cardPaid + advancePaid;
    final scopedMakingCharge = scopedSaleItems.fold(
      0.0,
      (sum, item) =>
          sum +
          (source.billingMode == BillingMode.wholesale
              ? item.wholesaleLabourAmt
              : item.makingAmt),
    );

    return PosInvoiceModel(
      invoiceNumber: _metalInvoiceNumber(source, metal),
      invoiceDate: source.invoiceDate,
      billType: source.billType,
      billingMode: source.billingMode,
      shopName: source.shopName,
      shopAddress: source.shopAddress,
      shopPhone: source.shopPhone,
      shopGstin: source.shopGstin,
      customerName: source.customerName,
      customerMobile: source.customerMobile,
      customerCity: source.customerCity,
      customerPan: source.customerPan,
      customerGstin: source.customerGstin,
      oldGoldMode: source.oldGoldMode,
      saleItems: scopedSaleItems,
      oldGoldItems: scopedOldItems,
      grossAmount: scopedGrossAmount,
      discountAmount: scopedDiscount,
      taxableAmount: safeTaxable,
      cgst: scopedGst / 2,
      sgst: scopedGst / 2,
      totalGst: scopedGst,
      totalOldGoldDeduction: scopedExchangeDeduction,
      grandTotal: scopedGrandTotal,
      cashPaid: cashPaid,
      upiPaid: upiPaid,
      cardPaid: cardPaid,
      advancePaid: advancePaid,
      balanceDue: scopedNetPayable - scopedPaid,
      changeSettlementMethod: source.changeSettlementMethod,
      changeSettlementAmount:
          _splitPayment(source.changeSettlementAmount, paymentRatio),
      changeSettlementPaymentMode: source.changeSettlementPaymentMode,
      totalMakingCharge: scopedMakingCharge,
      promiseDate: source.promiseDate,
    );
  }

  double _splitPayment(double amount, double ratio) {
    if (amount <= 0 || ratio <= 0) return 0.0;
    final value = amount * ratio;
    return value > amount ? amount : value;
  }

  String _metalInvoiceNumber(PosInvoiceModel source, MetalType metal) {
    if (collectMetals(source).length <= 1) return source.invoiceNumber;
    return '${source.invoiceNumber}-${metal.displayName.toUpperCase()}';
  }
}
