// Centralized user-facing copy for the customer profile experience.

class CustomerProfileStrings {
  CustomerProfileStrings._();

  static const String appBarSubtitle = "LOTUS PRIME ERP";
  static const String appBarTitle = "CUSTOMER PROFILE";
  static const String moduleName = "PROFILE";
  static const String moduleStatus = "Customer Details";

  static const String btnNewSale = "New Sale";
  static const String btnEdit = "Edit";
  static const String btnHistory = "Transactions";
  static const String btnDelete = "Delete";

  static const String secContact = "Contact Information";
  static const String secAccountSnapshot = "Account Snapshot";
  static const String secBills = "Billing Activity";
  static const String secAdvance = "Advance Orders";
  static const String secDues = "Pending Dues";

  static const String lblMobile = "Mobile";
  static const String lblWhatsapp = "WhatsApp";
  static const String lblCity = "City";
  static const String lblSince = "Member Since";
  static const String lblType = "Type";
  static const String lblNa = "N/A";

  static const String lblDueLimit = "Approved Due Limit";
  static const String lblDueTotal = "Due Amount";
  static const String lblDueBillValue = "Pending Bill Value";
  static const String lblGirviTotal = "Total Girvi Principal";
  static const String lblGirviBalance = "Active Girvi Balance";
  static const String lblInterestBase = "Interest Principal";
  static const String lblInterestAccrued = "Accrued Interest";
  static const String lblGirviReceivable = "Current Receivable";
  static const String lblUsedPct = "Used";

  static const String statusClear = "DUE CLEAR";
  static const String statusDue = "DUE OPEN";
  static const String statusDefaulter = "LIMIT EXCEEDED";

  static const String hintDueLimit = "Enter approved due limit";
  static const String savedLimit = "Due limit updated successfully.";

  static const String paid = "SETTLED";
  static const String unpaid = "UNPAID";
  static const String active = "ACTIVE";
  static const String noBills = "No billing activity yet";
  static const String noBillsSub =
      "Sales invoices will appear here after the first sale.";

  static const String noAdvance = "No advance orders";
  static const String noAdvanceSub =
      "Advance bookings will appear here once created.";
  static const String advancePending = "PENDING";
  static const String advanceReady = "READY";
  static const String advanceDelivered = "DELIVERED";
  static const String advanceCancelled = "CANCELLED";
  static const String convertToSale = "Convert to Sale";
  static const String totalAdvancePaid = "Advance Paid";
  static const String remainingBalance = "Remaining";

  static const String noDues = "No pending dues";
  static const String noDuesSub = "All payable bills are currently settled.";
  static const String dueCleared = "Mark as Cleared";
  static const String totalDue = "Total Due";
  static const String dueBillCount = "Unpaid Bills";

  static const String deleteTitle = "Delete Customer?";
  static const String deleteMsg =
      "This will permanently delete this customer and all their data. This cannot be undone.";
  static const String deleteConfirm = "Delete";
  static const String deleteCancel = "Cancel";
  static const String deleteSuccess = "Customer deleted successfully.";
  static const String deleteError = "Failed to delete customer.";

  static const String editTitle = "Edit Customer";
  static const String editSave = "Save Changes";
  static const String editCancel = "Cancel";
  static const String editSuccess = "Customer updated successfully.";
  static const String editFail = "Failed to save. Please try again.";

  static const String editComingSoon = "Customer editing is not available yet.";
}
