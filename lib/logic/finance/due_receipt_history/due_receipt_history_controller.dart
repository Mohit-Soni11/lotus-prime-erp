import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/finance/due_receipt_history/due_receipt_history_model.dart';
import '../../../repositories/finance/due_receipt_history_repository.dart';

class DueReceiptHistoryController extends ChangeNotifier {
  DueReceiptHistoryController({DueReceiptHistoryRepository? repository})
      : _repository = repository ?? DueReceiptHistoryRepository() {
    searchCtrl.addListener(_onSearchChanged);
    _startWatch();
  }

  final DueReceiptHistoryRepository _repository;
  final TextEditingController searchCtrl = TextEditingController();

  StreamSubscription<List<DueReceiptModel>>? _watchSub;

  bool _disposed = false;
  List<DueReceiptModel> _allReceipts = [];
  List<DueReceiptModel> _receipts = [];
  DueReceiptModel? _selectedReceipt;
  DueReceiptStatsModel _stats = DueReceiptStatsModel.empty();
  DueReceiptDateFilter _dateFilter = DueReceiptDateFilter.all;
  DueReceiptModeFilter _modeFilter = DueReceiptModeFilter.all;
  DueReceiptSort _sort = DueReceiptSort.latest;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  List<DueReceiptModel> get receipts => _receipts;
  DueReceiptModel? get selectedReceipt => _selectedReceipt;
  DueReceiptStatsModel get stats => _stats;
  DueReceiptDateFilter get dateFilter => _dateFilter;
  DueReceiptModeFilter get modeFilter => _modeFilter;
  DueReceiptSort get sort => _sort;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int get allReceiptCount => _allReceipts.length;

  static final NumberFormat _amountFmt = NumberFormat('#,##,##0.00', 'en_IN');
  static final NumberFormat _compactFmt = NumberFormat('#,##,##0', 'en_IN');
  static final DateFormat _dateFmt = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _shortDateFmt = DateFormat('dd MMM');

  static String formatAmount(double amount) =>
      'Rs ${_amountFmt.format(amount)}';
  static String formatCompact(double amount) =>
      'Rs ${_compactFmt.format(amount)}';
  static String formatDate(DateTime? date) =>
      date == null ? '-' : _dateFmt.format(date);
  static String formatDateTime(DateTime? date) =>
      date == null ? '-' : _dateTimeFmt.format(date);
  static String formatShortDate(DateTime? date) =>
      date == null ? '-' : _shortDateFmt.format(date);

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  void _startWatch() {
    _watchSub?.cancel();
    _watchSub = _repository.watchReceipts().listen(
      (receipts) {
        if (_disposed) return;
        _allReceipts = receipts;
        _isLoading = false;
        _errorMessage = null;
        _applyViewState();
      },
      onError: (_) {
        if (_disposed) return;
        _isLoading = false;
        _errorMessage = 'Unable to load receipt history.';
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
      final receipts = await _repository.fetchReceipts();
      if (_disposed) return;
      _allReceipts = receipts;
      _isLoading = false;
      _applyViewState();
    } catch (_) {
      if (_disposed) return;
      _isLoading = false;
      _errorMessage = 'Refresh failed.';
      _notifyListeners();
    }
  }

  void setDateFilter(DueReceiptDateFilter value) {
    if (_dateFilter == value) return;
    _dateFilter = value;
    _applyViewState();
  }

  void setModeFilter(DueReceiptModeFilter value) {
    if (_modeFilter == value) return;
    _modeFilter = value;
    _applyViewState();
  }

  void setSort(DueReceiptSort value) {
    if (_sort == value) return;
    _sort = value;
    _applyViewState();
  }

  void selectReceipt(DueReceiptModel receipt) {
    _selectedReceipt = receipt;
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
    var visible = _allReceipts
        .where(_matchesDateFilter)
        .where(_matchesModeFilter)
        .toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      visible = visible.where((receipt) {
        return receipt.customerName.toLowerCase().contains(q) ||
            receipt.mobile.toLowerCase().contains(q) ||
            receipt.billNo.toLowerCase().contains(q) ||
            receipt.receiptNo.toLowerCase().contains(q) ||
            receipt.paymentMode.toLowerCase().contains(q) ||
            receipt.channelLabel.toLowerCase().contains(q) ||
            (receipt.referenceId?.toLowerCase().contains(q) ?? false) ||
            (receipt.description?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    _sortReceipts(visible);
    _receipts = visible;
    _stats = DueReceiptStatsModel.fromReceipts(visible);
    _syncSelection();
    _notifyListeners();
  }

  bool _matchesDateFilter(DueReceiptModel receipt) {
    final today = DueReceiptDate.only(DateTime.now());
    final receiptDay = DueReceiptDate.only(receipt.receiptDate);
    switch (_dateFilter) {
      case DueReceiptDateFilter.all:
        return true;
      case DueReceiptDateFilter.today:
        return receiptDay.isAtSameMomentAs(today);
      case DueReceiptDateFilter.last7Days:
        return !receiptDay.isBefore(today.subtract(const Duration(days: 6)));
      case DueReceiptDateFilter.last30Days:
        return !receiptDay.isBefore(today.subtract(const Duration(days: 29)));
      case DueReceiptDateFilter.dueMarked:
        return receipt.isDueMarked;
    }
  }

  bool _matchesModeFilter(DueReceiptModel receipt) {
    final mode = receipt.modeKey;
    switch (_modeFilter) {
      case DueReceiptModeFilter.all:
        return true;
      case DueReceiptModeFilter.cash:
        return mode == 'CASH';
      case DueReceiptModeFilter.upi:
        return mode == 'UPI';
      case DueReceiptModeFilter.card:
        return mode == 'CARD';
      case DueReceiptModeFilter.bank:
        return receipt.ledgerSource == 'BANK' ||
            mode == 'BANK' ||
            mode == 'NEFT' ||
            mode == 'RTGS' ||
            mode == 'IMPS';
      case DueReceiptModeFilter.cheque:
        return mode == 'CHEQUE';
    }
  }

  void _sortReceipts(List<DueReceiptModel> receipts) {
    switch (_sort) {
      case DueReceiptSort.latest:
        receipts.sort((a, b) => b.receiptDate.compareTo(a.receiptDate));
        break;
      case DueReceiptSort.highestAmount:
        receipts.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case DueReceiptSort.customerName:
        receipts.sort((a, b) => a.customerName.compareTo(b.customerName));
        break;
      case DueReceiptSort.billNo:
        receipts.sort((a, b) => a.billNo.compareTo(b.billNo));
        break;
    }
  }

  void _syncSelection() {
    final previousId = _selectedReceipt?.id;
    if (_receipts.isEmpty) {
      _selectedReceipt = null;
      return;
    }
    if (previousId != null) {
      for (final receipt in _receipts) {
        if (receipt.id == previousId) {
          _selectedReceipt = receipt;
          return;
        }
      }
    }
    _selectedReceipt = _receipts.first;
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
