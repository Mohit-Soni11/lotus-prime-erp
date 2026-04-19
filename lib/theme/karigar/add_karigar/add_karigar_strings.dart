// =============================================================================
// FILE        : add_karigar_strings.dart
// =============================================================================

class AddKarigarStrings {
  AddKarigarStrings._();

  // AppBar
  static const String screenTitle    = 'Add New Karigar';
  static const String screenSub      = 'Artisan Profile';
  static const String moduleBadge    = 'KARIGAR MODULE';
  static const String systemOnline   = 'SYSTEM ONLINE';

  // Sections
  static const String secPhoto       = 'Profile Photo';
  static const String secIdentity    = 'Identity & Name';
  static const String secContact     = 'Contact Details';
  static const String secProfessional= 'Professional Profile';
  static const String secAddress     = 'Address';
  static const String secFinancial   = 'Financial Setup';
  static const String secNotes       = 'Notes & Status';

  static const String subPhoto       = 'Upload karigar photo';
  static const String subIdentity    = 'Full name of the artisan';
  static const String subContact     = 'Phone & alternate contact';
  static const String subProfessional= 'Specialization & making rate';
  static const String subAddress     = 'Location details';
  static const String subFinancial   = 'Opening balance & setup';
  static const String subNotes       = 'Remarks & account status';

  // Fields
  static const String lblFirstName   = 'FIRST NAME';
  static const String lblLastName    = 'LAST NAME';
  static const String lblPhone       = 'PHONE NUMBER';
  static const String lblAltPhone    = 'ALTERNATE PHONE';
  static const String lblSpecialty   = 'SPECIALIZATION';
  static const String lblRateType    = 'RATE TYPE';
  static const String lblRateAmount  = 'RATE AMOUNT';
  static const String lblAddress     = 'ADDRESS';
  static const String lblCity        = 'CITY';
  static const String lblBalance     = 'OPENING BALANCE';
  static const String lblNotes       = 'INTERNAL NOTES';
  static const String lblStatus      = 'ACCOUNT STATUS';

  static const String hintFirstName  = 'Enter first name';
  static const String hintLastName   = 'Enter last name';
  static const String hintPhone      = '10-digit mobile number';
  static const String hintAltPhone   = 'Secondary number (optional)';
  static const String hintRateAmount = '0.00';
  static const String hintAddress    = 'Street, Area, Locality';
  static const String hintCity       = 'City name';
  static const String hintBalance    = '0.00';
  static const String hintNotes      = 'Internal remarks (not visible on reports)';

  // Buttons
  static const String btnSave        = 'Save Karigar';
  static const String btnSaving      = 'Saving...';
  static const String btnClear       = 'Clear Form';

  // Messages
  static const String successMsg     = 'Karigar saved successfully!';
  static const String errorMsg       = 'Failed to save. Please try again.';
  static const String requiredNote   = '* Required fields';

  // Balance note
  static const String balanceNote    = 'Positive = we owe karigar. Negative = karigar owes us.';

  // Photo
  static const String photoUploaded  = '✓ Photo uploaded';
  static const String photoAuto      = 'Initials avatar will be used as placeholder.';
  static const String btnUploadPhoto = 'Upload Photo';
  static const String btnChangePhoto = 'Change Photo';
  static const String btnRemove      = 'Remove';

  // Status
  static const String statusActive   = 'Active';
  static const String statusInactive = 'Inactive';
  static const String statusActiveHint   = 'Karigar can be assigned new jobs';
  static const String statusInactiveHint = 'Karigar will not appear in job assignments';
}
