part of 'customer_profile_repository.dart';

mixin _CustomerProfileBillQueries {
  AppDatabase get _db;
  Future<CustomerBillDetailModel?> fetchBillDetails({
    required int customerId,
    required int billId,
  }) async {
    try {
      await _db.ensureReturnReversalSchema();
      final bill = await (_db.select(_db.bills)
            ..where(
                (t) => t.id.equals(billId) & t.customerId.equals(customerId)))
          .getSingleOrNull();
      if (bill == null) return null;

      final itemRows = await (_db.select(_db.billItems)
            ..where((t) => t.billId.equals(billId))
            ..orderBy([(t) => OrderingTerm(expression: t.lineNo)]))
          .get();

      final returnMarkers = await _fetchBillReturnMarkers([bill.id]);
      final returnMarker = returnMarkers[bill.id];
      final linkedDocuments = await _fetchBillLinkedDocuments([bill.id]);
      final billModel = CustomerBillModel(
        id: bill.id,
        billNo: bill.billNo,
        totalAmount: bill.finalAmount,
        paidAmount: bill.paidAmount,
        recordedDueAmount: _authoritativeBillDueAmount(bill),
        status: bill.status,
        paymentStatus: bill.paymentStatus,
        billDate: bill.billDate,
        sourceAdvanceOrderId: bill.sourceAdvanceOrderId,
        sourceAdvanceOrderNo: bill.sourceAdvanceOrderNo,
        lineCount: itemRows.length,
        returnedLineCount: returnMarker?.lineCount ?? 0,
        returnedAmount: returnMarker?.amount ?? 0,
        returnVoucherNo: returnMarker?.voucherNo ?? '',
        isModified: bill.updatedAt != null,
        grossAmount: bill.totalAmount,
        discountAmount: bill.discount,
        taxableAmount: bill.taxableAmount,
        cgstAmount: bill.cgstAmount,
        sgstAmount: bill.sgstAmount,
        igstAmount: bill.igstAmount,
        gstAmount: bill.gstAmount,
        makingTotal: bill.makingTotal,
        roundOffAmount: bill.roundOffAmount,
        tradeInDeduction: bill.tradeInDeduction,
        cashPaid: bill.cashPaid,
        upiPaid: bill.upiPaid,
        cardPaid: bill.cardPaid,
        advancePaid: bill.advancePaid,
        billingMode: bill.billingMode,
        documentType: bill.documentType,
        gstPricingMode: bill.gstPricingMode,
        taxTreatment: bill.taxTreatment,
        placeOfSupply: bill.placeOfSupplySnapshot ?? '',
        linkedDocuments: linkedDocuments[bill.id] ?? const [],
      );

      final returnLineMarkers = await _fetchBillReturnLineMarkers(bill.id);
      final items = itemRows.map(
        (item) {
          final marker = returnLineMarkers[item.lineNo];
          return CustomerBillLineItemModel(
            lineNo: item.lineNo,
            metalType: item.metalType,
            itemName: item.itemName,
            hsnCode: item.hsnCode ?? '',
            huid: item.huid,
            purity: item.purity,
            quantity: item.quantity,
            quantityUnitCode: item.quantityUnitCode,
            grossWeight: item.grossWeight,
            lessWeight: item.lessWeight,
            netWeight: item.netWeight,
            rate: item.rate,
            makingChargeType: item.makingChargeType,
            makingChargeInput: item.makingChargeInput,
            makingCharge: item.makingCharge,
            itemTotal: item.itemTotal,
            taxableAmount: item.taxableAmountSnapshot,
            gstRate: item.gstRateSnapshot,
            cgstAmount: item.cgstAmountSnapshot,
            sgstAmount: item.sgstAmountSnapshot,
            igstAmount: item.igstAmountSnapshot,
            gstAmount: item.gstAmountSnapshot,
            invoiceValue: item.invoiceValueSnapshot,
            isReturned: marker != null,
            returnVoucherNo: marker?.voucherNo ?? '',
            returnedValue: marker?.amount ?? 0,
          );
        },
      ).toList();
      final existingLineNumbers = itemRows.map((item) => item.lineNo).toSet();
      items.addAll(
        await _fetchRecoveredBillItemsFromReturnLines(
          billId: bill.id,
          existingLineNumbers: existingLineNumbers,
        ),
      );
      items.sort((a, b) => a.lineNo.compareTo(b.lineNo));

      return CustomerBillDetailModel(
        bill: billModel,
        customerName: bill.customerName ?? 'Walk-in Customer',
        customerMobile: bill.mobile ?? '',
        items: items,
      );
    } catch (e) {
      AppLogger.error("Customer bill details fetch error: $e");
      return null;
    }
  }

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

  Future<Map<int, _BillReturnLineMarker>> _fetchBillReturnLineMarkers(
    int billId,
  ) async {
    try {
      final rows = await _db.customSelect(
        '''
        SELECT
          l.source_line_no,
          COALESCE(MIN(v.voucher_no), '') AS voucher_no,
          COALESCE(SUM(l.line_return_value), 0.0) AS returned_amount
        FROM return_voucher_lines l
        INNER JOIN return_vouchers v ON v.id = l.return_voucher_id
        WHERE l.source_type = 'SALES_INVOICE'
          AND l.source_id = ?
          AND l.status <> 'VOIDED'
          AND v.status <> 'VOIDED'
        GROUP BY l.source_line_no
        ''',
        variables: [Variable.withInt(billId)],
      ).get();

      return {
        for (final row in rows)
          row.read<int>('source_line_no'): _BillReturnLineMarker(
            voucherNo: row.readNullable<String>('voucher_no') ?? '',
            amount: _readDouble(row, 'returned_amount'),
          ),
      };
    } catch (e) {
      AppLogger.error("Customer bill return line marker fetch error: $e");
      rethrow;
    }
  }

  Future<List<CustomerBillLineItemModel>>
      _fetchRecoveredBillItemsFromReturnLines({
    required int billId,
    required Set<int> existingLineNumbers,
  }) async {
    try {
      final rows = await _db.customSelect(
        '''
        SELECT
          l.source_line_no,
          COALESCE(MIN(v.voucher_no), '') AS voucher_no,
          COALESCE(MAX(l.metal_type), '') AS metal_type,
          COALESCE(MAX(l.item_description), '') AS item_description,
          COALESCE(MAX(l.huid), '') AS huid,
          COALESCE(MAX(l.quantity), 1) AS quantity,
          COALESCE(MAX(l.quantity_unit_code), 'PCS') AS quantity_unit_code,
          COALESCE(MAX(l.purity), '') AS purity,
          COALESCE(MAX(l.sold_net_weight), 0.0) AS sold_net_weight,
          COALESCE(MAX(l.rate), 0.0) AS rate,
          COALESCE(MAX(l.sold_item_value), 0.0) AS sold_item_value,
          COALESCE(MAX(l.available_making_amount), 0.0) AS making_amount,
          COALESCE(SUM(l.line_return_value), 0.0) AS returned_amount
        FROM return_voucher_lines l
        INNER JOIN return_vouchers v ON v.id = l.return_voucher_id
        WHERE l.source_type = 'SALES_INVOICE'
          AND l.source_id = ?
          AND l.status <> 'VOIDED'
          AND v.status <> 'VOIDED'
        GROUP BY l.source_line_no
        ORDER BY l.source_line_no ASC
        ''',
        variables: [Variable.withInt(billId)],
      ).get();

      final recovered = <CustomerBillLineItemModel>[];
      for (final row in rows) {
        final lineNo = row.read<int>('source_line_no');
        if (existingLineNumbers.contains(lineNo)) continue;
        final itemTotal = _readDouble(row, 'sold_item_value');
        final netWeight = _readDouble(row, 'sold_net_weight');
        recovered.add(
          CustomerBillLineItemModel(
            lineNo: lineNo,
            metalType: row.readNullable<String>('metal_type') ?? 'GOLD',
            itemName:
                row.readNullable<String>('item_description') ?? 'Invoice Item',
            hsnCode: '',
            huid: row.readNullable<String>('huid'),
            purity: row.readNullable<String>('purity'),
            quantity: row.readNullable<int>('quantity') ?? 1,
            quantityUnitCode:
                row.readNullable<String>('quantity_unit_code') ?? 'PCS',
            grossWeight: netWeight,
            netWeight: netWeight,
            rate: _readDouble(row, 'rate'),
            makingCharge: _readDouble(row, 'making_amount'),
            itemTotal: itemTotal,
            invoiceValue: itemTotal,
            isReturned: true,
            returnVoucherNo: row.readNullable<String>('voucher_no') ?? '',
            returnedValue: _readDouble(row, 'returned_amount'),
          ),
        );
      }
      return recovered;
    } catch (e) {
      AppLogger.error("Recovered returned bill item fetch error: $e");
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
        .where((bill) => !bill.isPaid && bill.dueAmount > 0)
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

class _BillReturnLineMarker {
  final String voucherNo;
  final double amount;

  const _BillReturnLineMarker({
    required this.voucherNo,
    required this.amount,
  });
}
