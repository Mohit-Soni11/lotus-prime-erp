import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/repositories/purchase/purchase_entry_repository.dart';

void main() {
  late AppDatabase database;
  late PurchaseEntryRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PurchaseEntryRepository(db: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('purchase sequence continues from matching short and legacy year series',
      () async {
    await _insertPurchaseVoucher(database, 'AJ-PUR-2026-0004', 4);
    await _insertPurchaseVoucher(database, 'AJ-PUR-26-0009', 9);
    await _insertPurchaseVoucher(database, 'RJ-PUR-26-0099', 99);
    await _insertPurchaseVoucher(database, 'AJ-PUR-25-0088', 88);

    final nextSequence = await repository.getNextSequence(
      voucherPrefix: 'AJ',
      documentCode: 'PUR',
      yearToken: '26',
    );

    expect(nextSequence, 10);
  });

  test('purchase sequence resets when the financial-year token changes',
      () async {
    await _insertPurchaseVoucher(database, 'AJ-PUR-26-0099', 99);
    await _insertPurchaseVoucher(database, 'AJ-PUR-2026-0100', 100);

    final nextSequence = await repository.getNextSequence(
      voucherPrefix: 'AJ',
      documentCode: 'PUR',
      yearToken: '27',
    );

    expect(nextSequence, 1);
  });
}

Future<void> _insertPurchaseVoucher(
  AppDatabase database,
  String voucherNo,
  int sequenceNo,
) {
  final now = DateTime(2026, 9, 6).millisecondsSinceEpoch;
  return database.customStatement(
    '''
    INSERT INTO purchase_vouchers (
      voucher_no,
      sequence_no,
      source_type,
      party_name,
      created_at
    ) VALUES (?, ?, ?, ?, ?)
    ''',
    [voucherNo, sequenceNo, 'CUSTOMER', 'Test Seller', now],
  );
}
