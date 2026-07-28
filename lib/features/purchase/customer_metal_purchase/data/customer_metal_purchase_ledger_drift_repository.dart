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
    return entries;
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
}
