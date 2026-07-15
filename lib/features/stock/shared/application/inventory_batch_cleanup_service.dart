import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';

final class InventoryBatchCleanupService {
  final AppDatabase _db;

  const InventoryBatchCleanupService(this._db);

  Future<InventoryBatchCleanupAudit> auditBatch(String batchCode) async {
    final code = batchCode.trim();
    if (code.isEmpty) {
      return InventoryBatchCleanupAudit.notFound(batchCode: batchCode);
    }

    final row = await _db.customSelect(
      '''
      SELECT
        pv.id AS voucher_id,
        pv.voucher_no AS batch_code,
        pv.party_name AS supplier_name,
        COALESCE(pv.total_paid, 0.0) AS total_paid,
        COALESCE(pv.balance_due, 0.0) AS balance_due,
        COALESCE((
          SELECT COUNT(*)
          FROM stock_item_units u
          WHERE u.purchase_voucher_id = pv.id OR u.batch_code = pv.voucher_no
        ), 0) AS total_units,
        COALESCE((
          SELECT COUNT(*)
          FROM stock_item_units u
          WHERE (u.purchase_voucher_id = pv.id OR u.batch_code = pv.voucher_no)
            AND lower(u.status) = 'available'
        ), 0) AS available_units,
        COALESCE((
          SELECT COUNT(*)
          FROM stock_item_units u
          WHERE (u.purchase_voucher_id = pv.id OR u.batch_code = pv.voucher_no)
            AND lower(u.status) <> 'available'
        ), 0) AS non_available_units,
        COALESCE((
          SELECT COUNT(DISTINCT bi.id)
          FROM bill_items bi
          WHERE bi.linked_stock_unit_id IN (
            SELECT u.id
            FROM stock_item_units u
            WHERE u.purchase_voucher_id = pv.id OR u.batch_code = pv.voucher_no
          )
          OR bi.linked_stock_item_id IN (
            SELECT DISTINCT u.stock_item_id
            FROM stock_item_units u
            WHERE u.purchase_voucher_id = pv.id OR u.batch_code = pv.voucher_no
          )
        ), 0) AS linked_sales_rows,
        COALESCE((
          SELECT COUNT(*)
          FROM stock_movements sm
          WHERE sm.source_type = 'SALE'
            AND sm.stock_item_id IN (
              SELECT DISTINCT u.stock_item_id
              FROM stock_item_units u
              WHERE u.purchase_voucher_id = pv.id OR u.batch_code = pv.voucher_no
            )
        ), 0) AS sale_movements,
        COALESCE((
          SELECT COUNT(*)
          FROM cash_transactions ct
          WHERE ct.reference_type = 'PURCHASE'
            AND ct.reference_id = pv.voucher_no
            AND ct.is_voided = 0
        ), 0) AS cash_entries,
        COALESCE((
          SELECT COUNT(*)
          FROM cash_transactions ct
          WHERE ct.reference_type = 'PURCHASE'
            AND ct.reference_id = pv.voucher_no
            AND ct.is_auto_generated = 0
            AND ct.is_voided = 0
        ), 0) AS manual_cash_entries,
        COALESCE((
          SELECT COUNT(*)
          FROM bank_transactions bt
          WHERE bt.reference_type = 'PURCHASE'
            AND bt.reference_id = pv.voucher_no
            AND bt.is_voided = 0
        ), 0) AS bank_entries,
        COALESCE((
          SELECT COUNT(*)
          FROM bank_transactions bt
          WHERE bt.reference_type = 'PURCHASE'
            AND bt.reference_id = pv.voucher_no
            AND bt.is_auto_generated = 0
            AND bt.is_voided = 0
        ), 0) AS manual_bank_entries
      FROM purchase_vouchers pv
      WHERE pv.voucher_no = ?
      LIMIT 1
      ''',
      variables: [drift.Variable.withString(code)],
    ).getSingleOrNull();

    if (row == null) {
      return InventoryBatchCleanupAudit.notFound(batchCode: code);
    }

    final audit = InventoryBatchCleanupAudit(
      batchCode: _text(row, 'batch_code', code),
      supplierName: _text(row, 'supplier_name', ''),
      voucherId: _int(row, 'voucher_id'),
      totalUnits: _int(row, 'total_units'),
      availableUnits: _int(row, 'available_units'),
      nonAvailableUnits: _int(row, 'non_available_units'),
      linkedSalesRows: _int(row, 'linked_sales_rows'),
      saleMovements: _int(row, 'sale_movements'),
      cashEntries: _int(row, 'cash_entries'),
      bankEntries: _int(row, 'bank_entries'),
      manualCashEntries: _int(row, 'manual_cash_entries'),
      manualBankEntries: _int(row, 'manual_bank_entries'),
      totalPaid: _double(row, 'total_paid'),
      balanceDue: _double(row, 'balance_due'),
      exists: true,
    );

    return audit.copyWith(blockers: _blockersFor(audit));
  }

  Future<InventoryBatchCleanupResult> deleteSafeTestBatch(
    String batchCode, {
    bool voidLinkedFinance = true,
  }) async {
    final audit = await auditBatch(batchCode);
    if (!audit.canDelete) {
      throw StateError(audit.blockReason);
    }

    return _db.transaction(() async {
      final voucherId = audit.voucherId;
      final voucherIdText = voucherId.toString();
      final now = DateTime.now().millisecondsSinceEpoch;

      if (voidLinkedFinance) {
        await _db.customStatement(
          '''
          UPDATE cash_transactions
          SET is_voided = 1, void_reason = ?, updated_at = ?
          WHERE reference_type = 'PURCHASE'
            AND reference_id = ?
            AND is_auto_generated = 1
            AND is_voided = 0
          ''',
          [
            'Voided with safe inventory test batch cleanup',
            now,
            audit.batchCode,
          ],
        );
        await _db.customStatement(
          '''
          UPDATE bank_transactions
          SET is_voided = 1, void_reason = ?, updated_at = ?
          WHERE reference_type = 'PURCHASE'
            AND reference_id = ?
            AND is_auto_generated = 1
            AND is_voided = 0
          ''',
          [
            'Voided with safe inventory test batch cleanup',
            now,
            audit.batchCode,
          ],
        );
      }

      await _db.customStatement(
        '''
        DELETE FROM stock_movements
        WHERE source_type = 'PURCHASE'
          AND source_id = ?
        ''',
        [voucherIdText],
      );

      await _db.customStatement(
        '''
        DELETE FROM stock_items
        WHERE id IN (
          SELECT DISTINCT stock_item_id
          FROM stock_item_units
          WHERE purchase_voucher_id = ? OR batch_code = ?
        )
        ''',
        [voucherId, audit.batchCode],
      );

      await _db.customStatement(
        '''
        DELETE FROM purchase_vouchers
        WHERE id = ?
        ''',
        [voucherId],
      );

      return InventoryBatchCleanupResult(
        batchCode: audit.batchCode,
        removedUnits: audit.totalUnits,
        voidedFinanceEntries:
            voidLinkedFinance ? audit.cashEntries + audit.bankEntries : 0,
      );
    });
  }

  List<String> _blockersFor(InventoryBatchCleanupAudit audit) {
    if (!audit.exists) {
      return ['Batch not found.'];
    }
    final blockers = <String>[];
    if (audit.totalUnits == 0) {
      blockers.add('No stock units are linked with this batch.');
    }
    if (audit.nonAvailableUnits > 0) {
      blockers.add('Batch has sold or reserved stock units.');
    }
    if (audit.linkedSalesRows > 0 || audit.saleMovements > 0) {
      blockers.add('Batch is linked with sales records.');
    }
    if (audit.manualCashEntries > 0 || audit.manualBankEntries > 0) {
      blockers.add('Batch has manual finance entries.');
    }
    return blockers;
  }

  static int _int(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is num ? value.toInt() : 0;
  }

  static double _double(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is num ? value.toDouble() : 0.0;
  }

  static String _text(drift.QueryRow row, String column, String fallback) {
    final value = row.data[column];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }
}

final class InventoryBatchCleanupAudit {
  final String batchCode;
  final String supplierName;
  final int voucherId;
  final int totalUnits;
  final int availableUnits;
  final int nonAvailableUnits;
  final int linkedSalesRows;
  final int saleMovements;
  final int cashEntries;
  final int bankEntries;
  final int manualCashEntries;
  final int manualBankEntries;
  final double totalPaid;
  final double balanceDue;
  final bool exists;
  final List<String> blockers;

  const InventoryBatchCleanupAudit({
    required this.batchCode,
    required this.supplierName,
    required this.voucherId,
    required this.totalUnits,
    required this.availableUnits,
    required this.nonAvailableUnits,
    required this.linkedSalesRows,
    required this.saleMovements,
    required this.cashEntries,
    required this.bankEntries,
    required this.manualCashEntries,
    required this.manualBankEntries,
    required this.totalPaid,
    required this.balanceDue,
    required this.exists,
    this.blockers = const [],
  });

  factory InventoryBatchCleanupAudit.notFound({required String batchCode}) {
    return InventoryBatchCleanupAudit(
      batchCode: batchCode,
      supplierName: '',
      voucherId: 0,
      totalUnits: 0,
      availableUnits: 0,
      nonAvailableUnits: 0,
      linkedSalesRows: 0,
      saleMovements: 0,
      cashEntries: 0,
      bankEntries: 0,
      manualCashEntries: 0,
      manualBankEntries: 0,
      totalPaid: 0,
      balanceDue: 0,
      exists: false,
      blockers: const ['Batch not found.'],
    );
  }

  bool get canDelete => exists && blockers.isEmpty;

  String get blockReason =>
      blockers.isEmpty ? 'Batch is safe to clean.' : blockers.join(' ');

  InventoryBatchCleanupAudit copyWith({List<String>? blockers}) {
    return InventoryBatchCleanupAudit(
      batchCode: batchCode,
      supplierName: supplierName,
      voucherId: voucherId,
      totalUnits: totalUnits,
      availableUnits: availableUnits,
      nonAvailableUnits: nonAvailableUnits,
      linkedSalesRows: linkedSalesRows,
      saleMovements: saleMovements,
      cashEntries: cashEntries,
      bankEntries: bankEntries,
      manualCashEntries: manualCashEntries,
      manualBankEntries: manualBankEntries,
      totalPaid: totalPaid,
      balanceDue: balanceDue,
      exists: exists,
      blockers: blockers ?? this.blockers,
    );
  }
}

final class InventoryBatchCleanupResult {
  final String batchCode;
  final int removedUnits;
  final int voidedFinanceEntries;

  const InventoryBatchCleanupResult({
    required this.batchCode,
    required this.removedUnits,
    required this.voidedFinanceEntries,
  });
}
