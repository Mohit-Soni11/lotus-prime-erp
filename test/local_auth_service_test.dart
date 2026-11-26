import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/local_database/shop_database_helper.dart';
import 'package:lotus_erp/database/local_database/shop_database_schema.dart';
import 'package:lotus_erp/ui/auth/services/auth_service.dart';
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
}
