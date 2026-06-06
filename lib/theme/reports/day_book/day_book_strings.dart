// =============================================================================
// FILE        : day_book_strings.dart
// MODULE      : Reports & Analytics → Day Book
// LAYER       : Theme / Strings
// DESCRIPTION : All UI text strings — centralized for easy localization.
// =============================================================================

class DayBookStrings {
  DayBookStrings._();

  // ── AppBar ────────────────────────────────────────────────────────────────
  static const String appBarTitle = 'DAY BOOK';
  static const String systemOnline = 'System Online';
  static const String moduleSubtitle = 'Daily Financial Ledger';

  // ── Date Navigation ───────────────────────────────────────────────────────
  static const String todayLabel = 'Today';
  static const String yesterday = 'Yesterday';

  // ── Opening Balance ───────────────────────────────────────────────────────
  static const String openingBal = 'OPENING BALANCE';
  static const String openingCash = 'Opening Cash';
  static const String openingGold = 'Opening Gold';
  static const String openingSilver = 'Opening Silver';
  static const String carryForward = 'Carried forward from previous day';

  // ── Anomaly Alert ─────────────────────────────────────────────────────────
  static const String anomalyTitle = 'Unusual Activity Detected';
  static const String anomalyDismiss = 'Dismiss';

  // ── Section: Cash Inward ─────────────────────────────────────────────────
  static const String cashInTitle = 'CASH INWARD';
  static const String cashInSubtitle = 'Total money received today';
  static const String retailSales = 'Direct Retail Sales';
  static const String retailSalesSub = 'Counter sales — Cash / UPI / Card';
  static const String dueReceipts = 'Due Receipts';
  static const String dueReceiptsSub = 'Recovered pending bill payments';
  static const String bookingAdv = 'Booking Advances';
  static const String bookingAdvSub = 'Custom order advance deposits';
  static const String vendorRefund = 'Vendor Refunds';
  static const String vendorRefundSub = 'Purchase return — supplier refund';
  static const String girviReceipt = 'Girvi Receipts';
  static const String girviReceiptSub =
      'Mortgage release — principal + interest';

  // ── Section: GST & Non-GST Bills (inside Cash In) ────────────────────────
  static const String gstBillSection = 'GST INVOICES';
  static const String gstBillSubtitle = 'Tax invoices — 3% GST collected';
  static const String nonGstBillSection = 'NORMAL BILLS';
  static const String nonGstBillSubtitle = 'Non-GST sales — no tax collected';
  static const String gstCollectedLbl = 'GST Collected';
  static const String cgstLbl = 'CGST (1.5%)';
  static const String sgstLbl = 'SGST (1.5%)';
  static const String taxableLbl = 'Taxable Amount';
  static const String billCountLbl = 'Bills';

  // ── Section: Cash Outward ─────────────────────────────────────────────────
  static const String cashOutTitle = 'CASH OUTWARD';
  static const String cashOutSubtitle = 'Total money paid out today';
  static const String expenses = 'Operational Expenses';
  static const String expensesSub = 'Admin, staff, utility, marketing';
  static const String girviGiven = 'Girvi Disbursements';
  static const String girviGivenSub = 'Cash loans against mortgage security';
  static const String karigarPay = 'Karigar Settlements';
  static const String karigarPaySub = 'Labour charges and cash advances';
  static const String vendorPay = 'Vendor Payments';
  static const String vendorPaySub = 'Stock purchase — supplier payments';
  static const String salesReturn = 'Customer Refunds';
  static const String salesReturnSub = 'Sales return — refund to customer';

  // ── Section: Payment Mode Breakup ─────────────────────────────────────────
  static const String paymentMode = 'PAYMENT MODE BREAKUP';
  static const String paymentModeSub = 'How money was received today';
  static const String cashMode = 'Physical Cash';
  static const String upiMode = 'UPI';
  static const String cardMode = 'Card';
  static const String bankMode = 'Bank Transfer';

  // ── Section: Metal Inward ─────────────────────────────────────────────────
  static const String metalInTitle = 'METAL INWARD';
  static const String metalInSubtitle = 'Gold & Silver added to vault today';
  static const String urdPurchase = 'URD / Old Gold Purchase';
  static const String urdPurchaseSub = 'Customer scrap / old jewellery bought';
  static const String karigarFinish = 'Karigar Finished Goods';
  static const String karigarFinishSub =
      'Ready jewellery received from artisan';
  static const String girviSecurity = 'Mortgage Security Deposit';
  static const String girviSecuritySub = 'Gold pledged by customer for girvi';
  static const String returnAsset = 'Sales Return Asset Reversal';
  static const String returnAssetSub = 'Sold item returned — back to vault';

  // ── Section: Metal Outward ────────────────────────────────────────────────
  static const String metalOutTitle = 'METAL OUTWARD';
  static const String metalOutSubtitle = 'Gold & Silver leaving vault today';
  static const String retailDispatch = 'Retail Asset Dispatch';
  static const String retailDispatchSub =
      'Jewellery sold — delivered to customer';
  static const String karigarIssue = 'Karigar Raw Material Issue';
  static const String karigarIssueSub = 'Raw gold issued to artisan for making';
  static const String vendorReturn = 'Defective Vendor Returns';
  static const String vendorReturnSub = 'Dead / defective stock sent back';

  // ── Summary Row Labels ────────────────────────────────────────────────────
  static const String goldGrams = 'Gold';
  static const String silverGrams = 'Silver';
  static const String gramsUnit = 'gms';
  static const String rupeeUnit = '₹';

  // ── Net Flow ─────────────────────────────────────────────────────────────
  static const String netCashFlow = 'NET CASH FLOW';
  static const String netGoldFlow = 'Net Gold';
  static const String netSilverFlow = 'Net Silver';
  static const String closingCash = 'Closing Cash Balance';
  static const String closingGold = 'Closing Gold (gms)';
  static const String closingSilver = 'Closing Silver (gms)';

  // ── Predictive Card ───────────────────────────────────────────────────────
  static const String predictTitle = 'PREDICTED CLOSING';
  static const String predictSub = 'At current pace by end of day';
  static const String vsYesterday = 'vs Yesterday';
  static const String vsLastWeek = 'vs Last Week';

  // ── EOD Settlement ────────────────────────────────────────────────────────
  static const String eodTitle = 'END OF DAY SETTLEMENT';
  static const String eodSubtitle = 'Physical cash count — denomination wise';
  static const String eodSystemAmt = 'System Amount';
  static const String eodPhysAmt = 'Physical Count';
  static const String eodDiff = 'Difference';
  static const String eodMatched = 'Cash Matched ✓';
  static const String eodMismatch = 'Cash Mismatch!';
  static const String closeDay = 'CLOSE DAY & LOCK LEDGER';
  static const String dayLocked = 'Day Locked';
  static const String note2000 = '₹2000';
  static const String note500 = '₹500';
  static const String note200 = '₹200';
  static const String note100 = '₹100';
  static const String note50 = '₹50';
  static const String note20 = '₹20';
  static const String note10 = '₹10';
  static const String coins = 'Coins';

  // ── Export ────────────────────────────────────────────────────────────────
  static const String exportPdf = 'Export PDF';
  static const String exportExcel = 'Export Excel';
  static const String shareWa = 'WhatsApp';
  static const String exportSuccess = 'Day Book exported successfully';
}
