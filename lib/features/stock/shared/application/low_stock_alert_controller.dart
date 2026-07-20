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
  List<LowStockStockCard> get alertItemTypeCards {
    final cards = _dashboard.itemTypeCards
        .where((card) => card.requiresAction)
        .toList(growable: false);
    cards.sort(_compareStockCards);
    return cards;
  }

  List<LowStockStockCard> get alertGradeCards {
    return _buildAggregateCards(
      level: LowStockCardLevel.grade,
      sourceCards: alertItemTypeCards,
    );
  }

  List<LowStockStockCard> get alertItemGroupCards {
    return _buildAggregateCards(
      level: LowStockCardLevel.itemGroup,
      sourceCards: alertItemTypeCards,
    );
  }

  List<LowStockStockCard> get alertMetalCards {
    return _buildAggregateCards(
      level: LowStockCardLevel.metal,
      sourceCards: alertItemTypeCards,
    );
  }

  List<LowStockStockCard> get inventoryRuleMetalCards {
    return _dashboard.metalCards;
  }

  List<LowStockStockCard> inventoryRuleGroupCardsForMetal(String metalType) {
    return groupCardsForMetal(metalType);
  }

  List<LowStockStockCard> inventoryRuleItemCardsForGroup(
    LowStockStockCard groupCard,
  ) {
    return detailCardsForGroup(groupCard);
  }

  List<LowStockStockCard> get autoRuleGroupCards {
    final cards = [
      ..._dashboard.gradeCards.where(
        (card) =>
            !_same(card.metalType, 'Silver') &&
            card.ruleMode == LowStockRuleMode.auto,
      ),
      ..._dashboard.itemGroupCards.where(
        (card) =>
            _same(card.metalType, 'Silver') &&
            card.ruleMode == LowStockRuleMode.auto,
      ),
    ];
    cards.sort((a, b) {
      final metal = a.metalType.compareTo(b.metalType);
      if (metal != 0) return metal;
      return a.title.compareTo(b.title);
    });
    return cards;
  }

  List<LowStockStockCard> get autoRuleMetalCards {
    final autoMetalKeys = {
      for (final card in autoRuleGroupCards)
        card.metalType.trim().toLowerCase(),
    };
    final cards = _dashboard.metalCards
        .where(
          (card) => autoMetalKeys.contains(card.metalType.trim().toLowerCase()),
        )
        .toList(growable: false);
    return cards;
  }

  List<LowStockStockCard> autoRuleGroupCardsForMetal(String metalType) {
    return autoRuleGroupCards
        .where((card) => _same(card.metalType, metalType))
        .toList(growable: false);
  }

  List<LowStockStockCard> autoRuleItemCardsForGroup(
    LowStockStockCard groupCard,
  ) {
    if (groupCard.level == LowStockCardLevel.itemGroup) {
      return const [];
    }
    return detailCardsForGroup(groupCard)
        .where((card) => card.ruleMode == LowStockRuleMode.auto)
        .toList(growable: false);
  }

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

  List<LowStockStockCard> alertGroupCardsForMetal(String metalType) {
    final source =
        _same(metalType, 'Silver') ? alertItemGroupCards : alertGradeCards;
    return source
        .where((card) => _same(card.metalType, metalType))
        .toList(growable: false);
  }

  List<LowStockStockCard> detailCardsForGroup(LowStockStockCard groupCard) {
    if (groupCard.level == LowStockCardLevel.itemGroup) {
      return const [];
    }
    return _dashboard.itemTypeCards
        .where(
          (card) =>
              _same(card.metalType, groupCard.metalType) &&
              _same(card.gradeLabel, groupCard.gradeLabel),
        )
        .toList(growable: false);
  }

  List<LowStockStockCard> alertDetailCardsForGroup(
    LowStockStockCard groupCard,
  ) {
    if (groupCard.level == LowStockCardLevel.itemGroup) {
      return const [];
    }
    return alertItemTypeCards
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

  Future<void> saveManualRule(LowStockManualRuleDraft draft) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.saveManualRule(draft);
      _dashboard = await _repository.loadDashboard();
      _normalizeSelection();
    } catch (error) {
      _errorMessage = 'Manual low stock rule could not be saved. $error';
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

  List<LowStockStockCard> _buildAggregateCards({
    required String level,
    required List<LowStockStockCard> sourceCards,
  }) {
    final grouped = <String, List<LowStockStockCard>>{};
    for (final card in sourceCards) {
      final key = level == LowStockCardLevel.metal
          ? card.metalType
          : level == LowStockCardLevel.itemGroup
              ? '${card.metalType}|${card.itemType}'
              : '${card.metalType}|${card.gradeLabel}';
      grouped.putIfAbsent(key, () => <LowStockStockCard>[]).add(card);
    }

    final cards = grouped.entries.map((entry) {
      final children = entry.value;
      final first = children.first;
      return LowStockStockCard(
        level: level,
        metalType: first.metalType,
        gradeLabel:
            level == LowStockCardLevel.grade ? first.gradeLabel : 'All Grades',
        itemType: level == LowStockCardLevel.itemGroup
            ? first.itemType
            : LowStockConstants.anyItemKey,
        unitLabel: _aggregateUnitLabel(children),
        totalUnits: children.fold(0, (sum, card) => sum + card.totalUnits),
        availableUnits:
            children.fold(0, (sum, card) => sum + card.availableUnits),
        soldUnits: children.fold(0, (sum, card) => sum + card.soldUnits),
        totalSets: children.fold(0, (sum, card) => sum + card.totalSets),
        availableSets:
            children.fold(0, (sum, card) => sum + card.availableSets),
        soldSets: children.fold(0, (sum, card) => sum + card.soldSets),
        totalNetWeight:
            children.fold(0, (sum, card) => sum + card.totalNetWeight),
        availableNetWeight:
            children.fold(0, (sum, card) => sum + card.availableNetWeight),
        soldNetWeight:
            children.fold(0, (sum, card) => sum + card.soldNetWeight),
        ruleMode:
            children.any((card) => card.ruleMode == LowStockRuleMode.manual)
                ? LowStockRuleMode.manual
                : LowStockRuleMode.auto,
        criticalUnits:
            children.fold(0, (sum, card) => sum + card.criticalUnits),
        thresholdUnits:
            children.fold(0, (sum, card) => sum + card.thresholdUnits),
        targetUnits: children.fold(0, (sum, card) => sum + card.targetUnits),
        criticalNetWeight:
            children.fold(0, (sum, card) => sum + card.criticalNetWeight),
        thresholdNetWeight:
            children.fold(0, (sum, card) => sum + card.thresholdNetWeight),
        targetNetWeight:
            children.fold(0, (sum, card) => sum + card.targetNetWeight),
        targetSets: children.fold(0, (sum, card) => sum + card.targetSets),
        targetPackets:
            children.fold(0, (sum, card) => sum + card.targetPackets),
        reorderTargetUnits:
            children.fold(0, (sum, card) => sum + card.reorderTargetUnits),
        suggestedReorderUnits: children.fold(
          0,
          (sum, card) => sum + card.suggestedReorderUnits,
        ),
        suggestedReorderNetWeight: children.fold(
          0,
          (sum, card) => sum + card.suggestedReorderNetWeight,
        ),
        riskLevel: _highestRisk(children.map((card) => card.riskLevel)),
      );
    }).toList(growable: false);

    cards.sort(_compareStockCards);
    return cards;
  }

  String _highestRisk(Iterable<String> riskLevels) {
    var selected = LowStockRiskLevel.stable;
    var selectedRank = _riskRank(selected);
    for (final riskLevel in riskLevels) {
      final rank = _riskRank(riskLevel);
      if (rank > selectedRank) {
        selected = riskLevel;
        selectedRank = rank;
      }
    }
    return selected;
  }

  int _compareStockCards(LowStockStockCard left, LowStockStockCard right) {
    final risk =
        _riskRank(right.riskLevel).compareTo(_riskRank(left.riskLevel));
    if (risk != 0) return risk;
    final available = left.availableUnits.compareTo(right.availableUnits);
    if (available != 0) return available;
    final metal = left.metalType.compareTo(right.metalType);
    if (metal != 0) return metal;
    return left.title.compareTo(right.title);
  }

  int _riskRank(String riskLevel) {
    switch (riskLevel) {
      case LowStockRiskLevel.stockout:
        return 4;
      case LowStockRiskLevel.critical:
        return 3;
      case LowStockRiskLevel.low:
        return 2;
      default:
        return 1;
    }
  }

  String _aggregateUnitLabel(List<LowStockStockCard> children) {
    final labels = children
        .map((card) => card.unitLabel.trim().toLowerCase())
        .where((label) => label.isNotEmpty)
        .toSet();
    if (labels.length == 1) return labels.single;
    if (children.any((card) => card.totalSets > 0 || card.targetPackets > 0)) {
      return 'packet';
    }
    return 'item';
  }
}
