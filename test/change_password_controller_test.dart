import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/settings/security_access/application/change_password_controller.dart';
import 'package:lotus_erp/ui/auth/services/auth_result.dart';

void main() {
  test('validates the focused password-change workflow', () {
    final controller = ChangePasswordController(
      changePassword: (
              {required currentPassword, required newPassword}) async =>
          const AuthResult(AuthResultCode.success, 'Updated.'),
    );

    expect(controller.validateCurrentPassword(''), isNotNull);
    expect(controller.validateNewPassword('onlyletters'), isNotNull);
    expect(controller.validateNewPassword('password123'), isNull);
    expect(controller.validateConfirmation('', 'password123'), isNotNull);
    expect(controller.validateConfirmation('different123', 'password123'),
        isNotNull);
    expect(
        controller.validateConfirmation('password123', 'password123'), isNull);
  });

  test('submits only the current and new password to the secured service',
      () async {
    String? capturedCurrent;
    String? capturedNew;
    final controller = ChangePasswordController(
      changePassword: ({required currentPassword, required newPassword}) async {
        capturedCurrent = currentPassword;
        capturedNew = newPassword;
        return const AuthResult(AuthResultCode.success, 'Updated.');
      },
    );

    final result = await controller.submit(
      currentPassword: 'currentPassword123',
      newPassword: 'nextPassword123',
    );

    expect(result.isSuccess, isTrue);
    expect(capturedCurrent, 'currentPassword123');
    expect(capturedNew, 'nextPassword123');
    expect(controller.isSubmitting, isFalse);
  });
}
