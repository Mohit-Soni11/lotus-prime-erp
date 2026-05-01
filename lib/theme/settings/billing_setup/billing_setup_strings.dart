// =============================================================================
// FILE        : lib/theme/settings/billing_setup/billing_setup_strings.dart
// MODULE      : Billing Setup
// LAYER       : Theme / Strings
// DESCRIPTION : All display text constants — zero hardcoded strings in UI.
//               Mirrors KarigarStrings pattern.
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
  static const String purchaseSub = 'Supplier purchase configuration';

  static const String girviTitle = 'GIRVI BILLING';
  static const String girviSub = 'Gold loan ticket configuration';

  static const String returnTitle = 'RETURN & BUYBACK';
  static const String returnSub = 'Return policy configuration';

  // ── HUB CARDS ─────────────────────────────────────────────────────────────
  static const String cardSalesTitle = 'Sales Billing';
  static const String cardSalesSub = 'Invoice, discount, UPI & terms';
  static const String cardSalesCount = '6 sections';

  static const String cardPurchaseTitle = 'Purchase Billing';
  static const String cardPurchaseSub = 'Supplier, GRN & payment rules';
  static const String cardPurchaseCount = '4 sections';

  static const String cardGirviTitle = 'Girvi Billing';
  static const String cardGirviSub = 'Interest, notice & auction rules';
  static const String cardGirviCount = '4 sections';

  static const String cardReturnTitle = 'Return & Buyback';
  static const String cardReturnSub = 'Return policy & buyback rates';
  static const String cardReturnCount = '3 sections';

  // ── SECTION HEADERS — SALES ───────────────────────────────────────────────
  static const String secInvoiceNo = 'Invoice Numbering';
  static const String subInvoiceNo = 'BILL NUMBER FORMAT & SEQUENCE';

  static const String secEstimate = 'Estimate / Quotation';
  static const String subEstimate = 'QUOTATION SETTINGS';

  static const String secPayment = 'Payment Settings';
  static const String subPayment = 'DEFAULT PAYMENT & CREDIT RULES';

  static const String secDiscount = 'Discount & Rounding';
  static const String subDiscount = 'BILL AMOUNT ADJUSTMENT RULES';

  static const String secDisplay = 'Invoice Items Display';
  static const String subDisplay = 'WHAT SHOWS ON PRINTED BILL';

  static const String secSalesTerms = 'Terms, Conditions & Footer';
  static const String subSalesTerms = 'PRINTED ON EVERY SALES INVOICE';

  // ── SECTION HEADERS — PURCHASE ────────────────────────────────────────────
  static const String secPurInvoice = 'Purchase Voucher Numbering';
  static const String subPurInvoice = 'GRN / PURCHASE BILL FORMAT';

  static const String secPurPayment = 'Supplier Payment Terms';
  static const String subPurPayment = 'CREDIT & ADVANCE DEFAULTS';

  static const String secPurItem = 'Item & Weight Rules';
  static const String subPurItem = 'QUALITY & KARAT DEFAULTS';

  static const String secPurTerms = 'Purchase Terms & Print';
  static const String subPurTerms = 'PRINTED ON PURCHASE ORDER';

  // ── SECTION HEADERS — GIRVI ───────────────────────────────────────────────
  static const String secGrvVoucher = 'Girvi Patti Numbering';
  static const String subGrvVoucher = 'LOAN TICKET FORMAT & SEQUENCE';

  static const String secGrvInterest = 'Interest Rules';
  static const String subGrvInterest = 'LOAN CHARGES & CALCULATION';

  static const String secGrvNotice = 'Reminder & Notice Period';
  static const String subGrvNotice = 'EXPIRY ALERTS & LEGAL NOTICE';

  static const String secGrvTerms = 'Girvi Terms & Print';
  static const String subGrvTerms = 'PRINTED ON GIRVI PATTI';

  // ── SECTION HEADERS — RETURN ──────────────────────────────────────────────
  static const String secRetPolicy = 'Return Policy';
  static const String subRetPolicy = 'CUSTOMER RETURN & EXCHANGE RULES';

  static const String secBuyback = 'Buyback (Old Gold Purchase)';
  static const String subBuyback = 'RATE & PURITY DEDUCTION';

  static const String secRetTerms = 'Return Terms & Conditions';
  static const String subRetTerms = 'PRINTED ON RETURN VOUCHER';

  // ── FIELD LABELS & HINTS ──────────────────────────────────────────────────
  static const String lblInvoicePrefix = 'Invoice Prefix';
  static const String hintInvoicePrefix = 'e.g.  INV-  or  LOTUS-';
  static const String lblStartingNo = 'Starting Invoice Number';
  static const String hintStartingNo = 'e.g.  1  or  501';
  static const String lblYearlyReset = 'Reset number on new financial year';
  static const String lblEstimatePrefix = 'Estimate Prefix';
  static const String hintEstimatePrefix = 'e.g.  EST-';
  static const String lblEstValidity = 'Validity (Days)';
  static const String hintEstValidity = 'e.g.  7';
  static const String lblPayMode = 'Default Payment Mode';
  static const String lblUpiId = 'UPI ID (shown on invoice)';
  static const String hintUpiId = 'e.g.  lotus@upi';
  static const String lblCreditDays = 'Default Credit Days';
  static const String hintCreditDays = 'e.g.  30';
  static const String lblMinAdvance = 'Min. Advance % for Orders';
  static const String hintMinAdvance = 'e.g.  30';
  static const String lblAllowDiscount = 'Allow staff to give discount';
  static const String lblMaxDiscount = 'Max Discount % Allowed';
  static const String hintMaxDiscount = 'e.g.  5';
  static const String lblRounding = 'Bill Total Rounding Rule';
  static const String lblShowMaking = 'Show Making Charges on Bill';
  static const String lblShowHuid = 'Show HUID / Hallmark Number';
  static const String lblShowOldGold = 'Show Old Gold Deduction Line';
  static const String lblSalesTerms = 'Terms & Conditions';
  static const String hintSalesTerms = 'Enter sales terms & conditions...';
  static const String lblFooterMsg = 'Invoice Footer Message';
  static const String hintFooterMsg = 'e.g.  Thank you for shopping with us!';

  static const String lblPurPrefix = 'Purchase Bill Prefix';
  static const String hintPurPrefix = 'e.g.  PUR-  or  GRN-';
  static const String lblPurStartNo = 'Starting Purchase Number';
  static const String hintPurStartNo = 'e.g.  1  or  101';
  static const String lblPurYearReset = 'Reset number on new financial year';
  static const String lblPurPayDays = 'Default Payment Days';
  static const String hintPurPayDays = 'e.g.  30';
  static const String lblPurAdvance = 'Default Advance % to Supplier';
  static const String hintPurAdvance = 'e.g.  20';
  static const String lblPurPayMode = 'Default Payment Mode';
  static const String lblWeightTolerance = 'Weight Tolerance %';
  static const String hintWeightTol = 'e.g.  0.5';
  static const String lblPurKarat = 'Default Karat (Purchase)';
  static const String lblPurTerms = 'Purchase Terms & Conditions';
  static const String hintPurTerms = 'Enter purchase terms...';
  static const String lblPurAutoPrint = 'Auto-print purchase order on save';

  static const String lblGrvPrefix = 'Girvi Ticket Prefix';
  static const String hintGrvPrefix = 'e.g.  GRV-  or  LOAN-';
  static const String lblGrvStartNo = 'Starting Girvi Number';
  static const String hintGrvStartNo = 'e.g.  1  or  501';
  static const String lblInterestRate = 'Default Interest Rate (% per month)';
  static const String hintInterestRate = 'e.g.  1.5';
  static const String lblInterestType = 'Interest Calculation Type';
  static const String lblGracePeriod = 'Grace Period (Days after due date)';
  static const String hintGracePeriod = 'e.g.  3';
  static const String lblGrvDuration = 'Default Loan Duration';
  static const String lblReminderDays = 'Reminder Days Before Expiry';
  static const String hintReminderDays = 'e.g.  15';
  static const String lblNoticeDays = 'Legal Notice Period (Days)';
  static const String hintNoticeDays = 'e.g.  30';
  static const String lblGrvTerms = 'Girvi Terms & Conditions';
  static const String hintGrvTerms = 'Enter girvi loan terms...';
  static const String lblGrvAutoPrint = 'Auto-print girvi patti on save';

  static const String lblRetWindow = 'Return Window (Days after purchase)';
  static const String hintRetWindow = 'e.g.  7';
  static const String lblHandlingCharge = 'Restocking / Handling Charge %';
  static const String hintHandlingCharge = 'e.g.  0  or  2';
  static const String lblReturnMode = 'Return Mode Allowed';
  static const String lblRetVoucher = 'Return Voucher Prefix';
  static const String hintRetVoucher = 'e.g.  RET-  or  CR-';
  static const String lblBuybackRate = 'Buyback Rate (% of today\'s rate)';
  static const String hintBuybackRate = 'e.g.  90';
  static const String lblPurityDeduct = 'Purity Deduction % (Melting)';
  static const String hintPurityDeduct = 'e.g.  2';
  static const String lblBuybackKarat = 'Default Buyback Karat';
  static const String lblRetTerms = 'Return & Buyback Terms';
  static const String hintRetTerms = 'Enter return/buyback terms...';

  // ── MESSAGES ─────────────────────────────────────────────────────────────
  static const String msgSaved = 'Settings saved successfully';
  static const String msgFixErrors = 'Please fix errors before saving';
  static const String msgSaving = 'Saving...';
  static const String lblLocked = 'Locked';
  static const String lblSave = 'Save';
  static const String configure = 'Configure';

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
  static const List<String> returnModes = [
    'Exchange Only',
    'Cash Refund Only',
    'Exchange or Cash Refund'
  ];

  // ── DEFAULT TERMS TEXTS ──────────────────────────────────────────────────
  static const String defaultSalesTerms =
      'Items once sold will not be taken back or exchanged.\n'
      'Guarantee is provided as per BIS standards.\n'
      'Original bill is mandatory for any service claim.';

  static const String defaultSalesFooter =
      'Thank you for shopping with us! Visit us again. 🙏';

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
