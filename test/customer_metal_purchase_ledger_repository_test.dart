import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/data/customer_metal_purchase_ledger_drift_repository.dart';
import 'package:lotus_erp/models/purchase/purchase_enums/purchase_enums.dart';
import 'package:lotus_erp/repositories/purchase/purchase_entry_repository.dart';

void main() {
  late AppDatabase database;
  late PurchaseEntryRepository purchaseRepository;
  late DriftCustomerMetalPurchaseLedgerRepository ledgerRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    purchaseRepository = PurchaseEntryRepository(db: database);
    ledgerRepository = DriftCustomerMetalPurchaseLedgerRepository(database);
  });

  tearDown(() => database.close());

  test('includes direct customer purchases and sales exchange adjustments only',
      () async {
    final customerPurchase = await purchaseRepository.savePurchase(
      _purchaseDraft(
        sequenceNo: 1,
        voucherNo: 'CMP-2026-0001',
        source: PurchaseSource.fromCustomer,
        partyName: 'Aarav Mehta',
        metal: PurchaseMetalType.gold,
      ),
    );
    final supplierPurchase = await purchaseRepository.savePurchase(
      _purchaseDraft(
        sequenceNo: 2,
        voucherNo: 'SUP-2026-0001',
        source: PurchaseSource.fromSupplier,
        partyName: 'Lotus Bullion Supply',
        metal: PurchaseMetalType.silver,
      ),
    );
    await _insertSalesTradeIn(database);

    expect(customerPurchase, isNotNull);
    expect(supplierPurchase, isNotNull);

    final rows = await ledgerRepository.fetchLedger(
      startDate: DateTime(2020),
      endDate: DateTime(2100, 12, 31),
    );

    expect(rows, hasLength(2));
    expect(
      rows.map((row) => row.referenceNo).toSet(),
      {'CMP-2026-0001', 'SALE-2026-0001'},
    );
    expect(
      rows.map((row) => row.source).toSet(),
      {'Direct Purchase', 'Exchange Adjustment'},
    );
    expect(rows.any((row) => row.referenceNo == 'SUP-2026-0001'), isFalse);
  });

  test(
      'groups silver direct purchases and sales exchange adjustments in silver summary',
      () async {
    final silverPurchase = await purchaseRepository.savePurchase(
      _purchaseDraft(
        sequenceNo: 1,
        voucherNo: 'CMP-SIL-2026-0001',
        source: PurchaseSource.fromCustomer,
        partyName: 'Riya Sharma',
        metal: PurchaseMetalType.silver,
      ),
    );

    await _insertSalesTradeIn(
      database,
      billNo: 'SALE-SIL-2026-0001',
      customerName: 'Kabir Jain',
      metalType: 'SILVER',
      itemDescription: 'Old Silver Anklet',
      grossWeight: 25,
      netWeight: 24,
      purity: 80,
      fineWeight: 19.2,
      rate: 72,
      lineAmount: 1382.4,
    );

    expect(silverPurchase, isNotNull);

    final rows = await ledgerRepository.fetchLedger(
      startDate: DateTime(2020),
      endDate: DateTime(2100, 12, 31),
    );

    final silverRows =
        rows.where((row) => row.metalType.toUpperCase() == 'SILVER').toList();
    final summary = buildCustomerMetalPurchaseSummary(
      metal: CustomerMetalPurchaseMetal.silver,
      entries: silverRows,
    );

    expect(silverRows, hasLength(2));
    expect(
      silverRows.map((row) => row.referenceNo).toSet(),
      {'CMP-SIL-2026-0001', 'SALE-SIL-2026-0001'},
    );
    expect(summary.entryCount, 2);
    expect(summary.customerCount, 2);
    expect(summary.directPurchaseCount, 1);
    expect(summary.tradeInCount, 1);
    expect(summary.grossWeight, closeTo(35, 0.001));
    expect(summary.fineWeight, closeTo(28.36, 0.001));
    expect(summary.amount, closeTo(11382.4, 0.001));
  });

  test('marks POS purchase-from-customer rows as direct purchase source',
      () async {
    await _insertSalesTradeIn(
      database,
      billNo: 'SALE-PUR-2026-0001',
      customerName: 'Ira Kapoor',
      settlementType: 'PURCHASE_FROM_CUSTOMER',
    );

    final rows = await ledgerRepository.fetchLedger(
      startDate: DateTime(2020),
      endDate: DateTime(2100, 12, 31),
    );

    final row = rows.single;
    final summary = buildCustomerMetalPurchaseSummary(
      metal: CustomerMetalPurchaseMetal.gold,
      entries: rows,
    );

    expect(row.source, 'Purchase From Customer');
    expect(summary.directPurchaseCount, 1);
    expect(summary.tradeInCount, 0);
  });

  test('loads read-only voucher detail for direct customer purchases',
      () async {
    final saved = await purchaseRepository.savePurchase(
      _purchaseDraft(
        sequenceNo: 1,
        voucherNo: 'CMP-VIEW-2026-0001',
        source: PurchaseSource.fromCustomer,
        partyName: 'Tara Soni',
        metal: PurchaseMetalType.gold,
        mobile: '9876543210',
        city: 'Jaipur',
        panNumber: 'ABCDE1234F',
        cashPaid: 6000,
        upiPaid: 2500,
        bankPaid: 0,
        totalPaid: 8500,
        balanceDue: 1500,
        promiseDate: DateTime(2026, 9, 3),
        sellerPhotoPath: r'D:\seller-photo.jpg',
      ),
    );

    expect(saved, isNotNull);

    final detail = await ledgerRepository.fetchVoucherDetail(saved!.voucherId);

    expect(detail, isNotNull);
    expect(detail!.voucherNo, 'CMP-VIEW-2026-0001');
    expect(detail.partyName, 'Tara Soni');
    expect(detail.mobile, '9876543210');
    expect(detail.city, 'Jaipur');
    expect(detail.panNumber, 'ABCDE1234F');
    expect(detail.totalPaid, 8500);
    expect(detail.balanceDue, 1500);
    expect(detail.resolvedPaymentStatus, 'PARTIAL');
    expect(detail.promiseDate, DateTime(2026, 9, 3));
    expect(detail.sellerPhotoPath, r'D:\seller-photo.jpg');
    expect(detail.lines, hasLength(1));
    expect(detail.lines.single.metalType, 'GOLD');
    expect(detail.lines.single.itemDescription, 'GOLD Customer Purchase');
    expect(detail.lines.single.grossWeight, 10);
    expect(detail.lines.single.lessWeight, 0);
    expect(detail.fineWeight, closeTo(9.16, 0.001));
  });

  test('marks customer metal entry returned without deleting original record',
      () async {
    await purchaseRepository.savePurchase(
      _purchaseDraft(
        sequenceNo: 1,
        voucherNo: 'CMP-RET-2026-0001',
        source: PurchaseSource.fromCustomer,
        partyName: 'Neel Verma',
        metal: PurchaseMetalType.gold,
      ),
    );

    final beforeReturn = await ledgerRepository.fetchLedger(
      startDate: DateTime(2020),
      endDate: DateTime(2100, 12, 31),
    );
    final original = beforeReturn.single;

    await ledgerRepository.markReturned(original);

    final afterReturn = await ledgerRepository.fetchLedger(
      startDate: DateTime(2020),
      endDate: DateTime(2100, 12, 31),
    );
    final returned = afterReturn.single;
    final activeSummary = buildCustomerMetalPurchaseSummary(
      metal: CustomerMetalPurchaseMetal.gold,
      entries: afterReturn.where((entry) => !entry.isReturned).toList(),
    );

    expect(returned.referenceNo, 'CMP-RET-2026-0001');
    expect(returned.sourceDocumentId, isPositive);
    expect(returned.isReturned, isTrue);
    expect(returned.returnedAt, isNotNull);
    expect(activeSummary.entryCount, 0);
    expect(activeSummary.grossWeight, 0);
    expect(activeSummary.amount, 0);
  });

  test('moves selected customer metal entries into melting batch', () async {
    await purchaseRepository.savePurchase(
      _purchaseDraft(
        sequenceNo: 1,
        voucherNo: 'CMP-MELT-2026-0001',
        source: PurchaseSource.fromCustomer,
        partyName: 'Ayaan Shah',
        metal: PurchaseMetalType.gold,
      ),
    );

    final beforeTransfer = await ledgerRepository.fetchLedger(
      startDate: DateTime(2020),
      endDate: DateTime(2100, 12, 31),
    );

    final batchNo = await ledgerRepository.createMeltingBatch(
      metalType: 'GOLD',
      entries: beforeTransfer,
    );

    final afterTransfer = await ledgerRepository.fetchLedger(
      startDate: DateTime(2020),
      endDate: DateTime(2100, 12, 31),
    );
    final transferred = afterTransfer.single;
    final activeSummary = buildCustomerMetalPurchaseSummary(
      metal: CustomerMetalPurchaseMetal.gold,
      entries: afterTransfer.where((entry) => entry.isAvailable).toList(),
    );

    expect(batchNo, startsWith('CMB-GOLD-'));
    expect(transferred.isTransferredToMelting, isTrue);
    expect(transferred.meltingBatchNo, batchNo);
    expect(transferred.transferredToMeltingAt, isNotNull);
    expect(activeSummary.entryCount, 0);
    expect(activeSummary.fineWeight, 0);
  });
}

Future<void> _insertSalesTradeIn(
  AppDatabase database, {
  String billNo = 'SALE-2026-0001',
  String customerName = 'Meera Shah',
  String metalType = 'GOLD',
  String itemDescription = 'Old Gold Bangles',
  double grossWeight = 12.5,
  double netWeight = 12.0,
  double purity = 91.6,
  double fineWeight = 10.992,
  double rate = 6550,
  double lineAmount = 72000,
  String settlementType = 'EXCHANGE_ADJUSTMENT',
}) async {
  final billId = await database.into(database.bills).insert(
        BillsCompanion.insert(
          billNo: billNo,
          customerName: Value(customerName),
          billDate: Value(DateTime.now()),
        ),
      );

  await database.into(database.billTradeInItems).insert(
        BillTradeInItemsCompanion.insert(
          billId: billId,
          metalType: Value(metalType),
          settlementType: Value(settlementType),
          itemDescription: Value(itemDescription),
          grossWeight: Value(grossWeight),
          netWeight: Value(netWeight),
          purity: Value(purity),
          fineWeight: Value(fineWeight),
          rate: Value(rate),
          lineAmount: Value(lineAmount),
        ),
      );
}

PurchaseVoucherDraft _purchaseDraft({
  required int sequenceNo,
  required String voucherNo,
  required PurchaseSource source,
  required String partyName,
  required PurchaseMetalType metal,
  String? mobile,
  String? city,
  String? panNumber,
  double cashPaid = 10000,
  double upiPaid = 0,
  double bankPaid = 0,
  double cardPaid = 0,
  double totalPaid = 10000,
  double balanceDue = 0,
  DateTime? promiseDate,
  String? sellerPhotoPath,
}) {
  return PurchaseVoucherDraft(
    sequenceNo: sequenceNo,
    voucherNo: voucherNo,
    source: source,
    taxType: PurchaseTaxType.normal,
    discountType: PurchaseDiscountType.flatAmount,
    discountValue: 0,
    discountAmount: 0,
    grossAmount: 10000,
    taxableAmount: 10000,
    gstAmount: 0,
    cgstAmount: 0,
    sgstAmount: 0,
    grandTotal: 10000,
    cashPaid: cashPaid,
    upiPaid: upiPaid,
    bankPaid: bankPaid,
    cardPaid: cardPaid,
    totalPaid: totalPaid,
    balanceDue: balanceDue,
    promiseDate: promiseDate,
    sellerPhotoPath: sellerPhotoPath,
    party: PurchaseVoucherPartyDraft(
      name: partyName,
      mobile: mobile,
      city: city,
      panNumber: panNumber,
    ),
    items: [
      PurchaseVoucherItemDraft(
        metal: metal,
        description: '${metal.displayName} Customer Purchase',
        grossWeight: 10,
        lessWeight: 0,
        netWeight: 10,
        purity: 91.6,
        fineWeight: 9.16,
        rate: 1000,
        lineAmount: 10000,
      ),
    ],
  );
}
