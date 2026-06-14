// -----------------------------------------------------------------------------
// FILE: add_customer_strings.dart
// MODULE: Customer → Add New Customer
// DESCRIPTION: Zero hardcoded text in UI.
// -----------------------------------------------------------------------------

class AddCustomerStrings {
  AddCustomerStrings._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const String appBarTitle = "ADD NEW CUSTOMER";
  static const String editAppBarTitle = "EDIT CUSTOMER";
  static const String appBarSubtitle = "ENTERPRISE POS TERMINAL";
  static const String systemOnline = "SYSTEM ONLINE";
  static const String moduleName = "NEW CUSTOMER";
  static const String moduleStatus = "Registration Form";

  // ── PAGE HEADER ───────────────────────────────────────────────────────────
  static const String pageTitle = "Customer Registration";
  static const String pageSubtitle =
      "Fill in the details to register a new customer";

  // ── SECTION TITLES ───────────────────────────────────────────────────────
  static const String secContact = "Contact Details";
  static const String secContactSub = "REQUIRED INFORMATION";
  static const String secLocation = "Location Details";
  static const String secLocationSub = "OPTIONAL";
  static const String secType = "Customer Type";
  static const String secTypeSub = "SELECT MEMBERSHIP";

  // ── FIELD LABELS ─────────────────────────────────────────────────────────
  static const String lblName = "Customer Name";
  static const String lblMobile = "Mobile Number";
  static const String lblWhatsapp = "WhatsApp Number";
  static const String lblCity = "City / Area";
  static const String lblNotes = "Notes (Optional)";

  // ── FIELD HINTS ──────────────────────────────────────────────────────────
  static const String hintName = "Enter full name";
  static const String hintMobile = "10-digit mobile number";
  static const String hintWhatsapp = "Same as mobile (optional)";
  static const String hintCity = "e.g. Patna, Gaya...";
  static const String hintNotes = "Any special notes...";

  // ── CUSTOMER TYPE ─────────────────────────────────────────────────────────
  static const String typeRegular = "Standard";
  static const String typeVip = "Elite";
  static const String typeRegularSub = "Everyday client profile";
  static const String typeVipSub = "Priority client account";

  // ── BUTTONS ───────────────────────────────────────────────────────────────
  static const String btnSave = "Save Customer";
  static const String btnUpdate = "Update Customer";
  static const String btnSaving = "Saving...";
  static const String btnClear = "Clear Form";
  static const String btnResetChanges = "Reset Changes";

  // ── VALIDATION MESSAGES ──────────────────────────────────────────────────
  static const String errNameEmpty = "Customer name is required";
  static const String errNameShort = "Name must be at least 2 characters";
  static const String errMobileEmpty = "Mobile number is required";
  static const String errMobileLen = "Enter a valid 10-digit mobile number";
  static const String errMobileDup = "This mobile number is already registered";
  static const String errMobileInvalid =
      "Mobile number must contain only digits";

  // ── SNACKBARS ─────────────────────────────────────────────────────────────
  static const String successMsg = "Customer saved successfully!";
  static const String updateSuccessMsg = "Customer updated successfully!";
  static const String errorMsg = "Failed to save. Please try again.";
  static const String duplicateMsg = "Mobile number already exists!";

  // ── REQUIRED LABEL ───────────────────────────────────────────────────────
  static const String requiredNote = "* Required fields";
  static const String editRequiredNote =
      "* Existing customer details loaded for editing";
}
