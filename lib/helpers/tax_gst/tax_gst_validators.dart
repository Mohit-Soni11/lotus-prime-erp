// -----------------------------------------------------------------------------
// FILE: tax_gst_validators.dart
// TYPE: Core / Foundation / Security
// AUTHOR: Senior System Architect
// DESCRIPTION: Bulletproof regex validators for GSTIN, BIS License, and dates.
//              Ensures dirty data never reaches the business logic or API.
// -----------------------------------------------------------------------------

class TaxGstValidators {
  // Private constructor to prevent instantiation. All methods are static.
  TaxGstValidators._();

  /// Validates Indian GSTIN (15 characters)
  /// Format: 2 digits + 5 letters + 4 digits + 1 letter + 1 alphanumeric + Z + 1 alphanumeric
  static String? validateGstin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "GSTIN cannot be empty";
    }

    final String cleanValue = value.trim().toUpperCase();

    // Strict production-grade regex for Indian GSTIN
    final RegExp gstRegex =
        RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');

    if (!gstRegex.hasMatch(cleanValue)) {
      return "Invalid GSTIN format. Please check again.";
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

  /// Validates BIS License format (e.g., HM/C-XXXXXXXX)
  static String? validateBisLicense(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "BIS License number is required";
    }

    return validateOptionalBisLicense(value);
  }

  /// Validates BIS license only when a value is provided.
  static String? validateOptionalBisLicense(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final String cleanValue = value.trim().toUpperCase();

    if (cleanValue.length < 5) {
      return "Invalid BIS License format";
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
