import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_transaction_summary.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/repositories/return_reversal_repository.dart';

class ReturnReversalDriftRepository implements ReturnReversalRepository {
  final AppDatabase _database;

  const ReturnReversalDriftRepository(this._database);

  @override
  Future<ReturnReversalTransactionSummary> fetchTransactionSummary() async {
    // Keeps the screen stable while the workflow tables and posting rules are
    // wired in the next implementation step.
    await _database.customSelect('SELECT 1').getSingle();
    return const ReturnReversalTransactionSummary.empty();
  }

  @override
  Future<ReturnReversalLookupResult> findCustomerHistoryByMobile(
    String mobile,
  ) async {
    final normalizedMobile = _normalizePhone(mobile);
    if (normalizedMobile.isEmpty) {
      return const ReturnReversalLookupResult.empty();
    }

    final salesInvoices = await _findSalesInvoicesByMobile(normalizedMobile);
    final advanceBookings = await _findAdvanceBookingsByMobile(
      normalizedMobile,
    );
    final customerPurchases = await _findCustomerPurchasesByMobile(
      normalizedMobile,
    );

    return ReturnReversalLookupResult(
      salesInvoices: salesInvoices,
      advanceBookings: advanceBookings,
      customerPurchases: customerPurchases,
    );
  }

  @override
  Future<ReturnReversalSourceDocument?> findSourceDocumentByNumber(
    String documentNumber,
  ) async {
    final sourceNumber = documentNumber.trim();
    if (sourceNumber.isEmpty) {
      return null;
    }

    return await _findSalesInvoiceByNumber(sourceNumber) ??
        await _findAdvanceBookingByNumber(sourceNumber) ??
        await _findCustomerPurchaseByNumber(sourceNumber);
  }

  Future<List<ReturnReversalSourceDocument>> _findSalesInvoicesByMobile(
    String normalizedMobile,
  ) async {
    final rows = await _database.customSelect(
      '''
      SELECT
        b.id,
        b.bill_no,
        COALESCE(NULLIF(b.customer_name, ''), c.name, '') AS customer_name,
        COALESCE(NULLIF(b.mobile, ''), c.mobile, '') AS mobile,
        COALESCE(c.address_line1, '') AS address_line1,
        COALESCE(c.address_line2, '') AS address_line2,
        COALESCE(c.city, '') AS city,
        b.bill_date,
        b.total_amount,
        b.discount,
        b.final_amount,
        b.paid_amount,
        b.due_amount,
        b.status
      FROM bills b
      LEFT JOIN customers c ON c.id = b.customer_id
      WHERE REPLACE(REPLACE(COALESCE(NULLIF(b.mobile, ''), c.mobile, ''), ' ', ''), '-', '') = ?
        AND b.status <> 'CANCELLED'
      ORDER BY b.bill_date DESC, b.id DESC
      LIMIT 100
      ''',
      variables: [drift.Variable.withString(normalizedMobile)],
    ).get();

    final documents = <ReturnReversalSourceDocument>[];
    for (final row in rows) {
      documents.add(await _mapSalesInvoice(row));
    }
    return documents;
  }

  Future<ReturnReversalSourceDocument?> _findSalesInvoiceByNumber(
    String documentNumber,
  ) async {
    final row = await _database.customSelect(
      '''
      SELECT
        b.id,
        b.bill_no,
        COALESCE(NULLIF(b.customer_name, ''), c.name, '') AS customer_name,
        COALESCE(NULLIF(b.mobile, ''), c.mobile, '') AS mobile,
        COALESCE(c.address_line1, '') AS address_line1,
        COALESCE(c.address_line2, '') AS address_line2,
        COALESCE(c.city, '') AS city,
        b.bill_date,
        b.total_amount,
        b.discount,
        b.final_amount,
        b.paid_amount,
        b.due_amount,
        b.status
      FROM bills b
      LEFT JOIN customers c ON c.id = b.customer_id
      WHERE UPPER(TRIM(b.bill_no)) = UPPER(TRIM(?))
        AND b.status <> 'CANCELLED'
      LIMIT 1
      ''',
      variables: [drift.Variable.withString(documentNumber)],
    ).getSingleOrNull();

    return row == null ? null : _mapSalesInvoice(row);
  }

  Future<ReturnReversalSourceDocument> _mapSalesInvoice(
    drift.QueryRow row,
  ) async {
    final billId = row.read<int>('id');
    final items = await (_database.select(_database.billItems)
          ..where((table) => table.billId.equals(billId))
          ..orderBy([(table) => drift.OrderingTerm.asc(table.lineNo)]))
        .get();
    final billTotal = _readDouble(row, 'total_amount');
    final billDiscount = _readDouble(row, 'discount');
    final lines = <ReturnReversalSourceLineItem>[
      for (final item in items)
        ReturnReversalSourceLineItem(
          lineNo: item.lineNo,
          metalType: item.metalType,
          description: item.itemName,
          hsnCode: item.hsnCode ?? '',
          purity: item.purity,
          quantity: item.quantity,
          grossWeight: item.grossWeight,
          lessWeight: item.lessWeight,
          lessWeightPerPiece: item.lessWeightPerPiece,
          netWeight: item.netWeight,
          fineWeight: item.fineWeight,
          rate: item.rate,
          makingChargeType: item.makingChargeType,
          makingChargeInput: item.makingChargeInput,
          makingAmount: item.makingCharge,
          discountAmount: _allocatedDiscount(
            lineValue: item.itemTotal,
            billTotal: billTotal,
            billDiscount: billDiscount,
          ),
          taxableAmount: item.taxableAmountSnapshot,
          gstAmount: item.gstAmountSnapshot,
          invoiceValue: item.invoiceValueSnapshot,
          value: item.itemTotal,
          huidNumber: item.huid ?? '',
          linkedStockSku: item.linkedStockSku ?? '',
          status: row.readNullable<String>('status') ?? 'ACTIVE',
        ),
    ];

    return ReturnReversalSourceDocument(
      id: billId,
      type: ReturnReversalSourceDocumentType.salesInvoice,
      documentNo: row.read<String>('bill_no'),
      customerName: row.readNullable<String>('customer_name') ?? '',
      mobile: row.readNullable<String>('mobile') ?? '',
      address: _joinAddress(
        row.readNullable<String>('address_line1'),
        row.readNullable<String>('address_line2'),
        row.readNullable<String>('city'),
      ),
      documentDate: _readDateTime(row, 'bill_date'),
      grossValue: _readDouble(row, 'final_amount'),
      paidAmount: _readDouble(row, 'paid_amount'),
      dueAmount: _readDouble(row, 'due_amount'),
      netWeight: lines.fold<double>(
        0,
        (total, line) => total + line.netWeight,
      ),
      lineItems: lines,
    );
  }

  Future<List<ReturnReversalSourceDocument>> _findAdvanceBookingsByMobile(
    String normalizedMobile,
  ) async {
    final rows = await _database.customSelect(
      '''
      SELECT
        o.id,
        o.order_no,
        c.name AS customer_name,
        c.mobile,
        COALESCE(c.address_line1, '') AS address_line1,
        COALESCE(c.address_line2, '') AS address_line2,
        COALESCE(c.city, '') AS city,
        COALESCE(o.created_at, 0) AS created_at,
        o.item_name,
        o.metal_type,
        o.approx_weight,
        o.locked_rate,
        o.status,
        COALESCE(SUM(a.amount_paid), 0.0) AS paid_amount
      FROM sales_orders o
      INNER JOIN customers c ON c.id = o.customer_id
      LEFT JOIN order_advances a ON a.order_id = o.id
      WHERE REPLACE(REPLACE(COALESCE(c.mobile, ''), ' ', ''), '-', '') = ?
      GROUP BY o.id
      ORDER BY o.id DESC
      LIMIT 100
      ''',
      variables: [drift.Variable.withString(normalizedMobile)],
    ).get();

    return rows.map(_mapAdvanceBooking).toList(growable: false);
  }

  Future<ReturnReversalSourceDocument?> _findAdvanceBookingByNumber(
    String documentNumber,
  ) async {
    final row = await _database.customSelect(
      '''
      SELECT
        o.id,
        o.order_no,
        c.name AS customer_name,
        c.mobile,
        COALESCE(c.address_line1, '') AS address_line1,
        COALESCE(c.address_line2, '') AS address_line2,
        COALESCE(c.city, '') AS city,
        COALESCE(o.created_at, 0) AS created_at,
        o.item_name,
        o.metal_type,
        o.approx_weight,
        o.locked_rate,
        o.status,
        COALESCE(SUM(a.amount_paid), 0.0) AS paid_amount
      FROM sales_orders o
      INNER JOIN customers c ON c.id = o.customer_id
      LEFT JOIN order_advances a ON a.order_id = o.id
      WHERE UPPER(TRIM(o.order_no)) = UPPER(TRIM(?))
      GROUP BY o.id
      LIMIT 1
      ''',
      variables: [drift.Variable.withString(documentNumber)],
    ).getSingleOrNull();

    return row == null ? null : _mapAdvanceBooking(row);
  }

  ReturnReversalSourceDocument _mapAdvanceBooking(drift.QueryRow row) {
    final weight = _readDouble(row, 'approx_weight');
    final rate = _readDouble(row, 'locked_rate');
    final paidAmount = _readDouble(row, 'paid_amount');
    final lineValue = rate > 0 && weight > 0 ? weight * rate : paidAmount;
    final line = ReturnReversalSourceLineItem(
      lineNo: 1,
      metalType: row.readNullable<String>('metal_type') ?? 'GOLD',
      description: row.readNullable<String>('item_name') ?? 'Booked Jewellery',
      quantity: 1,
      grossWeight: weight,
      netWeight: weight,
      rate: rate,
      value: lineValue,
      status: row.readNullable<String>('status') ?? 'PENDING',
    );

    return ReturnReversalSourceDocument(
      id: row.read<int>('id'),
      type: ReturnReversalSourceDocumentType.advanceBooking,
      documentNo: row.read<String>('order_no'),
      customerName: row.readNullable<String>('customer_name') ?? '',
      mobile: row.readNullable<String>('mobile') ?? '',
      address: _joinAddress(
        row.readNullable<String>('address_line1'),
        row.readNullable<String>('address_line2'),
        row.readNullable<String>('city'),
      ),
      documentDate: _readDateTime(row, 'created_at'),
      grossValue: lineValue,
      paidAmount: paidAmount,
      dueAmount: 0,
      netWeight: weight,
      lineItems: [line],
    );
  }

  Future<List<ReturnReversalSourceDocument>> _findCustomerPurchasesByMobile(
    String normalizedMobile,
  ) async {
    final rows = await _database.customSelect(
      '''
      SELECT
        id,
        voucher_no,
        party_name,
        mobile,
        COALESCE(city, '') AS city,
        created_at,
        grand_total,
        total_paid,
        balance_due,
        payment_status,
        status
      FROM purchase_vouchers
      WHERE source_type = 'CUSTOMER'
        AND REPLACE(REPLACE(COALESCE(mobile, ''), ' ', ''), '-', '') = ?
        AND status <> 'CANCELLED'
      ORDER BY created_at DESC, id DESC
      LIMIT 100
      ''',
      variables: [drift.Variable.withString(normalizedMobile)],
    ).get();

    final documents = <ReturnReversalSourceDocument>[];
    for (final row in rows) {
      documents.add(await _mapCustomerPurchase(row));
    }
    return documents;
  }

  Future<ReturnReversalSourceDocument?> _findCustomerPurchaseByNumber(
    String documentNumber,
  ) async {
    final row = await _database.customSelect(
      '''
      SELECT
        id,
        voucher_no,
        party_name,
        mobile,
        COALESCE(city, '') AS city,
        created_at,
        grand_total,
        total_paid,
        balance_due,
        payment_status,
        status
      FROM purchase_vouchers
      WHERE source_type = 'CUSTOMER'
        AND UPPER(TRIM(voucher_no)) = UPPER(TRIM(?))
        AND status <> 'CANCELLED'
      LIMIT 1
      ''',
      variables: [drift.Variable.withString(documentNumber)],
    ).getSingleOrNull();

    return row == null ? null : _mapCustomerPurchase(row);
  }

  Future<ReturnReversalSourceDocument> _mapCustomerPurchase(
    drift.QueryRow row,
  ) async {
    final voucherId = row.read<int>('id');
    final itemRows = await _database.customSelect(
      '''
      SELECT
        line_no,
        metal_type,
        item_description,
        quantity,
        gross_weight,
        net_weight,
        rate,
        line_amount
      FROM purchase_voucher_items
      WHERE purchase_voucher_id = ?
      ORDER BY line_no ASC, id ASC
      ''',
      variables: [drift.Variable.withInt(voucherId)],
    ).get();
    final lines = [
      for (final item in itemRows)
        ReturnReversalSourceLineItem(
          lineNo: item.read<int>('line_no'),
          metalType: item.readNullable<String>('metal_type') ?? 'OLD METAL',
          description:
              item.readNullable<String>('item_description') ?? 'Old Metal',
          quantity: item.readNullable<int>('quantity') ?? 1,
          grossWeight: _readDouble(item, 'gross_weight'),
          netWeight: _readDouble(item, 'net_weight'),
          rate: _readDouble(item, 'rate'),
          value: _readDouble(item, 'line_amount'),
          status: row.readNullable<String>('payment_status') ?? 'SAVED',
        ),
    ];

    return ReturnReversalSourceDocument(
      id: voucherId,
      type: ReturnReversalSourceDocumentType.customerPurchase,
      documentNo: row.read<String>('voucher_no'),
      customerName: row.readNullable<String>('party_name') ?? '',
      mobile: row.readNullable<String>('mobile') ?? '',
      address: row.readNullable<String>('city') ?? '',
      documentDate: _readDateTime(row, 'created_at'),
      grossValue: _readDouble(row, 'grand_total'),
      paidAmount: _readDouble(row, 'total_paid'),
      dueAmount: _readDouble(row, 'balance_due'),
      netWeight: lines.fold<double>(
        0,
        (total, line) => total + line.netWeight,
      ),
      lineItems: lines,
    );
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s\-]'), '').trim();
  }

  String _joinAddress(String? line1, String? line2, String? city) {
    return [line1, line2, city]
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .join(', ');
  }

  DateTime _readDateTime(drift.QueryRow row, String column) {
    try {
      final value = row.readNullable<DateTime>(column);
      if (value != null) {
        return value;
      }
    } catch (_) {
      // Drift custom queries can expose date columns as epoch milliseconds.
    }
    try {
      final millis = row.readNullable<int>(column);
      if (millis != null && millis > 0) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (_) {}
    return DateTime.now();
  }

  double _readDouble(drift.QueryRow row, String column) {
    try {
      return row.readNullable<double>(column) ?? 0;
    } catch (_) {
      return (row.readNullable<int>(column) ?? 0).toDouble();
    }
  }

  double _allocatedDiscount({
    required double lineValue,
    required double billTotal,
    required double billDiscount,
  }) {
    if (lineValue <= 0 || billTotal <= 0 || billDiscount <= 0) {
      return 0;
    }
    return billDiscount * (lineValue / billTotal);
  }
}
