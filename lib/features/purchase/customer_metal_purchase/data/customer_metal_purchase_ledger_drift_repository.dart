import 'package:drift/drift.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/repositories/customer_metal_purchase_ledger_repository.dart';

class DriftCustomerMetalPurchaseLedgerRepository
    implements CustomerMetalPurchaseLedgerRepository {
  final AppDatabase _db;

  DriftCustomerMetalPurchaseLedgerRepository(this._db);

  @override
  Future<List<CustomerMetalPurchaseEntry>> fetchLedger({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _ensureReturnTable();
    final entries = <CustomerMetalPurchaseEntry>[];
    final normalizedStart = startDate == null ? null : _startOfDay(startDate);
    final normalizedEnd = endDate == null ? null : _endOfDay(endDate);

    await _appendSalesTradeInEntries(
      entries,
      startDate: normalizedStart,
      endDate: normalizedEnd,
    );
    await _appendDirectPurchaseEntries(
      entries,
      startDate: normalizedStart,
      endDate: normalizedEnd,
    );

    entries.sort((a, b) => b.date.compareTo(a.date));
    return _applyReturnStatus(entries);
  }

  @override
  Future<void> markReturned(CustomerMetalPurchaseEntry entry) async {
    await _ensureReturnTable();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.customStatement(
      '''
      INSERT OR IGNORE INTO customer_metal_purchase_returns (
        source,
        source_entry_id,
        reference_no,
        metal_type,
        customer_name,
        gross_weight,
        fine_weight,
        amount,
        reason,
        returned_at,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        entry.source,
        entry.id,
        entry.referenceNo,
        entry.metalType,
        entry.customerName,
        entry.grossWeight,
        entry.fineWeight,
        entry.amount,
        'Customer item returned',
        now,
        now,
      ],
    );
  }

  Future<void> _appendSalesTradeInEntries(
    List<CustomerMetalPurchaseEntry> entries, {
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    final query = _db.select(_db.billTradeInItems).join([
      innerJoin(_db.bills, _db.bills.id.equalsExp(_db.billTradeInItems.billId)),
      leftOuterJoin(
        _db.customers,
        _db.customers.id.equalsExp(_db.bills.customerId),
      ),
    ]);

    if (startDate != null && endDate != null) {
      query.where(_db.bills.billDate.isBetweenValues(startDate, endDate));
    }

    final rows = await query.get();
    for (final row in rows) {
      final item = row.readTable(_db.billTradeInItems);
      final bill = row.readTable(_db.bills);
      final customer = row.readTableOrNull(_db.customers);

      entries.add(
        CustomerMetalPurchaseEntry(
          id: item.id,
          date: bill.billDate,
          source: 'Sales Trade-In',
          referenceNo: bill.billNo,
          customerName:
              customer?.name ?? bill.customerName ?? 'Walk-in Customer',
          metalType: item.metalType,
          itemDescription: item.itemDescription,
          grossWeight: item.grossWeight,
          netWeight: item.netWeight,
          purity: item.purity,
          fineWeight: item.fineWeight,
          rate: item.rate,
          amount: item.lineAmount,
        ),
      );
    }
  }

  Future<void> _appendDirectPurchaseEntries(
    List<CustomerMetalPurchaseEntry> entries, {
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    var sql = '''
      SELECT
        pvi.id,
        pv.created_at,
        pv.voucher_no,
        COALESCE(c.name, pv.party_name, 'Walk-in Customer') AS customer_name,
        pvi.metal_type,
        pvi.item_description,
        pvi.gross_weight,
        pvi.net_weight,
        pvi.purity,
        pvi.fine_weight,
        pvi.rate,
        pvi.line_amount
      FROM purchase_voucher_items pvi
      INNER JOIN purchase_vouchers pv ON pvi.purchase_voucher_id = pv.id
      LEFT JOIN customers c ON pv.customer_id = c.id
      WHERE pv.source_type = 'CUSTOMER'
        AND pv.status <> 'CANCELLED'
    ''';

    final variables = <Variable>[];
    if (startDate != null && endDate != null) {
      sql += ' AND pv.created_at BETWEEN ? AND ?';
      variables.add(Variable.withInt(startDate.millisecondsSinceEpoch));
      variables.add(Variable.withInt(endDate.millisecondsSinceEpoch));
    }

    final rows = await _db.customSelect(sql, variables: variables).get();
    for (final row in rows) {
      entries.add(
        CustomerMetalPurchaseEntry(
          id: row.read<int>('id'),
          date:
              DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at')),
          source: 'Direct Purchase',
          referenceNo: row.read<String>('voucher_no'),
          customerName: row.read<String>('customer_name'),
          metalType: row.read<String>('metal_type'),
          itemDescription: row.read<String>('item_description'),
          grossWeight: row.read<double>('gross_weight'),
          netWeight: row.read<double>('net_weight'),
          purity: row.read<double>('purity'),
          fineWeight: row.read<double>('fine_weight'),
          rate: row.read<double>('rate'),
          amount: row.read<double>('line_amount'),
        ),
      );
    }
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  Future<List<CustomerMetalPurchaseEntry>> _applyReturnStatus(
    List<CustomerMetalPurchaseEntry> entries,
  ) async {
    final returnedRows = await _db.customSelect(
      '''
      SELECT source, source_entry_id, returned_at
      FROM customer_metal_purchase_returns
      ''',
    ).get();

    final returnedEntries = <String, DateTime>{};
    for (final row in returnedRows) {
      final source = row.read<String>('source');
      final entryId = row.read<int>('source_entry_id');
      final returnedAt = row.read<int>('returned_at');
      returnedEntries[_entryKey(source, entryId)] =
          DateTime.fromMillisecondsSinceEpoch(returnedAt);
    }

    return [
      for (final entry in entries)
        if (returnedEntries.containsKey(_entryKey(entry.source, entry.id)))
          entry.copyWith(
            isReturned: true,
            returnedAt: returnedEntries[_entryKey(entry.source, entry.id)],
          )
        else
          entry,
    ];
  }

  Future<void> _ensureReturnTable() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS customer_metal_purchase_returns (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        source TEXT NOT NULL,
        source_entry_id INTEGER NOT NULL,
        reference_no TEXT NOT NULL,
        metal_type TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        gross_weight REAL NOT NULL DEFAULT 0.0,
        fine_weight REAL NOT NULL DEFAULT 0.0,
        amount REAL NOT NULL DEFAULT 0.0,
        reason TEXT NOT NULL DEFAULT '',
        returned_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE(source, source_entry_id)
      )
    ''');

    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_customer_metal_purchase_returns_source
      ON customer_metal_purchase_returns (source, source_entry_id)
    ''');
  }

  String _entryKey(String source, int entryId) {
    return '${source.trim().toUpperCase()}|$entryId';
  }
}
