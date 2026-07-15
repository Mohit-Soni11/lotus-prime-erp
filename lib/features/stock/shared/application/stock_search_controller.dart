import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_search/stock_search_models.dart';

class StockSearchController extends ChangeNotifier {
  final AppDatabase _db;

  StockSearchController(this._db);

  bool _isLoading = false;
  String _searchText = '';
  String _statusFilter = 'All';
  String _metalFilter = 'All';
  String _trackingFilter = 'All';
  String? _errorMessage;
  StockSearchSummary _summary = StockSearchSummary.empty();
  List<StockSearchResult> _results = const [];

  bool get isLoading => _isLoading;
  String get searchText => _searchText;
  String get statusFilter => _statusFilter;
  String get metalFilter => _metalFilter;
  String get trackingFilter => _trackingFilter;
  String? get errorMessage => _errorMessage;
  StockSearchSummary get summary => _summary;
  List<StockSearchResult> get results => _results;

  static const List<String> statusFilters = [
    'All',
    'Available',
    'Sold',
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

  static String statusFilterLabel(String value) {
    switch (value) {
      case 'Available':
        return 'Available Stock';
      case 'Sold':
        return 'Sold Stock';
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
      final where = _buildWhere();
      final summaryRow = await _db.customSelect(
        '''
        SELECT
          COUNT(u.id) AS total_units,
          COALESCE(SUM(CASE WHEN LOWER(u.status) = 'available' THEN 1 ELSE 0 END), 0) AS available_units,
          COALESCE(SUM(CASE WHEN LOWER(u.status) = 'sold' THEN 1 ELSE 0 END), 0) AS sold_units,
          COALESCE(SUM(u.gross_weight), 0.0) AS gross_weight,
          COALESCE(SUM(u.net_weight), 0.0) AS net_weight,
          COALESCE(SUM(u.unit_cost), 0.0) AS stock_value
        FROM stock_item_units u
        LEFT JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
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
          b.bill_no AS sold_bill_no,
          b.customer_name AS sold_customer_name,
          b.bill_date AS sold_bill_date,
          b.final_amount AS sold_bill_amount,
          bi.stock_profit_amount AS sold_profit_amount
        FROM stock_item_units u
        LEFT JOIN purchase_vouchers pv ON pv.id = u.purchase_voucher_id
        LEFT JOIN bill_items bi ON (
          bi.linked_stock_unit_id = u.id OR
          LOWER(COALESCE(bi.linked_stock_sku, '')) = LOWER(COALESCE(u.unit_code, '')) OR
          (
            TRIM(COALESCE(u.huid, '')) <> '' AND
            LOWER(COALESCE(bi.huid, '')) = LOWER(COALESCE(u.huid, ''))
          )
        )
        LEFT JOIN bills b ON b.id = bi.bill_id
        ${where.sql}
        ORDER BY
          ${_searchPriorityOrder()}
          CASE WHEN LOWER(u.status) = 'available' THEN 0 ELSE 1 END,
          u.created_at DESC,
          u.id DESC
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

  void clearFilters() {
    _searchText = '';
    _statusFilter = 'All';
    _metalFilter = 'All';
    _trackingFilter = 'All';
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
        LOWER(COALESCE(u.item_name, '')) LIKE ? OR
        LOWER(COALESCE(u.item_type, '')) LIKE ? OR
        LOWER(COALESCE(u.segment, '')) LIKE ? OR
        LOWER(COALESCE(u.supplier_name, '')) LIKE ? OR
        LOWER(COALESCE(pv.voucher_no, '')) LIKE ? OR
        LOWER(COALESCE(pv.supplier_invoice_no, '')) LIKE ? OR
        CAST(COALESCE(u.net_weight, 0) AS TEXT) LIKE ?
      )
      ''');
      for (var index = 0; index < 10; index++) {
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
            WHEN LOWER(COALESCE(u.item_name, '')) LIKE '$query%' THEN 4
            WHEN LOWER(COALESCE(u.item_type, '')) LIKE '$query%' THEN 5
            ELSE 9
          END,
    ''';
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
      supplierName: _readString(row, 'supplier_name'),
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
}

class _SearchWhere {
  final String sql;
  final List<drift.Variable> variables;

  const _SearchWhere(this.sql, this.variables);
}
