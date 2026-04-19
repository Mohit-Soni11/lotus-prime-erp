// -----------------------------------------------------------------------------
// FILE: basic_info_strings.dart
// TYPE: Core Constants / UI Text
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized microcopy, labels, and system messages for the 
//              Basic Info module. 100% Extracted from Logic for i18n support.
// -----------------------------------------------------------------------------

class BasicInfoStrings {
  // --- PAGE HEADERS ---
  static const String pageTitle = "Business Profile & Statutory Details";
  static const String pageSub = "Configure your enterprise identity and operational parameters";
  static const String statusActive = "PROFILE ACTIVE";
  
  // --- SECTION HEADERS ---
  static const String secEnterprise = "Enterprise Registration";
  static const String subEnterprise = "LEGAL & STATUTORY DETAILS";
  static const String subProprietor = "PROPRIETORSHIP / DIRECTORATE";
  static const String subMeta = "ESTABLISHMENT METADATA";
  
  static const String secOperations = "Operational Parameters";
  static const String subHours = "BUSINESS HOURS & AVAILABILITY";
  
  static const String secCommunication = "Support & Communication";
  static const String subTouchpoints = "CUSTOMER TOUCHPOINTS";

  // --- LABELS & HINTS ---
  static const String lblLegalName = "Registered Legal Entity Name";
  static const String hintLegalName = "Enter Registered Name (Optional)";
  
  static const String lblDisplayName = "Trade / Display Name";
  static const String hintDisplayName = "Enter Shop Name";
  
  static const String lblTagline = "Brand Slogan / Motto";
  static const String hintTagline = "Enter Slogan (Optional)";
  
  static const String lblOwner = "Authorized Proprietor/Director";
  static const String hintOwner = "Enter Full Name";
  
  static const String lblPhone = "Registered Mobile";
  static const String hintPhone = "10 Digit Mobile No.";
  
  static const String lblWhatsapp = "Official WhatsApp";
  static const String hintWhatsapp = "WhatsApp No.";
  
  static const String lblEstYear = "Incorporation Year";
  static const String hintEstYear = "YYYY";
  
  static const String lblBranch = "Store Unit ID (Branch Code)";
  static const String hintBranch = "Enter Branch ID";

  static const String lblOpenTime = "Opens At";  
  static const String lblCloseTime = "Closes At"; 
  static const String lblHoliday = "Weekly Statutory Holiday";
  
  static const String lblBrandDisplay = "Support Display Name";
  static const String hintBrandDisplay = "Enter Team Name";
  
  static const String lblEmail = "Official Correspondence Email";
  static const String hintEmail = "email@domain.com";
  
  static const String lblHelpPhone = "Helpdesk Mobile";
  static const String lblBizWhatsapp = "Business WhatsApp";

  // --- VISUALS ---
  static const String titleIdentity = "Corporate Identity";
  static const String subIdentity = "Upload Official Brand Logo";
  static const String titleSignature = "Authorized Signatory";
  static const String subSignature = "Digital Signature for Invoicing";
  
  // --- SYSTEM & ERROR MESSAGES ---
  static const String msgSaved = "Section Locked Successfully"; 
  static const String msgFixErrors = "Please fix the highlighted errors before proceeding.";
  static const String errFileTooLarge = "File too large. Maximum size is 5MB.";
  static const String errInvalidFormat = "Invalid format. Please use JPG or PNG.";

  // --- EXTRACTED FROM LOGIC (DEFAULTS & ERROR KEYS) ---
  static const String valDefaultHoliday = "Sunday";
  static const String valDefaultBranch = "HQ-001";
  static const List<String> weekDaysList = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "None"];
  
  // Field Keys for Validation Tracking
  static const String keyDisplayName = "displayName";
  static const String keyOwnerName = "ownerName";
  static const String keyOwnerPhone = "ownerPhone";
  static const String keyOwnerWa = "ownerWa";
  static const String keyOpenTime = "openTime";
  static const String keyCloseTime = "closeTime";
  static const String keyEmail = "email";
  static const String keyShopPhone = "shopPhone";
  static const String keyShopWa = "shopWa";

  // --- PHOTO WIDGET & UI STRINGS ---
  static const String photoOptTitle = "Profile Photo Options";
  static const String photoOptUpload = "Upload New Photo";
  static const String photoOptPreview = "Preview Photo";
  static const String photoOptRemove = "Remove Photo";
  static const String photoAdjustTitle = "Adjust Photo";
  static const String photoFinalizeTitle = "Finalize Look";
  static const String photoShapeLabel = "Display Shape";
  static const String photoShapeCircle = "Circle";
  static const String photoShapeSquare = "Square";
  static const String btnCancel = "Cancel";
  static const String btnRecrop = "Recrop";
  static const String btnSavePhoto = "Save Photo";
  static const String btnManagePhoto = "Manage Photo";
  static const String btnUploadPhoto = "Upload Photo";
  static const String lblNoPhoto = "No Photo";
  static const String lblLocked = "Locked";
  static const String lblEdit = "Edit";
}