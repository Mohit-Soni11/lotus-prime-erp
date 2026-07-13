import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/gold/data/receipts/drift_gold_stock_receipt_repository.dart';
import 'package:lotus_erp/features/stock/gold/domain/receipts/gold_stock_receipt.dart';
import 'package:lotus_erp/features/stock/gold/domain/receipts/gold_purity.dart';
import 'package:lotus_erp/features/stock/gold/domain/receipts/gold_weight.dart';
import 'package:lotus_erp/features/stock/gold/domain/receipts/money.dart';

void main() {
  late AppDatabase database;
  late DriftGoldStockReceiptRepository repository;
  late int supplierId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftGoldStockReceiptRepository(database);
    supplierId = await database.into(database.suppliers).insert(
          SuppliersCompanion.insert(
            businessName: 'Lotus Gold Supplier',
            mobile: '9876543210',
          ),
        );
  });

  tearDown(() => database.close());

  test('records a Gold receipt, its lines, and an audit event atomically',
      () async {
    final result = await repository.record(_receipt(supplierId));

    final receipt = await (database.select(database.goldStockReceipts)
          ..where((table) => table.id.equals(result.receiptId)))
        .getSingle();
    final lines = await (database.select(database.goldStockReceiptLines)
          ..where((table) => table.receiptId.equals(result.receiptId)))
        .get();
    final events = await (database.select(database.goldReceiptAuditEvents)
          ..where((table) => table.receiptId.equals(result.receiptId)))
        .get();

    expect(result.receiptNumber, 'GR-2026-0001');
    expect(receipt.totalCostPaise, 5860800);
    expect(lines, hasLength(1));
    expect(lines.single.fineWeightMilligrams, 8244);
    expect(lines.single.hallmarkUniqueId, 'A1B2C3');
    expect(events.single.eventType, 'RECEIPT_POSTED');
    expect(events.single.actorUserId, 'user-7');
  });

  test('does not write an invalid receipt', () async {
    final invalid = GoldStockReceipt(
      receiptNumber: 'GR-2026-0002',
      source: GoldReceiptSource.supplierPurchase,
      supplierId: supplierId,
      supplierName: 'Lotus Gold Supplier',
      receivedAt: DateTime(2026, 7, 12),
      lines: const [],
    );

    await expectLater(
      repository.record(invalid),
      throwsA(isA<GoldStockReceiptValidationException>()),
    );

    final receipts = await database.select(database.goldStockReceipts).get();
    expect(receipts, isEmpty);
  });

  test('rolls back a receipt that repeats an existing HUID', () async {
    await repository.record(_receipt(supplierId));

    await expectLater(
      repository.record(
        _receipt(
          supplierId,
          receiptNumber: 'GR-2026-0002',
        ),
      ),
      throwsA(anything),
    );

    final receipts = await database.select(database.goldStockReceipts).get();
    final lines = await database.select(database.goldStockReceiptLines).get();

    expect(receipts, hasLength(1));
    expect(lines, hasLength(1));
  });
}

GoldStockReceipt _receipt(
  int supplierId, {
  String receiptNumber = 'GR-2026-0001',
}) {
  return GoldStockReceipt(
    receiptNumber: receiptNumber,
    source: GoldReceiptSource.supplierPurchase,
    supplierId: supplierId,
    supplierName: 'Lotus Gold Supplier',
    supplierInvoiceNumber: 'SUP-341',
    createdByUserId: 'user-7',
    receivedAt: DateTime(2026, 7, 12, 10),
    lines: [
      GoldStockReceiptLine(
        lineId: 'line-1',
        category: GoldArticleCategory.ring,
        itemName: 'Hallmarked Gold Ring',
        quantity: 1,
        grossWeight: GoldWeight.fromGrams(10),
        stoneWeight: GoldWeight.fromGrams(1),
        purity: GoldPurity.fromPercent(91.6),
        ratePerGram: Money.fromRupees(7000),
        makingCharge: Money.fromRupees(100),
        makingChargeMethod: GoldMakingChargeMethod.perGram,
        hallmarkUniqueId: 'A1B2C3',
      ),
    ],
  );
}
