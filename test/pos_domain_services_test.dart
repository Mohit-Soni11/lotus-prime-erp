import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_item_unit_profile.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_gst_classification_resolver.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_number_formatter.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_number_parser.dart';
import 'package:lotus_erp/features/sales_pos/domain/use_cases/calculate_pos_totals.dart';
import 'package:lotus_erp/features/sales_pos/domain/use_cases/validate_pos_invoice_readiness.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';
import 'package:lotus_erp/models/setting/tax_gst/hsn_code_model.dart';
import 'package:lotus_erp/theme/settings/tax_gst/tax_gst_strings.dart';

void main() {
  group('HsnCodeModel', () {
    test('restores missing core classifications from saved settings JSON', () {
      final saved = hsnListToJson(const [
        HsnCodeModel(
          category: 'Silver Jewellery',
          hsnCode: '71131120',
          gstRate: '3%',
        ),
      ]);

      final codes = hsnListFromJson(saved);

      expect(codes.first.category, 'Gold Jewellery');
      expect(codes.any((entry) => entry.category == 'Gold Jewellery'), isTrue);
      expect(
        codes
            .firstWhere((entry) => entry.category == 'Making Charges')
            .appliesTo,
        TaxGstStrings.hsnAppliesRepairService,
      );
    });
  });

  group('PosNumberParser', () {
    test('parses clean non-negative numeric input only', () {
      expect(PosNumberParser.parseNonNegative(''), 0);
      expect(PosNumberParser.parseNonNegative('1,234.50'), 1234.5);
      expect(PosNumberParser.parseNonNegative('12.'), 12);
      expect(PosNumberParser.parseNonNegative('10.5.0'), 0);
      expect(PosNumberParser.parseNonNegative('-10'), 0);
      expect(PosNumberParser.parseNonNegative('Rs 100'), 0);
    });
  });

  group('PosNumberFormatter', () {
    test('formats compact input values consistently', () {
      expect(PosNumberFormatter.compact(0), '');
      expect(PosNumberFormatter.compact(1200), '1200');
      expect(PosNumberFormatter.compact(1200.50), '1200.5');
      expect(
        PosNumberFormatter.compact(4.1258, maxFractionDigits: 3),
        '4.126',
      );
    });

    test('preserves jewellery weight precision for POS inputs', () {
      expect(PosNumberFormatter.weight(20.365), '20.365');
      expect(PosNumberFormatter.weight(20.360), '20.36');
      expect(PosNumberFormatter.weight(20), '20');
    });
  });

  group('PosGstClassificationResolver', () {
    test('groups gold and silver jewellery under configured display HSN', () {
      final gold = SaleItemModel(metal: MetalType.gold)..grossCtrl.text = '5';
      final silver = SaleItemModel(metal: MetalType.silver)
        ..grossCtrl.text = '10';

      final lines = const PosGstClassificationResolver().resolve(
        saleItems: [gold, silver],
        hsnCodes: const [
          HsnCodeModel(
            category: 'Gold Jewellery',
            hsnCode: '71131910',
            gstRate: '3%',
            displayCode: '7113',
          ),
          HsnCodeModel(
            category: 'Silver Jewellery',
            hsnCode: '71131120',
            gstRate: '3%',
            displayCode: '7113',
          ),
        ],
      );

      expect(lines, hasLength(1));
      expect(lines.first.code, 'HSN 7113');
      expect(lines.first.taxLabel, 'GST 3%');
      expect(lines.first.subtitle, 'Gold + Silver finished jewellery');

      gold.dispose();
      silver.dispose();
    });
  });

  group('PosItemUnitProfile', () {
    test('infers pair unit for gold jhumka and opens two HUID slots', () {
      final item = SaleItemModel(metal: MetalType.gold);

      item.descCtrl.text = 'Gold Jhumka';
      item.setHuidValues(['GJ1234', 'GJ5678']);

      expect(item.unitProfile.code, PosItemUnitCode.pair);
      expect(item.unitShortName, 'PAIR');
      expect(item.pcs, 1);
      expect(item.huidControllers.length, 2);
      expect(item.huidText, 'GJ1234, GJ5678');

      item.dispose();
    });

    test('infers silver pair and packet units from item description', () {
      final payal = SaleItemModel(metal: MetalType.silver);
      final packet = SaleItemModel(metal: MetalType.silver);

      payal.descCtrl.text = 'Silver Payal';
      packet.descCtrl.text = 'Silver Beads Packet';

      expect(payal.unitProfile.code, PosItemUnitCode.pair);
      expect(payal.pcs, 1);
      expect(payal.huidControllers.length, 2);
      expect(packet.unitProfile.code, PosItemUnitCode.packet);
      expect(packet.pcs, 1);
      expect(packet.huidControllers.length, 1);

      payal.dispose();
      packet.dispose();
    });

    test('exposes silver invoice unit options', () {
      final item = SaleItemModel(metal: MetalType.silver);

      expect(
        item.availableUnitProfiles.map((unit) => unit.shortName),
        ['PCS', 'PACK', 'PAIR', 'SET'],
      );

      item.setUnitProfile(PosItemUnitProfile.packet);

      expect(item.unitProfile.code, PosItemUnitCode.packet);
      expect(item.huidSlotCount, 1);

      item.dispose();
    });

    test('keeps manual quantity when description unit changes later', () {
      final item = SaleItemModel(metal: MetalType.gold);

      item.pcsCtrl.text = '3';
      item.descCtrl.text = 'Gold Jhumka';

      expect(item.unitProfile.code, PosItemUnitCode.pair);
      expect(item.pcs, 3);
      expect(item.huidControllers.length, 6);

      item.dispose();
    });

    test('keeps two HUID slots for pair items even with one stock HUID', () {
      final item = SaleItemModel(metal: MetalType.gold);

      item.descCtrl.text = 'Casting Tops';
      item.pcsCtrl.text = '1';
      item.setHuidValues(['BXZ01A']);

      expect(item.unitProfile.code, PosItemUnitCode.pair);
      expect(item.huidSlotCount, 2);
      expect(item.huidControllers, hasLength(2));
      expect(item.huidControllers.first.text, 'BXZ01A');
      expect(item.huidControllers.last.text, isEmpty);

      item.dispose();
    });

    test('keeps linked stock reference when sale weights are adjusted', () {
      final item = SaleItemModel(metal: MetalType.gold);

      item.applyStockReferenceSnapshot(
        huids: const ['HUID-001'],
        grossWeight: 5,
        lessWeight: 0,
        stockItemId: 10,
        stockUnitId: 20,
        stockUnitCost: 50000,
        sku: 'SKU-10',
      );

      expect(item.hasLinkedStock, isTrue);
      expect(item.linkedStockSku, 'SKU-10');

      item.grossCtrl.text = '6';

      expect(item.hasLinkedStock, isTrue);
      expect(item.linkedStockSku, 'SKU-10');

      item.dispose();
    });

    test('applies stock snapshot with exact gross and less weight precision',
        () {
      final item = SaleItemModel(metal: MetalType.gold);

      item.applyStockReferenceSnapshot(
        huids: const ['HUID-001'],
        grossWeight: 20.365,
        lessWeight: 0.125,
        stockItemId: 10,
        stockUnitId: 20,
        stockUnitCost: 250000,
        sku: 'SKU-10',
      );

      expect(item.grossCtrl.text, '20.365');
      expect(item.lessCtrl.text, '0.125');
      expect(item.netWt, closeTo(20.240, 0.0001));
      expect(item.hasLinkedStock, isTrue);

      item.dispose();
    });

    test('compares sale value with proportional stock cost for partial lots',
        () {
      final item = SaleItemModel(metal: MetalType.gold);

      item.applyStockReferenceSnapshot(
        huids: const ['HUID-001'],
        grossWeight: 20,
        lessWeight: 0,
        stockItemId: 10,
        stockUnitId: 20,
        stockUnitCost: 200000,
        sku: 'SKU-10',
      );
      item.grossCtrl.text = '0.250';
      item.rateCtrl.text = '10000';
      item.makingCtrl.text = '0';

      expect(item.linkedStockCostBasis, closeTo(2500, 0.001));
      expect(item.totalValue, closeTo(2500, 0.001));
      expect(item.isAtStockCost, isTrue);
      expect(item.isBelowStockCost, isFalse);

      item.rateCtrl.text = '12000';

      expect(item.totalValue, closeTo(3000, 0.001));
      expect(item.shouldWarnStockCost, isFalse);

      item.dispose();
    });

    test('keeps linked stock reference when sale quantity is adjusted', () {
      final item = SaleItemModel(metal: MetalType.silver);

      item.applyStockReferenceSnapshot(
        huids: const ['HUID-001'],
        grossWeight: 17.95,
        lessWeight: 0,
        stockItemId: 10,
        stockUnitId: 20,
        stockUnitCost: 3000,
        sku: 'SKU-10',
      );

      expect(item.hasLinkedStock, isTrue);
      expect(item.linkedStockSku, 'SKU-10');

      item.pcsCtrl.text = '2';

      expect(item.hasLinkedStock, isTrue);
      expect(item.linkedStockItemId, 10);
      expect(item.linkedStockUnitId, 20);
      expect(item.linkedStockSku, 'SKU-10');

      item.dispose();
    });

    test('clears linked stock reference when item identity is edited', () {
      final item = SaleItemModel(metal: MetalType.gold);

      item.applyStockReferenceSnapshot(
        huids: const ['HUID-001'],
        grossWeight: 5,
        lessWeight: 0,
        stockItemId: 10,
        stockUnitId: 20,
        stockUnitCost: 50000,
        sku: 'SKU-10',
      );

      expect(item.hasLinkedStock, isTrue);
      expect(item.linkedStockSku, 'SKU-10');

      item.descCtrl.text = 'Casting Ring';

      expect(item.hasLinkedStock, isFalse);
      expect(item.linkedStockSku, isNull);

      item.dispose();
    });
  });

  group('PosInvoiceReadinessValidator', () {
    test('accepts a complete cash sale', () {
      final item = _saleItem(huid: 'HUID-001');

      final result = const PosInvoiceReadinessValidator().validate(
        _input(saleItems: [item]),
      );

      expect(result, isNull);
      item.dispose();
    });

    test('blocks duplicate HUID entries before invoice generation', () {
      final first = _saleItem(huid: 'HUID-001');
      final second = _saleItem(huid: 'huid-001');

      final result = const PosInvoiceReadinessValidator().validate(
        _input(saleItems: [first, second]),
      );

      expect(result, contains('HUID HUID-001'));
      first.dispose();
      second.dispose();
    });

    test('blocks duplicate HUID values across multi-slot rows', () {
      final first = _saleItem(huid: 'HUID-001');
      final second = _saleItem(huid: '');

      second.descCtrl.text = 'Gold Jhumka';
      second.setHuidValues(['HUID-002', 'huid-001']);

      final result = const PosInvoiceReadinessValidator().validate(
        _input(saleItems: [first, second]),
      );

      expect(result, contains('HUID HUID-001'));
      first.dispose();
      second.dispose();
    });

    test('blocks duplicate linked stock items before invoice generation', () {
      final first = _saleItem(huid: 'HUID-001', stockItemId: 10);
      final second = _saleItem(huid: 'HUID-002', stockItemId: 10);

      final result = const PosInvoiceReadinessValidator().validate(
        _input(saleItems: [first, second]),
      );

      expect(result, contains('same stock item'));
      first.dispose();
      second.dispose();
    });

    test('requires customer and promise date for due bills', () {
      final item = _saleItem(huid: 'HUID-001');

      final withoutCustomer = const PosInvoiceReadinessValidator().validate(
        _input(
          saleItems: [item],
          balanceDue: 500,
          hasSelectedCustomer: false,
          hasPromiseDate: false,
        ),
      );
      final withoutPromiseDate = const PosInvoiceReadinessValidator().validate(
        _input(
          saleItems: [item],
          balanceDue: 500,
          hasSelectedCustomer: true,
          hasPromiseDate: false,
        ),
      );

      expect(withoutCustomer, contains('Select or create a customer'));
      expect(withoutPromiseDate, contains('Select a promise date'));
      item.dispose();
    });

    test('blocks negative payment entries before invoice generation', () {
      final item = _saleItem(huid: 'HUID-001');

      final result = const PosInvoiceReadinessValidator().validate(
        _input(
          saleItems: [item],
          cashInput: -100,
        ),
      );

      expect(result, contains('Cash received cannot be negative'));
      item.dispose();
    });
  });

  group('CalculatePosTotals', () {
    test('calculates retail GST totals and excess payment allocation', () {
      final item = _saleItem(
        huid: 'HUID-001',
        grossWeight: 10,
        rate: 1000,
      );

      final totals = const CalculatePosTotals()(
        _totalsInput(
          saleItems: [item],
          billType: BillType.gst,
          cashInput: 10500,
        ),
      );

      expect(totals.grossAmount, 10000);
      expect(totals.totalGst, 300);
      expect(totals.grandTotal, 10300);
      expect(totals.finalPayableAmount, 10300);
      expect(totals.cashPaidAmount, 10300);
      expect(totals.totalPaid, 10500);
      expect(totals.changeReturnAmount, 200);
      expect(totals.changeCreditSourcePaymentMode, PaymentMode.cash);

      item.dispose();
    });

    test('calculates wholesale totals from fine weight and bhaw', () {
      final item = _saleItem(
        huid: 'HUID-001',
        grossWeight: 10,
        rate: 1000,
        makingInput: 100,
      );

      final totals = const CalculatePosTotals()(
        _totalsInput(
          saleItems: [item],
          billingMode: BillingMode.wholesale,
          goldBhawInput: 60000,
        ),
      );

      expect(totals.goldSoldFine, 9.167);
      expect(totals.goldBhawAmount, 55002);
      expect(totals.goldMakingCharge, 1000);
      expect(totals.grossAmount, 56002);
      expect(totals.finalPayableAmount, 56002);

      item.dispose();
    });

    test('deducts old gold only in retail cash-adjust mode', () {
      final saleItem = _saleItem(huid: 'HUID-001', grossWeight: 10, rate: 1000);
      final oldItem = _tradeInItem(grossWeight: 2, purity: 90, rate: 500);

      final totals = const CalculatePosTotals()(
        _totalsInput(
          saleItems: [saleItem],
          tradeInItems: [oldItem],
          tradeInMode: TradeInAdjustMode.cashAdjust,
        ),
      );

      expect(totals.totalTradeInAmount, 900);
      expect(totals.tradeInCashDeduction, 900);
      expect(totals.finalPayableAmount, 9100);

      saleItem.dispose();
      oldItem.dispose();
    });
  });
}

SaleItemModel _saleItem({
  required String huid,
  int? stockItemId,
  double grossWeight = 10,
  double rate = 1000,
  double makingInput = 0,
}) {
  final item = SaleItemModel(metal: MetalType.gold);
  item.descCtrl.text = 'Gold Ring';
  item.huidCtrl.text = huid;
  item.purityCtrl.text = '22KT';
  item.grossCtrl.text = PosNumberFormatter.compact(grossWeight);
  item.lessCtrl.text = '0';
  item.rateCtrl.text = PosNumberFormatter.compact(rate);
  item.makingCtrl.text =
      PosNumberFormatter.compact(makingInput, blankWhenZero: false);
  if (stockItemId != null) {
    item.attachStockReference(
        stockItemId: stockItemId, sku: 'SKU-$stockItemId');
  }
  return item;
}

TradeInItemModel _tradeInItem({
  required double grossWeight,
  required double purity,
  required double rate,
}) {
  final item = TradeInItemModel(metal: MetalType.gold);
  item.descCtrl.text = 'Old Gold';
  item.grossCtrl.text = PosNumberFormatter.compact(grossWeight);
  item.lessCtrl.text = '0';
  item.purityCtrl.text = PosNumberFormatter.compact(purity);
  item.rateCtrl.text = PosNumberFormatter.compact(rate);
  return item;
}

PosInvoiceReadinessInput _input({
  required List<SaleItemModel> saleItems,
  double finalPayableAmount = 10000,
  double balanceDue = 0,
  bool hasSelectedCustomer = false,
  bool hasPromiseDate = false,
  double cashInput = 0,
  double upiInput = 0,
  double cardInput = 0,
  double advanceInput = 0,
}) {
  return PosInvoiceReadinessInput(
    saleItems: saleItems,
    tradeInItems: const [],
    billingMode: BillingMode.retail,
    finalPayableAmount: finalPayableAmount,
    hasChangeReturn: false,
    hasConfirmedChangeReturn: false,
    changeReturnMethod: null,
    balanceDue: balanceDue,
    hasSelectedCustomer: hasSelectedCustomer,
    hasPromiseDate: hasPromiseDate,
    cashInput: cashInput,
    upiInput: upiInput,
    cardInput: cardInput,
    advanceInput: advanceInput,
  );
}

PosTotalsInput _totalsInput({
  required List<SaleItemModel> saleItems,
  List<TradeInItemModel> tradeInItems = const [],
  BillingMode billingMode = BillingMode.retail,
  BillType billType = BillType.normal,
  TradeInAdjustMode tradeInMode = TradeInAdjustMode.cashAdjust,
  double cashInput = 0,
  double upiInput = 0,
  double cardInput = 0,
  double advanceInput = 0,
  double goldBhawInput = 0,
}) {
  return PosTotalsInput(
    saleItems: saleItems,
    tradeInItems: tradeInItems,
    billingMode: billingMode,
    billType: billType,
    tradeInMode: tradeInMode,
    discountType: DiscountType.percentage,
    discountInput: 0,
    cashInput: cashInput,
    upiInput: upiInput,
    cardInput: cardInput,
    advanceInput: advanceInput,
    goldBhawInput: goldBhawInput,
    silverBhawInput: 0,
    platinumBhawInput: 0,
    diamondBhawInput: 0,
    metalGstRates: const {
      MetalType.gold: 0.03,
      MetalType.silver: 0.03,
      MetalType.platinum: 0.03,
      MetalType.diamond: 0.03,
    },
    defaultJewelleryGstRate: 0.03,
    makingGstRate: 0.05,
    roundOffGstAmount: true,
  );
}
