part of 'return_reversal_drift_repository.dart';

extension _ReturnReversalPostingGuards on ReturnReversalDriftRepository {
  void _validateProcessRequest(ReturnReversalProcessRequest request) {
    if (!request.operationType.acceptsSourceType(request.sourceDocument.type)) {
      throw StateError('Selected document is not valid for this operation.');
    }
    if (request.lines.isEmpty) {
      throw StateError('Add at least one item to the return cart.');
    }
    final isAdvanceBookingCancellation =
        request.operationType.isBookingCancellation &&
            request.sourceDocument.type ==
                ReturnReversalSourceDocumentType.advanceBooking;
    final seen = <int>{};
    for (final line in request.lines) {
      if (!seen.add(line.sourceLineNo)) {
        throw StateError('Duplicate return line ${line.sourceLineNo}.');
      }
      final sourceLine = request.sourceDocument.lineByNo(line.sourceLineNo);
      if (sourceLine == null) {
        throw StateError('Invoice line ${line.sourceLineNo} no longer exists.');
      }
      if (sourceLine.isReversed) {
        throw StateError('Line ${line.sourceLineNo} is already reversed.');
      }
      if (isAdvanceBookingCancellation) {
        if (line.stockDisposition !=
            ReturnReversalStockDisposition.notApplicable) {
          throw StateError(
            'Booking cancellation does not use stock routing.',
          );
        }
        continue;
      }
      if (line.receivedNetWeight <= 0) {
        throw StateError(
            'Received net weight is required for line ${line.sourceLineNo}.');
      }
      if (line.receivedNetWeight - sourceLine.netWeight > _weightTolerance) {
        throw StateError(
          'Received net weight for line ${line.sourceLineNo} cannot exceed the original sold net weight.',
        );
      }
      if ((!line.huidMatched || !line.unitMatched) &&
          line.stockDisposition != ReturnReversalStockDisposition.managerHold) {
        throw StateError(
          'Line ${line.sourceLineNo} has a verification mismatch. Move it to manager hold before processing.',
        );
      }
    }
  }

  Future<void> _assertProcessLinesAvailable(
    ReturnReversalProcessRequest request,
    String sourceType,
  ) async {
    for (final line in request.lines) {
      final row = await _database.customSelect(
        '''
        SELECT COUNT(*) AS line_count
        FROM return_voucher_lines
        WHERE source_type = ?
          AND source_id = ?
          AND source_line_no = ?
          AND status <> 'VOIDED'
        ''',
        variables: [
          drift.Variable.withString(sourceType),
          drift.Variable.withInt(request.sourceDocument.id),
          drift.Variable.withInt(line.sourceLineNo),
        ],
      ).getSingle();
      if (row.read<int>('line_count') > 0) {
        throw StateError(
            'Line ${line.sourceLineNo} has already been processed.');
      }
    }
  }

  Future<void> _assertBookingStillCancellable(int orderId) async {
    final row = await _database.customSelect(
      '''
      SELECT o.id
      FROM sales_orders o
      WHERE o.id = ? AND $cancellableBookingPredicate
      ''',
      variables: [drift.Variable.withInt(orderId)],
    ).getSingleOrNull();
    if (row == null) {
      throw StateError(
        'This booking is no longer active or has been converted to a sale. '
        'Refresh the Desk before cancelling.',
      );
    }
  }

  Future<void> _assertSourceSnapshotCurrent(
    ReturnReversalSourceDocument reviewed,
  ) async {
    final current = switch (reviewed.type) {
      ReturnReversalSourceDocumentType.salesInvoice =>
        await _findSalesInvoiceByNumber(reviewed.documentNo),
      ReturnReversalSourceDocumentType.advanceBooking =>
        await _findAdvanceBookingByNumber(reviewed.documentNo),
      ReturnReversalSourceDocumentType.customerPurchase =>
        await _findCustomerPurchaseByNumber(reviewed.documentNo),
    };
    if (current == null || !_sourceSnapshotPolicy.matches(reviewed, current)) {
      throw StateError(
        'The source document changed since it was opened. '
        'Refresh and review the latest amounts before posting.',
      );
    }
  }

  Future<void> _insertReturnLine({
    required int voucherId,
    required String voucherNo,
    required String sourceType,
    required ReturnReversalSourceDocument sourceDocument,
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
    required ReturnReversalLineValuation valuation,
    required int nowMs,
  }) async {
    final values = <String, Object?>{
      'return_voucher_id': voucherId,
      'source_type': sourceType,
      'source_id': sourceDocument.id,
      'source_number': sourceDocument.documentNo,
      'source_line_no': sourceLine.lineNo,
      'source_bill_item_id': sourceLine.sourceLineId,
      'stock_item_id': sourceLine.linkedStockItemId,
      'stock_unit_id': sourceLine.linkedStockUnitId,
      'stock_disposition': returnLine.stockDisposition.storageValue,
      'metal_type': sourceLine.metalType,
      'item_description': sourceLine.description,
      'huid': sourceLine.huidNumber.trim().isEmpty
          ? null
          : sourceLine.huidNumber.trim(),
      'quantity': sourceLine.quantity,
      'quantity_unit_code': sourceLine.quantityUnitCode,
      'purity': sourceLine.purity,
      'sold_net_weight': sourceLine.netWeight,
      'received_net_weight': returnLine.receivedNetWeight,
      'short_weight': (sourceLine.netWeight - returnLine.receivedNetWeight)
          .clamp(0.0, double.infinity),
      'rate': sourceLine.rate,
      'sold_item_value': sourceLine.displayLineTotal,
      'adjusted_item_value': valuation.adjustedLineAmount,
      'available_making_amount': valuation.adjustedMakingAmount,
      'making_returned_amount': valuation.makingReturnedAmount,
      'metal_return_amount': valuation.metalAmount,
      'line_return_value': valuation.returnValue,
      'huid_matched': returnLine.huidMatched ? 1 : 0,
      'unit_matched': returnLine.unitMatched ? 1 : 0,
      'status': 'POSTED',
      'created_at': nowMs,
      'action': returnLine.stockDisposition.storageValue,
    };
    await _insertFilteringExistingColumns(
      tableName: 'return_voucher_lines',
      values: values,
    );
  }

  Future<void> _insertReturnVoucher({
    required ReturnReversalProcessRequest request,
    required String voucherNo,
    required String sourceType,
    required double returnValue,
    required double dueAdjustedAmount,
    required double refundPayableAmount,
    required double makingReturnedAmount,
    required int nowMs,
  }) {
    final operatorNote = request.operatorNote.trim();
    final values = <String, Object?>{
      'voucher_no': voucherNo,
      'operation_type': _operationTypeStorage(request.operationType),
      'source_type': sourceType,
      'source_id': request.sourceDocument.id,
      'source_number': request.sourceDocument.documentNo,
      'customer_id': request.sourceDocument.customerId,
      'customer_name': request.sourceDocument.customerName,
      'mobile': request.sourceDocument.mobile,
      'settlement_mode': request.settlementMode.storageValue,
      'original_total_amount': request.sourceDocument.finalAmount,
      'return_value': returnValue,
      'due_adjusted_amount': dueAdjustedAmount,
      'refund_payable_amount': refundPayableAmount,
      'making_returned_amount': makingReturnedAmount,
      'status': 'POSTED',
      'operator_note': operatorNote.isEmpty ? null : operatorNote,
      'created_at': nowMs,
      'updated_at': nowMs,
      'action': _operationTypeStorage(request.operationType),
    };
    return _insertFilteringExistingColumns(
      tableName: 'return_vouchers',
      values: values,
    );
  }

  Future<void> _insertFilteringExistingColumns({
    required String tableName,
    required Map<String, Object?> values,
  }) async {
    final existingColumns = await _columnNamesFor(tableName);
    final filtered = Map.fromEntries(
      values.entries.where((entry) => existingColumns.contains(entry.key)),
    );
    final columns = filtered.keys.map((column) => '"$column"').join(', ');
    final placeholders = List.filled(filtered.length, '?').join(', ');
    await _database.customStatement(
      'INSERT INTO "$tableName" ($columns) VALUES ($placeholders)',
      filtered.values.toList(growable: false),
    );
  }

  Future<Set<String>> _columnNamesFor(String tableName) async {
    final rows =
        await _database.customSelect('PRAGMA table_info("$tableName")').get();
    return rows
        .map((row) => row.data['name'])
        .whereType<String>()
        .map((name) => name.toLowerCase())
        .toSet();
  }
}
