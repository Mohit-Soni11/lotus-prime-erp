import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/ui/settings/settings_dashboard/data/settings_data.dart';

void main() {
  test('Print Templates settings card is wired through the app router', () {
    final item = SettingsData.items.singleWhere(
      (item) => item.title == 'Print Templates',
    );

    expect(item.id, AppRoutes.printTemplatesRoute);
    expect(RouteMapper.toPath(item.id), RoutePaths.printTemplates);
    expect(
      RouteMapper.toRouteId(RoutePaths.printTemplates),
      AppRoutes.printTemplatesRoute,
    );
  });
}
