import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';

void main() {
  test('v66 removes credit limit and preserves legacy refund obligations',
      () async {
    final directory = await Directory.systemTemp.createTemp('customer-v66-');
    final file = File('${directory.path}/lotus.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));

    try {
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
                name: 'Reyansh Soni', mobile: '9304479436'),
          );
      await db.into(db.customerRefundPayables).insert(
            CustomerRefundPayablesCompanion.insert(
              customerId: customerId,
              entryType: 'CREDIT',
              sourceType: 'POS_REFUND_PAYABLE',
              amount: const Value(1200),
              paymentMode: const Value('REFUND_PAYABLE'),
              sourceReference: const Value('INV-1#REFUND_PAYABLE'),
            ),
          );
      await db.customStatement('''
        INSERT INTO return_vouchers
          (voucher_no, operation_type, source_type, source_id, source_number,
           settlement_mode, refund_payable_amount, created_at)
        VALUES ('RET-1', 'SALES_RETURN', 'SALES_INVOICE', 1, 'INV-1',
                'REFUND_PAYABLE', 800, 1)
      ''');

      await db.customStatement(
        'ALTER TABLE customers ADD COLUMN credit_limit REAL NOT NULL DEFAULT 0',
      );
      await db.customStatement(
        'UPDATE customers SET credit_limit = 50000 WHERE id = $customerId',
      );
      await db.customStatement(
        'ALTER TABLE customer_refund_payables RENAME TO customer_account_ledger',
      );
      await db.customStatement('''
        UPDATE customer_account_ledger
        SET source_type = 'POS_CHANGE_CREDIT',
            payment_mode = 'CUSTOMER_CREDIT',
            source_reference = 'INV-1#ACCOUNT_CREDIT'
      ''');
      await db.customStatement('''
        ALTER TABLE return_vouchers
        RENAME COLUMN refund_payable_amount TO customer_credit_amount
      ''');
      await db.customStatement('''
        UPDATE return_vouchers SET settlement_mode = 'CUSTOMER_CREDIT'
      ''');
      await db.customStatement('PRAGMA user_version = 65');
      await db.close();

      db = AppDatabase.forTesting(NativeDatabase(file));
      final customer = await (db.select(db.customers)
            ..where((row) => row.id.equals(customerId)))
          .getSingle();
      expect(customer.name, 'Reyansh Soni');
      final customerColumns =
          await db.customSelect('PRAGMA table_info("customers")').get();
      expect(customerColumns.map((row) => row.read<String>('name')),
          isNot(contains('credit_limit')));

      final obligations = await db.select(db.customerRefundPayables).get();
      expect(obligations, hasLength(1));
      expect(obligations.single.amount, 1200);
      expect(obligations.single.sourceType, 'POS_REFUND_PAYABLE');
      expect(obligations.single.paymentMode, 'REFUND_PAYABLE');
      expect(obligations.single.sourceReference, 'INV-1#REFUND_PAYABLE');

      final voucher = await db.customSelect('''
        SELECT settlement_mode, refund_payable_amount
        FROM return_vouchers WHERE voucher_no = 'RET-1'
      ''').getSingle();
      expect(voucher.read<String>('settlement_mode'), 'REFUND_PAYABLE');
      expect(voucher.read<double>('refund_payable_amount'), 800);
    } finally {
      await db.close();
      await directory.delete(recursive: true);
    }
  });
}
