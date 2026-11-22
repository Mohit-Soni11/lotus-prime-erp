import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/settings/backup_restore/domain/google_drive_client.dart';

void main() {
  test('application identity comes from build configuration', () {
    const client = GoogleDriveClient.fromEnvironment();
    expect(client.clientId,
        const String.fromEnvironment('LOTUS_GOOGLE_CLIENT_ID'));
    expect(client.clientSecret,
        const String.fromEnvironment('LOTUS_GOOGLE_CLIENT_SECRET'));
  });

  test('empty and malformed identities cannot enable account connection', () {
    for (final id in [
      '',
      'not-a-google-client',
      'abc.apps.googleusercontent.com/extra'
    ]) {
      expect(GoogleDriveClient(clientId: id).configured, isFalse);
    }
    expect(
        const GoogleDriveClient(clientId: 'test.apps.googleusercontent.com')
            .configured,
        isTrue);
  });
}
