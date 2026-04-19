// =============================================================================
// FILE        : add_stock_strings.dart
// MODULE      : Stock & Inventory
// LAYER       : Theme / Strings
// DESCRIPTION : All UI text for Add Stock. Single source of truth.
//               Easy to localize in future.
// =============================================================================

class AddStockStrings {
  AddStockStrings._();

  // ── HEADER ───────────────────────────────────────────────────
  static const String screenTitle      = 'ADD STOCK';
  static const String screenSubtitle   = 'Inventory mein naya item add karo';
  static const String moduleBadge      = 'Stock & Inventory';
  static const String systemOnline     = 'SYSTEM ONLINE';

  // ── WIZARD STEPS (NEW FROM PC 2) ─────────────────────────────
  static const String stepMetal        = 'Metal';
  static const String stepPurity       = 'Purity';
  static const String stepItems        = 'Items';

  // ── STEP 1: METAL (NEW FROM PC 2) ────────────────────────────
  static const String metalQuestion    = 'What are you adding?';
  static const String metalSubtitle    = 'Select the primary metal for this batch.';
  static const String metalGold        = 'Gold';
  static const String metalSilver      = 'Silver';
  static const String metalDiamond     = 'Diamond';
  static const String metalPlatinum    = 'Platinum';
  static const String btnNextPurity    = 'Continue to Purity';

  // ── STEP 2: PURITY (NEW FROM PC 2) ───────────────────────────
  static const String purityQuestion   = 'Select Purity';
  static const String purityCustomLabel= 'Custom Purity / Description';
  static const String purityCustomHint = 'e.g. 18K Rose Gold';
  static const String btnNextItems     = 'Continue to Items';

  // ── STEP 3: ITEMS MULTI-ROW (NEW FROM PC 2) ──────────────────
  static const String supplierSession  = 'Supplier for this batch';
  static const String sameForAll       = 'Same for all items';
  static const String btnAddRow        = 'Add Another Item';
  static const String ownerOnlyTitle   = 'Cost & Purchase Info (Owner Only)';
  static const String lblPurchaseRate  = 'Purchase Rate /g';
  static const String costPriceLabel   = 'Est. Cost Price: ';
  static const String lblSupplierRow   = 'Supplier (Specific to this item)';
  static const String supplierHint     = 'Search by name or mobile...';
  static const String lblStoneValue    = 'Stone Value';
  static const String stoneValueNote   = 'Entered in Rupees (₹). This value is added to the final price, NOT deducted from metal.';

  // ── DIALOGS (NEW FROM PC 2) ──────────────────────────────────
  static const String savedTitle       = 'Stock Added Successfully';
  static const String btnAddMore       = 'Add More Items';
  static const String btnNewBatch      = 'Start New Batch';
  static const String btnDone          = 'Done & Exit';

  // ── SECTION TITLES ───────────────────────────────────────────
  static const String secBasicInfo     = 'Basic Information';
  static const String secMetalDetails  = 'Metal Details';
  static const String secStoneDetails  = 'Stone / Diamond Details';
  static const String secPricing       = 'Pricing';
  static const String secCompliance    = 'GST & Compliance';
  static const String secInventory     = 'Inventory & Location';

  // ── SECTION DESCRIPTIONS ─────────────────────────────────────
  static const String descBasicInfo    = 'Item ka naam, category aur SKU';
  static const String descMetal        = 'Dhatu ka prakar, shuddhi aur wajan';
  static const String descStone        = 'Heera aur ratna ki jaankari';
  static const String descPricing      = 'Lagat, MRP aur GST daren';
  static const String descCompliance   = 'HSN code aur BIS hallmark HUID';
  static const String descInventory    = 'Matra, rack aur supplier';

  // ── FIELD LABELS ─────────────────────────────────────────────
  static const String lblItemName      = 'Item Name *';
  static const String lblSku           = 'SKU / Barcode';
  static const String lblCategory      = 'Category *';
  static const String lblSubCategory   = 'Sub Category *';
  static const String lblDescription   = 'Description (Optional)';
  static const String lblMetalType     = 'Metal Type';
  static const String lblPurity        = 'Purity';
  static const String lblGrossWeight   = 'Gross Weight (g)';
  static const String lblStoneWeight   = 'Stone Weight (g)';
  static const String lblNetWeight     = 'Net Weight (g)';
  static const String lblStoneType     = 'Stone Type';
  
  // ✅ FIX: Matched exactly with PC 2 UI requirements
  static const String lblCarats        = 'Stone Carats';
  static const String lblPieces        = 'Stone Pieces';
  
  static const String lblMakingType    = 'Making Charges Type';
  static const String lblMakingCharges = 'Making Charges';
  static const String lblPurchasePrice = 'Purchase Price (₹)';
  static const String lblMrp           = 'MRP / Selling Price (₹)';
  static const String lblGstRate       = 'GST Rate (%)';
  static const String lblHsnPreset     = 'HSN Code (Quick Select)';
  static const String lblHsnCode       = 'HSN Code';
  static const String lblHuid          = 'HUID (Hallmark Unique ID)';
  static const String lblQuantity      = 'Quantity *';
  static const String lblRackLocation  = 'Rack / Location';
  static const String lblStatus        = 'Status';
  static const String lblSupplier      = 'Supplier Name';

  // ── HINTS ────────────────────────────────────────────────────
  static const String hintItemName     = 'e.g. Ladies Gold Ring 22K';
  static const String hintSku          = 'Auto-generated';
  static const String hintDescription  = 'Optional — Floral design, 5 stones...';
  static const String hintWeight       = '0.000';
  static const String hintCarats       = '0.00';
  static const String hintPieces       = '0';
  static const String hintPrice        = '0.00';
  static const String hintGstRate      = '3.0';
  static const String hintHuid         = '6-char BIS code e.g. AB1234';
  static const String hintRack         = 'e.g. Shelf-A1, Counter-3';
  static const String hintQuantity     = '1';

  // ── ACTIONS ──────────────────────────────────────────────────
  static const String btnSave          = 'Save Stock Item';
  static const String btnSaving        = 'Saving...';
  static const String btnReset         = 'Reset Form';

  // ── NOTES ────────────────────────────────────────────────────
  static const String noteHuid         = '⚠  HUID is mandatory for BIS Hallmarked gold (BIS Order 2021)';
  
  // ✅ FIX: Matched exactly with PC 2 UI requirements
  static const String netWeightNote    = 'Auto calculated: Gross − Stone';
  
  static const String noteNoStone      = 'Select a stone type above to enable stone fields';

  // ── SUCCESS / ERROR ──────────────────────────────────────────
  static const String errItemName      = 'Item name is required';
  static const String errItemNameShort = 'Name is too short';
  static const String errQuantity      = 'Quantity is required';
  static const String errQtyMin        = 'Minimum 1 piece required';
  static const String errQtyInvalid    = 'Enter a valid number';
  static const String errWeightNeg     = 'Weight cannot be negative';
  static const String errWeightInvalid = 'Enter a valid weight';
  static const String errPriceNeg      = 'Price cannot be negative';
  static const String errPriceInvalid  = 'Enter a valid amount';
  static const String errHuidLength    = 'HUID must be exactly 6 characters';
  static const String errSkuExists     = 'This SKU already exists. Please enter a unique SKU.';
  static const String errSaveFailed    = 'Could not save. Please try again.';
}