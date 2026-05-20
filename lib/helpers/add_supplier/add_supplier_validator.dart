class AddSupplierValidator {
  AddSupplierValidator._();

  static String? validateBusinessName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Business name is required';
    if (trimmed.length < 2) return 'Business name must be at least 2 letters';
    return null;
  }

  static String? validateBusinessNameLive(String value) {
    if (value.trim().isEmpty) return null;
    return validateBusinessName(value);
  }

  static String? validateMobile(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Mobile number is required';
    if (digits.length != 10) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  static String? validateMobileLive(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length < 10) return 'Mobile number needs 10 digits';
    if (digits.length > 10) return 'Mobile number cannot exceed 10 digits';
    return null;
  }

  static String? validateWhatsapp(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length != 10) return 'Enter a valid 10-digit WhatsApp number';
    return null;
  }

  static String? validateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
    return ok ? null : 'Enter a valid email address';
  }

  static String? validatePan(String value) {
    final trimmed = value.trim().toUpperCase();
    if (trimmed.isEmpty) return null;
    final ok = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(trimmed);
    return ok ? null : 'Enter a valid PAN, e.g. ABCDE1234F';
  }

  static String? validateGst(String value) {
    final trimmed = value.trim().toUpperCase();
    if (trimmed.isEmpty) return null;
    final ok = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
    ).hasMatch(trimmed);
    return ok ? null : 'Enter a valid 15-character GST number';
  }

  static String? validatePincode(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length != 6) return 'Pincode must be 6 digits';
    return null;
  }

  static String? validateOpeningBalance(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return 'Enter a valid amount';
    if (parsed < 0) return 'Opening balance cannot be negative';
    return null;
  }
}
