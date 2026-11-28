import 'auth_result.dart';

abstract interface class PasswordRecoveryActions {
  Future<AuthResult> sendPasswordResetOtp(String email);
  Future<AuthResult> verifyPasswordResetOtp({
    required String email,
    required String code,
  });
  Future<AuthResult> resetPasswordWithOtp({
    required String email,
    required String newPassword,
  });
  Future<AuthResult> resetPassword({
    required String recoveryCode,
    required String newPassword,
  });
}
