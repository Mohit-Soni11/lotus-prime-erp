part of 'customer_category_repository.dart';

extension _CustomerCategoryRelationshipQueries on CustomerCategoryRepository {
  Future<void> _loadGirvi(Map<int, _FactsBuilder> facts, int since) async {
    final singleId = facts.length == 1 ? facts.keys.single : null;
    final rows = await _db.customSelect('''
      SELECT g.customer_id, g.status, g.start_date,
        COALESCE(SUM(CASE WHEN p.payment_date >= ?
          THEN p.interest_component ELSE 0 END), 0) AS interest_received
      FROM girvi_loans g LEFT JOIN girvi_payments p ON p.girvi_id = g.id
      ${singleId == null ? '' : 'WHERE g.customer_id = ?'}
      GROUP BY g.id
    ''', variables: [
      Variable.withInt(since),
      if (singleId != null) Variable.withInt(singleId),
    ]).get();
    for (final row in rows) {
      final fact = facts[row.read<int>('customer_id')];
      if (fact == null) continue;
      fact.receivedInterest += _number(row, 'interest_received');
      if (row.read<String>('status').toUpperCase() == 'OVERDUE') {
        fact.overdueGirvi++;
      }
    }
  }

  Future<void> _loadAdvances(Map<int, _FactsBuilder> facts, int since) async {
    final singleId = facts.length == 1 ? facts.keys.single : null;
    final rows = await _db.customSelect('''
      SELECT o.customer_id,
        COUNT(DISTINCT CASE WHEN b.id IS NOT NULL THEN o.id END) AS converted,
        COUNT(DISTINCT CASE WHEN UPPER(o.status) = 'CANCELLED'
          THEN o.id END) AS cancelled
      FROM sales_orders o
      LEFT JOIN bills b ON b.source_advance_order_id = o.id
        AND UPPER(b.status) NOT IN ('CANCELLED', 'VOID')
      WHERE o.created_at >= ?
        ${singleId == null ? '' : 'AND o.customer_id = ?'}
      GROUP BY o.customer_id
    ''', variables: [
      Variable.withInt(since),
      if (singleId != null) Variable.withInt(singleId),
    ]).get();
    for (final row in rows) {
      final fact = facts[row.read<int>('customer_id')];
      if (fact == null) continue;
      fact.convertedAdvances = row.read<int>('converted');
      fact.cancelledAdvances = row.read<int>('cancelled');
    }
  }

  Future<void> _loadCustomerPurchases(
    Map<int, _FactsBuilder> facts,
    int since,
  ) async {
    final singleId = facts.length == 1 ? facts.keys.single : null;
    final rows = await _db.customSelect('''
      SELECT customer_id, COUNT(*) AS purchases FROM purchase_vouchers
      WHERE source_type = 'CUSTOMER' AND voucher_no NOT LIKE 'MELT-%'
        AND UPPER(status) NOT IN ('CANCELLED', 'VOID')
        AND created_at >= ? AND customer_id IS NOT NULL
        ${singleId == null ? '' : 'AND customer_id = ?'}
      GROUP BY customer_id
    ''', variables: [
      Variable.withInt(since * 1000),
      if (singleId != null) Variable.withInt(singleId),
    ]).get();
    for (final row in rows) {
      facts[row.read<int>('customer_id')]?.customerPurchases =
          row.read<int>('purchases');
    }
  }

  Future<void> _loadPurchasedMetalResales(
    Map<int, _FactsBuilder> facts,
    int since,
  ) async {
    final singleId = facts.length == 1 ? facts.keys.single : null;
    final rows = await _db.customSelect('''
      SELECT pv.customer_id, COUNT(DISTINCT bi.id) AS resale_count
      FROM purchase_vouchers pv
      JOIN purchase_voucher_items pvi ON pvi.purchase_voucher_id = pv.id
      JOIN stock_item_units u ON u.purchase_voucher_item_id = pvi.id
      JOIN bill_items bi ON bi.linked_stock_unit_id = u.id
      JOIN bills b ON b.id = bi.bill_id
      WHERE pv.source_type = 'CUSTOMER' AND pv.customer_id IS NOT NULL
        ${singleId == null ? '' : 'AND pv.customer_id = ?'}
        AND pv.voucher_no NOT LIKE 'MELT-%'
        AND b.bill_date >= ?
        AND UPPER(b.status) NOT IN ('CANCELLED', 'VOID',
          'RETURNED', 'PARTIALLY_RETURNED')
        AND bi.stock_unit_cost > 0
        AND (SELECT COUNT(*) FROM bill_items WHERE bill_id = b.id) = 1
        AND b.total_amount - b.discount - b.gst_amount -
          bi.stock_unit_cost > 0.005
        AND NOT EXISTS (SELECT 1 FROM return_vouchers rv
          WHERE rv.source_type = 'SALES_INVOICE' AND rv.source_id = b.id
            AND rv.status <> 'VOIDED')
      GROUP BY pv.customer_id
    ''', variables: [
      if (singleId != null) Variable.withInt(singleId),
      Variable.withInt(since),
    ]).get();
    for (final row in rows) {
      facts[row.read<int>('customer_id')]?.profitableResales =
          row.read<int>('resale_count');
    }
  }

  Future<void> _loadDueEvidence(
    Map<int, _FactsBuilder> facts,
    int since,
  ) async {
    final singleId = facts.length == 1 ? facts.keys.single : null;
    final rows = await _db.customSelect('''
      SELECT customer_id,
        SUM(CASE WHEN settled_at < original_promise_at + 86400
          THEN 1 ELSE 0 END) AS on_time,
        SUM(CASE WHEN settled_at >= original_promise_at + 86400
          THEN 1 ELSE 0 END) AS late
      FROM customer_due_settlement_evidence
      WHERE settled_at >= ? AND original_promise_at IS NOT NULL
        ${singleId == null ? '' : 'AND customer_id = ?'}
      GROUP BY customer_id
    ''', variables: [
      Variable.withInt(since),
      if (singleId != null) Variable.withInt(singleId),
    ]).get();
    for (final row in rows) {
      final fact = facts[row.read<int>('customer_id')];
      if (fact == null) continue;
      fact.onTimeSettlements = row.read<int>('on_time');
      fact.lateSettlements = row.read<int>('late');
    }
  }

  Future<void> _loadCustomerReturns(
    Map<int, _FactsBuilder> facts,
    int since,
  ) async {
    final singleId = facts.length == 1 ? facts.keys.single : null;
    final rows = await _db.customSelect('''
      SELECT customer_id, COUNT(*) AS requested_returns
      FROM return_vouchers
      WHERE source_type = 'SALES_INVOICE'
        AND status <> 'VOIDED'
        AND operator_note = 'Customer requested return'
        AND created_at >= ?
        AND customer_id IS NOT NULL
        ${singleId == null ? '' : 'AND customer_id = ?'}
      GROUP BY customer_id
    ''', variables: [
      Variable.withInt(since * 1000),
      if (singleId != null) Variable.withInt(singleId),
    ]).get();
    for (final row in rows) {
      facts[row.read<int>('customer_id')]?.customerRequestedReturns =
          row.read<int>('requested_returns');
    }
  }
}
