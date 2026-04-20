// =============================================================================
// FILE        : app_database.dart  [MODIFIED — v11]
// LAYER       : Database
// DESCRIPTION : Main Drift database.
//               Schema bumped to v11 for Delivery Management Module.
//
// CHANGELOG:
//   v9  — Girvi Module tables added.
//   v10 — Supplier Module added (Suppliers table).
//         StockItems: stoneValue, purchaseRate, supplierId columns added.
//   v11 — ✅ Delivery Management Module added:
//              DeliveryOrders table — master delivery pipeline record
//              DeliveryItems  table — line items for partial delivery support
// =============================================================================

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../config/db_config.dart';
import '../tables/customers.dart';
import '../tables/stock/suppliers.dart';
import '../tables/shop_profile_table.dart';
import '../tables/bills.dart';
import '../tables/bill_items.dart';
import '../tables/sales_orders.dart';
import '../tables/loans.dart';
import '../tables/notifications.dart';
import '../../database/tables/stock/stock_items.dart';
import '../tables/daily_rates/daily_rates.dart';
import '../tables/finance/cash_transactions.dart';
import '../tables/finance/bank_accounts.dart';
import '../tables/finance/bank_transactions.dart';

// ✅ v8: Karigar Module
import '../tables/karigar/karigar_masters.dart';
import '../tables/karigar/karigar_issues.dart';
import '../tables/karigar/karigar_receipts.dart';

// ✅ v9: Girvi Module
import '../tables/girvi/girvi_loans.dart';
import '../tables/girvi/girvi_payments.dart';

// ✅ v11: Delivery Management Module
import '../tables/delivery/delivery_orders.dart';
import '../tables/delivery/delivery_items.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Customers,
  Suppliers,
  ShopProfiles,
  Bills,
  BillItems,
  SalesOrders,
  OrderAdvances,
  Loans,
  Notifications,
  StockItems,
  DailyRates,
  CashTransactions,
  BankAccounts,
  BankTransactions,
  KarigarMasters,
  KarigarIssues,
  KarigarReceipts,
  GirviLoans,
  GirviPayments,
  DeliveryOrders, // ✅ v11: Delivery Management
  DeliveryItems, // ✅ v11: Delivery Management
])
class AppDatabase extends _$AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal() : super(_openConnection());

  @override
  int get schemaVersion => 11; // ✅ v11: Bumped for Delivery Management Module

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
            debugPrint('✅ v3: Customers table expanded.');
          }

          if (from < 4) {
            await m.addColumn(stockItems, stockItems.description);
            await m.addColumn(stockItems, stockItems.category);
            await m.addColumn(stockItems, stockItems.purity);
            await m.addColumn(stockItems, stockItems.grossWeight);
            await m.addColumn(stockItems, stockItems.netWeight);
            await m.addColumn(stockItems, stockItems.wastage);
            await m.addColumn(stockItems, stockItems.makingCharge);
            await m.addColumn(stockItems, stockItems.makingChargeType);
            await m.addColumn(stockItems, stockItems.quantity);
            await m.addColumn(stockItems, stockItems.imagePath);
            await m.addColumn(stockItems, stockItems.location);
            await m.addColumn(stockItems, stockItems.isActive);
            debugPrint('✅ v4: StockItems expanded.');
          }

          if (from < 5) {
            await m.createTable(cashTransactions);
            debugPrint('✅ v5: CashTransactions table created.');
          }

          if (from < 6) {
            await m.addColumn(bills, bills.paidAmount);
            debugPrint('✅ v6: Bills.paidAmount added.');
          }

          if (from < 7) {
            await m.createTable(bankAccounts);
            await m.createTable(bankTransactions);
            debugPrint('✅ v7: Bank Book tables created.');
          }

          if (from < 8) {
            await m.createTable(karigarMasters);
            await m.createTable(karigarIssues);
            await m.createTable(karigarReceipts);
            debugPrint('✅ v8: Karigar Module tables created.');
          }

          if (from < 9) {
            await m.createTable(girviLoans);
            await m.createTable(girviPayments);
            debugPrint('✅ v9: Girvi Module tables created.');
          }

          if (from < 10) {
            await m.createTable(suppliers);
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
            debugPrint('✅ v10: Supplier Module done.');
          }

          // ── ✅ v11: Delivery Management Module ───────────────────────────────
          if (from < 11) {
            await m.createTable(deliveryOrders);
            await m.createTable(deliveryItems);
            debugPrint('✅ v11: Delivery Management tables created.');
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          if (kDebugMode) {
            debugPrint('📂 Database opened: v${details.versionNow}');
          }

          // Safety net for bank tables
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

          // ✅ v11 Safety net: Delivery Management tables
          await customStatement('''
        CREATE TABLE IF NOT EXISTS "delivery_orders" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "delivery_no" TEXT NOT NULL UNIQUE,
          "customer_id" INTEGER NOT NULL,
          "source_order_id" INTEGER,
          "customer_name" TEXT NOT NULL,
          "customer_mobile" TEXT NOT NULL,
          "item_name" TEXT NOT NULL,
          "metal_type" TEXT NOT NULL DEFAULT 'GOLD',
          "purity" TEXT NOT NULL DEFAULT '22K',
          "approx_weight" REAL NOT NULL DEFAULT 0.0,
          "locked_rate" REAL NOT NULL DEFAULT 0.0,
          "status" TEXT NOT NULL DEFAULT 'BOOKED',
          "karigar_id" INTEGER,
          "karigar_name" TEXT,
          "advance_paid" REAL NOT NULL DEFAULT 0.0,
          "total_amount" REAL NOT NULL DEFAULT 0.0,
          "due_amount" REAL NOT NULL DEFAULT 0.0,
          "payment_status" TEXT NOT NULL DEFAULT 'UNPAID',
          "expected_delivery_date" INTEGER,
          "actual_delivery_date" INTEGER,
          "image_path" TEXT,
          "notes" TEXT,
          "linked_bill_id" INTEGER,
          "linked_bill_no" TEXT,
          "created_at" INTEGER NOT NULL,
          "updated_at" INTEGER NOT NULL,
          FOREIGN KEY ("customer_id") REFERENCES "customers" ("id") ON DELETE CASCADE
        )
      ''');

          await customStatement('''
        CREATE TABLE IF NOT EXISTS "delivery_items" (
          "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          "delivery_order_id" INTEGER NOT NULL,
          "item_name" TEXT NOT NULL,
          "metal_type" TEXT NOT NULL DEFAULT 'GOLD',
          "purity" TEXT NOT NULL DEFAULT '22K',
          "approx_weight" REAL NOT NULL DEFAULT 0.0,
          "final_weight" REAL NOT NULL DEFAULT 0.0,
          "quantity" INTEGER NOT NULL DEFAULT 1,
          "image_path" TEXT,
          "notes" TEXT,
          "item_status" TEXT NOT NULL DEFAULT 'PENDING',
          "karigar_id" INTEGER,
          "karigar_name" TEXT,
          "delivered_at" INTEGER,
          "created_at" INTEGER NOT NULL,
          "updated_at" INTEGER NOT NULL,
          FOREIGN KEY ("delivery_order_id") REFERENCES "delivery_orders" ("id") ON DELETE CASCADE
        )
      ''');

          debugPrint('✅ Safety net: All v11 tables ensured.');
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
