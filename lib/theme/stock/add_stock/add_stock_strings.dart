class AddStockStrings {
  AddStockStrings._();

  static const String screenTitle = 'ADD STOCK';
  static const String screenSubtitle = 'Register new items into inventory';
  static const String moduleBadge = 'Stock & Inventory';
  static const String systemOnline = 'SYSTEM ONLINE';

  static const String stepMetal = 'Metal';
  static const String stepPurity = 'Purity';
  static const String stepItems = 'Items';

  static const String purityQuestion = 'Select Purity Grade';
  static const String purityCustomLabel = 'Enter Custom Purity';
  static const String purityCustomHint = 'e.g. 18K Rose Gold, 950 Platinum';
  static const String btnNextItems = 'Continue to Item Entry';

  static const String supplierSession = 'Supplier for this batch';
  static const String sameForAll = 'Same for all items';
  static const String btnAddRow = 'Add Another Item';
  static const String ownerOnlyTitle = 'Cost & Purchase Info (Owner Only)';
  static const String lblPurchaseRate = 'Purchase Rate /g';
  static const String costPriceLabel = 'Est. Cost Price';
  static const String lblSupplierRow = 'Supplier (Item-specific)';
  static const String supplierHint = 'Search by name or mobile number...';
  static const String noSupplierSaved =
      'No suppliers on record. You may also enter a name manually.';
  static const String lblStoneValue = 'Stone Value (Rs)';
  static const String stoneValueNote =
      'Amount in Rupees. This value is added to the final price as a separate line — it is NOT deducted from the metal weight.';
  static const String batchOverview = 'Batch Overview';
  static const String batchInsights =
      'Metal type, purity, supplier and running inventory totals.';
  static const String overviewPieces = 'Pieces';
  static const String overviewGross = 'Gross Wt';
  static const String overviewNet = 'Net Wt';
  static const String overviewCost = 'Est. Cost';
  static const String overviewSale = 'Est. Sale';
  static const String rowsNeedAttention = 'rows need attention';
  static const String readyToSave = 'Ready to save';
  static const String confirmResetTitle = 'Reset current batch?';
  static const String confirmResetBody =
      'All purity selections, item rows, supplier mappings and pricing inputs will be cleared.';
  static const String confirmExitTitle = 'Discard unsaved batch?';
  static const String confirmExitBody =
      'Unsaved rows, purity selection and supplier inputs will be permanently lost.';

  static const String savedTitle = 'Stock Added Successfully';
  static const String btnAddMore = 'Add More Items';
  static const String btnNewBatch = 'Start New Batch';
  static const String btnDone = 'Done & Exit';
  static const String btnResetBatch = 'Reset Batch';
  static const String btnBackPurity = 'Back to Purity';
  static const String btnKeepEditing = 'Keep Editing';
  static const String btnDiscard = 'Discard';
  static const String btnCancel = 'Cancel';

  static const String secBasicInfo = 'Basic Information';
  static const String secMetalDetails = 'Metal Details';
  static const String secStoneDetails = 'Stone / Diamond Details';
  static const String secPricing = 'Pricing';
  static const String secCompliance = 'GST & Compliance';
  static const String secInventory = 'Inventory & Location';

  static const String descBasicInfo = 'Item name, category and description';
  static const String descMetal = 'Metal type, purity and weight details';
  static const String descStone = 'Stone, diamond and gemstone information';
  static const String descPricing = 'Cost rate, MRP and applicable GST';
  static const String descCompliance = 'HSN code and BIS hallmark HUID';
  static const String descInventory = 'Quantity, rack location and supplier';

  static const String lblItemName = 'Item Name *';
  static const String lblSku = 'SKU / Barcode';
  static const String lblCategory = 'Category *';
  static const String lblSubCategory = 'Sub-Category *';
  static const String lblDescription = 'Description';
  static const String lblMetalType = 'Metal Type';
  static const String lblPurity = 'Purity';
  static const String lblGrossWeight = 'Gross Weight (g)';
  static const String lblStoneWeight = 'Stone Weight (g)';
  static const String lblNetWeight = 'Net Weight (g)';
  static const String lblStoneType = 'Stone Type';
  static const String lblCarats = 'Stone Carats';
  static const String lblPieces = 'Stone Pieces';
  static const String lblMakingType = 'Making Charges Type';
  static const String lblMakingCharges = 'Making Charges';
  static const String lblPurchasePrice = 'Purchase Price (Rs)';
  static const String lblMrp = 'MRP / Selling Price (Rs)';
  static const String lblGstRate = 'GST Rate (%)';
  static const String lblHsnPreset = 'HSN Code — Quick Select';
  static const String lblHsnCode = 'HSN Code';
  static const String lblHuid = 'HUID (BIS Hallmark ID)';
  static const String lblQuantity = 'Quantity *';
  static const String lblRackLocation = 'Rack / Location';
  static const String lblStatus = 'Status';
  static const String lblSupplier = 'Supplier Name';

  static const String hintItemName = 'e.g. Ladies Gold Ring 22K';
  static const String hintSku = 'Auto-generated';
  static const String hintDescription =
      'Optional — Floral design, wedding band, office wear…';
  static const String hintWeight = '0.000';
  static const String hintCarats = '0.00';
  static const String hintPieces = '0';
  static const String hintPrice = '0.00';
  static const String hintGstRate = '3.0';
  static const String hintHuid = '6-character BIS code, e.g. AB1234';
  static const String hintRack = 'e.g. Shelf-A1, Counter-3';
  static const String hintQuantity = '1';

  static const String btnSave = 'Save Stock Item';
  static const String btnSaving = 'Saving…';
  static const String btnReset = 'Reset Form';

  static const String noteHuid =
      'HUID is recommended for hallmarked inventory and BIS traceability compliance.';
  static const String netWeightNote =
      'Auto-calculated — Gross minus Stone weight';
  static const String noteNoStone =
      'Select a stone type above to enable gem detail fields';

  static const String errItemName = 'Item name is required';
  static const String errItemNameShort = 'Name must be at least 2 characters';
  static const String errQuantity = 'Quantity is required';
  static const String errQtyMin = 'Minimum quantity is 1 piece';
  static const String errQtyInvalid = 'Enter a valid whole number';
  static const String errWeightNeg = 'Weight cannot be a negative value';
  static const String errWeightInvalid = 'Enter a valid weight in grams';
  static const String errPriceNeg = 'Price values cannot be negative';
  static const String errPriceInvalid = 'Enter a valid amount';
  static const String errHuidLength = 'HUID must be exactly 6 characters';
  static const String errSkuExists =
      'This SKU already exists. Please use a unique SKU.';
  static const String errSaveFailed = 'Could not save. Please try again.';
  static const String errPurityRequired =
      'Please select a purity grade to proceed';
  static const String errRowsMissing = 'At least one item row is required';
  static const String errStoneWeightExceeds =
      'Stone weight cannot exceed gross weight';
  static const String errGstRange = 'GST rate must be between 0 and 100';
  static const String errDuplicateHuidInBatch =
      'Duplicate HUID within current batch';
  static const String errDuplicateHuidInStock = 'HUID already exists in stock';
}
