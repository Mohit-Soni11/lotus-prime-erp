// =============================================================================
// FILE        : lib/repositories/metal_costing/metal_costing_repository.dart
// MODULE      : Metal Costing Analysis
// LAYER       : Repository / Data Access
// DESCRIPTION : Reads stock items from Drift DB, groups by metalType + purity.
//               Controllers NEVER touch AppDatabase directly.
// =============================================================================

import 'package:drift/drift.dart' as drift;
import 'package:lotus_erp/database/db/app_database.dart';
import '../../../models/setting/metal_costing/metal_costing_model.dart';

class MetalCostingRepository {
  final AppDatabase _db;

  MetalCostingRepository(this._db);

  // ── Fetch all stock items for a given metalType ────────────────────────────
  Future<List<StockItem>> getItemsByMetal(String metalType) async {
    final query = _db.select(_db.stockItems)
      ..where((s) => s.metalType.equals(metalType) & s.isActive.equals(true))
      ..orderBy([(s) => drift.OrderingTerm.asc(s.purity)]);
    return query.get();
  }

  // ── Fetch ALL stock items (all metals) ────────────────────────────────────
  Future<List<StockItem>> getAllStockItems() async {
    final query = _db.select(_db.stockItems)
      ..where((s) => s.isActive.equals(true))
      ..orderBy([
        (s) => drift.OrderingTerm.asc(s.metalType),
        (s) => drift.OrderingTerm.asc(s.purity),
      ]);
    return query.get();
  }

  // ── Convert StockItem row → MetalCostingItem (with injected todayRate) ─────
  MetalCostingItem fromRow(StockItem row, double todayRate) {
    return MetalCostingItem(
      id: row.id,
      sku: row.sku,
      itemName: row.itemName,
      metalType: row.metalType,
      purity: row.purity ?? '',
      netWeight: row.netWeight,
      wastage: row.wastage, // tanch %
      purchaseRate: row.purchaseRate, // rate per 100g at purchase
      makingCharge: row.makingCharge,
      makingChargeType: row.makingChargeType,
      purchaseDate: row.createdAt,
      // Sold status — status field = 'Sold' when item is billed
      soldPrice: row.status == 'Sold' ? row.mrp : null,
      soldDate: row.status == 'Sold' ? row.updatedAt : null,
      todayRate: todayRate,
    );
  }

  // ── Build grouped data: metalType → purity → items ────────────────────────
  Future<List<MetalSummary>> buildSummary({
    required Map<String, double> todayRates,
  }) async {
    final allRows = await getAllStockItems();

    // Group by metalType
    final Map<String, List<StockItem>> byMetal = {};
    for (final row in allRows) {
      byMetal.putIfAbsent(row.metalType, () => []).add(row);
    }

    return byMetal.entries.map((metalEntry) {
      final metal = metalEntry.key;
      final rate = todayRates[metal.toLowerCase()] ?? 0.0;
      final rows = metalEntry.value;

      // Group by purity
      final Map<String, List<StockItem>> byPurity = {};
      for (final row in rows) {
        final p = row.purity ?? 'Unknown';
        byPurity.putIfAbsent(p, () => []).add(row);
      }

      final purities = byPurity.entries.map((pEntry) {
        final items = pEntry.value.map((r) => fromRow(r, rate)).toList();
        return PuritySummary(purity: pEntry.key, items: items);
      }).toList();

      return MetalSummary(metalType: metal, purities: purities);
    }).toList();
  }
}
