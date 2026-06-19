// ==========================================
// FILE: pos_stock_lookup_repository.dart
// TYPE: Repository
// DESCRIPTION: Stock-aware lookup layer for the Sales POS screen. Handles
//              name and HUID suggestions filtered by the currently selected
//              metal and available stock only.
// ==========================================

import 'package:lotus_erp/database/db/app_database.dart';

import '../../../helpers/search/fuzzy_search_helper.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales_orders/sales_pos_models/pos_stock_lookup_model.dart';
import '../../../models/stock/stock_item_model/stock_enums.dart' as stock;

class PosStockLookupRepository {
  final AppDatabase _db;

  PosStockLookupRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<List<PosStockLookupModel>> searchByDescription({
    required String query,
    required MetalType metal,
    int limit = 8,
  }) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) {
      return const [];
    }

    final stockRows = await _availableItemsForMetal(metal);
    if (stockRows.isEmpty) {
      return const [];
    }

    final matches = term.length == 1
        ? stockRows
            .where((row) => _descriptionSearchText(row).contains(term))
            .toList(growable: false)
        : FuzzySearchHelper.searchObjects(
            items: stockRows,
            query: term,
            getSearchText: _descriptionSearchText,
            maxResults: limit,
            threshold: 0.25,
          );

    return matches.take(limit).map(_toLookupModel).toList(growable: false);
  }

  Future<List<PosStockLookupModel>> searchByHuid({
    required String query,
    required MetalType metal,
    int limit = 6,
  }) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) {
      return const [];
    }

    final stockRows = await _availableItemsForMetal(metal);
    final matches = stockRows.where((row) {
      final huid = (row.huid ?? '').toLowerCase();
      final sku = row.sku.toLowerCase();
      return huid.contains(term) || sku.contains(term);
    }).toList();

    matches.sort(
        (a, b) => _rankHuidMatch(a, term).compareTo(_rankHuidMatch(b, term)));
    return matches.take(limit).map(_toLookupModel).toList(growable: false);
  }

  Future<PosStockLookupModel?> findExactByHuid({
    required String query,
    required MetalType metal,
  }) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) {
      return null;
    }

    final stockRows = await _availableItemsForMetal(metal);
    for (final row in stockRows) {
      final huid = (row.huid ?? '').trim().toLowerCase();
      final sku = row.sku.trim().toLowerCase();
      if (huid == term || sku == term) {
        return _toLookupModel(row);
      }
    }
    return null;
  }

  Future<List<StockItem>> _availableItemsForMetal(MetalType metal) async {
    final rows = await _db.select(_db.stockItems).get();
    return rows.where((row) {
      final isAvailable =
          row.isActive && row.status == stock.StockStatus.available.label;
      return isAvailable && _matchesMetal(row, metal);
    }).toList(growable: false);
  }

  bool _matchesMetal(StockItem row, MetalType metal) {
    final expected = metal.displayName.toLowerCase();
    final category = row.category.trim().toLowerCase();
    final metalType = row.metalType.trim().toLowerCase();
    return category == expected || metalType == expected;
  }

  String _descriptionSearchText(StockItem row) {
    return [
      row.itemName,
      row.description ?? '',
      row.huid ?? '',
      row.sku,
    ].join(' ').toLowerCase();
  }

  int _rankHuidMatch(StockItem row, String term) {
    final huid = (row.huid ?? '').trim().toLowerCase();
    final sku = row.sku.trim().toLowerCase();
    if (huid == term || sku == term) {
      return 0;
    }
    if (huid.startsWith(term) || sku.startsWith(term)) {
      return 1;
    }
    return 2;
  }

  PosStockLookupModel _toLookupModel(StockItem row) {
    return PosStockLookupModel(
      stockItemId: row.id,
      sku: row.sku,
      itemName: row.itemName,
      description: row.description ?? '',
      huid: row.huid,
      purity: row.purity ?? '',
      metal: _metalFromStockRow(row),
      categoryLabel: row.category,
      grossWeight: row.grossWeight,
      lessWeight: row.stoneWeight,
      netWeight: row.netWeight,
      quantity: row.quantity,
      status: row.status,
    );
  }

  MetalType _metalFromStockRow(StockItem row) {
    final value = row.category.trim().toLowerCase();
    switch (value) {
      case 'gold':
        return MetalType.gold;
      case 'silver':
        return MetalType.silver;
      case 'platinum':
        return MetalType.platinum;
      case 'diamond':
        return MetalType.diamond;
      default:
        final metalValue = row.metalType.trim().toLowerCase();
        if (metalValue == 'gold') return MetalType.gold;
        if (metalValue == 'silver') return MetalType.silver;
        if (metalValue == 'platinum') return MetalType.platinum;
        if (metalValue == 'diamond') return MetalType.diamond;
        return MetalType.gold;
    }
  }
}
