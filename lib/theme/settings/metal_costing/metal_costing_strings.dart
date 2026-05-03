// =============================================================================
// FILE        : lib/theme/settings/metal_costing/metal_costing_strings.dart
// MODULE      : Metal Costing Analysis
// LAYER       : Theme / Strings
// =============================================================================

class MetalCostingStrings {
  MetalCostingStrings._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const String moduleBadge = 'METAL COST ANALYSER';
  static const String systemOnline = 'SYSTEM ONLINE';

  static const String hubTitle = 'METAL COST ANALYSER';
  static const String hubSub = 'Cost tracking & profit analysis by metal';

  // ── HUB SECTION ──────────────────────────────────────────────────────────
  static const String selectMetal = 'SELECT METAL TO ANALYSE';
  static const String totalProfit = 'Total Profit';
  static const String infoText =
      'Purchase cost, current market value aur sold price ka comparison. '
      'Rate fluctuation pe based profit/loss real-time calculate hota hai.';

  // ── METAL NAMES ───────────────────────────────────────────────────────────
  static const String gold = 'Gold';
  static const String silver = 'Silver';
  static const String platinum = 'Platinum';
  static const String diamond = 'Diamond';

  // ── PURITY SCREEN ────────────────────────────────────────────────────────
  static const String purityWise = 'Purity Wise Analysis';
  static const String soldItems = 'sold';
  static const String inStock = 'in stock';
  static const String stockValue = 'Stock Value (Today)';
  static const String profitSold = 'Total Profit (Sold)';
  static const String viewItems = 'View Items';

  // ── ITEM SCREEN ───────────────────────────────────────────────────────────
  static const String itemWisePL = 'Item Wise P&L';
  static const String tapToExpand = 'Tap any item to see full breakdown';

  // ── 3 PRICE BOXES ────────────────────────────────────────────────────────
  static const String purchaseCostLabel = 'PURCHASE COST';
  static const String currentValueLabel = 'CURRENT VALUE';
  static const String soldAtLabel = 'SOLD AT';
  static const String notSoldLabel = 'IN STOCK';

  // ── BREAKDOWN ────────────────────────────────────────────────────────────
  static const String purchaseBreakdown = 'PURCHASE COST BREAKDOWN';
  static const String currentBreakdown = 'CURRENT VALUE';
  static const String currentNote = '(Making charge nahi — sirf rate change)';
  static const String rateDiv100 = 'Rate ÷ 100';
  static const String timesWeight = '× Weight';
  static const String timesTanch = '× Tanch / Purity';
  static const String fineMetalCost = '= Fine Metal Cost';
  static const String makingCharge = '+ Making Charge';
  static const String totalPurchaseCost = 'Total Purchase Cost';
  static const String currentMetalValue = 'Current Metal Value';

  // ── PROFIT ANALYSIS ───────────────────────────────────────────────────────
  static const String profitAnalysis = 'PROFIT ANALYSIS';
  static const String profit1Label = 'Profit 1 — Sold At − Purchase Cost';
  static const String profit1Note = 'actual earning';
  static const String profit2Label = 'Profit 2 — Sold At − Current Value';
  static const String profit2Note = 'agar aaj khareedte to';
  static const String actualProfit = 'Actual Profit';
  static const String actualLoss = 'Actual Loss';
  static const String replProfit = 'Replacement Profit';
  static const String replLoss = 'Replacement Loss ⚠️';
  static const String rateMovement = 'RATE MOVEMENT (ITEM IN STOCK)';
  static const String metalGain = 'Metal Value Gain';
  static const String metalLoss = 'Metal Value Loss';
  static const String rateMoveSub = 'Purchase rate vs aaj ka rate (metal only)';
  static const String configure = 'Analyse';

  // ── INFO NOTE ────────────────────────────────────────────────────────────
  static const String profit1Info =
      'Profit 1 = aapka actual faayda jab aapne kharida tha us waqt ke rate se.';
  static const String profit2Info =
      'Profit 2 = agar aaj same item supplier se khareedte to kitna bachta.';
  static const String replacementWarn =
      'Rate badh gaya — usi sold price pe ab nuksaan hoga. Pricing update karein!';
}
