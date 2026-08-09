import 'package:flutter/foundation.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_grade_repository.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_grade_models.dart';

class MetalValuationGradeController extends ChangeNotifier {
  final String metalType;
  final MetalValuationGradeRepository _repository;

  MetalValuationGradeSnapshot _snapshot;
  bool _isLoading = false;
  String? _errorMessage;

  MetalValuationGradeController({
    required this.metalType,
    MetalValuationGradeRepository? repository,
  })  : _repository = repository ?? MetalValuationGradeRepository(),
        _snapshot = MetalValuationGradeSnapshot.empty(metalType);

  MetalValuationGradeSnapshot get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _snapshot = await _repository.fetchGradeSnapshot(metalType);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();
}
