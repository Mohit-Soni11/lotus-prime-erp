import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/report/day_book/day_book_close_authorization.dart';

void main() {
  test('owner and manager can close; staff cannot', () async {
    Future<String> role(String value) => DayBookCloseAuthorization(
          currentUid: () => 'user-1',
          loadProfile: (_) async => {'isActive': true, 'role': value},
        ).authorizedActorId();
    expect(await role('OWNER'), 'user-1');
    expect(await role('manager'), 'user-1');
    await expectLater(role('STAFF'), throwsStateError);
  });

  test('missing or inactive account cannot close', () async {
    final unsigned = DayBookCloseAuthorization(
      currentUid: () => null,
      loadProfile: (_) async => {'role': 'OWNER'},
    );
    final inactive = DayBookCloseAuthorization(
      currentUid: () => 'user-1',
      loadProfile: (_) async => {'role': 'OWNER', 'isActive': false},
    );
    await expectLater(unsigned.authorizedActorId(), throwsStateError);
    await expectLater(inactive.authorizedActorId(), throwsStateError);
  });
}
