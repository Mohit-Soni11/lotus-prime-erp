import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';

final class StockLotSaleReconciliationService {
  final AppDatabase _db;

  StockLotSaleReconciliationService(this._db);

  Future<void> reconcile() async {
    await _normalizeUntrackedBulkLots();

    final rows = await _db.customSelect(
      '''
      SELECT
        s.id AS stock_item_id,
        s.quantity AS current_quantity,
        s.gross_weight AS current_gross_weight,
        s.stone_weight AS current_less_weight,
        s.net_weight AS current_net_weight,
        u.id AS unit_id,
        pvi.quantity AS original_quantity,
        pvi.gross_weight AS original_gross_weight,
        pvi.less_weight AS original_less_weight,
        pvi.net_weight AS original_net_weight,
        pvi.fine_weight AS original_fine_weight,
        pvi.wastage_fine_weight AS original_wastage_fine_weight,
        pvi.valuation_fine_weight AS original_valuation_fine_weight,
        u.unit_cost AS current_unit_cost,
        u.making_amount AS current_making_amount,
        COALESCE(sales.sold_quantity, 0) AS sold_quantity,
        COALESCE(sales.sold_gross_weight, 0.0) AS sold_gross_weight,
        COALESCE(sales.sold_less_weight, 0.0) AS sold_less_weight,
        COALESCE(sales.sold_net_weight, 0.0) AS sold_net_weight,
        COALESCE(sales.sold_fine_weight, 0.0) AS sold_fine_weight
      FROM stock_items s
      INNER JOIN stock_item_units u ON u.stock_item_id = s.id
      LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
      INNER JOIN (
        SELECT
          bi.linked_stock_item_id AS stock_item_id,
          SUM(COALESCE(bi.quantity, 0)) AS sold_quantity,
          SUM(COALESCE(bi.gross_weight, 0.0)) AS sold_gross_weight,
          SUM(COALESCE(bi.less_weight, 0.0)) AS sold_less_weight,
          SUM(COALESCE(bi.net_weight, 0.0)) AS sold_net_weight,
          SUM(COALESCE(bi.fine_weight, 0.0)) AS sold_fine_weight
        FROM bill_items bi
        INNER JOIN bills b ON b.id = bi.bill_id
        WHERE bi.linked_stock_item_id IS NOT NULL
          AND UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
        GROUP BY bi.linked_stock_item_id
      ) sales ON sales.stock_item_id = s.id
      WHERE LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
        AND TRIM(COALESCE(u.huid, '')) = ''
        AND pvi.id IS NOT NULL
      ''',
    ).get();

    for (final row in rows) {
      await _reconcileLot(row);
    }

    await _reconcileSaleMovements();
  }

  Future<void> _normalizeUntrackedBulkLots() async {
    final stockRows = await _db.customSelect(
      '''
      SELECT
        s.id AS stock_item_id,
        s.sku AS sku,
        s.quantity AS current_quantity,
        COUNT(u.id) AS available_units,
        COALESCE(SUM(CASE WHEN LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%' THEN 1 ELSE 0 END), 0) AS lot_units
      FROM stock_items s
      INNER JOIN stock_item_units u ON u.stock_item_id = s.id
      WHERE u.status = ?
        AND TRIM(COALESCE(u.huid, '')) = ''
        AND NOT EXISTS (
          SELECT 1
          FROM stock_item_units hu
          WHERE hu.stock_item_id = s.id
            AND TRIM(COALESCE(hu.huid, '')) <> ''
        )
      GROUP BY s.id
      HAVING available_units > 1 OR lot_units = 0
      ''',
      variables: [drift.Variable<String>(StockStatus.available.label)],
    ).get();

    for (final stockRow in stockRows) {
      await _normalizeStockRow(stockRow);
    }
  }

  Future<void> _normalizeStockRow(drift.QueryRow stockRow) async {
    final stockItemId = stockRow.read<int>('stock_item_id');
    final sku = stockRow.read<String>('sku');
    final availableRows = await _db.customSelect(
      '''
      SELECT id,
             purchase_voucher_item_id,
             gross_weight,
             less_weight,
             net_weight,
             actual_fine_weight,
             wastage_fine_weight,
             valuation_fine_weight,
             unit_cost,
             making_amount
      FROM stock_item_units
      WHERE stock_item_id = ?
        AND status = ?
        AND TRIM(COALESCE(huid, '')) = ''
      ORDER BY
        CASE WHEN LOWER(COALESCE(unit_code, '')) LIKE '%lot%' THEN 0 ELSE 1 END,
        id ASC
      ''',
      variables: [
        drift.Variable<int>(stockItemId),
        drift.Variable<String>(StockStatus.available.label),
      ],
    ).get();

    if (availableRows.isEmpty) {
      return;
    }

    final unitBalance = _unitBalanceFromRows(availableRows);
    final sourceBalance = await _sourceBalanceForStock(
      stockItemId: stockItemId,
      availableRows: availableRows,
    );
    final balance = sourceBalance ?? unitBalance;
    final keeper = availableRows.first;
    final keeperId = keeper.read<int>('id');
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.customStatement(
      '''
      UPDATE stock_item_units
      SET unit_code = ?,
          piece_no = 1,
          gross_weight = ?,
          less_weight = ?,
          net_weight = ?,
          actual_fine_weight = ?,
          wastage_fine_weight = ?,
          valuation_fine_weight = ?,
          unit_cost = ?,
          making_amount = ?,
          status = ?,
          sold_at = NULL,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        '$sku-LOT',
        balance.grossWeight,
        balance.lessWeight,
        balance.netWeight,
        balance.fineWeight,
        balance.wastageFineWeight,
        balance.valuationFineWeight,
        balance.unitCost,
        unitBalance.makingAmount,
        StockStatus.available.label,
        now,
        keeperId,
      ],
    );

    final idsToDelete = availableRows
        .skip(1)
        .map((row) => row.read<int>('id'))
        .toList(growable: false);
    if (idsToDelete.isNotEmpty) {
      final placeholders = List.filled(idsToDelete.length, '?').join(', ');
      await _db.customStatement(
        '''
        DELETE FROM stock_item_units
        WHERE id IN ($placeholders)
        ''',
        idsToDelete,
      );
    }

    final currentQuantity = stockRow.read<int>('current_quantity');
    final quantity = currentQuantity > 0 ? currentQuantity : 1;
    await _db.customStatement(
      '''
      UPDATE stock_items
      SET quantity = ?,
          gross_weight = ?,
          stone_weight = ?,
          net_weight = ?,
          status = ?,
          is_active = 1,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        quantity,
        balance.grossWeight,
        balance.lessWeight,
        balance.netWeight,
        StockStatus.available.label,
        now,
        stockItemId,
      ],
    );
  }

  _StockLotBalance _unitBalanceFromRows(List<drift.QueryRow> rows) {
    double sum(String column) => rows.fold(
          0,
          (total, row) => total + _readDouble(row, column),
        );
    return _StockLotBalance(
      grossWeight: sum('gross_weight'),
      lessWeight: sum('less_weight'),
      netWeight: sum('net_weight'),
      fineWeight: sum('actual_fine_weight'),
      wastageFineWeight: sum('wastage_fine_weight'),
      valuationFineWeight: sum('valuation_fine_weight'),
      unitCost: sum('unit_cost'),
      makingAmount: sum('making_amount'),
    );
  }

  Future<_StockLotBalance?> _sourceBalanceForStock({
    required int stockItemId,
    required List<drift.QueryRow> availableRows,
  }) async {
    final purchaseItemIds = availableRows
        .map((row) => row.readNullable<int>('purchase_voucher_item_id'))
        .whereType<int>()
        .toSet();
    if (purchaseItemIds.length != 1) {
      return null;
    }

    final row = await _db.customSelect(
      '''
      SELECT
        pvi.gross_weight AS original_gross_weight,
        pvi.less_weight AS original_less_weight,
        pvi.net_weight AS original_net_weight,
        pvi.fine_weight AS original_fine_weight,
        pvi.wastage_fine_weight AS original_wastage_fine_weight,
        pvi.valuation_fine_weight AS original_valuation_fine_weight,
        pvi.line_amount AS original_line_amount,
        COALESCE(sales.sold_gross_weight, 0.0) AS sold_gross_weight,
        COALESCE(sales.sold_less_weight, 0.0) AS sold_less_weight,
        COALESCE(sales.sold_net_weight, 0.0) AS sold_net_weight,
        COALESCE(sales.sold_fine_weight, 0.0) AS sold_fine_weight,
        COALESCE(sales.sold_amount, 0.0) AS sold_amount
      FROM purchase_voucher_items pvi
      LEFT JOIN (
        SELECT
          bi.linked_stock_item_id AS stock_item_id,
          SUM(COALESCE(bi.gross_weight, 0.0)) AS sold_gross_weight,
          SUM(COALESCE(bi.less_weight, 0.0)) AS sold_less_weight,
          SUM(COALESCE(bi.net_weight, 0.0)) AS sold_net_weight,
          SUM(COALESCE(bi.fine_weight, 0.0)) AS sold_fine_weight,
          SUM(COALESCE(bi.item_total, 0.0)) AS sold_amount
        FROM bill_items bi
        INNER JOIN bills b ON b.id = bi.bill_id
        WHERE bi.linked_stock_item_id = ?
          AND UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
        GROUP BY bi.linked_stock_item_id
      ) sales ON sales.stock_item_id = ?
      WHERE pvi.id = ?
      ''',
      variables: [
        drift.Variable<int>(stockItemId),
        drift.Variable<int>(stockItemId),
        drift.Variable<int>(purchaseItemIds.single),
      ],
    ).getSingleOrNull();
    if (row == null) {
      return null;
    }

    final originalNet = _readDouble(row, 'original_net_weight');
    final availableNet = _positiveDouble(
      _readDouble(row, 'original_net_weight') -
          _readDouble(row, 'sold_net_weight'),
    );
    final remainingFactor = originalNet <= 0 ? 0.0 : availableNet / originalNet;
    return _StockLotBalance(
      grossWeight: _positiveDouble(
        _readDouble(row, 'original_gross_weight') -
            _readDouble(row, 'sold_gross_weight'),
      ),
      lessWeight: _positiveDouble(
        _readDouble(row, 'original_less_weight') -
            _readDouble(row, 'sold_less_weight'),
      ),
      netWeight: availableNet,
      fineWeight: _positiveDouble(
        _readDouble(row, 'original_fine_weight') -
            _readDouble(row, 'sold_fine_weight'),
      ),
      wastageFineWeight: _positiveDouble(
        _readDouble(row, 'original_wastage_fine_weight') * remainingFactor,
      ),
      valuationFineWeight: _positiveDouble(
        _readDouble(row, 'original_valuation_fine_weight') * remainingFactor,
      ),
      unitCost: _positiveDouble(
        _readDouble(row, 'original_line_amount') -
            _readDouble(row, 'sold_amount'),
      ),
      makingAmount: 0,
    );
  }

  Future<void> _reconcileLot(drift.QueryRow row) async {
    final stockItemId = row.read<int>('stock_item_id');
    final unitId = row.read<int>('unit_id');
    final originalQuantity = _positiveInt(row.read<int>('original_quantity'));
    final soldQuantity = _positiveInt(row.read<int>('sold_quantity'));
    final availableQuantity = _positiveInt(originalQuantity - soldQuantity);

    final originalGross = _readDouble(row, 'original_gross_weight');
    final originalLess = _readDouble(row, 'original_less_weight');
    final originalNet = _readDouble(row, 'original_net_weight');
    final originalFine = _readDouble(row, 'original_fine_weight');
    final originalWastageFine =
        _readDouble(row, 'original_wastage_fine_weight');
    final originalValuationFine =
        _readDouble(row, 'original_valuation_fine_weight');

    final soldGross = _readDouble(row, 'sold_gross_weight');
    final soldLess = _readDouble(row, 'sold_less_weight');
    final soldNet = _readDouble(row, 'sold_net_weight');
    final soldFine = _readDouble(row, 'sold_fine_weight');

    final availableGross = _positiveDouble(originalGross - soldGross);
    final availableLess = _positiveDouble(originalLess - soldLess);
    final availableNet = _positiveDouble(originalNet - soldNet);
    final availableFine = _positiveDouble(originalFine - soldFine);
    final remainingFactor = originalNet <= 0 ? 0.0 : availableNet / originalNet;
    final availableWastageFine =
        _positiveDouble(originalWastageFine * remainingFactor);
    final availableValuationFine =
        _positiveDouble(originalValuationFine * remainingFactor);
    final status = availableQuantity > 0
        ? StockStatus.available.label
        : StockStatus.sold.label;
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.customStatement(
      '''
      UPDATE stock_items
      SET quantity = ?,
          gross_weight = ?,
          stone_weight = ?,
          net_weight = ?,
          status = ?,
          is_active = ?,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        availableQuantity,
        availableGross,
        availableLess,
        availableNet,
        status,
        availableQuantity > 0 ? 1 : 0,
        now,
        stockItemId,
      ],
    );

    await _db.customStatement(
      '''
      UPDATE stock_item_units
      SET gross_weight = ?,
          less_weight = ?,
          net_weight = ?,
          actual_fine_weight = ?,
          wastage_fine_weight = ?,
          valuation_fine_weight = ?,
          status = ?,
          sold_at = CASE WHEN ? = 0 THEN COALESCE(sold_at, ?) ELSE NULL END,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        availableGross,
        availableLess,
        availableNet,
        availableFine,
        availableWastageFine,
        availableValuationFine,
        status,
        availableQuantity,
        now,
        now,
        unitId,
      ],
    );
  }

  Future<void> _reconcileSaleMovements() async {
    final rows = await _db.customSelect(
      '''
      SELECT
        sm.id AS movement_id,
        bi.gross_weight AS gross_weight,
        bi.net_weight AS net_weight,
        bi.fine_weight AS fine_weight
      FROM stock_movements sm
      INNER JOIN bill_items bi ON bi.linked_stock_item_id = sm.stock_item_id
        AND CAST(bi.bill_id AS TEXT) = sm.source_id
        AND bi.line_no = sm.source_line_no
      INNER JOIN bills b ON b.id = bi.bill_id
      WHERE sm.movement_type = 'SALE'
        AND sm.source_type = 'SALE'
        AND UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
      ''',
    ).get();

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final row in rows) {
      await _db.customStatement(
        '''
        UPDATE stock_movements
        SET gross_weight_delta = ?,
            net_weight_delta = ?,
            fine_weight_delta = ?,
            updated_at = ?
        WHERE id = ?
        ''',
        [
          -_readDouble(row, 'gross_weight'),
          -_readDouble(row, 'net_weight'),
          -_readDouble(row, 'fine_weight'),
          now,
          row.read<int>('movement_id'),
        ],
      );
    }
  }

  double _readDouble(drift.QueryRow row, String column) {
    return row.readNullable<double>(column) ?? 0.0;
  }

  int _positiveInt(int value) => value < 0 ? 0 : value;

  double _positiveDouble(double value) {
    if (value.abs() < 0.000001) return 0.0;
    return value < 0 ? 0.0 : value;
  }
}

final class _StockLotBalance {
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double fineWeight;
  final double wastageFineWeight;
  final double valuationFineWeight;
  final double unitCost;
  final double makingAmount;

  const _StockLotBalance({
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.fineWeight,
    required this.wastageFineWeight,
    required this.valuationFineWeight,
    required this.unitCost,
    required this.makingAmount,
  });
}
