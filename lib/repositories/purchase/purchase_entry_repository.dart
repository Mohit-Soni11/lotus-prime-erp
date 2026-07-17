import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/finance/bank_book/bank_book_enums.dart';
import '../../models/finance/cash_book/cash_book_enums.dart';
import '../../models/purchase/purchase_enums/purchase_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

enum PurchaseStockTrackingMode { unit, lot }

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
  final String companyLabel;
  final String segmentLabel;
  final int quantity;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double purity;
  final double fineWeight;
  final double wastageFineWeight;
  final double valuationFineWeight;
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
  final String quantityMode;
  final int packetCount;
  final int piecesPerPacket;
  final PurchaseStockTrackingMode stockTrackingMode;
  final bool weightsAreLineTotals;

  const PurchaseVoucherItemDraft({
    required this.metal,
    required this.description,
    this.companyLabel = '',
    this.segmentLabel = '',
    this.quantity = 1,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.purity,
    required this.fineWeight,
    this.wastageFineWeight = 0.0,
    this.valuationFineWeight = 0.0,
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
    this.quantityMode = 'PIECES',
    this.packetCount = 0,
    this.piecesPerPacket = 1,
    this.stockTrackingMode = PurchaseStockTrackingMode.unit,
    this.weightsAreLineTotals = false,
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
  final int stockUnitCount;
  final int huidCount;

  const PurchaseSaveResult({
    required this.voucherId,
    required this.voucherNo,
    required this.stockEntryCount,
    this.stockUnitCount = 0,
    this.huidCount = 0,
  });
}

class PurchasePostingException implements Exception {
  final String message;

  const PurchasePostingException(this.message);

  @override
  String toString() => message;
}

class _PostingVerificationResult {
  final int stockUnitCount;
  final int huidCount;

  const _PostingVerificationResult({
    required this.stockUnitCount,
    required this.huidCount,
  });
}

class PurchaseEntryRepository {
  final AppDatabase _db;
  String? _lastErrorMessage;

  PurchaseEntryRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  String? get lastErrorMessage => _lastErrorMessage;

  String _formatSaveError(Object error) {
    if (error is PurchasePostingException) {
      return error.message;
    }

    final detail = error.toString();
    final lower = detail.toLowerCase();
    if (lower.contains('unique constraint') ||
        lower.contains('constraint failed')) {
      return 'This purchase could not be saved because a duplicate voucher, unit code or HUID already exists.';
    }
    return detail;
  }

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
        _assertDraftCanBePosted(draft);
        await _assertVoucherNoAvailable(draft.voucherNo);
        await _assertHuidsAvailable(_draftHuids(draft));

        final now = DateTime.now();
        final createdAtMs = now.millisecondsSinceEpoch;
        final isSupplierPurchase = draft.source == PurchaseSource.fromSupplier;
        final paymentStatus = _resolvePaymentStatus(
          draft.balanceDue,
          draft.totalPaid,
          draft.dueMode,
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
              item_company,
              item_segment,
              gross_weight,
              less_weight,
              net_weight,
              purity,
              fine_weight,
              wastage_fine_weight,
              valuation_fine_weight,
              rate,
              quantity,
              quantity_mode,
              packet_count,
              pieces_per_packet,
              line_amount,
              created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              voucherId,
              index + 1,
              sku,
              item.metal.displayName,
              item.description,
              item.companyLabel.trim(),
              item.segmentLabel.trim(),
              item.grossWeight,
              item.lessWeight,
              item.netWeight,
              item.purity,
              item.fineWeight,
              item.wastageFineWeight,
              item.valuationFineWeight > 0
                  ? item.valuationFineWeight
                  : item.fineWeight + item.wastageFineWeight,
              item.rate,
              item.quantity,
              item.quantityMode,
              item.packetCount,
              item.piecesPerPacket,
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
                      companyLabel: item.companyLabel,
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
          await _db.customUpdate(
            '''
            UPDATE stock_items
            SET company_name = ?,
                quantity_mode = ?,
                packet_count = ?,
                pieces_per_packet = ?
            WHERE id = ?
            ''',
            variables: [
              drift.Variable.withString(item.companyLabel.trim()),
              drift.Variable.withString(item.quantityMode),
              drift.Variable.withInt(item.packetCount),
              drift.Variable.withInt(item.piecesPerPacket),
              drift.Variable.withInt(stockItemId),
            ],
          );
          await _insertPurchaseItemHuids(
            voucherId: voucherId,
            purchaseVoucherItemId: purchaseVoucherItemId,
            stockItemId: stockItemId,
            lineNo: index + 1,
            item: item,
            createdAtMs: createdAtMs,
          );
          await _insertStockItemUnits(
            voucherId: voucherId,
            voucherNo: draft.voucherNo,
            purchaseVoucherItemId: purchaseVoucherItemId,
            stockItemId: stockItemId,
            lineNo: index + 1,
            sku: sku,
            item: item,
            supplierId: isSupplierPurchase ? draft.party.supplierId : null,
            supplierName: isSupplierPurchase ? draft.party.name : null,
            createdAtMs: createdAtMs,
          );
          final stockQuantity = item.quantity > 0 ? item.quantity : 1;
          final movementWeightMultiplier = item.weightsAreLineTotals ||
                  item.stockTrackingMode == PurchaseStockTrackingMode.lot
              ? 1
              : stockQuantity;
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
            quantityDelta: stockQuantity,
            grossWeightDelta: item.grossWeight * movementWeightMultiplier,
            netWeightDelta: item.netWeight * movementWeightMultiplier,
            fineWeightDelta: item.fineWeight * movementWeightMultiplier,
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

        final verification = await _verifyPurchasePosting(
          voucherId: voucherId,
          draft: draft,
          stockEntryCount: stockEntryCount,
        );

        return PurchaseSaveResult(
          voucherId: voucherId,
          voucherNo: draft.voucherNo,
          stockEntryCount: stockEntryCount,
          stockUnitCount: verification.stockUnitCount,
          huidCount: verification.huidCount,
        );
      });
    } catch (error) {
      _lastErrorMessage = _formatSaveError(error);
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
        'quantity_mode': "TEXT NOT NULL DEFAULT 'PIECES'",
        'packet_count': 'INTEGER NOT NULL DEFAULT 0',
        'pieces_per_packet': 'INTEGER NOT NULL DEFAULT 1',
        'company_name': 'TEXT',
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
        'discount_type': "TEXT NOT NULL DEFAULT 'FLAT'",
        'discount_value': 'REAL NOT NULL DEFAULT 0.0',
        'discount_amount': 'REAL NOT NULL DEFAULT 0.0',
        'gross_amount': 'REAL NOT NULL DEFAULT 0.0',
        'taxable_amount': 'REAL NOT NULL DEFAULT 0.0',
        'gst_amount': 'REAL NOT NULL DEFAULT 0.0',
        'cgst_amount': 'REAL NOT NULL DEFAULT 0.0',
        'sgst_amount': 'REAL NOT NULL DEFAULT 0.0',
        'grand_total': 'REAL NOT NULL DEFAULT 0.0',
        'cash_paid': 'REAL NOT NULL DEFAULT 0.0',
        'upi_paid': 'REAL NOT NULL DEFAULT 0.0',
        'bank_paid': 'REAL NOT NULL DEFAULT 0.0',
        'card_paid': 'REAL NOT NULL DEFAULT 0.0',
        'total_paid': 'REAL NOT NULL DEFAULT 0.0',
        'balance_due': 'REAL NOT NULL DEFAULT 0.0',
        'rate_per_kg': 'REAL NOT NULL DEFAULT 0.0',
        'metal_paid_gross_weight': 'REAL NOT NULL DEFAULT 0.0',
        'metal_paid_purity': 'REAL NOT NULL DEFAULT 0.0',
        'metal_paid_fine': 'REAL NOT NULL DEFAULT 0.0',
        'metal_paid_value': 'REAL NOT NULL DEFAULT 0.0',
        'due_mode': 'TEXT',
        'excess_mode': 'TEXT',
        'promise_date': 'INTEGER',
        'payment_meta': 'TEXT',
        'payment_status': "TEXT NOT NULL DEFAULT 'UNPAID'",
        'stock_entry_count': 'INTEGER NOT NULL DEFAULT 0',
        'status': "TEXT NOT NULL DEFAULT 'SAVED'",
      },
    );
    await _ensureTableColumns(
      'purchase_voucher_items',
      const {
        'quantity': 'INTEGER NOT NULL DEFAULT 1',
        'quantity_mode': "TEXT NOT NULL DEFAULT 'PIECES'",
        'packet_count': 'INTEGER NOT NULL DEFAULT 0',
        'pieces_per_packet': 'INTEGER NOT NULL DEFAULT 1',
        'item_company': 'TEXT',
        'item_segment': 'TEXT',
        'wastage_fine_weight': 'REAL NOT NULL DEFAULT 0.0',
        'valuation_fine_weight': 'REAL NOT NULL DEFAULT 0.0',
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
    await _db.customStatement(_createStockItemUnitsTableSql);
    await _ensureTableColumns(
      'stock_item_units',
      const {
        'company_name': 'TEXT',
      },
    );
    for (final statement in _stockItemUnitsIndexSql) {
      await _db.customStatement(statement);
    }
    await _createUniqueHuidIndexWhenClean(
      tableName: 'purchase_item_huids',
      indexName: 'uq_purchase_item_huids_huid',
    );
    await _createUniqueHuidIndexWhenClean(
      tableName: 'stock_item_units',
      indexName: 'uq_stock_item_units_huid',
    );
  }

  void _assertDraftCanBePosted(PurchaseVoucherDraft draft) {
    if (draft.voucherNo.trim().isEmpty) {
      throw const PurchasePostingException('Voucher number is required.');
    }
    if (draft.items.isEmpty) {
      throw const PurchasePostingException(
        'At least one purchase item is required before saving.',
      );
    }

    final seenHuids = <String>{};
    for (var index = 0; index < draft.items.length; index++) {
      final item = draft.items[index];
      final rowNo = index + 1;
      final quantity = item.quantity > 0 ? item.quantity : 1;
      final huids = _normalizedHuids(item);

      if (item.description.trim().isEmpty) {
        throw PurchasePostingException('Row $rowNo item name is required.');
      }
      if (quantity < 1) {
        throw PurchasePostingException('Row $rowNo quantity must be valid.');
      }
      if (huids.length > quantity) {
        throw PurchasePostingException(
          'Row $rowNo has more HUID numbers than pieces.',
        );
      }

      for (final huid in huids) {
        if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(huid)) {
          throw PurchasePostingException(
            'Row $rowNo HUID must be exactly 6 letters or digits.',
          );
        }
        if (!seenHuids.add(huid)) {
          throw PurchasePostingException(
            'HUID $huid is repeated in this batch.',
          );
        }
      }
    }
  }

  Future<void> _assertVoucherNoAvailable(String voucherNo) async {
    final normalized = voucherNo.trim();
    if (normalized.isEmpty) {
      return;
    }

    final rows = await _db.customSelect(
      '''
      SELECT 1
      FROM purchase_vouchers
      WHERE UPPER(TRIM(voucher_no)) = UPPER(TRIM(?))
      LIMIT 1
      ''',
      variables: [drift.Variable.withString(normalized)],
    ).get();
    if (rows.isNotEmpty) {
      throw PurchasePostingException(
        'Purchase voucher $normalized is already posted. Start a new batch before saving again.',
      );
    }
  }

  Future<void> _assertHuidsAvailable(List<String> huids) async {
    if (huids.isEmpty) {
      return;
    }

    final placeholders = List.filled(huids.length, '?').join(', ');
    final variables = huids.map(drift.Variable.withString).toList();
    final existingRows = await _db.customSelect(
      '''
      SELECT huid
      FROM stock_items
      WHERE huid IS NOT NULL
        AND UPPER(TRIM(huid)) IN ($placeholders)
      LIMIT 1
      ''',
      variables: variables,
    ).get();
    if (existingRows.isNotEmpty) {
      final huid =
          existingRows.first.readNullable<String>('huid') ?? huids.first;
      throw PurchasePostingException('HUID already exists in stock ($huid).');
    }

    final unitRows = await _db.customSelect(
      '''
      SELECT huid
      FROM stock_item_units
      WHERE huid IS NOT NULL
        AND UPPER(TRIM(huid)) IN ($placeholders)
      LIMIT 1
      ''',
      variables: variables,
    ).get();
    if (unitRows.isNotEmpty) {
      final huid = unitRows.first.readNullable<String>('huid') ?? huids.first;
      throw PurchasePostingException('HUID already exists in stock ($huid).');
    }

    final purchaseHuidRows = await _db.customSelect(
      '''
      SELECT huid
      FROM purchase_item_huids
      WHERE huid IS NOT NULL
        AND UPPER(TRIM(huid)) IN ($placeholders)
      LIMIT 1
      ''',
      variables: variables,
    ).get();
    if (purchaseHuidRows.isNotEmpty) {
      final huid =
          purchaseHuidRows.first.readNullable<String>('huid') ?? huids.first;
      throw PurchasePostingException(
        'HUID already exists in purchase history ($huid).',
      );
    }
  }

  Future<_PostingVerificationResult> _verifyPurchasePosting({
    required int voucherId,
    required PurchaseVoucherDraft draft,
    required int stockEntryCount,
  }) async {
    final expectedLines = draft.items.length;
    final expectedUnits = draft.items.fold<int>(
      0,
      (sum, item) => sum + (item.quantity > 0 ? item.quantity : 1),
    );
    final expectedHuids = _draftHuids(draft).length;
    final voucherIdValue = drift.Variable.withInt(voucherId);

    final voucherRow = await _db.customSelect(
      '''
      SELECT stock_entry_count
      FROM purchase_vouchers
      WHERE id = ?
      LIMIT 1
      ''',
      variables: [voucherIdValue],
    ).getSingleOrNull();
    final savedStockEntryCount =
        voucherRow?.readNullable<int>('stock_entry_count') ?? -1;

    final purchaseLines = await _countInt(
      '''
      SELECT COUNT(*) AS total
      FROM purchase_voucher_items
      WHERE purchase_voucher_id = ?
      ''',
      [voucherIdValue],
    );
    final stockUnits = await _countInt(
      '''
      SELECT COUNT(*) AS total
      FROM stock_item_units
      WHERE purchase_voucher_id = ?
      ''',
      [voucherIdValue],
    );
    final huidCount = await _countInt(
      '''
      SELECT COUNT(*) AS total
      FROM purchase_item_huids
      WHERE purchase_voucher_id = ?
      ''',
      [voucherIdValue],
    );
    final movementRows = await _countInt(
      '''
      SELECT COUNT(*) AS total
      FROM stock_movements
      WHERE source_type = 'PURCHASE'
        AND source_id = ?
      ''',
      [drift.Variable.withString(voucherId.toString())],
    );
    final movementQuantity = await _countInt(
      '''
      SELECT COALESCE(SUM(quantity_delta), 0) AS total
      FROM stock_movements
      WHERE source_type = 'PURCHASE'
        AND source_id = ?
      ''',
      [drift.Variable.withString(voucherId.toString())],
    );

    if (savedStockEntryCount != stockEntryCount ||
        stockEntryCount != expectedLines ||
        purchaseLines != expectedLines ||
        stockUnits != expectedUnits ||
        huidCount != expectedHuids ||
        movementRows != expectedLines ||
        movementQuantity != expectedUnits) {
      throw const PurchasePostingException(
        'Purchase posting verification failed. No stock was posted. Please save again.',
      );
    }

    return _PostingVerificationResult(
      stockUnitCount: stockUnits,
      huidCount: huidCount,
    );
  }

  Future<int> _countInt(
    String sql,
    List<drift.Variable<Object>> variables,
  ) async {
    final row = await _db.customSelect(sql, variables: variables).getSingle();
    return row.read<int>('total');
  }

  Future<void> _createUniqueHuidIndexWhenClean({
    required String tableName,
    required String indexName,
  }) async {
    try {
      final duplicates = await _db.customSelect(
        '''
        SELECT UPPER(TRIM(huid)) AS huid_key, COUNT(*) AS total
        FROM "$tableName"
        WHERE huid IS NOT NULL AND TRIM(huid) <> ''
        GROUP BY UPPER(TRIM(huid))
        HAVING COUNT(*) > 1
        LIMIT 1
        ''',
      ).get();
      if (duplicates.isNotEmpty) {
        return;
      }
      await _db.customStatement(
        '''
        CREATE UNIQUE INDEX IF NOT EXISTS "$indexName"
        ON "$tableName" (UPPER(TRIM("huid")))
        WHERE "huid" IS NOT NULL AND TRIM("huid") <> ''
        ''',
      );
    } catch (error) {
      AppLogger.debug(
        'PurchaseEntryRepository._createUniqueHuidIndexWhenClean: $error',
      );
    }
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

  List<String> _draftHuids(PurchaseVoucherDraft draft) {
    final seen = <String>{};
    return draft.items
        .expand(_normalizedHuids)
        .where((huid) => seen.add(huid))
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

  Future<void> _insertStockItemUnits({
    required int voucherId,
    required String voucherNo,
    required int purchaseVoucherItemId,
    required int stockItemId,
    required int lineNo,
    required String sku,
    required PurchaseVoucherItemDraft item,
    required int? supplierId,
    required String? supplierName,
    required int createdAtMs,
  }) async {
    final quantity = item.quantity > 0 ? item.quantity : 1;
    final huids = _normalizedHuids(item);
    if (item.stockTrackingMode == PurchaseStockTrackingMode.lot &&
        huids.isEmpty) {
      await _insertStockLotUnit(
        voucherId: voucherId,
        voucherNo: voucherNo,
        purchaseVoucherItemId: purchaseVoucherItemId,
        stockItemId: stockItemId,
        lineNo: lineNo,
        sku: sku,
        item: item,
        supplierId: supplierId,
        supplierName: supplierName,
        createdAtMs: createdAtMs,
      );
      return;
    }
    final unitCost = item.lineAmount / quantity;
    final unitMaking = item.labourType == MakingChargesType.flat
        ? item.labourCharge / quantity
        : item.labourCharge;
    final valuationFine = item.valuationFineWeight > 0
        ? item.valuationFineWeight
        : item.fineWeight + item.wastageFineWeight;
    final unitGrossWeight = item.weightsAreLineTotals
        ? _divideForStockUnit(item.grossWeight, quantity)
        : item.grossWeight;
    final unitLessWeight = item.weightsAreLineTotals
        ? _divideForStockUnit(item.lessWeight, quantity)
        : item.lessWeight;
    final unitNetWeight = item.weightsAreLineTotals
        ? _divideForStockUnit(item.netWeight, quantity)
        : item.netWeight;
    final unitFineWeight = item.weightsAreLineTotals
        ? _divideForStockUnit(item.fineWeight, quantity)
        : item.fineWeight;
    final unitWastageFineWeight = item.weightsAreLineTotals
        ? _divideForStockUnit(item.wastageFineWeight, quantity)
        : item.wastageFineWeight;
    final unitValuationFineWeight = item.weightsAreLineTotals
        ? _divideForStockUnit(valuationFine, quantity)
        : valuationFine;

    for (var index = 0; index < quantity; index++) {
      final huid = index < huids.length ? huids[index] : null;
      await _db.customStatement(
        '''
        INSERT INTO stock_item_units (
          stock_item_id,
          purchase_voucher_id,
          purchase_voucher_item_id,
          batch_code,
          unit_code,
          piece_no,
          metal_type,
          item_type,
          company_name,
          segment,
          item_name,
          huid,
          gross_weight,
          less_weight,
          net_weight,
          purity_percent,
          actual_fine_weight,
          wastage_fine_weight,
          valuation_fine_weight,
          rate_per_gram,
          making_amount,
          unit_cost,
          supplier_id,
          supplier_name,
          status,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          stockItemId,
          voucherId,
          purchaseVoucherItemId,
          voucherNo,
          '$sku-U${(index + 1).toString().padLeft(3, '0')}',
          index + 1,
          item.metal.displayName,
          item.subCategory,
          item.companyLabel.trim(),
          item.segmentLabel.trim(),
          item.description.isNotEmpty
              ? item.description
              : '${item.subCategory} Purchase Item',
          huid,
          unitGrossWeight,
          unitLessWeight,
          unitNetWeight,
          item.purity,
          unitFineWeight,
          unitWastageFineWeight,
          unitValuationFineWeight,
          item.effectiveRatePerGram > 0 ? item.effectiveRatePerGram : item.rate,
          unitMaking,
          unitCost,
          supplierId,
          supplierName,
          StockStatus.available.label,
          createdAtMs,
          createdAtMs,
        ],
      );
    }
  }

  Future<void> _insertStockLotUnit({
    required int voucherId,
    required String voucherNo,
    required int purchaseVoucherItemId,
    required int stockItemId,
    required int lineNo,
    required String sku,
    required PurchaseVoucherItemDraft item,
    required int? supplierId,
    required String? supplierName,
    required int createdAtMs,
  }) async {
    final valuationFine = item.valuationFineWeight > 0
        ? item.valuationFineWeight
        : item.fineWeight + item.wastageFineWeight;
    await _db.customStatement(
      '''
      INSERT INTO stock_item_units (
        stock_item_id,
        purchase_voucher_id,
        purchase_voucher_item_id,
        batch_code,
        unit_code,
        piece_no,
        metal_type,
        item_type,
        company_name,
        segment,
        item_name,
        huid,
        gross_weight,
        less_weight,
        net_weight,
        purity_percent,
        actual_fine_weight,
        wastage_fine_weight,
        valuation_fine_weight,
        rate_per_gram,
        making_amount,
        unit_cost,
        supplier_id,
        supplier_name,
        status,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        stockItemId,
        voucherId,
        purchaseVoucherItemId,
        voucherNo,
        '$sku-LOT001',
        lineNo,
        item.metal.displayName,
        item.subCategory,
        item.companyLabel.trim(),
        item.segmentLabel.trim(),
        item.description.isNotEmpty
            ? item.description
            : '${item.subCategory} Purchase Item',
        null,
        item.grossWeight,
        item.lessWeight,
        item.netWeight,
        item.purity,
        item.fineWeight,
        item.wastageFineWeight,
        valuationFine,
        item.effectiveRatePerGram > 0 ? item.effectiveRatePerGram : item.rate,
        item.labourCharge,
        item.lineAmount,
        supplierId,
        supplierName,
        StockStatus.available.label,
        createdAtMs,
        createdAtMs,
      ],
    );
  }

  double _divideForStockUnit(double value, int quantity) {
    if (quantity <= 1) {
      return value;
    }
    return double.parse((value / quantity).toStringAsFixed(3));
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

  String _resolvePaymentStatus(
    double balanceDue,
    double totalPaid,
    String? dueMode,
  ) {
    if (totalPaid <= 0) {
      return 'UNPAID';
    }
    if (balanceDue <= 0.005 && (dueMode == null || dueMode.trim().isEmpty)) {
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
    required String companyLabel,
    required String segmentLabel,
    required String purityLabel,
    required double labourCharge,
    required MakingChargesType labourType,
  }) {
    final parts = <String>[
      'Purchased via $voucherNo from $partyName',
      if (companyLabel.trim().isNotEmpty) 'Company ${companyLabel.trim()}',
      if (segmentLabel.trim().isNotEmpty) 'Segment ${segmentLabel.trim()}',
      if (purityLabel.isNotEmpty) purityLabel,
      if (labourCharge > 0)
        'Labour ${labourType.label}: ${labourCharge.toStringAsFixed(2)}',
    ];
    return parts.join(' • ');
  }
}

const String _createStockItemUnitsTableSql = '''
CREATE TABLE IF NOT EXISTS "stock_item_units" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "stock_item_id" INTEGER NOT NULL,
  "purchase_voucher_id" INTEGER,
  "purchase_voucher_item_id" INTEGER,
  "batch_code" TEXT,
  "unit_code" TEXT NOT NULL UNIQUE,
  "piece_no" INTEGER NOT NULL,
  "metal_type" TEXT NOT NULL,
  "item_type" TEXT,
  "company_name" TEXT,
  "segment" TEXT,
  "item_name" TEXT NOT NULL,
  "huid" TEXT,
  "gross_weight" REAL NOT NULL DEFAULT 0.0,
  "less_weight" REAL NOT NULL DEFAULT 0.0,
  "net_weight" REAL NOT NULL DEFAULT 0.0,
  "purity_percent" REAL NOT NULL DEFAULT 0.0,
  "actual_fine_weight" REAL NOT NULL DEFAULT 0.0,
  "wastage_fine_weight" REAL NOT NULL DEFAULT 0.0,
  "valuation_fine_weight" REAL NOT NULL DEFAULT 0.0,
  "rate_per_gram" REAL NOT NULL DEFAULT 0.0,
  "making_amount" REAL NOT NULL DEFAULT 0.0,
  "unit_cost" REAL NOT NULL DEFAULT 0.0,
  "supplier_id" INTEGER,
  "supplier_name" TEXT,
  "status" TEXT NOT NULL DEFAULT 'Available',
  "created_at" INTEGER NOT NULL,
  "updated_at" INTEGER,
  "sold_at" INTEGER,
  FOREIGN KEY ("stock_item_id") REFERENCES "stock_items" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("purchase_voucher_id") REFERENCES "purchase_vouchers" ("id") ON DELETE SET NULL,
  FOREIGN KEY ("purchase_voucher_item_id") REFERENCES "purchase_voucher_items" ("id") ON DELETE SET NULL
)
''';

const List<String> _stockItemUnitsIndexSql = [
  'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_stock_item" ON "stock_item_units" ("stock_item_id")',
  'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_huid" ON "stock_item_units" ("huid")',
  'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_status" ON "stock_item_units" ("status")',
  'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_item_name" ON "stock_item_units" ("item_name")',
  'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_net_weight" ON "stock_item_units" ("net_weight")',
  'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_batch" ON "stock_item_units" ("batch_code")',
];
