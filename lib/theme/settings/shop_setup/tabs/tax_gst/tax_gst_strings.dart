// -----------------------------------------------------------------------------
// FILE: tax_gst_strings.dart
// TYPE: Theme / Localization (Step C)
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized string resources for the Tax & GST module.
//              Eliminates all hardcoded text from UI and Logic layers.
// -----------------------------------------------------------------------------

class TaxGstStrings {
  TaxGstStrings._();

  // --- Page Headers ---
  static const String pageTitle = "Statutory & Tax Compliance";
  static const String pageSubtitle =
      "Manage GSTIN and BIS hallmarking registration";
  static const String badgeComplianceActive = "COMPLIANCE ACTIVE";

  // --- Section Titles & Labels ---
  static const String secGstTitle = "GST Registration";
  static const String secGstLabel = "REGISTRATION DATA";

  static const String secBisTitle = "Bureau of Indian Standards";
  static const String secBisLabel = "JEWELLER HALLMARKING REGISTRATION";

  // --- Input Labels & Hints ---
  static const String lblGstin = "GSTIN Number";
  static const String hintGstin = "22AAAAA0000A1Z5";

  static const String lblLegalName = "Legal Trade Name";
  static const String hintLegalName = "As per GST Certificate";

  static const String lblRegDate = "Registration Date";
  static const String hintDate = "Select Date";

  static const String lblTaxpayerType = "Taxpayer Type";

  static const String lblBisLic = "BIS Registration No.";
  static const String hintBisLic = "Enter BIS registration number";

  // --- Documents & Uploads ---
  static const String docGstTitle = "GST Certificate";
  static const String docGstSub = "Upload Form GST REG-06";

  static const String docBisTitle = "BIS Registration Certificate";
  static const String docBisSub = "Upload jeweller hallmarking registration";

  static const String docEmpty = "No Document Uploaded";
  static const String btnUploadDoc = "Upload Document";
  static const String btnManageDoc = "Manage Document";

  static const String optUploadNew = "Upload New";
  static const String optPreview = "Preview Document";
  static const String optRemove = "Remove";

  // --- Buttons & States ---
  static const String btnSave = "Save";
  static const String btnSaving = "Saving...";
  static const String btnLocked = "Locked";
  static const String btnEdit = "Edit";

  static const String btnConfirm = "CONFIRM";
  static const String btnCancel = "CANCEL";

  // --- Dialogs & Feedback messages ---
  static const String dlgSelectDate = "SELECT DATE";
  static const String dlgCropDoc = "Crop Document";
  static const String dlgSecureCrop = "Secure Document Crop";
  static const String dlgDocOptions = "Document Options";
  static const String feedbackTaxSyncDone = "Tax Sync Done";

  // --- Error & Validation Messages ---
  static const String errGstinEmpty = "GSTIN cannot be empty";
  static const String errGstinInvalid =
      "Invalid GSTIN format. Please check again.";
  static const String errLegalNameEmpty = "Legal Trade Name is required";
  static const String errLegalNameShort =
      "Name must be at least 3 characters long";
  static const String errBisEmpty = "BIS registration number is required";
  static const String errBisInvalid = "Invalid BIS registration number";
  static const String errFileTooLarge = "File too large. Max 10MB.";
}
