import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_change_watcher.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_repository.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

enum MetalValuationLoadState { idle, loading, ready, error }

class MetalValuationController extends ChangeNotifier {
  final MetalValuationSnapshotReader _repository;
  final MetalValuationChangeStream _changeWatcher;

  MetalValuationLoadState _state = MetalValuationLoadState.idle;
  MetalValuationFilter _filter = MetalValuationFilter.all;
  MetalValuationSnapshot _snapshot = MetalValuationSnapshot.empty;
  String? _errorMessage;
  StreamSubscription<void>? _changeSubscription;
  Timer? _refreshDebounce;
  bool _isDisposed = false;
  bool _hasSeenInitialChangeEvent = false;
  int _loadToken = 0;

  MetalValuationController({
    MetalValuationSnapshotReader? repository,
    MetalValuationChangeStream? changeWatcher,
    MetalValuationFilter initialFilter = MetalValuationFilter.all,
  })  : _repository = repository ?? MetalValuationRepository(),
        _changeWatcher = changeWatcher ?? MetalValuationChangeWatcher(),
        _filter = initialFilter;

  MetalValuationLoadState get state => _state;
  MetalValuationFilter get filter => _filter;
  MetalValuationSnapshot get snapshot => _snapshot;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == MetalValuationLoadState.loading;
  bool get hasError => _state == MetalValuationLoadState.error;

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
        debugPrint('Metal valuation live refresh failed: $error\n$stackTrace');
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
      _state = MetalValuationLoadState.loading;
    }
    _errorMessage = null;
    if (!silent) notifyListeners();

    try {
      final snapshot = await _repository.fetchSnapshot(filter: _filter);
      if (_isDisposed || token != _loadToken) return;
      _snapshot = snapshot;
      _state = MetalValuationLoadState.ready;
    } catch (error, stackTrace) {
      if (_isDisposed || token != _loadToken) return;
      debugPrint('Metal valuation load failed: $error\n$stackTrace');
      _errorMessage =
          'Unable to load metal valuation data. Please refresh the desk.';
      _state = MetalValuationLoadState.error;
    }

    if (!_isDisposed) notifyListeners();
  }

  Future<void> refresh() => load();

  Future<void> setFilter(MetalValuationFilter filter) async {
    if (_filter == filter && _state == MetalValuationLoadState.ready) return;
    _filter = filter;
    await load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshDebounce?.cancel();
    _changeSubscription?.cancel();
    super.dispose();
  }
}
