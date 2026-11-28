import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/local_database/shop_database_helper.dart';
import 'package:lotus_erp/database/local_database/shop_database_schema.dart';
import 'package:lotus_erp/features/settings/backup_restore/application/backup_coordinator.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_restore_service.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_store.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/google_drive_auth.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/google_drive_backup_service.dart';
import 'package:lotus_erp/ui/auth/services/auth_service.dart';
import 'package:lotus_erp/ui/auth/services/company_google_enrollment.dart';
import 'package:lotus_erp/ui/auth/services/local_account_repository.dart';
import 'package:lotus_erp/ui/auth/services/local_session_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'backup_restore_test_support.dart';
import 'google_drive_backup_test_support.dart';

class _MemorySessionStore implements LocalSessionStore {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> readUserId() async => null;
  @override
  Future<void> writeUserId(String userId) async {}
}

class _EnrollmentGoogleAuth extends GoogleDriveAuth {
  _EnrollmentGoogleAuth(this.identity)
      : super(
          http: FakeBackupHttp((a, b, c, d) async => backupJsonResponse({})),
          secrets: MemoryBackupSecrets(),
        );

  VerifiedGoogleIdentity identity;
  bool disconnected = false;
  bool gmailSendAllowed = true;

  @override
  bool get configured => true;
  @override
  bool get canSendRecoveryEmail => gmailSendAllowed;
  @override
  Future<void> signIn() async {
    disconnected = false;
  }

  @override
  Future<VerifiedGoogleIdentity> verifiedIdentity() async => identity;
  @override
  Future<void> disconnect() async {
    disconnected = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('registration links only the same verified Google mailbox', () async {
    final db = await openDatabase(inMemoryDatabasePath,
        version: ShopDatabaseSchema.currentVersion,
        onCreate: ShopDatabaseSchema.create);
    addTearDown(db.close);
    final accounts =
        LocalAccountRepository(helper: ShopDatabaseHelper.forTesting(db));
    final auth =
        AuthService.forTesting(accounts, sessionStore: _MemorySessionStore());
    final created = await auth.registerOwner(
      username: 'owner@example.com',
      password: 'SecurePass123',
      ownerName: 'Owner',
      mobile: '9876543210',
      companyName: 'Lotus Jewellers',
    );
    expect(created.isSuccess, isTrue);

    final directory = await Directory.systemTemp.createTemp('lotus-enroll-');
    addTearDown(() => directory.delete(recursive: true));
    final fixture = BackupFixture(directory);
    final http = FakeBackupHttp((a, b, c, d) async => backupJsonResponse({}));
    final google = _EnrollmentGoogleAuth(const VerifiedGoogleIdentity(
        email: 'other@example.com', subject: 'other-google'));
    final backup = BackupCoordinator(
      locations: fixture.locations,
      store: BackupStore(fixture.locations),
      preferences: fixture.preferences,
      drive: GoogleDriveBackupService(auth: google, http: http),
      restore: BackupRestoreService(fixture.locations, fixture.preferences,
          clearSession: () async {}),
      requireOwner: () async {},
    );
    addTearDown(backup.dispose);
    final enrollment = CompanyGoogleEnrollment(
      authService: auth,
      coordinator: () async => backup,
    );

    await expectLater(
        enrollment.connect(
            email: 'owner@example.com', password: 'SecurePass123'),
        throwsStateError);
    expect(google.disconnected, isTrue);
    expect((await accounts.read())?['recovery_email'], isNull);

    google.identity = const VerifiedGoogleIdentity(
        email: 'owner@example.com', subject: 'owner-google');
    google.gmailSendAllowed = false;
    await expectLater(
        enrollment.connect(
            email: 'owner@example.com', password: 'SecurePass123'),
        throwsStateError);
    expect(google.disconnected, isTrue);
    expect((await accounts.read())?['recovery_email'], isNull);

    google.gmailSendAllowed = true;
    await enrollment.connect(
        email: 'owner@example.com', password: 'SecurePass123');
    expect(backup.recoveryLinked, isTrue);
    expect(google.disconnected, isFalse);
    expect((await accounts.read())?['recovery_email'], 'owner@example.com');
    expect((await accounts.read())?['recovery_google_subject'], 'owner-google');
  });
}
