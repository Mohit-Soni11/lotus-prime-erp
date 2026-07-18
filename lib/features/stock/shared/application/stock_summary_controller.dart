import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_lot_sale_reconciliation_service.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_summary/stock_summary_models.dart';

const String _isLotUnitExpression = '''
LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
  AND TRIM(COALESCE(u.huid, '')) = ''
''';

const String _availableQuantityExpression = '''
CASE
  WHEN LOWER(u.status) = 'available' THEN
    CASE
      WHEN $_isLotUnitExpression THEN COALESCE(NULLIF(s.quantity, 0), 0)
      ELSE 1
    END
  ELSE 0
END
''';

const String _soldQuantityExpression = '''
CASE
  WHEN $_isLotUnitExpression THEN
    CASE
      WHEN LOWER(u.status) = 'sold' THEN COALESCE(NULLIF(pvi.quantity, 0), 1)
      WHEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0) > 0
        THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0)
      ELSE 0
    END
  WHEN LOWER(u.status) = 'sold' THEN 1
  ELSE 0
END
''';

const String _soldWeightExpression = '''
CASE
  WHEN u.id = (
    SELECT MIN(first_unit.id)
    FROM stock_item_units first_unit
    WHERE first_unit.stock_item_id = s.id
  ) THEN
    CASE
      WHEN COALESCE(sm.sold_net_weight, 0) > 0
        THEN COALESCE(sm.sold_net_weight, 0)
      ELSE 0
    END
  ELSE 0
END
''';

const String _soldWeightJoin = '''
LEFT JOIN (
  SELECT
    source.stock_item_id,
    COALESCE(bill_weight.sold_net_weight, movement_weight.sold_net_weight, 0.0) AS sold_net_weight
  FROM (
    SELECT stock_item_id
    FROM stock_movements
    WHERE movement_type IN ('SALE', 'SALE_RESTORE')
    UNION
    SELECT linked_stock_item_id AS stock_item_id
    FROM bill_items
    WHERE linked_stock_item_id IS NOT NULL
  ) source
  LEFT JOIN (
    SELECT
      bi.linked_stock_item_id AS stock_item_id,
      SUM(COALESCE(bi.net_weight, 0.0)) AS sold_net_weight
    FROM bill_items bi
    INNER JOIN bills b ON b.id = bi.bill_id
    WHERE bi.linked_stock_item_id IS NOT NULL
      AND UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
    GROUP BY bi.linked_stock_item_id
  ) bill_weight ON bill_weight.stock_item_id = source.stock_item_id
  LEFT JOIN (
    SELECT
      stock_item_id,
      SUM(
        CASE
          WHEN movement_type = 'SALE' THEN ABS(net_weight_delta)
          WHEN movement_type = 'SALE_RESTORE' THEN -ABS(net_weight_delta)
          ELSE 0
        END
      ) AS sold_net_weight
    FROM stock_movements
    WHERE movement_type IN ('SALE', 'SALE_RESTORE')
    GROUP BY stock_item_id
  ) movement_weight ON movement_weight.stock_item_id = source.stock_item_id
) sm ON sm.stock_item_id = s.id
''';

class StockSummaryController extends ChangeNotifier {
  final AppDatabase _db;

  StockSummaryController(this._db);

  bool _isLoading = false;
  String? _errorMessage;
  StockSummaryOverview _overview = StockSummaryOverview.empty();
  List<StockSummaryMetal> _metals = const [];
  List<StockSummaryGrade> _grades = const [];
  List<StockSummaryMovement> _recentMovements = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StockSummaryOverview get overview => _overview;
  List<StockSummaryMetal> get metals => _metals;
  List<StockSummaryGrade> get grades => _grades;
  List<StockSummaryMovement> get recentMovements => _recentMovements;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await StockLotSaleReconciliationService(_db).reconcile();

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final current = await _loadCurrentSnapshot();
      final today = await _loadTodayMovement(startOfDay, endOfDay);
      final metals = await _loadMetalSummary();
      final grades = await _loadGradeSummary();
      final movements = await _loadRecentMovements();

      final closingUnits = current.availableUnits;
      final closingWeight = current.availableWeight;
      final openingUnits = _positiveInt(
        closingUnits -
            today.inwardUnits -
            today.restoredUnits +
            today.outwardUnits,
      );
      final openingWeight = _positiveDouble(
        closingWeight -
            today.inwardWeight -
            today.restoredWeight +
            today.outwardWeight,
      );

      _overview = StockSummaryOverview(
        openingUnits: openingUnits,
        inwardUnits: today.inwardUnits,
        outwardUnits: today.outwardUnits,
        restoredUnits: today.restoredUnits,
        closingUnits: closingUnits,
        openingWeight: openingWeight,
        inwardWeight: today.inwardWeight,
        outwardWeight: today.outwardWeight,
        restoredWeight: today.restoredWeight,
        closingWeight: closingWeight,
        soldWeight: current.soldWeight,
        totalWeight: closingWeight + current.soldWeight,
        closingFine: current.availableFine,
        soldUnits: current.soldUnits,
      );
      _metals = metals;
      _grades = grades;
      _recentMovements = movements;
    } catch (error) {
      _overview = StockSummaryOverview.empty();
      _metals = const [];
      _grades = const [];
      _recentMovements = const [];
      _errorMessage = 'Stock summary could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<_CurrentSnapshot> _loadCurrentSnapshot() async {
    final row = await _db.customSelect('''
      SELECT
        COALESCE(SUM($_availableQuantityExpression), 0) AS available_units,
        COALESCE(SUM($_soldQuantityExpression), 0) AS sold_units,
        COALESCE(SUM(CASE WHEN LOWER(u.status) = 'available' THEN u.net_weight ELSE 0 END), 0.0) AS available_weight,
        COALESCE(SUM($_soldWeightExpression), 0.0) AS sold_weight,
        COALESCE(SUM(CASE WHEN LOWER(u.status) = 'available' THEN u.actual_fine_weight ELSE 0 END), 0.0) AS available_fine
      FROM stock_item_units u
      LEFT JOIN stock_items s ON s.id = u.stock_item_id
      LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
      $_soldWeightJoin
    ''').getSingle();

    return _CurrentSnapshot(
      availableUnits: _readInt(row, 'available_units'),
      soldUnits: _readInt(row, 'sold_units'),
      availableWeight: _readDouble(row, 'available_weight'),
      soldWeight: _readDouble(row, 'sold_weight'),
      availableFine: _readDouble(row, 'available_fine'),
    );
  }

  Future<_TodayMovement> _loadTodayMovement(
    DateTime startOfDay,
    DateTime endOfDay,
  ) async {
    final row = await _db.customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN movement_type = 'IN' THEN ABS(quantity_delta) ELSE 0 END), 0) AS inward_units,
        COALESCE(SUM(CASE WHEN movement_type = 'SALE' THEN ABS(quantity_delta) ELSE 0 END), 0) AS outward_units,
        COALESCE(SUM(CASE WHEN movement_type = 'SALE_RESTORE' THEN ABS(quantity_delta) ELSE 0 END), 0) AS restored_units,
        COALESCE(SUM(CASE WHEN movement_type = 'IN' THEN ABS(net_weight_delta) ELSE 0 END), 0.0) AS inward_weight,
        COALESCE(SUM(CASE WHEN movement_type = 'SALE' THEN ABS(net_weight_delta) ELSE 0 END), 0.0) AS outward_weight,
        COALESCE(SUM(CASE WHEN movement_type = 'SALE_RESTORE' THEN ABS(net_weight_delta) ELSE 0 END), 0.0) AS restored_weight
      FROM stock_movements
      WHERE occurred_at >= ? AND occurred_at < ?
      ''',
      variables: [
        drift.Variable.withDateTime(startOfDay),
        drift.Variable.withDateTime(endOfDay),
      ],
    ).getSingle();

    return _TodayMovement(
      inwardUnits: _readInt(row, 'inward_units'),
      outwardUnits: _readInt(row, 'outward_units'),
      restoredUnits: _readInt(row, 'restored_units'),
      inwardWeight: _readDouble(row, 'inward_weight'),
      outwardWeight: _readDouble(row, 'outward_weight'),
      restoredWeight: _readDouble(row, 'restored_weight'),
    );
  }

  Future<List<StockSummaryMetal>> _loadMetalSummary() async {
    final rows = await _db.customSelect('''
      SELECT
        CASE
          WHEN LOWER(u.metal_type) = 'gold' THEN 'Gold'
          WHEN LOWER(u.metal_type) = 'silver' THEN 'Silver'
          WHEN LOWER(u.metal_type) = 'diamond' THEN 'Diamond'
          WHEN LOWER(u.metal_type) = 'platinum' THEN 'Platinum'
          ELSE COALESCE(NULLIF(TRIM(u.metal_type), ''), 'Other')
        END AS metal,
        COALESCE(SUM($_availableQuantityExpression), 0) AS available_units,
        COALESCE(SUM($_soldQuantityExpression), 0) AS sold_units,
        COALESCE(SUM(CASE WHEN LOWER(u.status) = 'available' THEN u.gross_weight ELSE 0 END), 0.0) AS gross_weight,
        COALESCE(SUM(CASE WHEN LOWER(u.status) = 'available' THEN u.net_weight ELSE 0 END), 0.0) AS net_weight,
        COALESCE(SUM($_soldWeightExpression), 0.0) AS sold_weight,
        COALESCE(SUM(CASE WHEN LOWER(u.status) = 'available' THEN u.actual_fine_weight ELSE 0 END), 0.0) AS actual_fine
      FROM stock_item_units u
      LEFT JOIN stock_items s ON s.id = u.stock_item_id
      LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
      $_soldWeightJoin
      GROUP BY LOWER(u.metal_type)
      ORDER BY available_units DESC, metal ASC
    ''').get();

    return rows
        .map(
          (row) => StockSummaryMetal(
            metal: _readString(row, 'metal'),
            availableUnits: _readInt(row, 'available_units'),
            soldUnits: _readInt(row, 'sold_units'),
            grossWeight: _readDouble(row, 'gross_weight'),
            netWeight: _readDouble(row, 'net_weight'),
            soldWeight: _readDouble(row, 'sold_weight'),
            totalWeight: _readDouble(row, 'net_weight') +
                _readDouble(row, 'sold_weight'),
            actualFine: _readDouble(row, 'actual_fine'),
          ),
        )
        .where((item) => item.availableUnits > 0 || item.soldUnits > 0)
        .toList(growable: false);
  }

  Future<List<StockSummaryGrade>> _loadGradeSummary() async {
    final rows = await _db.customSelect('''
      SELECT
        CASE
          WHEN LOWER(u.metal_type) = 'gold' THEN 'Gold'
          WHEN LOWER(u.metal_type) = 'silver' THEN 'Silver'
          WHEN LOWER(u.metal_type) = 'diamond' THEN 'Diamond'
          WHEN LOWER(u.metal_type) = 'platinum' THEN 'Platinum'
          ELSE COALESCE(NULLIF(TRIM(u.metal_type), ''), 'Other')
        END AS metal,
        printf('%.0f%% Purity', COALESCE(u.purity_percent, 0.0)) AS grade_label,
        COALESCE(SUM($_availableQuantityExpression), 0) AS available_units,
        COALESCE(SUM($_soldQuantityExpression), 0) AS sold_units,
        COALESCE(SUM(CASE WHEN LOWER(u.status) = 'available' THEN u.net_weight ELSE 0 END), 0.0) AS net_weight,
        COALESCE(SUM($_soldWeightExpression), 0.0) AS sold_weight,
        COALESCE(SUM(CASE WHEN LOWER(u.status) = 'available' THEN u.actual_fine_weight ELSE 0 END), 0.0) AS actual_fine
      FROM stock_item_units u
      LEFT JOIN stock_items s ON s.id = u.stock_item_id
      LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
      $_soldWeightJoin
      GROUP BY LOWER(u.metal_type), ROUND(COALESCE(u.purity_percent, 0.0), 2)
      ORDER BY LOWER(u.metal_type), u.purity_percent DESC
      LIMIT 24
    ''').get();

    return rows
        .map(
          (row) => StockSummaryGrade(
            metal: _readString(row, 'metal'),
            gradeLabel: _readString(row, 'grade_label'),
            availableUnits: _readInt(row, 'available_units'),
            soldUnits: _readInt(row, 'sold_units'),
            netWeight: _readDouble(row, 'net_weight'),
            soldWeight: _readDouble(row, 'sold_weight'),
            totalWeight: _readDouble(row, 'net_weight') +
                _readDouble(row, 'sold_weight'),
            actualFine: _readDouble(row, 'actual_fine'),
          ),
        )
        .where((item) => item.availableUnits > 0 || item.soldUnits > 0)
        .toList(growable: false);
  }

  Future<List<StockSummaryMovement>> _loadRecentMovements() async {
    final rows = await _db.customSelect('''
      SELECT
        movement_type,
        COALESCE(source_number, '') AS source_number,
        COALESCE(metal_type_snapshot, '') AS metal,
        COALESCE(item_name_snapshot, '') AS item_name,
        ABS(quantity_delta) AS quantity,
        ABS(net_weight_delta) AS net_weight,
        occurred_at
      FROM stock_movements
      WHERE movement_type IN ('IN', 'SALE', 'SALE_RESTORE')
      ORDER BY occurred_at DESC, id DESC
      LIMIT 12
    ''').get();

    return rows
        .map(
          (row) => StockSummaryMovement(
            movementType: _readString(row, 'movement_type'),
            sourceNumber: _readString(row, 'source_number'),
            metal: _readString(row, 'metal'),
            itemName: _readString(row, 'item_name'),
            quantity: _readInt(row, 'quantity'),
            netWeight: _readDouble(row, 'net_weight'),
            occurredAt: _readDate(row, 'occurred_at'),
          ),
        )
        .toList(growable: false);
  }

  int _readInt(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is num ? value.toInt() : 0;
  }

  double _readDouble(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is num ? value.toDouble() : 0;
  }

  String _readString(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is String ? value.trim() : '';
  }

  DateTime? _readDate(drift.QueryRow row, String column) {
    final value = row.data[column];
    if (value is DateTime) return value;
    if (value is int && value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  int _positiveInt(int value) => value < 0 ? 0 : value;

  double _positiveDouble(double value) => value < 0 ? 0 : value;
}

class _CurrentSnapshot {
  final int availableUnits;
  final int soldUnits;
  final double availableWeight;
  final double soldWeight;
  final double availableFine;

  const _CurrentSnapshot({
    required this.availableUnits,
    required this.soldUnits,
    required this.availableWeight,
    required this.soldWeight,
    required this.availableFine,
  });
}

class _TodayMovement {
  final int inwardUnits;
  final int outwardUnits;
  final int restoredUnits;
  final double inwardWeight;
  final double outwardWeight;
  final double restoredWeight;

  const _TodayMovement({
    required this.inwardUnits,
    required this.outwardUnits,
    required this.restoredUnits,
    required this.inwardWeight,
    required this.outwardWeight,
    required this.restoredWeight,
  });
}
