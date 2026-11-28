import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/ui/auth/services/auth_result.dart';
import 'package:lotus_erp/ui/auth/services/password_recovery_actions.dart';
import 'package:lotus_erp/ui/auth/widgets/password_recovery_panel.dart';

class _RecoveryActions implements PasswordRecoveryActions {
  @override
  Future<AuthResult> sendPasswordResetOtp(String email) async =>
      const AuthResult(AuthResultCode.success, 'Code sent.');

  @override
  Future<AuthResult> verifyPasswordResetOtp({
    required String email,
    required String code,
  }) async =>
      code == '123456'
          ? const AuthResult(AuthResultCode.success, 'Verified.')
          : const AuthResult(AuthResultCode.failure, 'Invalid code.');

  @override
  Future<AuthResult> resetPasswordWithOtp({
    required String email,
    required String newPassword,
  }) async =>
      const AuthResult(AuthResultCode.success, 'Password reset.',
          recoveryCode: 'NEW-RECOVERY-CODE');

  @override
  Future<AuthResult> resetPassword({
    required String recoveryCode,
    required String newPassword,
  }) async =>
      const AuthResult(AuthResultCode.success, 'Password reset.',
          recoveryCode: 'NEW-RECOVERY-CODE');
}

void main() {
  testWidgets('email, OTP, password and success stay in one panel',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 740,
                height: 706,
                child: PasswordRecoveryPanel(
                    authService: _RecoveryActions(), onBackToSignIn: () {})))));
    expect(find.text('Forgot Password'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'owner@example.com');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Verify OTP'), findsWidgets);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Verify OTP').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Reset Password'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'NewPassword123');
    await tester.enterText(find.byType(TextField).last, 'NewPassword123');
    await tester.ensureVisible(find.text('Reset Password').last);
    await tester.tap(find.text('Reset Password').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Password Reset Successful'), findsOneWidget);
    expect(find.text('NEW-RECOVERY-CODE'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull);
  });
}
