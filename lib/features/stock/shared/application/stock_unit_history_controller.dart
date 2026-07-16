import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_lifecycle_controller.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_search/stock_search_models.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_search/stock_unit_history_models.dart';

class StockUnitHistoryController {
  final AppDatabase _db;

  StockUnitHistoryController(this._db);

  Future<List<StockUnitHistoryEvent>> loadFor(StockSearchResult item) async {
    await StockLifecycleSchema.ensure(_db);
    final rows = await _db.customSelect(
      '''
      SELECT
        'IN' AS movement_type,
        'Stock Added' AS title,
        COALESCE(NULLIF(TRIM(u.batch_code), ''), pv.voucher_no, 'Stock Intake') AS source_number,
        COALESCE(NULLIF(TRIM(u.supplier_name), ''), pv.party_name, '') AS party_name,
        1 AS quantity_delta,
        COALESCE(u.gross_weight, 0.0) AS gross_weight_delta,
        COALESCE(u.net_weight, 0.0) AS net_weight_delta,
        COALESCE(u.actual_fine_weight, 0.0) AS fine_weight_delta,
        u.created_at AS occurred_at,
        'Purchase intake recorded in inventory' AS note
      FROM stock_item_units u
      LEFT JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
      WHERE u.id = ?

      UNION ALL

      SELECT
        'SALE' AS movement_type,
        'Sold Through POS' AS title,
        COALESCE(b.bill_no, '') AS source_number,
        COALESCE(b.customer_name, '') AS party_name,
        -ABS(COALESCE(bi.quantity, 1)) AS quantity_delta,
        -ABS(COALESCE(NULLIF(bi.gross_weight, 0.0), unit.gross_weight, 0.0)) AS gross_weight_delta,
        -ABS(COALESCE(NULLIF(bi.net_weight, 0.0), unit.net_weight, 0.0)) AS net_weight_delta,
        -ABS(COALESCE(NULLIF(bi.fine_weight, 0.0), unit.actual_fine_weight, 0.0)) AS fine_weight_delta,
        COALESCE(b.bill_date, unit.sold_at, bi.created_at) AS occurred_at,
        COALESCE(b.payment_status, 'Sale invoice') AS note
      FROM bill_items bi
      INNER JOIN bills b ON b.id = bi.bill_id
      LEFT JOIN stock_item_units unit ON unit.id = ?
      WHERE
        bi.linked_stock_unit_id = ?
        OR (
          TRIM(?) <> ''
          AND LOWER(COALESCE(bi.huid, '')) = LOWER(?)
        )
        OR (
          TRIM(?) <> ''
          AND LOWER(COALESCE(bi.linked_stock_sku, '')) = LOWER(?)
        )

      UNION ALL

      SELECT
        'STATUS_CHANGE' AS movement_type,
        previous_status || ' to ' || new_status AS title,
        COALESCE(source_number, 'Status Update') AS source_number,
        '' AS party_name,
        0 AS quantity_delta,
        0.0 AS gross_weight_delta,
        0.0 AS net_weight_delta,
        0.0 AS fine_weight_delta,
        created_at AS occurred_at,
        reason AS note
      FROM stock_unit_status_events
      WHERE stock_unit_id = ?
      ORDER BY occurred_at ASC
      ''',
      variables: [
        drift.Variable.withInt(item.id),
        drift.Variable.withInt(item.id),
        drift.Variable.withInt(item.id),
        drift.Variable.withString(item.huid.trim()),
        drift.Variable.withString(item.huid.trim()),
        drift.Variable.withString(item.unitCode.trim()),
        drift.Variable.withString(item.unitCode.trim()),
        drift.Variable.withInt(item.id),
      ],
    ).get();

    final events = rows
        .map(StockUnitHistoryEvent.fromRow)
        .where((event) => event.occurredAt != null)
        .toList(growable: false);

    return events;
  }
}
