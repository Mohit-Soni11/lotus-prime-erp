import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_change_watcher.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_grade_repository.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_grade_models.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

class MetalValuationGradeController extends ChangeNotifier {
  final String metalType;
  final MetalValuationGradeReader _repository;
  final MetalValuationChangeStream _changeWatcher;

  MetalValuationGradeSnapshot _snapshot;
  List<MetalValuationGradeBatchRow> _gradeBatchRows = const [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<void>? _changeSubscription;
  Timer? _refreshDebounce;
  bool _isDisposed = false;
  bool _hasSeenInitialChangeEvent = false;
  int _loadToken = 0;

  MetalValuationGradeController({
    required this.metalType,
    MetalValuationGradeReader? repository,
    MetalValuationChangeStream? changeWatcher,
  })  : _repository = repository ?? MetalValuationGradeRepository(),
        _changeWatcher = changeWatcher ?? MetalValuationChangeWatcher(),
        _snapshot = MetalValuationGradeSnapshot.empty(metalType);

  MetalValuationGradeSnapshot get snapshot => _snapshot;
  List<MetalValuationGradeBatchRow> get gradeBatchRows => _gradeBatchRows;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  List<BatchValuationRow> batchesForGrade(String gradeLabel) {
    final normalized = gradeLabel.trim().toLowerCase();
    return _gradeBatchRows
        .where((row) => row.gradeLabel.trim().toLowerCase() == normalized)
        .map((row) => row.batch)
        .toList(growable: false);
  }

  void startLiveRefresh() {
    _changeSubscription?.cancel();
    _changeSubscription = _changeWatcher.watch().listen(
      (_) {
        if (!_hasSeenInitialChangeEvent) {
          _hasSeenInitialChangeEvent = true;
          return;
        }
        _scheduleLiveRefresh();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Metal valuation grade live refresh failed: $error\n$stackTrace',
        );
      },
    );
  }

  void _scheduleLiveRefresh() {
    if (_isDisposed) return;
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!_isDisposed) {
        load(silent: true);
      }
    });
  }

  Future<void> load({bool silent = false}) async {
    final token = ++_loadToken;
    if (!silent) {
      _isLoading = true;
    }
    _errorMessage = null;
    if (!silent) notifyListeners();
    try {
      final results = await Future.wait([
        _repository.fetchGradeSnapshot(metalType),
        _repository.fetchGradeBatchRows(metalType),
      ]);
      if (_isDisposed || token != _loadToken) return;
      _snapshot = results[0] as MetalValuationGradeSnapshot;
      _gradeBatchRows = results[1] as List<MetalValuationGradeBatchRow>;
    } catch (error) {
      if (_isDisposed || token != _loadToken) return;
      _errorMessage = error.toString();
    } finally {
      if (!_isDisposed && token == _loadToken) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() => load();

  @override
  void dispose() {
    _isDisposed = true;
    _refreshDebounce?.cancel();
    _changeSubscription?.cancel();
    super.dispose();
  }
}
