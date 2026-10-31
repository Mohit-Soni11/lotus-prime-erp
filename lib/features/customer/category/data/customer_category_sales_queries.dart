part of 'customer_category_repository.dart';

extension _CustomerCategorySalesQueries on CustomerCategoryRepository {
  Future<void> _loadVisits(Map<int, _FactsBuilder> facts, int since) async {
    final localOffset = DateTime.now().timeZoneOffset.inSeconds;
    final singleId = facts.length == 1 ? facts.keys.single : null;
    final rows = await _db.customSelect('''
      SELECT customer_id, COUNT(DISTINCT visit_day) AS visits FROM (
        SELECT customer_id, date(bill_date + ?, 'unixepoch') AS visit_day
          FROM bills WHERE customer_id IS NOT NULL
            AND bill_date >= ? AND UPPER(status) NOT IN ('CANCELLED', 'VOID')
        UNION ALL
        SELECT customer_id, date(start_date + ?, 'unixepoch')
          FROM girvi_loans WHERE start_date >= ?
        UNION ALL
        SELECT customer_id, date(created_at + ?, 'unixepoch')
          FROM sales_orders WHERE created_at >= ?
        UNION ALL
        SELECT customer_id, date(created_at / 1000 + ?, 'unixepoch')
          FROM purchase_vouchers WHERE source_type = 'CUSTOMER'
            AND voucher_no NOT LIKE 'MELT-%' AND created_at >= ?
      ) WHERE visit_day IS NOT NULL
        ${singleId == null ? '' : 'AND customer_id = ?'}
      GROUP BY customer_id
    ''', variables: [
      Variable.withInt(localOffset),
      Variable.withInt(since),
      Variable.withInt(localOffset),
      Variable.withInt(since),
      Variable.withInt(localOffset),
      Variable.withInt(since),
      Variable.withInt(localOffset),
      Variable.withInt(since * 1000),
      if (singleId != null) Variable.withInt(singleId),
    ]).get();
    for (final row in rows) {
      facts[row.read<int>('customer_id')]?.visits = row.read<int>('visits');
    }
  }

  Future<void> _loadSales(Map<int, _FactsBuilder> facts, int since) async {
    final singleId = facts.length == 1 ? facts.keys.single : null;
    final rows = await _db.customSelect('''
      SELECT b.customer_id, b.bill_date, b.total_amount, b.gst_amount,
        b.discount, b.final_amount, b.paid_amount, b.due_amount,
        b.payment_status, b.promise_date,
        b.status, COUNT(bi.id) AS item_count,
        SUM(CASE WHEN bi.stock_unit_cost > 0 THEN 1 ELSE 0 END)
          AS known_cost_count,
        COALESCE(SUM(bi.stock_unit_cost), 0) AS cost,
        COALESCE(MAX(bi.item_total), 0) AS max_item_total,
        EXISTS(SELECT 1 FROM return_vouchers rv
          WHERE rv.source_type = 'SALES_INVOICE' AND rv.source_id = b.id
            AND rv.status <> 'VOIDED') AS has_return
      FROM bills b LEFT JOIN bill_items bi ON bi.bill_id = b.id
      WHERE b.customer_id IS NOT NULL
        AND UPPER(b.status) NOT IN ('CANCELLED', 'VOID')
        AND (b.bill_date >= ? OR b.due_amount > 0.005
          OR b.final_amount - b.paid_amount > 0.005)
        ${singleId == null ? '' : 'AND b.customer_id = ?'}
      GROUP BY b.id
    ''', variables: [
      Variable.withInt(since),
      if (singleId != null) Variable.withInt(singleId),
    ]).get();
    final today = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (final row in rows) {
      final fact = facts[row.read<int>('customer_id')];
      if (fact == null) continue;
      final status = row.read<String>('payment_status').toUpperCase();
      final settled =
          {'PAID', 'SETTLED', 'COMPLETE', 'COMPLETED'}.contains(status);
      final recordedDue = _number(row, 'due_amount');
      final due = settled
          ? 0.0
          : recordedDue > 0.005 || {'PARTIAL', 'DUE', 'UNPAID'}.contains(status)
              ? recordedDue.clamp(0.0, double.infinity)
              : (_number(row, 'final_amount') - _number(row, 'paid_amount'))
                  .clamp(0.0, double.infinity);
      final activeDue = due > 0.005;
      if (activeDue) {
        fact.activeDues++;
        final promise = row.readNullable<int>('promise_date');
        if (promise != null && promise + 86400 <= today) {
          fact.overdueDues++;
        }
      }

      if (row.read<int>('bill_date') < since) continue;
      if (row.read<int>('has_return') != 0 ||
          {'RETURNED', 'PARTIALLY_RETURNED'}
              .contains(row.read<String>('status').toUpperCase())) {
        fact.returnedSales++;
        continue;
      }
      final itemCount = row.read<int>('item_count');
      if (itemCount == 0 || row.read<int>('known_cost_count') != itemCount) {
        fact.unverifiedSales++;
        continue;
      }
      final revenue = _number(row, 'total_amount') -
          _number(row, 'discount') -
          _number(row, 'gst_amount');
      if (revenue <= 0) {
        fact.unverifiedSales++;
        continue;
      }
      final cost = _number(row, 'cost');
      final contribution = revenue - cost;
      fact.verifiedContribution += contribution;
      fact.verifiedRevenue += revenue;
      fact.verifiedSales++;
      if (contribution < -0.005) fact.hasSalesLoss = true;
      if (itemCount == 1 &&
          _number(row, 'max_item_total') >=
              CustomerCategoryPolicy.highValueSale &&
          contribution > 0) {
        fact.hasHighValueSale = true;
      }
      final discount = _number(row, 'discount');
      final marginBeforeDiscount = contribution + discount;
      if (itemCount == 1 && discount > 0 && marginBeforeDiscount > 0) {
        if (discount <= CustomerCategoryPolicy.responsibleItemDiscount &&
            discount <= marginBeforeDiscount * 0.25) {
          fact.responsibleDiscounts++;
        } else if (discount > marginBeforeDiscount * 0.5) {
          fact.excessiveDiscounts++;
        }
      }
    }
  }

  Future<void> _loadMetalDiscounts(
    Map<int, _FactsBuilder> facts,
    int since,
  ) async {
    final singleId = facts.length == 1 ? facts.keys.single : null;
    final rows = await _db.customSelect('''
      SELECT b.customer_id, a.gross_amount, a.discount_amount, a.gst_amount,
        COUNT(bi.id) AS item_count, SUM(bi.stock_unit_cost) AS cost
      FROM bills b
      JOIN bill_metal_payment_allocations a ON a.bill_id = b.id
      JOIN bill_items bi ON bi.bill_id = b.id
        AND UPPER(bi.metal_type) = UPPER(a.metal)
      WHERE b.bill_date >= ?
        ${singleId == null ? '' : 'AND b.customer_id = ?'}
        AND UPPER(b.status) NOT IN ('CANCELLED', 'VOID',
          'RETURNED', 'PARTIALLY_RETURNED')
        AND a.discount_amount > 0
        AND (SELECT COUNT(*) FROM bill_items WHERE bill_id = b.id) > 1
        AND ABS(b.discount - (SELECT SUM(discount_amount)
          FROM bill_metal_payment_allocations WHERE bill_id = b.id)) < 0.01
        AND NOT EXISTS (SELECT 1 FROM return_vouchers rv
          WHERE rv.source_type = 'SALES_INVOICE' AND rv.source_id = b.id
            AND rv.status <> 'VOIDED')
      GROUP BY b.id, a.metal
      HAVING COUNT(bi.id) = 1 AND MIN(bi.stock_unit_cost) > 0
    ''', variables: [
      Variable.withInt(since),
      if (singleId != null) Variable.withInt(singleId),
    ]).get();
    for (final row in rows) {
      final fact = facts[row.read<int>('customer_id')];
      if (fact == null) continue;
      final discount = _number(row, 'discount_amount');
      final marginBeforeDiscount = _number(row, 'gross_amount') -
          _number(row, 'gst_amount') -
          _number(row, 'cost');
      if (marginBeforeDiscount <= 0) continue;
      if (discount <= CustomerCategoryPolicy.responsibleItemDiscount &&
          discount <= marginBeforeDiscount * 0.25) {
        fact.responsibleDiscounts++;
      } else if (discount > marginBeforeDiscount * 0.5) {
        fact.excessiveDiscounts++;
      }
    }
  }
}
