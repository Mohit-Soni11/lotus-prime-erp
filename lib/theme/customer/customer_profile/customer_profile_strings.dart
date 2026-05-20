// -----------------------------------------------------------------------------
// FILE: customer_profile_strings.dart
// MODULE: Customer → Customer Profile
// CHANGE LOG:
//   - appBarSubtitle: "ENTERPRISE POS TERMINAL" → "LOTUS PRIME ERP"
//   - Added: Advance Orders section strings
//   - Added: Dues section strings
// -----------------------------------------------------------------------------

class CustomerProfileStrings {
  CustomerProfileStrings._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const String appBarSubtitle = "LOTUS PRIME ERP"; // ✅ FIXED
  static const String appBarTitle = "CUSTOMER PROFILE";
  static const String moduleName = "PROFILE";
  static const String moduleStatus = "Customer Details";

  // ── 4 ACTION BUTTONS ──────────────────────────────────────────────────────
  static const String btnNewSale = "New Sale";
  static const String btnEdit = "Edit";
  static const String btnHistory = "Bill History";
  static const String btnDelete = "Delete";

  // ── SECTIONS ─────────────────────────────────────────────────────────────
  static const String secContact = "Contact Information";
  static const String secCredit = "Credit & Outstanding";
  static const String secBills = "Bill History";
  static const String secAdvance = "Advance Orders"; // ✅ NEW
  static const String secDues = "Dues & Pending"; // ✅ NEW

  // ── CONTACT FIELDS ────────────────────────────────────────────────────────
  static const String lblMobile = "Mobile";
  static const String lblWhatsapp = "WhatsApp";
  static const String lblCity = "City";
  static const String lblSince = "Member Since";
  static const String lblType = "Type";
  static const String lblNa = "N/A";

  // ── CREDIT LABELS ─────────────────────────────────────────────────────────
  static const String lblCreditLimit = "Credit Limit";
  static const String lblOutstanding = "Outstanding";
  static const String lblAvailable = "Available Credit";
  static const String lblUsedPct = "Used";

  // ── STATUS LABELS ────────────────────────────────────────────────────────
  static const String statusClear = "CLEAR";
  static const String statusDue = "DUE";
  static const String statusDefaulter = "DEFAULTER";

  // ── CREDIT LIMIT EDIT ────────────────────────────────────────────────────
  static const String hintCreditLimit = "Enter limit (e.g. 50000)";
  static const String savedLimit = "Credit limit updated!";

  // ── BILL HISTORY ─────────────────────────────────────────────────────────
  static const String paid = "PAID";
  static const String unpaid = "UNPAID";
  static const String active = "ACTIVE";
  static const String noBills = "No bills yet";
  static const String noBillsSub = "Bills will appear here after first sale";

  // ── ADVANCE ORDERS ───────────────────────────────────────────────────────  ✅ NEW
  static const String noAdvance = "No Advance Orders";
  static const String noAdvanceSub = "Booking/advance orders will appear here";
  static const String advancePending = "PENDING";
  static const String advanceReady = "READY";
  static const String advanceDelivered = "DELIVERED";
  static const String advanceCancelled = "CANCELLED";
  static const String convertToSale = "Convert to Sale";
  static const String totalAdvancePaid = "Advance Paid";
  static const String remainingBalance = "Remaining";

  // ── DUES SECTION ─────────────────────────────────────────────────────────  ✅ NEW
  static const String noDues = "No Dues";
  static const String noDuesSub = "All bills are cleared";
  static const String dueCleared = "Mark as Cleared";
  static const String totalDue = "Total Due Amount";
  static const String dueBillCount = "Unpaid Bills";

  // ── DELETE DIALOG ─────────────────────────────────────────────────────────
  static const String deleteTitle = "Delete Customer?";
  static const String deleteMsg =
      "This will permanently delete this customer and all their data. This cannot be undone.";
  static const String deleteConfirm = "Delete";
  static const String deleteCancel = "Cancel";
  static const String deleteSuccess = "Customer deleted successfully";
  static const String deleteError = "Failed to delete customer";

  // ── EDIT DIALOG ──────────────────────────────────────────────────────────
  static const String editTitle = "Edit Customer";
  static const String editSave = "Save Changes";
  static const String editCancel = "Cancel";
  static const String editSuccess = "Customer updated successfully!";
  static const String editFail = "Failed to save. Please try again.";

  // ── SNACKBARS ─────────────────────────────────────────────────────────────
  static const String editComingSoon = "Edit customer coming soon!";
}
