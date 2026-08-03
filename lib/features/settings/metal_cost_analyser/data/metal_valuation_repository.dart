import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

class MetalValuationRepository {
  final AppDatabase _db;

  MetalValuationRepository({AppDatabase? database})
      : _db = database ?? AppDatabase();

  Future<MetalValuationSnapshot> fetchSnapshot({
    MetalValuationFilter filter = MetalValuationFilter.all,
  }) async {
    final availableSummary = await _readAvailableSummary(filter);
    final soldSummary = await _readSoldSummary(filter);

    final summary = MetalValuationSummary(
      availableUnits: _readInt(availableSummary, 'units'),
      soldUnits: _readInt(soldSummary, 'units'),
      availableCost: _readDouble(availableSummary, 'cost'),
      soldCost: _readDouble(soldSummary, 'cost'),
      saleValue: _readDouble(soldSummary, 'sales'),
      profit: _readDouble(soldSummary, 'profit'),
      availableNetWeight: _readDouble(availableSummary, 'net_weight'),
      availableActualFine: _readDouble(availableSummary, 'actual_fine'),
      availableValuationFine: _readDouble(
        availableSummary,
        'valuation_fine',
      ),
      soldNetWeight: _readDouble(soldSummary, 'net_weight'),
      soldFineWeight: _readDouble(soldSummary, 'fine_weight'),
    );

    final breakdown = await _readBreakdown(filter);
    final batchSummaries = await _readBatchSummaries(filter);
    final availableRows = await _readAvailableRows(filter);
    final soldRows = await _readSoldRows(filter);

    return MetalValuationSnapshot(
      summary: summary,
      breakdown: breakdown,
      batchSummaries: batchSummaries,
      availableStock: availableRows,
      soldStock: soldRows,
    );
  }

  Future<QueryRow> _readAvailableSummary(MetalValuationFilter filter) {
    return _db.customSelect(
      '''
          SELECT
            COUNT(*) AS units,
            CAST(COALESCE(SUM(unit_cost), 0.0) AS REAL) AS cost,
            CAST(COALESCE(SUM(net_weight), 0.0) AS REAL) AS net_weight,
            CAST(COALESCE(SUM(actual_fine_weight), 0.0) AS REAL) AS actual_fine,
            CAST(COALESCE(SUM(valuation_fine_weight), 0.0) AS REAL) AS valuation_fine
          FROM stock_item_units
          WHERE status = 'Available' ${_metalWhereClause(filter)}
          ''',
      variables: _metalVariables(filter),
    ).getSingle();
  }

  Future<QueryRow> _readSoldSummary(MetalValuationFilter filter) {
    return _db.customSelect(
      '''
          SELECT
            COUNT(*) AS units,
            CAST(COALESCE(SUM(stock_unit_cost), 0.0) AS REAL) AS cost,
            CAST(COALESCE(SUM(item_total), 0.0) AS REAL) AS sales,
            CAST(COALESCE(SUM(stock_profit_amount), 0.0) AS REAL) AS profit,
            CAST(COALESCE(SUM(net_weight), 0.0) AS REAL) AS net_weight,
            CAST(COALESCE(SUM(fine_weight), 0.0) AS REAL) AS fine_weight
          FROM bill_items
          WHERE stock_unit_cost > 0 ${_metalWhereClause(filter)}
          ''',
      variables: _metalVariables(filter),
    ).getSingle();
  }

  Future<List<MetalValuationBreakdown>> _readBreakdown(
    MetalValuationFilter filter,
  ) async {
    final rows = await _db.customSelect(
      '''
          WITH available AS (
            SELECT
              metal_type,
              COUNT(*) AS available_units,
              CAST(COALESCE(SUM(unit_cost), 0.0) AS REAL) AS available_cost,
              CAST(COALESCE(SUM(net_weight), 0.0) AS REAL) AS available_net_weight,
              CAST(COALESCE(SUM(actual_fine_weight), 0.0) AS REAL) AS available_fine_weight
            FROM stock_item_units
            WHERE status = 'Available' ${_metalWhereClause(filter)}
            GROUP BY metal_type
          ),
          sold AS (
            SELECT
              metal_type,
              COUNT(*) AS sold_units,
              CAST(COALESCE(SUM(stock_unit_cost), 0.0) AS REAL) AS sold_cost,
              CAST(COALESCE(SUM(item_total), 0.0) AS REAL) AS sale_value,
              CAST(COALESCE(SUM(stock_profit_amount), 0.0) AS REAL) AS profit,
              CAST(COALESCE(SUM(net_weight), 0.0) AS REAL) AS sold_net_weight,
              CAST(COALESCE(SUM(fine_weight), 0.0) AS REAL) AS sold_fine_weight
            FROM bill_items
            WHERE stock_unit_cost > 0 ${_metalWhereClause(filter)}
            GROUP BY metal_type
          )
          SELECT
            COALESCE(available.metal_type, sold.metal_type) AS metal_type,
            COALESCE(available.available_units, 0) AS available_units,
            COALESCE(sold.sold_units, 0) AS sold_units,
            CAST(COALESCE(available.available_cost, 0.0) AS REAL) AS available_cost,
            CAST(COALESCE(sold.sold_cost, 0.0) AS REAL) AS sold_cost,
            CAST(COALESCE(sold.sale_value, 0.0) AS REAL) AS sale_value,
            CAST(COALESCE(sold.profit, 0.0) AS REAL) AS profit,
            CAST(COALESCE(available.available_net_weight, 0.0) AS REAL) AS available_net_weight,
            CAST(COALESCE(available.available_fine_weight, 0.0) AS REAL) AS available_fine_weight,
            CAST(COALESCE(sold.sold_net_weight, 0.0) AS REAL) AS sold_net_weight,
            CAST(COALESCE(sold.sold_fine_weight, 0.0) AS REAL) AS sold_fine_weight
          FROM available
          LEFT JOIN sold ON sold.metal_type = available.metal_type
          UNION
          SELECT
            COALESCE(available.metal_type, sold.metal_type) AS metal_type,
            COALESCE(available.available_units, 0) AS available_units,
            COALESCE(sold.sold_units, 0) AS sold_units,
            CAST(COALESCE(available.available_cost, 0.0) AS REAL) AS available_cost,
            CAST(COALESCE(sold.sold_cost, 0.0) AS REAL) AS sold_cost,
            CAST(COALESCE(sold.sale_value, 0.0) AS REAL) AS sale_value,
            CAST(COALESCE(sold.profit, 0.0) AS REAL) AS profit,
            CAST(COALESCE(available.available_net_weight, 0.0) AS REAL) AS available_net_weight,
            CAST(COALESCE(available.available_fine_weight, 0.0) AS REAL) AS available_fine_weight,
            CAST(COALESCE(sold.sold_net_weight, 0.0) AS REAL) AS sold_net_weight,
            CAST(COALESCE(sold.sold_fine_weight, 0.0) AS REAL) AS sold_fine_weight
          FROM sold
          LEFT JOIN available ON available.metal_type = sold.metal_type
          WHERE available.metal_type IS NULL
          ORDER BY metal_type
          ''',
      variables: [
        ..._metalVariables(filter),
        ..._metalVariables(filter),
      ],
    ).get();

    return rows
        .map(
          (row) => MetalValuationBreakdown(
            metalType: _readString(row, 'metal_type'),
            availableUnits: _readInt(row, 'available_units'),
            soldUnits: _readInt(row, 'sold_units'),
            availableCost: _readDouble(row, 'available_cost'),
            soldCost: _readDouble(row, 'sold_cost'),
            saleValue: _readDouble(row, 'sale_value'),
            profit: _readDouble(row, 'profit'),
            availableNetWeight: _readDouble(row, 'available_net_weight'),
            availableFineWeight: _readDouble(row, 'available_fine_weight'),
            soldNetWeight: _readDouble(row, 'sold_net_weight'),
            soldFineWeight: _readDouble(row, 'sold_fine_weight'),
          ),
        )
        .toList();
  }

  Future<List<BatchValuationRow>> _readBatchSummaries(
    MetalValuationFilter filter,
  ) async {
    final rows = await _db.customSelect(
      '''
          WITH unit_sales AS (
            SELECT
              linked_stock_unit_id AS unit_id,
              COUNT(*) AS sold_units,
              CAST(COALESCE(SUM(net_weight), 0.0) AS REAL) AS sold_net_weight,
              CAST(COALESCE(SUM(fine_weight), 0.0) AS REAL) AS sold_fine_weight,
              CAST(COALESCE(SUM(stock_unit_cost), 0.0) AS REAL) AS sold_cost,
              CAST(COALESCE(SUM(item_total), 0.0) AS REAL) AS sale_value,
              CAST(COALESCE(SUM(stock_profit_amount), 0.0) AS REAL) AS profit
            FROM bill_items
            WHERE stock_unit_cost > 0 AND linked_stock_unit_id IS NOT NULL
            GROUP BY linked_stock_unit_id
          )
          SELECT
            COALESCE(NULLIF(u.batch_code, ''), 'Not recorded') AS batch_code,
            u.metal_type AS metal_type,
            COALESCE(NULLIF(MAX(u.supplier_name), ''), 'Not recorded') AS supplier_name,
            MIN(u.created_at) AS created_at,
            COUNT(u.id) AS total_units,
            SUM(CASE WHEN u.status = 'Available' THEN 1 ELSE 0 END) AS available_units,
            COALESCE(SUM(unit_sales.sold_units), 0) AS sold_units,
            CAST(COALESCE(SUM(u.gross_weight), 0.0) AS REAL) AS total_gross_weight,
            CAST(COALESCE(SUM(u.net_weight), 0.0) AS REAL) AS total_net_weight,
            CAST(COALESCE(SUM(CASE WHEN u.status = 'Available' THEN u.net_weight ELSE 0 END), 0.0) AS REAL) AS available_net_weight,
            CAST(COALESCE(SUM(unit_sales.sold_net_weight), 0.0) AS REAL) AS sold_net_weight,
            CAST(COALESCE(SUM(u.actual_fine_weight), 0.0) AS REAL) AS total_fine_weight,
            CAST(COALESCE(SUM(u.valuation_fine_weight), 0.0) AS REAL) AS valuation_fine_weight,
            CAST(COALESCE(SUM(CASE WHEN u.status = 'Available' THEN u.actual_fine_weight ELSE 0 END), 0.0) AS REAL) AS available_fine_weight,
            CAST(COALESCE(SUM(unit_sales.sold_fine_weight), 0.0) AS REAL) AS sold_fine_weight,
            CAST(COALESCE(AVG(NULLIF(u.rate_per_gram, 0.0)), 0.0) AS REAL) AS rate_per_gram,
            CAST(COALESCE(SUM(u.making_amount), 0.0) AS REAL) AS making_amount,
            CAST(COALESCE(SUM(u.unit_cost), 0.0) AS REAL) AS total_cost,
            CAST(COALESCE(SUM(CASE WHEN u.status = 'Available' THEN u.unit_cost ELSE 0 END), 0.0) AS REAL) AS available_cost,
            CAST(COALESCE(SUM(unit_sales.sold_cost), 0.0) AS REAL) AS sold_cost,
            CAST(COALESCE(SUM(unit_sales.sale_value), 0.0) AS REAL) AS sale_value,
            CAST(COALESCE(SUM(unit_sales.profit), 0.0) AS REAL) AS profit
          FROM stock_item_units u
          LEFT JOIN unit_sales ON unit_sales.unit_id = u.id
          WHERE 1 = 1 ${_metalWhereClause(filter, alias: 'u')}
          GROUP BY COALESCE(NULLIF(u.batch_code, ''), 'Not recorded'), u.metal_type
          ORDER BY MAX(u.created_at) DESC, batch_code
          LIMIT 80
          ''',
      variables: _metalVariables(filter),
    ).get();

    return rows
        .map(
          (row) => BatchValuationRow(
            batchCode: _readString(row, 'batch_code'),
            metalType: _readString(row, 'metal_type'),
            supplierName: _readString(row, 'supplier_name'),
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
        )
        .toList();
  }

  Future<List<AvailableValuationRow>> _readAvailableRows(
    MetalValuationFilter filter,
  ) async {
    final rows = await _db.customSelect(
      '''
          WITH line_unit_counts AS (
            SELECT
              purchase_voucher_item_id,
              COUNT(*) AS unit_count
            FROM stock_item_units
            GROUP BY purchase_voucher_item_id
          )
          SELECT
            u.metal_type AS metal_type,
            COALESCE(NULLIF(u.batch_code, ''), 'Not recorded') AS batch_code,
            COALESCE(NULLIF(u.item_type, ''), 'Not recorded') AS item_type,
            u.item_name AS item_name,
            COALESCE(NULLIF(u.company_name, ''), 'Unbranded') AS company_name,
            COALESCE(NULLIF(u.huid, ''), '') AS huid,
            u.unit_code AS unit_code,
            CASE
              WHEN COALESCE(luc.unit_count, 1) <= 1
                THEN COALESCE(pvi.quantity, 1)
              ELSE 1
            END AS quantity,
            COALESCE(NULLIF(pvi.quantity_mode, ''), 'PCS') AS quantity_mode,
            CAST(
              CASE
                WHEN COALESCE(luc.unit_count, 1) <= 1
                  THEN COALESCE(pvi.gross_weight, u.gross_weight)
                ELSE u.gross_weight
              END AS REAL
            ) AS gross_weight,
            CAST(
              CASE
                WHEN COALESCE(luc.unit_count, 1) <= 1
                  THEN COALESCE(pvi.net_weight, u.net_weight)
                ELSE u.net_weight
              END AS REAL
            ) AS net_weight,
            CAST(
              CASE
                WHEN COALESCE(luc.unit_count, 1) <= 1
                  THEN COALESCE(pvi.fine_weight, u.actual_fine_weight)
                ELSE u.actual_fine_weight
              END AS REAL
            ) AS actual_fine_weight,
            CAST(
              CASE
                WHEN COALESCE(luc.unit_count, 1) <= 1
                  THEN COALESCE(pvi.valuation_fine_weight, u.valuation_fine_weight)
                ELSE u.valuation_fine_weight
              END AS REAL
            ) AS valuation_fine_weight,
            CAST(
              CASE
                WHEN COALESCE(luc.unit_count, 1) <= 1
                  THEN COALESCE(pvi.rate, u.rate_per_gram)
                ELSE u.rate_per_gram
              END AS REAL
            ) AS rate_per_gram,
            CAST(
              CASE
                WHEN COALESCE(luc.unit_count, 1) <= 1
                  THEN MAX(
                    COALESCE(pvi.line_amount, u.unit_cost) -
                    (COALESCE(pvi.valuation_fine_weight, u.valuation_fine_weight) *
                     COALESCE(pvi.rate, u.rate_per_gram)),
                    0.0
                  )
                ELSE u.making_amount
              END AS REAL
            ) AS making_amount,
            CAST(
              CASE
                WHEN COALESCE(luc.unit_count, 1) <= 1
                  THEN COALESCE(pvi.line_amount, u.unit_cost)
                ELSE u.unit_cost
              END AS REAL
            ) AS unit_cost
          FROM stock_item_units u
          LEFT JOIN purchase_voucher_items pvi
            ON pvi.id = u.purchase_voucher_item_id
          LEFT JOIN line_unit_counts luc
            ON luc.purchase_voucher_item_id = u.purchase_voucher_item_id
          WHERE 1 = 1 ${_metalWhereClause(filter, alias: 'u')}
          ORDER BY u.created_at DESC, u.id DESC
          LIMIT 120
          ''',
      variables: _metalVariables(filter),
    ).get();

    return rows
        .map(
          (row) => AvailableValuationRow(
            metalType: _readString(row, 'metal_type'),
            batchCode: _readString(row, 'batch_code'),
            itemType: _readString(row, 'item_type'),
            itemName: _readString(row, 'item_name'),
            companyName: _readString(row, 'company_name'),
            huid: _readString(row, 'huid'),
            unitCode: _readString(row, 'unit_code'),
            quantity: _readInt(row, 'quantity'),
            quantityMode: _readString(row, 'quantity_mode'),
            grossWeight: _readDouble(row, 'gross_weight'),
            netWeight: _readDouble(row, 'net_weight'),
            actualFine: _readDouble(row, 'actual_fine_weight'),
            valuationFine: _readDouble(row, 'valuation_fine_weight'),
            ratePerGram: _readDouble(row, 'rate_per_gram'),
            makingAmount: _readDouble(row, 'making_amount'),
            unitCost: _readDouble(row, 'unit_cost'),
          ),
        )
        .toList();
  }

  Future<List<SoldValuationRow>> _readSoldRows(
    MetalValuationFilter filter,
  ) async {
    final rows = await _db.customSelect(
      '''
          SELECT
            b.bill_no AS bill_no,
            b.bill_date AS bill_date,
            u.batch_code AS batch_code,
            i.metal_type AS metal_type,
            i.item_name AS item_name,
            i.huid AS huid,
            i.linked_stock_sku AS unit_code,
            i.net_weight AS net_weight,
            i.stock_unit_cost AS cost,
            i.item_total AS sale,
            i.stock_profit_amount AS profit
          FROM bill_items i
          INNER JOIN bills b ON b.id = i.bill_id
          LEFT JOIN stock_item_units u ON u.id = i.linked_stock_unit_id
          WHERE i.stock_unit_cost > 0 ${_metalWhereClause(filter, alias: 'i')}
          ORDER BY b.bill_date DESC, i.id DESC
          LIMIT 120
          ''',
      variables: _metalVariables(filter),
    ).get();

    return rows
        .map(
          (row) => SoldValuationRow(
            billNo: _readString(row, 'bill_no'),
            billDate: _readDateTime(row, 'bill_date'),
            batchCode: _readString(row, 'batch_code'),
            metalType: _readString(row, 'metal_type'),
            itemName: _readString(row, 'item_name'),
            huid: _readString(row, 'huid'),
            unitCode: _readString(row, 'unit_code'),
            netWeight: _readDouble(row, 'net_weight'),
            saleValue: _readDouble(row, 'sale'),
            costBasis: _readDouble(row, 'cost'),
            profit: _readDouble(row, 'profit'),
          ),
        )
        .toList();
  }

  String _metalWhereClause(MetalValuationFilter filter, {String? alias}) {
    if (filter.isAll) return '';
    final prefix = alias == null ? '' : '$alias.';
    return 'AND ${prefix}metal_type = ?';
  }

  List<Variable<String>> _metalVariables(MetalValuationFilter filter) {
    if (filter.isAll) return const [];
    return [Variable<String>(filter.databaseValue)];
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

  static String _readString(QueryRow row, String key) {
    return (row.data[key] ?? '').toString().trim();
  }

  static DateTime? _readDateTime(QueryRow row, String key) {
    final value = row.data[key];
    if (value is DateTime) return value;
    if (value is int) {
      if (value > 100000000000000) {
        return DateTime.fromMicrosecondsSinceEpoch(value);
      }
      if (value < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
