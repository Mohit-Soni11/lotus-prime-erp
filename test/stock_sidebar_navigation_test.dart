import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/ui/layout/sidebar/sidebar_menu.dart';

void main() {
  test('stock menu follows the inventory workflow', () {
    final stockMenu = SidebarMenu.menuItems.singleWhere(
      (item) => item.title == 'Stock & Inventory',
    );

    expect(stockMenu.subItems.map((item) => item.routeId), [
      AppRoutes.addStockRoute,
      AppRoutes.inventoryRoute,
      AppRoutes.stockSummaryRoute,
      AppRoutes.stockSearchRoute,
      AppRoutes.stockActivityRoute,
      AppRoutes.stockTransferRoute,
      AppRoutes.lowStockAlertRoute,
    ]);
    expect(stockMenu.subItems, hasLength(7));
    for (final item in stockMenu.subItems) {
      expect(RouteMapper.toPath(item.routeId), isNot(RoutePaths.dashboard));
    }
  });
}
