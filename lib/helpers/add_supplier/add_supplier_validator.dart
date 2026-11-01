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
    final mobile = value.trim();
    if (mobile.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? validateMobileLive(String value) {
    if (value.isEmpty) return null;
    if (!RegExp(r'^[0-9]*$').hasMatch(value)) return 'Only digits allowed';
    if (value.length > 10) return 'Mobile number cannot exceed 10 digits';
    if (value.length == 10) return validateMobile(value);
    return null;
  }

  static String? validateWhatsapp(String value) {
    if (value.trim().isEmpty) return null;
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value.trim())) {
      return 'Enter a valid 10-digit WhatsApp number';
    }
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
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(trimmed)) {
      return 'Enter a valid 6-digit pincode';
    }
    return null;
  }

  static String? validatePostalCode(String value, {required String country}) {
    if (country == 'India') return validatePincode(value);
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return RegExp(r'^[A-Za-z0-9][A-Za-z0-9 -]{1,10}[A-Za-z0-9]$')
            .hasMatch(trimmed)
        ? null
        : 'Enter a valid postal code';
  }
}
