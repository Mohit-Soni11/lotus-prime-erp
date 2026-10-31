part of 'return_reversal_drift_repository.dart';

extension _ReturnReversalLedgerPosting on ReturnReversalDriftRepository {
  Future<void> _applySourceStatus({
    required ReturnReversalProcessRequest request,
    required String sourceType,
    required DateTime now,
  }) async {
    final postedLineCount = await _postedLineCount(
      sourceType: sourceType,
      sourceId: request.sourceDocument.id,
    );
    final fullyProcessed =
        postedLineCount >= request.sourceDocument.lineItems.length;

    switch (request.sourceDocument.type) {
      case ReturnReversalSourceDocumentType.salesInvoice:
        final newDue = (request.sourceDocument.dueAmount -
                _valuationService.totalReturnValue(
                  sourceDocument: request.sourceDocument,
                  returnLines: request.lines,
                ))
            .clamp(0.0, double.infinity)
            .toDouble();
        await (_database.update(_database.bills)
              ..where((bill) => bill.id.equals(request.sourceDocument.id)))
            .write(
          BillsCompanion(
            dueAmount: drift.Value(_roundMoney(newDue)),
            paymentStatus: drift.Value(newDue <= 0.5 ? 'PAID' : 'PARTIAL'),
            status:
                drift.Value(fullyProcessed ? 'RETURNED' : 'PARTIALLY_RETURNED'),
            updatedAt: drift.Value(now),
          ),
        );
      case ReturnReversalSourceDocumentType.advanceBooking:
        await (_database.update(_database.salesOrders)
              ..where((order) => order.id.equals(request.sourceDocument.id)))
            .write(
          SalesOrdersCompanion(
            status: const drift.Value('CANCELLED'),
            notes: const drift.Value('Cancelled via return desk'),
            updatedAt: drift.Value(now),
          ),
        );
      case ReturnReversalSourceDocumentType.customerPurchase:
        await _database.customStatement(
          '''
          UPDATE purchase_vouchers
          SET status = ?, updated_at = ?
          WHERE id = ?
          ''',
          [
            fullyProcessed ? 'RETURNED' : 'PARTIALLY_RETURNED',
            now.millisecondsSinceEpoch,
            request.sourceDocument.id
          ],
        );
    }
  }

  Future<void> _postRefundPayableLedger({
    required ReturnReversalProcessRequest request,
    required String voucherNo,
    required double payableAmount,
    required DateTime now,
  }) async {
    final customerId = request.sourceDocument.customerId;
    if (payableAmount <= 0.005 || customerId == null) {
      return;
    }
    await _database.into(_database.customerRefundPayables).insert(
          CustomerRefundPayablesCompanion.insert(
            customerId: customerId,
            entryType: 'CREDIT',
            sourceType: _operationTypeStorage(request.operationType),
            sourceReference: drift.Value(voucherNo),
            amount: drift.Value(payableAmount),
            paymentMode: const drift.Value('REFUND_PAYABLE'),
            notes: drift.Value(
              '${request.operationType.title} refund payable for ${request.sourceDocument.documentNo}',
            ),
            entryDate: drift.Value(now),
            isVoided: const drift.Value(false),
          ),
        );
  }

  Future<int> _postedLineCount({
    required String sourceType,
    required int sourceId,
  }) async {
    final row = await _database.customSelect(
      '''
      SELECT COUNT(*) AS line_count
      FROM return_voucher_lines
      WHERE source_type = ?
        AND source_id = ?
        AND status <> 'VOIDED'
      ''',
      variables: [
        drift.Variable.withString(sourceType),
        drift.Variable.withInt(sourceId),
      ],
    ).getSingle();
    return row.read<int>('line_count');
  }

  Future<int> _lastInsertRowId() async {
    final row = await _database
        .customSelect('SELECT last_insert_rowid() AS id')
        .getSingle();
    return row.read<int>('id');
  }

  Future<int> _nextPurchaseSequence() async {
    final row = await _database
        .customSelect(
          'SELECT COALESCE(MAX(sequence_no), 0) AS max_no FROM purchase_vouchers',
        )
        .getSingle();
    return row.read<int>('max_no') + 1;
  }

  Future<String> _nextReturnVoucherNo(
    ReturnReversalOperationType operationType,
  ) async {
    final prefix =
        operationType == ReturnReversalOperationType.salesReturn ? 'SR' : 'BC';
    final year = DateTime.now().year.toString().substring(2);
    final row = await _database
        .customSelect(
          'SELECT COALESCE(MAX(id), 0) AS max_id FROM return_vouchers',
        )
        .getSingle();
    final next = row.read<int>('max_id') + 1;
    return '$prefix-$year-${next.toString().padLeft(5, '0')}';
  }

  bool _isVoucherNoConflict(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('unique') &&
        message.contains('return_vouchers') &&
        message.contains('voucher_no');
  }
}
