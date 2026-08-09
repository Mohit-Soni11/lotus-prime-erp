import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_cost_basis_sql.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_grade_models.dart';

class MetalValuationGradeRepository {
  final AppDatabase _db;

  MetalValuationGradeRepository({AppDatabase? database})
      : _db = database ?? AppDatabase();

  Future<MetalValuationGradeSnapshot> fetchGradeSnapshot(
    String metalType,
  ) async {
    await _db.ensureStockInventorySchema();
    final metal = _normalizeMetal(metalType);
    final availableGradeExpression = _gradeExpression(metal);
    final soldGradeExpression = _gradeExpression(metal, includeBill: true);
    final costBasis = soldCostBasisExpression();

    final rows = await _db.customSelect(
      '''
      WITH available AS (
        SELECT
          $availableGradeExpression AS grade_label,
          COUNT(*) AS available_units,
          CAST(COALESCE(SUM(u.net_weight), 0.0) AS REAL) AS available_net_weight,
          CAST(COALESCE(SUM(u.unit_cost), 0.0) AS REAL) AS available_cost
        FROM stock_item_units u
        LEFT JOIN stock_items si ON si.id = u.stock_item_id
        WHERE lower(u.metal_type) = lower(?)
          AND lower(u.status) = 'available'
        GROUP BY grade_label
      ),
      sold AS (
        SELECT
          $soldGradeExpression AS grade_label,
          CAST(COALESCE(SUM(COALESCE(NULLIF(i.quantity, 0), 1)), 0) AS INTEGER) AS sold_units,
          CAST(COALESCE(SUM(i.net_weight), 0.0) AS REAL) AS sold_net_weight,
          CAST(COALESCE(SUM($costBasis), 0.0) AS REAL) AS sold_cost,
          CAST(COALESCE(SUM(i.item_total), 0.0) AS REAL) AS sale_value,
          CAST(COALESCE(SUM(i.item_total - $costBasis), 0.0) AS REAL) AS profit
        FROM bill_items i
        INNER JOIN bills b ON b.id = i.bill_id
        LEFT JOIN stock_item_units u ON u.id = i.linked_stock_unit_id
        LEFT JOIN stock_items si ON si.id = u.stock_item_id
        LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
        WHERE lower(i.metal_type) = lower(?)
          AND UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
          AND $costBasis > 0
        GROUP BY grade_label
      )
      SELECT
        COALESCE(available.grade_label, sold.grade_label) AS grade_label,
        COALESCE(available.available_units, 0) AS available_units,
        COALESCE(sold.sold_units, 0) AS sold_units,
        CAST(COALESCE(available.available_net_weight, 0.0) AS REAL) AS available_net_weight,
        CAST(COALESCE(sold.sold_net_weight, 0.0) AS REAL) AS sold_net_weight,
        CAST(COALESCE(available.available_cost, 0.0) AS REAL) AS available_cost,
        CAST(COALESCE(sold.sold_cost, 0.0) AS REAL) AS sold_cost,
        CAST(COALESCE(sold.sale_value, 0.0) AS REAL) AS sale_value,
        CAST(COALESCE(sold.profit, 0.0) AS REAL) AS profit
      FROM available
      LEFT JOIN sold ON lower(sold.grade_label) = lower(available.grade_label)
      UNION
      SELECT
        COALESCE(available.grade_label, sold.grade_label) AS grade_label,
        COALESCE(available.available_units, 0) AS available_units,
        COALESCE(sold.sold_units, 0) AS sold_units,
        CAST(COALESCE(available.available_net_weight, 0.0) AS REAL) AS available_net_weight,
        CAST(COALESCE(sold.sold_net_weight, 0.0) AS REAL) AS sold_net_weight,
        CAST(COALESCE(available.available_cost, 0.0) AS REAL) AS available_cost,
        CAST(COALESCE(sold.sold_cost, 0.0) AS REAL) AS sold_cost,
        CAST(COALESCE(sold.sale_value, 0.0) AS REAL) AS sale_value,
        CAST(COALESCE(sold.profit, 0.0) AS REAL) AS profit
      FROM sold
      LEFT JOIN available ON lower(available.grade_label) = lower(sold.grade_label)
      WHERE available.grade_label IS NULL
      ORDER BY sold_units DESC, available_units DESC, grade_label ASC
      ''',
      variables: [
        Variable<String>(metal),
        Variable<String>(metal),
      ],
    ).get();

    final grades = rows
        .map(
          (row) => MetalValuationGradeRow(
            gradeLabel: _readString(row, 'grade_label', _fallbackLabel(metal)),
            availableUnits: _readInt(row, 'available_units'),
            soldUnits: _readInt(row, 'sold_units'),
            availableNetWeight: _readDouble(row, 'available_net_weight'),
            soldNetWeight: _readDouble(row, 'sold_net_weight'),
            availableCost: _readDouble(row, 'available_cost'),
            soldCost: _readDouble(row, 'sold_cost'),
            saleValue: _readDouble(row, 'sale_value'),
            profit: _readDouble(row, 'profit'),
          ),
        )
        .where((grade) => grade.availableUnits > 0 || grade.soldUnits > 0)
        .toList(growable: false);

    return MetalValuationGradeSnapshot(metalType: metal, grades: grades);
  }

  static String _gradeExpression(String metal, {bool includeBill = false}) {
    final billPurityFallback = includeBill
        ? "WHEN NULLIF(TRIM(COALESCE(i.purity, '')), '') IS NOT NULL THEN i.purity"
        : '';
    final billItemNameFallback = includeBill
        ? "WHEN NULLIF(TRIM(COALESCE(i.item_name, '')), '') IS NOT NULL THEN i.item_name"
        : '';
    if (metal.toLowerCase() == 'gold') {
      return '''
        CASE
          WHEN COALESCE(u.purity_percent, 0.0) > 0 THEN
            CASE CAST(ROUND(u.purity_percent * 24.0 / 100.0) AS INTEGER)
              WHEN 24 THEN '24KT (99.9%)'
              WHEN 22 THEN '22KT (91.6%)'
              WHEN 18 THEN '18KT (75%)'
              WHEN 14 THEN '14KT (58.5%)'
              WHEN 9 THEN '9KT (37.5%)'
              ELSE CAST(CAST(ROUND(u.purity_percent * 24.0 / 100.0) AS INTEGER) AS TEXT) || 'KT (' || printf('%.1f', u.purity_percent) || '%)'
            END
          WHEN NULLIF(TRIM(COALESCE(si.purity, '')), '') IS NOT NULL THEN si.purity
          $billPurityFallback
          ELSE 'Custom Gold Grade'
        END
      ''';
    }

    if (metal.toLowerCase() == 'silver') {
      return '''
        CASE
          WHEN NULLIF(TRIM(COALESCE(u.item_type, si.sub_category, '')), '') IS NOT NULL
            THEN COALESCE(NULLIF(TRIM(u.item_type), ''), NULLIF(TRIM(si.sub_category), ''))
          WHEN NULLIF(TRIM(COALESCE(u.item_name, si.item_name, '')), '') IS NOT NULL
            THEN COALESCE(NULLIF(TRIM(u.item_name), ''), NULLIF(TRIM(si.item_name), ''))
          $billItemNameFallback
          ELSE 'Silver Item'
        END
      ''';
    }

    return '''
      COALESCE(
        NULLIF(TRIM(si.purity), ''),
        CASE
          WHEN COALESCE(u.purity_percent, 0.0) > 0 THEN printf('%.2f%%', u.purity_percent)
          $billPurityFallback
          ELSE 'Custom Grade'
        END
      )
    ''';
  }

  static String _normalizeMetal(String metalType) {
    final value = metalType.trim();
    if (value.isEmpty) return 'Gold';
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  static String _fallbackLabel(String metalType) {
    if (metalType.toLowerCase() == 'gold') return 'Custom Gold Grade';
    if (metalType.toLowerCase() == 'silver') return 'Silver Item';
    return 'Custom Grade';
  }

  static int _readInt(QueryRow row, String key) {
    final value = row.data[key];
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _readDouble(QueryRow row, String key) {
    final value = row.data[key];
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static String _readString(QueryRow row, String key, String fallback) {
    final value = row.data[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }
}
