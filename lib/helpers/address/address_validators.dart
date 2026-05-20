// -----------------------------------------------------------------------------
// FILE: address_validators.dart
// TYPE: Utility / Helper (Validation Logic)
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized, robust validation logic for geographical data.
// -----------------------------------------------------------------------------

class AddressValidators {
  // Pre-compiled regex for strict 6-digit Indian Pincode validation
  static final RegExp _pinCodeRegex = RegExp(r'^[0-9]{6}$');

  // Regex to ensure City/State only contains alphabets and spaces (no numbers or special chars)
  static final RegExp _alphaSpaceRegex = RegExp(r'^[a-zA-Z\s]+$');

  // --- GENERIC VALIDATOR ---
  static String? requiredField(String? val, String fieldName,
      {int? minLength, int? maxLength}) {
    if (val == null || val.trim().isEmpty) {
      return '$fieldName is required';
    }

    final trimmed = val.trim();

    if (minLength != null && trimmed.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (maxLength != null && trimmed.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }

    return null;
  }

  // --- SPECIFIC VALIDATORS ---
  static String? pinCode(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Pincode is required';
    }
    if (!_pinCodeRegex.hasMatch(val.trim())) {
      return 'Invalid Pincode (Must be exactly 6 digits)';
    }
    return null;
  }

  static String? cityOrState(String? val, String fieldName) {
    // First check if it's empty and within valid length bounds
    final requiredCheck =
        requiredField(val, fieldName, minLength: 2, maxLength: 50);
    if (requiredCheck != null) return requiredCheck;

    // Then strictly check for valid alphabetic characters
    if (!_alphaSpaceRegex.hasMatch(val!.trim())) {
      return '$fieldName can only contain alphabets and spaces';
    }

    return null;
  }
}
