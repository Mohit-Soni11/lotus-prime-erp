part of 'return_reversal_drift_repository.dart';

extension _ReturnReversalStockPosting on ReturnReversalDriftRepository {
  Future<void> _applyStockDisposition({
    required int voucherId,
    required String voucherNo,
    required ReturnReversalSourceDocument sourceDocument,
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
    required ReturnReversalLineValuation valuation,
    required DateTime now,
    required int nowMs,
  }) async {
    if (sourceDocument.type != ReturnReversalSourceDocumentType.salesInvoice) {
      return;
    }

    if (returnLine.stockDisposition == ReturnReversalStockDisposition.melting) {
      await _postMeltingPurchaseLine(
        voucherNo: voucherNo,
        sourceDocument: sourceDocument,
        sourceLine: sourceLine,
        returnLine: returnLine,
        valuation: valuation,
        nowMs: nowMs,
      );
      await _moveLinkedUnitToStatus(
        sourceLine: sourceLine,
        voucherNo: voucherNo,
        newStatus: 'Melting',
        reason: 'Sales return routed to melting',
        now: now,
        nowMs: nowMs,
      );
      return;
    }

    final targetStatus = returnLine.stockDisposition ==
            ReturnReversalStockDisposition.managerHold
        ? 'On Hold'
        : 'Available';
    final movementType = returnLine.stockDisposition ==
            ReturnReversalStockDisposition.managerHold
        ? 'RETURN_HOLD'
        : 'SALE_RESTORE';

    final createdStockItem = sourceLine.linkedStockItemId == null;
    final stockItemId = sourceLine.linkedStockItemId ??
        await _createReturnedStockItem(
          voucherNo: voucherNo,
          sourceDocument: sourceDocument,
          sourceLine: sourceLine,
          returnLine: returnLine,
          valuation: valuation,
          status: targetStatus,
          nowMs: nowMs,
        );

    if (sourceLine.linkedStockUnitId != null) {
      await _moveLinkedUnitToStatus(
        sourceLine: sourceLine,
        voucherNo: voucherNo,
        newStatus: targetStatus,
        reason: returnLine.stockDisposition ==
                ReturnReversalStockDisposition.managerHold
            ? 'Sales return held for manager review'
            : 'Sales return restored to sellable stock',
        now: now,
        nowMs: nowMs,
      );
      await _database.customStatement(
        '''
        UPDATE stock_items
        SET quantity = quantity + 1,
            is_active = 1,
            status = ?,
            updated_at = ?
        WHERE id = ?
        ''',
        [targetStatus, nowMs, stockItemId],
      );
    } else if (!createdStockItem) {
      await _createReturnedStockUnit(
        stockItemId: stockItemId,
        sku: sourceLine.linkedStockSku.trim().isEmpty
            ? '$voucherNo-L${sourceLine.lineNo.toString().padLeft(3, '0')}'
            : sourceLine.linkedStockSku.trim(),
        batchCode: voucherNo,
        sourceLine: sourceLine,
        returnLine: returnLine,
        valuation: valuation,
        status: targetStatus,
        nowMs: nowMs,
      );
      await _database.customStatement(
        '''
        UPDATE stock_items
        SET quantity = quantity + 1,
            is_active = 1,
            status = ?,
            updated_at = ?
        WHERE id = ?
        ''',
        [targetStatus, nowMs, stockItemId],
      );
    }

    await _insertReturnStockMovement(
      stockItemId: stockItemId,
      movementType: movementType,
      voucherNo: voucherNo,
      sourceLine: sourceLine,
      returnLine: returnLine,
      nowMs: nowMs,
      reason: targetStatus == 'Available'
          ? 'Sales return stock restore'
          : 'Sales return manager hold',
    );
  }

  Future<void> _moveLinkedUnitToStatus({
    required ReturnReversalSourceLineItem sourceLine,
    required String voucherNo,
    required String newStatus,
    required String reason,
    required DateTime now,
    required int nowMs,
  }) async {
    final stockUnitId = sourceLine.linkedStockUnitId;
    if (stockUnitId == null) {
      return;
    }
    final row = await _database.customSelect(
      '''
      SELECT
        id,
        stock_item_id,
        unit_code,
        huid,
        batch_code,
        status
      FROM stock_item_units
      WHERE id = ?
      LIMIT 1
      ''',
      variables: [drift.Variable.withInt(stockUnitId)],
    ).getSingleOrNull();
    if (row == null) {
      throw StateError(
          'Linked stock unit for line ${sourceLine.lineNo} no longer exists.');
    }
    final previousStatus = row.readNullable<String>('status') ?? '';
    await _database.customStatement(
      '''
      UPDATE stock_item_units
      SET status = ?, sold_at = NULL, updated_at = ?
      WHERE id = ?
      ''',
      [newStatus, nowMs, stockUnitId],
    );
    await _database.customStatement(
      '''
      INSERT INTO stock_unit_status_events (
        stock_unit_id,
        stock_item_id,
        unit_code,
        huid,
        batch_code,
        previous_status,
        new_status,
        reason,
        source_type,
        source_number,
        created_at
      ) VALUES (?, NULLIF(?, 0), ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        stockUnitId,
        row.readNullable<int>('stock_item_id') ??
            sourceLine.linkedStockItemId ??
            0,
        row.readNullable<String>('unit_code') ?? sourceLine.linkedStockSku,
        row.readNullable<String>('huid') ?? sourceLine.huidNumber,
        row.readNullable<String>('batch_code') ?? voucherNo,
        previousStatus,
        newStatus,
        reason,
        'SALES_RETURN',
        voucherNo,
        nowMs,
      ],
    );
  }

  Future<int> _createReturnedStockItem({
    required String voucherNo,
    required ReturnReversalSourceDocument sourceDocument,
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
    required ReturnReversalLineValuation valuation,
    required String status,
    required int nowMs,
  }) async {
    final sku = '$voucherNo-L${sourceLine.lineNo.toString().padLeft(3, '0')}';
    final stockItemId = await _database.into(_database.stockItems).insert(
          StockItemsCompanion(
            sku: drift.Value(sku),
            itemName: drift.Value(sourceLine.description),
            description: drift.Value(
              'Returned from ${sourceDocument.documentNo}; original line ${sourceLine.lineNo}',
            ),
            category: drift.Value(_categoryForMetal(sourceLine.metalType)),
            subCategory: const drift.Value('Sales Return'),
            metalType: drift.Value(_metalDisplayName(sourceLine.metalType)),
            purity: drift.Value(sourceLine.purity),
            grossWeight: drift.Value(returnLine.receivedNetWeight),
            stoneWeight: const drift.Value(0),
            netWeight: drift.Value(returnLine.receivedNetWeight),
            purchaseRate: drift.Value(sourceLine.rate),
            makingCharge: drift.Value(valuation.makingReturnedAmount),
            makingChargeType: drift.Value(sourceLine.makingChargeType),
            purchasePrice: drift.Value(valuation.returnValue),
            mrp: drift.Value(sourceLine.displayLineTotal),
            hsnCode: drift.Value(sourceLine.hsnCode.trim().isEmpty
                ? null
                : sourceLine.hsnCode.trim()),
            huid: drift.Value(sourceLine.huidNumber.trim().isEmpty
                ? null
                : sourceLine.huidNumber.trim()),
            quantity: const drift.Value(1),
            status: drift.Value(status),
            isActive: drift.Value(status == 'Available'),
          ),
        );
    await _createReturnedStockUnit(
      stockItemId: stockItemId,
      sku: sku,
      batchCode: voucherNo,
      sourceLine: sourceLine,
      returnLine: returnLine,
      valuation: valuation,
      status: status,
      nowMs: nowMs,
      pieceNo: 1,
    );
    return stockItemId;
  }

  Future<void> _createReturnedStockUnit({
    required int stockItemId,
    required String sku,
    required String batchCode,
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
    required ReturnReversalLineValuation valuation,
    required String status,
    required int nowMs,
    int? pieceNo,
  }) async {
    final resolvedPieceNo = pieceNo ?? await _nextStockUnitPieceNo(stockItemId);
    await _database.customStatement(
      '''
      INSERT INTO stock_item_units (
        stock_item_id,
        batch_code,
        unit_code,
        piece_no,
        metal_type,
        item_type,
        item_name,
        huid,
        gross_weight,
        less_weight,
        net_weight,
        purity_percent,
        actual_fine_weight,
        rate_per_gram,
        making_amount,
        unit_cost,
        status,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        stockItemId,
        batchCode,
        '$sku-U${resolvedPieceNo.toString().padLeft(3, '0')}',
        resolvedPieceNo,
        _metalDisplayName(sourceLine.metalType),
        'Sales Return',
        sourceLine.description,
        sourceLine.huidNumber.trim().isEmpty
            ? null
            : sourceLine.huidNumber.trim(),
        returnLine.receivedNetWeight,
        0.0,
        returnLine.receivedNetWeight,
        _purityPercent(sourceLine.purity),
        sourceLine.displayFineWeight * valuation.receivedRatio,
        sourceLine.rate,
        valuation.makingReturnedAmount,
        valuation.returnValue,
        status,
        nowMs,
        nowMs,
      ],
    );
  }

  Future<int> _nextStockUnitPieceNo(int stockItemId) async {
    final row = await _database.customSelect(
      '''
      SELECT COALESCE(MAX(piece_no), 0) + 1 AS next_piece_no
      FROM stock_item_units
      WHERE stock_item_id = ?
      ''',
      variables: [drift.Variable.withInt(stockItemId)],
    ).getSingle();
    return row.read<int>('next_piece_no');
  }

  Future<void> _postMeltingPurchaseLine({
    required String voucherNo,
    required ReturnReversalSourceDocument sourceDocument,
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
    required ReturnReversalLineValuation valuation,
    required int nowMs,
  }) async {
    final meltingVoucherNo = 'MELT-$voucherNo';
    var row = await _database.customSelect(
      'SELECT id FROM purchase_vouchers WHERE voucher_no = ? LIMIT 1',
      variables: [drift.Variable.withString(meltingVoucherNo)],
    ).getSingleOrNull();

    if (row == null) {
      final sequence = await _nextPurchaseSequence();
      await _database.customStatement(
        '''
        INSERT INTO purchase_vouchers (
          voucher_no,
          sequence_no,
          source_type,
          customer_id,
          party_name,
          mobile,
          tax_type,
          gross_amount,
          taxable_amount,
          grand_total,
          total_paid,
          balance_due,
          payment_status,
          stock_entry_count,
          status,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          meltingVoucherNo,
          sequence,
          'CUSTOMER',
          sourceDocument.customerId,
          sourceDocument.customerName,
          sourceDocument.mobile,
          'NORMAL',
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          'RETURN_MELTING',
          0,
          'MELTING',
          nowMs,
          nowMs,
        ],
      );
      row = await _database.customSelect(
        'SELECT id FROM purchase_vouchers WHERE voucher_no = ? LIMIT 1',
        variables: [drift.Variable.withString(meltingVoucherNo)],
      ).getSingle();
    }

    final purchaseVoucherId = row.read<int>('id');
    await _database.customStatement(
      '''
      INSERT INTO purchase_voucher_items (
        purchase_voucher_id,
        line_no,
        sku,
        metal_type,
        item_description,
        gross_weight,
        less_weight,
        net_weight,
        purity,
        fine_weight,
        rate,
        quantity,
        quantity_mode,
        line_amount,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        purchaseVoucherId,
        sourceLine.lineNo,
        '$meltingVoucherNo-L${sourceLine.lineNo.toString().padLeft(3, '0')}',
        _metalDisplayName(sourceLine.metalType),
        '${sourceLine.description} | Return melting ${sourceDocument.documentNo}',
        returnLine.receivedNetWeight,
        0.0,
        returnLine.receivedNetWeight,
        _purityPercent(sourceLine.purity),
        sourceLine.displayFineWeight * valuation.receivedRatio,
        sourceLine.rate,
        sourceLine.quantity,
        sourceLine.quantityUnitCode,
        valuation.metalAmount,
        nowMs,
      ],
    );
    await _database.customStatement(
      '''
      UPDATE purchase_vouchers
      SET gross_amount = gross_amount + ?,
          taxable_amount = taxable_amount + ?,
          grand_total = grand_total + ?,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        valuation.metalAmount,
        valuation.metalAmount,
        valuation.metalAmount,
        nowMs,
        purchaseVoucherId,
      ],
    );
  }

  Future<void> _insertReturnStockMovement({
    required int stockItemId,
    required String movementType,
    required String voucherNo,
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
    required int nowMs,
    required String reason,
  }) async {
    await _database.customStatement(
      '''
      INSERT INTO stock_movements (
        stock_item_id,
        movement_type,
        source_type,
        source_id,
        source_line_no,
        source_number,
        sku_snapshot,
        metal_type_snapshot,
        item_name_snapshot,
        quantity_delta,
        gross_weight_delta,
        net_weight_delta,
        fine_weight_delta,
        reason,
        occurred_at,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        stockItemId,
        movementType,
        'SALES_RETURN',
        voucherNo,
        sourceLine.lineNo,
        voucherNo,
        sourceLine.linkedStockSku.trim().isEmpty
            ? '$voucherNo-L${sourceLine.lineNo.toString().padLeft(3, '0')}'
            : sourceLine.linkedStockSku.trim(),
        _metalDisplayName(sourceLine.metalType),
        sourceLine.description,
        1,
        returnLine.receivedNetWeight,
        returnLine.receivedNetWeight,
        sourceLine.displayFineWeight *
            _valuationService
                .valueLine(sourceLine: sourceLine, returnLine: returnLine)
                .receivedRatio,
        reason,
        nowMs,
        nowMs,
        nowMs,
      ],
    );
  }
}
