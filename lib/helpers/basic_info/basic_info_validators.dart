// -----------------------------------------------------------------------------
// FILE: basic_info_validators.dart
// TYPE: Utility / Helper (Validation Logic)
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized, robust validation logic with global regex support 
//              for international standards.
// -----------------------------------------------------------------------------

class BasicInfoValidators {
  
  // Pre-compiled regex for maximum performance (Memory efficient)
  // Supports international email formats strictly
  static final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  
  // Supports local 10-digit or international formats like +919876543210 (10 to 15 digits)
  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');

  // --- GENERIC VALIDATORS ---
  
  static String? required(String? val, String fieldName) {
    if (val == null || val.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // --- SPECIFIC VALIDATORS ---

  static String? phone(String? val) {
    if (val == null || val.trim().isEmpty) return null; // Optional field
    if (!_phoneRegex.hasMatch(val.trim())) return 'Invalid Mobile No (10-15 digits allowed)';
    return null;
  }

  static String? requiredPhone(String? val) {
    if (val == null || val.trim().isEmpty) return 'Mobile No is required';
    if (!_phoneRegex.hasMatch(val.trim())) return 'Invalid Mobile No (10-15 digits allowed)';
    return null;
  }

  static String? email(String? val) {
    if (val == null || val.trim().isEmpty) return null; // Optional field
    if (!_emailRegex.hasMatch(val.trim())) return 'Invalid Email Format';
    return null;
  }
}