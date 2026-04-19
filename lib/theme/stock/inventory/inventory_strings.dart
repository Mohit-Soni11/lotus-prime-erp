// =============================================================================
// FILE        : inventory_strings.dart
// MODULE      : Stock & Inventory
// LAYER       : Theme / Strings
// DESCRIPTION : All UI text for Inventory Ledger. Single source of truth.
// =============================================================================

class InvStrings {
  InvStrings._();

  // ── HEADER ───────────────────────────────────────────────────
  static const String screenTitle     = 'INVENTORY LEDGER';
  static const String screenSubtitle  = 'Poore stock ka hisaab — ek jagah';
  static const String moduleBadge     = 'Stock & Inventory';
  static const String systemOnline    = 'SYSTEM ONLINE';

  // ── PAGE HEADER ──────────────────────────────────────────────
  static const String pageTitle       = 'Inventory Ledger';
  static const String pageSubtitle    = 'Opening & Closing stock — Metal-wise holdings';

  // ── SUMMARY CARDS ────────────────────────────────────────────
  static const String cardOpening     = 'Opening Stock';
  static const String cardOpeningNote = 'Aaj se pehle ka maal';
  static const String cardClosing     = 'Closing Stock';
  static const String cardClosingNote = 'Abhi available maal';
  static const String cardMetal       = 'Metal Holdings';
  static const String cardMetalNote   = 'Category-wise breakdown';

  // ── SUMMARY LABELS ────────────────────────────────────────────
  static const String lblItems        = 'Items';
  static const String lblPieces       = 'pcs';
  static const String lblGrams        = 'g';
  static const String lblValue        = 'Total Value';
  static const String lblWeight       = 'Gross Weight';
  static const String lblTodayIn      = 'Today In';
  static const String lblTodaySold    = 'Today Sold';

  // ── METAL HOLDINGS ────────────────────────────────────────────
  static const String lblGold         = 'Gold';
  static const String lblSilver       = 'Silver';
  static const String lblDiamond      = 'Diamond';
  static const String lblPlatinum     = 'Platinum';

  // ── SECTION ───────────────────────────────────────────────────
  static const String secStockList    = 'Stock Items';
  static const String secListSubtitle = 'Category se filter karo';

  // ── ITEM CARD ────────────────────────────────────────────────
  static const String lblSku          = 'SKU';
  static const String lblCategory     = 'Category';
  static const String lblMrp          = 'MRP';
  static const String lblGrossWt      = 'Gross Wt';
  static const String lblNetWt        = 'Net Wt';
  static const String lblQty          = 'Qty';
  static const String lblPurity       = 'Purity';
  static const String lblStatus       = 'Status';

  // ── EMPTY STATE ──────────────────────────────────────────────
  static const String emptyTitle      = 'Koi item nahi mila';
  static const String emptySubtitle   = 'Is category mein abhi koi stock nahi hai.\nAdd Stock se naya item add karo.';
  static const String emptyAll        = 'Abhi koi stock nahi hai.\nAdd Stock se pehla item add karo.';
}