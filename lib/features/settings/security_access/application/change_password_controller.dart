import 'package:flutter/foundation.dart';
import 'package:lotus_erp/ui/auth/services/auth_result.dart';
import 'package:lotus_erp/ui/auth/services/auth_service.dart';
import 'package:lotus_erp/ui/auth/services/password_policy.dart';

typedef ChangePasswordAction = Future<AuthResult> Function({
  required String currentPassword,
  required String newPassword,
});

class ChangePasswordController extends ChangeNotifier {
  ChangePasswordController({ChangePasswordAction? changePassword})
      : _changePassword = changePassword ?? AuthService().changePassword;

  final ChangePasswordAction _changePassword;
  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  String? validateCurrentPassword(String? value) =>
      value == null || value.isEmpty ? 'Enter your current password.' : null;

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a new password.';
    return PasswordPolicy.validate(value);
  }

  String? validateConfirmation(String? value, String newPassword) {
    if (value == null || value.isEmpty) return 'Confirm your new password.';
    return value == newPassword ? null : 'Passwords do not match.';
  }

  Future<AuthResult> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      return await _changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
