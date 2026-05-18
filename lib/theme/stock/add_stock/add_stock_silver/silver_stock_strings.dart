// =============================================================================
// FILE        : silver_stock_strings.dart
// MODULE      : Stock & Inventory (Silver)
// LAYER       : Theme / Strings
// DESCRIPTION : Centralized string dictionary for Silver Module.
//               Full parity with AddStockStrings (Gold).
// =============================================================================

class SilverStockStrings {
  SilverStockStrings._();

  // ── SCREEN HEADER ────────────────────────────────────────────
  static const String screenTitle = 'ADD STOCK';
  static const String screenSubtitle =
      'Register new Silver items into inventory';
  static const String moduleBadge = 'Stock & Inventory';
  static const String systemOnline = 'SYSTEM ONLINE';

  // ── TOP HEADER (Batch Code Row) ───────────────────────────────
  static const String headerTitle = 'SILVER';
  static const String headerSubtitle = 'ADD STOCK • BATCH:';
  static const String statTotalItems = 'TOTAL ITEMS';
  static const String statNetWeight = 'NET WEIGHT';

  // ── STEP LABELS ──────────────────────────────────────────────
  static const String stepPurity = 'Purity';
  static const String stepItems = 'Items';

  // ── PURITY STEP ──────────────────────────────────────────────
  static const String purityQuestion = 'Select Purity Grade';
  static const String purityCustomLabel = 'Enter Custom Purity';
  static const String purityCustomHint = 'e.g. 800 Silver, 92.5 Sterling';
  static const String btnNextItems = 'Continue to Item Entry';

  // ── BATCH CONFIGURATION PANEL ────────────────────────────────
  static const String configPanelTitle = 'BATCH CONFIGURATION';
  static const String taxStatusNormal = 'NORMAL BILLING';
  static const String taxStatusGst = 'GST ENABLED (3%)';
  static const String supplierInvoiceId = 'Supplier Invoice ID';
  static const String systemInvoiceId = 'System Batch ID';

  // ── SUPPLIER ─────────────────────────────────────────────────
  static const String supplierSession = 'Supplier for this batch';
  static const String sameForAll = 'Same for all items';
  static const String supplierHint = 'Search by name or mobile number...';
  static const String noSupplierSaved =
      'No suppliers on record. You may also enter a name manually.';

  // ── SUPPLIER PROFILE PANEL ───────────────────────────────────
  static const String supplierProfileTitle = 'SUPPLIER PROFILE';
  static const String supplierProfileDesc =
      'Search by name or mobile and bind this entire batch to one supplier ledger';
  static const String ledgerLinked = 'Ledger Linked';
  static const String lookupReady = 'Lookup Ready';
  static const String createSupplier = 'Create Supplier';
  static const String fieldMobileNumber = 'MOBILE NUMBER';
  static const String fieldSupplierName = 'SUPPLIER NAME';
  static const String fieldAddress = 'ADDRESS';
  static const String hintSearchByPhone = 'Search by phone';
  static const String hintSearchByName = 'Search by supplier name';
  static const String hintAutoFilled = 'Auto-filled after link';
  static const String linkedBatchMessage =
      'This batch will be recorded against the supplier ledger automatically.';
  static const String lookupHelperMessage =
      'Search by mobile or supplier name to link one supplier ledger. Linked details will appear here automatically.';
  static const String notFoundMessage =
      'No supplier profile matched this lookup. Create the supplier first so this silver batch can be linked to the correct ledger.';
  static const String contactPrefix = 'Contact: ';
  static const String sameForAllLabel = 'SAME FOR ALL';
  static const String gstPrefix = 'GST ';
  static const String linkedSupplierFallback = 'Linked Supplier';

  // ── ITEM TABLE (CART) ────────────────────────────────────────
  static const String tableColSubCategory = 'Sub-Category';
  static const String tableColCompany = 'Company / Supplier';
  static const String tableColGrossWt = 'Gross Wt.';
  static const String tableColPcs = 'Pcs';
  static const String tableColHuid = 'HUID (Optional)';
  static const String customItemHint = 'Enter custom item name';
  static const String btnAddRow = 'Add Another Item';

  // ── OWNER-ONLY / COST INFO ────────────────────────────────────
  static const String ownerOnlyTitle = 'Cost & Purchase Info (Owner Only)';
  static const String lblPurchaseRate = 'Purchase Rate /g';
  static const String costPriceLabel = 'Est. Cost Price';
  static const String lblStoneValue = 'Stone Value (Rs)';
  static const String stoneValueNote =
      'Amount in Rupees. This value is added to the final price as a separate line — it is NOT deducted from the metal weight.';

  // ── RIGHT BILLING PANEL ──────────────────────────────────────
  static const String billingLiveRate = 'Live Silver Rate';
  static const String billingMetalGiven = 'Metal Supplied (Melted)';
  static const String billingCashGiven = 'Cash Paid (₹)';
  static const String billingDueMetal = 'Due converted to Fine (g)';
  static const String batchOverview = 'Batch Overview';
  static const String batchInsights =
      'Metal type, purity, supplier and running inventory totals.';

  // ── BATCH OVERVIEW STATS ─────────────────────────────────────
  static const String overviewPieces = 'Pieces';
  static const String overviewGross = 'Gross Wt';
  static const String overviewNet = 'Net Wt';
  static const String overviewCost = 'Est. Cost';
  static const String overviewSale = 'Est. Sale';

  // ── VALIDATION STATUS ────────────────────────────────────────
  static const String rowsNeedAttention = 'rows need attention';
  static const String readyToSave = 'Ready to save';

  // ── CONFIRM DIALOGS ──────────────────────────────────────────
  static const String confirmResetTitle = 'Reset current batch?';
  static const String confirmResetBody =
      'All purity selections, item rows, supplier mappings and pricing inputs will be cleared.';
  static const String confirmExitTitle = 'Discard unsaved batch?';
  static const String confirmExitBody =
      'Unsaved rows, purity selection and supplier inputs will be permanently lost.';

  // ── SUCCESS STATE ────────────────────────────────────────────
  static const String savedTitle = 'Stock Added Successfully';
  static const String btnAddMore = 'Add More Items';
  static const String btnNewBatch = 'Start New Batch';
  static const String btnDone = 'Done & Exit';

  // ── BUTTON LABELS ────────────────────────────────────────────
  static const String btnResetBatch = 'Reset Batch';
  static const String btnBackPurity = 'Back to Purity';
  static const String btnKeepEditing = 'Keep Editing';
  static const String btnDiscard = 'Discard';
  static const String btnCancel = 'Cancel';
  static const String btnSave = 'Save Stock Item';
  static const String btnSaving = 'Saving…';
  static const String btnReset = 'Reset Form';

  // ── SECTION NAMES ────────────────────────────────────────────
  static const String secBasicInfo = 'Basic Information';
  static const String secMetal = 'Metal Details';
  static const String secStone = 'Stone / Diamond Details';
  static const String secPricing = 'Pricing';
  static const String secCompliance = 'GST & Compliance';
  static const String secInventory = 'Inventory & Location';

  static const String descBasicInfo = 'Item name, category and description';
  static const String descMetal = 'Metal type, purity and weight details';
  static const String descStone = 'Stone, diamond and gemstone information';
  static const String descPricing = 'Cost rate, MRP and applicable GST';
  static const String descCompliance = 'HSN code and BIS hallmark HUID';
  static const String descInventory = 'Quantity, rack location and supplier';

  // ── FIELD LABELS ─────────────────────────────────────────────
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
  static const String lblSupplierRow = 'Supplier (Item-specific)';

  // ── HINT TEXTS ───────────────────────────────────────────────
  static const String hintItemName = 'e.g. Silver Kangan 925 Sterling';
  static const String hintSku = 'Auto-generated';
  static const String hintDescription =
      'Optional — Floral design, wedding set, pooja item…';
  static const String hintWeight = '0.000';
  static const String hintCarats = '0.00';
  static const String hintPieces = '0';
  static const String hintPrice = '0.00';
  static const String hintGstRate = '3.0';
  static const String hintHuid = '6-character BIS code, e.g. AB1234';
  static const String hintRack = 'e.g. Shelf-A1, Counter-3';
  static const String hintQuantity = '1';

  // ── NOTES ────────────────────────────────────────────────────
  static const String noteHuid =
      'HUID is recommended for hallmarked inventory and BIS traceability compliance.';
  static const String netWeightNote =
      'Auto-calculated — Gross minus Stone weight';
  static const String noteNoStone =
      'Select a stone type above to enable gem detail fields';

  // ── ERROR MESSAGES ───────────────────────────────────────────
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

  static const String paymentRecordTitle = 'Payment Record';
  static const String paymentRecordSubtitle =
      'Live bill definition and supplier settlement';
  static const String paymentStatementTitle = 'Payment Statement';
  static const String paymentStatementSubtitle =
      'See every rupee and metal adjustment without extra scrolling.';
  static const String paymentModesTitle = 'Payment Modes';
  static const String paymentModesSubtitle =
      'Choose how this silver batch is being settled.';
  static const String paymentCollectionTitle = 'Collection Entry';
  static const String paymentCollectionSubtitle =
      'Enter metal adjustment and the remaining payment split.';
  static const String finalSettlementTitle = 'Final Settlement';
  static const String finalSettlementSubtitle =
      'Due, return and settlement direction are resolved here.';
  static const String invoiceSummaryTitle = 'Invoice Summary';
  static const String invoiceSummarySubtitle =
      'Item snapshot, fine total, making and final payable.';
  static const String invoiceSnapshotTitle = 'Item Snapshot';
  static const String invoiceSnapshotSubtitle =
      'Every entered silver line is listed exactly as it will be billed.';
  static const String promiseDateLabel = 'Promise Date';
  static const String promiseDateHint = 'Tap to set follow-up date';
  static const String clearPromiseDate = 'Clear Date';
  static const String gstIncludedLabel = 'GST Included';
  static const String gstExcludedLabel = 'No GST Applied';
  static const String rateVarianceNote =
      'Invoice rate differs from one or more item rates, so snapshot total and payable may not fully match.';
  static const String totalFineLabel = 'Total Fine';
  static const String makingTotalLabel = 'Making Total';
  static const String itemSnapshotTotalLabel = 'Item Snapshot Total';
  static const String invoiceSubtotalLabel = 'Invoice Subtotal';
  static const String finalBillAmountLabel = 'Final Bill Amount';
  static const String totalReceivedLabel = 'Total Received';
  static const String currentDueLabel = 'Current Due';
  static const String supplierReturnLabel = 'Supplier Return';
  static const String cashLabel = 'Cash';
  static const String upiLabel = 'UPI';
  static const String bankLabel = 'Bank Transfer';
  static const String cardLabel = 'Card';
  static const String metalLabel = 'Metal Adjust';
  static const String perGramLabel = 'Per Gram';
  static const String marketRefLabel = 'Market Reference';
  static const String todaySilverRateLabel = 'Today Silver Rate';
  static const String manualGstLabel = 'Manual GST';
  static const String autoGstLabel = 'Auto GST';
  static const String settlementCompleteLabel = 'Settlement Complete';
  static const String duePendingLabel = 'Due Pending';
  static const String returnPendingLabel = 'Return Pending';
  static const String cashCollectionLabel = 'Cash Collection';
  static const String metalAdjustmentLabel = 'Metal Adjustment';
  static const String lineTotalLabel = 'Line Total';
  static const String purityLabelShort = 'Purity';
}
