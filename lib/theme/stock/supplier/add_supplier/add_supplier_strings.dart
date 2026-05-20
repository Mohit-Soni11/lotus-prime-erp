// -----------------------------------------------------------------------------
// FILE: add_supplier_strings.dart
// MODULE: Supplier > Add Supplier
// -----------------------------------------------------------------------------

class AddSupplierStrings {
  AddSupplierStrings._();

  static const String appBarTitleAdd = 'ADD NEW SUPPLIER';
  static const String appBarTitleEdit = 'EDIT SUPPLIER';
  static const String appBarSubtitle = 'LOTUS PRIME ERP';
  static const String systemOnline = 'SYSTEM ONLINE';

  static const String secIdentity = 'Supplier Identity';
  static const String secIdentitySub = 'Profile preview and account type';
  static const String secBasic = 'Business Information';
  static const String secBasicSub = 'Business name, contact person and type';
  static const String secContact = 'Contact Details';
  static const String secContactSub =
      'Mobile, WhatsApp, email and backup phone';
  static const String secKyc = 'KYC & Compliance';
  static const String secKycSub = 'GST and PAN details';
  static const String secAddress = 'Address';
  static const String secAddressSub = 'Business billing and delivery address';
  static const String secFinance = 'Financial Details';
  static const String secFinanceSub = 'Opening balance and internal notes';

  static const String lblBusinessName = 'Business / Company Name';
  static const String lblContactPerson = 'Contact Person Name';
  static const String lblSupplierType = 'Supplier Type';
  static const String lblMobile = 'Mobile Number';
  static const String lblWhatsapp = 'WhatsApp Number';
  static const String lblEmail = 'Email Address';
  static const String lblAltContact = 'Alternate Contact';
  static const String lblPan = 'PAN Number';
  static const String lblGst = 'GST Number';
  static const String lblAddress1 = 'Address Line 1';
  static const String lblAddress2 = 'Address Line 2';
  static const String lblState = 'State';
  static const String lblCountry = 'Country';
  static const String lblPincode = 'Pincode';
  static const String lblOpeningBal = 'Opening Balance (Rs)';
  static const String lblNotes = 'Notes / Remarks';

  static const String hintBusinessName = 'e.g. Zaveri Traders Pvt Ltd';
  static const String hintContactPerson = 'Contact person name';
  static const String hintMobile = '10-digit mobile number';
  static const String hintWhatsapp = 'Same as mobile (optional)';
  static const String hintEmail = 'business@email.com';
  static const String hintAltContact = 'Alternate number';
  static const String hintPan = '10-char PAN e.g. ABCDE1234F';
  static const String hintGst = '15-char GST e.g. 22AAAAA0000A1Z5';
  static const String hintAddress1 = 'Shop no, building, street';
  static const String hintAddress2 = 'Area, landmark';
  static const String hintState = 'State name';
  static const String hintCountry = 'Country';
  static const String hintPincode = '6-digit pincode';
  static const String hintOpeningBal = '0.00';
  static const String hintNotes = 'Any remarks about this supplier...';

  static const String btnSaveAdd = 'Save Supplier';
  static const String btnSaveEdit = 'Update Supplier';
  static const String btnSaving = 'Saving...';
  static const String btnClear = 'Clear Form';
  static const String requiredNote =
      'Business name and mobile number are required.';

  static const String errNameEmpty = 'Business name is required';
  static const String errNameShort = 'Name must be at least 2 characters';
  static const String errMobileEmpty = 'Mobile number is required';
  static const String errMobileLen = 'Enter a valid 10-digit mobile number';
  static const String errMobileDup = 'This mobile number is already registered';
  static const String errGstLen = 'GST number must be 15 characters';
  static const String errPanLen = 'PAN must be 10 characters';
  static const String errSaveFailed = 'Could not save. Please try again.';
}
