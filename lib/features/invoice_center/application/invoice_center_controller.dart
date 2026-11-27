import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

import '../data/invoice_center_repository.dart';
import '../domain/invoice_center_models.dart';

class InvoiceCenterController extends ChangeNotifier {
  InvoiceCenterController({
    required InvoiceCenterRepository repository,
    DateTime? initialMonth,
    this.pageSize = 10,
  })  : _repository = repository,
        _month = initialMonth ?? DateTime.now();

  final InvoiceCenterRepository _repository;
  final int pageSize;

  DateTime _month;
  InvoiceCenterTab _tab = InvoiceCenterTab.all;
  String _search = '';
  String _metal = '';
  String _status = '';
  double? _minAmount;
  double? _maxAmount;
  int _page = 1;
  int _generation = 0;
  Timer? _searchDebounce;
  bool _disposed = false;

  bool isLoading = false;
  String? error;
  InvoiceCenterSnapshot? snapshot;

  DateTime get month => _month;
  InvoiceCenterTab get tab => _tab;
  String get search => _search;
  String get metal => _metal;
  String get status => _status;
  double? get minAmount => _minAmount;
  double? get maxAmount => _maxAmount;
  int get page => _page;
  int get totalPages =>
      ((snapshot?.totalRows ?? 0) / pageSize).ceil().clamp(1, 1 << 30);
  bool get usesMonth =>
      _tab != InvoiceCenterTab.due && _tab != InvoiceCenterTab.advance;

  InvoiceCenterQuery get query => InvoiceCenterQuery(
        tab: _tab,
        month: _month,
        page: _page,
        pageSize: pageSize,
        search: _search,
        metal: _metal,
        status: _status,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
      );

  Future<void> load() async {
    final generation = ++_generation;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final loaded = await _repository.load(query);
      if (_disposed || generation != _generation) return;
      snapshot = loaded;
    } catch (failure, stackTrace) {
      if (_disposed || generation != _generation) return;
      AppLogger.error('Invoice Center load failed.',
          error: failure, stackTrace: stackTrace);
      error = 'Invoices could not be loaded.';
    } finally {
      if (!_disposed && generation == _generation) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void selectTab(InvoiceCenterTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    _status = '';
    _page = 1;
    load();
  }

  void changeMonth(int delta) {
    if (!usesMonth) return;
    _month = DateTime(_month.year, _month.month + delta);
    _page = 1;
    load();
  }

  void setSearch(String value) {
    _search = value;
    _page = 1;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), load);
  }

  void setMetal(String value) {
    if (_metal == value) return;
    _metal = value;
    _page = 1;
    load();
  }

  void setStatus(String value) {
    if (_status == value) return;
    _status = value;
    _page = 1;
    load();
  }

  void setAmountRange({double? min, double? max}) {
    _minAmount = min;
    _maxAmount = max;
    _page = 1;
    load();
  }

  void setPage(int page) {
    if (page < 1 || page > totalPages || page == _page) return;
    _page = page;
    load();
  }

  Future<List<InvoiceCenterRow>> exportRows() => _repository.exportRows(query);

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _searchDebounce?.cancel();
    super.dispose();
  }
}
