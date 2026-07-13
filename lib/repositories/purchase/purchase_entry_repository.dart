import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/finance/bank_book/bank_book_enums.dart';
import '../../models/finance/cash_book/cash_book_enums.dart';
import '../../models/purchase/purchase_enums/purchase_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class PurchaseVoucherPartyDraft {
  final int? customerId;
  final int? supplierId;
  final String name;
  final String? contactName;
  final String? mobile;
  final String? city;
  final String? panNumber;
  final String? gstNumber;

  const PurchaseVoucherPartyDraft({
    this.customerId,
    this.supplierId,
    required this.name,
    this.contactName,
    this.mobile,
    this.city,
    this.panNumber,
    this.gstNumber,
  });
}

class PurchaseVoucherItemDraft {
  final PurchaseMetalType metal;
  final String description;
  final String segmentLabel;
  final int quantity;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double purity;
  final double fineWeight;
  final double rate;
  final double lineAmount;
  final String subCategory;
  final String? huid;
  final List<String> huids;
  final String? hsnCode;
  final double labourCharge;
  final MakingChargesType labourType;
  final String purityLabel;
  final double effectiveRatePerGram;
  final double gstRate;

  const PurchaseVoucherItemDraft({
    required this.metal,
    required this.description,
    this.segmentLabel = '',
    this.quantity = 1,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.purity,
    required this.fineWeight,
    required this.rate,
    required this.lineAmount,
    this.subCategory = 'Purchase Inward',
    this.huid,
    this.huids = const [],
    this.hsnCode,
    this.labourCharge = 0.0,
    this.labourType = MakingChargesType.perGram,
    this.purityLabel = '',
    this.effectiveRatePerGram = 0.0,
    this.gstRate = 0.0,
  });
}

class PurchaseVoucherDraft {
  final int sequenceNo;
  final String voucherNo;
  final String? supplierInvoiceNo;
  final PurchaseSource source;
  final PurchaseTaxType taxType;
  final PurchaseDiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final double grossAmount;
  final double taxableAmount;
  final double gstAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double grandTotal;
  final double cashPaid;
  final double upiPaid;
  final double bankPaid;
  final double cardPaid;
  final double totalPaid;
  final double balanceDue;
  final double ratePerKg;
  final double metalPaidGrossWeight;
  final double metalPaidPurity;
  final double metalPaidFine;
  final double metalPaidValue;
  final String? dueMode;
  final String? excessMode;
  final DateTime? promiseDate;
  final String? paymentMeta;
  final PurchaseVoucherPartyDraft party;
  final List<PurchaseVoucherItemDraft> items;

  const PurchaseVoucherDraft({
    required this.sequenceNo,
    required this.voucherNo,
    this.supplierInvoiceNo,
    required this.source,
    required this.taxType,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.grossAmount,
    required this.taxableAmount,
    required this.gstAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.grandTotal,
    required this.cashPaid,
    this.upiPaid = 0.0,
    required this.bankPaid,
    required this.cardPaid,
    required this.totalPaid,
    required this.balanceDue,
    this.ratePerKg = 0.0,
    this.metalPaidGrossWeight = 0.0,
    this.metalPaidPurity = 0.0,
    this.metalPaidFine = 0.0,
    this.metalPaidValue = 0.0,
    this.dueMode,
    this.excessMode,
    this.promiseDate,
    this.paymentMeta,
    required this.party,
    required this.items,
  });
}

class PurchaseSaveResult {
  final int voucherId;
  final String voucherNo;
  final int stockEntryCount;

  const PurchaseSaveResult({
    required this.voucherId,
    required this.voucherNo,
    required this.stockEntryCount,
  });
}

class PurchaseEntryRepository {
  final AppDatabase _db;
  String? _lastErrorMessage;

  PurchaseEntryRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  String? get lastErrorMessage => _lastErrorMessage;

  Future<int> getNextSequence() async {
    try {
      final row = await _db
          .customSelect(
            'SELECT COALESCE(MAX(sequence_no), 0) AS max_no FROM purchase_vouchers',
          )
          .getSingle();
      final currentMax = row.read<int>('max_no');
      return currentMax + 1;
    } catch (error) {
      AppLogger.debug('PurchaseEntryRepository.getNextSequence: $error');
      return 1;
    }
  }

  Future<PurchaseSaveResult?> savePurchase(PurchaseVoucherDraft draft) async {
    _lastErrorMessage = null;
    try {
      await _ensurePurchaseSchemaCompatibility();
      return await _db.transaction(() async {
        final now = DateTime.now();
        final createdAtMs = now.millisecondsSinceEpoch;
        final isSupplierPurchase = draft.source == PurchaseSource.fromSupplier;
        final paymentStatus = _resolvePaymentStatus(
          draft.balanceDue,
          draft.totalPaid,
        );

        await _db.customStatement(
          '''
          INSERT INTO purchase_vouchers (
            voucher_no,
            sequence_no,
            supplier_invoice_no,
            source_type,
            customer_id,
            supplier_id,
            party_name,
            contact_name,
            mobile,
            city,
            pan_number,
            gst_number,
            tax_type,
            discount_type,
            discount_value,
            discount_amount,
            gross_amount,
            taxable_amount,
            gst_amount,
            cgst_amount,
            sgst_amount,
            grand_total,
            cash_paid,
            upi_paid,
            bank_paid,
            card_paid,
            total_paid,
            balance_due,
            rate_per_kg,
            metal_paid_gross_weight,
            metal_paid_purity,
            metal_paid_fine,
            metal_paid_value,
            due_mode,
            excess_mode,
            promise_date,
            payment_meta,
            payment_status,
            stock_entry_count,
            status,
            created_at,
            updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            draft.voucherNo,
            draft.sequenceNo,
            draft.supplierInvoiceNo,
            draft.source == PurchaseSource.fromCustomer
                ? 'CUSTOMER'
                : 'SUPPLIER',
            draft.party.customerId,
            draft.party.supplierId,
            draft.party.name,
            draft.party.contactName,
            draft.party.mobile,
            draft.party.city,
            draft.party.panNumber,
            draft.party.gstNumber,
            draft.taxType == PurchaseTaxType.gst ? 'GST' : 'NORMAL',
            draft.discountType == PurchaseDiscountType.percentage
                ? 'PERCENTAGE'
                : 'FLAT',
            draft.discountValue,
            draft.discountAmount,
            draft.grossAmount,
            draft.taxableAmount,
            draft.gstAmount,
            draft.cgstAmount,
            draft.sgstAmount,
            draft.grandTotal,
            draft.cashPaid,
            draft.upiPaid,
            draft.bankPaid,
            draft.cardPaid,
            draft.totalPaid,
            draft.balanceDue,
            draft.ratePerKg,
            draft.metalPaidGrossWeight,
            draft.metalPaidPurity,
            draft.metalPaidFine,
            draft.metalPaidValue,
            draft.dueMode,
            draft.excessMode,
            draft.promiseDate?.millisecondsSinceEpoch,
            draft.paymentMeta,
            paymentStatus,
            draft.items.length,
            'SAVED',
            createdAtMs,
            createdAtMs,
          ],
        );

        final voucherRow = await _db
            .customSelect('SELECT last_insert_rowid() AS id')
            .getSingle();
        final voucherId = voucherRow.read<int>('id');

        var stockEntryCount = 0;
        for (var index = 0; index < draft.items.length; index++) {
          final item = draft.items[index];
          final sku = _buildSku(item.metal, createdAtMs, index + 1);

          await _db.customStatement(
            '''
            INSERT INTO purchase_voucher_items (
              purchase_voucher_id,
              line_no,
              sku,
              metal_type,
              item_description,
              item_segment,
              gross_weight,
              less_weight,
              net_weight,
              purity,
              fine_weight,
              rate,
              quantity,
              line_amount,
              created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              voucherId,
              index + 1,
              sku,
              item.metal.displayName,
              item.description,
              item.segmentLabel.trim(),
              item.grossWeight,
              item.lessWeight,
              item.netWeight,
              item.purity,
              item.fineWeight,
              item.rate,
              item.quantity,
              item.lineAmount,
              createdAtMs,
            ],
          );
          final purchaseVoucherItemId = await _lastInsertRowId();

          final stockItemId = await _db.into(_db.stockItems).insert(
                StockItemsCompanion(
                  sku: drift.Value(sku),
                  itemName: drift.Value(
                    item.description.isNotEmpty
                        ? item.description
                        : '${item.subCategory} Purchase Item',
                  ),
                  description: drift.Value(
                    _buildStockDescription(
                      voucherNo: draft.voucherNo,
                      partyName: draft.party.name,
                      segmentLabel: item.segmentLabel,
                      purityLabel: item.purityLabel.isEmpty
                          ? _purityLabel(item)
                          : item.purityLabel,
                      labourCharge: item.labourCharge,
                      labourType: item.labourType,
                    ),
                  ),
                  category: drift.Value(_categoryLabel(item.metal)),
                  subCategory: drift.Value(
                    item.subCategory.isEmpty
                        ? 'Purchase Inward'
                        : item.subCategory,
                  ),
                  metalType: drift.Value(item.metal.displayName),
                  purity: drift.Value(
                    item.purityLabel.isEmpty
                        ? _purityLabel(item)
                        : item.purityLabel,
                  ),
                  grossWeight: drift.Value(item.grossWeight),
                  stoneWeight: drift.Value(item.lessWeight),
                  netWeight: drift.Value(item.netWeight),
                  purchaseRate: drift.Value(
                    item.effectiveRatePerGram > 0
                        ? item.effectiveRatePerGram
                        : item.rate,
                  ),
                  makingCharge: drift.Value(item.labourCharge),
                  makingChargeType: drift.Value(item.labourType.label),
                  purchasePrice: drift.Value(
                    item.lineAmount / (item.quantity > 0 ? item.quantity : 1),
                  ),
                  mrp: drift.Value(
                    item.lineAmount / (item.quantity > 0 ? item.quantity : 1),
                  ),
                  huid: drift.Value(_primaryHuid(item)),
                  hsnCode: drift.Value(
                    item.hsnCode?.trim().isEmpty ?? true ? null : item.hsnCode,
                  ),
                  supplierId: drift.Value(
                    isSupplierPurchase ? draft.party.supplierId : null,
                  ),
                  supplierName: drift.Value(
                    isSupplierPurchase ? draft.party.name : null,
                  ),
                  quantity: drift.Value(item.quantity > 0 ? item.quantity : 1),
                  status: drift.Value(StockStatus.available.label),
                  gstRate: drift.Value(item.gstRate),
                ),
              );
          await _insertPurchaseItemHuids(
            voucherId: voucherId,
            purchaseVoucherItemId: purchaseVoucherItemId,
            stockItemId: stockItemId,
            lineNo: index + 1,
            item: item,
            createdAtMs: createdAtMs,
          );
          await _insertStockMovement(
            stockItemId: stockItemId,
            movementType: 'IN',
            sourceType: 'PURCHASE',
            sourceId: voucherId.toString(),
            sourceLineNo: index + 1,
            sourceNumber: draft.voucherNo,
            skuSnapshot: sku,
            metalTypeSnapshot: item.metal.displayName,
            itemNameSnapshot: item.description.isNotEmpty
                ? item.description
                : '${item.subCategory} Purchase Item',
            quantityDelta: item.quantity > 0 ? item.quantity : 1,
            grossWeightDelta:
                item.grossWeight * (item.quantity > 0 ? item.quantity : 1),
            netWeightDelta:
                item.netWeight * (item.quantity > 0 ? item.quantity : 1),
            fineWeightDelta:
                item.fineWeight * (item.quantity > 0 ? item.quantity : 1),
            reason: 'Purchase stock inward',
            occurredAt: now,
          );
          stockEntryCount++;
        }

        if (draft.cashPaid > 0) {
          await _insertCashExpense(
            amount: draft.cashPaid,
            paymentMode: PaymentMode.cash,
            voucherNo: draft.voucherNo,
            partyName: draft.party.name,
            txnDate: now,
          );
        }

        final bankAccountId = await _findPreferredBankAccountId();
        if (draft.bankPaid > 0) {
          if (bankAccountId != null) {
            await _insertBankExpense(
              accountId: bankAccountId,
              amount: draft.bankPaid,
              paymentMode: BankPaymentMode.neft,
              voucherNo: draft.voucherNo,
              partyName: draft.party.name,
              txnDate: now,
            );
          } else {
            await _insertCashExpense(
              amount: draft.bankPaid,
              paymentMode: PaymentMode.bank,
              voucherNo: draft.voucherNo,
              partyName: draft.party.name,
              txnDate: now,
            );
          }
        }

        if (draft.upiPaid > 0) {
          if (bankAccountId != null) {
            await _insertBankExpense(
              accountId: bankAccountId,
              amount: draft.upiPaid,
              paymentMode: BankPaymentMode.upi,
              voucherNo: draft.voucherNo,
              partyName: draft.party.name,
              txnDate: now,
            );
          } else {
            await _insertCashExpense(
              amount: draft.upiPaid,
              paymentMode: PaymentMode.upi,
              voucherNo: draft.voucherNo,
              partyName: draft.party.name,
              txnDate: now,
            );
          }
        }

        if (draft.cardPaid > 0) {
          if (bankAccountId != null) {
            await _insertBankExpense(
              accountId: bankAccountId,
              amount: draft.cardPaid,
              paymentMode: BankPaymentMode.card,
              voucherNo: draft.voucherNo,
              partyName: draft.party.name,
              txnDate: now,
            );
          } else {
            await _insertCashExpense(
              amount: draft.cardPaid,
              paymentMode: PaymentMode.card,
              voucherNo: draft.voucherNo,
              partyName: draft.party.name,
              txnDate: now,
            );
          }
        }

        await _db.customStatement(
          'UPDATE purchase_vouchers SET stock_entry_count = ?, updated_at = ? WHERE id = ?',
          [stockEntryCount, createdAtMs, voucherId],
        );

        return PurchaseSaveResult(
          voucherId: voucherId,
          voucherNo: draft.voucherNo,
          stockEntryCount: stockEntryCount,
        );
      });
    } catch (error) {
      _lastErrorMessage = error.toString();
      AppLogger.debug('PurchaseEntryRepository.savePurchase: $error');
      return null;
    }
  }

  Future<void> _ensurePurchaseSchemaCompatibility() async {
    await _ensureTableColumns(
      'stock_items',
      const {
        'description': 'TEXT',
        'category': "TEXT NOT NULL DEFAULT ''",
        'sub_category': "TEXT NOT NULL DEFAULT 'Purchase Inward'",
        'metal_type': "TEXT NOT NULL DEFAULT 'Gold'",
        'purity': 'TEXT',
        'gross_weight': 'REAL NOT NULL DEFAULT 0.0',
        'stone_weight': 'REAL NOT NULL DEFAULT 0.0',
        'net_weight': 'REAL NOT NULL DEFAULT 0.0',
        'wastage': 'REAL NOT NULL DEFAULT 0.0',
        'stone_type': "TEXT NOT NULL DEFAULT 'None'",
        'stone_carats': 'REAL NOT NULL DEFAULT 0.0',
        'stone_pieces': 'INTEGER NOT NULL DEFAULT 0',
        'stone_value': 'REAL NOT NULL DEFAULT 0.0',
        'making_charge': 'REAL NOT NULL DEFAULT 0.0',
        'making_charge_type': "TEXT NOT NULL DEFAULT 'Per Gram (Rs/g)'",
        'purchase_rate': 'REAL NOT NULL DEFAULT 0.0',
        'purchase_price': 'REAL NOT NULL DEFAULT 0.0',
        'mrp': 'REAL NOT NULL DEFAULT 0.0',
        'hsn_code': 'TEXT',
        'huid': 'TEXT',
        'gst_rate': 'REAL NOT NULL DEFAULT 3.0',
        'quantity': 'INTEGER NOT NULL DEFAULT 1',
        'location': 'TEXT',
        'supplier_id': 'INTEGER',
        'supplier_name': 'TEXT',
        'status': "TEXT NOT NULL DEFAULT 'Available'",
        'is_active': 'INTEGER NOT NULL DEFAULT 1',
        'image_path': 'TEXT',
      },
    );
    await _ensureTableColumns(
      'purchase_vouchers',
      const {
        'supplier_invoice_no': 'TEXT',
        'upi_paid': 'REAL NOT NULL DEFAULT 0.0',
        'rate_per_kg': 'REAL NOT NULL DEFAULT 0.0',
        'metal_paid_gross_weight': 'REAL NOT NULL DEFAULT 0.0',
        'metal_paid_purity': 'REAL NOT NULL DEFAULT 0.0',
        'metal_paid_fine': 'REAL NOT NULL DEFAULT 0.0',
        'metal_paid_value': 'REAL NOT NULL DEFAULT 0.0',
        'due_mode': 'TEXT',
        'excess_mode': 'TEXT',
        'promise_date': 'INTEGER',
        'payment_meta': 'TEXT',
      },
    );
    await _ensureTableColumns(
      'purchase_voucher_items',
      const {
        'quantity': 'INTEGER NOT NULL DEFAULT 1',
        'item_segment': 'TEXT',
      },
    );
    await _db.customStatement('''
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
    ''');
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS "idx_purchase_item_huids_huid" ON "purchase_item_huids" ("huid")',
    );
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS "idx_purchase_item_huids_voucher" ON "purchase_item_huids" ("purchase_voucher_id")',
    );
  }

  Future<void> _insertStockMovement({
    required int stockItemId,
    required String movementType,
    required String sourceType,
    required String sourceId,
    required int? sourceLineNo,
    required String? sourceNumber,
    required String skuSnapshot,
    required String metalTypeSnapshot,
    required String itemNameSnapshot,
    required int quantityDelta,
    required double grossWeightDelta,
    required double netWeightDelta,
    required double fineWeightDelta,
    required String reason,
    required DateTime occurredAt,
  }) {
    return _db.customStatement(
      '''
      INSERT INTO stock_movements (
        stock_item_id,
        movement_type,
        source_type,
        source_id,
        source_line_no,
        source_number,
        sku_snapshot,
        metal_type_snapshot,
        item_name_snapshot,
        quantity_delta,
        gross_weight_delta,
        net_weight_delta,
        fine_weight_delta,
        reason,
        occurred_at,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        stockItemId,
        movementType,
        sourceType,
        sourceId,
        sourceLineNo,
        sourceNumber,
        skuSnapshot,
        metalTypeSnapshot,
        itemNameSnapshot,
        quantityDelta,
        grossWeightDelta,
        netWeightDelta,
        fineWeightDelta,
        reason,
        occurredAt.millisecondsSinceEpoch,
        occurredAt.millisecondsSinceEpoch,
        occurredAt.millisecondsSinceEpoch,
      ],
    );
  }

  Future<int> _lastInsertRowId() async {
    final row =
        await _db.customSelect('SELECT last_insert_rowid() AS id').getSingle();
    return row.read<int>('id');
  }

  String? _primaryHuid(PurchaseVoucherItemDraft item) {
    final values = _normalizedHuids(item);
    if (values.isNotEmpty) {
      return values.first;
    }
    final fallback = item.huid?.trim().toUpperCase();
    return fallback == null || fallback.isEmpty ? null : fallback;
  }

  List<String> _normalizedHuids(PurchaseVoucherItemDraft item) {
    final values = <String>[
      ...item.huids,
      if ((item.huid ?? '').trim().isNotEmpty) item.huid!,
    ];
    final seen = <String>{};
    return values
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty && seen.add(value))
        .toList(growable: false);
  }

  Future<void> _insertPurchaseItemHuids({
    required int voucherId,
    required int purchaseVoucherItemId,
    required int stockItemId,
    required int lineNo,
    required PurchaseVoucherItemDraft item,
    required int createdAtMs,
  }) async {
    final huids = _normalizedHuids(item);
    if (huids.isEmpty) {
      return;
    }

    for (var index = 0; index < huids.length; index++) {
      await _db.customStatement(
        '''
        INSERT INTO purchase_item_huids (
          purchase_voucher_id,
          purchase_voucher_item_id,
          stock_item_id,
          line_no,
          piece_no,
          huid,
          created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          voucherId,
          purchaseVoucherItemId,
          stockItemId,
          lineNo,
          index + 1,
          huids[index],
          createdAtMs,
        ],
      );
    }
  }

  Future<void> _ensureTableColumns(
    String tableName,
    Map<String, String> columns,
  ) async {
    final rows =
        await _db.customSelect('PRAGMA table_info("$tableName")').get();
    if (rows.isEmpty) {
      return;
    }

    final existingColumns = rows.map((row) => row.read<String>('name')).toSet();
    for (final entry in columns.entries) {
      if (existingColumns.contains(entry.key)) {
        continue;
      }
      await _db.customStatement(
        'ALTER TABLE "$tableName" ADD COLUMN "${entry.key}" ${entry.value}',
      );
    }
  }

  Future<void> _insertCashExpense({
    required double amount,
    required PaymentMode paymentMode,
    required String voucherNo,
    required String partyName,
    required DateTime txnDate,
  }) async {
    final txnId = await _generateCashTxnId();
    await _db.into(_db.cashTransactions).insert(
          CashTransactionsCompanion.insert(
            txnId: txnId,
            txnDate: txnDate,
            type: CashTransactionType.expense.dbValue,
            category: ExpenseCategory.purchasePayment.dbValue,
            amount: drift.Value(amount),
            paymentMode: drift.Value(paymentMode.dbValue),
            description: drift.Value('Purchase payout against $voucherNo'),
            referenceId: drift.Value(voucherNo),
            referenceType: const drift.Value('PURCHASE'),
            partyName: drift.Value(partyName),
            isAutoGenerated: const drift.Value(true),
            isVoided: const drift.Value(false),
          ),
        );
  }

  Future<void> _insertBankExpense({
    required int accountId,
    required double amount,
    required BankPaymentMode paymentMode,
    required String voucherNo,
    required String partyName,
    required DateTime txnDate,
  }) async {
    final txnId = await _generateBankTxnId();
    await _db.into(_db.bankTransactions).insert(
          BankTransactionsCompanion.insert(
            txnId: txnId,
            accountId: accountId,
            txnDate: txnDate,
            type: BankTransactionType.debit.dbValue,
            category: BankDebitCategory.purchasePayment.dbValue,
            amount: drift.Value(amount),
            paymentMode: drift.Value(paymentMode.dbValue),
            description: drift.Value('Purchase payout against $voucherNo'),
            referenceId: drift.Value(voucherNo),
            referenceType: const drift.Value('PURCHASE'),
            partyName: drift.Value(partyName),
            isAutoGenerated: const drift.Value(true),
            isVoided: const drift.Value(false),
          ),
        );
  }

  Future<int?> _findPreferredBankAccountId() async {
    final account = await (_db.select(_db.bankAccounts)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([
            (tbl) => drift.OrderingTerm.desc(tbl.isPrimary),
            (tbl) => drift.OrderingTerm.asc(tbl.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    return account?.id;
  }

  Future<String> _generateCashTxnId() async {
    final count = await _countRows('cash_transactions');
    final year = DateTime.now().year;
    return 'TXN-$year-${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<String> _generateBankTxnId() async {
    final count = await _countRows('bank_transactions');
    final year = DateTime.now().year;
    return 'BTXN-$year-${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<int> _countRows(String tableName) async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS total FROM $tableName')
        .getSingle();
    return row.read<int>('total');
  }

  String _buildSku(PurchaseMetalType metal, int batchTimestamp, int lineNo) {
    return 'PUR-${metal.name.toUpperCase()}-$batchTimestamp-$lineNo';
  }

  String _resolvePaymentStatus(double balanceDue, double totalPaid) {
    if (totalPaid <= 0) {
      return 'UNPAID';
    }
    if (balanceDue <= 0.005) {
      return 'PAID';
    }
    return 'PARTIAL';
  }

  String _categoryLabel(PurchaseMetalType metal) {
    switch (metal) {
      case PurchaseMetalType.gold:
        return StockCategory.gold.label;
      case PurchaseMetalType.silver:
        return StockCategory.silver.label;
      case PurchaseMetalType.platinum:
        return StockCategory.platinum.label;
      case PurchaseMetalType.diamond:
        return StockCategory.diamond.label;
    }
  }

  String _purityLabel(PurchaseVoucherItemDraft item) {
    if (item.purity <= 0) {
      return '';
    }
    return item.purity == item.purity.roundToDouble()
        ? item.purity.round().toString()
        : item.purity.toStringAsFixed(2);
  }

  String _buildStockDescription({
    required String voucherNo,
    required String partyName,
    required String segmentLabel,
    required String purityLabel,
    required double labourCharge,
    required MakingChargesType labourType,
  }) {
    final parts = <String>[
      'Purchased via $voucherNo from $partyName',
      if (segmentLabel.trim().isNotEmpty) 'Segment ${segmentLabel.trim()}',
      if (purityLabel.isNotEmpty) purityLabel,
      if (labourCharge > 0)
        'Labour ${labourType.label}: ${labourCharge.toStringAsFixed(2)}',
    ];
    return parts.join(' • ');
  }
}
