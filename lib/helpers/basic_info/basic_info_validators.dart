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
  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

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
    if (!_phoneRegex.hasMatch(val.trim())) {
      return 'Invalid Mobile No (10-15 digits allowed)';
    }
    return null;
  }

  static String? requiredPhone(String? val) {
    if (val == null || val.trim().isEmpty) return 'Mobile No is required';
    if (!_phoneRegex.hasMatch(val.trim())) {
      return 'Invalid Mobile No (10-15 digits allowed)';
    }
    return null;
  }

  static String? email(String? val) {
    if (val == null || val.trim().isEmpty) return null; // Optional field
    if (!_emailRegex.hasMatch(val.trim())) return 'Invalid Email Format';
    return null;
  }

  static String? businessHours({
    required String openTime,
    required String closeTime,
  }) {
    final openMinutes = _parseClockMinutes(openTime);
    final closeMinutes = _parseClockMinutes(closeTime);
    if (openMinutes == null || closeMinutes == null) {
      return 'Use a valid time format';
    }
    if (closeMinutes <= openMinutes) {
      return 'Closing time must be after opening time';
    }
    return null;
  }

  static int? _parseClockMinutes(String value) {
    final text = value.trim().toUpperCase();
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(text);
    if (match == null) return null;

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    final meridiem = match.group(3)!;
    if (hour == null ||
        minute == null ||
        hour < 1 ||
        hour > 12 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    final normalizedHour = switch (meridiem) {
      'AM' => hour == 12 ? 0 : hour,
      'PM' => hour == 12 ? 12 : hour + 12,
      _ => hour,
    };
    return normalizedHour * 60 + minute;
  }
}
