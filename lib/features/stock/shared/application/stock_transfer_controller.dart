import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:lotus_erp/features/stock/shared/data/repositories/stock_transfer_repository.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/stock_transfer/stock_transfer_models.dart';

class StockTransferController extends ChangeNotifier {
  final StockTransferRepository _repository;

  StockTransferController(this._repository);

  StockTransferSummary _summary = StockTransferSummary.empty();
  List<StockTransferUnit> _availableUnits = const [];
  List<StockTransferRecord> _recentTransfers = const [];
  final List<StockTransferUnit> _selectedUnits = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchText = '';
  String _metalFilter = 'All';
  Timer? _searchDebounce;

  StockTransferSummary get summary => _summary;
  List<StockTransferUnit> get availableUnits => _availableUnits;
  List<StockTransferRecord> get recentTransfers => _recentTransfers;
  List<StockTransferUnit> get selectedUnits =>
      List.unmodifiable(_selectedUnits);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get searchText => _searchText;
  String get metalFilter => _metalFilter;

  int get selectedPieces => _selectedUnits.length;
  double get selectedNetWeight =>
      _selectedUnits.fold(0, (sum, unit) => sum + unit.netWeight);
  double get selectedGrossWeight =>
      _selectedUnits.fold(0, (sum, unit) => sum + unit.grossWeight);
  double get selectedFineWeight =>
      _selectedUnits.fold(0, (sum, unit) => sum + unit.fineWeight);

  bool isSelected(int unitId) {
    return _selectedUnits.any((unit) => unit.id == unitId);
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.ensureSchema();
      final results = await Future.wait([
        _repository.loadSummary(),
        _repository.searchAvailableUnits(
          query: _searchText,
          metal: _metalFilter,
        ),
        _repository.loadRecentTransfers(),
      ]);
      _summary = results[0] as StockTransferSummary;
      _availableUnits = results[1] as List<StockTransferUnit>;
      _recentTransfers = results[2] as List<StockTransferRecord>;
      _removeUnavailableSelections();
    } catch (error) {
      _summary = StockTransferSummary.empty();
      _availableUnits = const [];
      _recentTransfers = const [];
      _errorMessage = 'Stock transfer could not be loaded. $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchText(String value) {
    _searchText = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), () {
      load();
    });
  }

  void setMetalFilter(String value) {
    if (_metalFilter == value) return;
    _metalFilter = value;
    load();
  }

  void toggleUnit(StockTransferUnit unit) {
    final index = _selectedUnits.indexWhere((entry) => entry.id == unit.id);
    if (index >= 0) {
      _selectedUnits.removeAt(index);
    } else {
      _selectedUnits.add(unit);
    }
    notifyListeners();
  }

  void removeUnit(int unitId) {
    _selectedUnits.removeWhere((unit) => unit.id == unitId);
    notifyListeners();
  }

  void clearSelection() {
    _selectedUnits.clear();
    notifyListeners();
  }

  Future<StockTransferCreated> createTransfer(StockTransferForm form) async {
    if (_isSaving) throw StateError('Transfer is already being saved.');
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.createTransfer(
        form: form,
        units: selectedUnits,
      );
      _selectedUnits.clear();
      await _reloadQuietly();
      return result;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> receiveTransfer({
    required StockTransferRecord transfer,
    required String receivedBy,
  }) async {
    if (_isSaving) return;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.receiveTransfer(
        transfer: transfer,
        receivedBy: receivedBy,
      );
      await _reloadQuietly();
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> cancelTransfer({
    required StockTransferRecord transfer,
    required String reason,
  }) async {
    if (_isSaving) return;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.cancelTransfer(
        transfer: transfer,
        reason: reason,
      );
      await _reloadQuietly();
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<List<StockTransferLine>> loadLines(int transferId) {
    return _repository.loadTransferLines(transferId);
  }

  Future<void> _reloadQuietly() async {
    final results = await Future.wait([
      _repository.loadSummary(),
      _repository.searchAvailableUnits(
        query: _searchText,
        metal: _metalFilter,
      ),
      _repository.loadRecentTransfers(),
    ]);
    _summary = results[0] as StockTransferSummary;
    _availableUnits = results[1] as List<StockTransferUnit>;
    _recentTransfers = results[2] as List<StockTransferRecord>;
    _removeUnavailableSelections();
  }

  void _removeUnavailableSelections() {
    final availableIds = _availableUnits.map((unit) => unit.id).toSet();
    _selectedUnits.removeWhere((unit) => !availableIds.contains(unit.id));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
