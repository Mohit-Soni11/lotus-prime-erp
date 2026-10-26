import 'package:drift/drift.dart';

import '../../database/db/app_database.dart';
import '../../features/customer/domain/services/customer_contact_value.dart';
import '../../models/customer/customer_enums/customer_list_enums.dart';
import '../../models/customer/customer_list/customer_list_ui_model.dart';

/// Reads one aggregate row per customer from each transaction source.
/// Transaction rows stay in SQLite instead of being materialized in Dart.
class CustomerListActivityLoader {
  const CustomerListActivityLoader(this._db);

  final AppDatabase _db;

  Future<List<CustomerListItemModel>> load(List<Customer> customers) async {
    final activity = {
      for (final customer in customers)
        customer.id: _CustomerActivity(customer),
    };
    if (activity.isEmpty) return [];

    await _loadBills(activity);
    await _loadOrders(activity);
    await _loadGirvi(activity);
    return activity.values.map((entry) => entry.toModel()).toList();
  }

  Future<void> _loadBills(Map<int, _CustomerActivity> activity) async {
    final rows = await _db.customSelect('''
      WITH ranked AS (
        SELECT customer_id, bill_no, source_advance_order_no,
          COALESCE(updated_at, bill_date) AS activity_at,
          CASE
            WHEN UPPER(TRIM(payment_status)) IN
              ('PAID', 'SETTLED', 'COMPLETE', 'COMPLETED') THEN 0.0
            WHEN due_amount > 0.005 OR UPPER(TRIM(payment_status)) IN
              ('PARTIAL', 'DUE', 'UNPAID') THEN MAX(due_amount, 0.0)
            ELSE MAX(final_amount - paid_amount, 0.0)
          END AS current_due,
          CASE WHEN UPPER(TRIM(status)) IN ('CANCELLED', 'VOID')
            THEN 0 ELSE 1 END AS posted,
          final_amount,
          ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY COALESCE(updated_at, bill_date) DESC, id DESC
          ) AS activity_rank
        FROM bills WHERE customer_id IS NOT NULL
      ), totals AS (
        SELECT customer_id, SUM(posted) AS bill_count,
          SUM(CASE WHEN posted = 1 THEN final_amount ELSE 0.0 END)
            AS invoice_value,
          SUM(CASE WHEN posted = 1 THEN current_due ELSE 0.0 END)
            AS due_amount
        FROM ranked GROUP BY customer_id
      )
      SELECT ranked.customer_id, bill_no, source_advance_order_no,
        activity_at, current_due, posted, bill_count, invoice_value, due_amount
      FROM ranked JOIN totals USING (customer_id)
      WHERE activity_rank = 1
    ''').get();

    for (final row in rows) {
      final entry = activity[row.read<int>('customer_id')];
      if (entry == null) continue;
      entry
        ..billCount = row.read<int>('bill_count')
        ..invoiceValue = _number(row, 'invoice_value')
        ..dueAmount = _number(row, 'due_amount');
      final due = _number(row, 'current_due');
      final billNo = row.read<String>('bill_no');
      final advanceNo = row.readNullable<String>('source_advance_order_no');
      entry.touch(
        when: _date(row.read<int>('activity_at')),
        kind: CustomerActivityKind.invoice,
        label: advanceNo?.trim().isNotEmpty == true
            ? 'Advance invoice $billNo'
            : 'Invoice $billNo',
        detail: row.read<int>('posted') == 0
            ? 'Invoice cancelled'
            : due > 0.01
                ? 'Due ${_formatMoney(due)}'
                : 'Sales bill settled',
        priority: 40,
      );
    }
  }

  Future<void> _loadOrders(Map<int, _CustomerActivity> activity) async {
    final rows = await _db.customSelect('''
      WITH ranked AS (
        SELECT customer_id, order_no, status, item_name, metal_type, purity,
          MAX(COALESCE(updated_at, 0), COALESCE(delivery_date, 0),
              created_at) AS activity_at,
          CASE WHEN UPPER(TRIM(status)) IN ('PENDING', 'READY')
            THEN 1 ELSE 0 END AS is_open,
          ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY MAX(COALESCE(updated_at, 0),
              COALESCE(delivery_date, 0), created_at) DESC, id DESC
          ) AS activity_rank
        FROM sales_orders
      ), totals AS (
        SELECT customer_id, SUM(is_open) AS active_count
        FROM ranked GROUP BY customer_id
      )
      SELECT ranked.customer_id, order_no, status, item_name, metal_type,
        purity, activity_at, is_open, active_count
      FROM ranked JOIN totals USING (customer_id)
      WHERE activity_rank = 1
    ''').get();

    for (final row in rows) {
      final entry = activity[row.read<int>('customer_id')];
      if (entry == null) continue;
      entry.activeAdvanceCount = row.read<int>('active_count');
      final status = row.read<String>('status').trim().toUpperCase();
      entry.touch(
        when: _date(row.read<int>('activity_at')),
        kind: CustomerActivityKind.advance,
        label: row.read<int>('is_open') == 1
            ? 'Advance order ${row.read<String>('order_no')}'
            : 'Advance ${status.toLowerCase()}',
        detail: '${row.read<String>('item_name')} - '
            '${row.read<String>('metal_type')} ${row.read<String>('purity')}',
        priority: 30,
      );
    }
  }

  Future<void> _loadGirvi(Map<int, _CustomerActivity> activity) async {
    final rows = await _db.customSelect('''
      WITH ranked AS (
        SELECT customer_id, ticket_no, item_description, loan_amount,
          MAX(COALESCE(updated_at, 0), COALESCE(release_date, 0),
              COALESCE(last_interest_paid_date, 0), start_date)
            AS activity_at,
          CASE WHEN UPPER(TRIM(status)) IN ('RELEASED', 'AUCTIONED')
            THEN 0 ELSE 1 END AS is_open,
          ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY MAX(COALESCE(updated_at, 0),
              COALESCE(release_date, 0),
              COALESCE(last_interest_paid_date, 0), start_date) DESC, id DESC
          ) AS activity_rank
        FROM girvi_loans
      ), totals AS (
        SELECT customer_id, SUM(is_open) AS active_count
        FROM ranked GROUP BY customer_id
      )
      SELECT ranked.customer_id, ticket_no, item_description, loan_amount,
        activity_at, active_count
      FROM ranked JOIN totals USING (customer_id)
      WHERE activity_rank = 1
    ''').get();

    for (final row in rows) {
      final entry = activity[row.read<int>('customer_id')];
      if (entry == null) continue;
      entry.activeGirviCount = row.read<int>('active_count');
      entry.touch(
        when: _date(row.read<int>('activity_at')),
        kind: CustomerActivityKind.girvi,
        label: 'Girvi ticket ${row.read<String>('ticket_no')}',
        detail: '${row.read<String>('item_description')} - '
            '${_formatMoney(_number(row, 'loan_amount'))}',
        priority: 20,
      );
    }
  }

  static double _number(QueryRow row, String column) =>
      (row.data[column] as num).toDouble();

  static DateTime _date(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000);

  static String _formatMoney(double value) {
    final amount = value.abs();
    if (amount >= 10000000) {
      return 'Rs ${(value / 10000000).toStringAsFixed(1)}Cr';
    }
    if (amount >= 100000) return 'Rs ${(value / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return 'Rs ${(value / 1000).toStringAsFixed(1)}K';
    return 'Rs ${value.toStringAsFixed(0)}';
  }
}

class _CustomerActivity {
  _CustomerActivity(this.customer) {
    lastActivityAt = customer.updatedAt ?? customer.createdAt;
    if (customer.updatedAt != null) {
      lastActivityLabel = 'Customer profile updated';
      lastActivityDetail = 'Profile information changed';
    }
  }

  final Customer customer;
  int billCount = 0;
  int activeAdvanceCount = 0;
  int activeGirviCount = 0;
  double invoiceValue = 0;
  double dueAmount = 0;
  late DateTime lastActivityAt;
  CustomerActivityKind lastActivityKind = CustomerActivityKind.profile;
  String lastActivityLabel = 'Customer profile created';
  String lastActivityDetail = 'No transaction posted yet';
  int _lastPriority = 0;

  void touch({
    required DateTime when,
    required CustomerActivityKind kind,
    required String label,
    required String detail,
    required int priority,
  }) {
    final isNewer = when.isAfter(lastActivityAt);
    final isSameMoment = when.isAtSameMomentAs(lastActivityAt);
    if (!isNewer && !(isSameMoment && priority > _lastPriority)) return;

    lastActivityAt = when;
    lastActivityKind = kind;
    lastActivityLabel = label;
    lastActivityDetail = detail;
    _lastPriority = priority;
  }

  CustomerListItemModel toModel() {
    final name =
        customer.name.trim().isEmpty ? 'Unknown Customer' : customer.name;
    return CustomerListItemModel(
      id: customer.id,
      name: name,
      mobile: CustomerContactValue.displayMobile(customer.mobile),
      city: customer.city ?? '',
      state: customer.state ?? '',
      gstNumber: customer.gstNumber ?? '',
      panNumber: customer.panNumber ?? '',
      type: CustomerType.fromString(customer.type),
      billCount: billCount,
      activeAdvanceCount: activeAdvanceCount,
      activeGirviCount: activeGirviCount,
      invoiceValue: invoiceValue,
      dueAmount: dueAmount,
      createdAt: customer.createdAt,
      lastActivityAt: lastActivityAt,
      lastActivityKind: lastActivityKind,
      lastActivityLabel: lastActivityLabel,
      lastActivityDetail: lastActivityDetail,
      initials: CustomerListItemModel.buildInitials(name),
    );
  }
}
