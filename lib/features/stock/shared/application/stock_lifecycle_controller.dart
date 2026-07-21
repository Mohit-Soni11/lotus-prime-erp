import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_search/stock_search_models.dart';

class StockLifecycleAction {
  final String label;
  final String targetStatus;
  final String reasonHint;
  final bool danger;

  const StockLifecycleAction({
    required this.label,
    required this.targetStatus,
    required this.reasonHint,
    this.danger = false,
  });
}

class StockLifecycleSchema {
  static Future<void> ensure(AppDatabase db) async {
    await db.ensureStockLifecycleSchema();
  }
}

class StockLifecycleController {
  final AppDatabase _db;

  StockLifecycleController(this._db);

  List<StockLifecycleAction> actionsFor(StockSearchResult item) {
    final status = item.status.trim().toLowerCase();
    if (status == 'sold') return const [];
    if (status == 'reserved') {
      return const [
        StockLifecycleAction(
          label: 'Release Reservation',
          targetStatus: 'Available',
          reasonHint: 'Why is this reservation being released?',
        ),
        StockLifecycleAction(
          label: 'Put On Hold',
          targetStatus: 'On Hold',
          reasonHint: 'Why should this reserved stock be kept on hold?',
        ),
        StockLifecycleAction(
          label: 'Mark Damaged',
          targetStatus: 'Damaged',
          reasonHint: 'Describe the damage or correction reason.',
          danger: true,
        ),
      ];
    }
    if (status == 'on hold' || status == 'hold') {
      return const [
        StockLifecycleAction(
          label: 'Release Hold',
          targetStatus: 'Available',
          reasonHint: 'Why is this hold being released?',
        ),
        StockLifecycleAction(
          label: 'Mark Damaged',
          targetStatus: 'Damaged',
          reasonHint: 'Describe the damage or correction reason.',
          danger: true,
        ),
        StockLifecycleAction(
          label: 'Archive Stock',
          targetStatus: 'Archived',
          reasonHint: 'Why should this stock be archived?',
          danger: true,
        ),
      ];
    }
    if (status == 'damaged') {
      return const [
        StockLifecycleAction(
          label: 'Restore To Available',
          targetStatus: 'Available',
          reasonHint: 'Why is this damaged stock ready again?',
        ),
        StockLifecycleAction(
          label: 'Archive Stock',
          targetStatus: 'Archived',
          reasonHint: 'Why should this damaged stock be archived?',
          danger: true,
        ),
      ];
    }
    if (status == 'archived') {
      return const [
        StockLifecycleAction(
          label: 'Restore To Available',
          targetStatus: 'Available',
          reasonHint: 'Why should this archived stock be restored?',
        ),
      ];
    }
    return const [
      StockLifecycleAction(
        label: 'Reserve Stock',
        targetStatus: 'Reserved',
        reasonHint: 'Customer name, order number or reservation note.',
      ),
      StockLifecycleAction(
        label: 'Put On Hold',
        targetStatus: 'On Hold',
        reasonHint: 'Why should this stock be blocked from sale?',
      ),
      StockLifecycleAction(
        label: 'Mark Damaged',
        targetStatus: 'Damaged',
        reasonHint: 'Describe the damage or correction reason.',
        danger: true,
      ),
      StockLifecycleAction(
        label: 'Archive Stock',
        targetStatus: 'Archived',
        reasonHint: 'Why should this stock be archived?',
        danger: true,
      ),
    ];
  }

  Future<void> applyAction({
    required StockSearchResult item,
    required StockLifecycleAction action,
    required String reason,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.length < 3) {
      throw ArgumentError('Reason is required.');
    }
    if (item.isSold) {
      throw StateError('Sold stock can only be changed through sale return.');
    }
    await StockLifecycleSchema.ensure(_db);
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db.customStatement(
        '''
        UPDATE stock_item_units
        SET status = ?, updated_at = ?
        WHERE id = ?
        ''',
        [
          drift.Variable.withString(action.targetStatus),
          drift.Variable.withDateTime(now),
          drift.Variable.withInt(item.id),
        ],
      );

      if (item.stockItemId != null &&
          await _hasSingleUnitForStockItem(item.stockItemId!)) {
        await _db.customStatement(
          '''
          UPDATE stock_items
          SET status = ?, updated_at = ?
          WHERE id = ?
          ''',
          [
            drift.Variable.withString(action.targetStatus),
            drift.Variable.withDateTime(now),
            drift.Variable.withInt(item.stockItemId!),
          ],
        );
      }

      await _db.customStatement(
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
          drift.Variable.withInt(item.id),
          drift.Variable.withInt(item.stockItemId ?? 0),
          drift.Variable.withString(item.unitCode),
          drift.Variable.withString(item.huid),
          drift.Variable.withString(item.inventoryBatchCode),
          drift.Variable.withString(item.status),
          drift.Variable.withString(action.targetStatus),
          drift.Variable.withString(cleanReason),
          drift.Variable.withString('STOCK_STATUS'),
          drift.Variable.withString(action.label),
          drift.Variable.withDateTime(now),
        ],
      );

      if (item.stockItemId != null) {
        await _db.customStatement(
          '''
          INSERT INTO stock_movements (
            stock_item_id,
            movement_type,
            source_type,
            source_id,
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
            created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            drift.Variable.withInt(item.stockItemId!),
            drift.Variable.withString('STATUS_CHANGE'),
            drift.Variable.withString('STOCK_STATUS'),
            drift.Variable.withString(item.id.toString()),
            drift.Variable.withString(action.label),
            drift.Variable.withString(item.unitCode),
            drift.Variable.withString(item.metalType),
            drift.Variable.withString(item.itemName),
            drift.Variable.withInt(0),
            const drift.Variable<double>(0),
            const drift.Variable<double>(0),
            const drift.Variable<double>(0),
            drift.Variable.withString(
              '${item.status} to ${action.targetStatus}: $cleanReason',
            ),
            drift.Variable.withDateTime(now),
            drift.Variable.withDateTime(now),
          ],
        );
      }
    });
  }

  Future<bool> _hasSingleUnitForStockItem(int stockItemId) async {
    final row = await _db.customSelect(
      '''
      SELECT COUNT(*) AS unit_count
      FROM stock_item_units
      WHERE stock_item_id = ?
      ''',
      variables: [drift.Variable.withInt(stockItemId)],
    ).getSingle();
    return ((row.data['unit_count'] as num?)?.toInt() ?? 0) == 1;
  }
}
