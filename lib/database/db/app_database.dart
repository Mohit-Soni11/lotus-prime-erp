// =============================================================================
// FILE        : app_database.dart
// LAYER       : Database
// DESCRIPTION : Main Drift database.
//               Schema bumped to v10 for Supplier Module + StockItems expansion.
//
// CHANGELOG:
//   v9  — Girvi Module tables added.
//   v10 — Supplier Module added (Suppliers table).
//         StockItems: stoneValue, purchaseRate, supplierId columns added.
// =============================================================================

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../config/db_config.dart';
import '../tables/customers.dart';
import '../tables/stock/suppliers.dart';       // ✅ v10: Supplier Module
import '../tables/shop_profile_table.dart';
import '../tables/bills.dart';
import '../tables/bill_items.dart';
import '../tables/sales_orders.dart';
import '../tables/loans.dart';
import '../tables/notifications.dart';
import '../../database/tables/stock/stock_items.dart';
import '../tables/daily_rates/daily_rates.dart';
import '../tables/finance/cash_transactions.dart';
import '../tables/finance/bank_accounts.dart';       // ✅ v7: Bank Book
import '../tables/finance/bank_transactions.dart';   // ✅ v7: Bank Book

// ✅ v8: Karigar Module
import '../tables/karigar/karigar_masters.dart';
import '../tables/karigar/karigar_issues.dart';
import '../tables/karigar/karigar_receipts.dart';

// ✅ v9: Girvi Module
import '../tables/girvi/girvi_loans.dart';
import '../tables/girvi/girvi_payments.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Customers,
  Suppliers,        // ✅ v10: Supplier Module
  ShopProfiles,
  Bills,
  BillItems,
  SalesOrders,
  OrderAdvances,
  Loans,
  Notifications,
  StockItems,
  DailyRates,
  CashTransactions, // ✅ v6: Cash Book ledger
  BankAccounts,     // ✅ v7: Bank Book — account master
  BankTransactions, // ✅ v7: Bank Book — transaction ledger
  KarigarMasters,   // ✅ v8: Karigar Module
  KarigarIssues,    // ✅ v8: Karigar Module
  KarigarReceipts,  // ✅ v8: Karigar Module
  GirviLoans,       // ✅ v9: Girvi Module — pawn loan master
  GirviPayments,    // ✅ v9: Girvi Module — payment ledger
])
class AppDatabase extends _$AppDatabase {

  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal() : super(_openConnection());

  @override
  int get schemaVersion => 10; // ✅ v10: Bumped for Supplier Module

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      debugPrint('🔄 Migrating DB from $from to $to');

      if (from < 2) {
        await m.createTable(dailyRates);
        debugPrint('✅ v2: DailyRates table created.');
      }

      if (from < 3) {
        debugPrint('🔄 v3: Expanding Customers table...');
        await m.addColumn(customers, customers.entityType);
        await m.addColumn(customers, customers.firstName);
        await m.addColumn(customers, customers.lastName);
        await m.addColumn(customers, customers.companyName);
        await m.addColumn(customers, customers.contactPersonName);
        await m.addColumn(customers, customers.dateOfBirth);
        await m.addColumn(customers, customers.gender);
        await m.addColumn(customers, customers.anniversaryDate);
        await m.addColumn(customers, customers.whatsapp);
        await m.addColumn(customers, customers.email);
        await m.addColumn(customers, customers.alternateContact);
        await m.addColumn(customers, customers.panNumber);
        await m.addColumn(customers, customers.idProofType);
        await m.addColumn(customers, customers.idProofNumber);
        await m.addColumn(customers, customers.idProofDocPath);
        await m.addColumn(customers, customers.gstNumber);
        await m.addColumn(customers, customers.addressLine1);
        await m.addColumn(customers, customers.addressLine2);
        await m.addColumn(customers, customers.country);
        await m.addColumn(customers, customers.state);
        await m.addColumn(customers, customers.pincode);
        await m.addColumn(customers, customers.openingBalance);
        await m.addColumn(customers, customers.creditLimit);
        await m.addColumn(customers, customers.customerTier);
        await m.addColumn(customers, customers.membershipId);
        await m.addColumn(customers, customers.ringSize);
        await m.addColumn(customers, customers.bangleSize);
        await m.addColumn(customers, customers.familyDetailsJson);
        await m.addColumn(customers, customers.referralSource);
        await m.addColumn(customers, customers.notes);
        await m.addColumn(customers, customers.profileImagePath);
        debugPrint('✅ v3: Customers expansion complete.');
      }

      if (from < 4) {
        debugPrint('🔄 v4: Creating missing tables...');
        try { await m.createTable(stockItems); } catch (_) {}
        try { await m.createTable(billItems); } catch (_) {}
        try { await m.createTable(salesOrders); } catch (_) {}
        try { await m.createTable(orderAdvances); } catch (_) {}
        debugPrint('✅ v4: All missing tables done.');
      }

      if (from < 5) {
        debugPrint('🔄 v5: Adding new columns...');
        try { await m.addColumn(bills, bills.paidAmount); } catch (_) {}
        try { await m.addColumn(shopProfiles, shopProfiles.openingCashBalance); } catch (_) {}
        debugPrint('✅ v5: Done.');
      }

      if (from < 6) {
        debugPrint('🔄 v6: Creating CashTransactions table...');
        try { await m.createTable(cashTransactions); } catch (_) {}
        debugPrint('✅ v6: Cash Book schema ready.');
      }

      if (from < 7) {
        debugPrint('🔄 v7: Creating Bank Book tables...');
        try { await m.createTable(bankAccounts); } catch (_) {}
        try { await m.createTable(bankTransactions); } catch (_) {}
        debugPrint('✅ v7: Bank Book schema ready.');
      }

      if (from < 8) {
        debugPrint('🔄 v8: Creating Karigar module tables...');
        try { await m.createTable(karigarMasters); } catch (_) {}
        try { await m.createTable(karigarIssues); } catch (_) {}
        try { await m.createTable(karigarReceipts); } catch (_) {}
        debugPrint('✅ v8: Karigar module schema ready.');
      }

      // ✅ v9: Girvi Module Migration (From PC 1)
      if (from < 9) {
        debugPrint('🔄 v9: Creating Girvi module tables...');
        try { await m.createTable(girviLoans); } catch (_) {}
        try { await m.createTable(girviPayments); } catch (_) {}
        debugPrint('✅ v9: Girvi module schema ready.');
      }

      // ✅ v10: Supplier Module + StockItems expansion (From PC 2)
      if (from < 10) {
        debugPrint('🔄 v10: Creating Supplier module + StockItems expansion...');
        
        try {
          await m.createTable(suppliers);
          debugPrint('✅ v10: Suppliers table created.');
        } catch (_) {
          debugPrint('ℹ️ v10: Suppliers already exists.');
        }

        try {
          await m.addColumn(stockItems, stockItems.stoneValue);
          debugPrint('✅ v10: stoneValue added.');
        } catch (_) {}

        try {
          await m.addColumn(stockItems, stockItems.purchaseRate);
          debugPrint('✅ v10: purchaseRate added.');
        } catch (_) {}

        try {
          await m.addColumn(stockItems, stockItems.supplierId);
          debugPrint('✅ v10: supplierId added.');
        } catch (_) {}

        debugPrint('✅ v10: Done.');
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (kDebugMode) {
        debugPrint('📂 Database opened: v${details.versionNow}');
      }

      // ✅ SAFETY NET FIX: Agar migration kisi reason se skip ho gayi ho
      // (jaise doosre PC se DB copy aaya ho), to yeh tables ensure karega.
      // Yeh "IF NOT EXISTS" use karta hai isliye existing tables ko koi
      // nuksan nahi hoga.
      await customStatement('''
        CREATE TABLE IF NOT EXISTS "bank_accounts" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "account_name" TEXT NOT NULL,
          "bank_name" TEXT NOT NULL,
          "account_number" TEXT NOT NULL,
          "ifsc_code" TEXT NOT NULL,
          "branch" TEXT,
          "account_type" TEXT NOT NULL DEFAULT 'SAVINGS',
          "opening_balance" REAL NOT NULL DEFAULT 0.0,
          "is_primary" INTEGER NOT NULL DEFAULT 0,
          "is_active" INTEGER NOT NULL DEFAULT 1,
          "created_at" INTEGER NOT NULL,
          "updated_at" INTEGER NOT NULL
        )
      ''');

      await customStatement('''
        CREATE TABLE IF NOT EXISTS "bank_transactions" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "account_id" INTEGER NOT NULL,
          "type" TEXT NOT NULL,
          "amount" REAL NOT NULL,
          "description" TEXT,
          "reference_no" TEXT,
          "txn_date" INTEGER NOT NULL,
          "is_voided" INTEGER NOT NULL DEFAULT 0,
          "created_at" INTEGER NOT NULL,
          FOREIGN KEY ("account_id") REFERENCES "bank_accounts" ("id")
        )
      ''');

      debugPrint('✅ Safety net: bank_accounts & bank_transactions ensured.');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, DbConfig.dbName));
    return NativeDatabase(
      file,
      logStatements: kDebugMode,
      setup: (database) {
        database.execute('PRAGMA journal_mode=WAL;');
      },
    );
  });
}