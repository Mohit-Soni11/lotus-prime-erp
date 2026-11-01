import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_enums.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/supplier/supplier_model.dart';
import 'package:lotus_erp/repositories/supplier/supplier_repository.dart';

enum SupplierListState { loading, loaded, empty, error }

class SupplierListLogic extends ChangeNotifier {
  SupplierListLogic({SupplierRepository? repository, AppDatabase? database})
      : _database = database ?? AppDatabase(),
        _repository =
            repository ?? SupplierRepository(database ?? AppDatabase()) {
    _subscription =
        _database.select(_database.suppliers).watch().skip(1).listen(
              (_) => refresh(showLoading: false),
              onError: (Object error, StackTrace stack) => AppLogger.error(
                'Supplier list watcher failed.',
                error: error,
                stackTrace: stack,
              ),
            );
    refresh();
  }

  final AppDatabase _database;
  final SupplierRepository _repository;
  late final StreamSubscription<List<Supplier>> _subscription;
  List<SupplierListItemModel> _source = const [];
  List<SupplierListItemModel> _visible = const [];
  SupplierListState _state = SupplierListState.loading;
  SupplierFilter _filter = SupplierFilter.all;
  String _query = '';
  String? _error;
  int _requestId = 0;
  bool _disposed = false;

  List<SupplierListItemModel> get suppliers => _visible;
  int get totalSuppliers => _source.length;
  SupplierListState get state => _state;
  SupplierFilter get activeFilter => _filter;
  bool get isSearching => _query.isNotEmpty;
  String? get errorMessage => _error;

  Future<void> refresh({bool showLoading = true}) async {
    final request = ++_requestId;
    if (showLoading) {
      _state = SupplierListState.loading;
      notifyListeners();
    }
    try {
      final suppliers = await _repository.getAllSuppliers();
      if (_disposed || request != _requestId) return;
      _source = suppliers;
      _error = null;
      _apply();
    } catch (error, stack) {
      if (_disposed || request != _requestId) return;
      AppLogger.error('Supplier list load failed.',
          error: error, stackTrace: stack);
      _error = 'Suppliers could not be loaded. Please try again.';
      if (_source.isEmpty) _state = SupplierListState.error;
    }
    notifyListeners();
  }

  void onSearchChanged(String value) {
    _query = value.trim().toLowerCase();
    _apply();
    notifyListeners();
  }

  void clearSearch() => onSearchChanged('');

  void setFilter(SupplierFilter value) {
    _filter = value;
    _apply();
    notifyListeners();
  }

  void _apply() {
    _visible = _source.where((supplier) {
      if (_filter != SupplierFilter.all &&
          supplier.supplierType.label != _filter.label) {
        return false;
      }
      if (_query.isEmpty) return true;
      return supplier.businessName.toLowerCase().contains(_query) ||
          supplier.mobile.contains(_query) ||
          (supplier.contactPersonName?.toLowerCase().contains(_query) ??
              false) ||
          (supplier.gstNumber?.toLowerCase().contains(_query) ?? false);
    }).toList();
    _state =
        _visible.isEmpty ? SupplierListState.empty : SupplierListState.loaded;
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    _subscription.cancel();
    super.dispose();
  }
}
