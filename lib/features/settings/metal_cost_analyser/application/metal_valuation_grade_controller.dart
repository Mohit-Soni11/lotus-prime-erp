import 'package:flutter/foundation.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/data/metal_valuation_grade_repository.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_grade_models.dart';
import 'package:lotus_erp/features/settings/metal_cost_analyser/domain/metal_valuation_models.dart';

class MetalValuationGradeController extends ChangeNotifier {
  final String metalType;
  final MetalValuationGradeRepository _repository;

  MetalValuationGradeSnapshot _snapshot;
  List<MetalValuationGradeBatchRow> _gradeBatchRows = const [];
  bool _isLoading = false;
  String? _errorMessage;

  MetalValuationGradeController({
    required this.metalType,
    MetalValuationGradeRepository? repository,
  })  : _repository = repository ?? MetalValuationGradeRepository(),
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

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.fetchGradeSnapshot(metalType),
        _repository.fetchGradeBatchRows(metalType),
      ]);
      _snapshot = results[0] as MetalValuationGradeSnapshot;
      _gradeBatchRows = results[1] as List<MetalValuationGradeBatchRow>;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();
}
