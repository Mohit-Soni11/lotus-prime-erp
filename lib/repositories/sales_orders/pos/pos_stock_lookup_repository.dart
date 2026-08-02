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

  Future<PosStockLookupModel?> findUniqueExactDescription({
    required String query,
    required MetalType metal,
    String purityLabel = '',
    int limit = 20,
  }) async {
    final term = _normalizeExactText(query);
    if (term.isEmpty) {
      return null;
    }

    final matches = await searchByDescription(
      query: query,
      metal: metal,
      purityLabel: purityLabel,
      limit: limit,
    );
    final exactMatches = matches
        .where((match) => _isExactDescriptionMatch(match, term))
        .toList(growable: false);
    return exactMatches.length == 1 ? exactMatches.single : null;
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
      final huid = row.huidSearchText.trim().toLowerCase();
      final unitCode = row.unitCode.trim().toLowerCase();
      if (huid.split(' ').contains(term) || unitCode == term) {
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
        COALESCE(ph.huid_list, '') AS huid_list,
        u.gross_weight AS gross_weight,
        u.less_weight AS less_weight,
        u.net_weight AS net_weight,
        u.purity_percent AS purity_percent,
        u.unit_cost AS unit_cost,
        u.status AS unit_status,
        COALESCE(s.quantity, 0) AS stock_quantity,
        COALESCE(NULLIF(TRIM(s.quantity_mode), ''), 'PIECES') AS quantity_mode,
        COALESCE(s.packet_count, 0) AS packet_count,
        COALESCE(s.pieces_per_packet, 1) AS pieces_per_packet,
        COALESCE(NULLIF(TRIM(u.company_name), ''), NULLIF(TRIM(s.company_name), '')) AS company_name,
        s.purity AS purity_label,
        s.category AS category,
        s.description AS description
      FROM stock_item_units u
      INNER JOIN stock_items s ON s.id = u.stock_item_id
      LEFT JOIN (
        SELECT
          purchase_voucher_item_id,
          stock_item_id,
          GROUP_CONCAT(huid, ',') AS huid_list
        FROM purchase_item_huids
        GROUP BY purchase_voucher_item_id, stock_item_id
      ) ph ON ph.stock_item_id = u.stock_item_id
          AND (
            ph.purchase_voucher_item_id = u.purchase_voucher_item_id
            OR u.purchase_voucher_item_id IS NULL
          )
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
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS "purchase_item_huids" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "purchase_voucher_id" INTEGER NOT NULL,
        "purchase_voucher_item_id" INTEGER,
        "stock_item_id" INTEGER,
        "line_no" INTEGER NOT NULL,
        "piece_no" INTEGER NOT NULL,
        "huid" TEXT NOT NULL,
        "created_at" INTEGER NOT NULL
      )
    ''');
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS "idx_purchase_item_huids_huid" ON "purchase_item_huids" ("huid")',
    );
    await _db.customStatement(_createStockItemUnitsTableSql);
    await _ensureTableColumns(
      'stock_item_units',
      const {
        'company_name': 'TEXT',
      },
    );
    for (final statement in _stockItemUnitsIndexSql) {
      await _db.customStatement(statement);
    }
  }

  Future<void> _ensureTableColumns(
    String tableName,
    Map<String, String> columns,
  ) async {
    final rows =
        await _db.customSelect('PRAGMA table_info("$tableName")').get();
    if (rows.isEmpty) {
      return;
    }

    final existingColumns = rows.map((row) => row.read<String>('name')).toSet();
    for (final entry in columns.entries) {
      if (existingColumns.contains(entry.key)) {
        continue;
      }
      await _db.customStatement(
        'ALTER TABLE "$tableName" ADD COLUMN "${entry.key}" ${entry.value}',
      );
    }
  }

  String _descriptionSearchText(_StockUnitLookupRow row) {
    return [
      row.itemName,
      row.itemType,
      row.segment,
      row.companyName,
      row.huid,
      row.huidList,
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
    final huid = row.huidSearchText.trim().toLowerCase();
    final unitCode = row.unitCode.trim().toLowerCase();
    if (itemName == term || itemType == term) return 0;
    if (itemName.startsWith(term)) return 1;
    if (itemType.startsWith(term)) return 2;
    if (segment.startsWith(term)) return 3;
    if (itemName.contains(term) || itemType.contains(term)) return 4;
    if (huid.startsWith(term) || unitCode.startsWith(term)) return 5;
    return 6;
  }

  bool _isExactDescriptionMatch(PosStockLookupModel match, String term) {
    return _normalizeExactText(match.displayTitle) == term ||
        _normalizeExactText(match.itemName) == term ||
        _normalizeExactText(match.categoryLabel) == term;
  }

  String _normalizeExactText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
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
        .expand((unit) => unit.huidTokens)
        .where((huid) => huid.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final availablePieces = _availablePiecesForRows(effectiveRows);
    final quantityUnitLabel = _quantityUnitLabel(row);

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
      quantity: availablePieces,
      availableQuantity: _availableDisplayQuantity(
        pieces: availablePieces,
        row: row,
        unitLabel: quantityUnitLabel,
      ),
      quantityUnitLabel: quantityUnitLabel,
      status: row.status,
    );
  }

  int _availablePiecesForRows(List<_StockUnitLookupRow> rows) {
    return rows.fold<int>(
      0,
      (sum, row) => sum + (_isLotUnit(row) ? row.stockQuantity : 1),
    );
  }

  bool _isLotUnit(_StockUnitLookupRow row) {
    return row.unitCode.toLowerCase().contains('lot') &&
        row.huid.trim().isEmpty;
  }

  String _quantityUnitLabel(_StockUnitLookupRow row) {
    final mode = row.quantityMode.trim().toLowerCase();
    if (mode == 'packet' || mode == 'pack') return 'packet';
    if (mode == 'pair') return 'pair';
    if (mode == 'set') return 'set';
    if (mode == 'lot' || mode == 'bulk') return 'lot';

    final text = '${row.itemType} ${row.itemName}'.toLowerCase();
    if (text.contains('packet') || text.contains('pack')) return 'packet';
    if (text.contains('payal') ||
        text.contains('anklet') ||
        text.contains('jhumka') ||
        text.contains('earring') ||
        text.contains('tops') ||
        text.contains('bali') ||
        text.contains('kundal') ||
        text.contains('bichhiya') ||
        text.contains('toe ring')) {
      return 'pair';
    }
    if (text.contains('set') ||
        text.contains('necklace') ||
        text.contains('haar') ||
        text.contains('har') ||
        text.contains('chudi')) {
      return 'set';
    }
    return 'pcs';
  }

  double _availableDisplayQuantity({
    required int pieces,
    required _StockUnitLookupRow row,
    required String unitLabel,
  }) {
    if (pieces <= 0) return 0;
    return switch (unitLabel) {
      'packet' => pieces / _positiveInt(row.piecesPerPacket, fallback: 1),
      'pair' => pieces.toDouble(),
      _ => pieces.toDouble(),
    };
  }

  int _positiveInt(int value, {required int fallback}) {
    return value > 0 ? value : fallback;
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
  final String huidList;
  final double grossWeight;
  final double lessWeight;
  final double netWeight;
  final double purityPercent;
  final double unitCost;
  final String status;
  final int stockQuantity;
  final String quantityMode;
  final int packetCount;
  final int piecesPerPacket;
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
    required this.huidList,
    required this.grossWeight,
    required this.lessWeight,
    required this.netWeight,
    required this.purityPercent,
    required this.unitCost,
    required this.status,
    required this.stockQuantity,
    required this.quantityMode,
    required this.packetCount,
    required this.piecesPerPacket,
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
      huidList: row.readNullable<String>('huid_list') ?? '',
      grossWeight: row.read<double>('gross_weight'),
      lessWeight: row.read<double>('less_weight'),
      netWeight: row.read<double>('net_weight'),
      purityPercent: row.read<double>('purity_percent'),
      unitCost: row.read<double>('unit_cost'),
      status: row.read<String>('unit_status'),
      stockQuantity: row.readNullable<int>('stock_quantity') ?? 0,
      quantityMode: row.readNullable<String>('quantity_mode') ?? 'PIECES',
      packetCount: row.readNullable<int>('packet_count') ?? 0,
      piecesPerPacket: row.readNullable<int>('pieces_per_packet') ?? 1,
      companyName: row.readNullable<String>('company_name') ?? '',
      purityLabel: row.readNullable<String>('purity_label') ?? '',
      category: row.read<String>('category'),
      description: row.readNullable<String>('description') ?? '',
    );
  }

  List<String> get huidTokens {
    final values = <String>[
      ...huidList.split(RegExp(r'[,;/\s]+')),
      huid,
    ];
    return values
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String get huidSearchText => huidTokens.join(' ');
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
  "company_name" TEXT,
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
