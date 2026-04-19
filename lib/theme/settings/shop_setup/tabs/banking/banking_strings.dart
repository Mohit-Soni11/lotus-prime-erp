// -----------------------------------------------------------------------------
// FILE: banking_strings.dart
// TYPE: Theme / Localization 
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized string constants for the Banking module to ensure
//              zero hardcoded text in the UI and enable future localization.
// -----------------------------------------------------------------------------

class BankingStrings {
  // --- Headers & Status ---
  static const String pageTitle = "Financial & Banking Repository";
  static const String pageSubtitle = "Manage corporate accounts, UPI, and digital receivables";
  static const String statusActive = "FINANCIALS ACTIVE";
  
  // --- Buttons & Actions ---
  static const String btnAddAccount = "Add Another Bank Account";
  static const String btnSave = "Save";
  static const String btnSaving = "Saving...";
  static const String btnLocked = "Locked";
  
  // 🚀 UPGRADE: Extracted hardcoded copy labels
  static const String msgCopied = "Copied to Clipboard!";
  static const String copyTypeAccount = "Account Number";

  // --- Messages & Errors (🚀 UPGRADE: Newly Injected) ---
  static const String errFileSize = "File size must be under 10MB";

  // --- Section Titles ---
  static const String secBankingCreds = "BANKING CREDENTIALS";
  static const String secDigitalReceivables = "DIGITAL RECEIVABLES";

  // --- Input Labels & Hints ---
  static const String lblHolderName = "Account Holder Name";
  static const String hintHolderName = "e.g. My Shop Pvt Ltd";
  
  static const String lblBankName = "Bank Name";
  static const String hintBankName = "e.g. HDFC";
  
  static const String lblAccountType = "Account Type";
  
  static const String lblAccountNumber = "Account Number";
  static const String hintAccountNumber = "Enter Secure Account No.";
  
  static const String lblIfsc = "IFSC Code";
  static const String hintIfsc = "HDFC0001234";
  
  static const String lblBranch = "Branch Location";
  static const String hintBranch = "City/Area";
  
  static const String lblUpi = "UPI ID / VPA";
  static const String hintUpi = "e.g. shop@okicici";

  // --- QR Section & Dialogs ---
  static const String qrTitle = "Payment QR Code";
  static const String qrSubtitle = "Upload UPI / Merchant QR";
  static const String qrUpload = "Upload QR";
  static const String qrOptionsTitle = "QR Code Options";
  static const String qrUploadNew = "Upload New QR";
  static const String qrRemove = "Remove QR";
  static const String qrCropTitle = "Crop QR Code";

  // --- Default Values & Fallbacks ---
  static const String defaultAccountTitle = "New Bank Account";
  static const String noAccountDetails = "No Account Details";
}