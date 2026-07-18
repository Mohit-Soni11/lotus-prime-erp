import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart';

final class StockLotSaleReconciliationService {
  final AppDatabase _db;

  StockLotSaleReconciliationService(this._db);

  Future<void> reconcile() async {
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
    final originalWastageFine = _readDouble(row, 'original_wastage_fine_weight');
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
