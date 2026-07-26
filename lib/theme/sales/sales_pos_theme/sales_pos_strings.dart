// ==========================================
// FILE: sales_pos_strings.dart
// TYPE: Theme Core
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized string constants for UI text and future localization.
// ==========================================

class SalesPosStrings {
  SalesPosStrings._(); // Prevent instantiation

  // --- SYSTEM & SHELL ---
  static const String systemOnline = "SYSTEM ONLINE";
  static const String defaultShopName = "Lotus Jewellers";
  static const String defaultCity = "Patna";

  // --- LOGIN BADGE ---
  static const String menuProfile = "My Profile";
  static const String menuLogout = "Logout";

  // --- TOP CONTROL BAR ---
  static const String modeRetail = "RETAIL";
  static const String modeWholesale = "WHOLESALE";
  static const String lblBillType = "Bill Type:";
  static const String typeNormal = "NORMAL";
  static const String typeGst = "GST";

  // --- INVOICE STRIP ---
  static const String lblInvoiceNo = "INVOICE NO : ";

  // --- CUSTOMER SECTION ---
  static const String lblMobile = "Mobile Number";
  static const String hintMobile = "10-digit number";
  static const String badgeNewCustomer = "New Customer (Auto-Create)";
  static const String lblCustomerName = "Customer Name";
  static const String hintCustomerName = "Full Name";
  static const String lblCity = "City / Area";
  static const String hintCity = "Address";
  static const String lblPanAadhar = "PAN / Aadhar";
  static const String hintPanAadhar = ">2L required";
  static const String btnSearch = "Search";
  static const String btnNewCustomer = "New Customer";

  // --- ITEMS TABLE ---
  static const String headerNewItems = "NEW ITEMS (SALE)   [+ Click to Add]";
  static const String btnAddNewItem = "Add New Item (F2)";
  static const String emptyItemsMsg =
      "Press F2 or click 'Add New Item' to start billing.";

  // --- TRADE-IN TABLE ---
  static const String headerTradeIn = "METAL TRADE-IN (-)";
  static const String msgNoTradeIn = "No trade-in items added.";
  static const String btnAddTradeIn = "Add Trade-In";
  static const String toggleCashAdjust = "Cash Adjust";
  static const String toggleMetalAdjust = "Metal Adjust";

  // --- PAYMENT HUB & SUMMARY ---
  static const String headerBillSummary = "BILL SUMMARY";
  static const String lblGoldNetWt = "Total Gold Net Wt.";
  static const String lblSilverNetWt = "Total Silver Net Wt.";
  static const String lblGrossAmt = "Gross Amount";
  static const String lblLessTradeIn = "Less: Trade-In";
  static const String lblLessDiscount = "Less: Discount ";
  static const String lblTaxableAmt = "Taxable Amount";
  static const String headerPaymentMode = "PAYMENT MODE";
  static const String lblCash = "Cash Amount";
  static const String lblUpi = "UPI / Bank";
  static const String lblCard = "Card Payment";
  static const String lblAdvance = "Advance Used";
  static const String lblRefund = "REFUND TO CUSTOMER";
  static const String lblBalanceDue = "BALANCE DUE";
  static const String lblPromiseDate = "Promise Date:";
  static const String btnSelectDate = "Select Date";
  static const String lblGrandTotal = "GRAND TOTAL";

  // --- ACTION BUTTONS ---
  static const String btnHold = "HOLD";
  static const String btnSavePrint = "SAVE & PRINT";
}
