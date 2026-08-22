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
}

PosInvoiceModel _invoice({
  required List<SaleItemModel> saleItems,
  required double grossAmount,
  required double netPayable,
  required double cashPaid,
  required double balanceDue,
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
    balanceDue: balanceDue,
    totalMakingCharge: 0,
    metalPaymentAllocations: allocations,
  );
}
