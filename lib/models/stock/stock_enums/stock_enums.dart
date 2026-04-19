// =============================================================================
// FILE        : stock_enums.dart
// MODULE      : Stock & Inventory
// LAYER       : Models / Enums
// DESCRIPTION : All enums for Add Stock. Single source of truth.
// =============================================================================

enum StockCategory {
  gold('Gold'),
  silver('Silver'),
  diamond('Diamond'),
  antique('Antique'),
  platinum('Platinum'),
  other('Other');

  final String label;
  const StockCategory(this.label);

  static StockCategory fromLabel(String l) =>
      StockCategory.values.firstWhere((e) => e.label == l,
          orElse: () => StockCategory.other);
}

enum StockSubCategory {
  ring('Ring'),
  necklace('Necklace'),
  bangle('Bangle'),
  earring('Earring'),
  pendant('Pendant'),
  bracelet('Bracelet'),
  chain('Chain'),
  anklet('Anklet'),
  noseRing('Nose Ring'),
  mangalsutra('Mangalsutra'),
  set_('Set'),
  other('Other');

  final String label;
  const StockSubCategory(this.label);

  static StockSubCategory fromLabel(String l) =>
      StockSubCategory.values.firstWhere((e) => e.label == l,
          orElse: () => StockSubCategory.other);
}

enum MetalType {
  gold('Gold'),
  silver('Silver'),
  platinum('Platinum'),
  none('None / Other');

  final String label;
  const MetalType(this.label);

  static MetalType fromLabel(String l) =>
      MetalType.values.firstWhere((e) => e.label == l,
          orElse: () => MetalType.none);
}

enum GoldPurity {
  k24('24K (999)'),
  k22('22K (916)'),
  k18('18K (750)'),
  k14('14K (585)'),
  k10('10K (417)'),
  other('Other');

  final String label;
  const GoldPurity(this.label);
}

enum SilverPurity {
  s999('999 (Pure)'),
  s925('925 (Sterling)'),
  s800('800'),
  s700('700'),
  other('Other');

  final String label;
  const SilverPurity(this.label);
}

enum PlatinumPurity {
  pt950('950 Platinum'),
  pt900('900 Platinum'),
  pt850('850 Platinum'),
  other('Other');

  final String label;
  const PlatinumPurity(this.label);
}

enum MakingChargesType {
  perGram('Per Gram (Rs/g)'),
  flat('Flat Amount (Rs)'),
  percent('Percent (%)');

  final String label;
  const MakingChargesType(this.label);

  static MakingChargesType fromLabel(String l) =>
      MakingChargesType.values.firstWhere((e) => e.label == l,
          orElse: () => MakingChargesType.perGram);
}

enum StoneType {
  none('None'),
  diamond('Diamond'),
  ruby('Ruby'),
  emerald('Emerald'),
  sapphire('Sapphire'),
  pearl('Pearl'),
  polki('Polki'),
  coral('Coral'),
  turquoise('Turquoise'),
  other('Other');

  final String label;
  const StoneType(this.label);

  bool get hasDetails => this != StoneType.none;

  static StoneType fromLabel(String l) =>
      StoneType.values.firstWhere((e) => e.label == l,
          orElse: () => StoneType.none);
}

enum StockStatus {
  available('Available'),
  sold('Sold'),
  onOrder('On Order'),
  withKarigar('With Karigar'),
  repaired('Repaired');

  final String label;
  const StockStatus(this.label);

  static StockStatus fromLabel(String l) =>
      StockStatus.values.firstWhere((e) => e.label == l,
          orElse: () => StockStatus.available);
}

enum JewelleryHsn {
  h7113('7113', '7113 — Gold/Silver/Platinum Jewellery'),
  h7114('7114', '7114 — Articles of Goldsmiths/Silversmiths'),
  h7116('7116', '7116 — Articles of Precious/Semi-precious Stone'),
  h7117('7117', '7117 — Imitation Jewellery');

  final String code;
  final String label;
  const JewelleryHsn(this.code, this.label);
}