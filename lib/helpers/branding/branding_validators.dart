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

  /// Validates an optional Indian/international phone number.
  /// Returns null if valid (or empty), otherwise returns an error string.
  static String? validateOptionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Field is optional
    }

    final cleanValue = value.trim();
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');

    if (!phoneRegex.hasMatch(cleanValue)) {
      return 'Please enter a valid 10-15 digit number';
    }
    return null;
  }

  /// Validates an optional email address using a strict Regex pattern.
  static String? validateOptionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Field is optional
    }

    final cleanValue = value.trim();
    final emailRegex = RegExp(r'^[\w.-]+@([\w-]+\.)+[A-Za-z]{2,}$');

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

  static String? validateOptionalWebsite(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final cleanValue = value.trim();
    if (cleanValue.contains(' ')) return 'Website cannot contain spaces';

    final uriValue = cleanValue.startsWith(RegExp(r'https?://'))
        ? cleanValue
        : 'https://$cleanValue';
    final uri = Uri.tryParse(uriValue);
    final host = uri?.host ?? '';
    if (uri == null || host.isEmpty || !host.contains('.')) {
      return 'Please enter a valid website';
    }
    return null;
  }

  static String? validateOptionalWhatsAppChannel(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final cleanValue = value.trim();
    if (cleanValue.contains(' ')) {
      return 'WhatsApp channel cannot contain spaces';
    }
    final normalized = cleanValue.startsWith(RegExp(r'https?://'))
        ? cleanValue
        : 'https://$cleanValue';
    final uri = Uri.tryParse(normalized);
    final host = uri?.host.toLowerCase() ?? '';
    if (uri == null || !host.endsWith('whatsapp.com')) {
      return 'Please enter a valid WhatsApp channel link';
    }
    return null;
  }
}
