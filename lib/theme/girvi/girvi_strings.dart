// =============================================================================
// FILE        : girvi_strings.dart
// MODULE      : Girvi / Pawn
// LAYER       : Theme
// NOTE        : All four theme files combined for brevity.
//               In your project, split into separate files and update
//               girvi_theme.dart exports accordingly.
// =============================================================================

// ─── girvi_strings.dart ──────────────────────────────────────────────────────

class GirviStrings {
  GirviStrings._();

  // Module
  static const String moduleBadge = 'GIRVI';
  static const String moduleTitle = 'GIRVI MODULE';
  static const String systemOnline = 'SYSTEM ONLINE';

  // Screen titles
  static const String newGirviTitle = 'NEW GIRVI TICKET';
  static const String newGirviSub = 'Pawn loan registration';
  static const String listTitle = 'GIRVI LEDGER';
  static const String listSub = 'All pawn loans';
  static const String releaseTitle = 'GIRVI RELEASE';
  static const String releaseSub = 'Redeem & settle';
  static const String calcTitle = 'INTEREST CALCULATOR';
  static const String calcSub = 'Loan interest computation';
  static const String noticeTitle = 'NOTICE & AUCTION';
  static const String noticeSub = 'Overdue management';

  // Section headers
  static const String secCustomer = 'Customer Selection';
  static const String descCustomer = 'Choose the customer pledging items';
  static const String secItem = 'Item Details';
  static const String descItem = 'Item description and metal type';
  static const String secWeight = 'Weight Details';
  static const String descWeight = 'Gross, stone and net weight';
  static const String secValuation = 'Valuation';
  static const String descValuation = 'Market rate and item value';
  static const String secLoanTerms = 'Loan Terms';
  static const String descLoanTerms = 'Amount, interest rate and duration';
  static const String secDisbursement = 'Disbursement';
  static const String descDisbursement = 'How the loan is paid to customer';
  static const String secDates = 'Loan Dates';
  static const String descDates = 'Start date and maturity date';
  static const String secKyc = 'KYC / Compliance';
  static const String descKyc = 'ID proof for RBI compliance';
  static const String secNotes = 'Notes & Remarks';
  static const String descNotes = 'Optional internal remarks';
  static const String secRelease = 'Release Summary';
  static const String descRelease = 'Final settlement breakdown';

  // Messages
  static const String successGirviSaved = 'Girvi ticket created successfully!';
  static const String successReleased = 'Girvi released successfully!';
  static const String errorCustomerRequired = 'Please select a customer';
  static const String errorWeightZero = 'Net weight must be greater than zero';
  static const String errorAmountZero = 'Loan amount must be greater than zero';
  static const String noLoansFound = 'No girvi loans found';
  static const String selectCustomerHint = 'Tap to search and select customer';
}
