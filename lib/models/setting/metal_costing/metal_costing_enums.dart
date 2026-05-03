// =============================================================================
// FILE        : lib/models/metal_costing/metal_costing_enums.dart
// MODULE      : Metal Costing Analysis
// LAYER       : Models / Enums
// =============================================================================

enum CostingMetalType {
  gold('Gold', 'GOLD'),
  silver('Silver', 'SILVER'),
  platinum('Platinum', 'PLATINUM'),
  diamond('Diamond', 'DIAMOND');

  final String label;
  final String dbValue;
  const CostingMetalType(this.label, this.dbValue);

  static CostingMetalType fromLabel(String l) =>
      CostingMetalType.values.firstWhere(
        (e) => e.label.toLowerCase() == l.toLowerCase(),
        orElse: () => CostingMetalType.gold,
      );
}
