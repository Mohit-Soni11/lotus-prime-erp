import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_activity/stock_activity_models.dart';

const String _activityMetalLabelExpression = '''
CASE
  WHEN LOWER(COALESCE(NULLIF(TRIM(u.metal_type), ''), sm.metal_type_snapshot)) = 'gold' THEN 'Gold'
  WHEN LOWER(COALESCE(NULLIF(TRIM(u.metal_type), ''), sm.metal_type_snapshot)) = 'silver' THEN 'Silver'
  WHEN LOWER(COALESCE(NULLIF(TRIM(u.metal_type), ''), sm.metal_type_snapshot)) = 'diamond' THEN 'Diamond'
  WHEN LOWER(COALESCE(NULLIF(TRIM(u.metal_type), ''), sm.metal_type_snapshot)) = 'platinum' THEN 'Platinum'
  ELSE COALESCE(NULLIF(TRIM(sm.metal_type_snapshot), ''), 'Other')
END
''';

const String _activityGradeLabelExpression = '''
CASE
  WHEN LOWER(COALESCE(NULLIF(TRIM(u.metal_type), ''), sm.metal_type_snapshot)) = 'gold' THEN
    CASE
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 91.6) <= 0.6 THEN '22KT (91.6%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 92.0) <= 0.6 THEN '22KT (91.6%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 75.0) <= 0.6 THEN '18KT (75%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 99.9) <= 0.6 THEN '24KT (99.9%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 58.5) <= 0.6 THEN '14KT (58.5%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 37.5) <= 0.6 THEN '9KT (37.5%)'
      ELSE printf('%.2f%% Gold', COALESCE(u.purity_percent, 0.0))
    END
  WHEN LOWER(COALESCE(NULLIF(TRIM(u.metal_type), ''), sm.metal_type_snapshot)) = 'silver' THEN
    printf('%.0f%% Silver', COALESCE(u.purity_percent, 0.0))
  ELSE printf('%.2f%% Purity', COALESCE(u.purity_percent, 0.0))
END
''';

const String _activityGroupLabelExpression = '''
CASE
  WHEN LOWER(COALESCE(NULLIF(TRIM(u.metal_type), ''), sm.metal_type_snapshot)) = 'gold' THEN
    $_activityGradeLabelExpression
  WHEN LOWER(COALESCE(NULLIF(TRIM(u.metal_type), ''), sm.metal_type_snapshot)) = 'silver' THEN
    COALESCE(
      NULLIF(TRIM(u.item_type), ''),
      NULLIF(TRIM(s.sub_category), ''),
      NULLIF(TRIM(sm.item_name_snapshot), ''),
      'Silver Item'
    )
  ELSE COALESCE(
    NULLIF(TRIM(u.item_type), ''),
    NULLIF(TRIM(s.sub_category), ''),
    NULLIF(TRIM(sm.item_name_snapshot), ''),
    'Stock Item'
  )
END
''';

const String _activityGroupKindExpression = '''
CASE
  WHEN LOWER(COALESCE(NULLIF(TRIM(u.metal_type), ''), sm.metal_type_snapshot)) = 'gold' THEN 'Grade'
  WHEN LOWER(COALESCE(NULLIF(TRIM(u.metal_type), ''), sm.metal_type_snapshot)) = 'silver' THEN 'Item Type'
  ELSE 'Item Type'
END
''';

class StockActivityController extends ChangeNotifier {
  final AppDatabase _db;

  StockActivityController(this._db);

  bool _isLoading = false;
  String _dateFilter = 'All Time';
  String _movementFilter = 'All';
  String _metalFilter = 'All';
  String _searchText = '';
  String? _errorMessage;
  StockActivitySummary _summary = StockActivitySummary.empty();
  List<StockMetalActivitySummary> _metalSummaries = const [];
  List<StockActivityBreakdownSummary> _breakdownSummaries = const [];
  List<StockActivityRecord> _records = const [];

  bool get isLoading => _isLoading;
  String get dateFilter => _dateFilter;
  String get movementFilter => _movementFilter;
  String get metalFilter => _metalFilter;
  String get searchText => _searchText;
  String? get errorMessage => _errorMessage;
  StockActivitySummary get summary => _summary;
  List<StockMetalActivitySummary> get metalSummaries => _metalSummaries;
  List<StockActivityBreakdownSummary> get breakdownSummaries =>
      _breakdownSummaries;
  List<StockActivityRecord> get records => _records;

  static const List<String> dateFilters = [
    'All Time',
    'Today',
    'Yesterday',
    'Last 7 Days',
    'This Month',
  ];

  static const List<String> movementFilters = [
    'All',
    'Stock Added',
    'Sold',
    'Restored',
  ];

  static const List<String> metalFilters = [
    'All',
    'Gold',
    'Silver',
    'Diamond',
    'Platinum',
  ];

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _ensureActivitySchema();
      final where = _buildWhere();
      final metalWhere = _buildWhere(includeMetalFilter: false);
      final summaryRow = await _db.customSelect(
        '''
        SELECT
          COUNT(sm.id) AS total_movements,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'IN' THEN ABS(sm.quantity_delta) ELSE 0 END), 0) AS stock_added,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'SALE' THEN ABS(sm.quantity_delta) ELSE 0 END), 0) AS stock_sold,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'SALE_RESTORE' THEN ABS(sm.quantity_delta) ELSE 0 END), 0) AS stock_restored,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'IN' THEN ABS(sm.net_weight_delta) ELSE 0 END), 0.0) AS added_weight,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'SALE' THEN ABS(sm.net_weight_delta) ELSE 0 END), 0.0) AS sold_weight
        ${_activityFromClause()}
        ${where.sql}
        ''',
        variables: where.variables,
      ).getSingle();

      final metalRows = await _db.customSelect(
        '''
        SELECT
          $_activityMetalLabelExpression AS metal_type,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'IN' THEN ABS(sm.quantity_delta) ELSE 0 END), 0) AS inward_quantity,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'SALE' THEN ABS(sm.quantity_delta) ELSE 0 END), 0) AS outward_quantity,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'SALE_RESTORE' THEN ABS(sm.quantity_delta) ELSE 0 END), 0) AS restored_quantity,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'IN' THEN ABS(sm.net_weight_delta) ELSE 0 END), 0.0) AS inward_weight,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'SALE' THEN ABS(sm.net_weight_delta) ELSE 0 END), 0.0) AS outward_weight,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'SALE_RESTORE' THEN ABS(sm.net_weight_delta) ELSE 0 END), 0.0) AS restored_weight
        ${_activityFromClause()}
        ${metalWhere.sql}
        GROUP BY 1
        ORDER BY inward_quantity DESC, outward_quantity DESC, metal_type ASC
        ''',
        variables: metalWhere.variables,
      ).get();

      final breakdownRows = await _db.customSelect(
        '''
        SELECT
          $_activityMetalLabelExpression AS metal_type,
          $_activityGroupLabelExpression AS group_label,
          $_activityGroupKindExpression AS group_kind,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'IN' THEN ABS(sm.quantity_delta) ELSE 0 END), 0) AS inward_quantity,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'SALE' THEN ABS(sm.quantity_delta) ELSE 0 END), 0) AS outward_quantity,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'SALE_RESTORE' THEN ABS(sm.quantity_delta) ELSE 0 END), 0) AS restored_quantity,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'IN' THEN ABS(sm.net_weight_delta) ELSE 0 END), 0.0) AS inward_weight,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'SALE' THEN ABS(sm.net_weight_delta) ELSE 0 END), 0.0) AS outward_weight,
          COALESCE(SUM(CASE WHEN sm.movement_type = 'SALE_RESTORE' THEN ABS(sm.net_weight_delta) ELSE 0 END), 0.0) AS restored_weight,
          COUNT(DISTINCT $_activityGradeLabelExpression) AS grade_count,
          COUNT(DISTINCT COALESCE(NULLIF(TRIM(u.item_type), ''), NULLIF(TRIM(s.sub_category), ''), NULLIF(TRIM(sm.item_name_snapshot), ''), 'Stock Item')) AS item_type_count,
          COUNT(DISTINCT NULLIF(TRIM(COALESCE(u.company_name, s.company_name, pv.party_name, '')), '')) AS company_count
        ${_activityFromClause()}
        ${where.sql}
        GROUP BY 1, 2, 3
        ORDER BY metal_type ASC, inward_quantity DESC, outward_quantity DESC, group_label ASC
        LIMIT 80
        ''',
        variables: where.variables,
      ).get();

      final rows = await _db.customSelect(
        '''
        SELECT
          sm.id,
          sm.stock_item_id,
          sm.movement_type,
          sm.source_type,
          sm.source_id,
          sm.source_number,
          sm.sku_snapshot,
          sm.metal_type_snapshot,
          sm.item_name_snapshot,
          sm.quantity_delta,
          sm.gross_weight_delta,
          sm.net_weight_delta,
          sm.fine_weight_delta,
          sm.reason,
          sm.occurred_at,
          u.batch_code,
          u.unit_code,
          u.huid,
          u.status AS unit_status,
          pv.party_name AS supplier_name,
          pv.tax_type
        ${_activityFromClause()}
        ${where.sql}
        ORDER BY sm.occurred_at DESC, sm.id DESC
        LIMIT 250
        ''',
        variables: where.variables,
      ).get();

      _summary = StockActivitySummary(
        totalMovements: summaryRow.read<int>('total_movements'),
        stockAdded: summaryRow.read<int>('stock_added'),
        stockSold: summaryRow.read<int>('stock_sold'),
        stockRestored: summaryRow.read<int>('stock_restored'),
        addedWeight: summaryRow.read<double>('added_weight'),
        soldWeight: summaryRow.read<double>('sold_weight'),
      );
      _metalSummaries = metalRows
          .map(StockMetalActivitySummary.fromRow)
          .where((summary) => summary.hasMovement)
          .toList(growable: false);
      _breakdownSummaries = breakdownRows
          .map(StockActivityBreakdownSummary.fromRow)
          .where((summary) => summary.hasMovement)
          .toList(growable: false);
      _records = rows.map(StockActivityRecord.fromRow).toList();
    } catch (error) {
      _summary = StockActivitySummary.empty();
      _metalSummaries = const [];
      _breakdownSummaries = const [];
      _records = const [];
      _errorMessage = 'Stock activity could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setMovementFilter(String value) {
    if (_movementFilter == value) return;
    _movementFilter = value;
    load();
  }

  void setDateFilter(String value) {
    if (_dateFilter == value) return;
    _dateFilter = value;
    load();
  }

  void setMetalFilter(String value) {
    if (_metalFilter == value) return;
    _metalFilter = value;
    load();
  }

  void setSearchText(String value) {
    final normalized = value.trim();
    if (_searchText == normalized) return;
    _searchText = normalized;
    load();
  }

  _StockActivityWhere _buildWhere({bool includeMetalFilter = true}) {
    final clauses = <String>['1 = 1'];
    final variables = <drift.Variable<Object>>[];

    final movementType = _movementTypeForFilter(_movementFilter);
    if (movementType != null) {
      clauses.add('sm.movement_type = ?');
      variables.add(drift.Variable.withString(movementType));
    }

    if (includeMetalFilter && _metalFilter != 'All') {
      clauses.add('LOWER(sm.metal_type_snapshot) = LOWER(?)');
      variables.add(drift.Variable.withString(_metalFilter));
    }

    final dateRange = _dateRangeForFilter(_dateFilter);
    if (dateRange != null) {
      clauses.add('sm.occurred_at >= ?');
      variables
          .add(drift.Variable<int>(dateRange.start.millisecondsSinceEpoch));
      clauses.add('sm.occurred_at < ?');
      variables.add(drift.Variable<int>(dateRange.end.millisecondsSinceEpoch));
    }

    if (_searchText.isNotEmpty) {
      clauses.add('''
        (
          LOWER(sm.source_number) LIKE LOWER(?)
          OR LOWER(sm.sku_snapshot) LIKE LOWER(?)
          OR LOWER(sm.item_name_snapshot) LIKE LOWER(?)
          OR LOWER(COALESCE(u.batch_code, '')) LIKE LOWER(?)
          OR LOWER(COALESCE(u.huid, '')) LIKE LOWER(?)
          OR LOWER(COALESCE(u.unit_code, '')) LIKE LOWER(?)
          OR LOWER(COALESCE(u.item_type, '')) LIKE LOWER(?)
          OR LOWER(COALESCE(s.sub_category, '')) LIKE LOWER(?)
          OR LOWER(COALESCE(u.company_name, s.company_name, '')) LIKE LOWER(?)
          OR LOWER(COALESCE(pv.party_name, '')) LIKE LOWER(?)
        )
      ''');
      final searchValue = '%$_searchText%';
      for (int index = 0; index < 10; index++) {
        variables.add(drift.Variable.withString(searchValue));
      }
    }

    return _StockActivityWhere(
      sql: 'WHERE ${clauses.join(' AND ')}',
      variables: variables,
    );
  }

  String? _movementTypeForFilter(String filter) {
    return switch (filter) {
      'Stock Added' => 'IN',
      'Sold' => 'SALE',
      'Restored' => 'SALE_RESTORE',
      _ => null,
    };
  }

  _StockActivityDateRange? _dateRangeForFilter(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (filter) {
      'Today' => _StockActivityDateRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        ),
      'Yesterday' => _StockActivityDateRange(
          start: today.subtract(const Duration(days: 1)),
          end: today,
        ),
      'Last 7 Days' => _StockActivityDateRange(
          start: today.subtract(const Duration(days: 6)),
          end: today.add(const Duration(days: 1)),
        ),
      'This Month' => _StockActivityDateRange(
          start: DateTime(now.year, now.month),
          end: DateTime(now.year, now.month + 1),
        ),
      _ => null,
    };
  }

  String _activityFromClause() {
    return '''
      FROM stock_movements sm
      LEFT JOIN stock_item_units u ON u.id = (
        SELECT su.id
        FROM stock_item_units su
        WHERE su.stock_item_id = sm.stock_item_id
        ORDER BY su.id ASC
        LIMIT 1
      )
      LEFT JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
      LEFT JOIN stock_items s ON s.id = sm.stock_item_id
    ''';
  }

  Future<void> _ensureActivitySchema() async {
    await _db.ensureStockInventorySchema();
  }
}

class _StockActivityWhere {
  final String sql;
  final List<drift.Variable<Object>> variables;

  const _StockActivityWhere({
    required this.sql,
    required this.variables,
  });
}

class _StockActivityDateRange {
  final DateTime start;
  final DateTime end;

  const _StockActivityDateRange({
    required this.start,
    required this.end,
  });
}
