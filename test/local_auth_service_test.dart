import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/local_database/shop_database_helper.dart';
import 'package:lotus_erp/database/local_database/shop_database_schema.dart';
import 'package:lotus_erp/ui/auth/services/auth_service.dart';
import 'package:lotus_erp/ui/auth/services/email_recovery_gateway.dart';
import 'package:lotus_erp/ui/auth/services/local_account_repository.dart';
import 'package:lotus_erp/ui/auth/services/local_session_store.dart';
import 'package:lotus_erp/ui/auth/services/otp_email_gateway.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MemorySessionStore implements LocalSessionStore {
  String? userId;

  @override
  Future<String?> readUserId() async => userId;

  @override
  Future<void> writeUserId(String value) async => userId = value;

  @override
  Future<void> clear() async => userId = null;
}

class _FakeEmailGateway implements EmailRecoveryGateway {
  String? lastSentTo;
  VerifiedEmailIdentity? identity;

  @override
  bool get isConfigured => true;

  @override
  Future<void> sendSignInLink(String email) async => lastSentTo = email;

  @override
  Future<VerifiedEmailIdentity> verifySignInLink(
      String email, String link) async {
    if (link != 'valid-link' || identity == null) {
      throw const EmailRecoveryException('Invalid link.');
    }
    return identity!;
  }
}

class _FakeOtpEmailGateway implements OtpEmailGateway {
  String? lastCode;
  String? lastEmail;
  String? lastSubject;

  @override
  Future<void> send(
      {required String email,
      required String googleSubject,
      required String code}) async {
    lastEmail = email;
    lastSubject = googleSubject;
    lastCode = code;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('company registration uses email login and persists setup details',
      () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: ShopDatabaseSchema.currentVersion,
      onCreate: ShopDatabaseSchema.create,
    );
    addTearDown(db.close);
    final accounts =
        LocalAccountRepository(helper: ShopDatabaseHelper.forTesting(db));
    final auth =
        AuthService.forTesting(accounts, sessionStore: _MemorySessionStore());

    final created = await auth.registerOwner(
      username: 'Owner@Example.com',
      password: 'SecurePass123',
      ownerName: 'Shop Owner',
      mobile: '9876543210',
      companyName: 'Lotus Jewellers',
    );
    expect(created.isSuccess, isTrue);
    expect((await accounts.read())?['username'], 'owner@example.com');
    expect((await accounts.read())?['registration_company_name'],
        'Lotus Jewellers');
    expect((await db.query('shop_profile')), isEmpty);
    expect(
        (await auth.linkNewCompanyToGoogle(
                email: 'different@example.com',
                password: 'SecurePass123',
                googleSubject: 'google-owner'))
            .isSuccess,
        isFalse);
    expect((await accounts.read())?['recovery_email'], isNull);
    expect(
        (await auth.linkNewCompanyToGoogle(
                email: 'owner@example.com',
                password: 'wrong',
                googleSubject: 'google-owner'))
            .isSuccess,
        isFalse);
    expect((await accounts.read())?['recovery_email'], isNull);
    expect(
        (await auth.linkNewCompanyToGoogle(
                email: 'owner@example.com',
                password: 'SecurePass123',
                googleSubject: 'google-owner'))
            .isSuccess,
        isTrue);
    expect((await accounts.read())?['recovery_email'], 'owner@example.com');
    expect((await accounts.read())?['recovery_google_subject'], 'google-owner');
    expect(
        (await auth.loginUser(
                username: 'OWNER@example.com', password: 'SecurePass123'))
            .isSuccess,
        isTrue);
    expect((await auth.getUserDetails())?['registrationCompanyName'],
        'Lotus Jewellers');
    expect(
        (await auth.linkRecoveryToGoogleAccount(
                currentPassword: 'SecurePass123',
                email: 'other@example.com',
                googleSubject: 'other-google'))
            .isSuccess,
        isFalse);
    expect((await accounts.read())?['recovery_google_subject'], 'google-owner');
    await auth.unlinkGoogleRecovery();
    expect((await accounts.read())?['recovery_google_subject'], isNull);
    expect((await accounts.read())?['recovery_email'], isNull);
    expect(
        (await auth.registerOwner(
                username: 'second@example.com',
                password: 'SecurePass123',
                ownerName: 'Another Owner',
                mobile: '9876543210',
                companyName: 'Second Shop'))
            .isSuccess,
        isFalse);
  });

  test('owner can create, sign in, recover and change a local password',
      () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: ShopDatabaseSchema.currentVersion,
      onCreate: ShopDatabaseSchema.create,
    );
    addTearDown(db.close);
    final accounts =
        LocalAccountRepository(helper: ShopDatabaseHelper.forTesting(db));
    final sessions = _MemorySessionStore();
    final auth = AuthService.forTesting(accounts, sessionStore: sessions);

    expect(await auth.hasOwnerAccount(), isFalse);
    final created = await auth.registerOwner(
      username: 'owner',
      password: 'initialPassword123',
      ownerName: 'Shop Owner',
      mobile: '9999999999',
    );
    expect(created.isSuccess, isTrue);
    expect(created.recoveryCode, isNotEmpty);
    expect(await auth.hasOwnerAccount(), isTrue);
    expect((await accounts.read())!.containsKey('password'), isFalse);
    expect(
        (await auth.registerOwner(
                username: 'other',
                password: 'otherPassword123',
                ownerName: 'Other',
                mobile: '9999999999'))
            .isSuccess,
        isFalse);

    expect(
        (await auth.loginUser(username: 'owner', password: 'wrong')).isSuccess,
        isFalse);
    expect(
        (await auth.loginUser(
                username: 'owner', password: 'initialPassword123'))
            .isSuccess,
        isTrue);
    expect((await auth.getUserDetails())?['name'], 'Shop Owner');
    final reopened = AuthService.forTesting(accounts, sessionStore: sessions);
    expect(await reopened.authUserIds().first, auth.currentUserId);
    expect((await reopened.validateCurrentSession()).isAuthorized, isTrue);
    expect(
        (await auth.changePassword(
                currentPassword: 'wrong', newPassword: 'newPassword123'))
            .isSuccess,
        isFalse);
    expect(
        (await auth.changePassword(
                currentPassword: 'initialPassword123',
                newPassword: 'lettersOnly'))
            .isSuccess,
        isFalse);
    expect(
        (await auth.changePassword(
                currentPassword: 'initialPassword123',
                newPassword: 'newPassword123'))
            .isSuccess,
        isTrue);
    expect((await auth.getUserDetails())?['lastPasswordChangedAt'], isNotNull);
    await auth.signOut();
    final afterLogout =
        AuthService.forTesting(accounts, sessionStore: sessions);
    expect(await afterLogout.authUserIds().first, isNull);
    expect(
        (await auth.loginUser(
                username: 'owner', password: 'initialPassword123'))
            .isSuccess,
        isFalse);

    final recovered = await auth.resetPassword(
      recoveryCode: created.recoveryCode!,
      newPassword: 'recoveredPassword123',
    );
    expect(recovered.isSuccess, isTrue);
    expect(recovered.recoveryCode, isNot(created.recoveryCode));
    expect(
        (await auth.resetPassword(
                recoveryCode: created.recoveryCode!,
                newPassword: 'anotherPassword123'))
            .isSuccess,
        isFalse);
    expect(
        (await auth.loginUser(
                username: 'owner', password: 'recoveredPassword123'))
            .isSuccess,
        isTrue);
  });

  test('verified email can reset only its linked local account', () async {
    final db = await openDatabase(inMemoryDatabasePath,
        version: ShopDatabaseSchema.currentVersion,
        onCreate: ShopDatabaseSchema.create);
    addTearDown(db.close);
    final accounts =
        LocalAccountRepository(helper: ShopDatabaseHelper.forTesting(db));
    final gateway = _FakeEmailGateway();
    final auth = AuthService.forTesting(accounts,
        sessionStore: _MemorySessionStore(), emailGateway: gateway);
    final created = await auth.registerOwner(
        username: 'owner',
        password: 'initialPassword123',
        ownerName: 'Owner',
        mobile: '9999999999');
    expect(created.isSuccess, isTrue);
    expect(
        (await auth.loginUser(
                username: 'owner', password: 'initialPassword123'))
            .isSuccess,
        isTrue);

    expect(
        (await auth.sendRecoveryEmailEnrollment(
                currentPassword: 'wrong', email: 'owner@example.com'))
            .isSuccess,
        isFalse);
    expect(gateway.lastSentTo, isNull);
    expect(
        (await auth.sendRecoveryEmailEnrollment(
                currentPassword: 'initialPassword123',
                email: 'Owner@Example.com'))
            .isSuccess,
        isTrue);
    expect(gateway.lastSentTo, 'owner@example.com');
    gateway.identity = const VerifiedEmailIdentity(
        email: 'other@example.com', uid: 'firebase-owner');
    expect(
        (await auth.confirmRecoveryEmailEnrollment(
                currentPassword: 'initialPassword123',
                email: 'owner@example.com',
                link: 'valid-link'))
            .isSuccess,
        isFalse);
    expect(await auth.getRecoveryEmail(), isNull);

    gateway.identity = const VerifiedEmailIdentity(
        email: 'owner@example.com', uid: 'firebase-owner');
    expect(
        (await auth.confirmRecoveryEmailEnrollment(
                currentPassword: 'initialPassword123',
                email: 'owner@example.com',
                link: 'valid-link'))
            .isSuccess,
        isTrue);
    expect(await auth.getRecoveryEmail(), 'owner@example.com');
    await auth.signOut();
    expect((await auth.sendPasswordResetEmail('unknown@example.com')).isSuccess,
        isTrue);
    gateway.identity = const VerifiedEmailIdentity(
        email: 'owner@example.com', uid: 'different-firebase-user');
    expect(
        (await auth.resetPasswordWithEmail(
                email: 'owner@example.com',
                link: 'valid-link',
                newPassword: 'replacementPassword123'))
            .isSuccess,
        isFalse);
    expect(
        (await auth.loginUser(
                username: 'owner', password: 'initialPassword123'))
            .isSuccess,
        isTrue);
    await auth.signOut();
    gateway.identity = const VerifiedEmailIdentity(
        email: 'owner@example.com', uid: 'firebase-owner');
    final reset = await auth.resetPasswordWithEmail(
        email: 'owner@example.com',
        link: 'valid-link',
        newPassword: 'replacementPassword123');
    expect(reset.isSuccess, isTrue);
    expect(reset.recoveryCode, isNot(created.recoveryCode));
    expect(
        (await auth.loginUser(
                username: 'owner', password: 'initialPassword123'))
            .isSuccess,
        isFalse);
    expect(
        (await auth.loginUser(
                username: 'owner', password: 'replacementPassword123'))
            .isSuccess,
        isTrue);
  });

  test('one verified Drive account also becomes the recovery email', () async {
    final db = await openDatabase(inMemoryDatabasePath,
        version: ShopDatabaseSchema.currentVersion,
        onCreate: ShopDatabaseSchema.create);
    addTearDown(db.close);
    final accounts =
        LocalAccountRepository(helper: ShopDatabaseHelper.forTesting(db));
    final gateway = _FakeEmailGateway();
    final auth = AuthService.forTesting(accounts,
        sessionStore: _MemorySessionStore(), emailGateway: gateway);
    await auth.registerOwner(
        username: 'owner',
        password: 'initialPassword123',
        ownerName: 'Owner',
        mobile: '9999999999');
    await auth.loginUser(username: 'owner', password: 'initialPassword123');

    expect(
        (await auth.linkRecoveryToGoogleAccount(
                currentPassword: 'wrong',
                email: 'Owner@Example.com',
                googleSubject: 'google-owner'))
            .isSuccess,
        isFalse);
    expect(await auth.getRecoveryEmail(), isNull);
    expect(
        (await auth.linkRecoveryToGoogleAccount(
                currentPassword: 'initialPassword123',
                email: 'Owner@Example.com',
                googleSubject: 'google-owner'))
            .isSuccess,
        isTrue);
    expect(await auth.getRecoveryEmail(), 'owner@example.com');
    expect(await auth.isRecoveryLinkedToGoogle(), isTrue);
    expect((await accounts.read())?['recovery_email_uid'], isNull);
    await auth.signOut();

    gateway.identity = const VerifiedEmailIdentity(
        email: 'different@example.com', uid: 'firebase-owner');
    expect(
        (await auth.resetPasswordWithEmail(
                email: 'owner@example.com',
                link: 'valid-link',
                newPassword: 'replacementPassword123'))
            .isSuccess,
        isFalse);
    gateway.identity = const VerifiedEmailIdentity(
        email: 'owner@example.com', uid: 'firebase-owner');
    expect(
        (await auth.resetPasswordWithEmail(
                email: 'owner@example.com',
                link: 'valid-link',
                newPassword: 'replacementPassword123'))
            .isSuccess,
        isTrue);
    expect((await accounts.read())?['recovery_email_uid'], 'firebase-owner');

    gateway.identity = const VerifiedEmailIdentity(
        email: 'owner@example.com', uid: 'other-firebase-user');
    expect(
        (await auth.resetPasswordWithEmail(
                email: 'owner@example.com',
                link: 'valid-link',
                newPassword: 'anotherPassword123'))
            .isSuccess,
        isFalse);
  });

  test('email OTP is bound to the linked owner, limited and single use',
      () async {
    final db = await openDatabase(inMemoryDatabasePath,
        version: ShopDatabaseSchema.currentVersion,
        onCreate: ShopDatabaseSchema.create);
    addTearDown(db.close);
    final accounts =
        LocalAccountRepository(helper: ShopDatabaseHelper.forTesting(db));
    final sender = _FakeOtpEmailGateway();
    final auth = AuthService.forTesting(accounts,
        sessionStore: _MemorySessionStore(), otpEmailGateway: sender);
    await auth.registerOwner(
        username: 'owner',
        password: 'InitialPassword123',
        ownerName: 'Owner',
        mobile: '9999999999');
    expect((await auth.sendPasswordResetOtp('owner@example.com')).isSuccess,
        isFalse);
    expect(sender.lastCode, isNull);
    await auth.loginUser(username: 'owner', password: 'InitialPassword123');
    expect(
        (await auth.linkRecoveryToGoogleAccount(
                currentPassword: 'InitialPassword123',
                email: 'Owner@Example.com',
                googleSubject: 'google-owner'))
            .isSuccess,
        isTrue);
    await auth.signOut();

    expect((await auth.sendPasswordResetOtp('unknown@example.com')).isSuccess,
        isFalse);
    expect(sender.lastCode, isNull);
    var clock = DateTime.utc(2026, 11, 28);
    final otherSession = AuthService.forTesting(accounts,
        sessionStore: _MemorySessionStore(),
        otpEmailGateway: sender,
        clock: () => clock);
    expect(
        (await otherSession.sendPasswordResetOtp('owner@example.com'))
            .isSuccess,
        isTrue);
    expect(sender.lastEmail, 'owner@example.com');
    expect(sender.lastSubject, 'google-owner');
    expect(sender.lastCode, matches(RegExp(r'^\d{6}$')));
    expect(
        (await otherSession.sendPasswordResetOtp('owner@example.com'))
            .isSuccess,
        isFalse);
    expect(
        (await otherSession.verifyPasswordResetOtp(
                email: 'other@example.com', code: sender.lastCode!))
            .isSuccess,
        isFalse);
    for (var attempt = 0; attempt < 5; attempt++) {
      expect(
          (await otherSession.verifyPasswordResetOtp(
                  email: 'owner@example.com',
                  code: sender.lastCode == '000000' ? '000001' : '000000'))
              .isSuccess,
          isFalse);
    }
    expect(
        (await otherSession.resetPasswordWithOtp(
                email: 'owner@example.com', newPassword: 'Replacement123'))
            .isSuccess,
        isFalse);
    expect(
        (await otherSession.verifyPasswordResetOtp(
                email: 'owner@example.com', code: sender.lastCode!))
            .isSuccess,
        isFalse);
    clock = clock.add(const Duration(seconds: 61));
    expect(
        (await otherSession.sendPasswordResetOtp('owner@example.com'))
            .isSuccess,
        isTrue);
    final expiringCode = sender.lastCode!;
    clock = clock.add(const Duration(minutes: 10));
    expect(
        (await otherSession.verifyPasswordResetOtp(
                email: 'owner@example.com', code: expiringCode))
            .isSuccess,
        isFalse);
    expect(
        (await otherSession.sendPasswordResetOtp('owner@example.com'))
            .isSuccess,
        isTrue);
    expect(
        (await otherSession.verifyPasswordResetOtp(
                email: 'owner@example.com', code: sender.lastCode!))
            .isSuccess,
        isTrue);
    final reset = await otherSession.resetPasswordWithOtp(
        email: 'owner@example.com', newPassword: 'Replacement123');
    expect(reset.isSuccess, isTrue);
    expect(reset.recoveryCode, isNotNull);
    expect(
        (await otherSession.resetPasswordWithOtp(
                email: 'owner@example.com', newPassword: 'AnotherPassword123'))
            .isSuccess,
        isFalse);
    expect(
        (await otherSession.loginUser(
                username: 'owner', password: 'InitialPassword123'))
            .isSuccess,
        isFalse);
    expect(
        (await otherSession.loginUser(
                username: 'owner', password: 'Replacement123'))
            .isSuccess,
        isTrue);
  });

  test('version 11 owner account gains recovery and company columns', () async {
    final db = await openDatabase(inMemoryDatabasePath,
        version: 11, onCreate: ShopDatabaseSchema.create);
    addTearDown(db.close);
    await db
        .execute('ALTER TABLE local_owner_account DROP COLUMN recovery_email');
    await db.execute(
        'ALTER TABLE local_owner_account DROP COLUMN recovery_email_uid');
    await db.execute(
        'ALTER TABLE local_owner_account DROP COLUMN recovery_google_subject');
    await db.execute(
        'ALTER TABLE local_owner_account DROP COLUMN registration_company_name');
    await ShopDatabaseSchema.upgrade(db, 11, ShopDatabaseSchema.currentVersion);
    final columns = await db.rawQuery('PRAGMA table_info(local_owner_account)');
    final names = columns.map((row) => row['name']).toSet();
    expect(
        names,
        containsAll([
          'recovery_email',
          'recovery_email_uid',
          'recovery_google_subject',
          'registration_company_name'
        ]));
  });
}
