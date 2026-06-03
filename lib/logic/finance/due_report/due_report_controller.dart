import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/finance/due_report/due_report_model.dart';
import '../../../repositories/finance/due_report_repository.dart';

class DueReportController extends ChangeNotifier {
  DueReportController({DueReportRepository? repository})
      : _repository = repository ?? DueReportRepository() {
    searchCtrl.addListener(_onSearchChanged);
    _startWatch();
  }

  final DueReportRepository _repository;
  final TextEditingController searchCtrl = TextEditingController();

  StreamSubscription<List<DueBillModel>>? _watchSub;

  bool _disposed = false;
  List<DueBillModel> _allBills = [];
  List<DueCustomerGroupModel> _groups = [];
  DueCustomerGroupModel? _selectedGroup;
  DueReportStatsModel _stats = DueReportStatsModel.empty();
  DueReportFilter _filter = DueReportFilter.all;
  DueReportSort _sort = DueReportSort.highestDue;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  List<DueCustomerGroupModel> get groups => _groups;
  DueCustomerGroupModel? get selectedGroup => _selectedGroup;
  DueReportStatsModel get stats => _stats;
  DueReportFilter get filter => _filter;
  DueReportSort get sort => _sort;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int get allDueBillCount => _allBills.length;

  static final NumberFormat _amountFmt = NumberFormat('#,##,##0.00', 'en_IN');
  static final NumberFormat _compactFmt = NumberFormat('#,##,##0', 'en_IN');
  static final DateFormat _dateFmt = DateFormat('dd MMM yyyy');
  static final DateFormat _shortDateFmt = DateFormat('dd MMM');

  static String formatAmount(double amount) =>
      'Rs ${_amountFmt.format(amount)}';
  static String formatCompact(double amount) =>
      'Rs ${_compactFmt.format(amount)}';
  static String formatDate(DateTime date) => _dateFmt.format(date);
  static String formatShortDate(DateTime date) => _shortDateFmt.format(date);

  void _notifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _startWatch() {
    _watchSub?.cancel();
    _watchSub = _repository.watchDueBills().listen(
      (bills) {
        if (_disposed) return;
        _allBills = bills;
        _isLoading = false;
        _errorMessage = null;
        _applyViewState();
      },
      onError: (error) {
        if (_disposed) return;
        _isLoading = false;
        _errorMessage = 'Unable to load due report.';
        _notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    if (_disposed) return;
    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();

    try {
      final bills = await _repository.fetchDueBills();
      if (_disposed) return;
      _allBills = bills;
      _isLoading = false;
      _applyViewState();
    } catch (_) {
      if (_disposed) return;
      _isLoading = false;
      _errorMessage = 'Refresh failed.';
      _notifyListeners();
    }
  }

  void setFilter(DueReportFilter value) {
    if (_filter == value) return;
    _filter = value;
    _applyViewState();
  }

  void setSort(DueReportSort value) {
    if (_sort == value) return;
    _sort = value;
    _applyViewState();
  }

  void selectGroup(DueCustomerGroupModel group) {
    _selectedGroup = group;
    _notifyListeners();
  }

  void clearSearch() {
    searchCtrl.clear();
  }

  void _onSearchChanged() {
    if (_disposed) return;
    _searchQuery = searchCtrl.text.trim();
    _applyViewState();
  }

  void _applyViewState() {
    if (_disposed) return;
    final allGroups = _groupBills(_allBills);
    _stats = DueReportStatsModel.fromGroups(allGroups);

    var visibleBills = _allBills.where(_matchesFilter).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      visibleBills = visibleBills.where((bill) {
        return bill.customerName.toLowerCase().contains(q) ||
            bill.mobile.toLowerCase().contains(q) ||
            bill.city.toLowerCase().contains(q) ||
            bill.address.toLowerCase().contains(q) ||
            bill.billNo.toLowerCase().contains(q) ||
            bill.statusLabel.toLowerCase().contains(q);
      }).toList();
    }

    _groups = _groupBills(visibleBills);
    _sortGroups();
    _syncSelection();
    _notifyListeners();
  }

  bool _matchesFilter(DueBillModel bill) {
    switch (_filter) {
      case DueReportFilter.all:
        return true;
      case DueReportFilter.overdue:
        return bill.isOverdue;
      case DueReportFilter.dueToday:
        return bill.isDueToday;
      case DueReportFilter.partial:
        return bill.isPartial;
      case DueReportFilter.unpaid:
        return bill.isUnpaid;
      case DueReportFilter.noPromise:
        return bill.promiseDate == null;
    }
  }

  List<DueCustomerGroupModel> _groupBills(List<DueBillModel> bills) {
    final Map<String, List<DueBillModel>> map = {};
    for (final bill in bills) {
      map.putIfAbsent(bill.groupKey, () => []).add(bill);
    }
    return map.values
        .where((items) => items.isNotEmpty)
        .map(DueCustomerGroupModel.fromBills)
        .toList();
  }

  void _sortGroups() {
    switch (_sort) {
      case DueReportSort.highestDue:
        _groups.sort((a, b) => b.totalDue.compareTo(a.totalDue));
        break;
      case DueReportSort.oldestBill:
        _groups.sort((a, b) => a.oldestBillDate.compareTo(b.oldestBillDate));
        break;
      case DueReportSort.customerName:
        _groups.sort((a, b) => a.customerName.compareTo(b.customerName));
        break;
      case DueReportSort.billCount:
        _groups.sort((a, b) => b.billCount.compareTo(a.billCount));
        break;
      case DueReportSort.promiseDate:
        _groups.sort((a, b) => _promiseValue(a).compareTo(_promiseValue(b)));
        break;
    }
  }

  int _promiseValue(DueCustomerGroupModel group) {
    return group.nearestPromiseDate?.millisecondsSinceEpoch ?? 9999999999999;
  }

  void _syncSelection() {
    final previousKey = _selectedGroup?.key;
    if (_groups.isEmpty) {
      _selectedGroup = null;
      return;
    }
    if (previousKey != null) {
      for (final group in _groups) {
        if (group.key == previousKey) {
          _selectedGroup = group;
          return;
        }
      }
    }
    _selectedGroup = _groups.first;
  }

  @override
  void dispose() {
    _disposed = true;
    _watchSub?.cancel();
    searchCtrl.removeListener(_onSearchChanged);
    searchCtrl.dispose();
    super.dispose();
  }
}
