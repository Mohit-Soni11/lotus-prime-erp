class AuthFieldValidator {
  const AuthFieldValidator._();

  static String? requiredText(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'This field is required.' : null;

  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^[A-Za-z0-9._-]{3,32}$').hasMatch(text)) {
      return 'Use 3–32 letters, numbers, dots, hyphens or underscores.';
    }
    return null;
  }

  static String? loginIdentifier(String? value) {
    final text = value?.trim() ?? '';
    if (RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text) ||
        RegExp(r'^[A-Za-z0-9._-]{3,32}$').hasMatch(text)) {
      return null;
    }
    return 'Enter your email address or existing username.';
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
        ? null
        : 'Enter a valid email address.';
  }

  static String? mobile(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^\d{10}$').hasMatch(text)) {
      return 'Enter a 10-digit mobile number.';
    }
    return null;
  }

  static String? loginPassword(String? value) =>
      (value?.isEmpty ?? true) ? 'Password is required.' : null;

  static String? newPassword(String? value) {
    if (value == null || value.length < 8) {
      return 'Use at least 8 characters for your password.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    return value == password ? null : 'Passwords do not match.';
  }
}
