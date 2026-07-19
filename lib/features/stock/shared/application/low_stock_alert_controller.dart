import 'package:flutter/foundation.dart';

import 'package:lotus_erp/features/stock/shared/data/repositories/low_stock_alert_repository.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';

class LowStockAlertController extends ChangeNotifier {
  final LowStockAlertRepository _repository;

  LowStockAlertController(this._repository);

  LowStockAlertDashboard _dashboard = LowStockAlertDashboard.empty();
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedMetalType;
  String? _selectedGradeLabel;

  LowStockAlertDashboard get dashboard => _dashboard;
  LowStockAlertSummary get summary => _dashboard.summary;
  List<LowStockRiskCard> get riskCards => _dashboard.riskCards;
  List<LowStockStockCard> get metalCards => _dashboard.metalCards;
  List<LowStockStockCard> get itemGroupCards => _dashboard.itemGroupCards;
  List<LowStockStockCard> get gradeCards {
    final selectedMetal = _selectedMetalType;
    if (selectedMetal == null) return const [];
    return _dashboard.gradeCards
        .where((card) => _same(card.metalType, selectedMetal))
        .toList(growable: false);
  }

  List<LowStockStockCard> get itemTypeCards {
    final selectedMetal = _selectedMetalType;
    final selectedGrade = _selectedGradeLabel;
    if (selectedMetal == null || selectedGrade == null) return const [];
    return _dashboard.itemTypeCards
        .where(
          (card) =>
              _same(card.metalType, selectedMetal) &&
              _same(card.gradeLabel, selectedGrade),
        )
        .toList(growable: false);
  }

  List<LowStockStockCard> groupCardsForMetal(String metalType) {
    final source = _same(metalType, 'Silver')
        ? _dashboard.itemGroupCards
        : _dashboard.gradeCards;
    return source
        .where((card) => _same(card.metalType, metalType))
        .toList(growable: false);
  }

  List<LowStockStockCard> detailCardsForGroup(LowStockStockCard groupCard) {
    if (_same(groupCard.metalType, 'Silver') ||
        groupCard.level == LowStockCardLevel.itemGroup) {
      return _dashboard.itemTypeCards
          .where(
            (card) =>
                _same(card.metalType, groupCard.metalType) &&
                _same(card.itemType, groupCard.itemType),
          )
          .toList(growable: false);
    }
    return _dashboard.itemTypeCards
        .where(
          (card) =>
              _same(card.metalType, groupCard.metalType) &&
              _same(card.gradeLabel, groupCard.gradeLabel),
        )
        .toList(growable: false);
  }

  List<LowStockAlertRule> get rules => _dashboard.rules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedMetalType => _selectedMetalType;
  String? get selectedGradeLabel => _selectedGradeLabel;

  void selectMetal(LowStockStockCard card) {
    _selectedMetalType = card.metalType;
    _selectedGradeLabel = null;
    notifyListeners();
  }

  void selectGrade(LowStockStockCard card) {
    _selectedMetalType = card.metalType;
    _selectedGradeLabel = card.gradeLabel;
    notifyListeners();
  }

  void clearGradeSelection() {
    _selectedGradeLabel = null;
    notifyListeners();
  }

  void clearMetalSelection() {
    _selectedMetalType = null;
    _selectedGradeLabel = null;
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await _repository.loadDashboard();
      _normalizeSelection();
    } catch (error) {
      _dashboard = LowStockAlertDashboard.empty();
      _selectedMetalType = null;
      _selectedGradeLabel = null;
      _errorMessage = 'Low stock alerts could not be loaded. $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _normalizeSelection() {
    final selectedMetal = _selectedMetalType;
    if (selectedMetal != null &&
        !_dashboard.metalCards
            .any((card) => _same(card.metalType, selectedMetal))) {
      _selectedMetalType = null;
      _selectedGradeLabel = null;
      return;
    }
    final selectedGrade = _selectedGradeLabel;
    if (selectedMetal != null &&
        selectedGrade != null &&
        !_dashboard.gradeCards.any(
          (card) =>
              _same(card.metalType, selectedMetal) &&
              _same(card.gradeLabel, selectedGrade),
        )) {
      _selectedGradeLabel = null;
    }
  }

  bool _same(String left, String right) {
    return left.trim().toLowerCase() == right.trim().toLowerCase();
  }
}
