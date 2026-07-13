class InventoryStats {
  final int openingCount;
  final double openingWeight;
  final double openingValue;

  final int closingCount;
  final double closingWeight;
  final double closingValue;

  final int todayAdded;
  final int todaySold;

  final int goldCount;
  final double goldWeight;
  final double goldValue;

  final int silverCount;
  final double silverWeight;
  final double silverValue;

  final int diamondCount;
  final double diamondValue;

  final int platinumCount;
  final double platinumWeight;

  const InventoryStats({
    required this.openingCount,
    required this.openingWeight,
    required this.openingValue,
    required this.closingCount,
    required this.closingWeight,
    required this.closingValue,
    required this.todayAdded,
    required this.todaySold,
    required this.goldCount,
    required this.goldWeight,
    required this.goldValue,
    required this.silverCount,
    required this.silverWeight,
    required this.silverValue,
    required this.diamondCount,
    required this.diamondValue,
    required this.platinumCount,
    required this.platinumWeight,
  });

  int get netMovement => todayAdded - todaySold;

  bool get hasGold => goldCount > 0;
  bool get hasSilver => silverCount > 0;
  bool get hasDiamond => diamondCount > 0;
  bool get hasPlatinum => platinumCount > 0;

  static InventoryStats empty() => const InventoryStats(
        openingCount: 0,
        openingWeight: 0,
        openingValue: 0,
        closingCount: 0,
        closingWeight: 0,
        closingValue: 0,
        todayAdded: 0,
        todaySold: 0,
        goldCount: 0,
        goldWeight: 0,
        goldValue: 0,
        silverCount: 0,
        silverWeight: 0,
        silverValue: 0,
        diamondCount: 0,
        diamondValue: 0,
        platinumCount: 0,
        platinumWeight: 0,
      );
}
