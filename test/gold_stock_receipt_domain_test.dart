import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/stock/gold/domain/receipts/gold_stock_receipt.dart';
import 'package:lotus_erp/features/stock/gold/domain/receipts/gold_stock_receipt_validator.dart';
import 'package:lotus_erp/features/stock/gold/domain/receipts/gold_purity.dart';
import 'package:lotus_erp/features/stock/gold/domain/receipts/gold_weight.dart';
import 'package:lotus_erp/features/stock/gold/domain/receipts/money.dart';

void main() {
  group('GoldStockReceiptLine', () {
    test('calculates fine weight and total cost with fixed precision', () {
      final line = _line(
        grossWeight: GoldWeight.fromGrams(10),
        stoneWeight: GoldWeight.fromGrams(1),
        purity: GoldPurity.fromPercent(91.6),
        ratePerGram: Money.fromRupees(7000),
        makingCharge: Money.fromRupees(100),
      );

      expect(line.netWeight, GoldWeight.fromGrams(9));
      expect(line.fineWeight, GoldWeight.fromGrams(8.244));
      expect(line.metalValue, Money.fromRupees(57708));
      expect(line.totalMakingCharge, Money.fromRupees(900));
      expect(line.totalCost, Money.fromRupees(58608));
    });

    test('calculates a per-piece making charge for multiple pieces', () {
      final line = _line(
        quantity: 3,
        makingCharge: Money.fromRupees(250),
        makingChargeMethod: GoldMakingChargeMethod.perPiece,
      );

      expect(line.totalMakingCharge, Money.fromRupees(750));
    });
  });

  group('GoldStockReceiptValidator', () {
    const validator = GoldStockReceiptValidator();

    test('accepts a complete supplier receipt', () {
      final errors = validator.validate(_receipt(lines: [_line()]));

      expect(errors, isEmpty);
    });

    test('rejects duplicate HUIDs and multi-piece HUID lines', () {
      final errors = validator.validate(
        _receipt(
          lines: [
            _line(hallmarkUniqueId: 'A1B2C3'),
            _line(
              lineId: 'line-2',
              hallmarkUniqueId: 'a1b2c3',
              quantity: 2,
            ),
          ],
        ),
      );

      expect(errors, contains('Line 2 with a HUID must have quantity 1.'));
      expect(errors, contains('Line 2 repeats HUID A1B2C3 in this receipt.'));
    });

    test('rejects a missing supplier and invalid physical weights', () {
      final receipt = GoldStockReceipt(
        receiptNumber: 'GR-0001',
        source: GoldReceiptSource.supplierPurchase,
        supplierId: 0,
        supplierName: '',
        receivedAt: DateTime(2026, 7, 12),
        lines: [
          _line(
            grossWeight: GoldWeight.fromGrams(1),
            stoneWeight: GoldWeight.fromGrams(2),
          ),
        ],
      );

      final errors = validator.validate(receipt);

      expect(errors, contains('A saved supplier profile is required.'));
      expect(errors, contains('Supplier name is required.'));
      expect(
        errors,
        contains('Line 1 stone weight must be between zero and gross weight.'),
      );
    });
  });
}

GoldStockReceipt _receipt({required List<GoldStockReceiptLine> lines}) {
  return GoldStockReceipt(
    receiptNumber: 'GR-0001',
    source: GoldReceiptSource.supplierPurchase,
    supplierId: 10,
    supplierName: 'Lotus Gold Supplier',
    receivedAt: DateTime(2026, 7, 12),
    lines: lines,
  );
}

GoldStockReceiptLine _line({
  String lineId = 'line-1',
  int quantity = 1,
  GoldWeight? grossWeight,
  GoldWeight? stoneWeight,
  GoldPurity? purity,
  Money? ratePerGram,
  Money? makingCharge,
  GoldMakingChargeMethod makingChargeMethod = GoldMakingChargeMethod.perGram,
  String? hallmarkUniqueId,
}) {
  return GoldStockReceiptLine(
    lineId: lineId,
    category: GoldArticleCategory.ring,
    itemName: 'Gold Ring',
    quantity: quantity,
    grossWeight: grossWeight ?? GoldWeight.fromGrams(10),
    stoneWeight: stoneWeight ?? GoldWeight.zero,
    purity: purity ?? GoldPurity.fromPercent(91.6),
    ratePerGram: ratePerGram ?? Money.fromRupees(7000),
    makingCharge: makingCharge ?? Money.fromRupees(100),
    makingChargeMethod: makingChargeMethod,
    hallmarkUniqueId: hallmarkUniqueId,
  );
}
