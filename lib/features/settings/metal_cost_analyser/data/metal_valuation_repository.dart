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
    await _db.ensureStockInventorySchema();

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
      availablePurityPercentValue: _readDouble(
        availableSummary,
        'purity_percent',
      ),
      availableWastagePercent: _readDouble(
        availableSummary,
        'wastage_percent',
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
            CAST(COALESCE(SUM(valuation_fine_weight), 0.0) AS REAL) AS valuation_fine,
            CAST(
              CASE
                WHEN COALESCE(SUM(net_weight), 0.0) = 0.0 THEN 0.0
                ELSE COALESCE(
                  SUM(
                    net_weight * COALESCE(
                      NULLIF(purity_percent, 0.0),
                      CASE
                        WHEN COALESCE(net_weight, 0.0) = 0.0 THEN 0.0
                        ELSE actual_fine_weight * 100.0 / net_weight
                      END,
                      0.0
                    )
                  ) / SUM(net_weight),
                  0.0
                )
              END AS REAL
            ) AS purity_percent,
            CAST(
              CASE
                WHEN COALESCE(SUM(net_weight), 0.0) = 0.0 THEN 0.0
                ELSE COALESCE(SUM(net_weight * COALESCE(wastage_percent, 0.0)) / SUM(net_weight), 0.0)
              END AS REAL
            ) AS wastage_percent
          FROM stock_item_units
          WHERE status = 'Available' ${_metalWhereClause(filter)}
          ''',
      variables: _metalVariables(filter),
    ).getSingle();
  }

  Future<QueryRow> _readSoldSummary(MetalValuationFilter filter) {
    final costBasis = _soldCostBasisExpression();
    return _db.customSelect(
      '''
          SELECT
            COUNT(*) AS units,
            CAST(COALESCE(SUM($costBasis), 0.0) AS REAL) AS cost,
            CAST(COALESCE(SUM(i.item_total), 0.0) AS REAL) AS sales,
            CAST(COALESCE(SUM(i.item_total - $costBasis), 0.0) AS REAL) AS profit,
            CAST(COALESCE(SUM(i.net_weight), 0.0) AS REAL) AS net_weight,
            CAST(COALESCE(SUM(i.fine_weight), 0.0) AS REAL) AS fine_weight
          FROM bill_items i
          INNER JOIN bills b ON b.id = i.bill_id
          LEFT JOIN stock_item_units u ON u.id = i.linked_stock_unit_id
          LEFT JOIN stock_items si ON si.id = u.stock_item_id
          LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
          WHERE $costBasis > 0
            AND UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
            ${_metalWhereClause(filter, alias: 'i')}
          ''',
      variables: _metalVariables(filter),
    ).getSingle();
  }

  Future<List<MetalValuationBreakdown>> _readBreakdown(
    MetalValuationFilter filter,
  ) async {
    final costBasis = _soldCostBasisExpression();
    final rows = await _db.customSelect(
      '''
          WITH available AS (
            SELECT
              metal_type,
              COUNT(*) AS available_units,
              CAST(COALESCE(SUM(unit_cost), 0.0) AS REAL) AS available_cost,
              CAST(COALESCE(SUM(net_weight), 0.0) AS REAL) AS available_net_weight,
              CAST(COALESCE(SUM(actual_fine_weight), 0.0) AS REAL) AS available_fine_weight,
              CAST(COALESCE(SUM(valuation_fine_weight), 0.0) AS REAL) AS available_valuation_fine_weight,
              CAST(
                CASE
                  WHEN COALESCE(SUM(net_weight), 0.0) = 0.0 THEN 0.0
                  ELSE COALESCE(
                    SUM(
                      net_weight * COALESCE(
                        NULLIF(purity_percent, 0.0),
                        CASE
                          WHEN COALESCE(net_weight, 0.0) = 0.0 THEN 0.0
                          ELSE actual_fine_weight * 100.0 / net_weight
                        END,
                        0.0
                      )
                    ) / SUM(net_weight),
                    0.0
                  )
                END AS REAL
              ) AS available_purity_percent,
              CAST(
                CASE
                  WHEN COALESCE(SUM(net_weight), 0.0) = 0.0 THEN 0.0
                  ELSE COALESCE(SUM(net_weight * COALESCE(wastage_percent, 0.0)) / SUM(net_weight), 0.0)
                END AS REAL
              ) AS available_wastage_percent
            FROM stock_item_units
            WHERE status = 'Available' ${_metalWhereClause(filter)}
            GROUP BY metal_type
          ),
          sold AS (
            SELECT
              i.metal_type AS metal_type,
              COUNT(*) AS sold_units,
              CAST(COALESCE(SUM($costBasis), 0.0) AS REAL) AS sold_cost,
              CAST(COALESCE(SUM(i.item_total), 0.0) AS REAL) AS sale_value,
              CAST(COALESCE(SUM(i.item_total - $costBasis), 0.0) AS REAL) AS profit,
              CAST(COALESCE(SUM(i.net_weight), 0.0) AS REAL) AS sold_net_weight,
              CAST(COALESCE(SUM(i.fine_weight), 0.0) AS REAL) AS sold_fine_weight
            FROM bill_items i
            INNER JOIN bills b ON b.id = i.bill_id
            LEFT JOIN stock_item_units u ON u.id = i.linked_stock_unit_id
            LEFT JOIN stock_items si ON si.id = u.stock_item_id
            LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
            WHERE $costBasis > 0
              AND UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
              ${_metalWhereClause(filter, alias: 'i')}
            GROUP BY i.metal_type
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
            CAST(COALESCE(available.available_valuation_fine_weight, 0.0) AS REAL) AS available_valuation_fine_weight,
            CAST(COALESCE(available.available_purity_percent, 0.0) AS REAL) AS available_purity_percent,
            CAST(COALESCE(available.available_wastage_percent, 0.0) AS REAL) AS available_wastage_percent,
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
            CAST(COALESCE(available.available_valuation_fine_weight, 0.0) AS REAL) AS available_valuation_fine_weight,
            CAST(COALESCE(available.available_purity_percent, 0.0) AS REAL) AS available_purity_percent,
            CAST(COALESCE(available.available_wastage_percent, 0.0) AS REAL) AS available_wastage_percent,
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
            availableValuationFineWeight: _readDouble(
              row,
              'available_valuation_fine_weight',
            ),
            availablePurityPercentValue: _readDouble(
              row,
              'available_purity_percent',
            ),
            availableWastagePercent: _readDouble(
              row,
              'available_wastage_percent',
            ),
            soldNetWeight: _readDouble(row, 'sold_net_weight'),
            soldFineWeight: _readDouble(row, 'sold_fine_weight'),
          ),
        )
        .toList();
  }

  Future<List<BatchValuationRow>> _readBatchSummaries(
    MetalValuationFilter filter,
  ) async {
    final costBasis = _soldCostBasisExpression();
    final rows = await _db.customSelect(
      '''
          WITH purchase_lines AS (
            SELECT
              COALESCE(NULLIF(pv.voucher_no, ''), 'Not recorded') AS batch_code,
              pvi.metal_type AS metal_type,
              COALESCE(NULLIF(MAX(pv.party_name), ''), 'Not recorded') AS supplier_name,
              MIN(pvi.created_at) AS created_at,
              COALESCE(SUM(CASE WHEN pvi.quantity > 0 THEN pvi.quantity ELSE 1 END), 0) AS total_units,
              CAST(COALESCE(SUM(pvi.gross_weight), 0.0) AS REAL) AS total_gross_weight,
              CAST(COALESCE(SUM(pvi.net_weight), 0.0) AS REAL) AS total_net_weight,
              CAST(COALESCE(SUM(pvi.fine_weight), 0.0) AS REAL) AS total_fine_weight,
              CAST(COALESCE(SUM(pvi.valuation_fine_weight), 0.0) AS REAL) AS valuation_fine_weight,
              CAST(COALESCE(SUM(pvi.net_weight * COALESCE(pvi.purity, 0.0)), 0.0) AS REAL) AS purity_weighted_total,
              CAST(COALESCE(SUM(pvi.net_weight * COALESCE(pvi.wastage_percent, 0.0)), 0.0) AS REAL) AS wastage_weighted_total,
              CAST(COALESCE(AVG(NULLIF(pvi.rate, 0.0)), 0.0) AS REAL) AS rate_per_gram,
              CAST(
                COALESCE(
                  SUM(
                    MAX(
                      pvi.line_amount - (pvi.valuation_fine_weight * pvi.rate),
                      0.0
                    )
                  ),
                  0.0
                ) AS REAL
              ) AS making_amount,
              CAST(COALESCE(SUM(pvi.line_amount), 0.0) AS REAL) AS total_cost
            FROM purchase_voucher_items pvi
            INNER JOIN purchase_vouchers pv ON pv.id = pvi.purchase_voucher_id
            WHERE 1 = 1 ${_metalWhereClause(filter, alias: 'pvi')}
            GROUP BY COALESCE(NULLIF(pv.voucher_no, ''), 'Not recorded'), pvi.metal_type
          ),
          unit_sales AS (
            SELECT
              linked_stock_unit_id AS unit_id,
              COUNT(*) AS sold_units,
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
              COALESCE(NULLIF(u.batch_code, ''), 'Not recorded') AS batch_code,
              u.metal_type AS metal_type,
              COALESCE(NULLIF(MAX(u.supplier_name), ''), 'Not recorded') AS supplier_name,
              MIN(u.created_at) AS created_at,
              COUNT(u.id) AS stock_units,
              SUM(CASE WHEN u.status = 'Available' THEN 1 ELSE 0 END) AS available_units,
              COALESCE(SUM(unit_sales.sold_units), 0) AS sold_units,
              CAST(COALESCE(SUM(u.gross_weight), 0.0) AS REAL) AS current_gross_weight,
              CAST(COALESCE(SUM(CASE WHEN u.status = 'Available' THEN u.net_weight ELSE 0 END), 0.0) AS REAL) AS available_net_weight,
              CAST(COALESCE(SUM(unit_sales.sold_net_weight), 0.0) AS REAL) AS sold_net_weight,
              CAST(COALESCE(SUM(CASE WHEN u.status = 'Available' THEN u.actual_fine_weight ELSE 0 END), 0.0) AS REAL) AS available_fine_weight,
              CAST(COALESCE(SUM(CASE WHEN u.status = 'Available' THEN u.valuation_fine_weight ELSE 0 END), 0.0) AS REAL) AS available_valuation_fine_weight,
              CAST(COALESCE(SUM(CASE WHEN u.status <> 'Available' THEN u.valuation_fine_weight ELSE 0 END), 0.0) AS REAL) AS sold_valuation_fine_weight,
              CAST(COALESCE(SUM(u.net_weight * COALESCE(NULLIF(u.purity_percent, 0.0), CASE WHEN COALESCE(u.net_weight, 0.0) = 0.0 THEN 0.0 ELSE u.actual_fine_weight * 100.0 / u.net_weight END, 0.0)), 0.0) AS REAL) AS purity_weighted_total,
              CAST(COALESCE(SUM(u.net_weight * COALESCE(u.wastage_percent, 0.0)), 0.0) AS REAL) AS wastage_weighted_total,
              CAST(COALESCE(SUM(u.net_weight * COALESCE(u.rate_per_gram, 0.0)), 0.0) AS REAL) AS rate_weighted_total,
              CAST(COALESCE(SUM(u.making_amount), 0.0) AS REAL) AS making_amount,
              CAST(COALESCE(SUM(unit_sales.sold_fine_weight), 0.0) AS REAL) AS sold_fine_weight,
              CAST(COALESCE(SUM(CASE WHEN u.status = 'Available' THEN u.unit_cost ELSE 0 END), 0.0) AS REAL) AS available_cost,
              CAST(COALESCE(SUM(unit_sales.sold_cost), 0.0) AS REAL) AS sold_cost,
              CAST(COALESCE(SUM(unit_sales.sale_value), 0.0) AS REAL) AS sale_value,
              CAST(COALESCE(SUM(unit_sales.profit), 0.0) AS REAL) AS profit
            FROM stock_item_units u
            LEFT JOIN unit_sales ON unit_sales.unit_id = u.id
            WHERE 1 = 1 ${_metalWhereClause(filter, alias: 'u')}
            GROUP BY COALESCE(NULLIF(u.batch_code, ''), 'Not recorded'), u.metal_type
          )
          SELECT
            purchase_lines.batch_code AS batch_code,
            purchase_lines.metal_type AS metal_type,
            COALESCE(NULLIF(stock_balance.supplier_name, 'Not recorded'), purchase_lines.supplier_name) AS supplier_name,
            COALESCE(stock_balance.created_at, purchase_lines.created_at) AS created_at,
            CASE
              WHEN COALESCE(stock_balance.stock_units, 0) > 0 THEN stock_balance.stock_units
              ELSE purchase_lines.total_units
            END AS total_units,
            COALESCE(stock_balance.available_units, 0) AS available_units,
            COALESCE(stock_balance.sold_units, 0) AS sold_units,
            CASE
              WHEN COALESCE(stock_balance.stock_units, 0) > 0 THEN COALESCE(stock_balance.current_gross_weight, 0.0)
              ELSE purchase_lines.total_gross_weight
            END AS total_gross_weight,
            CASE
              WHEN COALESCE(stock_balance.stock_units, 0) > 0
                THEN COALESCE(stock_balance.available_net_weight, 0.0) + COALESCE(stock_balance.sold_net_weight, 0.0)
              ELSE purchase_lines.total_net_weight
            END AS total_net_weight,
            COALESCE(stock_balance.available_net_weight, 0.0) AS available_net_weight,
            COALESCE(stock_balance.sold_net_weight, 0.0) AS sold_net_weight,
            CASE
              WHEN COALESCE(stock_balance.stock_units, 0) > 0
                THEN COALESCE(stock_balance.available_fine_weight, 0.0) + COALESCE(stock_balance.sold_fine_weight, 0.0)
              ELSE purchase_lines.total_fine_weight
            END AS total_fine_weight,
            CASE
              WHEN COALESCE(stock_balance.stock_units, 0) > 0
                THEN COALESCE(stock_balance.available_valuation_fine_weight, 0.0) + COALESCE(stock_balance.sold_valuation_fine_weight, 0.0)
              ELSE purchase_lines.valuation_fine_weight
            END AS valuation_fine_weight,
            CAST(
              CASE
                WHEN COALESCE(stock_balance.stock_units, 0) > 0
                  AND COALESCE(stock_balance.available_net_weight + stock_balance.sold_net_weight, 0.0) <> 0.0
                  THEN COALESCE(stock_balance.purity_weighted_total / (stock_balance.available_net_weight + stock_balance.sold_net_weight), 0.0)
                WHEN COALESCE(purchase_lines.total_net_weight, 0.0) = 0.0 THEN 0.0
                ELSE COALESCE(purchase_lines.purity_weighted_total / purchase_lines.total_net_weight, 0.0)
              END AS REAL
            ) AS purity_percent,
            CAST(
              CASE
                WHEN COALESCE(stock_balance.stock_units, 0) > 0
                  AND COALESCE(stock_balance.available_net_weight + stock_balance.sold_net_weight, 0.0) <> 0.0
                  THEN COALESCE(stock_balance.wastage_weighted_total / (stock_balance.available_net_weight + stock_balance.sold_net_weight), 0.0)
                WHEN COALESCE(purchase_lines.total_net_weight, 0.0) = 0.0 THEN 0.0
                ELSE COALESCE(purchase_lines.wastage_weighted_total / purchase_lines.total_net_weight, 0.0)
              END AS REAL
            ) AS wastage_percent,
            COALESCE(stock_balance.available_fine_weight, 0.0) AS available_fine_weight,
            COALESCE(stock_balance.sold_fine_weight, 0.0) AS sold_fine_weight,
            CAST(
              CASE
                WHEN COALESCE(stock_balance.stock_units, 0) > 0
                  AND COALESCE(stock_balance.available_net_weight + stock_balance.sold_net_weight, 0.0) <> 0.0
                  THEN COALESCE(stock_balance.rate_weighted_total / (stock_balance.available_net_weight + stock_balance.sold_net_weight), 0.0)
                ELSE purchase_lines.rate_per_gram
              END AS REAL
            ) AS rate_per_gram,
            CASE
              WHEN COALESCE(stock_balance.stock_units, 0) > 0 THEN COALESCE(stock_balance.making_amount, 0.0)
              ELSE purchase_lines.making_amount
            END AS making_amount,
            CASE
              WHEN COALESCE(stock_balance.stock_units, 0) > 0
                THEN COALESCE(stock_balance.available_cost, 0.0) + COALESCE(stock_balance.sold_cost, 0.0)
              ELSE purchase_lines.total_cost
            END AS total_cost,
            COALESCE(stock_balance.available_cost, 0.0) AS available_cost,
            COALESCE(stock_balance.sold_cost, 0.0) AS sold_cost,
            COALESCE(stock_balance.sale_value, 0.0) AS sale_value,
            COALESCE(stock_balance.profit, 0.0) AS profit
          FROM purchase_lines
          LEFT JOIN stock_balance
            ON stock_balance.batch_code = purchase_lines.batch_code
           AND stock_balance.metal_type = purchase_lines.metal_type
          UNION ALL
          SELECT
            stock_balance.batch_code AS batch_code,
            stock_balance.metal_type AS metal_type,
            stock_balance.supplier_name AS supplier_name,
            stock_balance.created_at AS created_at,
            stock_balance.stock_units AS total_units,
            stock_balance.available_units AS available_units,
            stock_balance.sold_units AS sold_units,
            stock_balance.current_gross_weight AS total_gross_weight,
            stock_balance.available_net_weight + stock_balance.sold_net_weight AS total_net_weight,
            stock_balance.available_net_weight AS available_net_weight,
            stock_balance.sold_net_weight AS sold_net_weight,
            stock_balance.available_fine_weight + stock_balance.sold_fine_weight AS total_fine_weight,
            stock_balance.available_valuation_fine_weight + stock_balance.sold_valuation_fine_weight AS valuation_fine_weight,
            CAST(
              CASE
                WHEN COALESCE(stock_balance.available_net_weight + stock_balance.sold_net_weight, 0.0) = 0.0 THEN 0.0
                ELSE COALESCE(stock_balance.purity_weighted_total / (stock_balance.available_net_weight + stock_balance.sold_net_weight), 0.0)
              END AS REAL
            ) AS purity_percent,
            CAST(
              CASE
                WHEN COALESCE(stock_balance.available_net_weight + stock_balance.sold_net_weight, 0.0) = 0.0 THEN 0.0
                ELSE COALESCE(stock_balance.wastage_weighted_total / (stock_balance.available_net_weight + stock_balance.sold_net_weight), 0.0)
              END AS REAL
            ) AS wastage_percent,
            stock_balance.available_fine_weight AS available_fine_weight,
            stock_balance.sold_fine_weight AS sold_fine_weight,
            CAST(
              CASE
                WHEN COALESCE(stock_balance.available_net_weight + stock_balance.sold_net_weight, 0.0) = 0.0 THEN 0.0
                ELSE COALESCE(stock_balance.rate_weighted_total / (stock_balance.available_net_weight + stock_balance.sold_net_weight), 0.0)
              END AS REAL
            ) AS rate_per_gram,
            stock_balance.making_amount AS making_amount,
            stock_balance.available_cost + stock_balance.sold_cost AS total_cost,
            stock_balance.available_cost AS available_cost,
            stock_balance.sold_cost AS sold_cost,
            stock_balance.sale_value AS sale_value,
            stock_balance.profit AS profit
          FROM stock_balance
          WHERE NOT EXISTS (
            SELECT 1
            FROM purchase_lines
            WHERE purchase_lines.batch_code = stock_balance.batch_code
              AND purchase_lines.metal_type = stock_balance.metal_type
          )
          ORDER BY 4 DESC, 1
          LIMIT 80
          ''',
      variables: [
        ..._metalVariables(filter),
        ..._metalVariables(filter),
      ],
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
        )
        .toList();
  }

  Future<List<AvailableValuationRow>> _readAvailableRows(
    MetalValuationFilter filter,
  ) async {
    final rows = await _db.customSelect(
      '''
          SELECT
            u.metal_type AS metal_type,
            COALESCE(NULLIF(u.batch_code, ''), 'Not recorded') AS batch_code,
            COALESCE(NULLIF(u.item_type, ''), 'Not recorded') AS item_type,
            u.item_name AS item_name,
            COALESCE(NULLIF(u.company_name, ''), 'Unbranded') AS company_name,
            COALESCE(NULLIF(u.huid, ''), '') AS huid,
            u.unit_code AS unit_code,
            CASE
              WHEN (
                pvi.id IS NOT NULL
                AND (
                  (
                    LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
                    AND TRIM(COALESCE(u.huid, '')) = ''
                  )
                  OR LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) IN ('packet', 'pack', 'lot', 'bulk')
                )
              )
                THEN COALESCE(NULLIF(pvi.quantity, 0), 1)
              ELSE 1
            END AS quantity,
            COALESCE(NULLIF(s.quantity_mode, ''), 'PCS') AS quantity_mode,
            CAST(
              CASE
                WHEN (
                  pvi.id IS NOT NULL
                  AND (
                    (
                      LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
                      AND TRIM(COALESCE(u.huid, '')) = ''
                    )
                    OR LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) IN ('packet', 'pack', 'lot', 'bulk')
                  )
                )
                  THEN COALESCE(NULLIF(pvi.gross_weight, 0.0), u.gross_weight)
                ELSE u.gross_weight
              END AS REAL
            ) AS gross_weight,
            CAST(
              CASE
                WHEN (
                  pvi.id IS NOT NULL
                  AND (
                    (
                      LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
                      AND TRIM(COALESCE(u.huid, '')) = ''
                    )
                    OR LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) IN ('packet', 'pack', 'lot', 'bulk')
                  )
                )
                  THEN COALESCE(NULLIF(pvi.net_weight, 0.0), u.net_weight)
                ELSE u.net_weight
              END AS REAL
            ) AS net_weight,
            CAST(
              CASE
                WHEN (
                  pvi.id IS NOT NULL
                  AND (
                    (
                      LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
                      AND TRIM(COALESCE(u.huid, '')) = ''
                    )
                    OR LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) IN ('packet', 'pack', 'lot', 'bulk')
                  )
                )
                  THEN COALESCE(NULLIF(pvi.fine_weight, 0.0), u.actual_fine_weight)
                ELSE u.actual_fine_weight
              END AS REAL
            ) AS actual_fine_weight,
            CAST(
              CASE
                WHEN (
                  pvi.id IS NOT NULL
                  AND (
                    (
                      LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
                      AND TRIM(COALESCE(u.huid, '')) = ''
                    )
                    OR LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) IN ('packet', 'pack', 'lot', 'bulk')
                  )
                )
                  THEN COALESCE(NULLIF(pvi.purity, 0.0), u.purity_percent, 0.0)
                ELSE COALESCE(NULLIF(u.purity_percent, 0.0), NULLIF(pvi.purity, 0.0), 0.0)
              END AS REAL
            ) AS purity_percent,
            CAST(
              CASE
                WHEN (
                  pvi.id IS NOT NULL
                  AND (
                    (
                      LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
                      AND TRIM(COALESCE(u.huid, '')) = ''
                    )
                    OR LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) IN ('packet', 'pack', 'lot', 'bulk')
                  )
                )
                  THEN COALESCE(pvi.wastage_percent, u.wastage_percent, 0.0)
                ELSE COALESCE(u.wastage_percent, 0.0)
              END AS REAL
            ) AS wastage_percent,
            CAST(
              CASE
                WHEN (
                  (
                    pvi.id IS NOT NULL
                    AND (
                      (
                        LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
                        AND TRIM(COALESCE(u.huid, '')) = ''
                      )
                      OR LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) IN ('packet', 'pack', 'lot', 'bulk')
                    )
                  )
                )
                  THEN COALESCE(NULLIF(pvi.valuation_fine_weight, 0.0), u.valuation_fine_weight, 0.0)
                ELSE COALESCE(NULLIF(u.valuation_fine_weight, 0.0), pvi.valuation_fine_weight, 0.0)
              END AS REAL
            ) AS valuation_fine_weight,
            CAST(
              CASE
                WHEN (
                  pvi.id IS NOT NULL
                  AND (
                    (
                      LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
                      AND TRIM(COALESCE(u.huid, '')) = ''
                    )
                    OR LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) IN ('packet', 'pack', 'lot', 'bulk')
                  )
                )
                  THEN COALESCE(NULLIF(pvi.rate, 0.0), u.rate_per_gram, 0.0)
                ELSE COALESCE(NULLIF(u.rate_per_gram, 0.0), pvi.rate, 0.0)
              END AS REAL
            ) AS rate_per_gram,
            CAST(
              CASE
                WHEN (
                  pvi.id IS NOT NULL
                  AND (
                    (
                      LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
                      AND TRIM(COALESCE(u.huid, '')) = ''
                    )
                    OR LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) IN ('packet', 'pack', 'lot', 'bulk')
                  )
                )
                  THEN MAX(
                    COALESCE(pvi.line_amount, 0.0) -
                    (
                      COALESCE(NULLIF(pvi.valuation_fine_weight, 0.0), pvi.fine_weight + pvi.wastage_fine_weight, 0.0) *
                      COALESCE(NULLIF(pvi.rate, 0.0), u.rate_per_gram, 0.0)
                    ),
                    0.0
                  )
                ELSE COALESCE(u.making_amount, 0.0)
              END AS REAL
            ) AS making_amount,
            CAST(
              CASE
                WHEN (
                  pvi.id IS NOT NULL
                  AND (
                    (
                      LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
                      AND TRIM(COALESCE(u.huid, '')) = ''
                    )
                    OR LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), '')) IN ('packet', 'pack', 'lot', 'bulk')
                  )
                )
                  THEN COALESCE(NULLIF(pvi.line_amount, 0.0), u.unit_cost, 0.0)
                ELSE COALESCE(NULLIF(u.unit_cost, 0.0), pvi.line_amount, 0.0)
              END AS REAL
            ) AS unit_cost
          FROM stock_item_units u
          LEFT JOIN purchase_voucher_items pvi
            ON pvi.id = u.purchase_voucher_item_id
          LEFT JOIN stock_items s
            ON s.id = u.stock_item_id
          WHERE u.status = 'Available' ${_metalWhereClause(filter, alias: 'u')}
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
            purityPercentValue: _readDouble(row, 'purity_percent'),
            wastagePercent: _readDouble(row, 'wastage_percent'),
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
    final costBasis = _soldCostBasisExpression();
    final rows = await _db.customSelect(
      '''
          SELECT
            b.id AS bill_id,
            b.customer_id AS customer_id,
            b.bill_no AS bill_no,
            COALESCE(NULLIF(TRIM(b.customer_name), ''), NULLIF(TRIM(c.name), ''), 'Walk-in Customer') AS customer_name,
            b.bill_date AS bill_date,
            COALESCE(NULLIF(u.batch_code, ''), 'Not recorded') AS batch_code,
            i.metal_type AS metal_type,
            i.item_name AS item_name,
            COALESCE(NULLIF(i.huid, ''), NULLIF(u.huid, ''), '') AS huid,
            COALESCE(NULLIF(u.unit_code, ''), NULLIF(i.linked_stock_sku, ''), '') AS unit_code,
            i.quantity AS quantity,
            COALESCE(NULLIF(si.quantity_mode, ''), 'PIECES') AS quantity_mode,
            i.net_weight AS net_weight,
            $costBasis AS cost,
            i.item_total AS sale,
            i.item_total - $costBasis AS profit
          FROM bill_items i
          INNER JOIN bills b ON b.id = i.bill_id
          LEFT JOIN customers c ON c.id = b.customer_id
          LEFT JOIN stock_item_units u ON u.id = i.linked_stock_unit_id
          LEFT JOIN stock_items si ON si.id = u.stock_item_id
          LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
          WHERE $costBasis > 0
            AND UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
            ${_metalWhereClause(filter, alias: 'i')}
          ORDER BY b.bill_date DESC, i.id DESC
          LIMIT 120
          ''',
      variables: _metalVariables(filter),
    ).get();

    return rows
        .map(
          (row) => SoldValuationRow(
            billId: _readInt(row, 'bill_id'),
            customerId: _readNullableInt(row, 'customer_id'),
            billNo: _readString(row, 'bill_no'),
            customerName: _readString(row, 'customer_name'),
            billDate: _readDateTime(row, 'bill_date'),
            batchCode: _readString(row, 'batch_code'),
            metalType: _readString(row, 'metal_type'),
            itemName: _readString(row, 'item_name'),
            huid: _readString(row, 'huid'),
            unitCode: _readString(row, 'unit_code'),
            quantity: _readInt(row, 'quantity'),
            quantityMode: _readString(row, 'quantity_mode'),
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

  static String _soldCostBasisExpression({
    String itemAlias = 'i',
    String unitAlias = 'u',
    String stockAlias = 'si',
    String purchaseAlias = 'pvi',
  }) {
    final fallback =
        'COALESCE(NULLIF($itemAlias.stock_unit_cost, 0.0), $unitAlias.unit_cost, 0.0)';
    final originalValuationFine =
        'COALESCE(NULLIF($purchaseAlias.valuation_fine_weight, 0.0), '
        'COALESCE($purchaseAlias.fine_weight, 0.0) + '
        'COALESCE($purchaseAlias.wastage_fine_weight, 0.0), 0.0)';
    final originalRate =
        'COALESCE(NULLIF($purchaseAlias.rate, 0.0), $unitAlias.rate_per_gram, 0.0)';
    final originalMaking = 'MAX(COALESCE($purchaseAlias.line_amount, 0.0) - '
        '($originalValuationFine * $originalRate), 0.0)';
    final lotOrBulkLine = '''
      $purchaseAlias.id IS NOT NULL
      AND (
        (
          LOWER(COALESCE($unitAlias.unit_code, '')) LIKE '%lot%'
          AND TRIM(COALESCE($unitAlias.huid, '')) = ''
        )
        OR LOWER(COALESCE(NULLIF(TRIM($stockAlias.quantity_mode), ''), '')) IN ('packet', 'pack', 'lot', 'bulk')
      )
    ''';
    final allocatedCost = '''
      (
        CASE
          WHEN COALESCE($purchaseAlias.net_weight, 0.0) > 0
            THEN COALESCE($itemAlias.net_weight, 0.0) *
                 ($originalValuationFine / $purchaseAlias.net_weight) *
                 $originalRate
          ELSE 0.0
        END
        +
        CASE
          WHEN COALESCE($purchaseAlias.quantity, 0) > 0
            THEN $originalMaking *
                 COALESCE(NULLIF($itemAlias.quantity, 0), 1) /
                 $purchaseAlias.quantity
          ELSE 0.0
        END
      )
    ''';

    return '''
      CASE
        WHEN $lotOrBulkLine
          THEN COALESCE(NULLIF($allocatedCost, 0.0), $fallback)
        ELSE $fallback
      END
    ''';
  }

  static int _readInt(QueryRow row, String key) {
    final value = row.data[key];
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static int? _readNullableInt(QueryRow row, String key) {
    final value = row.data[key];
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
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
