import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/local_database/shop_database_helper.dart';
import 'package:lotus_erp/database/local_database/shop_database_schema.dart';
import 'package:lotus_erp/ui/auth/services/auth_service.dart';
import 'package:lotus_erp/ui/auth/services/email_recovery_gateway.dart';
import 'package:lotus_erp/ui/auth/services/local_account_repository.dart';
import 'package:lotus_erp/ui/auth/services/local_session_store.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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

  test('version 11 owner account gains nullable recovery email columns',
      () async {
    final db = await openDatabase(inMemoryDatabasePath,
        version: 11, onCreate: ShopDatabaseSchema.create);
    addTearDown(db.close);
    await db
        .execute('ALTER TABLE local_owner_account DROP COLUMN recovery_email');
    await db.execute(
        'ALTER TABLE local_owner_account DROP COLUMN recovery_email_uid');
    await db.execute(
        'ALTER TABLE local_owner_account DROP COLUMN recovery_google_subject');
    await ShopDatabaseSchema.upgrade(db, 11, 13);
    final columns = await db.rawQuery('PRAGMA table_info(local_owner_account)');
    final names = columns.map((row) => row['name']).toSet();
    expect(
        names,
        containsAll([
          'recovery_email',
          'recovery_email_uid',
          'recovery_google_subject'
        ]));
  });
}
