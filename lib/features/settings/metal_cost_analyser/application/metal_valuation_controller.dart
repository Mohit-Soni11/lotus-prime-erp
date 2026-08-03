import 'package:flutter/foundation.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_repository.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

enum MetalValuationLoadState { idle, loading, ready, error }

class MetalValuationController extends ChangeNotifier {
  final MetalValuationRepository _repository;

  MetalValuationLoadState _state = MetalValuationLoadState.idle;
  MetalValuationFilter _filter = MetalValuationFilter.all;
  MetalValuationSnapshot _snapshot = MetalValuationSnapshot.empty;
  String? _errorMessage;

  MetalValuationController({MetalValuationRepository? repository})
      : _repository = repository ?? MetalValuationRepository();

  MetalValuationLoadState get state => _state;
  MetalValuationFilter get filter => _filter;
  MetalValuationSnapshot get snapshot => _snapshot;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == MetalValuationLoadState.loading;
  bool get hasError => _state == MetalValuationLoadState.error;

  Future<void> load() async {
    _state = MetalValuationLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _snapshot = await _repository.fetchSnapshot(filter: _filter);
      _state = MetalValuationLoadState.ready;
    } catch (error, stackTrace) {
      debugPrint('Metal valuation load failed: $error\n$stackTrace');
      _errorMessage =
          'Unable to load metal valuation data. Please refresh the desk.';
      _state = MetalValuationLoadState.error;
    }

    notifyListeners();
  }

  Future<void> refresh() => load();

  Future<void> setFilter(MetalValuationFilter filter) async {
    if (_filter == filter && _state == MetalValuationLoadState.ready) return;
    _filter = filter;
    await load();
  }
}
