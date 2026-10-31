part of 'customer_profile_repository.dart';

mixin _CustomerProfileBillQueries {
  AppDatabase get _db;
  Future<Map<int, _BillReturnMarker>> _fetchBillReturnMarkers(
    List<int> billIds,
  ) async {
    if (billIds.isEmpty) {
      return const {};
    }
    try {
      final placeholders = List.filled(billIds.length, '?').join(', ');
      final rows = await _db.customSelect(
        '''
        SELECT
          l.source_id,
          COUNT(DISTINCT l.source_line_no) AS returned_line_count,
          COALESCE(SUM(l.line_return_value), 0.0) AS returned_amount,
          COALESCE(MIN(v.voucher_no), '') AS voucher_no
        FROM return_voucher_lines l
        INNER JOIN return_vouchers v ON v.id = l.return_voucher_id
        WHERE l.source_type = 'SALES_INVOICE'
          AND l.source_id IN ($placeholders)
          AND l.status <> 'VOIDED'
          AND v.status <> 'VOIDED'
        GROUP BY l.source_id
        ''',
        variables: [
          for (final billId in billIds) Variable.withInt(billId),
        ],
      ).get();

      return {
        for (final row in rows)
          row.read<int>('source_id'): _BillReturnMarker(
            lineCount: row.read<int>('returned_line_count'),
            amount: _readDouble(row, 'returned_amount'),
            voucherNo: row.readNullable<String>('voucher_no') ?? '',
          ),
      };
    } catch (e) {
      AppLogger.error("Customer bill return marker fetch error: $e");
      rethrow;
    }
  }

  Future<Map<int, int>> _fetchBillLineCounts(List<int> billIds) async {
    if (billIds.isEmpty) {
      return const {};
    }
    try {
      final placeholders = List.filled(billIds.length, '?').join(', ');
      final rows = await _db.customSelect(
        '''
        SELECT bill_id, COUNT(*) AS line_count
        FROM bill_items
        WHERE bill_id IN ($placeholders)
        GROUP BY bill_id
        ''',
        variables: [
          for (final billId in billIds) Variable.withInt(billId),
        ],
      ).get();

      return {
        for (final row in rows)
          row.read<int>('bill_id'): row.read<int>('line_count'),
      };
    } catch (e) {
      AppLogger.error("Customer bill line count fetch error: $e");
      rethrow;
    }
  }

  Future<Map<int, List<CustomerLinkedDocumentModel>>> _fetchBillLinkedDocuments(
    List<int> billIds,
  ) async {
    if (billIds.isEmpty) {
      return const {};
    }
    try {
      final placeholders = List.filled(billIds.length, '?').join(', ');
      final rows = await _db.customSelect(
        '''
        SELECT
          v.source_id,
          v.id,
          v.voucher_no,
          v.operation_type,
          v.source_type,
          v.source_number,
          v.status,
          v.created_at,
          v.return_value,
          v.making_returned_amount,
          v.due_adjusted_amount,
          v.refund_payable_amount,
          COUNT(DISTINCT l.source_line_no) AS line_count,
          COALESCE(SUM(l.received_net_weight), 0.0) AS net_weight
        FROM return_vouchers v
        LEFT JOIN return_voucher_lines l
          ON l.return_voucher_id = v.id
          AND l.status <> 'VOIDED'
        WHERE v.source_type = 'SALES_INVOICE'
          AND v.source_id IN ($placeholders)
          AND v.status <> 'VOIDED'
        GROUP BY
          v.source_id,
          v.id,
          v.voucher_no,
          v.operation_type,
          v.source_type,
          v.source_number,
          v.status,
          v.created_at,
          v.return_value,
          v.making_returned_amount,
          v.due_adjusted_amount,
          v.refund_payable_amount
        ORDER BY v.created_at ASC, v.id ASC
        ''',
        variables: [
          for (final billId in billIds) Variable.withInt(billId),
        ],
      ).get();

      final result = <int, List<CustomerLinkedDocumentModel>>{};
      for (final row in rows) {
        final sourceId = row.read<int>('source_id');
        final document = CustomerLinkedDocumentModel(
          id: row.read<int>('id'),
          documentNo: row.readNullable<String>('voucher_no') ?? '',
          operationType: row.readNullable<String>('operation_type') ?? '',
          sourceType: row.readNullable<String>('source_type') ?? '',
          sourceNumber: row.readNullable<String>('source_number') ?? '',
          status: row.readNullable<String>('status') ?? '',
          createdAt: _readEpochDateTime(row, 'created_at'),
          lineCount: row.read<int>('line_count'),
          netWeight: _readDouble(row, 'net_weight'),
          returnValue: _readDouble(row, 'return_value'),
          makingReturnedAmount: _readDouble(row, 'making_returned_amount'),
          dueAdjustedAmount: _readDouble(row, 'due_adjusted_amount'),
          refundPayableAmount: _readDouble(row, 'refund_payable_amount'),
        );
        result.putIfAbsent(sourceId, () => []).add(document);
      }
      return result;
    } catch (e) {
      AppLogger.error("Customer bill linked document fetch error: $e");
      rethrow;
    }
  }

  double _readDouble(QueryRow row, String column) {
    try {
      return row.readNullable<double>(column) ?? 0;
    } catch (_) {
      return (row.readNullable<int>(column) ?? 0).toDouble();
    }
  }

  DateTime _readEpochDateTime(QueryRow row, String column) {
    final value = row.readNullable<int>(column);
    if (value == null || value <= 0) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  double? _authoritativeBillDueAmount(Bill bill) {
    return BillDuePolicy.authoritativeCustomerDueSnapshot(bill);
  }

  List<CustomerDueModel> _buildDues(List<CustomerBillModel> bills) {
    return bills
        .where((bill) =>
            BillDuePolicy.isEligibleBillStatus(bill.status) &&
            !bill.isPaid &&
            bill.dueAmount > 0)
        .map(
          (bill) => CustomerDueModel(
            billId: bill.id,
            billNo: bill.billNo,
            totalAmount: bill.totalAmount,
            paidAmount: bill.paidAmount,
            recordedDueAmount: bill.dueAmount,
            billDate: bill.billDate,
            sourceAdvanceOrderId: bill.sourceAdvanceOrderId,
            sourceAdvanceOrderNo: bill.sourceAdvanceOrderNo,
          ),
        )
        .toList();
  }
}

class _BillReturnMarker {
  final int lineCount;
  final double amount;
  final String voucherNo;

  const _BillReturnMarker({
    required this.lineCount,
    required this.amount,
    required this.voucherNo,
  });
}
