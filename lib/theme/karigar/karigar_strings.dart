// =============================================================================
// FILE        : karigar_strings.dart
// MODULE      : Karigar
// LAYER       : Theme / Strings
// DESCRIPTION : All display text constants for the Karigar module.
//               Zero hardcoded strings in UI files.
// =============================================================================

class KarigarStrings {
  KarigarStrings._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const String moduleTitle        = 'KARIGAR MODULE';
  static const String moduleBadge        = 'KARIGAR';
  static const String systemOnline       = 'SYSTEM ONLINE';

  static const String issueScreenTitle   = 'ISSUE TO KARIGAR';
  static const String issueScreenSub     = 'Metal issue transaction';

  static const String receiveScreenTitle = 'RECEIVE FROM KARIGAR';
  static const String receiveScreenSub   = 'Receipt & settlement';

  static const String pendingScreenTitle = 'PENDING JOBS';
  static const String pendingScreenSub   = 'Live job tracker';

  static const String hisaabScreenTitle  = 'KARIGAR HISAAB';
  static const String hisaabScreenSub    = 'Full ledger & accounts';

  // ── SECTION HEADERS ───────────────────────────────────────────────────────
  static const String secSelectKarigar   = 'Select Karigar';
  static const String descSelectKarigar  = 'Choose the artisan for this transaction';

  static const String secIssueDetails    = 'Issue Details';
  static const String descIssueDetails   = 'Job description and quantity';

  static const String secMetalDetails    = 'Metal Details';
  static const String descMetalDetails   = 'Metal type, purity and weight breakdown';

  static const String secDelivery        = 'Delivery Timeline';
  static const String descDelivery       = 'Issue date and expected return date';

  static const String secWastage         = 'Weight & Wastage Analysis';
  static const String descWastage        = 'Received weight vs issued weight';

  static const String secMakingCharges   = 'Making Charges';
  static const String descMakingCharges  = 'Rate type and charge computation';

  static const String secPayment         = 'Payment Settlement';
  static const String descPayment        = 'Payment status and amount paid';

  static const String secNotes           = 'Notes';
  static const String descNotes          = 'Optional remarks for this transaction';

  static const String secKarigarProfile  = 'Karigar Profile';
  static const String descKarigarProfile = 'Name, contact and specialization';

  static const String secRateConfig      = 'Rate Configuration';
  static const String descRateConfig     = 'Default making charges rate';

  static const String secFinancial       = 'Financial Settings';
  static const String descFinancial      = 'Opening balance for this karigar';

  // ── FORM FIELD LABELS ─────────────────────────────────────────────────────
  static const String lblKarigar         = 'Karigar';
  static const String lblIssueNumber     = 'Issue Number';
  static const String lblReceiptNumber   = 'Receipt Number';
  static const String lblItemDesc        = 'Item Description';
  static const String lblCategory        = 'Item Category';
  static const String lblQuantity        = 'Quantity (Pieces)';
  static const String lblMetalType       = 'Metal Type';
  static const String lblPurity          = 'Purity';
  static const String lblGrossWeight     = 'Gross Weight (g)';
  static const String lblStoneWeight     = 'Stone Weight (g)';
  static const String lblNetWeight       = 'Net Weight (g)';
  static const String lblGrossReceived   = 'Gross Received (g)';
  static const String lblNetReceived     = 'Net Received (g)';
  static const String lblWastageWeight   = 'Wastage (g)';
  static const String lblWastagePercent  = 'Wastage (%)';
  static const String lblIssueDate       = 'Issue Date';
  static const String lblExpectedReturn  = 'Expected Return Date';
  static const String lblReceiptDate     = 'Receipt Date';
  static const String lblMakingType      = 'Rate Basis';
  static const String lblMakingRate      = 'Rate Amount';
  static const String lblMakingAmount    = 'Making Charges (₹)';
  static const String lblPaymentStatus   = 'Payment Status';
  static const String lblPaidAmount      = 'Amount Paid (₹)';
  static const String lblBalanceDue      = 'Balance Due (₹)';
  static const String lblStatus          = 'Job Status';
  static const String lblNotes           = 'Notes / Remarks';
  static const String lblKarigarName     = 'Karigar Name';
  static const String lblPhone           = 'Phone Number';
  static const String lblAltPhone        = 'Alternate Phone';
  static const String lblSpecialization  = 'Specialization';
  static const String lblRateType        = 'Rate Type';
  static const String lblRateAmount      = 'Rate Amount';
  static const String lblAddress         = 'Address';
  static const String lblCity            = 'City';
  static const String lblOpeningBalance  = 'Opening Balance (₹)';

  // ── HINTS ─────────────────────────────────────────────────────────────────
  static const String hintItemDesc       = 'e.g., 22K Gold Ring for wedding order';
  static const String hintWeight         = '0.000';
  static const String hintQuantity       = '1';
  static const String hintNotes         = 'Add any remarks or special instructions...';
  static const String hintKarigarName    = 'Full name of artisan';
  static const String hintPhone          = '10-digit mobile number';
  static const String hintAltPhone       = 'Optional alternate number';
  static const String hintAddress        = 'Shop or home address';
  static const String hintCity           = 'City';
  static const String hintBalance        = '0.00';
  static const String hintRate           = '0.00';
  static const String hintAmount         = '0.00';
  static const String hintSelectIssue    = 'Select a pending issue to receive';

  // ── BUTTONS ───────────────────────────────────────────────────────────────
  static const String btnSaveIssue       = 'Save Issue';
  static const String btnSaveReceipt     = 'Save Receipt';
  static const String btnSaveKarigar     = 'Save Karigar';
  static const String btnSaving          = 'Saving...';
  static const String btnReset           = 'Reset Form';
  static const String btnAddKarigar      = 'Add New Karigar';
  static const String btnMarkInProgress  = 'Mark In Progress';
  static const String btnMarkDone        = 'Mark Completed';
  static const String btnCancel          = 'Cancel Job';
  static const String btnReceive         = 'Receive Goods';

  // ── INFO / NOTES ──────────────────────────────────────────────────────────
  static const String noteNetWeight      = 'Auto-calculated: Gross − Stone';
  static const String noteNetReceived    = 'Auto-calculated: Gross − Stone';
  static const String noteWastage        = 'Gold loss during the making process';
  static const String noteBalanceDue     = 'Auto-calculated: Charges − Paid';
  static const String noteSelectKarigar  = 'Tap to select a karigar from the list';
  static const String noteNoIssues       = 'No pending issues available to receive';
  static const String noteWastageHigh    = 'Wastage exceeds standard 2% threshold';
  static const String noteWastageCritical= 'CRITICAL: Wastage above 5% — verify weights';
  static const String noteOpeningBalance = 'Positive = we owe karigar. Negative = karigar owes us.';

  // ── EMPTY STATES ─────────────────────────────────────────────────────────
  static const String emptyJobsTitle     = 'No Pending Jobs';
  static const String emptyJobsSub       = 'All jobs are up to date or no issues recorded yet.';
  static const String emptyKarigarTitle  = 'No Karigars Found';
  static const String emptyKarigarSub    = 'Add a karigar to get started.';
  static const String emptyLedgerTitle   = 'No Transactions Yet';
  static const String emptyLedgerSub     = 'Issue gold to this karigar to start the ledger.';
  static const String emptySearchTitle   = 'No Results Found';
  static const String emptySearchSub     = 'Try a different name, phone, or issue number.';

  // ── STATUS LABELS ─────────────────────────────────────────────────────────
  static const String statusPending      = 'Pending';
  static const String statusInProgress   = 'In Progress';
  static const String statusCompleted    = 'Completed';
  static const String statusCancelled    = 'Cancelled';
  static const String statusOverdue      = 'Overdue';
  static const String paymentUnpaid      = 'Unpaid';
  static const String paymentPartial     = 'Partial';
  static const String paymentPaid        = 'Paid';

  // ── STAT CARD LABELS ─────────────────────────────────────────────────────
  static const String statActiveKarigars = 'Active Karigars';
  static const String statActiveJobs     = 'Active Jobs';
  static const String statOverdueJobs    = 'Overdue Jobs';
  static const String statWeightPending  = 'Wt. With Karigar';
  static const String statOutstanding    = 'Outstanding (₹)';
  static const String statIssuedWt       = 'Total Issued';
  static const String statReceivedWt     = 'Total Received';
  static const String statPendingWt      = 'Metal Pending';
  static const String statTotalCharges   = 'Total Charges';
  static const String statTotalPaid      = 'Total Paid';
  static const String statBalance        = 'Balance Due';
  static const String statTotalIssues    = 'Total Issues';
  static const String statCompletedJobs  = 'Completed';

  // ── SNACKBAR / TOAST ─────────────────────────────────────────────────────
  static const String successIssueSaved   = 'Issue saved successfully!';
  static const String successReceiptSaved = 'Receipt saved successfully!';
  static const String successKarigarSaved = 'Karigar added successfully!';
  static const String errorSelectKarigar  = 'Please select a karigar first.';
  static const String errorSelectIssue    = 'Please select a pending issue first.';
  static const String errorGeneral        = 'Something went wrong. Please try again.';

  // ── FILTER CHIPS ─────────────────────────────────────────────────────────
  static const String filterAll          = 'All';
  static const String filterPending      = 'Pending';
  static const String filterInProgress   = 'In Progress';
  static const String filterOverdue      = 'Overdue';

  // ── LEDGER ────────────────────────────────────────────────────────────────
  static const String ledgerIssued       = 'Gold Issued';
  static const String ledgerReceived     = 'Goods Received';
  static const String ledgerSelectPrompt = 'Select a karigar to view their hisaab';

  // ── UNIT SUFFIXES ─────────────────────────────────────────────────────────
  static const String unitGrams          = 'g';
  static const String unitRupee          = '₹';
  static const String unitPercent        = '%';
  static const String unitPieces         = 'pcs';
  static const String unitDays           = 'days';
}
