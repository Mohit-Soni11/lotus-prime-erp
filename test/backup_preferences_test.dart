import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'business preferences restore without exporting sessions or OAuth tokens',
      () async {
    SharedPreferences.setMockInitialValues({
      'shop': 'original',
      'obsolete': true,
      'owner_session': 'session',
      'google_refresh_token': 'secret',
      'backup.folder': 'local-only'
    });
    final preferences = SharedBusinessPreferences();
    expect(await preferences.read(), {'shop': 'original', 'obsolete': true});
    await preferences.replace({
      'shop': 'restored',
      'rates': 10.5,
      'flags': ['one']
    });
    expect(await preferences.read(), {
      'shop': 'restored',
      'rates': 10.5,
      'flags': ['one']
    });
    final raw = await SharedPreferences.getInstance();
    expect(raw.getString('owner_session'), 'session');
    expect(raw.getString('google_refresh_token'), 'secret');
    expect(raw.getString('backup.folder'), 'local-only');
  });
}
