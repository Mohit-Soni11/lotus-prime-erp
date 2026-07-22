part of '../inventory_screen.dart';

class _InventoryGradeSummary {
  final String gradeLabel;
  final int totalUnits;
  final int availableUnits;
  final int soldUnits;
  final int totalPieces;
  final int availablePieces;
  final int soldPieces;
  final int totalSets;
  final int availableSets;
  final int companyCount;
  final int purityGroupCount;
  final double grossWeight;
  final double netWeight;
  final double soldWeight;
  final double actualFine;
  final double valuationFine;
  final double stockValue;
  final List<_InventoryGradeAvailableInfo> availableInfo;

  const _InventoryGradeSummary({
    required this.gradeLabel,
    required this.totalUnits,
    required this.availableUnits,
    required this.soldUnits,
    required this.totalPieces,
    required this.availablePieces,
    required this.soldPieces,
    required this.totalSets,
    required this.availableSets,
    required this.companyCount,
    required this.purityGroupCount,
    required this.grossWeight,
    required this.netWeight,
    required this.soldWeight,
    required this.actualFine,
    required this.valuationFine,
    required this.stockValue,
    required this.availableInfo,
  });

  bool get isSoldOut => totalPieces > 0 && availablePieces <= 0;
}

class _InventoryGradeAvailableInfo {
  final String itemType;
  final String segment;
  final String itemName;
  final int pieces;
  final double grossWeight;
  final double netWeight;

  const _InventoryGradeAvailableInfo({
    required this.itemType,
    required this.segment,
    required this.itemName,
    required this.pieces,
    required this.grossWeight,
    required this.netWeight,
  });
}

enum _InventoryGroupKind { grade, company, item }

String _inventoryPrimaryGroupExpression(StockCategory metal) {
  if (metal == StockCategory.gold) {
    return '''
      CASE
        WHEN u.purity_percent > 0 THEN
          CASE CAST(ROUND(u.purity_percent * 24.0 / 100.0) AS INTEGER)
            WHEN 24 THEN '24KT (99.9%)'
            WHEN 22 THEN '22KT (91.6%)'
            WHEN 18 THEN '18KT (75%)'
            WHEN 14 THEN '14KT (58.5%)'
            WHEN 9 THEN '9KT (37.5%)'
            ELSE CAST(CAST(ROUND(u.purity_percent * 24.0 / 100.0) AS INTEGER) AS TEXT) || 'KT (' || printf('%.1f', u.purity_percent) || '%)'
          END
        ELSE COALESCE(NULLIF(TRIM(s.purity), ''), 'Custom Grade')
      END
    ''';
  }

  if (metal == StockCategory.silver) {
    return '''
      CASE
        WHEN NULLIF(TRIM(COALESCE(u.item_type, s.sub_category, '')), '') IS NOT NULL THEN
          'item|GROUP|' || lower(TRIM(COALESCE(u.item_type, s.sub_category, '')))
        WHEN NULLIF(TRIM(COALESCE(u.item_name, s.item_name, '')), '') IS NOT NULL THEN
          'item|GROUP|' || lower(TRIM(COALESCE(u.item_name, s.item_name, '')))
        ELSE 'item|GROUP|Silver Item'
      END
    ''';
  }

  return '''
    COALESCE(
      NULLIF(TRIM(s.purity), ''),
      CASE
        WHEN u.purity_percent > 0 THEN printf('%.2f%%', u.purity_percent)
        ELSE 'Custom Grade'
      END
    )
  ''';
}

String _inventoryFallbackGroupLabel(StockCategory metal) {
  if (metal == StockCategory.gold) return 'Custom Gold Grade';
  if (metal == StockCategory.silver) return 'Silver Item';
  return 'Custom Grade';
}

String _inventoryGradeTitle(StockCategory metal, String gradeLabel) {
  final ui = stockMetalUiFor(metal);
  final parts = _inventoryGroupParts(gradeLabel);
  final label = parts.label.trim();
  if (label.isEmpty || label.toLowerCase() == 'custom grade') {
    return 'Custom ${ui.title} Stock';
  }
  if (metal == StockCategory.gold) {
    return '${_inventoryGoldGradeText(parts.label)} Gold Stock';
  }
  if (metal == StockCategory.silver) {
    return '${_titleCase(label)} Silver Stock';
  }
  return '$label ${ui.title} Stock';
}

String _inventoryGradeSubtitle(
  StockCategory metal,
  String gradeLabel,
  int availableUnits,
  int totalUnits,
  int companyCount,
  int purityGroupCount,
) {
  final ui = stockMetalUiFor(metal);
  final parts = _inventoryGroupParts(gradeLabel);
  if (metal == StockCategory.gold) {
    final gradeText = _inventoryGoldGradeText(parts.label);
    return '$gradeText gold - $availableUnits available pcs';
  }
  if (metal == StockCategory.silver) {
    final companyText =
        companyCount <= 1 ? '$companyCount company' : '$companyCount companies';
    final gradeText = purityGroupCount <= 1
        ? '$purityGroupCount grade'
        : '$purityGroupCount grades';
    return '$availableUnits available pcs - $companyText - $gradeText';
  }
  final purity = _inventoryGradePurityPercent(parts.label);
  final purityText = purity == null
      ? parts.label
      : '${_formatInventoryPercent(purity)}% ${ui.title.toLowerCase()} purity';
  return '$purityText - $availableUnits available items';
}

({String label, _InventoryGroupKind kind}) _inventoryGroupParts(String value) {
  final parts = value.split('|GROUP|');
  if (parts.length < 2) {
    final label = value.trim();
    return (label: label, kind: _InventoryGroupKind.grade);
  }
  final type = parts.first.trim().toLowerCase();
  return (
    label: parts.sublist(1).join('|GROUP|').trim(),
    kind: type == 'company'
        ? _InventoryGroupKind.company
        : type == 'item'
            ? _InventoryGroupKind.item
            : _InventoryGroupKind.grade,
  );
}

String _inventoryGoldGradeText(String gradeLabel) {
  final raw = gradeLabel.trim();
  if (raw.isEmpty) return 'Custom Gold Grade';
  if (RegExp(r'\b\d+(?:\.\d+)?\s*KT\b', caseSensitive: false).hasMatch(raw)) {
    return raw.replaceAll(RegExp(r'\s+'), ' ').replaceAllMapped(
          RegExp(r'\bkt\b', caseSensitive: false),
          (_) => 'KT',
        );
  }
  final purity = _inventoryGradePurityPercent(raw);
  if (purity == null) return _titleCase(raw);
  final karat = (purity * 24 / 100).round();
  return '${karat}KT (${_formatInventoryPercent(_standardGoldPurity(karat, purity))}%)';
}

double _standardGoldPurity(int karat, double fallback) {
  switch (karat) {
    case 24:
      return 99.9;
    case 22:
      return 91.6;
    case 18:
      return 75;
    case 14:
      return 58.5;
    case 9:
      return 37.5;
    default:
      return fallback;
  }
}

double? _inventoryGradePurityPercent(String gradeLabel) {
  final raw = gradeLabel.trim();
  final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
  if (match == null) return null;
  final value = double.tryParse(match.group(1) ?? '');
  if (value == null || value <= 0) return null;
  if (value > 100 && value <= 1000) return value / 10;
  return value;
}

String _formatInventoryPercent(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.001) return rounded.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

String _titleCase(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
    final lower = part.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }).join(' ');
}
