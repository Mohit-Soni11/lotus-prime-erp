// -----------------------------------------------------------------------------
// FILE: tax_gst_validators.dart
// TYPE: Core / Foundation / Security
// AUTHOR: Senior System Architect
// DESCRIPTION: Business-friendly validators for GSTIN, BIS License, and dates.
//              Keeps required data present without blocking future formats.
// -----------------------------------------------------------------------------

class TaxGstValidators {
  // Private constructor to prevent instantiation. All methods are static.
  TaxGstValidators._();

  /// Validates GSTIN presence without locking the app to one government format.
  static String? validateGstin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "GSTIN cannot be empty";
    }

    return null;
  }

  /// Validates Legal Trade Name
  static String? validateLegalName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Legal Trade Name is required";
    }
    if (value.trim().length < 3) {
      return "Name must be at least 3 characters long";
    }
    return null;
  }

  /// Validates BIS registration number when the field is mandatory.
  static String? validateBisLicense(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "BIS registration number is required";
    }

    return validateOptionalBisLicense(value);
  }

  /// Validates BIS registration number only when a value is provided.
  static String? validateOptionalBisLicense(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final String cleanValue = value.trim().toUpperCase();

    if (cleanValue.length < 5) {
      return "Invalid BIS registration number";
    }
    return null;
  }

  /// General validation for mandatory date fields
  static String? validateDate(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    return null;
  }
}
