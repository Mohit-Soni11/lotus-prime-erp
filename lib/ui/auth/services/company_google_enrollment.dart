import '../../../features/settings/backup_restore/application/backup_coordinator.dart';
import '../../../features/settings/backup_restore/application/backup_runtime.dart';
import 'auth_service.dart';

class CompanyGoogleEnrollment {
  CompanyGoogleEnrollment({
    AuthService? authService,
    Future<BackupCoordinator> Function()? coordinator,
  })  : _authService = authService ?? AuthService(),
        _coordinator = coordinator ?? BackupRuntime.instance.coordinator;

  final AuthService _authService;
  final Future<BackupCoordinator> Function() _coordinator;

  Future<void> connect({
    required String email,
    required String password,
  }) async {
    final backup = await _coordinator();
    final google = backup.drive.auth;
    if (!google.configured) {
      throw StateError(
          'Google account connection is unavailable in this build.');
    }
    if (backup.busy) {
      throw StateError('Another backup operation is in progress.');
    }

    await google.signIn();
    try {
      final identity = await google.verifiedIdentity();
      if (identity.email.trim().toLowerCase() != email.trim().toLowerCase()) {
        throw StateError(
            'Choose $email in Google sign-in to link this company.');
      }
      if (!google.canSendRecoveryEmail) {
        throw StateError(
            'Allow Gmail send permission to enable password recovery OTP.');
      }
      final result = await _authService.linkNewCompanyToGoogle(
        email: email,
        password: password,
        googleSubject: identity.subject,
      );
      if (!result.isSuccess) throw StateError(result.message);
      backup.recoveryLinked = true;
    } catch (_) {
      await google.disconnect();
      backup.recoveryLinked = false;
      rethrow;
    }
  }
}
