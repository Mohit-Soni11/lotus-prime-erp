import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../config/db_config.dart';
import '../tables/bill_items.dart';
import '../tables/bills.dart';
import '../tables/customers.dart';
import '../tables/daily_rates/daily_rates.dart';
import '../tables/delivery/delivery_items.dart';
import '../tables/delivery/delivery_orders.dart';
import '../tables/finance/bank_accounts.dart';
import '../tables/finance/bank_transactions.dart';
import '../tables/finance/cash_transactions.dart';
import '../tables/girvi/girvi_loans.dart';
import '../tables/girvi/girvi_payments.dart';
import '../tables/karigar/karigar_issues.dart';
import '../tables/karigar/karigar_masters.dart';
import '../tables/karigar/karigar_receipts.dart';
import '../tables/loans.dart';
import '../tables/notifications.dart';
import '../tables/sales_orders.dart';
import '../tables/shop_profile_table.dart';
import '../tables/stock/stock_items.dart';
import '../tables/stock/suppliers.dart';

// ✅ v13: Billing Setup
import '../tables/setting/billing/billing_settings_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
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
    DeliveryOrders,
    DeliveryItems,
    BillingSettings, // ✅ v13
  ],
)
class AppDatabase extends _$AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();

  factory AppDatabase() => _instance;

  AppDatabase._internal() : super(_openConnection());

  @override
  int get schemaVersion => 13; // ✅ v13: Billing Setup

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          debugPrint('Migrating DB from $from to $to');

          if (from < 2) {
            await m.createTable(dailyRates);
            debugPrint('v2: DailyRates table created.');
          }

          if (from < 3) {
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
            debugPrint('v3: Customers table expanded.');
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
            debugPrint('v4: StockItems expanded.');
          }

          if (from < 5) {
            await m.createTable(cashTransactions);
            debugPrint('v5: CashTransactions table created.');
          }

          if (from < 6) {
            await m.addColumn(bills, bills.paidAmount);
            debugPrint('v6: Bills.paidAmount added.');
          }

          if (from < 7) {
            await m.createTable(bankAccounts);
            await m.createTable(bankTransactions);
            debugPrint('v7: Bank Book tables created.');
          }

          if (from < 8) {
            await m.createTable(karigarMasters);
            await m.createTable(karigarIssues);
            await m.createTable(karigarReceipts);
            debugPrint('v8: Karigar tables created.');
          }

          if (from < 9) {
            await m.createTable(girviLoans);
            await m.createTable(girviPayments);
            debugPrint('v9: Girvi tables created.');
          }

          if (from < 10) {
            await m.createTable(suppliers);
            try {
              await m.addColumn(stockItems, stockItems.stoneValue);
            } catch (_) {}
            try {
              await m.addColumn(stockItems, stockItems.purchaseRate);
            } catch (_) {}
            try {
              await m.addColumn(stockItems, stockItems.supplierId);
            } catch (_) {}
            debugPrint('v10: Supplier module migration complete.');
          }

          if (from < 11) {
            await m.createTable(deliveryOrders);
            await m.createTable(deliveryItems);
            debugPrint('v11: Delivery tables created.');
          }

          // v12: Purchase Vouchers — unchanged
          if (from < 12) {
            await customStatement(_createPurchaseVouchersTableSql);
            await customStatement(_createPurchaseVoucherItemsTableSql);
            for (final statement in _purchaseVoucherIndexSql) {
              await customStatement(statement);
            }
            debugPrint('v12: Purchase voucher tables created.');
          }

          // ✅ v13: Billing Setup
          if (from < 13) {
            await m.createTable(billingSettings);
            debugPrint('v13: BillingSettings table created.');
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          if (kDebugMode) {
            debugPrint('Database opened: v${details.versionNow}');
          }

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

          await customStatement(_createPurchaseVouchersTableSql);
          await customStatement(_createPurchaseVoucherItemsTableSql);
          for (final statement in _purchaseVoucherIndexSql) {
            await customStatement(statement);
          }

          // ✅ v13 Safety net: BillingSettings
          await customStatement('''
            CREATE TABLE IF NOT EXISTS "billing_settings" (
              "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              "sales_invoice_prefix" TEXT NOT NULL DEFAULT 'INV-',
              "sales_starting_number" INTEGER NOT NULL DEFAULT 1,
              "sales_yearly_reset" INTEGER NOT NULL DEFAULT 1,
              "estimate_prefix" TEXT NOT NULL DEFAULT 'EST-',
              "estimate_validity_days" INTEGER NOT NULL DEFAULT 7,
              "sales_default_payment_mode" TEXT NOT NULL DEFAULT 'Cash',
              "sales_upi_id" TEXT NOT NULL DEFAULT '',
              "sales_default_credit_days" INTEGER NOT NULL DEFAULT 30,
              "sales_min_advance_percent" INTEGER NOT NULL DEFAULT 30,
              "sales_allow_discount" INTEGER NOT NULL DEFAULT 1,
              "sales_max_discount_percent" REAL NOT NULL DEFAULT 5.0,
              "sales_rounding_rule" TEXT NOT NULL DEFAULT 'Nearest ₹1',
              "sales_show_making_charges" INTEGER NOT NULL DEFAULT 1,
              "sales_show_huid" INTEGER NOT NULL DEFAULT 1,
              "sales_show_old_gold_line" INTEGER NOT NULL DEFAULT 1,
              "sales_terms" TEXT NOT NULL DEFAULT 'Items once sold will not be taken back or exchanged.',
              "sales_footer_msg" TEXT NOT NULL DEFAULT 'Thank you for shopping with us!',
              "purchase_invoice_prefix" TEXT NOT NULL DEFAULT 'PUR-',
              "purchase_starting_number" INTEGER NOT NULL DEFAULT 1,
              "purchase_yearly_reset" INTEGER NOT NULL DEFAULT 1,
              "purchase_default_payment_days" INTEGER NOT NULL DEFAULT 30,
              "purchase_advance_percent" INTEGER NOT NULL DEFAULT 20,
              "purchase_default_payment_mode" TEXT NOT NULL DEFAULT 'Bank Transfer',
              "purchase_weight_tolerance_percent" REAL NOT NULL DEFAULT 0.5,
              "purchase_default_karat" TEXT NOT NULL DEFAULT '22K',
              "purchase_terms" TEXT NOT NULL DEFAULT 'Quality will be checked on delivery.',
              "purchase_auto_print" INTEGER NOT NULL DEFAULT 0,
              "girvi_prefix" TEXT NOT NULL DEFAULT 'GRV-',
              "girvi_starting_number" INTEGER NOT NULL DEFAULT 1,
              "girvi_default_interest_rate" REAL NOT NULL DEFAULT 1.5,
              "girvi_interest_type" TEXT NOT NULL DEFAULT 'Simple',
              "girvi_grace_period_days" INTEGER NOT NULL DEFAULT 3,
              "girvi_default_duration" TEXT NOT NULL DEFAULT '6 Months',
              "girvi_reminder_days" INTEGER NOT NULL DEFAULT 15,
              "girvi_notice_days" INTEGER NOT NULL DEFAULT 30,
              "girvi_terms" TEXT NOT NULL DEFAULT 'Interest charged per month on the loan amount.',
              "girvi_auto_print" INTEGER NOT NULL DEFAULT 1,
              "return_window_days" INTEGER NOT NULL DEFAULT 7,
              "return_handling_charge_percent" REAL NOT NULL DEFAULT 0.0,
              "return_mode" TEXT NOT NULL DEFAULT 'Exchange Only',
              "return_voucher_prefix" TEXT NOT NULL DEFAULT 'RET-',
              "buyback_rate_percent" REAL NOT NULL DEFAULT 90.0,
              "buyback_purity_deduct_percent" REAL NOT NULL DEFAULT 2.0,
              "buyback_default_karat" TEXT NOT NULL DEFAULT '22K',
              "return_terms" TEXT NOT NULL DEFAULT 'Returns accepted with original bill only.',
              "created_at" INTEGER NOT NULL,
              "updated_at" INTEGER
            )
          ''');

          debugPrint('Safety net bootstrap complete.');
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

// ── Purchase Vouchers SQL (v12 — unchanged) ───────────────────────────────────

const String _createPurchaseVouchersTableSql = '''
  CREATE TABLE IF NOT EXISTS "purchase_vouchers" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "voucher_no" TEXT NOT NULL UNIQUE,
    "sequence_no" INTEGER NOT NULL,
    "source_type" TEXT NOT NULL,
    "customer_id" INTEGER,
    "supplier_id" INTEGER,
    "party_name" TEXT NOT NULL,
    "contact_name" TEXT,
    "mobile" TEXT,
    "city" TEXT,
    "pan_number" TEXT,
    "gst_number" TEXT,
    "tax_type" TEXT NOT NULL DEFAULT 'NORMAL',
    "discount_type" TEXT NOT NULL DEFAULT 'FLAT',
    "discount_value" REAL NOT NULL DEFAULT 0.0,
    "discount_amount" REAL NOT NULL DEFAULT 0.0,
    "gross_amount" REAL NOT NULL DEFAULT 0.0,
    "taxable_amount" REAL NOT NULL DEFAULT 0.0,
    "gst_amount" REAL NOT NULL DEFAULT 0.0,
    "cgst_amount" REAL NOT NULL DEFAULT 0.0,
    "sgst_amount" REAL NOT NULL DEFAULT 0.0,
    "grand_total" REAL NOT NULL DEFAULT 0.0,
    "cash_paid" REAL NOT NULL DEFAULT 0.0,
    "bank_paid" REAL NOT NULL DEFAULT 0.0,
    "card_paid" REAL NOT NULL DEFAULT 0.0,
    "total_paid" REAL NOT NULL DEFAULT 0.0,
    "balance_due" REAL NOT NULL DEFAULT 0.0,
    "payment_status" TEXT NOT NULL DEFAULT 'UNPAID',
    "stock_entry_count" INTEGER NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'SAVED',
    "created_at" INTEGER NOT NULL,
    "updated_at" INTEGER,
    FOREIGN KEY ("customer_id") REFERENCES "customers" ("id") ON DELETE SET NULL,
    FOREIGN KEY ("supplier_id") REFERENCES "suppliers" ("id") ON DELETE SET NULL
  )
''';

const String _createPurchaseVoucherItemsTableSql = '''
  CREATE TABLE IF NOT EXISTS "purchase_voucher_items" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "purchase_voucher_id" INTEGER NOT NULL,
    "line_no" INTEGER NOT NULL,
    "sku" TEXT,
    "metal_type" TEXT NOT NULL,
    "item_description" TEXT,
    "gross_weight" REAL NOT NULL DEFAULT 0.0,
    "less_weight" REAL NOT NULL DEFAULT 0.0,
    "net_weight" REAL NOT NULL DEFAULT 0.0,
    "purity" REAL NOT NULL DEFAULT 0.0,
    "fine_weight" REAL NOT NULL DEFAULT 0.0,
    "rate" REAL NOT NULL DEFAULT 0.0,
    "line_amount" REAL NOT NULL DEFAULT 0.0,
    "created_at" INTEGER NOT NULL,
    FOREIGN KEY ("purchase_voucher_id") REFERENCES "purchase_vouchers" ("id") ON DELETE CASCADE
  )
''';

const List<String> _purchaseVoucherIndexSql = [
  'CREATE INDEX IF NOT EXISTS "idx_purchase_vouchers_voucher_no" ON "purchase_vouchers" ("voucher_no")',
  'CREATE INDEX IF NOT EXISTS "idx_purchase_vouchers_sequence_no" ON "purchase_vouchers" ("sequence_no")',
  'CREATE INDEX IF NOT EXISTS "idx_purchase_vouchers_customer_id" ON "purchase_vouchers" ("customer_id")',
  'CREATE INDEX IF NOT EXISTS "idx_purchase_vouchers_supplier_id" ON "purchase_vouchers" ("supplier_id")',
  'CREATE INDEX IF NOT EXISTS "idx_purchase_voucher_items_voucher_id" ON "purchase_voucher_items" ("purchase_voucher_id")',
];
