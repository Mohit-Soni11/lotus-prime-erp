import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/market_refill/market_refill_models.dart';

const String _refillMetalExpression = '''
CASE
  WHEN LOWER(COALESCE(u.metal_type, m.metal_type_snapshot, s.metal_type, '')) = 'gold' THEN 'Gold'
  WHEN LOWER(COALESCE(u.metal_type, m.metal_type_snapshot, s.metal_type, '')) = 'silver' THEN 'Silver'
  WHEN LOWER(COALESCE(u.metal_type, m.metal_type_snapshot, s.metal_type, '')) = 'diamond' THEN 'Diamond'
  WHEN LOWER(COALESCE(u.metal_type, m.metal_type_snapshot, s.metal_type, '')) = 'platinum' THEN 'Platinum'
  ELSE COALESCE(NULLIF(TRIM(COALESCE(u.metal_type, m.metal_type_snapshot, s.metal_type, '')), ''), 'Other')
END
''';

const String _refillUnitMetalExpression = '''
CASE
  WHEN LOWER(COALESCE(u.metal_type, s.metal_type, '')) = 'gold' THEN 'Gold'
  WHEN LOWER(COALESCE(u.metal_type, s.metal_type, '')) = 'silver' THEN 'Silver'
  WHEN LOWER(COALESCE(u.metal_type, s.metal_type, '')) = 'diamond' THEN 'Diamond'
  WHEN LOWER(COALESCE(u.metal_type, s.metal_type, '')) = 'platinum' THEN 'Platinum'
  ELSE COALESCE(NULLIF(TRIM(COALESCE(u.metal_type, s.metal_type, '')), ''), 'Other')
END
''';

const String _refillGradeExpression = '''
CASE
  WHEN LOWER(COALESCE(u.metal_type, m.metal_type_snapshot, s.metal_type, '')) = 'gold' THEN
    CASE
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 91.6) <= 0.6 THEN '22KT (91.6%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 92.0) <= 0.6 THEN '22KT (91.6%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 75.0) <= 0.6 THEN '18KT (75%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 99.9) <= 0.6 THEN '24KT (99.9%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 58.5) <= 0.6 THEN '14KT (58.5%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 37.5) <= 0.6 THEN '9KT (37.5%)'
      ELSE printf('%.2f%% Gold', COALESCE(u.purity_percent, 0.0))
    END
  WHEN LOWER(COALESCE(u.metal_type, m.metal_type_snapshot, s.metal_type, '')) = 'silver'
    THEN printf('%.0f%% Silver', COALESCE(u.purity_percent, 0.0))
  ELSE printf('%.2f%% Purity', COALESCE(u.purity_percent, 0.0))
END
''';

const String _refillUnitGradeExpression = '''
CASE
  WHEN LOWER(COALESCE(u.metal_type, s.metal_type, '')) = 'gold' THEN
    CASE
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 91.6) <= 0.6 THEN '22KT (91.6%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 92.0) <= 0.6 THEN '22KT (91.6%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 75.0) <= 0.6 THEN '18KT (75%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 99.9) <= 0.6 THEN '24KT (99.9%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 58.5) <= 0.6 THEN '14KT (58.5%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 37.5) <= 0.6 THEN '9KT (37.5%)'
      ELSE printf('%.2f%% Gold', COALESCE(u.purity_percent, 0.0))
    END
  WHEN LOWER(COALESCE(u.metal_type, s.metal_type, '')) = 'silver'
    THEN printf('%.0f%% Silver', COALESCE(u.purity_percent, 0.0))
  ELSE printf('%.2f%% Purity', COALESCE(u.purity_percent, 0.0))
END
''';

const String _refillCompanyExpression = '''
CASE
  WHEN LOWER(COALESCE(u.metal_type, m.metal_type_snapshot, s.metal_type, '')) = 'silver'
    THEN COALESCE(NULLIF(TRIM(COALESCE(u.company_name, s.company_name, '')), ''), 'Company Not Tagged')
  ELSE ''
END
''';

const String _refillUnitCompanyExpression = '''
CASE
  WHEN LOWER(COALESCE(u.metal_type, s.metal_type, '')) = 'silver'
    THEN COALESCE(NULLIF(TRIM(COALESCE(u.company_name, s.company_name, '')), ''), 'Company Not Tagged')
  ELSE ''
END
''';

const String _refillLotUnitExpression = '''
LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
  AND TRIM(COALESCE(u.huid, '')) = ''
''';

const String _refillAvailableQuantityExpression = '''
CASE
  WHEN LOWER(u.status) = 'available' THEN
    CASE
      WHEN $_refillLotUnitExpression THEN COALESCE(NULLIF(s.quantity, 0), 0)
      ELSE 1
    END
  ELSE 0
END
''';

class MarketRefillReportRepository {
  static const Duration _checkoutHistoryRetention = Duration(days: 2);

  final AppDatabase _db;

  MarketRefillReportRepository(this._db);

  Future<MarketRefillReport> loadActiveReport() async {
    await _ensureSchema();
    final lastClearedAt = await _loadLastClearedAt();
    final now = DateTime.now();
    final range = MarketRefillDateRange(
      start: lastClearedAt ?? DateTime(2000),
      end: now.add(const Duration(days: 1)),
      label: 'Active Purchase List',
    );
    final report = await loadReport(range);
    final recentCheckouts = await loadRecentCheckouts();
    return MarketRefillReport(
      range: report.range,
      summary: report.summary,
      metals: report.metals,
      rows: report.rows,
      recentCheckouts: recentCheckouts,
      progressScope: lastClearedAt?.millisecondsSinceEpoch ?? 0,
      lastClearedAt: lastClearedAt,
    );
  }

  Future<MarketRefillReport> loadReport(MarketRefillDateRange range) async {
    await _ensureSchema();
    final soldRows = await _loadSoldRows(range);
    if (soldRows.isEmpty) return MarketRefillReport.empty(range);

    final availableRows = await _loadAvailableRows();
    final availableByKey = {
      for (final row in availableRows) _rowKey(row): row,
    };

    final progressScope =
        range.start.year <= 2000 ? 0 : range.start.millisecondsSinceEpoch;
    final progressByKey = await _loadLineProgress(progressScope);

    final rows = soldRows.map((sold) {
      final available = availableByKey[_rowKey(sold)];
      final soldQuantity = _positiveInt(_readInt(sold, 'sold_quantity'));
      final availableQuantity =
          _positiveInt(_readIntOrZero(available, 'available_quantity'));
      final soldWeight = _positiveDouble(_readDouble(sold, 'sold_weight'));
      final availableWeight =
          _positiveDouble(_readDoubleOrZero(available, 'available_weight'));
      final metal = _readString(sold, 'metal');
      final gradeLabel = _readString(sold, 'grade_label');
      final companyName = _readString(sold, 'company_name');
      final itemType = _titleCase(_readString(sold, 'item_type'));
      final unitLabel = _unitLabel(
        _readString(sold, 'quantity_mode'),
        _readString(sold, 'item_type'),
      );
      final rowKey = _itemRowKey(
        metal: metal,
        gradeLabel: gradeLabel,
        companyName: companyName,
        itemType: itemType,
        unitLabel: unitLabel,
      );
      final progress = progressByKey[rowKey];

      return MarketRefillItemRow(
        rowKey: rowKey,
        metal: metal,
        gradeLabel: gradeLabel,
        companyName: companyName,
        itemType: itemType,
        unitLabel: unitLabel,
        soldQuantity: soldQuantity,
        availableQuantity: availableQuantity,
        refillQuantity: soldQuantity,
        soldNetWeight: soldWeight,
        availableNetWeight: availableWeight,
        billCount: _readInt(sold, 'bill_count'),
        latestInvoice: _readString(sold, 'latest_invoice'),
        lastSoldAt: _readDate(sold, 'last_sold_at'),
        companyNames: _readCsv(sold, 'company_names'),
        itemNames: _readCsv(sold, 'item_names'),
        boughtQuantity: progress?.boughtQuantity ?? soldQuantity,
        purchaseDone: progress?.purchaseDone ?? false,
      );
    }).toList(growable: false)
      ..sort((a, b) {
        final metalCompare = a.metal.compareTo(b.metal);
        if (metalCompare != 0) return metalCompare;
        final groupCompare = _sortGroup(a).compareTo(_sortGroup(b));
        if (groupCompare != 0) return groupCompare;
        final refillCompare = b.refillQuantity.compareTo(a.refillQuantity);
        if (refillCompare != 0) return refillCompare;
        return a.title.compareTo(b.title);
      });

    return MarketRefillReport(
      range: range,
      summary: _buildSummary(rows),
      metals: _buildMetalSummary(rows),
      rows: rows,
      progressScope: progressScope,
    );
  }

  Future<List<MarketRefillCheckoutRecord>> loadRecentCheckouts({
    int limit = 5,
  }) async {
    await _ensureSchema();
    final rows = await _db.customSelect(
      '''
      SELECT
        id,
        checkout_no,
        checked_out_at,
        sold_quantity,
        item_groups,
        metal_groups,
        sold_net_weight
      FROM market_refill_checkout_history
      ORDER BY checked_out_at DESC, id DESC
      LIMIT ?
      ''',
      variables: [drift.Variable<int>(limit)],
    ).get();
    return rows.map(_mapCheckoutRecord).toList(growable: false);
  }

  String buildCsv(MarketRefillReport report) {
    final lines = <List<String>>[
      [
        'Metal',
        'Grade',
        'Company',
        'Item Type',
        'Unit',
        'Sold Qty',
        'Available Qty',
        'Refill Qty',
        'Bought Qty',
        'Done',
        'Sold Net Weight',
        'Available Net Weight',
        'Companies',
        'Item Names',
        'Bill Count',
        'Latest Invoice',
        'Last Sold At',
        'Status',
      ],
      for (final row in report.rows)
        [
          row.metal,
          row.gradeLabel,
          row.companyLabel,
          row.title,
          row.unitLabel,
          row.soldQuantity.toString(),
          row.availableQuantity.toString(),
          row.refillQuantity.toString(),
          row.boughtQuantity.toString(),
          row.purchaseDone ? 'Yes' : 'No',
          row.soldNetWeight.toStringAsFixed(3),
          row.availableNetWeight.toStringAsFixed(3),
          row.companyNames.join(' | '),
          row.itemNames.join(' | '),
          row.billCount.toString(),
          row.latestInvoice,
          row.lastSoldAt?.toIso8601String() ?? '',
          row.statusLabel,
        ],
    ];
    return lines.map((line) => line.map(_csvCell).join(',')).join('\n');
  }

  Future<void> saveLineProgress({
    required int progressScope,
    required String rowKey,
    required int boughtQuantity,
    required bool purchaseDone,
  }) async {
    await _ensureSchema();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement(
      '''
      INSERT INTO market_refill_line_progress (
        progress_scope,
        row_key,
        bought_quantity,
        is_checked,
        updated_at
      ) VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(progress_scope, row_key) DO UPDATE SET
        bought_quantity = excluded.bought_quantity,
        is_checked = excluded.is_checked,
        updated_at = excluded.updated_at
      ''',
      [
        progressScope,
        rowKey,
        boughtQuantity < 0 ? 0 : boughtQuantity,
        purchaseDone ? 1 : 0,
        now,
      ],
    );
  }

  Future<void> checkoutAndClear({MarketRefillReport? report}) async {
    await _ensureSchema();
    final snapshot = report ?? await loadActiveReport();
    final nowDate = DateTime.now();
    final now = nowDate.millisecondsSinceEpoch;
    await _db.transaction(() async {
      if (snapshot.rows.isNotEmpty) {
        final checkoutNo = await _nextCheckoutNo(nowDate);
        await _db.customStatement(
          '''
          INSERT INTO market_refill_checkout_history (
            checkout_no,
            checked_out_at,
            cleared_until,
            sold_quantity,
            item_groups,
            metal_groups,
            sold_net_weight
          ) VALUES (?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            checkoutNo,
            now,
            now,
            snapshot.summary.soldQuantity,
            snapshot.summary.itemGroups,
            snapshot.summary.metalGroups,
            snapshot.summary.soldNetWeight,
          ],
        );
        final checkoutId = await _lastInsertId();
        for (final row in snapshot.rows) {
          await _insertCheckoutLine(checkoutId: checkoutId, row: row);
        }
      }

      await _db.customStatement(
        '''
        INSERT INTO market_refill_report_state (id, cleared_until, updated_at)
        VALUES (1, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          cleared_until = excluded.cleared_until,
          updated_at = excluded.updated_at
        ''',
        [now, now],
      );
    });
  }

  Future<void> restoreClearedList() async {
    await _ensureSchema();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement(
      '''
      INSERT INTO market_refill_report_state (id, cleared_until, updated_at)
      VALUES (1, 0, ?)
      ON CONFLICT(id) DO UPDATE SET
        cleared_until = 0,
        updated_at = excluded.updated_at
      ''',
      [now],
    );
  }

  Future<List<drift.QueryRow>> _loadSoldRows(
    MarketRefillDateRange range,
  ) {
    return _db.customSelect(
      '''
      SELECT
        $_refillMetalExpression AS metal,
        $_refillGradeExpression AS grade_label,
        $_refillCompanyExpression AS company_name,
        COALESCE(
          NULLIF(TRIM(u.item_type), ''),
          NULLIF(TRIM(s.sub_category), ''),
          NULLIF(TRIM(m.item_name_snapshot), ''),
          'General'
        ) AS item_type,
        COALESCE(NULLIF(TRIM(COALESCE(s.quantity_mode, '')), ''), 'PIECES') AS quantity_mode,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(COALESCE(u.company_name, s.company_name, '')), '')) AS company_names,
        GROUP_CONCAT(DISTINCT NULLIF(TRIM(COALESCE(u.item_name, s.item_name, m.item_name_snapshot, '')), '')) AS item_names,
        COALESCE(SUM(
          CASE
            WHEN m.movement_type = 'SALE' THEN ABS(m.quantity_delta)
            WHEN m.movement_type = 'SALE_RESTORE' THEN -ABS(m.quantity_delta)
            ELSE 0
          END
        ), 0) AS sold_quantity,
        COALESCE(SUM(
          CASE
            WHEN m.movement_type = 'SALE' THEN ABS(m.net_weight_delta)
            WHEN m.movement_type = 'SALE_RESTORE' THEN -ABS(m.net_weight_delta)
            ELSE 0
          END
        ), 0.0) AS sold_weight,
        COUNT(DISTINCT NULLIF(TRIM(COALESCE(m.source_number, '')), '')) AS bill_count,
        COALESCE(
          (
            SELECT sm.source_number
            FROM stock_movements sm
            WHERE sm.stock_item_id = m.stock_item_id
              AND sm.movement_type = 'SALE'
              AND sm.occurred_at >= ? AND sm.occurred_at < ?
            ORDER BY sm.occurred_at DESC, sm.id DESC
            LIMIT 1
          ),
          ''
        ) AS latest_invoice,
        MAX(m.occurred_at) AS last_sold_at
      FROM stock_movements m
      LEFT JOIN stock_items s ON s.id = m.stock_item_id
      LEFT JOIN stock_item_units u ON u.id = (
        SELECT MIN(first_unit.id)
        FROM stock_item_units first_unit
        WHERE first_unit.stock_item_id = m.stock_item_id
      )
      WHERE m.movement_type IN ('SALE', 'SALE_RESTORE')
        AND m.occurred_at >= ? AND m.occurred_at < ?
      GROUP BY
        1,
        2,
        3,
        LOWER(COALESCE(NULLIF(TRIM(u.item_type), ''), NULLIF(TRIM(s.sub_category), ''), NULLIF(TRIM(m.item_name_snapshot), ''), 'general')),
        LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), 'pieces'))
      HAVING sold_quantity > 0 OR sold_weight > 0.001
      ORDER BY metal ASC, sold_quantity DESC, sold_weight DESC, item_type ASC
      ''',
      variables: [
        drift.Variable<int>(range.start.millisecondsSinceEpoch),
        drift.Variable<int>(range.end.millisecondsSinceEpoch),
        drift.Variable<int>(range.start.millisecondsSinceEpoch),
        drift.Variable<int>(range.end.millisecondsSinceEpoch),
      ],
    ).get();
  }

  Future<List<drift.QueryRow>> _loadAvailableRows() {
    return _db.customSelect('''
      SELECT
        $_refillUnitMetalExpression AS metal,
        $_refillUnitGradeExpression AS grade_label,
        $_refillUnitCompanyExpression AS company_name,
        COALESCE(
          NULLIF(TRIM(u.item_type), ''),
          NULLIF(TRIM(s.sub_category), ''),
          NULLIF(TRIM(u.item_name), ''),
          'General'
        ) AS item_type,
        COALESCE(NULLIF(TRIM(COALESCE(s.quantity_mode, '')), ''), 'PIECES') AS quantity_mode,
        COALESCE(SUM($_refillAvailableQuantityExpression), 0) AS available_quantity,
        COALESCE(SUM(CASE WHEN LOWER(u.status) = 'available' THEN u.net_weight ELSE 0 END), 0.0) AS available_weight
      FROM stock_item_units u
      LEFT JOIN stock_items s ON s.id = u.stock_item_id
      GROUP BY
        1,
        2,
        3,
        LOWER(COALESCE(NULLIF(TRIM(u.item_type), ''), NULLIF(TRIM(s.sub_category), ''), NULLIF(TRIM(u.item_name), ''), 'general')),
        LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), 'pieces'))
      HAVING available_quantity > 0 OR available_weight > 0.001
    ''').get();
  }

  Future<Map<String, MarketRefillLineProgress>> _loadLineProgress(
    int progressScope,
  ) async {
    final rows = await _db.customSelect(
      '''
      SELECT row_key, bought_quantity, is_checked
      FROM market_refill_line_progress
      WHERE progress_scope = ?
      ''',
      variables: [drift.Variable<int>(progressScope)],
    ).get();
    return {
      for (final row in rows)
        _readString(row, 'row_key'): MarketRefillLineProgress(
          rowKey: _readString(row, 'row_key'),
          boughtQuantity: _positiveInt(_readInt(row, 'bought_quantity')),
          purchaseDone: _readInt(row, 'is_checked') == 1,
        ),
    };
  }

  MarketRefillSummary _buildSummary(List<MarketRefillItemRow> rows) {
    return MarketRefillSummary(
      soldQuantity: rows.fold(0, (sum, row) => sum + row.soldQuantity),
      availableQuantity:
          rows.fold(0, (sum, row) => sum + row.availableQuantity),
      refillQuantity: rows.fold(0, (sum, row) => sum + row.refillQuantity),
      itemGroups: rows.length,
      metalGroups: rows.map((row) => row.metal.toLowerCase()).toSet().length,
      soldNetWeight: rows.fold(0, (sum, row) => sum + row.soldNetWeight),
      availableNetWeight:
          rows.fold(0, (sum, row) => sum + row.availableNetWeight),
    );
  }

  List<MarketRefillMetalSummary> _buildMetalSummary(
    List<MarketRefillItemRow> rows,
  ) {
    final groups = <String, List<MarketRefillItemRow>>{};
    for (final row in rows) {
      groups.putIfAbsent(row.metal, () => []).add(row);
    }
    return groups.entries.map((entry) {
      final metalRows = entry.value;
      return MarketRefillMetalSummary(
        metal: entry.key,
        soldQuantity: metalRows.fold(0, (sum, row) => sum + row.soldQuantity),
        availableQuantity:
            metalRows.fold(0, (sum, row) => sum + row.availableQuantity),
        refillQuantity:
            metalRows.fold(0, (sum, row) => sum + row.refillQuantity),
        itemGroups: metalRows.length,
        soldNetWeight: metalRows.fold(0, (sum, row) => sum + row.soldNetWeight),
        availableNetWeight:
            metalRows.fold(0, (sum, row) => sum + row.availableNetWeight),
      );
    }).toList(growable: false)
      ..sort((a, b) => a.metal.compareTo(b.metal));
  }

  Future<String> _nextCheckoutNo(DateTime now) async {
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final row = await _db.customSelect(
      '''
      SELECT COUNT(*) AS count
      FROM market_refill_checkout_history
      WHERE checked_out_at >= ? AND checked_out_at < ?
      ''',
      variables: [
        drift.Variable<int>(dayStart.millisecondsSinceEpoch),
        drift.Variable<int>(dayEnd.millisecondsSinceEpoch),
      ],
    ).getSingle();
    final sequence = _readInt(row, 'count') + 1;
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'MPL-$y$m$d-${sequence.toString().padLeft(3, '0')}';
  }

  Future<int> _lastInsertId() async {
    final row =
        await _db.customSelect('SELECT last_insert_rowid() AS id').getSingle();
    return _readInt(row, 'id');
  }

  Future<void> _insertCheckoutLine({
    required int checkoutId,
    required MarketRefillItemRow row,
  }) {
    return _db.customStatement(
      '''
      INSERT INTO market_refill_checkout_lines (
        checkout_id,
        row_key,
        metal,
        grade_label,
        company_name,
        item_type,
        unit_label,
        sold_quantity,
        bought_quantity,
        is_checked,
        sold_net_weight,
        last_sold_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        checkoutId,
        row.rowKey,
        row.metal,
        row.gradeLabel,
        row.companyLabel,
        row.title,
        row.unitLabel,
        row.soldQuantity,
        row.boughtQuantity,
        row.purchaseDone ? 1 : 0,
        row.soldNetWeight,
        row.lastSoldAt?.millisecondsSinceEpoch,
      ],
    );
  }

  MarketRefillCheckoutRecord _mapCheckoutRecord(drift.QueryRow row) {
    return MarketRefillCheckoutRecord(
      id: _readInt(row, 'id'),
      checkoutNo: _readString(row, 'checkout_no'),
      checkedOutAt: _readDate(row, 'checked_out_at') ?? DateTime(2000),
      soldQuantity: _readInt(row, 'sold_quantity'),
      itemGroups: _readInt(row, 'item_groups'),
      metalGroups: _readInt(row, 'metal_groups'),
      soldNetWeight: _readDouble(row, 'sold_net_weight'),
    );
  }

  String _rowKey(drift.QueryRow row) {
    final metal = _readString(row, 'metal').toLowerCase();
    final grade = _readString(row, 'grade_label').toLowerCase();
    final company = _readString(row, 'company_name').toLowerCase();
    final itemType = _readString(row, 'item_type').toLowerCase();
    final quantityMode = _readString(row, 'quantity_mode').toLowerCase();
    return '$metal|$grade|$company|$itemType|${_unitLabel(quantityMode, itemType)}';
  }

  String _itemRowKey({
    required String metal,
    required String gradeLabel,
    required String companyName,
    required String itemType,
    required String unitLabel,
  }) {
    String normalize(String value) => value.trim().toLowerCase();
    return [
      normalize(metal),
      normalize(gradeLabel),
      normalize(companyName),
      normalize(itemType),
      normalize(unitLabel),
    ].join('|');
  }

  String _unitLabel(String quantityMode, String itemType) {
    final mode = quantityMode.trim().toLowerCase();
    final item = itemType.trim().toLowerCase();
    if (mode.contains('packet') || mode == 'pack') return 'packet';
    if (mode.contains('set')) return 'set';
    if (mode.contains('pair')) return 'pair';
    if (mode.contains('bulk')) return 'bulk';
    if (item.contains('payal') ||
        item.contains('bichhiya') ||
        item.contains('bali') ||
        item.contains('jhumka') ||
        item.contains('earring') ||
        item.contains('tops')) {
      return 'pair';
    }
    return 'pcs';
  }

  Future<void> _ensureSchema() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS market_refill_report_state (
        id INTEGER NOT NULL PRIMARY KEY,
        cleared_until INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER
      )
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS market_refill_line_progress (
        progress_scope INTEGER NOT NULL DEFAULT 0,
        row_key TEXT NOT NULL,
        bought_quantity INTEGER NOT NULL DEFAULT 0,
        is_checked INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (progress_scope, row_key)
      )
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS market_refill_checkout_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        checkout_no TEXT NOT NULL UNIQUE,
        checked_out_at INTEGER NOT NULL,
        cleared_until INTEGER NOT NULL,
        sold_quantity INTEGER NOT NULL DEFAULT 0,
        item_groups INTEGER NOT NULL DEFAULT 0,
        metal_groups INTEGER NOT NULL DEFAULT 0,
        sold_net_weight REAL NOT NULL DEFAULT 0
      )
    ''');
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS market_refill_checkout_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        checkout_id INTEGER NOT NULL,
        row_key TEXT NOT NULL,
        metal TEXT NOT NULL,
        grade_label TEXT,
        company_name TEXT,
        item_type TEXT NOT NULL,
        unit_label TEXT NOT NULL,
        sold_quantity INTEGER NOT NULL DEFAULT 0,
        bought_quantity INTEGER NOT NULL DEFAULT 0,
        is_checked INTEGER NOT NULL DEFAULT 0,
        sold_net_weight REAL NOT NULL DEFAULT 0,
        last_sold_at INTEGER,
        FOREIGN KEY (checkout_id) REFERENCES market_refill_checkout_history(id)
      )
    ''');
    final itemColumns = await _tableColumns('stock_items');
    if (!itemColumns.contains('company_name')) {
      await _db.customStatement(
        'ALTER TABLE stock_items ADD COLUMN company_name TEXT',
      );
    }
    if (!itemColumns.contains('quantity_mode')) {
      await _db.customStatement(
        "ALTER TABLE stock_items ADD COLUMN quantity_mode TEXT NOT NULL DEFAULT 'PIECES'",
      );
    }
    final unitColumns = await _tableColumns('stock_item_units');
    if (!unitColumns.contains('item_type')) {
      await _db.customStatement(
        'ALTER TABLE stock_item_units ADD COLUMN item_type TEXT',
      );
    }
    if (!unitColumns.contains('company_name')) {
      await _db.customStatement(
        'ALTER TABLE stock_item_units ADD COLUMN company_name TEXT',
      );
    }
    if (!unitColumns.contains('segment')) {
      await _db.customStatement(
        'ALTER TABLE stock_item_units ADD COLUMN segment TEXT',
      );
    }
    await _purgeExpiredCheckoutHistory();
  }

  Future<void> _purgeExpiredCheckoutHistory() async {
    final cutoff = DateTime.now()
        .subtract(_checkoutHistoryRetention)
        .millisecondsSinceEpoch;
    final rows = await _db.customSelect(
      '''
      SELECT id
      FROM market_refill_checkout_history
      WHERE checked_out_at < ?
      ''',
      variables: [drift.Variable<int>(cutoff)],
    ).get();
    final ids = rows
        .map((row) => _readInt(row, 'id'))
        .where((id) => id > 0)
        .toList(growable: false);
    if (ids.isEmpty) return;

    final placeholders = List.filled(ids.length, '?').join(', ');
    await _db.transaction(() async {
      await _db.customStatement(
        'DELETE FROM market_refill_checkout_lines WHERE checkout_id IN ($placeholders)',
        ids,
      );
      await _db.customStatement(
        'DELETE FROM market_refill_checkout_history WHERE id IN ($placeholders)',
        ids,
      );
    });
  }

  Future<DateTime?> _loadLastClearedAt() async {
    final row = await _db
        .customSelect(
          'SELECT cleared_until FROM market_refill_report_state WHERE id = 1',
        )
        .getSingleOrNull();
    if (row == null) return null;
    final value = row.data['cleared_until'];
    if (value is! num || value <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }

  Future<Set<String>> _tableColumns(String tableName) async {
    final rows = await _db.customSelect('PRAGMA table_info($tableName)').get();
    return rows
        .map((row) => row.data['name'])
        .whereType<String>()
        .map((name) => name.toLowerCase())
        .toSet();
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('\n') ||
        escaped.contains('"')) {
      return '"$escaped"';
    }
    return escaped;
  }

  int _readInt(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is num ? value.toInt() : 0;
  }

  int _readIntOrZero(drift.QueryRow? row, String column) {
    if (row == null) return 0;
    return _readInt(row, column);
  }

  double _readDouble(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is num ? value.toDouble() : 0;
  }

  double _readDoubleOrZero(drift.QueryRow? row, String column) {
    if (row == null) return 0;
    return _readDouble(row, column);
  }

  String _readString(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is String ? value.trim() : '';
  }

  List<String> _readCsv(drift.QueryRow row, String column) {
    final value = row.data[column];
    if (value is! String || value.trim().isEmpty) return const [];
    final seen = <String>{};
    final values = <String>[];
    for (final part in value.split(',')) {
      final clean = part.trim();
      if (clean.isEmpty || !seen.add(clean.toLowerCase())) continue;
      values.add(clean);
    }
    return values;
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

  String _sortGroup(MarketRefillItemRow row) {
    if (row.metal.toLowerCase() == 'silver') return row.companyLabel;
    return row.gradeLabel;
  }

  String _titleCase(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'General';
    return text.split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      if (word.length == 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
