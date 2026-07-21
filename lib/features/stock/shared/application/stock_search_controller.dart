import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/application/stock_lot_sale_reconciliation_service.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_search/stock_search_models.dart';

const String _isLotUnitExpression = '''
LOWER(COALESCE(u.unit_code, '')) LIKE '%lot%'
  AND TRIM(COALESCE(u.huid, '')) = ''
''';

const String _totalQuantityExpression = '''
CASE
  WHEN $_isLotUnitExpression THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1)
  ELSE 1
END
''';

const String _availableQuantityExpression = '''
CASE
  WHEN LOWER(u.status) = 'available' THEN
    CASE
      WHEN $_isLotUnitExpression THEN COALESCE(NULLIF(s.quantity, 0), 0)
      ELSE 1
    END
  ELSE 0
END
''';

const String _soldQuantityExpression = '''
CASE
  WHEN $_isLotUnitExpression THEN
    CASE
      WHEN LOWER(u.status) = 'sold' THEN COALESCE(NULLIF(pvi.quantity, 0), 1)
      WHEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0) > 0
        THEN COALESCE(NULLIF(pvi.quantity, 0), NULLIF(s.quantity, 0), 1) - COALESCE(s.quantity, 0)
      ELSE 0
    END
  WHEN LOWER(u.status) = 'sold' THEN 1
  ELSE 0
END
''';

const String _soldWeightExpression = '''
CASE
  WHEN u.id = (
    SELECT MIN(first_unit.id)
    FROM stock_item_units first_unit
    WHERE first_unit.stock_item_id = s.id
  ) THEN
    CASE
      WHEN COALESCE(sm.sold_net_weight, 0) > 0
        THEN COALESCE(sm.sold_net_weight, 0)
      ELSE 0
    END
  ELSE 0
END
''';

const String _soldWeightJoin = '''
LEFT JOIN (
  SELECT
    source.stock_item_id,
    COALESCE(bill_weight.sold_net_weight, movement_weight.sold_net_weight, 0.0) AS sold_net_weight
  FROM (
    SELECT stock_item_id
    FROM stock_movements
    WHERE movement_type IN ('SALE', 'SALE_RESTORE')
    UNION
    SELECT linked_stock_item_id AS stock_item_id
    FROM bill_items
    WHERE linked_stock_item_id IS NOT NULL
  ) source
  LEFT JOIN (
    SELECT
      bi.linked_stock_item_id AS stock_item_id,
      SUM(COALESCE(bi.net_weight, 0.0)) AS sold_net_weight
    FROM bill_items bi
    INNER JOIN bills b ON b.id = bi.bill_id
    WHERE bi.linked_stock_item_id IS NOT NULL
      AND UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
    GROUP BY bi.linked_stock_item_id
  ) bill_weight ON bill_weight.stock_item_id = source.stock_item_id
  LEFT JOIN (
    SELECT
      stock_item_id,
      SUM(
        CASE
          WHEN movement_type = 'SALE' THEN ABS(net_weight_delta)
          WHEN movement_type = 'SALE_RESTORE' THEN -ABS(net_weight_delta)
          ELSE 0
        END
      ) AS sold_net_weight
    FROM stock_movements
    WHERE movement_type IN ('SALE', 'SALE_RESTORE')
    GROUP BY stock_item_id
  ) movement_weight ON movement_weight.stock_item_id = source.stock_item_id
) sm ON sm.stock_item_id = s.id
''';

class StockSearchController extends ChangeNotifier {
  final AppDatabase _db;

  StockSearchController(this._db);

  bool _isLoading = false;
  String _searchText = '';
  String _statusFilter = 'All';
  String _metalFilter = 'All';
  String _trackingFilter = 'All';
  String _sortMode = 'Relevance';
  String? _errorMessage;
  StockSearchSummary _summary = StockSearchSummary.empty();
  List<StockSearchResult> _results = const [];

  bool get isLoading => _isLoading;
  String get searchText => _searchText;
  String get statusFilter => _statusFilter;
  String get metalFilter => _metalFilter;
  String get trackingFilter => _trackingFilter;
  String get sortMode => _sortMode;
  String? get errorMessage => _errorMessage;
  StockSearchSummary get summary => _summary;
  List<StockSearchResult> get results => _results;
  bool get hasActiveFilters =>
      _searchText.trim().isNotEmpty ||
      _statusFilter != 'All' ||
      _metalFilter != 'All' ||
      _trackingFilter != 'All' ||
      _sortMode != 'Relevance';

  static const List<String> statusFilters = [
    'All',
    'Available',
    'Sold',
    'Reserved',
    'On Hold',
    'Damaged',
    'Archived',
  ];

  static const List<String> metalFilters = [
    'All',
    'Gold',
    'Silver',
    'Diamond',
    'Platinum',
  ];

  static const List<String> trackingFilters = [
    'All',
    'HUID Linked',
    'Weight Tracked',
  ];

  static const List<String> sortModes = [
    'Relevance',
    'Newest',
    'Weight High',
    'Fine High',
    'Value High',
  ];

  static String statusFilterLabel(String value) {
    switch (value) {
      case 'Available':
        return 'Available Stock';
      case 'Sold':
        return 'Sold Stock';
      case 'Reserved':
        return 'Reserved';
      case 'On Hold':
        return 'On Hold';
      case 'Damaged':
        return 'Damaged';
      case 'Archived':
        return 'Archived';
      default:
        return 'All Status';
    }
  }

  static String metalFilterLabel(String value) {
    return value == 'All' ? 'All Metals' : value;
  }

  static String trackingFilterLabel(String value) {
    return value == 'All' ? 'All Tracking' : value;
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _ensureSearchSchema();
      await StockLotSaleReconciliationService(_db).reconcile();

      final where = _buildWhere();
      final summaryRow = await _db.customSelect(
        '''
        SELECT
          COALESCE(SUM($_totalQuantityExpression), 0) AS total_units,
          COALESCE(SUM($_availableQuantityExpression), 0) AS available_units,
          COALESCE(SUM($_soldQuantityExpression), 0) AS sold_units,
          COALESCE(SUM(u.gross_weight), 0.0) AS gross_weight,
          COALESCE(SUM(
            u.net_weight +
            $_soldWeightExpression
          ), 0.0) AS net_weight,
          COALESCE(SUM(CASE WHEN LOWER(u.status) = 'available' THEN u.net_weight ELSE 0 END), 0.0) AS available_weight,
          COALESCE(SUM($_soldWeightExpression), 0.0) AS sold_weight,
          COALESCE(SUM(u.unit_cost), 0.0) AS stock_value
        FROM stock_item_units u
        LEFT JOIN stock_items s ON s.id = u.stock_item_id
        LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
        LEFT JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
        ${_latestSaleJoin()}
        $_soldWeightJoin
        ${where.sql}
        ''',
        variables: where.variables,
      ).getSingle();

      final rows = await _db.customSelect(
        '''
        SELECT
          u.id,
          u.stock_item_id,
          u.purchase_voucher_id,
          u.batch_code,
          u.unit_code,
          u.piece_no,
          u.metal_type,
          u.item_type,
          u.segment,
          u.item_name,
          u.huid,
          u.gross_weight,
          u.less_weight,
          u.net_weight,
          u.purity_percent,
          u.actual_fine_weight,
          u.valuation_fine_weight,
          u.rate_per_gram,
          u.making_amount,
          u.unit_cost,
          u.supplier_id,
          u.supplier_name,
          u.status,
          u.created_at,
          u.sold_at,
          pv.voucher_no,
          pv.supplier_invoice_no,
          pv.tax_type,
          s.sku AS stock_sku,
          s.company_name,
          sale.bill_no AS sold_bill_no,
          sale.customer_name AS sold_customer_name,
          sale.bill_date AS sold_bill_date,
          sale.final_amount AS sold_bill_amount,
          sale.stock_profit_amount AS sold_profit_amount
        FROM stock_item_units u
        LEFT JOIN stock_items s ON s.id = u.stock_item_id
        LEFT JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
        ${_latestSaleJoin()}
        ${where.sql}
        ORDER BY
          ${_searchPriorityOrder()}
          ${_sortOrder()}
        LIMIT 250
        ''',
        variables: where.variables,
      ).get();

      _summary = StockSearchSummary(
        totalUnits: _readInt(summaryRow, 'total_units'),
        availableUnits: _readInt(summaryRow, 'available_units'),
        soldUnits: _readInt(summaryRow, 'sold_units'),
        grossWeight: _readDouble(summaryRow, 'gross_weight'),
        netWeight: _readDouble(summaryRow, 'net_weight'),
        availableWeight: _readDouble(summaryRow, 'available_weight'),
        soldWeight: _readDouble(summaryRow, 'sold_weight'),
        stockValue: _readDouble(summaryRow, 'stock_value'),
      );
      _results = rows.map(_mapResult).toList(growable: false);
    } catch (error) {
      _summary = StockSearchSummary.empty();
      _results = const [];
      _errorMessage = 'Stock search could not be loaded. $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchText(String value) {
    _searchText = value;
    load();
  }

  void setStatusFilter(String value) {
    _statusFilter = value;
    load();
  }

  void setMetalFilter(String value) {
    _metalFilter = value;
    load();
  }

  void setTrackingFilter(String value) {
    _trackingFilter = value;
    load();
  }

  void setSortMode(String value) {
    _sortMode = value;
    load();
  }

  void clearFilters() {
    _searchText = '';
    _statusFilter = 'All';
    _metalFilter = 'All';
    _trackingFilter = 'All';
    _sortMode = 'Relevance';
    load();
  }

  _SearchWhere _buildWhere() {
    final clauses = <String>[];
    final variables = <drift.Variable>[];

    if (_statusFilter != 'All') {
      clauses.add('LOWER(u.status) = ?');
      variables.add(drift.Variable<String>(_statusFilter.toLowerCase()));
    }

    if (_metalFilter != 'All') {
      clauses.add('LOWER(u.metal_type) = ?');
      variables.add(drift.Variable<String>(_metalFilter.toLowerCase()));
    }

    if (_trackingFilter == 'HUID Linked') {
      clauses.add("TRIM(COALESCE(u.huid, '')) <> ''");
    } else if (_trackingFilter == 'Weight Tracked') {
      clauses.add("TRIM(COALESCE(u.huid, '')) = ''");
    }

    final query = _searchText.trim().toLowerCase();
    if (query.isNotEmpty) {
      final pattern = '%$query%';
      clauses.add('''
      (
        LOWER(COALESCE(u.huid, '')) LIKE ? OR
        LOWER(COALESCE(u.unit_code, '')) LIKE ? OR
        LOWER(COALESCE(u.batch_code, '')) LIKE ? OR
        LOWER(COALESCE(s.sku, '')) LIKE ? OR
        LOWER(COALESCE(u.item_name, '')) LIKE ? OR
        LOWER(COALESCE(u.item_type, '')) LIKE ? OR
        LOWER(COALESCE(u.segment, '')) LIKE ? OR
        LOWER(COALESCE(s.sub_category, '')) LIKE ? OR
        LOWER(COALESCE(u.status, '')) LIKE ? OR
        LOWER(COALESCE(u.metal_type, '')) LIKE ? OR
        LOWER(COALESCE(u.company_name, s.company_name, '')) LIKE ? OR
        LOWER(COALESCE(u.supplier_name, '')) LIKE ? OR
        LOWER(COALESCE(pv.party_name, '')) LIKE ? OR
        LOWER(COALESCE(pv.voucher_no, '')) LIKE ? OR
        LOWER(COALESCE(pv.supplier_invoice_no, '')) LIKE ? OR
        LOWER(COALESCE(sale.bill_no, '')) LIKE ? OR
        LOWER(COALESCE(sale.customer_name, '')) LIKE ? OR
        CAST(COALESCE(u.net_weight, 0) AS TEXT) LIKE ?
      )
      ''');
      for (var index = 0; index < 18; index++) {
        variables.add(drift.Variable<String>(pattern));
      }
    }

    return _SearchWhere(
      clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}',
      variables,
    );
  }

  String _searchPriorityOrder() {
    final query = _searchText.trim().toLowerCase().replaceAll("'", "''");
    if (query.isEmpty) return '';
    return '''
          CASE
            WHEN LOWER(COALESCE(u.huid, '')) = '$query' THEN 0
            WHEN LOWER(COALESCE(u.unit_code, '')) = '$query' THEN 1
            WHEN LOWER(COALESCE(u.batch_code, '')) = '$query' THEN 2
            WHEN LOWER(COALESCE(pv.supplier_invoice_no, '')) = '$query' THEN 3
            WHEN LOWER(COALESCE(sale.bill_no, '')) = '$query' THEN 4
            WHEN LOWER(COALESCE(s.sku, '')) = '$query' THEN 5
            WHEN LOWER(COALESCE(u.item_name, '')) LIKE '$query%' THEN 6
            WHEN LOWER(COALESCE(u.item_type, '')) LIKE '$query%' THEN 7
            ELSE 9
          END,
    ''';
  }

  String _latestSaleJoin() {
    return '''
        LEFT JOIN (
          SELECT *
          FROM (
            SELECT
              bi.linked_stock_unit_id,
              bi.linked_stock_item_id,
              bi.linked_stock_sku,
              bi.huid,
              bi.stock_profit_amount,
              b.bill_no,
              b.customer_name,
              b.bill_date,
              b.final_amount,
              ROW_NUMBER() OVER (
                PARTITION BY
                  COALESCE(
                    CAST(bi.linked_stock_unit_id AS TEXT),
                    CAST(bi.linked_stock_item_id AS TEXT),
                    NULLIF(LOWER(COALESCE(bi.linked_stock_sku, '')), ''),
                    NULLIF(LOWER(COALESCE(bi.huid, '')), '')
                  )
                ORDER BY b.bill_date DESC, b.id DESC
              ) AS sale_rank
            FROM bill_items bi
            INNER JOIN bills b ON b.id = bi.bill_id
            WHERE UPPER(COALESCE(b.status, 'ACTIVE')) <> 'VOID'
          ) ranked_sale
          WHERE sale_rank = 1
        ) sale ON (
          sale.linked_stock_unit_id = u.id OR
          sale.linked_stock_item_id = u.stock_item_id OR
          LOWER(COALESCE(sale.linked_stock_sku, '')) = LOWER(COALESCE(u.unit_code, '')) OR
          (
            TRIM(COALESCE(u.huid, '')) <> '' AND
            LOWER(COALESCE(sale.huid, '')) = LOWER(COALESCE(u.huid, ''))
          )
        )
    ''';
  }

  String _sortOrder() {
    switch (_sortMode) {
      case 'Newest':
        return 'u.created_at DESC, u.id DESC';
      case 'Weight High':
        return 'u.net_weight DESC, u.created_at DESC, u.id DESC';
      case 'Fine High':
        return 'u.actual_fine_weight DESC, u.created_at DESC, u.id DESC';
      case 'Value High':
        return 'u.unit_cost DESC, u.created_at DESC, u.id DESC';
      default:
        return '''
          CASE WHEN LOWER(u.status) = 'available' THEN 0 ELSE 1 END,
          u.created_at DESC,
          u.id DESC
        ''';
    }
  }

  StockSearchResult _mapResult(drift.QueryRow row) {
    return StockSearchResult(
      id: _readInt(row, 'id'),
      stockItemId: _readNullableInt(row, 'stock_item_id'),
      purchaseVoucherId: _readNullableInt(row, 'purchase_voucher_id'),
      batchCode: _readString(row, 'batch_code'),
      unitCode: _readString(row, 'unit_code'),
      pieceNo: _readInt(row, 'piece_no'),
      metalType: _readString(row, 'metal_type'),
      itemType: _readString(row, 'item_type'),
      segment: _readString(row, 'segment'),
      itemName: _readString(row, 'item_name'),
      huid: _readString(row, 'huid'),
      grossWeight: _readDouble(row, 'gross_weight'),
      lessWeight: _readDouble(row, 'less_weight'),
      netWeight: _readDouble(row, 'net_weight'),
      purityPercent: _readDouble(row, 'purity_percent'),
      actualFineWeight: _readDouble(row, 'actual_fine_weight'),
      valuationFineWeight: _readDouble(row, 'valuation_fine_weight'),
      ratePerGram: _readDouble(row, 'rate_per_gram'),
      makingAmount: _readDouble(row, 'making_amount'),
      unitCost: _readDouble(row, 'unit_cost'),
      supplierId: _readNullableInt(row, 'supplier_id'),
      supplierName: _firstNonEmpty([
        _readString(row, 'supplier_name'),
        _readString(row, 'company_name'),
      ]),
      status: _readString(row, 'status').isEmpty
          ? 'Available'
          : _readString(row, 'status'),
      createdAt: _readDate(row, 'created_at'),
      soldAt: _readDate(row, 'sold_at'),
      voucherNo: _readString(row, 'voucher_no'),
      supplierInvoiceNo: _readString(row, 'supplier_invoice_no'),
      taxType: _readString(row, 'tax_type'),
      soldBillNo: _readString(row, 'sold_bill_no'),
      soldCustomerName: _readString(row, 'sold_customer_name'),
      soldBillDate: _readDate(row, 'sold_bill_date'),
      soldBillAmount: _readDouble(row, 'sold_bill_amount'),
      soldProfitAmount: _readDouble(row, 'sold_profit_amount'),
    );
  }

  int _readInt(drift.QueryRow row, String key) {
    return (row.data[key] as num?)?.toInt() ?? 0;
  }

  int? _readNullableInt(drift.QueryRow row, String key) {
    return (row.data[key] as num?)?.toInt();
  }

  double _readDouble(drift.QueryRow row, String key) {
    return (row.data[key] as num?)?.toDouble() ?? 0;
  }

  String _readString(drift.QueryRow row, String key) {
    return (row.data[key] as String?)?.trim() ?? '';
  }

  DateTime? _readDate(drift.QueryRow row, String key) {
    final raw = row.data[key];
    if (raw is DateTime) return raw;
    final value = (raw as num?)?.toInt();
    if (value == null || value <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty) return clean;
    }
    return '';
  }

  Future<void> _ensureSearchSchema() async {
    await _db.ensureStockInventorySchema();
  }
}

class _SearchWhere {
  final String sql;
  final List<drift.Variable> variables;

  const _SearchWhere(this.sql, this.variables);
}
