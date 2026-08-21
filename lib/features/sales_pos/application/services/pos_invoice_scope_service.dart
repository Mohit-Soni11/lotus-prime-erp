import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';

class PosInvoiceScopeService {
  const PosInvoiceScopeService();

  List<MetalType> collectMetals(PosInvoiceModel invoice) {
    final present = <MetalType>{
      ...invoice.saleItems.map((item) => item.metal),
      ...invoice.tradeInItems.map((item) => item.metal),
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

    final crossAdjustments = _crossMetalAdjustments(source, metals);
    return metals
        .map(
          (metal) => scopedInvoiceForMetal(
            source,
            metal,
            crossMetalAdjustmentDeduction: crossAdjustments[metal] ?? 0.0,
            isMetalScopedCopy: metals.length > 1,
          ),
        )
        .toList(growable: false);
  }

  PosInvoiceModel scopedInvoiceForMetal(
    PosInvoiceModel source,
    MetalType? metal, {
    double crossMetalAdjustmentDeduction = 0.0,
    bool isMetalScopedCopy = false,
  }) {
    if (metal == null) return source;

    final scopedSaleItems = source.saleItems
        .where((item) => item.metal == metal)
        .toList(growable: false);
    final scopedOldItems = source.tradeInItems
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
        source.tradeInMode == TradeInAdjustMode.cashAdjust
            ? scopedOldItems.fold(0.0, (sum, item) => sum + item.totalValue)
            : 0.0;
    final scopedNetPayable = source.billingMode == BillingMode.wholesale
        ? scopedGrandTotal
        : scopedGrandTotal - scopedExchangeDeduction;
    final scopedRoundOff = source.isMetalScopedCopy
        ? source.roundOffAmount * grossRatio
        : source.roundOffAmount * grossRatio;
    final adjustedScopedNetPayable =
        scopedNetPayable - crossMetalAdjustmentDeduction + scopedRoundOff;
    final paymentRatio = source.netPayable.abs() <= 0.005
        ? grossRatio
        : adjustedScopedNetPayable / source.netPayable;
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
      invoiceNumber: source.invoiceNumber,
      invoiceDate: source.invoiceDate,
      billType: source.billType,
      gstPricingMode: source.gstPricingMode,
      documentType: source.documentType,
      billingMode: source.billingMode,
      shopName: source.shopName,
      shopAddress: source.shopAddress,
      shopPhone: source.shopPhone,
      shopGstin: source.shopGstin,
      shopStateCode: source.shopStateCode,
      shopLogoPath: source.shopLogoPath,
      shopLogoShape: source.shopLogoShape,
      shopPrintFields: source.shopPrintFields,
      shopPrintProfileApplied: source.shopPrintProfileApplied,
      shopSignaturePath: source.shopSignaturePath,
      shopSignatureShape: source.shopSignatureShape,
      customerName: source.customerName,
      customerMobile: source.customerMobile,
      customerCity: source.customerCity,
      customerPan: source.customerPan,
      customerGstin: source.customerGstin,
      customerStateCode: source.customerStateCode,
      placeOfSupply: source.placeOfSupply,
      tradeInMode: source.tradeInMode,
      customerMetalSettlementType: source.customerMetalSettlementType,
      saleItems: scopedSaleItems,
      tradeInItems: scopedOldItems,
      grossAmount: scopedGrossAmount,
      discountAmount: scopedDiscount,
      taxableAmount: safeTaxable,
      cgst: scopedGst / 2,
      sgst: scopedGst / 2,
      totalGst: scopedGst,
      totalTradeInDeduction: scopedExchangeDeduction,
      crossMetalAdjustmentDeduction: crossMetalAdjustmentDeduction,
      grandTotal: scopedGrandTotal,
      roundOffAmount: scopedRoundOff,
      cashPaid: cashPaid,
      upiPaid: upiPaid,
      cardPaid: cardPaid,
      advancePaid: advancePaid,
      balanceDue: adjustedScopedNetPayable - scopedPaid,
      changeSettlementMethod: source.changeSettlementMethod,
      changeSettlementAmount:
          _splitPayment(source.changeSettlementAmount, paymentRatio),
      changeSettlementPaymentMode: source.changeSettlementPaymentMode,
      totalMakingCharge: scopedMakingCharge,
      promiseDate: source.promiseDate,
      isMetalScopedCopy: isMetalScopedCopy,
    );
  }

  Map<MetalType, double> _crossMetalAdjustments(
    PosInvoiceModel source,
    List<MetalType> metals,
  ) {
    if (metals.length <= 1 ||
        source.billingMode == BillingMode.wholesale ||
        source.netPayable <= 0.005) {
      return const {};
    }

    final netByMetal = {
      for (final metal in metals) metal: _sectionNetPayable(source, metal),
    };
    final excess = netByMetal.values
        .where((net) => net < -0.005)
        .fold(0.0, (sum, net) => sum + net.abs());
    if (excess <= 0.005) return const {};

    final positiveTotal = netByMetal.values
        .where((net) => net > 0.005)
        .fold(0.0, (sum, net) => sum + net);
    if (positiveTotal <= 0.005) return const {};

    return {
      for (final entry in netByMetal.entries)
        if (entry.value > 0.005)
          entry.key: excess * (entry.value / positiveTotal),
    };
  }

  double _sectionNetPayable(PosInvoiceModel source, MetalType metal) {
    final scopedSaleItems = source.saleItems
        .where((item) => item.metal == metal)
        .toList(growable: false);
    final scopedOldItems = source.tradeInItems
        .where((item) => item.metal == metal)
        .toList(growable: false);
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
        source.tradeInMode == TradeInAdjustMode.cashAdjust
            ? scopedOldItems.fold(0.0, (sum, item) => sum + item.totalValue)
            : 0.0;
    return scopedGrandTotal - scopedExchangeDeduction;
  }

  double _splitPayment(double amount, double ratio) {
    if (amount <= 0 || ratio <= 0) return 0.0;
    final value = amount * ratio;
    return value > amount ? amount : value;
  }
}
