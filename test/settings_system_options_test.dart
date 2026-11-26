import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/setting/settings_model.dart';
import 'package:lotus_erp/ui/settings/settings_dashboard/data/settings_data.dart';

void main() {
  test('System settings contain only supported operational options', () {
    final systemItems = SettingsData.getByCategory(SettingsCategory.system);

    expect(systemItems, hasLength(1));
    expect(systemItems.single.title, 'Backup & Restore');
    expect(systemItems.map((item) => item.title),
        isNot(contains('Notifications')));
    expect(systemItems.map((item) => item.title),
        isNot(contains('App Preferences')));
  });
}
