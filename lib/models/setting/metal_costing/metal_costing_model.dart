// =============================================================================
// FILE        : lib/models/metal_costing/metal_costing_model.dart
// MODULE      : Metal Costing Analysis
// LAYER       : Models
// DESCRIPTION : Pure data model for one stock item with cost+profit data.
//               Immutable. All calculations done in controller.
// =============================================================================

class MetalCostingItem {
  // ── Identification ─────────────────────────────────────────────────────────
  final int id;
  final String sku;
  final String itemName;
  final String metalType; // 'Gold', 'Silver', 'Platinum', 'Diamond'
  final String purity; // '18K (750)', '22K (916)', '925 (Sterling)', etc.

  // ── Purchase Data ──────────────────────────────────────────────────────────
  final double netWeight; // grams
  final double wastage; // tanch % — e.g. 79.0
  final double purchaseRate; // rate per 100g at purchase time
  final double makingCharge; // per gram
  final String makingChargeType;
  final DateTime purchaseDate;

  // ── Sale Data (null if unsold) ─────────────────────────────────────────────
  final double? soldPrice; // invoice sold price (from billing)
  final DateTime? soldDate;

  // ── Today's rate (injected by controller) ─────────────────────────────────
  final double todayRate; // rate per 100g — same metal, live/manual

  const MetalCostingItem({
    required this.id,
    required this.sku,
    required this.itemName,
    required this.metalType,
    required this.purity,
    required this.netWeight,
    required this.wastage,
    required this.purchaseRate,
    required this.makingCharge,
    required this.makingChargeType,
    required this.purchaseDate,
    this.soldPrice,
    this.soldDate,
    required this.todayRate,
  });

  bool get isSold => soldPrice != null;

  // ── FORMULA 1: Purchase Cost ───────────────────────────────────────────────
  // (purchaseRate / 100) × netWeight × (wastage / 100) + makingCharge × netWeight
  double get purchaseCost {
    final metalCost = (purchaseRate / 100) * netWeight * (wastage / 100);
    final making = makingChargeType == 'Flat Amount (Rs)'
        ? makingCharge
        : makingCharge * netWeight;
    return metalCost + making;
  }

  // ── FORMULA 2: Current Value ───────────────────────────────────────────────
  // (todayRate / 100) × netWeight × (wastage / 100)   ← NO making charge
  double get currentValue {
    return (todayRate / 100) * netWeight * (wastage / 100);
  }

  // ── FORMULA 3: Fine metal cost (for breakdown display) ────────────────────
  double get fineMetalCostAtPurchase {
    return (purchaseRate / 100) * netWeight * (wastage / 100);
  }

  double get makingAmount {
    return makingChargeType == 'Flat Amount (Rs)'
        ? makingCharge
        : makingCharge * netWeight;
  }

  // ── PROFITS ───────────────────────────────────────────────────────────────
  // Profit 1 = Sold At − Purchase Cost  (actual earning)
  double? get profit1 => isSold ? soldPrice! - purchaseCost : null;

  // Profit 2 = Sold At − Current Value  (replacement comparison)
  double? get profit2 => isSold ? soldPrice! - currentValue : null;

  // Rate movement on unsold stock
  double get rateMoveAmount => currentValue - purchaseCost;
  bool get rateWentUp => currentValue >= purchaseCost;

  // Replacement loss warning
  bool get hasReplacementLoss => isSold && profit2! < 0;
}

// ── Summary per purity ────────────────────────────────────────────────────────
class PuritySummary {
  final String purity;
  final List<MetalCostingItem> items;

  const PuritySummary({required this.purity, required this.items});

  List<MetalCostingItem> get soldItems => items.where((i) => i.isSold).toList();
  List<MetalCostingItem> get inStockItems =>
      items.where((i) => !i.isSold).toList();

  double get totalProfit1 =>
      soldItems.fold(0.0, (s, i) => s + (i.profit1 ?? 0));

  double get totalStockValue =>
      inStockItems.fold(0.0, (s, i) => s + i.currentValue);
}

// ── Summary per metal ─────────────────────────────────────────────────────────
class MetalSummary {
  final String metalType;
  final List<PuritySummary> purities;

  const MetalSummary({required this.metalType, required this.purities});

  List<MetalCostingItem> get allItems =>
      purities.expand((p) => p.items).toList();

  List<MetalCostingItem> get soldItems =>
      allItems.where((i) => i.isSold).toList();

  double get totalProfit1 =>
      soldItems.fold(0.0, (s, i) => s + (i.profit1 ?? 0));
}
