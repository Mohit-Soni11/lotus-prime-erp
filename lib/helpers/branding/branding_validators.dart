// -----------------------------------------------------------------------------
// FILE: branding_validators.dart
// TYPE: Core Foundation / Validators
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized validation logic with strict Regex patterns to
//              ensure data integrity before it reaches the Business Logic layer.
// -----------------------------------------------------------------------------

class BrandingValidators {
  // Private constructor to prevent instantiation of this utility class.
  BrandingValidators._();

  /// Validates an optional 10-digit phone number or WhatsApp Business number.
  /// Returns null if valid (or empty), otherwise returns an error string.
  static String? validateOptionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Field is optional
    }
    
    final cleanValue = value.trim();
    // Strict regex for exactly 10 digits
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    
    if (!phoneRegex.hasMatch(cleanValue)) {
      return 'Please enter a valid 10-digit number';
    }
    return null;
  }

  /// Validates an optional email address using a strict Regex pattern.
  static String? validateOptionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Field is optional
    }

    final cleanValue = value.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(cleanValue)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates optional social media handles or URLs to prevent basic typos.
  static String? validateOptionalSocialLink(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Field is optional
    }
    
    // Basic sanitization: social handles and URLs should not contain spaces
    if (value.trim().contains(' ')) {
      return 'Links and handles cannot contain spaces';
    }
    return null;
  }
}