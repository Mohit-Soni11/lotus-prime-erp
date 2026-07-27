import 'package:drift/drift.dart';
import '../../../database/db/app_database.dart';
import '../../../models/purchase/metal_inward/metal_inward_entry.dart';

class MetalInwardLedgerRepository {
  final AppDatabase _db;

  MetalInwardLedgerRepository(this._db);

  Future<List<MetalInwardEntry>> fetchMetalInwardLedger({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // We need to fetch from two sources:
    // 1. bill_old_gold_items (Trade-In from Sales)
    // 2. purchase_voucher_items where purchase_vouchers.source == 'fromCustomer'
    
    // For now, we will construct a raw SQL query or use Drift's select.
    final List<MetalInwardEntry> entries = [];
    
    // 1. Fetch Trade-In (Sales)
    final tradeInQuery = _db.select(_db.billTradeInItems).join([
      innerJoin(_db.bills, _db.bills.id.equalsExp(_db.billTradeInItems.billId)),
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.bills.customerId)),
    ]);
    
    // Filter by date if provided
    if (startDate != null && endDate != null) {
      tradeInQuery.where(
        _db.bills.billDate.isBetweenValues(startDate, endDate),
      );
    }
    
    final tradeInRows = await tradeInQuery.get();
    for (final row in tradeInRows) {
      final item = row.readTable(_db.billTradeInItems);
      final bill = row.readTable(_db.bills);
      final customer = row.readTableOrNull(_db.customers);
      
      entries.add(MetalInwardEntry(
        id: item.id,
        date: bill.billDate,
        source: 'Trade-In (Sales)',
        referenceNo: bill.billNo,
        customerName: customer?.name ?? 'Unknown Customer',
        metalType: item.metalType,
        itemDescription: item.itemDescription,
        grossWeight: item.grossWeight,
        netWeight: item.netWeight,
        purity: item.purity,
        fineWeight: item.fineWeight,
        amount: item.lineAmount,
      ));
    }
    
    // 2. Fetch Customer Metal Purchases
    // We have to use raw query because purchase_vouchers is not a drift table (it was created with raw sql).
    String purchaseSql = '''
      SELECT 
        pvi.id,
        pv.invoice_date,
        pv.voucher_no,
        c.name as customer_name,
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
    ''';
    
    final args = <Variable>[];
    
    if (startDate != null && endDate != null) {
      purchaseSql += ' AND pv.invoice_date BETWEEN ? AND ?';
      // Store milliseconds since epoch in DB usually. Need to verify format.
      // Assuming it's unix timestamp in ms.
      args.add(Variable.withInt(startDate.millisecondsSinceEpoch));
      args.add(Variable.withInt(endDate.millisecondsSinceEpoch));
    }
    
    final purchaseResult = await _db.customSelect(purchaseSql, variables: args).get();
    
    for (final row in purchaseResult) {
      entries.add(MetalInwardEntry(
        id: row.read<int>('id'),
        date: DateTime.fromMillisecondsSinceEpoch(row.read<int>('invoice_date')),
        source: 'Purchase (Customer)',
        referenceNo: row.read<String>('voucher_no'),
        customerName: row.readNullable<String>('customer_name') ?? 'Unknown Customer',
        metalType: row.read<String>('metal_type'),
        itemDescription: row.read<String>('item_description'),
        grossWeight: row.read<double>('gross_weight'),
        netWeight: row.read<double>('net_weight'),
        purity: row.read<double>('purity'),
        fineWeight: row.read<double>('fine_weight'),
        amount: row.read<double>('line_amount'),
      ));
    }
    
    // Sort by date descending
    entries.sort((a, b) => b.date.compareTo(a.date));
    
    return entries;
  }
}
