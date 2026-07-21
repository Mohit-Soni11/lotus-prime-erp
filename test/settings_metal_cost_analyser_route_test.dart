import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/ui/settings/settings_dashboard/data/settings_data.dart';

void main() {
  test('Metal Cost Analyser settings card owns stock valuation flow', () {
    final item = SettingsData.items.singleWhere(
      (item) => item.title == 'Metal Cost Analyser',
    );

    expect(item.id, AppRoutes.metalCostAnalyserRoute);
    expect(RouteMapper.toPath(item.id), RoutePaths.settingsMetalCostAnalyser);
    expect(
      RouteMapper.toPath(AppRoutes.stockValuationRoute),
      RoutePaths.settingsMetalCostAnalyser,
    );
    expect(
      RouteMapper.toRouteId(RoutePaths.stockValuation),
      AppRoutes.metalCostAnalyserRoute,
    );
  });
}
