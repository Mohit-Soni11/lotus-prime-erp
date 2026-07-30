// -----------------------------------------------------------------------------
// FILE: address_strings.dart
// TYPE: Core Constants / UI Text
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized microcopy for the Address & Geo-Location module.
//              100% Hardcode-free UI layer.
// -----------------------------------------------------------------------------

class AddressStrings {
  // --- PAGE HEADERS ---
  static const String pageTitle = "Registered Office";
  static const String pageSub =
      "Manage billing premises and branch address details";
  static const String statusActive = "ADDRESS ACTIVE";

  // --- SECTION HEADERS ---
  static const String secAddress = "Registered Premises";
  static const String subLocation = "LOCATION DETAILS";
  static const String subFacility = "FACILITY CLASSIFICATION";

  // --- LABELS & HINTS ---
  static const String lblAddr1 = "Building / Shop / Premise No.";
  static const String hintAddr1 = "e.g. Unit 402, Infinity Towers";

  static const String lblAddr2 = "Street / Area / Road";
  static const String hintAddr2 = "e.g. Cyber City, Sector 21";

  static const String lblCity = "City / District";
  static const String hintCity = "Enter City";

  static const String lblState = "State / Province";
  static const String hintState = "Enter State";

  static const String lblPin = "Pincode / Zip";
  static const String hintPin = "6 Digit Code";

  static const String lblCountry = "Country";
  static const String hintCountry = "India";

  // --- FACILITY TYPES (Chips) ---
  static const String typeHeadOffice = "Head Office";
  static const String typeBranchOffice = "Branch Office";
  static const String typeWarehouse = "Warehouse";

  // --- SYSTEM MESSAGES & SNACKBARS ---
  static const String lblSaving = "Saving...";
  static const String lblLocked = "Locked";
  static const String lblSave = "Save";
}
