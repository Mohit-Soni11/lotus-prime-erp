import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';

import '../../../helpers/search/fuzzy_search_helper.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_item/stock_enums.dart'
    as stock;

class PosStockLookupRepository {
  final AppDatabase _db;

  PosStockLookupRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<List<PosStockLookupModel>> searchByDescription({
    required String query,
    required MetalType metal,
    String purityLabel = '',
    int limit = 8,
  }) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) {
      return const [];
    }

    final unitRows = await _availableUnitsForMetal(metal);
    if (unitRows.isEmpty) {
      return const [];
    }

    final matches = term.length == 1
        ? unitRows.where((row) => _startsWithItemText(row, term)).toList()
        : FuzzySearchHelper.searchObjects(
            items: unitRows,
            query: term,
            getSearchText: _descriptionSearchText,
            maxResults: limit,
            threshold: 0.25,
          );
    matches.sort(
      (a, b) => _rankDescriptionMatch(a, term).compareTo(
        _rankDescriptionMatch(b, term),
      ),
    );

    return _toLookupModels(matches, unitRows, limit);
  }

  Future<List<PosStockLookupModel>> searchByHuid({
    required String query,
    required MetalType metal,
    String purityLabel = '',
    int limit = 6,
  }) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) {
      return const [];
    }

    final unitRows = await _availableUnitsForMetal(metal);
    final matches = unitRows.where((row) {
      final huid = row.huid.toLowerCase();
      final unitCode = row.unitCode.toLowerCase();
      return huid.contains(term) || unitCode.contains(term);
    }).toList();

    matches.sort(
      (a, b) => _rankHuidMatch(a, term).compareTo(_rankHuidMatch(b, term)),
    );
    return _toLookupModels(matches, unitRows, limit);
  }

  Future<PosStockLookupModel?> findExactByHuid({
    required String query,
    required MetalType metal,
    String purityLabel = '',
  }) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) {
      return null;
    }

    final unitRows = await _availableUnitsForMetal(metal);
    for (final row in unitRows) {
      final huid = row.huid.trim().toLowerCase();
      final unitCode = row.unitCode.trim().toLowerCase();
      if (huid == term || unitCode == term) {
        return _toLookupModel(
          row,
          _stockItemGroupRows(row, unitRows),
        );
      }
    }
    return null;
  }

  Future<List<_StockUnitLookupRow>> _availableUnitsForMetal(
    MetalType metal,
  ) async {
    await _ensureStockItemUnitSchema();
    final rows = await _db.customSelect(
      '''
      SELECT
        u.id AS stock_unit_id,
        u.stock_item_id AS stock_item_id,
        u.unit_code AS unit_code,
        u.batch_code AS batch_code,
        u.metal_type AS metal_type,
        u.item_type AS item_type,
        u.segment AS segment,
        u.item_name AS item_name,
        u.huid AS huid,
        u.gross_weight AS gross_weight,
        u.less_weight AS less_weight,
        u.net_weight AS net_weight,
        u.purity_percent AS purity_percent,
        u.unit_cost AS unit_cost,
        u.status AS unit_status,
        u.supplier_name AS company_name,
        s.purity AS purity_label,
        s.category AS category,
        s.description AS description
      FROM stock_item_units u
      INNER JOIN stock_items s ON s.id = u.stock_item_id
      WHERE u.status = ?
        AND s.is_active = 1
        AND s.status = ?
        AND lower(u.metal_type) = ?
      ORDER BY u.created_at DESC, u.id DESC
      LIMIT 300
      ''',
      variables: [
        Variable.withString(stock.StockStatus.available.label),
        Variable.withString(stock.StockStatus.available.label),
        Variable.withString(metal.displayName.toLowerCase()),
      ],
    ).get();

    return rows.map(_StockUnitLookupRow.fromRow).toList(growable: false);
  }

  Future<void> _ensureStockItemUnitSchema() async {
    await _db.customStatement(_createStockItemUnitsTableSql);
    for (final statement in _stockItemUnitsIndexSql) {
      await _db.customStatement(statement);
    }
  }

  String _descriptionSearchText(_StockUnitLookupRow row) {
    return [
      row.itemName,
      row.itemType,
      row.segment,
      row.companyName,
      row.huid,
      row.unitCode,
      row.batchCode,
      row.netWeight.toStringAsFixed(3),
      row.grossWeight.toStringAsFixed(3),
    ].join(' ').toLowerCase();
  }

  bool _startsWithItemText(_StockUnitLookupRow row, String term) {
    return row.itemName.trim().toLowerCase().startsWith(term) ||
        row.itemType.trim().toLowerCase().startsWith(term);
  }

  int _rankDescriptionMatch(_StockUnitLookupRow row, String term) {
    final itemName = row.itemName.trim().toLowerCase();
    final itemType = row.itemType.trim().toLowerCase();
    final segment = row.segment.trim().toLowerCase();
    final huid = row.huid.trim().toLowerCase();
    final unitCode = row.unitCode.trim().toLowerCase();
    if (itemName == term || itemType == term) return 0;
    if (itemName.startsWith(term)) return 1;
    if (itemType.startsWith(term)) return 2;
    if (segment.startsWith(term)) return 3;
    if (itemName.contains(term) || itemType.contains(term)) return 4;
    if (huid.startsWith(term) || unitCode.startsWith(term)) return 5;
    return 6;
  }

  int _rankHuidMatch(_StockUnitLookupRow row, String term) {
    final huid = row.huid.trim().toLowerCase();
    final unitCode = row.unitCode.trim().toLowerCase();
    if (huid == term || unitCode == term) {
      return 0;
    }
    if (huid.startsWith(term) || unitCode.startsWith(term)) {
      return 1;
    }
    return 2;
  }

  List<PosStockLookupModel> _toLookupModels(
    List<_StockUnitLookupRow> matches,
    List<_StockUnitLookupRow> allRows,
    int limit,
  ) {
    final results = <PosStockLookupModel>[];
    final groupedStockItems = <int>{};
    final singleUnits = <int>{};

    for (final row in matches) {
      final groupRows = _stockItemGroupRows(row, allRows);
      if (_shouldSellAsSet(row, groupRows)) {
        if (!groupedStockItems.add(row.stockItemId)) {
          continue;
        }
        results.add(_toLookupModel(row, groupRows));
      } else {
        if (!singleUnits.add(row.stockUnitId)) {
          continue;
        }
        results.add(_toLookupModel(row, [row]));
      }
      if (results.length >= limit) {
        break;
      }
    }

    return results;
  }

  List<_StockUnitLookupRow> _stockItemGroupRows(
    _StockUnitLookupRow row,
    List<_StockUnitLookupRow> allRows,
  ) {
    return allRows
        .where((candidate) => candidate.stockItemId == row.stockItemId)
        .toList(growable: false);
  }

  bool _shouldSellAsSet(
    _StockUnitLookupRow row,
    List<_StockUnitLookupRow> groupRows,
  ) {
    if (groupRows.length <= 1) {
      return false;
    }
    final text = [
      row.itemType,
      row.itemName,
      row.category,
      row.description,
    ].join(' ').toLowerCase();
    return text.contains('jhumka') ||
        text.contains('earring') ||
        text.contains('tops') ||
        text.contains('pair') ||
        text.contains('set');
  }

  PosStockLookupModel _toLookupModel(
    _StockUnitLookupRow row,
    List<_StockUnitLookupRow> groupRows,
  ) {
    final sellAsSet = _shouldSellAsSet(row, groupRows);
    final effectiveRows = sellAsSet ? groupRows : [row];
    final huids = effectiveRows
        .map((unit) => unit.huid.trim())
        .where((huid) => huid.isNotEmpty)
        .toList(growable: false);

    return PosStockLookupModel(
      stockItemId: row.stockItemId,
      stockUnitId: row.stockUnitId,
      sku: row.unitCode,
      itemName: row.itemName,
      description: row.description,
      huid: huids.isEmpty ? null : huids.first,
      huids: huids,
      purity: row.purityLabel,
      metal: _metalFromUnitRow(row),
      categoryLabel: row.itemType.isEmpty ? row.category : row.itemType,
      segmentLabel: row.segment,
      companyName: row.companyName,
      grossWeight:
          effectiveRows.fold(0.0, (sum, unit) => sum + unit.grossWeight),
      lessWeight: effectiveRows.fold(0.0, (sum, unit) => sum + unit.lessWeight),
      netWeight: effectiveRows.fold(0.0, (sum, unit) => sum + unit.netWeight),
      unitCost: effectiveRows.fold(0.0, (sum, unit) => sum + unit.unitCost),
      quantity: effectiveRows.length,
      status: row.status,
    );
  }

  MetalType _metalFromUnitRow(_StockUnitLookupRow row) {
    final value = row.metalType.trim().toLowerCase();
    if (value == 'gold') return MetalType.gold;
    if (value == 'silver') return MetalType.silver;
    if (value == 'platinum') return MetalType.platinum;
    if (value == 'diamond') return MetalType.diamond;
    return MetalType.gold;
  }
}

class _StockUnitLookupRow {
  final int stockUnitId;
  final int stockItemId;
  final String unitCode;
  final String batchCode;
  final String metalType;
  final String itemType;
  final String segment;
  final String itemName;
  final String huid;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double purityPercent;
  final double unitCost;
  final String status;
  final String companyName;
  final String purityLabel;
  final String category;
  final String description;

  const _StockUnitLookupRow({
    required this.stockUnitId,
    required this.stockItemId,
    required this.unitCode,
    required this.batchCode,
    required this.metalType,
    required this.itemType,
    required this.segment,
    required this.itemName,
    required this.huid,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.purityPercent,
    required this.unitCost,
    required this.status,
    required this.companyName,
    required this.purityLabel,
    required this.category,
    required this.description,
  });

  factory _StockUnitLookupRow.fromRow(QueryRow row) {
    return _StockUnitLookupRow(
      stockUnitId: row.read<int>('stock_unit_id'),
      stockItemId: row.read<int>('stock_item_id'),
      unitCode: row.read<String>('unit_code'),
      batchCode: row.readNullable<String>('batch_code') ?? '',
      metalType: row.read<String>('metal_type'),
      itemType: row.readNullable<String>('item_type') ?? '',
      segment: row.readNullable<String>('segment') ?? '',
      itemName: row.read<String>('item_name'),
      huid: row.readNullable<String>('huid') ?? '',
      grossWeight: row.read<double>('gross_weight'),
      lessWeight: row.read<double>('less_weight'),
      netWeight: row.read<double>('net_weight'),
      purityPercent: row.read<double>('purity_percent'),
      unitCost: row.read<double>('unit_cost'),
      status: row.read<String>('unit_status'),
      companyName: row.readNullable<String>('company_name') ?? '',
      purityLabel: row.readNullable<String>('purity_label') ?? '',
      category: row.read<String>('category'),
      description: row.readNullable<String>('description') ?? '',
    );
  }
}

const String _createStockItemUnitsTableSql = '''
CREATE TABLE IF NOT EXISTS "stock_item_units" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "stock_item_id" INTEGER NOT NULL,
  "purchase_voucher_id" INTEGER,
  "purchase_voucher_item_id" INTEGER,
  "batch_code" TEXT,
  "unit_code" TEXT NOT NULL UNIQUE,
  "piece_no" INTEGER NOT NULL,
  "metal_type" TEXT NOT NULL,
  "item_type" TEXT,
  "segment" TEXT,
  "item_name" TEXT NOT NULL,
  "huid" TEXT,
  "gross_weight" REAL NOT NULL DEFAULT 0.0,
  "less_weight" REAL NOT NULL DEFAULT 0.0,
  "net_weight" REAL NOT NULL DEFAULT 0.0,
  "purity_percent" REAL NOT NULL DEFAULT 0.0,
  "actual_fine_weight" REAL NOT NULL DEFAULT 0.0,
  "wastage_fine_weight" REAL NOT NULL DEFAULT 0.0,
  "valuation_fine_weight" REAL NOT NULL DEFAULT 0.0,
  "rate_per_gram" REAL NOT NULL DEFAULT 0.0,
  "making_amount" REAL NOT NULL DEFAULT 0.0,
  "unit_cost" REAL NOT NULL DEFAULT 0.0,
  "supplier_id" INTEGER,
  "supplier_name" TEXT,
  "status" TEXT NOT NULL DEFAULT 'Available',
  "created_at" INTEGER NOT NULL,
  "updated_at" INTEGER,
  "sold_at" INTEGER,
  FOREIGN KEY ("stock_item_id") REFERENCES "stock_items" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("purchase_voucher_id") REFERENCES "purchase_vouchers" ("id") ON DELETE SET NULL,
  FOREIGN KEY ("purchase_voucher_item_id") REFERENCES "purchase_voucher_items" ("id") ON DELETE SET NULL
)
''';

const List<String> _stockItemUnitsIndexSql = [
  'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_stock_item" ON "stock_item_units" ("stock_item_id")',
  'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_huid" ON "stock_item_units" ("huid")',
  'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_status" ON "stock_item_units" ("status")',
  'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_item_name" ON "stock_item_units" ("item_name")',
  'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_net_weight" ON "stock_item_units" ("net_weight")',
  'CREATE INDEX IF NOT EXISTS "idx_stock_item_units_batch" ON "stock_item_units" ("batch_code")',
];
