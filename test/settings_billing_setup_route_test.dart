import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/ui/settings/settings_dashboard/data/settings_data.dart';

void main() {
  test('Billing Setup settings card is wired through the app router', () {
    final item = SettingsData.items.singleWhere(
      (item) => item.title == 'Billing Setup',
    );

    expect(item.id, AppRoutes.billingSetupRoute);
    expect(RouteMapper.toPath(item.id), RoutePaths.billingSetup);
    expect(
      RouteMapper.toRouteId(RoutePaths.billingSetup),
      AppRoutes.billingSetupRoute,
    );
  });
}
