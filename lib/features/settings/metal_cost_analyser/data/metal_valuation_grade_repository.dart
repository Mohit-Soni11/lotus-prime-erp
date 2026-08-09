import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_cost_basis_sql.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_grade_models.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

class MetalValuationGradeRepository {
  final AppDatabase _db;

  MetalValuationGradeRepository({AppDatabase? database})
      : _db = database ?? AppDatabase();

  Future<MetalValuationGradeSnapshot> fetchGradeSnapshot(
    String metalType, {
    String? batchCode,
  }) async {
    await _db.ensureStockInventorySchema();
    final metal = _normalizeMetal(metalType);
    final availableGradeExpression = _gradeExpression(metal);
    final soldGradeExpression = _gradeExpression(metal, includeBill: true);
    final costBasis = soldCostBasisExpression();
    final normalizedBatch = batchCode?.trim();
    final hasBatchFilter =
        normalizedBatch != null && normalizedBatch.isNotEmpty;
    final batchWhere = hasBatchFilter
        ? "AND lower(COALESCE(NULLIF(TRIM(u.batch_code), ''), 'Not recorded')) = lower(?)"
        : '';

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
          $batchWhere
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
          $batchWhere
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
        if (hasBatchFilter) Variable<String>(normalizedBatch),
        Variable<String>(metal),
        if (hasBatchFilter) Variable<String>(normalizedBatch),
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

  Future<List<MetalValuationGradeBatchRow>> fetchGradeBatchRows(
    String metalType,
  ) async {
    await _db.ensureStockInventorySchema();
    final metal = _normalizeMetal(metalType);
    final gradeExpression = _gradeExpression(metal);
    final costBasis = soldCostBasisExpression();

    final rows = await _db.customSelect(
      '''
      WITH unit_sales AS (
        SELECT
          linked_stock_unit_id AS unit_id,
          CAST(COALESCE(SUM(COALESCE(NULLIF(i.quantity, 0), 1)), 0) AS INTEGER) AS sold_units,
          CAST(COALESCE(SUM(i.net_weight), 0.0) AS REAL) AS sold_net_weight,
          CAST(COALESCE(SUM(i.fine_weight), 0.0) AS REAL) AS sold_fine_weight,
          CAST(COALESCE(SUM($costBasis), 0.0) AS REAL) AS sold_cost,
          CAST(COALESCE(SUM(i.item_total), 0.0) AS REAL) AS sale_value,
          CAST(COALESCE(SUM(i.item_total - $costBasis), 0.0) AS REAL) AS profit
        FROM bill_items i
        INNER JOIN bills b ON b.id = i.bill_id
        LEFT JOIN stock_item_units u ON u.id = i.linked_stock_unit_id
        LEFT JOIN stock_items si ON si.id = u.stock_item_id
        LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
        WHERE $costBasis > 0
          AND i.linked_stock_unit_id IS NOT NULL
          AND UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
        GROUP BY linked_stock_unit_id
      ),
      stock_balance AS (
        SELECT
          $gradeExpression AS grade_label,
          COALESCE(NULLIF(TRIM(u.batch_code), ''), 'Not recorded') AS batch_code,
          u.metal_type AS metal_type,
          COALESCE(NULLIF(MAX(u.supplier_name), ''), 'Not recorded') AS supplier_name,
          MIN(u.created_at) AS created_at,
          COUNT(u.id) AS stock_units,
          SUM(CASE WHEN lower(u.status) = 'available' THEN 1 ELSE 0 END) AS available_units,
          COALESCE(SUM(unit_sales.sold_units), 0) AS sold_units,
          CAST(COALESCE(SUM(u.gross_weight), 0.0) AS REAL) AS total_gross_weight,
          CAST(COALESCE(SUM(CASE WHEN lower(u.status) = 'available' THEN u.net_weight ELSE 0 END), 0.0) AS REAL) AS available_net_weight,
          CAST(COALESCE(SUM(unit_sales.sold_net_weight), 0.0) AS REAL) AS sold_net_weight,
          CAST(COALESCE(SUM(CASE WHEN lower(u.status) = 'available' THEN u.actual_fine_weight ELSE 0 END), 0.0) AS REAL) AS available_fine_weight,
          CAST(COALESCE(SUM(unit_sales.sold_fine_weight), 0.0) AS REAL) AS sold_fine_weight,
          CAST(COALESCE(SUM(CASE WHEN lower(u.status) = 'available' THEN u.valuation_fine_weight ELSE 0 END), 0.0) AS REAL) AS available_valuation_fine_weight,
          CAST(
            COALESCE(
              SUM(
                COALESCE(unit_sales.sold_net_weight, 0.0) * COALESCE(
                  NULLIF(pvi.valuation_fine_weight, 0.0) / NULLIF(pvi.net_weight, 0.0),
                  (COALESCE(u.purity_percent, 0.0) + COALESCE(u.wastage_percent, 0.0)) / 100.0,
                  0.0
                )
              ),
              0.0
            ) AS REAL
          ) AS sold_valuation_fine_weight,
          CAST(
            COALESCE(
              SUM(
                (
                  CASE WHEN lower(u.status) = 'available' THEN u.net_weight ELSE 0 END
                  + COALESCE(unit_sales.sold_net_weight, 0.0)
                ) * COALESCE(
                  NULLIF(u.purity_percent, 0.0),
                  CASE
                    WHEN COALESCE(u.net_weight, 0.0) = 0.0 THEN 0.0
                    ELSE u.actual_fine_weight * 100.0 / u.net_weight
                  END,
                  0.0
                )
              ),
              0.0
            ) AS REAL
          ) AS purity_weighted_total,
          CAST(
            COALESCE(
              SUM(
                (
                  CASE WHEN lower(u.status) = 'available' THEN u.net_weight ELSE 0 END
                  + COALESCE(unit_sales.sold_net_weight, 0.0)
                ) * COALESCE(u.wastage_percent, 0.0)
              ),
              0.0
            ) AS REAL
          ) AS wastage_weighted_total,
          CAST(
            COALESCE(
              SUM(
                (
                  CASE WHEN lower(u.status) = 'available' THEN u.net_weight ELSE 0 END
                  + COALESCE(unit_sales.sold_net_weight, 0.0)
                ) * COALESCE(u.rate_per_gram, 0.0)
              ),
              0.0
            ) AS REAL
          ) AS rate_weighted_total,
          CAST(COALESCE(SUM(u.making_amount), 0.0) AS REAL) AS making_amount,
          CAST(COALESCE(SUM(CASE WHEN lower(u.status) = 'available' THEN u.unit_cost ELSE 0 END), 0.0) AS REAL) AS available_cost,
          CAST(COALESCE(SUM(unit_sales.sold_cost), 0.0) AS REAL) AS sold_cost,
          CAST(COALESCE(SUM(unit_sales.sale_value), 0.0) AS REAL) AS sale_value,
          CAST(COALESCE(SUM(unit_sales.profit), 0.0) AS REAL) AS profit
        FROM stock_item_units u
        LEFT JOIN stock_items si ON si.id = u.stock_item_id
        LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
        LEFT JOIN unit_sales ON unit_sales.unit_id = u.id
        WHERE lower(u.metal_type) = lower(?)
        GROUP BY grade_label, batch_code, u.metal_type
      )
      SELECT
        grade_label,
        batch_code,
        metal_type,
        supplier_name,
        created_at,
        stock_units AS total_units,
        available_units,
        sold_units,
        total_gross_weight,
        available_net_weight + sold_net_weight AS total_net_weight,
        available_net_weight,
        sold_net_weight,
        available_fine_weight + sold_fine_weight AS total_fine_weight,
        available_valuation_fine_weight + sold_valuation_fine_weight AS valuation_fine_weight,
        available_valuation_fine_weight,
        sold_valuation_fine_weight,
        CAST(
          CASE
            WHEN COALESCE(available_net_weight + sold_net_weight, 0.0) = 0.0 THEN 0.0
            ELSE COALESCE(purity_weighted_total / (available_net_weight + sold_net_weight), 0.0)
          END AS REAL
        ) AS purity_percent,
        CAST(
          CASE
            WHEN COALESCE(available_net_weight + sold_net_weight, 0.0) = 0.0 THEN 0.0
            ELSE COALESCE(wastage_weighted_total / (available_net_weight + sold_net_weight), 0.0)
          END AS REAL
        ) AS wastage_percent,
        available_fine_weight,
        sold_fine_weight,
        CAST(
          CASE
            WHEN COALESCE(available_net_weight + sold_net_weight, 0.0) = 0.0 THEN 0.0
            ELSE COALESCE(rate_weighted_total / (available_net_weight + sold_net_weight), 0.0)
          END AS REAL
        ) AS rate_per_gram,
        making_amount,
        available_cost + sold_cost AS total_cost,
        available_cost,
        sold_cost,
        sale_value,
        profit
      FROM stock_balance
      WHERE available_units > 0 OR sold_units > 0
      ORDER BY grade_label ASC, created_at DESC, batch_code ASC
      ''',
      variables: [Variable<String>(metal)],
    ).get();

    return rows
        .map(
          (row) => MetalValuationGradeBatchRow(
            gradeLabel: _readString(row, 'grade_label', _fallbackLabel(metal)),
            batch: BatchValuationRow(
              batchCode: _readString(row, 'batch_code', 'Not recorded'),
              metalType: _readString(row, 'metal_type', metal),
              supplierName: _readString(row, 'supplier_name', 'Not recorded'),
              createdAt: _readDateTime(row, 'created_at'),
              totalUnits: _readInt(row, 'total_units'),
              availableUnits: _readInt(row, 'available_units'),
              soldUnits: _readInt(row, 'sold_units'),
              totalGrossWeight: _readDouble(row, 'total_gross_weight'),
              totalNetWeight: _readDouble(row, 'total_net_weight'),
              availableNetWeight: _readDouble(row, 'available_net_weight'),
              soldNetWeight: _readDouble(row, 'sold_net_weight'),
              totalFineWeight: _readDouble(row, 'total_fine_weight'),
              valuationFineWeight: _readDouble(row, 'valuation_fine_weight'),
              availableValuationFineWeight: _readDouble(
                row,
                'available_valuation_fine_weight',
              ),
              soldValuationFineWeight: _readDouble(
                row,
                'sold_valuation_fine_weight',
              ),
              purityPercentValue: _readDouble(row, 'purity_percent'),
              wastagePercent: _readDouble(row, 'wastage_percent'),
              availableFineWeight: _readDouble(row, 'available_fine_weight'),
              soldFineWeight: _readDouble(row, 'sold_fine_weight'),
              ratePerGram: _readDouble(row, 'rate_per_gram'),
              makingAmount: _readDouble(row, 'making_amount'),
              totalCost: _readDouble(row, 'total_cost'),
              availableCost: _readDouble(row, 'available_cost'),
              soldCost: _readDouble(row, 'sold_cost'),
              saleValue: _readDouble(row, 'sale_value'),
              profit: _readDouble(row, 'profit'),
            ),
          ),
        )
        .toList(growable: false);
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

  static DateTime? _readDateTime(QueryRow row, String key) {
    final value = row.data[key];
    if (value is int && value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num && value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}
