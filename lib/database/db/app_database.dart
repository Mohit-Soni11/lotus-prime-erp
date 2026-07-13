import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../config/db_config.dart';
import '../../config/env_config.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/features/stock/gold/data/receipts/gold_stock_receipt_tables.dart';
import '../tables/bill_items.dart';
import '../tables/bill_old_gold_items.dart';
import '../tables/bills.dart';
import '../tables/customer_account_ledger.dart';
import '../tables/customers.dart';
import '../tables/daily_rates/daily_rates.dart';
import '../tables/delivery/delivery_items.dart';
import '../tables/delivery/delivery_orders.dart';
import '../tables/finance/bank_accounts.dart';
import '../tables/finance/bank_transactions.dart';
import '../tables/finance/cash_transactions.dart';
import '../tables/girvi/girvi_loans.dart';
import '../tables/girvi/girvi_payments.dart';
import '../tables/girvi/girvi_loan_items.dart';
import '../tables/girvi/girvi_item_photos.dart';
import '../tables/girvi/girvi_disbursements.dart';
import '../tables/girvi/girvi_notice_actions.dart';
import '../tables/karigar/karigar_issues.dart';
import '../tables/karigar/karigar_masters.dart';
import '../tables/karigar/karigar_receipts.dart';
import '../tables/loans.dart';
import '../tables/notifications.dart';
import '../tables/sales_orders.dart';
import '../tables/shop_profile_table.dart';
import 'package:lotus_erp/features/stock/shared/data/tables/stock_items.dart';
import 'package:lotus_erp/features/stock/shared/data/tables/stock_movements.dart';
import 'package:lotus_erp/features/stock/shared/data/tables/suppliers.dart';
import '../tables/setting/billing/sales_billing_settings.dart';
import '../tables/setting/billing/purchase_billing_settings.dart';
import '../tables/setting/billing/girvi_billing_settings.dart';
import '../tables/setting/billing/shop_print_information_settings.dart';

// ✅ v16: Tax & GST
import '../../database/tables/setting/tax_gst/tax_gst_config_dao.dart';
import '../../database/tables/setting/tax_gst/tax_gst_config_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Customers,
    Suppliers,
    ShopProfiles,
    Bills,
    BillItems,
    BillOldGoldItems,
    CustomerAccountLedger,
    SalesOrders,
    OrderAdvances,
    Loans,
    Notifications,
    StockItems,
    StockMovements,
    DailyRates,
    CashTransactions,
    BankAccounts,
    BankTransactions,
    KarigarMasters,
    KarigarIssues,
    KarigarReceipts,
    GirviLoans,
    GirviPayments,
    GirviLoanItems,
    GirviItemPhotos,
    GirviDisbursements,
    GirviNoticeActions,
    DeliveryOrders,
    DeliveryItems,
    SalesBillingSettings,
    PurchaseBillingSettings,
    GirviBillingSettings,
    ShopPrintInformationSettings,
    GoldStockReceipts,
    GoldStockReceiptLines,
    GoldReceiptSettlements,
    GoldReceiptAttachments,
    GoldReceiptAuditEvents,
    TaxGstConfigs, // ✅ v16
  ],
)
class AppDatabase extends _$AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();

  factory AppDatabase() => _instance;

  AppDatabase._internal() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => DbConfig.schemaVersion;

  // ✅ DAO getter — directly use karo: AppDatabase().taxGstDao.fetchConfig()
  TaxGstConfigDao get taxGstDao => TaxGstConfigDao(this);

  /// Handles migration errors safely.
  ///
  /// SQLite raises "duplicate column name" when re-adding an existing column.
  /// This is expected when users upgrade across multiple schema versions.
  /// Any other error (disk full, permission denied, corruption) is logged
  /// and re-thrown so it surfaces immediately instead of silently corrupting data.
  static void _handleMigrationError(Object error, StackTrace stackTrace) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('duplicate column') ||
        msg.contains('already exists') ||
        msg.contains('duplicate')) {
      AppLogger.debug('Migration step skipped (already applied): $error');
      return;
    }
    AppLogger.error(
      'Unexpected migration failure',
      error: error,
      stackTrace: stackTrace,
    );
    throw error;
  }

  Future<bool> _tableExists(String tableName) async {
    final row = await customSelect(
      '''
      SELECT 1
      FROM sqlite_master
      WHERE type = 'table' AND name = ?
      LIMIT 1
      ''',
      variables: [Variable.withString(tableName)],
    ).getSingleOrNull();
    return row != null;
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _ensurePurchaseItemHuidSchema();
          await _ensureGirviPaymentReceiptIndex();
          await ensureGirviNoticeActionSchema();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          AppLogger.info('Migrating database from v$from to v$to');

          if (from < 2) {
            await m.createTable(dailyRates);
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
          }
          if (from < 5) await m.createTable(cashTransactions);
          if (from < 6) await m.addColumn(bills, bills.paidAmount);
          if (from < 7) {
            await m.createTable(bankAccounts);
            await m.createTable(bankTransactions);
          }
          if (from < 8) {
            await m.createTable(karigarMasters);
            await m.createTable(karigarIssues);
            await m.createTable(karigarReceipts);
          }
          if (from < 9) {
            await m.createTable(girviLoans);
            await m.createTable(girviPayments);
          }
          if (from < 10) {
            await m.createTable(suppliers);
            try {
              await m.addColumn(stockItems, stockItems.stoneValue);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(stockItems, stockItems.purchaseRate);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(stockItems, stockItems.supplierId);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
          }
          if (from < 11) {
            await m.createTable(deliveryOrders);
            await m.createTable(deliveryItems);
          }
          if (from < 12) {
            await customStatement(_createPurchaseVouchersTableSql);
            await customStatement(_createPurchaseVoucherItemsTableSql);
            for (final s in _purchaseVoucherIndexSql) {
              await customStatement(s);
            }
          }
          if (from < 14) {
            try {
              await customStatement('DROP TABLE IF EXISTS "billing_settings"');
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            await m.createTable(salesBillingSettings);
            await m.createTable(purchaseBillingSettings);
          }
          if (from < 15) {
            await m.createTable(girviBillingSettings);
          }

          // ✅ v16 — Tax & GST table
          if (from < 16) {
            await m.createTable(taxGstConfigs);
            AppLogger.info('v16 migration applied for TaxGstConfigs.');
          }

          if (from < 17) {
            final purchaseVoucherUpgradeSql = <String>[
              'ALTER TABLE "purchase_vouchers" ADD COLUMN "supplier_invoice_no" TEXT',
              'ALTER TABLE "purchase_vouchers" ADD COLUMN "upi_paid" REAL NOT NULL DEFAULT 0.0',
              'ALTER TABLE "purchase_vouchers" ADD COLUMN "rate_per_kg" REAL NOT NULL DEFAULT 0.0',
              'ALTER TABLE "purchase_vouchers" ADD COLUMN "metal_paid_gross_weight" REAL NOT NULL DEFAULT 0.0',
              'ALTER TABLE "purchase_vouchers" ADD COLUMN "metal_paid_purity" REAL NOT NULL DEFAULT 0.0',
              'ALTER TABLE "purchase_vouchers" ADD COLUMN "metal_paid_fine" REAL NOT NULL DEFAULT 0.0',
              'ALTER TABLE "purchase_vouchers" ADD COLUMN "metal_paid_value" REAL NOT NULL DEFAULT 0.0',
              'ALTER TABLE "purchase_vouchers" ADD COLUMN "due_mode" TEXT',
              'ALTER TABLE "purchase_vouchers" ADD COLUMN "excess_mode" TEXT',
              'ALTER TABLE "purchase_vouchers" ADD COLUMN "promise_date" INTEGER',
              'ALTER TABLE "purchase_vouchers" ADD COLUMN "payment_meta" TEXT',
              'ALTER TABLE "purchase_voucher_items" ADD COLUMN "quantity" INTEGER NOT NULL DEFAULT 1',
            ];

            for (final statement in purchaseVoucherUpgradeSql) {
              try {
                await customStatement(statement);
              } catch (e, s) {
                _handleMigrationError(e, s);
              }
            }

            AppLogger.info('v17 purchase voucher migration applied.');
          }

          if (from < 18) {
            try {
              await m.addColumn(bills, bills.billingMode);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.billType);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.paymentStatus);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.taxableAmount);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.cgstAmount);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.sgstAmount);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.gstAmount);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.makingTotal);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.cashPaid);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.upiPaid);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.cardPaid);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.advancePaid);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.dueAmount);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.oldGoldDeduction);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.oldGoldMode);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(bills, bills.promiseDate);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }

            try {
              await m.addColumn(billItems, billItems.lineNo);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(billItems, billItems.metalType);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(billItems, billItems.quantity);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(billItems, billItems.lessWeight);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(billItems, billItems.lessWeightPerPiece);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(billItems, billItems.fineWeight);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(billItems, billItems.makingChargeType);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(billItems, billItems.makingChargeInput);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(billItems, billItems.linkedStockItemId);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            try {
              await m.addColumn(billItems, billItems.linkedStockSku);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }

            try {
              await m.createTable(billOldGoldItems);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }

            AppLogger.info('v18 sales audit migration applied.');
          }

          if (from < 19) {
            await _repairBillingSetupTables(m);
            AppLogger.info('v19 billing setup settings migration applied.');
          }

          if (from < 20) {
            try {
              await m.addColumn(girviLoans, girviLoans.huidNumber);
            } catch (error) {
              AppLogger.warning('v20 Girvi HUID migration skipped: $error');
            }
            try {
              await m.addColumn(girviLoans, girviLoans.itemPhotoPath);
            } catch (error) {
              AppLogger.warning(
                'v20 Girvi item photo migration skipped: $error',
              );
            }
            try {
              await m.addColumn(girviLoans, girviLoans.invoiceGenerated);
            } catch (error) {
              AppLogger.warning(
                'v20 Girvi invoice flag migration skipped: $error',
              );
            }
            AppLogger.info(
                'v20 girvi invoice item metadata migration applied.');
          }

          if (from < 21) {
            await m.createTable(girviLoanItems);
            await m.createTable(girviItemPhotos);
            await m.createTable(girviDisbursements);
            await _backfillGirviStructuredDetails();
            AppLogger.info(
                'v21 structured girvi items, photos and disbursements applied.');
          }

          if (from < 22) {
            try {
              await m.addColumn(
                girviBillingSettings,
                girviBillingSettings.termsAndConditionsHindi,
              );
            } catch (error) {
              AppLogger.warning(
                'v22 Girvi Hindi terms migration skipped: $error',
              );
            }
            try {
              await m.addColumn(
                girviBillingSettings,
                girviBillingSettings.customerDeclaration,
              );
            } catch (error) {
              AppLogger.warning(
                'v22 Girvi customer declaration migration skipped: $error',
              );
            }
            try {
              await m.addColumn(
                girviBillingSettings,
                girviBillingSettings.customerDeclarationHindi,
              );
            } catch (error) {
              AppLogger.warning(
                'v22 Girvi Hindi declaration migration skipped: $error',
              );
            }
            AppLogger.info(
                'v22 bilingual Girvi terms and declaration applied.');
          }

          if (from < 23) {
            try {
              await m.addColumn(shopProfiles, shopProfiles.logoPath);
            } catch (error) {
              AppLogger.warning(
                'v23 shop logo path migration skipped: $error',
              );
            }
            try {
              await m.addColumn(shopProfiles, shopProfiles.logoShape);
            } catch (error) {
              AppLogger.warning(
                'v23 shop logo shape migration skipped: $error',
              );
            }
            try {
              await m.addColumn(shopProfiles, shopProfiles.signaturePath);
            } catch (error) {
              AppLogger.warning(
                'v23 shop signature path migration skipped: $error',
              );
            }
            try {
              await m.addColumn(shopProfiles, shopProfiles.signatureShape);
            } catch (error) {
              AppLogger.warning(
                'v23 shop signature shape migration skipped: $error',
              );
            }
            AppLogger.info(
                'v23 Shop Profile identity paths and shapes applied.');
          }

          if (from < 24) {
            final hasBillsTable = await _tableExists('bills');
            if (hasBillsTable) {
              try {
                await m.addColumn(bills, bills.sourceAdvanceOrderId);
              } catch (e, s) {
                _handleMigrationError(e, s);
              }
              try {
                await m.addColumn(bills, bills.sourceAdvanceOrderNo);
              } catch (e, s) {
                _handleMigrationError(e, s);
              }

              if (await _tableExists('sales_orders')) {
                await _backfillAdvanceBillSources();
              } else {
                AppLogger.warning(
                  'v24 advance bill source backfill skipped: sales_orders table missing.',
                );
              }
              AppLogger.info(
                  'v24 advance order to sales bill source links applied.');
            } else {
              AppLogger.warning(
                'v24 advance bill source migration skipped: bills table missing.',
              );
            }
          }

          if (from < 25) {
            try {
              await m.addColumn(
                girviLoans,
                girviLoans.expectedDeliveryDate,
              );
            } catch (error) {
              AppLogger.warning(
                'v25 expected Girvi delivery date migration skipped: $error',
              );
            }
            try {
              await m.addColumn(girviLoans, girviLoans.deliveredAt);
            } catch (error) {
              AppLogger.warning(
                'v25 Girvi delivered-at migration skipped: $error',
              );
            }
            try {
              await m.addColumn(
                girviPayments,
                girviPayments.principalComponent,
              );
            } catch (error) {
              AppLogger.warning(
                'v25 Girvi principal component migration skipped: $error',
              );
            }
            try {
              await m.addColumn(
                girviPayments,
                girviPayments.interestComponent,
              );
            } catch (error) {
              AppLogger.warning(
                'v25 Girvi interest component migration skipped: $error',
              );
            }
            AppLogger.info(
              'v25 Girvi settlement and delivery workflow applied.',
            );
          }

          if (from < 26) {
            try {
              await m.addColumn(girviLoans, girviLoans.releaseDiscount);
            } catch (error) {
              AppLogger.warning(
                'v26 Girvi release discount migration skipped: $error',
              );
            }
            try {
              await m.addColumn(
                girviPayments,
                girviPayments.principalDiscountComponent,
              );
            } catch (error) {
              AppLogger.warning(
                'v26 Girvi principal discount migration skipped: $error',
              );
            }
            try {
              await m.addColumn(
                girviPayments,
                girviPayments.interestDiscountComponent,
              );
            } catch (error) {
              AppLogger.warning(
                'v26 Girvi interest discount migration skipped: $error',
              );
            }
            AppLogger.info(
              'v26 Girvi release discount audit fields applied.',
            );
          }

          if (from < 27) {
            await _ensureGirviPaymentReceiptIndex();
            AppLogger.info(
              'v27 Girvi payment receipt uniqueness safeguards applied.',
            );
          }

          if (from < 28) {
            await ensureGirviNoticeActionSchema();
            AppLogger.info(
              'v28 Girvi notice action audit schema applied.',
            );
          }

          if (from < 29) {
            await m.createTable(customerAccountLedger);
            AppLogger.info(
              'v29 customer account credit ledger applied.',
            );
          }

          if (from < 32) {
            await m.createTable(shopPrintInformationSettings);
            AppLogger.info(
              'v32 shop print information settings applied.',
            );
          }

          if (from < 33) {
            await m.createTable(goldStockReceipts);
            await m.createTable(goldStockReceiptLines);
            await m.createTable(goldReceiptSettlements);
            await m.createTable(goldReceiptAttachments);
            await m.createTable(goldReceiptAuditEvents);
            AppLogger.info('v33 Gold stock receipt schema applied.');
          }

          if (from < 34) {
            try {
              await m.createTable(stockMovements);
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            AppLogger.info('v34 stock movement ledger applied.');
          }

          if (from < 35) {
            await _ensurePurchaseItemHuidSchema();
            AppLogger.info('v35 purchase item HUID serial schema applied.');
          }

          if (from < 36) {
            try {
              await customStatement(
                'ALTER TABLE "purchase_voucher_items" ADD COLUMN "item_segment" TEXT',
              );
            } catch (e, s) {
              _handleMigrationError(e, s);
            }
            AppLogger.info('v36 purchase item segment field applied.');
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement(
            'PRAGMA busy_timeout = ${DbConfig.busyTimeout.inMilliseconds}',
          );
          if (EnvConfig.enableVerboseLogs) {
            AppLogger.debug('Database opened at schema v${details.versionNow}');
          }

          await _ensureGirviPaymentReceiptIndex();
          await ensureGirviNoticeActionSchema();
          await _ensureCustomerAccountLedgerSchema();
          await _ensurePurchaseItemHuidSchema();

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
          await _ensurePurchaseItemHuidSchema();
          for (final s in _purchaseVoucherIndexSql) {
            await customStatement(s);
          }
          await ensureBillingSetupSchema();

          if (EnvConfig.enableVerboseLogs) {
            AppLogger.debug('Database bootstrap safety net complete.');
          }
        },
      );

  Future<void> ensureGirviNoticeActionSchema() async {
    await customStatement(_createGirviNoticeActionsTableSql);
    for (final statement in _girviNoticeActionColumnSafetySql) {
      try {
        await customStatement(statement);
      } catch (error, stackTrace) {
        _handleMigrationError(error, stackTrace);
      }
    }
    for (final statement in _girviNoticeActionIndexSql) {
      await customStatement(statement);
    }
  }

  Future<void> _ensureCustomerAccountLedgerSchema() async {
    await customStatement(_createCustomerAccountLedgerTableSql);
    for (final statement in _customerAccountLedgerIndexSql) {
      await customStatement(statement);
    }
  }

  Future<void> _ensurePurchaseItemHuidSchema() async {
    await customStatement(_createPurchaseItemHuidTableSql);
    for (final statement in _purchaseItemHuidIndexSql) {
      await customStatement(statement);
    }
  }

  Future<void> _ensureGirviPaymentReceiptIndex() async {
    try {
      await customStatement('''
        UPDATE "girvi_payments"
        SET "receipt_no" = "receipt_no" || '-DUP-' || "id"
        WHERE "receipt_no" IS NOT NULL
          AND "id" NOT IN (
            SELECT MIN("id")
            FROM "girvi_payments"
            WHERE "receipt_no" IS NOT NULL
            GROUP BY "receipt_no"
          )
      ''');
      await customStatement('''
        CREATE UNIQUE INDEX IF NOT EXISTS "idx_girvi_pay_receipt_no_unique"
        ON "girvi_payments" ("receipt_no")
        WHERE "receipt_no" IS NOT NULL
      ''');
    } catch (error) {
      AppLogger.warning(
        'Girvi payment receipt uniqueness safeguard skipped: $error',
      );
    }
  }

  Future<void> _backfillGirviStructuredDetails() async {
    await customStatement('''
      INSERT INTO "girvi_loan_items" (
        "girvi_id",
        "serial_no",
        "item_name",
        "metal_type",
        "purity",
        "purity_factor",
        "pieces",
        "huid_number",
        "gross_weight",
        "less_weight",
        "net_weight",
        "valuation_method",
        "fine_weight",
        "rate_per_gram",
        "valuation_amount",
        "is_legacy"
      )
      SELECT
        loan."id",
        1,
        loan."item_description",
        loan."metal_type",
        loan."metal_purity",
        CASE loan."metal_purity"
          WHEN '24K' THEN 0.999
          WHEN '22K' THEN 0.916
          WHEN '18K' THEN 0.750
          WHEN '14K' THEN 0.585
          WHEN '999' THEN 0.999
          WHEN '925' THEN 0.925
          WHEN '800' THEN 0.800
          ELSE 0.0
        END,
        loan."item_count",
        loan."huid_number",
        loan."gross_weight",
        loan."stone_weight",
        loan."net_weight",
        'LEGACY',
        loan."net_weight",
        loan."rate_per_gram",
        loan."total_value",
        1
      FROM "girvi_loans" AS loan
      WHERE NOT EXISTS (
        SELECT 1
        FROM "girvi_loan_items" AS item
        WHERE item."girvi_id" = loan."id"
      )
    ''');

    await customStatement('''
      INSERT INTO "girvi_item_photos" (
        "item_id",
        "file_path",
        "sort_order",
        "is_legacy"
      )
      SELECT
        item."id",
        loan."item_photo_path",
        1,
        1
      FROM "girvi_loans" AS loan
      INNER JOIN "girvi_loan_items" AS item
        ON item."girvi_id" = loan."id" AND item."serial_no" = 1
      WHERE loan."item_photo_path" IS NOT NULL
        AND TRIM(loan."item_photo_path") <> ''
        AND NOT EXISTS (
          SELECT 1
          FROM "girvi_item_photos" AS photo
          WHERE photo."item_id" = item."id"
        )
    ''');

    await customStatement('''
      INSERT INTO "girvi_disbursements" (
        "girvi_id",
        "sequence_no",
        "mode",
        "display_label",
        "amount",
        "details",
        "is_legacy"
      )
      SELECT
        loan."id",
        1,
        'LEGACY',
        loan."disbursement_mode",
        loan."loan_amount",
        loan."disbursement_mode",
        1
      FROM "girvi_loans" AS loan
      WHERE NOT EXISTS (
        SELECT 1
        FROM "girvi_disbursements" AS entry
        WHERE entry."girvi_id" = loan."id"
      )
    ''');
  }

  Future<void> ensureBillingSetupSchema() async {
    Future<void> runIfNeeded(String statement) async {
      try {
        await customStatement(statement);
      } catch (e, s) {
        _handleMigrationError(e, s);
      }
    }

    for (final statement in _billingSetupSchemaSafetySql) {
      await runIfNeeded(statement);
    }
  }

  Future<void> _repairBillingSetupTables(Migrator m) async {
    Future<void> runIfNeeded(Future<void> Function() action) async {
      try {
        await action();
      } catch (e, s) {
        _handleMigrationError(e, s);
      }
    }

    await runIfNeeded(() => m.createTable(salesBillingSettings));
    await runIfNeeded(() => m.createTable(purchaseBillingSettings));
    await runIfNeeded(() => m.createTable(girviBillingSettings));
    await runIfNeeded(() => m.createTable(shopPrintInformationSettings));

    await runIfNeeded(
        () => customStatement('DROP TABLE IF EXISTS "billing_settings"'));

    await runIfNeeded(() =>
        m.addColumn(salesBillingSettings, salesBillingSettings.showPieces));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.showGrossWeight));
    await runIfNeeded(() =>
        m.addColumn(salesBillingSettings, salesBillingSettings.showLessWeight));
    await runIfNeeded(() =>
        m.addColumn(salesBillingSettings, salesBillingSettings.showNetWeight));
    await runIfNeeded(() =>
        m.addColumn(salesBillingSettings, salesBillingSettings.showPurity));
    await runIfNeeded(
        () => m.addColumn(salesBillingSettings, salesBillingSettings.showRate));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.showMakingCharges));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.showMakingChargeType));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.showStoneDetails));
    await runIfNeeded(() =>
        m.addColumn(salesBillingSettings, salesBillingSettings.showStoneValue));
    await runIfNeeded(() =>
        m.addColumn(salesBillingSettings, salesBillingSettings.showTotalValue));
    await runIfNeeded(
        () => m.addColumn(salesBillingSettings, salesBillingSettings.showHuid));
    await runIfNeeded(() =>
        m.addColumn(salesBillingSettings, salesBillingSettings.showWastage));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.showOldGoldLine));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.showDiamondClarity));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.showCertificationNo));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.showDiamondCarats));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.showDiamondPieces));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.showMetalWeight));
    await runIfNeeded(() =>
        m.addColumn(salesBillingSettings, salesBillingSettings.showFineWeight));
    await runIfNeeded(() =>
        m.addColumn(salesBillingSettings, salesBillingSettings.showGstBreakup));
    await runIfNeeded(() =>
        m.addColumn(salesBillingSettings, salesBillingSettings.showHsnCode));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.returnWindowDays));
    await runIfNeeded(() =>
        m.addColumn(salesBillingSettings, salesBillingSettings.returnMode));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.handlingChargePercent));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.buybackRatePercent));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.buybackPurityDeductPercent));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.termsAndConditions));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.returnPolicyText));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.buybackPolicyText));
    await runIfNeeded(() =>
        m.addColumn(salesBillingSettings, salesBillingSettings.footerMessage));
    await runIfNeeded(() => m.addColumn(
        salesBillingSettings, salesBillingSettings.selectedTemplate));

    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showGrossWeight));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showLessWeight));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showNetWeight));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showPurity));
    await runIfNeeded(() =>
        m.addColumn(purchaseBillingSettings, purchaseBillingSettings.showRate));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showFineWeight));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showTotalValue));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showStoneDetails));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showStoneValue));
    await runIfNeeded(() =>
        m.addColumn(purchaseBillingSettings, purchaseBillingSettings.showHuid));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showSupplierDetails));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showPanNumber));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showDiamondCarats));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showDiamondClarity));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showCertificationNo));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showGstBreakup));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.showHsnCode));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.returnWindowDays));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.returnMode));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.purityDeductPercent));
    await runIfNeeded(() => m.addColumn(purchaseBillingSettings,
        purchaseBillingSettings.lateReclaimPenaltyAmount));
    await runIfNeeded(() => m.addColumn(purchaseBillingSettings,
        purchaseBillingSettings.highValueReclaimThreshold));
    await runIfNeeded(() => m.addColumn(purchaseBillingSettings,
        purchaseBillingSettings.highValueReclaimPenaltyPercent));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.termsAndConditions));
    await runIfNeeded(() => m.addColumn(purchaseBillingSettings,
        purchaseBillingSettings.sellerDeclarationText));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.returnPolicyText));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.buybackPolicyText));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.footerMessage));
    await runIfNeeded(() => m.addColumn(
        purchaseBillingSettings, purchaseBillingSettings.selectedTemplate));

    await runIfNeeded(() =>
        m.addColumn(girviBillingSettings, girviBillingSettings.girviPrefix));
    await runIfNeeded(() =>
        m.addColumn(girviBillingSettings, girviBillingSettings.startingNumber));
    await runIfNeeded(() => m.addColumn(
        girviBillingSettings, girviBillingSettings.defaultInterestRate));
    await runIfNeeded(() =>
        m.addColumn(girviBillingSettings, girviBillingSettings.interestType));
    await runIfNeeded(() => m.addColumn(
        girviBillingSettings, girviBillingSettings.gracePeriodDays));
    await runIfNeeded(() => m.addColumn(
        girviBillingSettings, girviBillingSettings.defaultDuration));
    await runIfNeeded(() =>
        m.addColumn(girviBillingSettings, girviBillingSettings.reminderDays));
    await runIfNeeded(() =>
        m.addColumn(girviBillingSettings, girviBillingSettings.noticeDays));
    await runIfNeeded(() => m.addColumn(
        girviBillingSettings, girviBillingSettings.termsAndConditions));
    await runIfNeeded(() => m.addColumn(
        girviBillingSettings, girviBillingSettings.termsAndConditionsHindi));
    await runIfNeeded(() => m.addColumn(
        girviBillingSettings, girviBillingSettings.customerDeclaration));
    await runIfNeeded(() => m.addColumn(
        girviBillingSettings, girviBillingSettings.customerDeclarationHindi));
    await runIfNeeded(() =>
        m.addColumn(girviBillingSettings, girviBillingSettings.footerMessage));
    await runIfNeeded(() =>
        m.addColumn(girviBillingSettings, girviBillingSettings.autoPrint));
    await runIfNeeded(() => m.addColumn(
        girviBillingSettings, girviBillingSettings.selectedTemplate));

    await runIfNeeded(() => customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS "idx_sales_billing_metal" ON "sales_billing_settings" ("metal")'));
    await runIfNeeded(() => customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS "idx_purchase_billing_metal" ON "purchase_billing_settings" ("metal")'));
  }

  Future<void> _backfillAdvanceBillSources() async {
    try {
      await customStatement('''
        UPDATE bills
        SET
          source_advance_order_id = (
            SELECT sales_orders.id
            FROM sales_orders
            WHERE sales_orders.customer_id = bills.customer_id
              AND sales_orders.notes = 'Converted to sales invoice ' || bills.bill_no
            LIMIT 1
          ),
          source_advance_order_no = (
            SELECT sales_orders.order_no
            FROM sales_orders
            WHERE sales_orders.customer_id = bills.customer_id
              AND sales_orders.notes = 'Converted to sales invoice ' || bills.bill_no
            LIMIT 1
          )
        WHERE source_advance_order_id IS NULL
          AND EXISTS (
            SELECT 1
            FROM sales_orders
            WHERE sales_orders.customer_id = bills.customer_id
              AND sales_orders.notes = 'Converted to sales invoice ' || bills.bill_no
          )
      ''');
    } catch (error) {
      AppLogger.warning('Advance bill source backfill skipped: $error');
    }
  }
}

const List<String> _billingSetupSchemaSafetySql = [
  '''
  CREATE TABLE IF NOT EXISTS "shop_print_information_settings" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "created_at" INTEGER NOT NULL DEFAULT 0,
    "updated_at" INTEGER,
    "tenant_id" TEXT NOT NULL,
    "enabled_field_ids_json" TEXT NOT NULL DEFAULT '[]'
  )
  ''',
  '''
  CREATE UNIQUE INDEX IF NOT EXISTS "idx_shop_print_information_tenant"
  ON "shop_print_information_settings" ("tenant_id")
  ''',
  '''
  CREATE TABLE IF NOT EXISTS "sales_billing_settings" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "created_at" INTEGER NOT NULL DEFAULT 0,
    "updated_at" INTEGER,
    "metal" TEXT NOT NULL,
    "show_pieces" INTEGER NOT NULL DEFAULT 1,
    "show_gross_weight" INTEGER NOT NULL DEFAULT 1,
    "show_less_weight" INTEGER NOT NULL DEFAULT 1,
    "show_net_weight" INTEGER NOT NULL DEFAULT 1,
    "show_purity" INTEGER NOT NULL DEFAULT 1,
    "show_rate" INTEGER NOT NULL DEFAULT 1,
    "show_making_charges" INTEGER NOT NULL DEFAULT 1,
    "show_making_charge_type" INTEGER NOT NULL DEFAULT 1,
    "show_stone_details" INTEGER NOT NULL DEFAULT 0,
    "show_stone_value" INTEGER NOT NULL DEFAULT 0,
    "show_total_value" INTEGER NOT NULL DEFAULT 1,
    "show_huid" INTEGER NOT NULL DEFAULT 0,
    "show_wastage" INTEGER NOT NULL DEFAULT 0,
    "show_old_gold_line" INTEGER NOT NULL DEFAULT 1,
    "show_diamond_clarity" INTEGER NOT NULL DEFAULT 1,
    "show_certification_no" INTEGER NOT NULL DEFAULT 0,
    "show_diamond_carats" INTEGER NOT NULL DEFAULT 1,
    "show_diamond_pieces" INTEGER NOT NULL DEFAULT 1,
    "show_metal_weight" INTEGER NOT NULL DEFAULT 1,
    "show_fine_weight" INTEGER NOT NULL DEFAULT 0,
    "show_gst_breakup" INTEGER NOT NULL DEFAULT 0,
    "show_hsn_code" INTEGER NOT NULL DEFAULT 0,
    "return_window_days" INTEGER NOT NULL DEFAULT 7,
    "return_mode" TEXT NOT NULL DEFAULT 'Exchange Only',
    "handling_charge_percent" REAL NOT NULL DEFAULT 0.0,
    "buyback_rate_percent" REAL NOT NULL DEFAULT 90.0,
    "buyback_purity_deduct_percent" REAL NOT NULL DEFAULT 2.0,
    "terms_and_conditions" TEXT NOT NULL DEFAULT '',
    "return_policy_text" TEXT NOT NULL DEFAULT '',
    "buyback_policy_text" TEXT NOT NULL DEFAULT '',
    "footer_message" TEXT NOT NULL DEFAULT '',
    "selected_template" TEXT NOT NULL DEFAULT 'default'
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS "purchase_billing_settings" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "created_at" INTEGER NOT NULL DEFAULT 0,
    "updated_at" INTEGER,
    "metal" TEXT NOT NULL,
    "show_gross_weight" INTEGER NOT NULL DEFAULT 1,
    "show_less_weight" INTEGER NOT NULL DEFAULT 1,
    "show_net_weight" INTEGER NOT NULL DEFAULT 1,
    "show_purity" INTEGER NOT NULL DEFAULT 1,
    "show_rate" INTEGER NOT NULL DEFAULT 1,
    "show_fine_weight" INTEGER NOT NULL DEFAULT 1,
    "show_total_value" INTEGER NOT NULL DEFAULT 1,
    "show_stone_details" INTEGER NOT NULL DEFAULT 0,
    "show_stone_value" INTEGER NOT NULL DEFAULT 0,
    "show_huid" INTEGER NOT NULL DEFAULT 0,
    "show_supplier_details" INTEGER NOT NULL DEFAULT 1,
    "show_pan_number" INTEGER NOT NULL DEFAULT 1,
    "show_diamond_carats" INTEGER NOT NULL DEFAULT 1,
    "show_diamond_clarity" INTEGER NOT NULL DEFAULT 1,
    "show_certification_no" INTEGER NOT NULL DEFAULT 0,
    "show_gst_breakup" INTEGER NOT NULL DEFAULT 0,
    "show_hsn_code" INTEGER NOT NULL DEFAULT 0,
    "return_window_days" INTEGER NOT NULL DEFAULT 1,
    "return_mode" TEXT NOT NULL DEFAULT 'Cash Refund',
    "purity_deduct_percent" REAL NOT NULL DEFAULT 2.0,
    "late_reclaim_penalty_amount" REAL NOT NULL DEFAULT 2000.0,
    "high_value_reclaim_threshold" REAL NOT NULL DEFAULT 50000.0,
    "high_value_reclaim_penalty_percent" REAL NOT NULL DEFAULT 12.0,
    "terms_and_conditions" TEXT NOT NULL DEFAULT '',
    "seller_declaration_text" TEXT NOT NULL DEFAULT '',
    "return_policy_text" TEXT NOT NULL DEFAULT '',
    "buyback_policy_text" TEXT NOT NULL DEFAULT '',
    "footer_message" TEXT NOT NULL DEFAULT '',
    "selected_template" TEXT NOT NULL DEFAULT 'default'
  )
  ''',
  '''
  CREATE TABLE IF NOT EXISTS "girvi_billing_settings" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "created_at" INTEGER NOT NULL DEFAULT 0,
    "updated_at" INTEGER,
    "girvi_prefix" TEXT NOT NULL DEFAULT 'GRV-',
    "starting_number" INTEGER NOT NULL DEFAULT 1,
    "default_interest_rate" REAL NOT NULL DEFAULT 1.5,
    "interest_type" TEXT NOT NULL DEFAULT 'Simple',
    "grace_period_days" INTEGER NOT NULL DEFAULT 3,
    "default_duration" TEXT NOT NULL DEFAULT '6 Months',
    "reminder_days" INTEGER NOT NULL DEFAULT 15,
    "notice_days" INTEGER NOT NULL DEFAULT 30,
    "terms_and_conditions" TEXT NOT NULL DEFAULT '',
    "terms_and_conditions_hindi" TEXT NOT NULL DEFAULT 'ऋण राशि पर ब्याज प्रति माह लिया जाएगा।
नोटिस अवधि के बाद न छुड़ाए गए आभूषणों की नीलामी लागू कानून के अनुसार की जा सकती है।
ग्राहक समय पर भुगतान और ऋण छुड़ाने के लिए जिम्मेदार है।',
    "customer_declaration" TEXT NOT NULL DEFAULT 'I declare that the pledged articles belong to me, are free from dispute, and the information provided by me is true. I have verified the item details, loan amount and interest terms, and have received the stated disbursement.',
    "customer_declaration_hindi" TEXT NOT NULL DEFAULT 'मैं घोषणा करता/करती हूं कि गिरवी रखी गई वस्तुएं मेरी हैं, किसी विवाद से मुक्त हैं और मेरे द्वारा दी गई जानकारी सत्य है। मैंने वस्तुओं का विवरण, ऋण राशि और ब्याज की शर्तें जांच ली हैं तथा बताई गई भुगतान राशि प्राप्त कर ली है।',
    "footer_message" TEXT NOT NULL DEFAULT 'Please keep this Girvi receipt safely.',
    "auto_print" INTEGER NOT NULL DEFAULT 1,
    "selected_template" TEXT NOT NULL DEFAULT 'default'
  )
  ''',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "created_at" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "updated_at" INTEGER',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "metal" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_pieces" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_gross_weight" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_less_weight" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_net_weight" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_purity" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_rate" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_making_charges" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_making_charge_type" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_stone_details" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_stone_value" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_total_value" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_huid" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_wastage" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_old_gold_line" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_diamond_clarity" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_certification_no" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_diamond_carats" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_diamond_pieces" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_metal_weight" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_fine_weight" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_gst_breakup" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "show_hsn_code" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "return_window_days" INTEGER NOT NULL DEFAULT 7',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "return_mode" TEXT NOT NULL DEFAULT "Exchange Only"',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "handling_charge_percent" REAL NOT NULL DEFAULT 0.0',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "buyback_rate_percent" REAL NOT NULL DEFAULT 90.0',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "buyback_purity_deduct_percent" REAL NOT NULL DEFAULT 2.0',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "terms_and_conditions" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "return_policy_text" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "buyback_policy_text" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "footer_message" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "sales_billing_settings" ADD COLUMN "selected_template" TEXT NOT NULL DEFAULT "default"',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "created_at" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "updated_at" INTEGER',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "metal" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_gross_weight" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_less_weight" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_net_weight" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_purity" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_rate" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_fine_weight" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_total_value" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_stone_details" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_stone_value" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_huid" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_supplier_details" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_pan_number" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_diamond_carats" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_diamond_clarity" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_certification_no" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_gst_breakup" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "show_hsn_code" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "return_window_days" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "return_mode" TEXT NOT NULL DEFAULT "Cash Refund"',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "purity_deduct_percent" REAL NOT NULL DEFAULT 2.0',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "late_reclaim_penalty_amount" REAL NOT NULL DEFAULT 2000.0',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "high_value_reclaim_threshold" REAL NOT NULL DEFAULT 50000.0',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "high_value_reclaim_penalty_percent" REAL NOT NULL DEFAULT 12.0',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "terms_and_conditions" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "seller_declaration_text" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "return_policy_text" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "buyback_policy_text" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "footer_message" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "purchase_billing_settings" ADD COLUMN "selected_template" TEXT NOT NULL DEFAULT "default"',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "created_at" INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "updated_at" INTEGER',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "girvi_prefix" TEXT NOT NULL DEFAULT "GRV-"',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "starting_number" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "default_interest_rate" REAL NOT NULL DEFAULT 1.5',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "interest_type" TEXT NOT NULL DEFAULT "Simple"',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "grace_period_days" INTEGER NOT NULL DEFAULT 3',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "default_duration" TEXT NOT NULL DEFAULT "6 Months"',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "reminder_days" INTEGER NOT NULL DEFAULT 15',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "notice_days" INTEGER NOT NULL DEFAULT 30',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "terms_and_conditions" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "terms_and_conditions_hindi" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "customer_declaration" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "customer_declaration_hindi" TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "footer_message" TEXT NOT NULL DEFAULT "Please keep this Girvi receipt safely."',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "auto_print" INTEGER NOT NULL DEFAULT 1',
  'ALTER TABLE "girvi_billing_settings" ADD COLUMN "selected_template" TEXT NOT NULL DEFAULT "default"',
  'CREATE UNIQUE INDEX IF NOT EXISTS "idx_sales_billing_metal" ON "sales_billing_settings" ("metal")',
  'CREATE UNIQUE INDEX IF NOT EXISTS "idx_purchase_billing_metal" ON "purchase_billing_settings" ("metal")',
];

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, DbConfig.dbName));
    return NativeDatabase(
      file,
      logStatements: EnvConfig.enableSqlLogging,
      setup: (db) {
        if (DbConfig.enableWal) {
          db.execute('PRAGMA journal_mode=WAL;');
        }
        db.execute(
            'PRAGMA busy_timeout = ${DbConfig.busyTimeout.inMilliseconds};');
      },
    );
  });
}

const String _createPurchaseVouchersTableSql = '''
  CREATE TABLE IF NOT EXISTS "purchase_vouchers" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "voucher_no" TEXT NOT NULL UNIQUE,
    "sequence_no" INTEGER NOT NULL,
    "supplier_invoice_no" TEXT,
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
    "upi_paid" REAL NOT NULL DEFAULT 0.0,
    "bank_paid" REAL NOT NULL DEFAULT 0.0,
    "card_paid" REAL NOT NULL DEFAULT 0.0,
    "total_paid" REAL NOT NULL DEFAULT 0.0,
    "balance_due" REAL NOT NULL DEFAULT 0.0,
    "rate_per_kg" REAL NOT NULL DEFAULT 0.0,
    "metal_paid_gross_weight" REAL NOT NULL DEFAULT 0.0,
    "metal_paid_purity" REAL NOT NULL DEFAULT 0.0,
    "metal_paid_fine" REAL NOT NULL DEFAULT 0.0,
    "metal_paid_value" REAL NOT NULL DEFAULT 0.0,
    "due_mode" TEXT,
    "excess_mode" TEXT,
    "promise_date" INTEGER,
    "payment_meta" TEXT,
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
    "item_segment" TEXT,
    "gross_weight" REAL NOT NULL DEFAULT 0.0,
    "less_weight" REAL NOT NULL DEFAULT 0.0,
    "net_weight" REAL NOT NULL DEFAULT 0.0,
    "purity" REAL NOT NULL DEFAULT 0.0,
    "fine_weight" REAL NOT NULL DEFAULT 0.0,
    "rate" REAL NOT NULL DEFAULT 0.0,
    "quantity" INTEGER NOT NULL DEFAULT 1,
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

const String _createPurchaseItemHuidTableSql = '''
CREATE TABLE IF NOT EXISTS "purchase_item_huids" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "purchase_voucher_id" INTEGER NOT NULL,
  "purchase_voucher_item_id" INTEGER,
  "stock_item_id" INTEGER,
  "line_no" INTEGER NOT NULL,
  "piece_no" INTEGER NOT NULL,
  "huid" TEXT NOT NULL,
  "created_at" INTEGER NOT NULL,
  FOREIGN KEY ("purchase_voucher_id") REFERENCES "purchase_vouchers" ("id") ON DELETE CASCADE
)
''';

const List<String> _purchaseItemHuidIndexSql = [
  'CREATE INDEX IF NOT EXISTS "idx_purchase_item_huids_huid" ON "purchase_item_huids" ("huid")',
  'CREATE INDEX IF NOT EXISTS "idx_purchase_item_huids_voucher" ON "purchase_item_huids" ("purchase_voucher_id")',
  'CREATE INDEX IF NOT EXISTS "idx_purchase_item_huids_stock_item" ON "purchase_item_huids" ("stock_item_id")',
];

const String _createCustomerAccountLedgerTableSql = '''
CREATE TABLE IF NOT EXISTS "customer_account_ledger" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "created_at" INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
  "updated_at" INTEGER,
  "customer_id" INTEGER NOT NULL,
  "entry_type" TEXT NOT NULL,
  "source_type" TEXT NOT NULL,
  "source_reference" TEXT,
  "amount" REAL NOT NULL DEFAULT 0.0,
  "payment_mode" TEXT,
  "notes" TEXT,
  "entry_date" INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
  "is_voided" INTEGER NOT NULL DEFAULT 0,
  "void_reason" TEXT,
  FOREIGN KEY ("customer_id") REFERENCES "customers" ("id") ON DELETE RESTRICT
)
''';

const List<String> _customerAccountLedgerIndexSql = [
  'CREATE INDEX IF NOT EXISTS "idx_customer_account_customer" ON "customer_account_ledger" ("customer_id")',
  'CREATE INDEX IF NOT EXISTS "idx_customer_account_reference" ON "customer_account_ledger" ("source_reference")',
  'CREATE INDEX IF NOT EXISTS "idx_customer_account_date" ON "customer_account_ledger" ("entry_date")',
];

const String _createGirviNoticeActionsTableSql = '''
CREATE TABLE IF NOT EXISTS "girvi_notice_actions" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "created_at" INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
  "updated_at" INTEGER,
  "girvi_id" INTEGER NOT NULL,
  "action_type" TEXT NOT NULL,
  "notice_stage" INTEGER,
  "notice_text" TEXT,
  "action_note" TEXT,
  "pledged_valuation" REAL NOT NULL DEFAULT 0.0,
  "recovered_amount" REAL NOT NULL DEFAULT 0.0,
  "penalty_amount" REAL NOT NULL DEFAULT 0.0,
  "settlement_total" REAL NOT NULL DEFAULT 0.0,
  "customer_balance_due" REAL NOT NULL DEFAULT 0.0,
  "customer_surplus" REAL NOT NULL DEFAULT 0.0,
  "action_at" INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
  "delivery_channel" TEXT,
  "delivery_status" TEXT,
  "delivery_reference" TEXT,
  "delivered_at" INTEGER,
  FOREIGN KEY ("girvi_id") REFERENCES "girvi_loans" ("id") ON DELETE CASCADE
)
''';

const List<String> _girviNoticeActionColumnSafetySql = [
  'ALTER TABLE "girvi_notice_actions" ADD COLUMN "notice_stage" INTEGER',
  'ALTER TABLE "girvi_notice_actions" ADD COLUMN "pledged_valuation" REAL NOT NULL DEFAULT 0.0',
  'ALTER TABLE "girvi_notice_actions" ADD COLUMN "recovered_amount" REAL NOT NULL DEFAULT 0.0',
  'ALTER TABLE "girvi_notice_actions" ADD COLUMN "penalty_amount" REAL NOT NULL DEFAULT 0.0',
  'ALTER TABLE "girvi_notice_actions" ADD COLUMN "settlement_total" REAL NOT NULL DEFAULT 0.0',
  'ALTER TABLE "girvi_notice_actions" ADD COLUMN "customer_balance_due" REAL NOT NULL DEFAULT 0.0',
  'ALTER TABLE "girvi_notice_actions" ADD COLUMN "customer_surplus" REAL NOT NULL DEFAULT 0.0',
  'ALTER TABLE "girvi_notice_actions" ADD COLUMN "delivery_channel" TEXT',
  'ALTER TABLE "girvi_notice_actions" ADD COLUMN "delivery_status" TEXT',
  'ALTER TABLE "girvi_notice_actions" ADD COLUMN "delivery_reference" TEXT',
  'ALTER TABLE "girvi_notice_actions" ADD COLUMN "delivered_at" INTEGER',
];

const List<String> _girviNoticeActionIndexSql = [
  'CREATE INDEX IF NOT EXISTS "idx_girvi_notice_action_loan" ON "girvi_notice_actions" ("girvi_id", "action_at" DESC)',
  'CREATE INDEX IF NOT EXISTS "idx_girvi_notice_action_stage" ON "girvi_notice_actions" ("girvi_id", "notice_stage")',
  'CREATE INDEX IF NOT EXISTS "idx_girvi_notice_action_type" ON "girvi_notice_actions" ("action_type")',
  'CREATE INDEX IF NOT EXISTS "idx_girvi_notice_action_delivery" ON "girvi_notice_actions" ("girvi_id", "delivery_status", "delivered_at" DESC)',
];
