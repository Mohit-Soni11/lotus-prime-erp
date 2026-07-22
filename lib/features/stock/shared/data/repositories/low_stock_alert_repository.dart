import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';

part 'low_stock_alert_queries.dart';
part 'low_stock_alert_internal_models.dart';

class LowStockAlertRepository {
  final AppDatabase _db;

  LowStockAlertRepository(this._db);

  Future<void> ensureSchema() async {
    await _db.ensureLowStockAlertSchema();
  }

  Future<LowStockAlertDashboard> loadDashboard() async {
    await ensureSchema();
    final rules = await _loadRules();
    final groups = await _loadAvailableGroups();
    final stockGroups = await _loadStockGroups();
    final itemTypeCards =
        _buildItemTypeCards(rules: rules, groups: stockGroups);
    final gradeCards = _buildAggregateCards(
      level: LowStockCardLevel.grade,
      sourceCards: itemTypeCards,
    );
    final itemGroupCards = _buildAggregateCards(
      level: LowStockCardLevel.itemGroup,
      sourceCards: itemTypeCards,
    );
    final metalCards = _buildAggregateCards(
      level: LowStockCardLevel.metal,
      sourceCards: gradeCards,
    );
    final cards = _buildRiskCards(rules: rules, groups: groups);

    final riskyCards = itemTypeCards.where((card) => card.requiresAction);
    final criticalCards = itemTypeCards
        .where((card) => card.riskLevel == LowStockRiskLevel.critical);
    final stockoutCards = itemTypeCards
        .where((card) => card.riskLevel == LowStockRiskLevel.stockout);

    final summary = LowStockAlertSummary(
      watchedGroups: itemTypeCards.length,
      lowGroups: riskyCards.length,
      criticalGroups: criticalCards.length,
      stockoutGroups: stockoutCards.length,
      availableUnits:
          metalCards.fold(0, (sum, card) => sum + card.availableUnits),
      availableNetWeight: metalCards.fold(
        0,
        (sum, card) => sum + card.availableNetWeight,
      ),
      lastCheckedAt: DateTime.now(),
    );

    return LowStockAlertDashboard(
      summary: summary,
      riskCards: cards,
      metalCards: metalCards,
      gradeCards: gradeCards,
      itemGroupCards: itemGroupCards,
      itemTypeCards: itemTypeCards,
      rules: rules,
    );
  }

  Future<void> saveManualRule(LowStockManualRuleDraft draft) async {
    await ensureSchema();
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await _db.customSelect(
      '''
      SELECT id
      FROM low_stock_alert_rules
      WHERE LOWER(metal_type) = LOWER(?)
        AND LOWER(COALESCE(grade_label, '')) = LOWER(?)
        AND LOWER(COALESCE(item_type, '')) = LOWER(?)
      LIMIT 1
      ''',
      variables: [
        drift.Variable.withString(draft.metalType.trim()),
        drift.Variable.withString(draft.gradeLabel.trim()),
        drift.Variable.withString(_normalizedItem(draft.itemType)),
      ],
    ).get();

    final values = [
      LowStockRuleMode.manual,
      draft.gradeLabel.trim().isEmpty ? 'item' : 'grade_item',
      draft.metalType.trim(),
      draft.gradeLabel.trim(),
      _normalizedItem(draft.itemType),
      draft.criticalUnits,
      draft.thresholdUnits,
      draft.targetUnits,
      draft.criticalNetWeight,
      draft.thresholdNetWeight,
      draft.targetNetWeight,
      draft.targetSets,
      draft.targetPackets,
      draft.targetUnits,
      draft.preferredSupplierName.trim(),
      1,
      now,
    ];

    if (existing.isEmpty) {
      await _db.customStatement(
        '''
        INSERT INTO low_stock_alert_rules (
          rule_mode,
          scope_level,
          metal_type,
          grade_label,
          item_type,
          critical_units,
          threshold_units,
          target_units,
          critical_net_weight,
          threshold_net_weight,
          target_net_weight,
          target_sets,
          target_packets,
          reorder_target_units,
          preferred_supplier_name,
          is_active,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [...values, now],
      );
      return;
    }

    await _db.customStatement(
      '''
      UPDATE low_stock_alert_rules
      SET rule_mode = ?,
          scope_level = ?,
          metal_type = ?,
          grade_label = ?,
          item_type = ?,
          critical_units = ?,
          threshold_units = ?,
          target_units = ?,
          critical_net_weight = ?,
          threshold_net_weight = ?,
          target_net_weight = ?,
          target_sets = ?,
          target_packets = ?,
          reorder_target_units = ?,
          preferred_supplier_name = ?,
          is_active = ?,
          updated_at = ?
      WHERE id = ?
      ''',
      [...values, _readInt(existing.first, 'id')],
    );
  }

  Future<List<LowStockAlertRule>> _loadRules() async {
    final rows = await _db.customSelect(
      '''
      SELECT *
      FROM low_stock_alert_rules
      WHERE is_active = 1
      ORDER BY
        CASE LOWER(metal_type)
          WHEN 'gold' THEN 1
          WHEN 'silver' THEN 2
          WHEN 'platinum' THEN 3
          WHEN 'diamond' THEN 4
          ELSE 5
        END,
        item_type
      ''',
    ).get();
    return rows.map(_mapRule).toList(growable: false);
  }

  Future<List<_StockLedgerGroup>> _loadStockGroups() async {
    final rows = await _db.customSelect('''
      SELECT
        $_lowStockMetalExpression AS metal_type,
        $_lowStockGradeExpression AS grade_label,
        MIN(COALESCE(NULLIF(TRIM(u.item_type), ''), 'General')) AS item_type,
        GROUP_CONCAT(DISTINCT LOWER(COALESCE(NULLIF(TRIM(s.quantity_mode), ''), 'pieces'))) AS quantity_modes,
        COALESCE(SUM($_lowStockTotalQuantityExpression), 0) AS total_units,
        COALESCE(SUM($_lowStockAvailableQuantityExpression), 0) AS available_units,
        COALESCE(SUM($_lowStockSoldQuantityExpression), 0) AS sold_units,
        COALESCE(SUM(CASE WHEN lower(COALESCE(s.quantity_mode, '')) IN ('packet', 'pack', 'set', 'pair') THEN $_lowStockTotalQuantityExpression ELSE 0 END), 0) AS total_sets,
        COALESCE(SUM(CASE WHEN lower(COALESCE(s.quantity_mode, '')) IN ('packet', 'pack', 'set', 'pair') THEN $_lowStockAvailableQuantityExpression ELSE 0 END), 0) AS available_sets,
        COALESCE(SUM(CASE WHEN lower(COALESCE(s.quantity_mode, '')) IN ('packet', 'pack', 'set', 'pair') THEN $_lowStockSoldQuantityExpression ELSE 0 END), 0) AS sold_sets,
        COALESCE(SUM(u.net_weight), 0.0) AS total_net_weight,
        COALESCE(SUM(CASE WHEN LOWER(u.status) = 'available' THEN u.net_weight ELSE 0 END), 0.0) AS available_net_weight,
        COALESCE(SUM(CASE WHEN LOWER(u.status) = 'sold' THEN u.net_weight ELSE 0 END), 0.0) AS sold_net_weight
      FROM stock_item_units u
      INNER JOIN stock_items s ON s.id = u.stock_item_id
      LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
      WHERE COALESCE(NULLIF(TRIM(u.metal_type), ''), '') <> ''
      GROUP BY
        $_lowStockMetalExpression,
        $_lowStockGradeExpression,
        LOWER(COALESCE(NULLIF(TRIM(u.item_type), ''), 'General'))
      HAVING total_units > 0
      ORDER BY
        CASE LOWER($_lowStockMetalExpression)
          WHEN 'gold' THEN 1
          WHEN 'silver' THEN 2
          WHEN 'platinum' THEN 3
          WHEN 'diamond' THEN 4
          ELSE 5
        END,
        grade_label,
        item_type
    ''').get();
    return rows.map(_mapStockGroup).toList(growable: false);
  }

  Future<List<_AvailableStockGroup>> _loadAvailableGroups() async {
    final rows = await _db.customSelect('''
      SELECT
        MIN(COALESCE(NULLIF(TRIM(u.metal_type), ''), 'Other')) AS metal_type,
        MIN(COALESCE(NULLIF(TRIM(u.item_type), ''), 'any')) AS item_type,
        COALESCE(SUM($_lowStockAvailableQuantityExpression), 0) AS units,
        COALESCE(SUM(u.net_weight), 0.0) AS net_weight
      FROM stock_item_units u
      LEFT JOIN stock_items s ON s.id = u.stock_item_id
      LEFT JOIN purchase_voucher_items pvi ON pvi.id = u.purchase_voucher_item_id
      WHERE LOWER(u.status) = 'available'
      GROUP BY
        LOWER(COALESCE(NULLIF(TRIM(u.metal_type), ''), 'Other')),
        LOWER(COALESCE(NULLIF(TRIM(u.item_type), ''), 'any'))
      ORDER BY units ASC, net_weight ASC
    ''').get();
    return rows.map(_mapGroup).toList(growable: false);
  }

  List<LowStockStockCard> _buildItemTypeCards({
    required List<LowStockAlertRule> rules,
    required List<_StockLedgerGroup> groups,
  }) {
    final cards = <LowStockStockCard>[];
    for (final group in groups) {
      final rule = _ruleForGroup(
        rules: rules,
        group: group,
      );
      final riskLevel = _stockRiskLevel(
        availableUnits: group.availableUnits,
        availableNetWeight: group.availableNetWeight,
        criticalUnits: rule.criticalUnits,
        thresholdUnits: rule.thresholdUnits,
        criticalNetWeight: rule.criticalNetWeight,
        thresholdNetWeight: rule.thresholdNetWeight,
      );
      final suggestedUnits =
          _suggestedUnits(group.availableUnits, rule.targetUnits);
      cards.add(
        LowStockStockCard(
          level: LowStockCardLevel.itemType,
          metalType: group.metalType,
          gradeLabel: group.gradeLabel,
          itemType: group.itemType,
          unitLabel: group.unitLabel,
          totalUnits: group.totalUnits,
          availableUnits: group.availableUnits,
          soldUnits: group.soldUnits,
          totalSets: group.totalSets,
          availableSets: group.availableSets,
          soldSets: group.soldSets,
          totalNetWeight: group.totalNetWeight,
          availableNetWeight: group.availableNetWeight,
          soldNetWeight: group.soldNetWeight,
          ruleMode: rule.ruleMode,
          criticalUnits: rule.criticalUnits,
          thresholdUnits: rule.thresholdUnits,
          targetUnits: rule.targetUnits,
          criticalNetWeight: rule.criticalNetWeight,
          thresholdNetWeight: rule.thresholdNetWeight,
          targetNetWeight: rule.targetNetWeight,
          targetSets: rule.targetSets,
          targetPackets: rule.targetPackets,
          reorderTargetUnits: rule.reorderTargetUnits,
          suggestedReorderUnits: suggestedUnits,
          suggestedReorderNetWeight: _suggestedNetWeight(
            availableUnits: group.availableUnits,
            availableNetWeight: group.availableNetWeight,
            targetNetWeight: rule.targetNetWeight,
            suggestedUnits: suggestedUnits,
          ),
          riskLevel: riskLevel,
        ),
      );
    }
    cards.sort(_compareStockCards);
    return cards;
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
        gradeLabel: level == LowStockCardLevel.grade
            ? first.gradeLabel
            : level == LowStockCardLevel.itemGroup
                ? 'All Grades'
                : 'All Grades',
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

  List<LowStockRiskCard> _buildRiskCards({
    required List<LowStockAlertRule> rules,
    required List<_AvailableStockGroup> groups,
  }) {
    final groupByScope = {
      for (final group in groups)
        _scopeKey(group.metalType, group.itemType): group,
    };
    final cards = <LowStockRiskCard>[];

    for (final rule in rules) {
      final exactGroup = groupByScope[_scopeKey(rule.metalType, rule.itemType)];
      final metalGroups = groups.where(
        (group) => _same(group.metalType, rule.metalType),
      );
      final isAnyRule =
          rule.itemType.trim().toLowerCase() == LowStockConstants.anyItemKey;
      final group = exactGroup ??
          (isAnyRule ? _mergeGroups(rule.metalType, metalGroups) : null) ??
          _AvailableStockGroup.empty(rule.metalType, rule.itemType);

      cards.add(
        LowStockRiskCard(
          metalType: rule.metalType,
          itemType: rule.itemType,
          availableUnits: group.units,
          availableNetWeight: group.netWeight,
          thresholdUnits: rule.thresholdUnits,
          thresholdNetWeight: rule.thresholdNetWeight,
          reorderTargetUnits: rule.reorderTargetUnits,
          preferredSupplierName: rule.preferredSupplierName,
          riskLevel: _riskLevel(group, rule),
        ),
      );
    }

    cards.sort((a, b) {
      final risk = _riskRank(b.riskLevel).compareTo(_riskRank(a.riskLevel));
      if (risk != 0) return risk;
      return a.availableUnits.compareTo(b.availableUnits);
    });
    return cards;
  }

  String _riskLevel(_AvailableStockGroup group, LowStockAlertRule rule) {
    if (group.units <= 0) return LowStockRiskLevel.stockout;
    final unitCritical = group.units <= (rule.thresholdUnits / 2).ceil();
    final weightCritical = rule.thresholdNetWeight > 0 &&
        group.netWeight <= rule.thresholdNetWeight * 0.5;
    if (unitCritical || weightCritical) return LowStockRiskLevel.critical;
    final unitLow = group.units <= rule.thresholdUnits;
    final weightLow = rule.thresholdNetWeight > 0 &&
        group.netWeight <= rule.thresholdNetWeight;
    if (unitLow || weightLow) return LowStockRiskLevel.low;
    return LowStockRiskLevel.stable;
  }

  _EffectiveLowStockRule _ruleForGroup({
    required List<LowStockAlertRule> rules,
    required _StockLedgerGroup group,
  }) {
    LowStockAlertRule? best;
    var bestRank = -1;
    for (final rule in rules) {
      if (rule.ruleMode != LowStockRuleMode.manual) continue;
      if (!_same(rule.metalType, group.metalType)) continue;
      final ruleGrade = rule.gradeLabel.trim();
      final ruleItem = rule.itemType.trim();
      final gradeMatches =
          ruleGrade.isEmpty || _same(ruleGrade, group.gradeLabel);
      final itemMatches = ruleItem.isEmpty ||
          ruleItem.toLowerCase() == LowStockConstants.anyItemKey ||
          _same(ruleItem, group.itemType);
      if (!gradeMatches || !itemMatches) continue;

      final rank = (ruleGrade.isNotEmpty ? 2 : 0) +
          (ruleItem.isNotEmpty &&
                  ruleItem.toLowerCase() != LowStockConstants.anyItemKey
              ? 1
              : 0);
      if (rank > bestRank) {
        best = rule;
        bestRank = rank;
      }
    }
    if (best != null) return _EffectiveLowStockRule.fromRule(best);
    return _EffectiveLowStockRule.auto(group);
  }

  String _stockRiskLevel({
    required int availableUnits,
    required double availableNetWeight,
    required int criticalUnits,
    required int thresholdUnits,
    required double criticalNetWeight,
    required double thresholdNetWeight,
  }) {
    if (availableUnits <= 0) return LowStockRiskLevel.stockout;
    final unitCritical = criticalUnits > 0 && availableUnits <= criticalUnits;
    final weightCritical =
        criticalNetWeight > 0 && availableNetWeight <= criticalNetWeight;
    if (unitCritical || weightCritical) return LowStockRiskLevel.critical;
    final unitLow = thresholdUnits > 0 && availableUnits <= thresholdUnits;
    final weightLow =
        thresholdNetWeight > 0 && availableNetWeight <= thresholdNetWeight;
    if (unitLow || weightLow) return LowStockRiskLevel.low;
    return LowStockRiskLevel.stable;
  }

  int _suggestedUnits(int availableUnits, int reorderTargetUnits) {
    final units = reorderTargetUnits - availableUnits;
    return units > 0 ? units : 0;
  }

  double _suggestedNetWeight({
    required int availableUnits,
    required double availableNetWeight,
    required double targetNetWeight,
    required int suggestedUnits,
  }) {
    final targetGap = targetNetWeight - availableNetWeight;
    if (targetGap > 0) return targetGap;
    if (suggestedUnits <= 0 || availableUnits <= 0) return 0;
    return (availableNetWeight / availableUnits) * suggestedUnits;
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
    final metal =
        _metalRank(left.metalType).compareTo(_metalRank(right.metalType));
    if (metal != 0) return metal;
    final available = left.availableUnits.compareTo(right.availableUnits);
    if (available != 0) return available;
    return left.title.toLowerCase().compareTo(right.title.toLowerCase());
  }

  _AvailableStockGroup _mergeGroups(
    String metalType,
    Iterable<_AvailableStockGroup> groups,
  ) {
    return _AvailableStockGroup(
      metalType: metalType,
      itemType: LowStockConstants.anyItemKey,
      units: groups.fold(0, (sum, group) => sum + group.units),
      netWeight: groups.fold(0, (sum, group) => sum + group.netWeight),
    );
  }

  LowStockAlertRule _mapRule(drift.QueryRow row) {
    return LowStockAlertRule(
      id: _readInt(row, 'id'),
      ruleMode: _readString(row, 'rule_mode').isEmpty
          ? LowStockRuleMode.manual
          : _readString(row, 'rule_mode'),
      scopeLevel: _readString(row, 'scope_level').isEmpty
          ? 'item'
          : _readString(row, 'scope_level'),
      metalType: _readString(row, 'metal_type'),
      gradeLabel: _readString(row, 'grade_label'),
      itemType: _readString(row, 'item_type'),
      criticalUnits: _readInt(row, 'critical_units'),
      thresholdUnits: _readInt(row, 'threshold_units'),
      targetUnits: _readInt(row, 'target_units') > 0
          ? _readInt(row, 'target_units')
          : _readInt(row, 'reorder_target_units'),
      criticalNetWeight: _readDouble(row, 'critical_net_weight'),
      thresholdNetWeight: _readDouble(row, 'threshold_net_weight'),
      targetNetWeight: _readDouble(row, 'target_net_weight'),
      targetSets: _readInt(row, 'target_sets'),
      targetPackets: _readInt(row, 'target_packets'),
      reorderTargetUnits: _readInt(row, 'reorder_target_units'),
      preferredSupplierName: _readString(row, 'preferred_supplier_name'),
      isActive: _readInt(row, 'is_active') == 1,
    );
  }

  _AvailableStockGroup _mapGroup(drift.QueryRow row) {
    return _AvailableStockGroup(
      metalType: _readString(row, 'metal_type'),
      itemType: _readString(row, 'item_type'),
      units: _readInt(row, 'units'),
      netWeight: _readDouble(row, 'net_weight'),
    );
  }

  _StockLedgerGroup _mapStockGroup(drift.QueryRow row) {
    return _StockLedgerGroup(
      metalType: _readString(row, 'metal_type'),
      gradeLabel: _readString(row, 'grade_label'),
      itemType: _readString(row, 'item_type'),
      unitLabel: _unitLabelFor(
        itemType: _readString(row, 'item_type'),
        quantityModes: _readString(row, 'quantity_modes'),
        totalSets: _readInt(row, 'total_sets'),
      ),
      totalUnits: _readInt(row, 'total_units'),
      availableUnits: _readInt(row, 'available_units'),
      soldUnits: _readInt(row, 'sold_units'),
      totalSets: _readInt(row, 'total_sets'),
      availableSets: _readInt(row, 'available_sets'),
      soldSets: _readInt(row, 'sold_sets'),
      totalNetWeight: _readDouble(row, 'total_net_weight'),
      availableNetWeight: _readDouble(row, 'available_net_weight'),
      soldNetWeight: _readDouble(row, 'sold_net_weight'),
    );
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

  int _metalRank(String metalType) {
    switch (metalType.trim().toLowerCase()) {
      case 'gold':
        return 1;
      case 'silver':
        return 2;
      case 'platinum':
        return 3;
      case 'diamond':
        return 4;
      default:
        return 5;
    }
  }

  bool _same(String left, String right) {
    return left.trim().toLowerCase() == right.trim().toLowerCase();
  }

  String _scopeKey(String metal, String item) {
    return '${metal.trim().toLowerCase()}|${item.trim().toLowerCase()}';
  }

  String _normalizedItem(String value) {
    final item = value.trim();
    return item.isEmpty ? LowStockConstants.anyItemKey : item;
  }

  int _readInt(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is num ? value.toInt() : 0;
  }

  double _readDouble(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is num ? value.toDouble() : 0;
  }

  String _readString(drift.QueryRow row, String column) {
    final value = row.data[column];
    return value is String ? value.trim() : '';
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

  String _unitLabelFor({
    required String itemType,
    required String quantityModes,
    required int totalSets,
  }) {
    final item = itemType.trim().toLowerCase();
    final modes = quantityModes.trim().toLowerCase();
    if (item.contains('payal') ||
        item.contains('anklet') ||
        item.contains('bichhiya') ||
        item.contains('toe ring') ||
        item.contains('jhumka') ||
        item.contains('earring') ||
        item.contains('ear ring') ||
        item.contains('tops') ||
        item.contains('bali') ||
        item.contains('kundal') ||
        item.contains('stud')) {
      return 'pair';
    }
    if (item.contains('set') ||
        item.contains('necklace') ||
        item.contains('haar') ||
        item.contains('har') ||
        item.contains('chudi')) {
      return 'set';
    }
    if (modes.contains('packet') || modes.contains('pack') || totalSets > 0) {
      return 'packet';
    }
    if (modes.contains('bulk') || modes.contains('lot')) return 'bulk';
    return 'pcs';
  }
}
