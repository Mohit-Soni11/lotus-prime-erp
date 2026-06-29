// =============================================================================
// FILE        : lib/theme/settings/billing_setup/billing_setup_strings.dart
// MODULE      : Billing Setup
// LAYER       : Theme / Strings
// DESCRIPTION : All display text constants — zero hardcoded strings in UI.
//               Mirrors KarigarStrings pattern.
//               v14 UPDATE: Metal hub + metal settings strings added.
// =============================================================================

class BillingSetupStrings {
  BillingSetupStrings._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const String moduleBadge = 'BILLING SETUP';
  static const String systemOnline = 'SYSTEM ONLINE';

  static const String hubTitle = 'BILLING SETUP';
  static const String hubSub = 'Invoice, payment & terms configuration';

  static const String salesTitle = 'SALES BILLING';
  static const String salesSub = 'Sales invoice configuration';

  static const String purchaseTitle = 'PURCHASE BILLING';
  static const String purchaseSub = 'Customer jewellery purchase configuration';

  static const String girviTitle = 'GIRVI BILLING';
  static const String girviSub = 'Gold loan ticket configuration';

  static const String returnTitle = 'RETURN & BUYBACK';
  static const String returnSub = 'Return policy configuration';

  // ── HUB CARDS (v14 — only 2 cards now: Sales + Purchase) ─────────────────
  static const String cardSalesTitle = 'Sales Billing';
  static const String cardSalesSub =
      'Invoice display, return policy & terms\nper metal type';
  static const String cardSalesTag = 'Gold · Silver · Diamond · Platinum';

  static const String cardPurchaseTitle = 'Purchase Billing';
  static const String cardPurchaseSub =
      'Seller KYC, valuation, payout policy & terms\nper metal type';
  static const String cardPurchaseTag = 'Gold · Silver · Diamond · Platinum';

  static const String hubInfoNote =
      'Each metal type has its own invoice display rules, '
      'return policy and terms. Changes apply to new bills only.';

  // ── METAL HUB ─────────────────────────────────────────────────────────────
  static const String selectMetal = 'SELECT METAL TYPE';

  // Metal display names
  static const String metalGold = 'Gold';
  static const String metalSilver = 'Silver';
  static const String metalDiamond = 'Diamond';
  static const String metalPlatinum = 'Platinum';

  // Metal emojis
  static const String emojiGold = '🥇';
  static const String emojiSilver = '🥈';
  static const String emojiDiamond = '💎';
  static const String emojiPlatinum = '⬜';

  // Metal hub card subtitles — Sales
  static const String goldSalesSub =
      'Invoice display, HUID, return\npolicy & T&C for gold bills';
  static const String silverSalesSub =
      'Invoice display, purity, return\npolicy & T&C for silver bills';
  static const String diamondSalesSub =
      'Carat, clarity, certification,\nreturn policy & T&C for diamond';
  static const String platinumSalesSub =
      'Invoice display, purity, return\npolicy & T&C for platinum bills';

  // Metal hub card subtitles — Purchase
  static const String goldPurchaseSub =
      'Seller KYC, HUID, valuation\npolicy & T&C for gold purchase';
  static const String silverPurchaseSub =
      'Seller KYC, purity, payout\npolicy & T&C for silver purchase';
  static const String diamondPurchaseSub =
      'Seller KYC, carat, clarity,\nvaluation policy & T&C for diamond';
  static const String platinumPurchaseSub =
      'Seller KYC, purity, payout\npolicy & T&C for platinum purchase';

  // Helper — subtitle for a metal in Sales hub
  static String salesMetalSub(String metal) {
    switch (metal) {
      case 'gold':
        return goldSalesSub;
      case 'silver':
        return silverSalesSub;
      case 'diamond':
        return diamondSalesSub;
      case 'platinum':
        return platinumSalesSub;
      default:
        return '';
    }
  }

  // Helper — subtitle for a metal in Purchase hub
  static String purchaseMetalSub(String metal) {
    switch (metal) {
      case 'gold':
        return goldPurchaseSub;
      case 'silver':
        return silverPurchaseSub;
      case 'diamond':
        return diamondPurchaseSub;
      case 'platinum':
        return platinumPurchaseSub;
      default:
        return '';
    }
  }

  // ── METAL SETTINGS SCREEN — Section Headers ───────────────────────────────
  static const String secInvoiceDisplay = 'Invoice Item Display';
  static const String subInvoiceDisplay =
      'What appears on each line item of the bill';

  static const String secVoucherDisplay = 'Purchase Voucher Display';
  static const String subVoucherDisplay =
      'What appears on each line item of the purchase voucher';

  static const String secReturnBuyback = 'Return & Buyback Policy';
  static const String subReturnBuyback =
      'Rules for this metal\'s return & exchange';

  static const String secPurchaseReturn = 'Seller Purchase Policy';
  static const String subPurchaseReturn =
      'KYC, ownership, valuation and payout rules';

  static const String secTermsTemplate = 'Terms & Template';

  // ── INVOICE DISPLAY TOGGLE LABELS ─────────────────────────────────────────
  static const String togPieces = 'Pieces (Pcs)';
  static const String togPiecesSub = 'Number of pieces in the item';

  static const String togGrossWeight = 'Gross Weight';
  static const String togGrossWeightSub = 'Total weight before deductions';

  static const String togLessWeight = 'Less / Stone Weight';
  static const String togLessWeightSub =
      'Weight deducted (stone, beading etc.)';

  static const String togNetWeight = 'Net Weight';
  static const String togNetWeightSub = 'Weight after deductions';

  static const String togPurity = 'Purity / Tunch';
  static const String togPuritySub = 'e.g. 22KT, 925, 950PT';

  static const String togRate = 'Rate (₹/g)';
  static const String togRateSub = 'Metal rate per gram';

  static const String togRateCarat = 'Rate (₹/ct)';
  static const String togRateCaratSub = 'Diamond rate per carat';

  static const String togMaking = 'Making Charges';
  static const String togMakingSub = 'Labour/making charge amount';

  static const String togMakingType = 'Making Charge Type';
  static const String togMakingTypeSub = 'Show /g or % or /pc label';

  static const String togFineWeight = 'Fine Weight';
  static const String togFineWeightSub = 'Calculated: net wt × purity %';

  static const String togHuid = 'HUID Number';
  static const String togHuidSub = 'BIS Hallmark HUID — govt. mandatory';

  static const String togHuidPurchase = 'HUID Number';
  static const String togHuidPurchaseSub =
      'BIS Hallmark HUID — mandatory for gold purchase';

  static const String togWastage = 'Wastage %';
  static const String togWastageSub = 'Wastage shown as a separate line';

  static const String togOldGold = 'Old Gold Exchange Line';
  static const String togOldGoldSub =
      'Shown when customer gives old gold in exchange';

  static const String togDiamondCarats = 'Diamond Carats';
  static const String togDiamondCaratsSub = 'Total diamond weight in carats';

  static const String togDiamondPieces = 'Diamond Pieces';
  static const String togDiamondPiecesSub = 'Number of diamond pieces';

  static const String togClarity = 'Clarity Grade';
  static const String togClaritySub = 'VVS1, VS1, SI1 etc.';

  static const String togCertNo = 'Certification Number';
  static const String togCertNoSub = 'GIA / IGI / HRD cert no.';

  static const String togMetalWeight = 'Metal Frame Weight';
  static const String togMetalWeightSub = 'Weight of gold/silver setting';

  static const String togStoneDetails = 'Stone Details';
  static const String togStoneDetailsSub = 'Stone type, carats, pieces';

  static const String togStoneValue = 'Stone Value';
  static const String togStoneValueSub = 'Stone/diamond value as separate line';

  static const String togGstBreakup = 'GST Breakup';
  static const String togGstBreakupSub = 'Show CGST + SGST lines separately';

  static const String togHsn = 'HSN Code';
  static const String togHsnSub = 'Show HSN code on invoice';

  static const String togTotalValue = 'Total Value';
  static const String togTotalValueSub = 'Final line item total';

  static const String togSupplierDetails = 'Seller Details';
  static const String togSupplierDetailsSub = 'Name, mobile, city on voucher';

  static const String togPanNumber = 'PAN Number';
  static const String togPanNumberSub =
      'Required for transactions above ₹2 lakh';

  // ── RETURN & BUYBACK FIELD LABELS ─────────────────────────────────────────
  static const String lblReturnWindow = 'Return Window (Days)';
  static const String hintReturnWindow = 'e.g. 7';
  static const String subReturnWindow = '0 = No return allowed';

  static const String lblReturnMode = 'Return Mode';
  static const String lblHandlingCharge = 'Handling Charge %';
  static const String hintHandlingCharge = 'e.g. 0';
  static const String subHandlingCharge = 'Deducted on return';

  static const String lblBuybackRate = 'Buyback Rate %';
  static const String hintBuybackRate = 'e.g. 90';
  static const String subBuybackRate = '% of today\'s market rate';

  static const String lblPurityDeduct = 'Purity Deduction %';
  static const String hintPurityDeduct = 'e.g. 2';
  static const String subPurityDeductSales =
      'Testing/refining loss deducted during buyback';
  static const String subPurityDeductPurchase =
      'Deducted for testing/refining loss';

  // ── TERMS & TEMPLATE FIELD LABELS ─────────────────────────────────────────
  static const String lblTerms = 'Terms & Conditions';
  static const String lblFooter = 'Footer Message';
  static const String lblTemplate = 'Print Template';
  static const String hintFooter = 'e.g. Thank you for shopping with us!';
  static const String hintFooterPurchase = 'e.g. Thank you for trusting us.';
  static const String templateHelper = 'More templates can be added in future';

  // ── SAVE BUTTON ───────────────────────────────────────────────────────────
  static String saveLabel(String metalDisplay) => 'Save $metalDisplay Settings';
  static String savePurchaseLabel(String metalDisplay) =>
      'Save $metalDisplay Purchase Settings';
  static String savedSuccess(String metal) => '$metal billing settings saved!';
  static String savedPurchase(String metal) =>
      '$metal purchase settings saved!';
  static const String saveFailed = 'Save failed. Please try again.';

  // ── APPBAR SUBTITLES ──────────────────────────────────────────────────────
  static const String salesSettingsSub =
      'Invoice display · Return policy · Terms';
  static const String purchaseSettingsSub =
      'Voucher display · Seller KYC · Payout terms';
  static const String selectModuleSub = 'Select metal type to configure';

  // ── MODULE HUB INFO ───────────────────────────────────────────────────────
  static const String selectModule = 'SELECT MODULE';
  static const String configureLabel = 'Configure';

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY — Old hub card strings (kept for backward compat if used elsewhere)
  // ═══════════════════════════════════════════════════════════════════════════
  static const String cardSalesCount = '4 metals';
  static const String cardPurchaseCount = '4 metals';
  static const String cardGirviTitle = 'Girvi Billing';
  static const String cardGirviSub = 'Interest, notice & auction rules';
  static const String cardGirviCount = '4 sections';
  static const String cardReturnTitle = 'Return & Buyback';
  static const String cardReturnSub = 'Return policy & buyback rates';
  static const String cardReturnCount = '3 sections';

  // ── DROPDOWN OPTIONS ─────────────────────────────────────────────────────
  static const List<String> paymentModes = [
    'Cash',
    'UPI',
    'Card',
    'Credit',
    'Cheque',
    'Bank Transfer',
    'Mixed'
  ];
  static const List<String> purchasePayModes = [
    'Cash',
    'Bank Transfer',
    'Cheque',
    'UPI',
    'Credit'
  ];
  static const List<String> roundingRules = [
    'No Rounding',
    'Nearest ₹1',
    'Nearest ₹5',
    'Nearest ₹10'
  ];
  static const List<String> karatOptions = ['24K', '22K', '18K', '14K', '10K'];
  static const List<String> interestTypes = ['Simple', 'Compound'];
  static const List<String> girviDurations = [
    '1 Month',
    '3 Months',
    '6 Months',
    '9 Months',
    '12 Months'
  ];
  static const List<String> returnModes = ['Exchange Only', 'Refund', 'Both'];
  static const List<String> purchaseReturnModes = [
    'Exchange',
    'Credit Note',
    'Cash Refund'
  ];

  // ── DEFAULT TERMS TEXTS ──────────────────────────────────────────────────
  static const String defaultSalesTerms =
      'Items once sold will not be taken back or exchanged.\n'
      'Guarantee is provided as per BIS standards.\n'
      'Original bill is mandatory for any service claim.';

  static const String defaultSalesFooter =
      'Thank you for shopping with us! Visit us again.';

  static const String defaultPurchaseTerms =
      'Quality will be checked on delivery.\n'
      'Short delivery or defective goods must be reported within 24 hours.\n'
      'Payment as per agreed terms only.';

  static const String defaultGirviTerms =
      'Interest will be charged per month on the loan amount.\n'
      'Unclaimed ornaments after notice period will be auctioned as per law.\n'
      'Customer is responsible for timely repayment.';

  static const String defaultReturnTerms =
      'Returns accepted within the specified window with original bill only.\n'
      'Exchange is subject to stock availability.\n'
      'Buyback rate is calculated on the day\'s market rate.';
}
