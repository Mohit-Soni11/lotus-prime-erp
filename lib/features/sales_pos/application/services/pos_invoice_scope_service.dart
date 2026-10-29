import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import '../../domain/services/pos_metal_payment_allocator.dart';

class PosInvoiceScopeService {
  const PosInvoiceScopeService();

  static const _allocator = PosMetalPaymentAllocator();

  List<MetalType> collectMetals(PosInvoiceModel invoice) {
    return _allocator.collectMetals(
      saleItems: invoice.saleItems,
      tradeInItems: invoice.tradeInItems,
    );
  }

  List<PosInvoiceModel> scopedInvoicesForAllMetals(PosInvoiceModel source) {
    final metals = collectMetals(source);
    if (metals.isEmpty) return [source];

    final crossAdjustments = _crossMetalAdjustments(source, metals);
    final scoped = metals
        .map(
          (metal) => _baseScopedInvoiceForMetal(
            source,
            metal,
            crossMetalAdjustmentDeduction: crossAdjustments[metal] ?? 0.0,
            isMetalScopedCopy: metals.length > 1,
          ),
        )
        .toList(growable: false);
    return _applyDueCollection(scoped, source.dueCollectionPaid);
  }

  PosInvoiceModel scopedInvoiceForMetal(
    PosInvoiceModel source,
    MetalType? metal,
  ) {
    if (metal == null) return source;
    final metals = collectMetals(source);
    final index = metals.indexOf(metal);
    if (index < 0) return source;
    return scopedInvoicesForAllMetals(source)[index];
  }

  PosInvoiceModel _baseScopedInvoiceForMetal(
    PosInvoiceModel source,
    MetalType metal, {
    double crossMetalAdjustmentDeduction = 0.0,
    bool isMetalScopedCopy = false,
  }) {
    final scopedSaleItems = source.saleItems
        .where((item) => item.metal == metal)
        .toList(growable: false);
    final scopedOldItems = source.tradeInItems
        .where((item) => item.metal == metal)
        .toList(growable: false);

    if (scopedSaleItems.isEmpty && scopedOldItems.isEmpty) {
      return source;
    }

    final itemGrossAmount =
        scopedSaleItems.fold(0.0, (sum, item) => sum + item.totalValue);
    final manualAllocation = _metalPaymentAllocationFor(source, metal);
    final scopedGrossAmount =
        manualAllocation != null && manualAllocation.grossAmount > 0
            ? manualAllocation.grossAmount
            : itemGrossAmount;
    final grossRatio = source.grossAmount.abs() <= 0.005
        ? 0.0
        : scopedGrossAmount / source.grossAmount;
    final scopedDiscount =
        manualAllocation?.discountAmount ?? source.discountAmount * grossRatio;
    final amountAfterDiscount = scopedGrossAmount - scopedDiscount;
    final safeAfterDiscount =
        amountAfterDiscount < 0 ? 0.0 : amountAfterDiscount;
    final taxRatio = source.taxableAmount.abs() <= 0.005
        ? grossRatio
        : safeAfterDiscount / source.taxableAmount;
    final scopedGst = manualAllocation?.gstAmount ?? source.totalGst * taxRatio;
    final scopedGrandTotal = source.gstPricingMode == GstPricingMode.inclusive
        ? safeAfterDiscount
        : safeAfterDiscount + scopedGst;
    final scopedTaxable = source.gstPricingMode == GstPricingMode.inclusive
        ? safeAfterDiscount - scopedGst
        : safeAfterDiscount;
    final scopedExchangeDeduction =
        source.tradeInMode == TradeInAdjustMode.cashAdjust
            ? scopedOldItems.fold(0.0, (sum, item) => sum + item.totalValue)
            : 0.0;
    final scopedNetPayable = source.billingMode == BillingMode.wholesale
        ? scopedGrandTotal
        : scopedGrandTotal - scopedExchangeDeduction;
    final scopedRoundOff = source.roundOffAmount * grossRatio;
    final scopedCrossDeduction =
        manualAllocation == null || source.billingMode == BillingMode.wholesale
            ? crossMetalAdjustmentDeduction
            : scopedNetPayable + scopedRoundOff - manualAllocation.netPayable;
    final adjustedScopedNetPayable = manualAllocation?.netPayable ??
        scopedNetPayable - crossMetalAdjustmentDeduction + scopedRoundOff;
    final paymentRatio = source.netPayable.abs() <= 0.005
        ? grossRatio
        : adjustedScopedNetPayable / source.netPayable;
    final cashPaid = manualAllocation?.cashPaid ??
        _splitPayment(source.cashPaid, paymentRatio);
    final upiPaid = manualAllocation?.upiPaid ??
        _splitPayment(source.upiPaid, paymentRatio);
    final cardPaid = manualAllocation?.cardPaid ??
        _splitPayment(source.cardPaid, paymentRatio);
    final advancePaid = manualAllocation?.advancePaid ??
        _splitPayment(source.advancePaid, paymentRatio);
    final scopedPaid = cashPaid + upiPaid + cardPaid + advancePaid;
    final scopedMakingCharge = scopedSaleItems.fold(
      0.0,
      (sum, item) =>
          sum +
          (source.billingMode == BillingMode.wholesale
              ? item.wholesaleLabourAmt
              : item.makingAmt),
    );

    return source.copyWith(
      saleItems: scopedSaleItems,
      tradeInItems: scopedOldItems,
      grossAmount: scopedGrossAmount,
      discountAmount: scopedDiscount,
      taxableAmount: scopedTaxable,
      cgst: scopedGst / 2,
      sgst: scopedGst / 2,
      totalGst: scopedGst,
      totalTradeInDeduction: scopedExchangeDeduction,
      crossMetalAdjustmentDeduction: scopedCrossDeduction,
      grandTotal: scopedGrandTotal,
      roundOffAmount: scopedRoundOff,
      cashPaid: cashPaid,
      upiPaid: upiPaid,
      cardPaid: cardPaid,
      advancePaid: advancePaid,
      dueCollectionPaid: 0,
      balanceDue: adjustedScopedNetPayable - scopedPaid,
      changeSettlementMethod: source.changeSettlementMethod,
      changeSettlementAmount:
          _splitPayment(source.changeSettlementAmount, paymentRatio),
      totalMakingCharge: scopedMakingCharge,
      isMetalScopedCopy: isMetalScopedCopy,
    );
  }

  List<PosInvoiceModel> _applyDueCollection(
    List<PosInvoiceModel> scoped,
    double collection,
  ) {
    if (collection <= 0.005) return scoped;
    final dueCents = scoped
        .map((invoice) =>
            invoice.balanceDue <= 0 ? 0 : (invoice.balanceDue * 100).round())
        .toList(growable: false);
    final totalDueCents = dueCents.fold<int>(0, (sum, value) => sum + value);
    if (totalDueCents == 0) return scoped;

    var remainingCents = (collection * 100).round().clamp(0, totalDueCents);
    var remainingDueCents = totalDueCents;
    final revised = <PosInvoiceModel>[];
    for (var index = 0; index < scoped.length; index++) {
      final available = dueCents[index];
      final allocated = available == 0 || remainingDueCents == 0
          ? 0
          : index == scoped.length - 1
              ? remainingCents.clamp(0, available)
              : (remainingCents * available / remainingDueCents)
                  .round()
                  .clamp(0, available);
      remainingCents -= allocated;
      remainingDueCents -= available;
      revised.add(scoped[index].copyWith(
        dueCollectionPaid: allocated / 100,
        balanceDue: (available - allocated) / 100,
      ));
    }
    return revised;
  }

  PosInvoiceMetalPaymentAllocation? _metalPaymentAllocationFor(
    PosInvoiceModel source,
    MetalType metal,
  ) {
    for (final allocation in source.metalPaymentAllocations) {
      if (allocation.metal == metal) return allocation;
    }
    return null;
  }

  Map<MetalType, double> _crossMetalAdjustments(
    PosInvoiceModel source,
    List<MetalType> metals,
  ) {
    if (metals.length <= 1 ||
        source.billingMode == BillingMode.wholesale ||
        source.metalPaymentAllocations.isNotEmpty ||
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
    final saved = _metalPaymentAllocationFor(source, metal);
    if (saved != null) return saved.netPayable;
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
