import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/ledger/data/finance_day_closure_repository.dart';
import 'package:lotus_erp/logic/dashboard/shared/dashboard_day.dart';
import 'package:lotus_erp/repositories/dashboard/cash_register_repository.dart';
import 'package:lotus_erp/repositories/dashboard/payment_status_repository.dart';

void main() {
  test('opening an existing database never renumbers an issued invoice',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus_invoice_startup_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/database.sqlite');
    final original = AppDatabase.forTesting(NativeDatabase(file));
    await original.into(original.bills).insert(BillsCompanion.insert(
          billNo: 'AJ-26-001',
          billDate: drift.Value(DateTime(2026, 6, 25, 12)),
          billType: const drift.Value('NORMAL'),
        ));
    await original.close();

    final reopened = AppDatabase.forTesting(NativeDatabase(file));
    try {
      expect(
        (await reopened.select(reopened.bills).getSingle()).billNo,
        'AJ-26-001',
      );
    } finally {
      await reopened.close();
    }
  });

  test('closed legacy invoices cannot block database startup or dashboard data',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus_invoice_startup_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/database.sqlite');
    final invoiceDate = DateTime(2026, 6, 25, 12);
    final original = AppDatabase.forTesting(NativeDatabase(file));
    await original.into(original.bills).insert(BillsCompanion.insert(
          billNo: 'AJ-26-001',
          billDate: drift.Value(invoiceDate),
          billType: const drift.Value('NORMAL'),
        ));
    expect(
      await FinanceDayClosureRepository(original).closeDay(
        invoiceDate,
        closingCash: 0,
        closedBy: 'owner',
      ),
      isTrue,
    );
    await original.close();

    final reopened = AppDatabase.forTesting(NativeDatabase(file));
    try {
      expect(
        (await reopened.select(reopened.bills).getSingle()).billNo,
        'AJ-26-001',
      );
      await reopened.ensureSalesInvoiceSeriesMigration();
      expect(
        (await reopened.select(reopened.bills).getSingle()).billNo,
        'AJ-26-001',
      );
      await PaymentStatusRepository(reopened).loadDay(invoiceDate);
      await CashRegisterRepository(reopened).loadDay(DashboardDay(invoiceDate));
      await reopened.select(reopened.metalRateProfiles).get();
    } finally {
      await reopened.close();
    }
  });
}
