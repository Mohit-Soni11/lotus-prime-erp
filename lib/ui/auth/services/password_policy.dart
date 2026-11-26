/// Central rules for every local-account password write.
abstract final class PasswordPolicy {
  static const minimumLength = 8;

  static String? validate(String password) {
    if (password.length < minimumLength) {
      return 'Use at least $minimumLength characters.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Include at least one letter and one number.';
    }
    return null;
  }
}
