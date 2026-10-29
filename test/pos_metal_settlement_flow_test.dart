import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_metal_payment_allocator.dart';
import 'package:lotus_erp/features/sales_pos/application/services/pos_invoice_scope_service.dart';
import 'package:lotus_erp/features/sales_pos/domain/use_cases/calculate_pos_totals.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/repositories/sales_orders/pos/pos_metal_settlement_repository.dart';

void main() {
  test('gold-first screenshot reconciles item, discount, payment, and due', () {
    final gold = SaleItemModel(
      metal: MetalType.gold,
      makingChargeType: MakingChargeType.percentage,
    )
      ..grossCtrl.text = '12.230'
      ..rateCtrl.text = '18900'
      ..makingCtrl.text = '12';
    final silver = SaleItemModel(metal: MetalType.silver)
      ..grossCtrl.text = '20'
      ..rateCtrl.text = '160'
      ..makingCtrl.text = '20';
    addTearDown(gold.dispose);
    addTearDown(silver.dispose);

    expect(gold.totalValue, closeTo(258884.64, 0.001));
    expect(silver.totalValue, closeTo(3600, 0.001));

    final totals = const CalculatePosTotals()(PosTotalsInput(
      saleItems: [gold, silver],
      tradeInItems: const [],
      billingMode: BillingMode.retail,
      billType: BillType.normal,
      tradeInMode: TradeInAdjustMode.cashAdjust,
      discountType: DiscountType.flatAmount,
      discountInput: 0,
      metalDiscounts: const {MetalType.gold: 0.64},
      cashInput: 260000,
      upiInput: 0,
      cardInput: 0,
      advanceInput: 0,
      goldBhawInput: 0,
      silverBhawInput: 0,
      platinumBhawInput: 0,
      diamondBhawInput: 0,
      metalGstRates: const {},
      defaultJewelleryGstRate: 0.03,
      makingGstRate: 0.05,
      roundOffGstAmount: true,
    ));
    expect(totals.grossAmount, 262484.64);
    expect(totals.discountAmount, 0.64);
    expect(totals.finalPayableAmount, 262484);
    expect(totals.invoiceTotalPaid, 260000);
    expect(totals.invoiceBalanceDue, 2484);

    final allocations = const PosMetalPaymentAllocator().allocate(
      saleItems: [gold, silver],
      tradeInItems: const [],
      billingMode: BillingMode.retail,
      tradeInMode: TradeInAdjustMode.cashAdjust,
      grossAmount: totals.grossAmount,
      discountAmount: totals.discountAmount,
      metalDiscounts: const {MetalType.gold: 0.64},
      taxableAmount: totals.taxableAmount,
      totalGst: totals.totalGst,
      roundOffAmount: totals.roundOffAmount,
      netPayable: totals.finalPayableAmount,
      cashPaid: totals.cashPaidAmount,
      upiPaid: 0,
      cardPaid: 0,
      advancePaid: 0,
      settleFirstMetals: const {MetalType.gold},
    );
    expect(allocations.map((row) => row.netPayable), [258884, 3600]);
    expect(allocations.map((row) => row.totalPaid), [258884, 1116]);
    expect(allocations.map((row) => row.balanceDue), [0, 2484]);
  });

  test('metal discounts and settle-first choice produce one-metal due', () {
    final gold = SaleItemModel(metal: MetalType.gold)
      ..grossCtrl.text = '1'
      ..rateCtrl.text = '6000';
    final silver = SaleItemModel(metal: MetalType.silver)
      ..grossCtrl.text = '1'
      ..rateCtrl.text = '2000';
    addTearDown(gold.dispose);
    addTearDown(silver.dispose);
    final items = [gold, silver];
    const discounts = {MetalType.gold: 100.0, MetalType.silver: 200.0};
    final totals = const CalculatePosTotals()(PosTotalsInput(
      saleItems: items,
      tradeInItems: const [],
      billingMode: BillingMode.retail,
      billType: BillType.normal,
      tradeInMode: TradeInAdjustMode.cashAdjust,
      discountType: DiscountType.flatAmount,
      discountInput: 0,
      metalDiscounts: discounts,
      cashInput: 6500,
      upiInput: 0,
      cardInput: 0,
      advanceInput: 0,
      goldBhawInput: 0,
      silverBhawInput: 0,
      platinumBhawInput: 0,
      diamondBhawInput: 0,
      metalGstRates: const {},
      defaultJewelleryGstRate: 0.03,
      makingGstRate: 0.05,
      roundOffGstAmount: true,
    ));
    expect(totals.discountAmount, 300);
    expect(totals.finalPayableAmount, 7700);

    List<double> dues(MetalType first) {
      final result = const PosMetalPaymentAllocator().allocate(
        saleItems: items,
        tradeInItems: const [],
        billingMode: BillingMode.retail,
        tradeInMode: TradeInAdjustMode.cashAdjust,
        grossAmount: totals.grossAmount,
        discountAmount: totals.discountAmount,
        metalDiscounts: discounts,
        taxableAmount: totals.taxableAmount,
        totalGst: totals.totalGst,
        roundOffAmount: totals.roundOffAmount,
        netPayable: totals.finalPayableAmount,
        cashPaid: totals.cashPaidAmount,
        upiPaid: 0,
        cardPaid: 0,
        advancePaid: 0,
        settleFirstMetals: {first},
      );
      expect(result.map((row) => row.discountAmount), [100, 200]);
      return result.map((row) => row.balanceDue).toList();
    }

    expect(dues(MetalType.gold), [0, 1200]);
    expect(dues(MetalType.silver), [1200, 0]);
  });

  test('issued metal settlement survives database reload', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = PosMetalSettlementRepository(db);
    await repository.ensureSchema();
    final billId = await db.into(db.bills).insert(
          const BillsCompanion(billNo: Value('AJ-26-TEST')),
        );
    await repository.replace(billId, const [
      PosInvoiceMetalPaymentAllocation(
        metal: MetalType.gold,
        discountAmount: 100,
        netPayable: 5900,
        cashPaid: 5900,
        settleFirst: true,
      ),
      PosInvoiceMetalPaymentAllocation(
        metal: MetalType.silver,
        discountAmount: 200,
        netPayable: 1800,
        cashPaid: 600,
      ),
    ]);
    final saved = await repository.load(billId);
    expect(saved.map((row) => row.discountAmount), [100, 200]);
    expect(saved.singleWhere((row) => row.metal == MetalType.gold).settleFirst,
        isTrue);
    expect(saved.map((row) => row.balanceDue), [0, 1200]);
  });

  test('GST and manual paid amounts remain scoped to their metal', () {
    final gold = SaleItemModel(metal: MetalType.gold)
      ..grossCtrl.text = '1'
      ..rateCtrl.text = '6000';
    final silver = SaleItemModel(metal: MetalType.silver)
      ..grossCtrl.text = '1'
      ..rateCtrl.text = '2000';
    addTearDown(gold.dispose);
    addTearDown(silver.dispose);
    const discounts = {MetalType.gold: 100.0, MetalType.silver: 200.0};
    final totals = const CalculatePosTotals()(PosTotalsInput(
      saleItems: [gold, silver],
      tradeInItems: const [],
      billingMode: BillingMode.retail,
      billType: BillType.gst,
      tradeInMode: TradeInAdjustMode.cashAdjust,
      discountType: DiscountType.flatAmount,
      discountInput: 0,
      metalDiscounts: discounts,
      cashInput: 6500,
      upiInput: 0,
      cardInput: 0,
      advanceInput: 0,
      goldBhawInput: 0,
      silverBhawInput: 0,
      platinumBhawInput: 0,
      diamondBhawInput: 0,
      metalGstRates: const {
        MetalType.gold: 0.03,
        MetalType.silver: 0.05,
      },
      defaultJewelleryGstRate: 0.03,
      makingGstRate: 0.05,
      roundOffGstAmount: true,
    ));
    expect(totals.goldGst, 177);
    expect(totals.silverGst, 90);
    final allocations = const PosMetalPaymentAllocator().allocate(
      saleItems: [gold, silver],
      tradeInItems: const [],
      billingMode: BillingMode.retail,
      tradeInMode: TradeInAdjustMode.cashAdjust,
      grossAmount: totals.grossAmount,
      discountAmount: totals.discountAmount,
      metalDiscounts: discounts,
      metalGstAmounts: {
        MetalType.gold: totals.goldGst,
        MetalType.silver: totals.silverGst,
      },
      taxableAmount: totals.taxableAmount,
      totalGst: totals.totalGst,
      roundOffAmount: totals.roundOffAmount,
      netPayable: totals.finalPayableAmount,
      cashPaid: totals.cashPaidAmount,
      upiPaid: 0,
      cardPaid: 0,
      advancePaid: 0,
      settleFirstMetals: const {},
      manualPaidByMetal: const {
        MetalType.gold: 5000,
        MetalType.silver: 1500,
      },
    );
    expect(allocations.map((row) => row.netPayable), [6077, 1890]);
    expect(allocations.map((row) => row.balanceDue), [1077, 390]);
  });

  test('PDF metal pages use the saved discount and payment snapshot', () {
    final gold = SaleItemModel(metal: MetalType.gold)
      ..grossCtrl.text = '1'
      ..rateCtrl.text = '6000';
    final silver = SaleItemModel(metal: MetalType.silver)
      ..grossCtrl.text = '1'
      ..rateCtrl.text = '2000';
    addTearDown(gold.dispose);
    addTearDown(silver.dispose);
    final invoice = PosInvoiceModel(
      invoiceNumber: 'AJ-26-TEST',
      invoiceDate: DateTime(2026, 10, 29),
      billType: BillType.normal,
      billingMode: BillingMode.retail,
      shopName: 'Lotus',
      shopAddress: 'Patna',
      shopPhone: '',
      shopGstin: '',
      customerName: 'Customer',
      customerMobile: '',
      customerCity: 'Patna',
      customerPan: '',
      customerGstin: '',
      tradeInMode: TradeInAdjustMode.cashAdjust,
      saleItems: [gold, silver],
      tradeInItems: const [],
      grossAmount: 8000,
      discountAmount: 300,
      taxableAmount: 7700,
      cgst: 0,
      sgst: 0,
      totalGst: 0,
      totalTradeInDeduction: 0,
      grandTotal: 7700,
      cashPaid: 6500,
      upiPaid: 0,
      cardPaid: 0,
      advancePaid: 0,
      balanceDue: 1200,
      totalMakingCharge: 0,
      metalPaymentAllocations: const [
        PosInvoiceMetalPaymentAllocation(
          metal: MetalType.gold,
          grossAmount: 6000,
          discountAmount: 100,
          netPayable: 5900,
          cashPaid: 5900,
          settleFirst: true,
        ),
        PosInvoiceMetalPaymentAllocation(
          metal: MetalType.silver,
          grossAmount: 2000,
          discountAmount: 200,
          netPayable: 1800,
          cashPaid: 600,
        ),
      ],
    );
    final pages =
        const PosInvoiceScopeService().scopedInvoicesForAllMetals(invoice);
    expect(pages.map((page) => page.discountAmount), [100, 200]);
    expect(pages.map((page) => page.netPayable), [5900, 1800]);
    expect(pages.map((page) => page.balanceDue), [0, 1200]);
  });

  test('cross-metal exchange never creates a negative metal due', () {
    final gold = SaleItemModel(metal: MetalType.gold)
      ..grossCtrl.text = '1'
      ..rateCtrl.text = '1000';
    final silver = SaleItemModel(metal: MetalType.silver)
      ..grossCtrl.text = '1'
      ..rateCtrl.text = '100';
    final exchange = TradeInItemModel(metal: MetalType.silver)
      ..grossCtrl.text = '1'
      ..purityCtrl.text = '100'
      ..rateCtrl.text = '500';
    addTearDown(gold.dispose);
    addTearDown(silver.dispose);
    addTearDown(exchange.dispose);
    final allocations = const PosMetalPaymentAllocator().allocate(
      saleItems: [gold, silver],
      tradeInItems: [exchange],
      billingMode: BillingMode.retail,
      tradeInMode: TradeInAdjustMode.cashAdjust,
      grossAmount: 1100,
      discountAmount: 0,
      taxableAmount: 1100,
      totalGst: 0,
      roundOffAmount: 0,
      netPayable: 600,
      cashPaid: 500,
      upiPaid: 0,
      cardPaid: 0,
      advancePaid: 0,
      settleFirstMetals: {MetalType.gold},
    );
    expect(allocations.map((row) => row.netPayable), [600, 0]);
    expect(allocations.map((row) => row.balanceDue), [100, 0]);
  });
}
