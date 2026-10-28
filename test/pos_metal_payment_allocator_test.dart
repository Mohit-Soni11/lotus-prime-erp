import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/sales_pos/application/services/pos_invoice_scope_service.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_metal_payment_allocator.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';

void main() {
  test('settle-first metal keeps selected metal fully paid in scoped PDFs', () {
    final gold = SaleItemModel(metal: MetalType.gold);
    gold.descCtrl.text = 'Gold Ring';
    gold.grossCtrl.text = '1';
    gold.rateCtrl.text = '6000';

    final silver = SaleItemModel(metal: MetalType.silver);
    silver.descCtrl.text = 'Silver Chain';
    silver.grossCtrl.text = '1';
    silver.rateCtrl.text = '2000';

    final allocations = const PosMetalPaymentAllocator().allocate(
      saleItems: [gold, silver],
      tradeInItems: const [],
      billingMode: BillingMode.retail,
      tradeInMode: TradeInAdjustMode.cashAdjust,
      grossAmount: 8000,
      discountAmount: 0,
      taxableAmount: 8000,
      totalGst: 0,
      roundOffAmount: 0,
      netPayable: 8000,
      cashPaid: 7000,
      upiPaid: 0,
      cardPaid: 0,
      advancePaid: 0,
      settleFirstMetals: {MetalType.gold},
    );

    final invoice = _invoice(
      saleItems: [gold, silver],
      grossAmount: 8000,
      netPayable: 8000,
      cashPaid: 7000,
      balanceDue: 1000,
      allocations: allocations,
    );

    const scope = PosInvoiceScopeService();
    final goldInvoice = scope.scopedInvoiceForMetal(invoice, MetalType.gold);
    final silverInvoice =
        scope.scopedInvoiceForMetal(invoice, MetalType.silver);

    expect(goldInvoice.netPayable, 6000);
    expect(goldInvoice.cashPaid, 6000);
    expect(goldInvoice.balanceDue, 0);

    expect(silverInvoice.netPayable, 2000);
    expect(silverInvoice.cashPaid, 1000);
    expect(silverInvoice.balanceDue, 1000);
  });

  test('settle-first silver leaves remaining due on gold', () {
    final gold = SaleItemModel(metal: MetalType.gold);
    gold.grossCtrl.text = '1';
    gold.rateCtrl.text = '6000';

    final silver = SaleItemModel(metal: MetalType.silver);
    silver.grossCtrl.text = '1';
    silver.rateCtrl.text = '2000';

    final allocations = const PosMetalPaymentAllocator().allocate(
      saleItems: [gold, silver],
      tradeInItems: const [],
      billingMode: BillingMode.retail,
      tradeInMode: TradeInAdjustMode.cashAdjust,
      grossAmount: 8000,
      discountAmount: 0,
      taxableAmount: 8000,
      totalGst: 0,
      roundOffAmount: 0,
      netPayable: 8000,
      cashPaid: 7000,
      upiPaid: 0,
      cardPaid: 0,
      advancePaid: 0,
      settleFirstMetals: {MetalType.silver},
    );

    final invoice = _invoice(
      saleItems: [gold, silver],
      grossAmount: 8000,
      netPayable: 8000,
      cashPaid: 7000,
      balanceDue: 1000,
      allocations: allocations,
    );

    const scope = PosInvoiceScopeService();
    final goldInvoice = scope.scopedInvoiceForMetal(invoice, MetalType.gold);
    final silverInvoice =
        scope.scopedInvoiceForMetal(invoice, MetalType.silver);

    expect(silverInvoice.netPayable, 2000);
    expect(silverInvoice.cashPaid, 2000);
    expect(silverInvoice.balanceDue, 0);

    expect(goldInvoice.netPayable, 6000);
    expect(goldInvoice.cashPaid, 5000);
    expect(goldInvoice.balanceDue, 1000);
  });

  test('due collection is split by each metal outstanding balance', () {
    final gold = SaleItemModel(metal: MetalType.gold);
    gold.grossCtrl.text = '1';
    gold.rateCtrl.text = '65038.68';
    final silver = SaleItemModel(metal: MetalType.silver);
    silver.grossCtrl.text = '1';
    silver.rateCtrl.text = '5103.32';

    final invoice = _invoice(
      saleItems: [gold, silver],
      grossAmount: 70142,
      netPayable: 70142,
      cashPaid: 65000,
      balanceDue: 0,
      dueCollectionPaid: 5142,
      allocations: const [
        PosInvoiceMetalPaymentAllocation(
          metal: MetalType.gold,
          netPayable: 65038.68,
          cashPaid: 60270.80,
        ),
        PosInvoiceMetalPaymentAllocation(
          metal: MetalType.silver,
          netPayable: 5103.32,
          cashPaid: 4729.20,
        ),
      ],
    );

    final scoped =
        const PosInvoiceScopeService().scopedInvoicesForAllMetals(invoice);
    expect(scoped, hasLength(2));
    expect(scoped[0].dueCollectionPaid, 4767.88);
    expect(scoped[1].dueCollectionPaid, 374.12);
    expect(scoped.every((item) => item.paymentStatus == PaymentStatus.paid),
        isTrue);
    expect(scoped[0].totalPaid, closeTo(scoped[0].netPayable, 0.01));
    expect(scoped[1].totalPaid, closeTo(scoped[1].netPayable, 0.01));
    expect(
      const PosInvoiceScopeService()
          .scopedInvoiceForMetal(invoice, MetalType.silver)
          .dueCollectionPaid,
      374.12,
    );

    final partial = const PosInvoiceScopeService().scopedInvoicesForAllMetals(
      invoice.copyWith(dueCollectionPaid: 1000, balanceDue: 4142),
    );
    expect(
      partial.fold<double>(0, (sum, item) => sum + item.dueCollectionPaid),
      closeTo(1000, 0.01),
    );
    expect(
      partial.fold<double>(0, (sum, item) => sum + item.balanceDue),
      closeTo(4142, 0.01),
    );
  });

  test('paid metal sections remain paid when another metal due is collected',
      () {
    final gold = SaleItemModel(metal: MetalType.gold)
      ..grossCtrl.text = '1'
      ..rateCtrl.text = '100';
    final silver = SaleItemModel(metal: MetalType.silver)
      ..grossCtrl.text = '1'
      ..rateCtrl.text = '100';
    final platinum = SaleItemModel(metal: MetalType.platinum)
      ..grossCtrl.text = '1'
      ..rateCtrl.text = '100';
    final invoice = _invoice(
      saleItems: [gold, silver, platinum],
      grossAmount: 300,
      netPayable: 300,
      cashPaid: 200,
      balanceDue: 0,
      dueCollectionPaid: 100,
      allocations: const [
        PosInvoiceMetalPaymentAllocation(
            metal: MetalType.gold, netPayable: 100),
        PosInvoiceMetalPaymentAllocation(
            metal: MetalType.silver, netPayable: 100, cashPaid: 100),
        PosInvoiceMetalPaymentAllocation(
            metal: MetalType.platinum, netPayable: 100, cashPaid: 100),
      ],
    );
    final scoped =
        const PosInvoiceScopeService().scopedInvoicesForAllMetals(invoice);
    expect(scoped.map((item) => item.dueCollectionPaid), [100, 0, 0]);
    expect(scoped.every((item) => item.paymentStatus == PaymentStatus.paid),
        isTrue);
  });
}

PosInvoiceModel _invoice({
  required List<SaleItemModel> saleItems,
  required double grossAmount,
  required double netPayable,
  required double cashPaid,
  required double balanceDue,
  double dueCollectionPaid = 0,
  required List<PosInvoiceMetalPaymentAllocation> allocations,
}) {
  return PosInvoiceModel(
    invoiceNumber: 'AJ-TEST',
    invoiceDate: DateTime(2026, 8, 22),
    billType: BillType.gst,
    billingMode: BillingMode.retail,
    shopName: 'ANJALI JEWELLERS',
    shopAddress: 'Patna',
    shopPhone: '9304479436',
    shopGstin: '10AAGFF2194N1Z1',
    customerName: 'REYANSH SONI',
    customerMobile: '9304479436',
    customerCity: 'Patna',
    customerPan: '',
    customerGstin: '',
    tradeInMode: TradeInAdjustMode.cashAdjust,
    saleItems: saleItems,
    tradeInItems: const [],
    grossAmount: grossAmount,
    discountAmount: 0,
    taxableAmount: grossAmount,
    cgst: 0,
    sgst: 0,
    totalGst: 0,
    totalTradeInDeduction: 0,
    grandTotal: netPayable,
    cashPaid: cashPaid,
    upiPaid: 0,
    cardPaid: 0,
    advancePaid: 0,
    dueCollectionPaid: dueCollectionPaid,
    balanceDue: balanceDue,
    totalMakingCharge: 0,
    metalPaymentAllocations: allocations,
  );
}
