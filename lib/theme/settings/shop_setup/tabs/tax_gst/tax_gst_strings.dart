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
      "Manage GSTIN, BIS License, and Tax Structure";
  static const String badgeComplianceActive = "COMPLIANCE ACTIVE";

  // --- Section Titles & Labels ---
  static const String secGstTitle = "GST Registration";
  static const String secGstLabel = "REGISTRATION DATA";

  static const String secBisTitle = "Bureau of Indian Standards";
  static const String secBisLabel = "LICENSE PARAMETERS";

  static const String secHsnTitle = "Applicable GST Structure";
  static const String secHsnSubtitle =
      "Current applicable GST rates (Snapshot)";

  // --- Input Labels & Hints ---
  static const String lblGstin = "GSTIN Number";
  static const String hintGstin = "22AAAAA0000A1Z5";

  static const String lblLegalName = "Legal Trade Name";
  static const String hintLegalName = "As per GST Certificate";

  static const String lblRegDate = "Registration Date";
  static const String hintDate = "Select Date";

  static const String lblTaxpayerType = "Taxpayer Type";

  static const String lblBisLic = "BIS License No. (HM/C)";
  static const String hintBisLic = "HM/C-XXXXXXXX";

  static const String lblValidFrom = "Valid From";
  static const String lblValidUpto = "Valid Upto";

  // --- Documents & Uploads ---
  static const String docGstTitle = "GST Certificate";
  static const String docGstSub = "Upload Form GST REG-06";

  static const String docBisTitle = "BIS License Copy";
  static const String docBisSub = "Upload Hallmarking Grant (HM/C)";

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
  static const String btnSyncing = "SYNCING";
  static const String btnLiveSync = "LIVE SYNC";
  static const String btnEditing = "EDITING";
  static const String btnFetchLatest = "Fetch Latest";
  static const String btnMarkVerified = "Mark Verified";

  static const String btnConfirm = "CONFIRM";
  static const String btnCancel = "CANCEL";

  // --- Dialogs & Snackbars ---
  static const String dlgSelectDate = "SELECT DATE";
  static const String dlgCropDoc = "Crop Document";
  static const String dlgSecureCrop = "Secure Document Crop";
  static const String dlgDocOptions = "Document Options";
  static const String snackTaxSyncDone = "Tax Sync Done";

  // --- Error & Validation Messages ---
  static const String errGstinEmpty = "GSTIN cannot be empty";
  static const String errGstinInvalid =
      "Invalid GSTIN format. Please check again.";
  static const String errLegalNameEmpty = "Legal Trade Name is required";
  static const String errLegalNameShort =
      "Name must be at least 3 characters long";
  static const String errBisEmpty = "BIS License number is required";
  static const String errBisInvalid = "Invalid BIS License format";
  static const String errFileTooLarge = "File too large. Max 10MB.";
}
