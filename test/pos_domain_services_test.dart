import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_number_formatter.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_number_parser.dart';
import 'package:lotus_erp/features/sales_pos/domain/use_cases/calculate_pos_totals.dart';
import 'package:lotus_erp/features/sales_pos/domain/use_cases/validate_pos_invoice_readiness.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';

void main() {
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
      final oldItem = _oldGoldItem(grossWeight: 2, purity: 90, rate: 500);

      final totals = const CalculatePosTotals()(
        _totalsInput(
          saleItems: [saleItem],
          oldGoldItems: [oldItem],
          oldGoldMode: OldGoldAdjustMode.cashAdjust,
        ),
      );

      expect(totals.totalOldGoldAmount, 900);
      expect(totals.oldGoldCashDeduction, 900);
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

OldGoldItemModel _oldGoldItem({
  required double grossWeight,
  required double purity,
  required double rate,
}) {
  final item = OldGoldItemModel(metal: MetalType.gold);
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
}) {
  return PosInvoiceReadinessInput(
    saleItems: saleItems,
    oldGoldItems: const [],
    billingMode: BillingMode.retail,
    finalPayableAmount: finalPayableAmount,
    hasChangeReturn: false,
    hasConfirmedChangeReturn: false,
    changeReturnMethod: null,
    balanceDue: balanceDue,
    hasSelectedCustomer: hasSelectedCustomer,
    hasPromiseDate: hasPromiseDate,
    advanceInput: 0,
  );
}

PosTotalsInput _totalsInput({
  required List<SaleItemModel> saleItems,
  List<OldGoldItemModel> oldGoldItems = const [],
  BillingMode billingMode = BillingMode.retail,
  BillType billType = BillType.normal,
  OldGoldAdjustMode oldGoldMode = OldGoldAdjustMode.cashAdjust,
  double cashInput = 0,
  double upiInput = 0,
  double cardInput = 0,
  double advanceInput = 0,
  double goldBhawInput = 0,
}) {
  return PosTotalsInput(
    saleItems: saleItems,
    oldGoldItems: oldGoldItems,
    billingMode: billingMode,
    billType: billType,
    oldGoldMode: oldGoldMode,
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
