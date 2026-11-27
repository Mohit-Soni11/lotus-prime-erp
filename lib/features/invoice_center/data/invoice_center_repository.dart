import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';

import '../domain/invoice_center_models.dart';

abstract interface class InvoiceCenterRepository {
  Future<InvoiceCenterSnapshot> load(InvoiceCenterQuery query);
  Future<List<InvoiceCenterRow>> exportRows(InvoiceCenterQuery query);
}

class DriftInvoiceCenterRepository implements InvoiceCenterRepository {
  DriftInvoiceCenterRepository(this._db);

  final AppDatabase _db;

  static const _gstExpression = '''
    CASE
      WHEN UPPER(REPLACE(REPLACE(TRIM(COALESCE(b.bill_type, '')), ' ', '_'), '-', '_')) IN
        ('NORMAL', 'NON_GST', 'NON_GST_BILL', 'NON_GST_INVOICE',
         'SALES_INVOICE', 'ESTIMATE')
        OR UPPER(REPLACE(REPLACE(TRIM(COALESCE(b.tax_treatment, '')), ' ', '_'), '-', '_')) IN
          ('NON_GST', 'NON_GST_SALE', 'NO_GST', 'EXEMPT') THEN 0
      WHEN UPPER(REPLACE(REPLACE(TRIM(COALESCE(b.bill_type, '')), ' ', '_'), '-', '_')) IN
        ('GST', 'TAX', 'TAX_INVOICE')
        OR ABS(COALESCE(b.gst_amount, 0)) > 0.005
        OR ABS(COALESCE(b.cgst_amount, 0)) > 0.005
        OR ABS(COALESCE(b.sgst_amount, 0)) > 0.005
        OR ABS(COALESCE(b.igst_amount, 0)) > 0.005
        OR ABS(COALESCE(b.output_gst_liability_snapshot, 0)) > 0.005
        OR (TRIM(COALESCE(b.bill_type, '')) = ''
            AND UPPER(TRIM(COALESCE(b.tax_treatment, ''))) IN
              ('GST', 'TAXABLE_SUPPLY'))
        OR (TRIM(COALESCE(b.bill_type, '')) = ''
            AND TRIM(COALESCE(b.tax_treatment, '')) = ''
            AND UPPER(TRIM(b.bill_no)) LIKE 'TAX-%') THEN 1
      ELSE 0
    END
  ''';

  static const _dueExpression = '''
    CASE
      WHEN UPPER(TRIM(COALESCE(b.payment_status, ''))) IN
        ('PAID', 'SETTLED', 'COMPLETE', 'COMPLETED') THEN 0.0
      WHEN b.due_amount > 0.5
        OR UPPER(TRIM(COALESCE(b.payment_status, ''))) IN
          ('PARTIAL', 'DUE', 'UNPAID')
        THEN MAX(COALESCE(b.due_amount, 0.0), 0.0)
      ELSE MAX(COALESCE(b.final_amount, 0.0) -
               COALESCE(b.paid_amount, 0.0), 0.0)
    END
  ''';

  @override
  Future<InvoiceCenterSnapshot> load(InvoiceCenterQuery query) async {
    await _db.ensureReturnReversalSchema();
    final summary = await _loadSummary(query.month);
    final metals = await _loadMetals();
    final source = _sourceSql(query);
    final where = _filterSql(query);
    final sql = 'WITH documents AS (${source.sql}) '
        'SELECT COUNT(*) AS total FROM documents WHERE ${where.sql}';
    final totalRow = await _db.customSelect(
      sql,
      variables: [...source.variables, ...where.variables],
    ).getSingle();
    final totalRows = _int(totalRow, 'total');
    final rows = await _readRows(
      source,
      where,
      limit: query.pageSize,
      offset: (query.page - 1) * query.pageSize,
    );
    return InvoiceCenterSnapshot(
      summary: summary,
      rows: rows,
      totalRows: totalRows,
      metals: metals,
    );
  }

  @override
  Future<List<InvoiceCenterRow>> exportRows(InvoiceCenterQuery query) async {
    await _db.ensureReturnReversalSchema();
    final source = _sourceSql(query);
    final where = _filterSql(query);
    return _readRows(source, where);
  }

  Future<List<InvoiceCenterRow>> _readRows(
    _SqlPart source,
    _SqlPart where, {
    int? limit,
    int offset = 0,
  }) async {
    final pageSql = limit == null ? '' : ' LIMIT ? OFFSET ?';
    final rows = await _db.customSelect(
      'WITH documents AS (${source.sql}) '
      'SELECT * FROM documents WHERE ${where.sql} '
      'ORDER BY issued_at DESC, source_kind, source_id DESC$pageSql',
      variables: [
        ...source.variables,
        ...where.variables,
        if (limit != null) Variable.withInt(limit),
        if (limit != null) Variable.withInt(offset),
      ],
    ).get();
    return rows.map(_mapRow).toList(growable: false);
  }

  _SqlPart _sourceSql(InvoiceCenterQuery query) {
    final parts = <String>[];
    final variables = <Variable<Object>>[];
    final start = DateTime(query.month.year, query.month.month);
    final end = DateTime(query.month.year, query.month.month + 1);
    final startSeconds = start.millisecondsSinceEpoch ~/ 1000;
    final endSeconds = end.millisecondsSinceEpoch ~/ 1000;

    if (query.tab != InvoiceCenterTab.advance) {
      final monthFilter =
          query.usesMonth ? 'AND b.bill_date >= ? AND b.bill_date < ?' : '';
      final dueStatusFilter = query.tab == InvoiceCenterTab.due
          ? "AND UPPER(TRIM(b.status)) IN ('ACTIVE', 'PARTIALLY_RETURNED', 'RETURNED')"
          : '';
      parts.add('''
        SELECT 'sales' AS source_kind, b.id AS source_id,
          b.bill_no AS document_number, b.bill_date AS issued_at,
          COALESCE(NULLIF(TRIM(b.customer_name), ''), c.name,
            'Walk-in Customer') AS customer_name,
          COALESCE(NULLIF(TRIM(b.mobile), ''), c.mobile, '') AS mobile,
          b.customer_id AS customer_id,
          COALESCE((SELECT GROUP_CONCAT(DISTINCT TRIM(i.metal_type))
                    FROM bill_items i WHERE i.bill_id = b.id), '') AS metals,
          CASE WHEN UPPER(TRIM(b.status)) = 'CANCELLED' THEN 'cancelled'
               WHEN $_gstExpression = 1 THEN 'gst'
               ELSE 'regular' END AS category,
          CASE WHEN UPPER(TRIM(b.status)) = 'CANCELLED' THEN 'CANCELLED'
               WHEN UPPER(TRIM(b.status)) = 'RETURNED' THEN 'RETURNED'
               WHEN UPPER(TRIM(b.status)) = 'PARTIALLY_RETURNED'
                 THEN 'PARTIALLY_RETURNED'
               WHEN $_dueExpression > 0.5 THEN 'DUE'
               ELSE 'SETTLED' END AS display_status,
          COALESCE(b.final_amount, 0.0) AS total_amount,
          COALESCE(b.paid_amount, 0.0) AS paid_amount,
          CASE WHEN UPPER(TRIM(b.status)) = 'CANCELLED' THEN 0.0
               ELSE $_dueExpression END AS current_due
        FROM bills b LEFT JOIN customers c ON c.id = b.customer_id
        WHERE 1 = 1 $monthFilter $dueStatusFilter
      ''');
      if (query.usesMonth) {
        variables.addAll([
          Variable.withInt(startSeconds),
          Variable.withInt(endSeconds),
        ]);
      }
    }

    if (query.tab == InvoiceCenterTab.all ||
        query.tab == InvoiceCenterTab.advance) {
      final monthFilter =
          query.usesMonth ? 'AND o.created_at >= ? AND o.created_at < ?' : '';
      parts.add('''
        SELECT 'booking' AS source_kind, o.id AS source_id,
          o.order_no AS document_number, o.created_at AS issued_at,
          COALESCE(NULLIF(TRIM(c.name), ''), 'Customer') AS customer_name,
          COALESCE(c.mobile, '') AS mobile, o.customer_id AS customer_id,
          COALESCE(o.metal_type, '') AS metals, 'advance' AS category,
          CASE WHEN UPPER(TRIM(o.status)) = 'DELIVERED' THEN 'DELIVERED'
               WHEN UPPER(TRIM(o.status)) = 'CANCELLED' THEN 'CANCELLED'
               ELSE 'ADVANCE' END AS display_status,
          COALESCE(a.paid_amount, 0.0) AS total_amount,
          COALESCE(a.paid_amount, 0.0) AS paid_amount,
          0.0 AS current_due
        FROM sales_orders o
        LEFT JOIN customers c ON c.id = o.customer_id
        LEFT JOIN (SELECT order_id, SUM(amount_paid) AS paid_amount
                   FROM order_advances GROUP BY order_id) a ON a.order_id = o.id
        WHERE 1 = 1 $monthFilter
      ''');
      if (query.usesMonth) {
        variables.addAll([
          Variable.withInt(startSeconds),
          Variable.withInt(endSeconds),
        ]);
      }
    }

    if (query.tab == InvoiceCenterTab.all ||
        query.tab == InvoiceCenterTab.cancelled) {
      parts.add('''
        SELECT 'cancellation' AS source_kind, v.id AS source_id,
          v.voucher_no AS document_number,
          CAST(v.created_at / 1000 AS INTEGER) AS issued_at,
          COALESCE(NULLIF(TRIM(v.customer_name), ''), c.name,
            'Customer') AS customer_name,
          COALESCE(NULLIF(TRIM(v.mobile), ''), c.mobile, '') AS mobile,
          v.customer_id AS customer_id,
          COALESCE((SELECT GROUP_CONCAT(DISTINCT TRIM(l.metal_type))
                    FROM return_voucher_lines l
                    WHERE l.return_voucher_id = v.id),
                   (SELECT o.metal_type FROM sales_orders o
                    WHERE v.source_type = 'ADVANCE_BOOKING'
                      AND o.id = v.source_id), '') AS metals,
          'cancelled' AS category, 'CANCELLED' AS display_status,
          COALESCE(v.return_value, 0.0) AS total_amount,
          0.0 AS paid_amount, 0.0 AS current_due
        FROM return_vouchers v
        LEFT JOIN customers c ON c.id = v.customer_id
        WHERE v.operation_type = 'BOOKING_CANCELLATION'
          AND UPPER(TRIM(v.status)) = 'POSTED'
          AND v.created_at >= ? AND v.created_at < ?
      ''');
      variables.addAll([
        Variable.withInt(start.millisecondsSinceEpoch),
        Variable.withInt(end.millisecondsSinceEpoch),
      ]);
    }

    return _SqlPart(parts.join(' UNION ALL '), variables);
  }

  _SqlPart _filterSql(InvoiceCenterQuery query) {
    final conditions = <String>[];
    final variables = <Variable<Object>>[];
    switch (query.tab) {
      case InvoiceCenterTab.all:
        break;
      case InvoiceCenterTab.due:
        conditions.add("source_kind = 'sales' AND current_due > 0.5 "
            "AND display_status IN ('DUE', 'PARTIALLY_RETURNED', 'RETURNED')");
      case InvoiceCenterTab.advance:
        conditions.add("source_kind = 'booking' AND display_status = 'ADVANCE' "
            "AND total_amount > 0.005");
      case InvoiceCenterTab.regular:
        conditions.add("category = 'regular'");
      case InvoiceCenterTab.gst:
        conditions.add("category = 'gst'");
      case InvoiceCenterTab.cancelled:
        conditions.add("category = 'cancelled'");
    }
    final search = query.search.trim();
    if (search.isNotEmpty) {
      conditions.add('''(
        instr(lower(document_number), lower(?)) > 0 OR
        instr(lower(customer_name), lower(?)) > 0 OR
        instr(lower(mobile), lower(?)) > 0
      )''');
      variables.addAll(List.generate(3, (_) => Variable.withString(search)));
    }
    if (query.metal.isNotEmpty) {
      conditions.add("instr(',' || lower(metals) || ',', "
          "',' || lower(?) || ',') > 0");
      variables.add(Variable.withString(query.metal));
    }
    if (query.status.isNotEmpty) {
      conditions.add('display_status = ?');
      variables.add(Variable.withString(query.status));
    }
    if (query.minAmount != null) {
      conditions.add('total_amount >= ?');
      variables.add(Variable.withReal(query.minAmount!));
    }
    if (query.maxAmount != null) {
      conditions.add('total_amount <= ?');
      variables.add(Variable.withReal(query.maxAmount!));
    }
    return _SqlPart(
        conditions.isEmpty ? '1 = 1' : conditions.join(' AND '), variables);
  }

  Future<InvoiceCenterSummary> _loadSummary(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final sales = await _db.customSelect('''
      SELECT
        COALESCE(SUM(CASE WHEN UPPER(TRIM(b.status)) <> 'CANCELLED'
                            AND $_gstExpression = 0 THEN 1 ELSE 0 END), 0)
          AS regular_count,
        COALESCE(SUM(CASE WHEN UPPER(TRIM(b.status)) <> 'CANCELLED'
                            AND $_gstExpression = 0
                          THEN b.final_amount ELSE 0 END), 0) AS regular_amount,
        COALESCE(SUM(CASE WHEN UPPER(TRIM(b.status)) <> 'CANCELLED'
                            AND $_gstExpression = 1 THEN 1 ELSE 0 END), 0)
          AS gst_count,
        COALESCE(SUM(CASE WHEN UPPER(TRIM(b.status)) <> 'CANCELLED'
                            AND $_gstExpression = 1
                          THEN b.final_amount ELSE 0 END), 0) AS gst_amount,
        COALESCE(SUM(CASE WHEN UPPER(TRIM(b.status)) = 'CANCELLED'
                          THEN 1 ELSE 0 END), 0) AS cancelled_count,
        COALESCE(SUM(CASE WHEN UPPER(TRIM(b.status)) = 'CANCELLED'
                          THEN b.final_amount ELSE 0 END), 0)
          AS cancelled_amount
      FROM bills b WHERE b.bill_date >= ? AND b.bill_date < ?
    ''', variables: [
      Variable.withDateTime(start),
      Variable.withDateTime(end)
    ]).getSingle();
    final due = await _db.customSelect('''
      SELECT COUNT(*) AS due_count,
             COALESCE(SUM(current_due), 0.0) AS due_amount
      FROM (SELECT $_dueExpression AS current_due
            FROM bills b
            WHERE UPPER(TRIM(b.status)) IN
              ('ACTIVE', 'PARTIALLY_RETURNED', 'RETURNED'))
      WHERE current_due > 0.5
    ''').getSingle();
    final advance = await _db.customSelect('''
      SELECT COUNT(*) AS advance_count,
             COALESCE(SUM(paid_amount), 0.0) AS advance_amount
      FROM (SELECT o.id, COALESCE(SUM(a.amount_paid), 0.0) AS paid_amount
            FROM sales_orders o
            LEFT JOIN order_advances a ON a.order_id = o.id
            WHERE UPPER(TRIM(o.status)) IN ('PENDING', 'READY')
            GROUP BY o.id HAVING paid_amount > 0.005)
    ''').getSingle();
    final cancellations = await _db.customSelect('''
      SELECT COUNT(*) AS voucher_count,
             COALESCE(SUM(return_value), 0.0) AS voucher_amount
      FROM return_vouchers
      WHERE operation_type = 'BOOKING_CANCELLATION'
        AND UPPER(TRIM(status)) = 'POSTED'
        AND created_at >= ? AND created_at < ?
    ''', variables: [
      Variable.withInt(start.millisecondsSinceEpoch),
      Variable.withInt(end.millisecondsSinceEpoch),
    ]).getSingle();
    return InvoiceCenterSummary({
      InvoiceCenterTab.regular: InvoiceCenterMetric(
        count: _int(sales, 'regular_count'),
        amount: _double(sales, 'regular_amount'),
      ),
      InvoiceCenterTab.gst: InvoiceCenterMetric(
        count: _int(sales, 'gst_count'),
        amount: _double(sales, 'gst_amount'),
      ),
      InvoiceCenterTab.due: InvoiceCenterMetric(
        count: _int(due, 'due_count'),
        amount: _double(due, 'due_amount'),
      ),
      InvoiceCenterTab.advance: InvoiceCenterMetric(
        count: _int(advance, 'advance_count'),
        amount: _double(advance, 'advance_amount'),
      ),
      InvoiceCenterTab.cancelled: InvoiceCenterMetric(
        count: _int(sales, 'cancelled_count') +
            _int(cancellations, 'voucher_count'),
        amount: _double(sales, 'cancelled_amount') +
            _double(cancellations, 'voucher_amount'),
      ),
    });
  }

  Future<List<String>> _loadMetals() async {
    final rows = await _db.customSelect('''
      SELECT DISTINCT TRIM(metal) AS metal FROM (
        SELECT metal_type AS metal FROM bill_items
        UNION ALL SELECT metal_type FROM sales_orders
        UNION ALL SELECT metal_type FROM return_voucher_lines
      ) WHERE TRIM(COALESCE(metal, '')) <> '' ORDER BY metal
    ''').get();
    return rows.map((row) => row.read<String>('metal')).toList(growable: false);
  }

  InvoiceCenterRow _mapRow(QueryRow row) {
    final category = row.read<String>('category');
    final kind = row.read<String>('source_kind');
    return InvoiceCenterRow(
      kind: InvoiceCenterDocumentKind.values.byName(kind),
      id: _int(row, 'source_id'),
      number: row.read<String>('document_number'),
      issuedAt: DateTime.fromMillisecondsSinceEpoch(
        _int(row, 'issued_at') * 1000,
      ),
      customerName: row.read<String>('customer_name'),
      mobile: row.read<String>('mobile'),
      customerId: row.readNullable<int>('customer_id'),
      metals: row.read<String>('metals'),
      category: InvoiceCenterTab.values.byName(category),
      status: row.read<String>('display_status'),
      total: _double(row, 'total_amount'),
      paid: _double(row, 'paid_amount'),
      due: _double(row, 'current_due'),
    );
  }

  static int _int(QueryRow row, String key) => (row.data[key] as num).toInt();
  static double _double(QueryRow row, String key) =>
      (row.data[key] as num).toDouble();
}

class _SqlPart {
  const _SqlPart(this.sql, this.variables);

  final String sql;
  final List<Variable<Object>> variables;
}
