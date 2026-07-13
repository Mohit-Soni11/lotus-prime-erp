import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/models/purchase/purchase_enums/purchase_enums.dart';
import 'package:lotus_erp/repositories/purchase/purchase_entry_repository.dart';

void main() {
  late AppDatabase database;
  late PurchaseEntryRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PurchaseEntryRepository(db: database);
  });

  tearDown(() => database.close());

  test('savePurchase creates stock and records an inward stock movement',
      () async {
    final result = await repository.savePurchase(
      const PurchaseVoucherDraft(
        sequenceNo: 1,
        voucherNo: 'GSTOCK-2026-0001',
        source: PurchaseSource.fromSupplier,
        taxType: PurchaseTaxType.normal,
        discountType: PurchaseDiscountType.flatAmount,
        discountValue: 0,
        discountAmount: 0,
        grossAmount: 70000,
        taxableAmount: 70000,
        gstAmount: 0,
        cgstAmount: 0,
        sgstAmount: 0,
        grandTotal: 70000,
        cashPaid: 70000,
        upiPaid: 0,
        bankPaid: 0,
        cardPaid: 0,
        totalPaid: 70000,
        balanceDue: 0,
        ratePerKg: 700000,
        metalPaidGrossWeight: 0,
        metalPaidPurity: 0,
        metalPaidFine: 0,
        metalPaidValue: 0,
        party: PurchaseVoucherPartyDraft(
          supplierId: null,
          name: 'Lotus Gold Supplier',
        ),
        items: [
          PurchaseVoucherItemDraft(
            metal: PurchaseMetalType.gold,
            description: 'Hallmarked Gold Ring',
            quantity: 2,
            grossWeight: 5,
            lessWeight: 0,
            netWeight: 5,
            purity: 91.6,
            fineWeight: 4.58,
            rate: 7000,
            lineAmount: 70000,
            subCategory: 'Ring',
            hsnCode: '7113',
            labourCharge: 0,
            labourType: MakingChargesType.perGram,
            purityLabel: '22KT',
            effectiveRatePerGram: 7000,
            gstRate: 0,
          ),
        ],
      ),
    );

    expect(result, isNotNull);
    expect(result!.stockEntryCount, 1);

    final stockRows = await database.select(database.stockItems).get();
    final movements = await database.select(database.stockMovements).get();

    expect(stockRows, hasLength(1));
    expect(stockRows.single.quantity, 2);
    expect(movements, hasLength(1));
    expect(movements.single.stockItemId, stockRows.single.id);
    expect(movements.single.movementType, 'IN');
    expect(movements.single.sourceType, 'PURCHASE');
    expect(movements.single.sourceNumber, 'GSTOCK-2026-0001');
    expect(movements.single.quantityDelta, 2);
    expect(movements.single.grossWeightDelta, 10);
    expect(movements.single.netWeightDelta, 10);
    expect(movements.single.fineWeightDelta, 9.16);
  });
}
