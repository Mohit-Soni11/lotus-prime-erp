import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/stock/shared/domain/models/low_stock_alert/low_stock_alert_models.dart';

const String _lowStockMetalExpression = '''
CASE
  WHEN LOWER(u.metal_type) = 'gold' THEN 'Gold'
  WHEN LOWER(u.metal_type) = 'silver' THEN 'Silver'
  WHEN LOWER(u.metal_type) = 'diamond' THEN 'Diamond'
  WHEN LOWER(u.metal_type) = 'platinum' THEN 'Platinum'
  ELSE COALESCE(NULLIF(TRIM(u.metal_type), ''), 'Other')
END
''';

const String _lowStockGradeExpression = '''
CASE
  WHEN LOWER(u.metal_type) = 'gold' THEN
    CASE
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 91.6) <= 0.6 THEN '22KT (91.6%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 92.0) <= 0.6 THEN '22KT (91.6%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 75.0) <= 0.6 THEN '18KT (75%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 99.9) <= 0.6 THEN '24KT (99.9%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 58.5) <= 0.6 THEN '14KT (58.5%)'
      WHEN ABS(COALESCE(u.purity_percent, 0.0) - 37.5) <= 0.6 THEN '9KT (37.5%)'
      ELSE printf('%.2f%% Gold', COALESCE(u.purity_percent, 0.0))
    END
  WHEN LOWER(u.metal_type) = 'silver' THEN printf('%.0f%% Silver', COALESCE(u.purity_percent, 0.0))
  ELSE printf('%.2f%% Purity', COALESCE(u.purity_percent, 0.0))
END
''';

class LowStockAlertRepository {
  final AppDatabase _db;

  LowStockAlertRepository(this._db);

  Future<void> ensureSchema() async {
    await _ensureStockUnitColumns();
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS "low_stock_alert_rules" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "metal_type" TEXT NOT NULL,
        "item_type" TEXT NOT NULL DEFAULT 'any',
        "threshold_units" INTEGER NOT NULL DEFAULT 1,
        "threshold_net_weight" REAL NOT NULL DEFAULT 0.0,
        "reorder_target_units" INTEGER NOT NULL DEFAULT 1,
        "preferred_supplier_name" TEXT,
        "is_active" INTEGER NOT NULL DEFAULT 1,
        "created_at" INTEGER NOT NULL,
        "updated_at" INTEGER
      )
    ''');
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS "idx_low_stock_rules_scope" ON "low_stock_alert_rules" ("metal_type", "item_type")',
    );
    await _seedDefaultRulesIfNeeded();
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
        COALESCE(NULLIF(TRIM(u.item_type), ''), 'General') AS item_type,
        COUNT(*) AS total_units,
        SUM(CASE WHEN LOWER(u.status) = 'available' THEN 1 ELSE 0 END) AS available_units,
        SUM(CASE WHEN LOWER(u.status) = 'sold' THEN 1 ELSE 0 END) AS sold_units,
        COALESCE(SUM(u.net_weight), 0.0) AS total_net_weight,
        COALESCE(SUM(CASE WHEN LOWER(u.status) = 'available' THEN u.net_weight ELSE 0 END), 0.0) AS available_net_weight,
        COALESCE(SUM(CASE WHEN LOWER(u.status) = 'sold' THEN u.net_weight ELSE 0 END), 0.0) AS sold_net_weight
      FROM stock_item_units u
      WHERE COALESCE(NULLIF(TRIM(u.metal_type), ''), '') <> ''
      GROUP BY 1, 2, 3
      HAVING total_units > 0
      ORDER BY
        CASE LOWER(metal_type)
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
        COALESCE(NULLIF(TRIM(metal_type), ''), 'Other') AS metal_type,
        COALESCE(NULLIF(TRIM(item_type), ''), 'any') AS item_type,
        COUNT(*) AS units,
        COALESCE(SUM(net_weight), 0.0) AS net_weight
      FROM stock_item_units
      WHERE LOWER(status) = 'available'
      GROUP BY 1, 2
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
        metalType: group.metalType,
        itemType: group.itemType,
      );
      final riskLevel = _stockRiskLevel(
        availableUnits: group.availableUnits,
        availableNetWeight: group.availableNetWeight,
        thresholdUnits: rule.thresholdUnits,
        thresholdNetWeight: rule.thresholdNetWeight,
      );
      final suggestedUnits =
          _suggestedUnits(group.availableUnits, rule.reorderTargetUnits);
      cards.add(
        LowStockStockCard(
          level: LowStockCardLevel.itemType,
          metalType: group.metalType,
          gradeLabel: group.gradeLabel,
          itemType: group.itemType,
          totalUnits: group.totalUnits,
          availableUnits: group.availableUnits,
          soldUnits: group.soldUnits,
          totalNetWeight: group.totalNetWeight,
          availableNetWeight: group.availableNetWeight,
          soldNetWeight: group.soldNetWeight,
          thresholdUnits: rule.thresholdUnits,
          thresholdNetWeight: rule.thresholdNetWeight,
          reorderTargetUnits: rule.reorderTargetUnits,
          suggestedReorderUnits: suggestedUnits,
          suggestedReorderNetWeight: _suggestedNetWeight(
            availableUnits: group.availableUnits,
            availableNetWeight: group.availableNetWeight,
            thresholdNetWeight: rule.thresholdNetWeight,
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
        totalUnits: children.fold(0, (sum, card) => sum + card.totalUnits),
        availableUnits:
            children.fold(0, (sum, card) => sum + card.availableUnits),
        soldUnits: children.fold(0, (sum, card) => sum + card.soldUnits),
        totalNetWeight:
            children.fold(0, (sum, card) => sum + card.totalNetWeight),
        availableNetWeight:
            children.fold(0, (sum, card) => sum + card.availableNetWeight),
        soldNetWeight:
            children.fold(0, (sum, card) => sum + card.soldNetWeight),
        thresholdUnits:
            children.fold(0, (sum, card) => sum + card.thresholdUnits),
        thresholdNetWeight:
            children.fold(0, (sum, card) => sum + card.thresholdNetWeight),
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
    required String metalType,
    required String itemType,
  }) {
    LowStockAlertRule? fallback;
    for (final rule in rules) {
      if (!_same(rule.metalType, metalType)) continue;
      final ruleItem = rule.itemType.trim().toLowerCase();
      if (ruleItem == itemType.trim().toLowerCase()) {
        return _EffectiveLowStockRule.fromRule(rule);
      }
      if (ruleItem == LowStockConstants.anyItemKey) {
        fallback ??= rule;
      }
    }
    if (fallback != null) return _EffectiveLowStockRule.fromRule(fallback);
    return const _EffectiveLowStockRule(
      thresholdUnits: 1,
      thresholdNetWeight: 0,
      reorderTargetUnits: 1,
    );
  }

  String _stockRiskLevel({
    required int availableUnits,
    required double availableNetWeight,
    required int thresholdUnits,
    required double thresholdNetWeight,
  }) {
    if (availableUnits <= 0) return LowStockRiskLevel.stockout;
    final unitCritical = availableUnits <= (thresholdUnits / 2).ceil();
    final weightCritical = thresholdNetWeight > 0 &&
        availableNetWeight <= thresholdNetWeight * 0.5;
    if (unitCritical || weightCritical) return LowStockRiskLevel.critical;
    final unitLow = availableUnits <= thresholdUnits;
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
    required double thresholdNetWeight,
    required int suggestedUnits,
  }) {
    final thresholdGap = thresholdNetWeight - availableNetWeight;
    if (thresholdGap > 0) return thresholdGap;
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

  Future<void> _seedDefaultRulesIfNeeded() async {
    final countRow = await _db
        .customSelect(
            'SELECT COUNT(*) AS rule_count FROM low_stock_alert_rules')
        .getSingle();
    if (_readInt(countRow, 'rule_count') > 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    const defaults = [
      _DefaultLowStockRule('Gold', 'any', 3, 20, 10),
      _DefaultLowStockRule('Silver', 'any', 12, 500, 40),
      _DefaultLowStockRule('Platinum', 'any', 2, 10, 6),
      _DefaultLowStockRule('Diamond', 'any', 2, 0, 8),
    ];

    for (final rule in defaults) {
      await _db.customStatement(
        '''
        INSERT INTO low_stock_alert_rules (
          metal_type,
          item_type,
          threshold_units,
          threshold_net_weight,
          reorder_target_units,
          preferred_supplier_name,
          is_active,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)
        ''',
        [
          rule.metalType,
          rule.itemType,
          rule.thresholdUnits,
          rule.thresholdNetWeight,
          rule.reorderTargetUnits,
          '',
          now,
          now,
        ],
      );
    }
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
      metalType: _readString(row, 'metal_type'),
      itemType: _readString(row, 'item_type'),
      thresholdUnits: _readInt(row, 'threshold_units'),
      thresholdNetWeight: _readDouble(row, 'threshold_net_weight'),
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
      totalUnits: _readInt(row, 'total_units'),
      availableUnits: _readInt(row, 'available_units'),
      soldUnits: _readInt(row, 'sold_units'),
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

  Future<void> _ensureStockUnitColumns() async {
    final rows =
        await _db.customSelect('PRAGMA table_info(stock_item_units)').get();
    final columns = rows
        .map((row) => row.data['name'])
        .whereType<String>()
        .map((name) => name.toLowerCase())
        .toSet();
    if (!columns.contains('item_type')) {
      await _db.customStatement(
          'ALTER TABLE stock_item_units ADD COLUMN item_type TEXT');
    }
  }
}

class _AvailableStockGroup {
  final String metalType;
  final String itemType;
  final int units;
  final double netWeight;

  const _AvailableStockGroup({
    required this.metalType,
    required this.itemType,
    required this.units,
    required this.netWeight,
  });

  factory _AvailableStockGroup.empty(String metalType, String itemType) {
    return _AvailableStockGroup(
      metalType: metalType,
      itemType: itemType,
      units: 0,
      netWeight: 0,
    );
  }
}

class _StockLedgerGroup {
  final String metalType;
  final String gradeLabel;
  final String itemType;
  final int totalUnits;
  final int availableUnits;
  final int soldUnits;
  final double totalNetWeight;
  final double availableNetWeight;
  final double soldNetWeight;

  const _StockLedgerGroup({
    required this.metalType,
    required this.gradeLabel,
    required this.itemType,
    required this.totalUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.totalNetWeight,
    required this.availableNetWeight,
    required this.soldNetWeight,
  });
}

class _EffectiveLowStockRule {
  final int thresholdUnits;
  final double thresholdNetWeight;
  final int reorderTargetUnits;

  const _EffectiveLowStockRule({
    required this.thresholdUnits,
    required this.thresholdNetWeight,
    required this.reorderTargetUnits,
  });

  factory _EffectiveLowStockRule.fromRule(LowStockAlertRule rule) {
    return _EffectiveLowStockRule(
      thresholdUnits: rule.thresholdUnits,
      thresholdNetWeight: rule.thresholdNetWeight,
      reorderTargetUnits: rule.reorderTargetUnits,
    );
  }
}

class _DefaultLowStockRule {
  final String metalType;
  final String itemType;
  final int thresholdUnits;
  final double thresholdNetWeight;
  final int reorderTargetUnits;

  const _DefaultLowStockRule(
    this.metalType,
    this.itemType,
    this.thresholdUnits,
    this.thresholdNetWeight,
    this.reorderTargetUnits,
  );
}
