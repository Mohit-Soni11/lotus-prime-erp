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

  static String? validateOptionalHandleOrUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().contains(' ')) {
      return 'Handle or link cannot contain spaces';
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
