// -----------------------------------------------------------------------------
// FILE: banking_validators.dart
// TYPE: Utility / Validation
// AUTHOR: Senior Security Analyst
// DESCRIPTION: Bulletproof Regex validators for Indian banking standards.
//              Upgraded with strict sanitization and edge-case handling.
// -----------------------------------------------------------------------------

class BankingValidators {
  static String? validateHolderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Account holder name is required";
    }
    if (value.trim().length < 3) return "Name must be at least 3 characters";

    // Security Upgrade: Block random special characters (only allow letters, spaces, dots, &, -, ')
    final nameRegex = RegExp(r"^[a-zA-Z\s\.\&\-\']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return "Name contains invalid characters";
    }

    return null;
  }

  static String? validateBankName(String? value) {
    if (value == null || value.trim().isEmpty) return "Bank name is required";
    return null;
  }

  static String? validateAccountNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Account number is required";
    }

    // Security Upgrade: Automatically handle accidental spaces from copy-pasting
    final sanitizedValue = value.replaceAll(RegExp(r'\s+'), '');

    if (sanitizedValue.length < 6 || sanitizedValue.length > 20) {
      return "Invalid account number length";
    }

    final isNumeric = RegExp(r'^[0-9]+$').hasMatch(sanitizedValue);
    if (!isNumeric) return "Account number must contain only digits";

    return null;
  }

  static String? validateIFSC(String? value) {
    if (value == null || value.trim().isEmpty) return "IFSC code is required";

    // Security Upgrade: Remove spaces and force uppercase for strict validation
    final sanitizedValue = value.replaceAll(RegExp(r'\s+'), '').toUpperCase();

    // Standard Indian IFSC Regex: 4 Letters, 1 Zero, 6 Alphanumeric
    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    if (!ifscRegex.hasMatch(sanitizedValue)) return "Invalid IFSC code format";

    return null;
  }

  static String? validateUPI(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional field

    final sanitizedValue = value.trim();
    // Standard UPI Regex
    final upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
    if (!upiRegex.hasMatch(sanitizedValue)) return "Invalid UPI ID format";

    return null;
  }
}
