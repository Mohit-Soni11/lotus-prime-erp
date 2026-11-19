import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/ui/layout/sidebar/sidebar_menu.dart';

void main() {
  test('purchase workflows and their report have distinct homes', () {
    final purchaseMenu = SidebarMenu.menuItems.singleWhere(
      (item) => item.title == 'Purchases',
    );
    final reportsMenu = SidebarMenu.menuItems.singleWhere(
      (item) => item.title == 'Reports',
    );

    expect(purchaseMenu.subItems.map((item) => item.routeId), [
      AppRoutes.purchaseEntryRoute,
      AppRoutes.addStockRoute,
    ]);
    expect(
      reportsMenu.subItems.map((item) => item.routeId),
      contains(AppRoutes.purchaseReportRoute),
    );

    final visibleReportEntries = SidebarMenu.menuItems
        .expand((item) => item.subItems)
        .where((item) => item.displayTitle == 'Metal Purchase Report')
        .length;
    expect(visibleReportEntries, 1);
  });

  test('sidebar groups every working destination once', () {
    expect(SidebarMenu.menuItems.map((item) => item.title), [
      'Customers & Suppliers',
      'Sales',
      'Purchases',
      'Inventory',
      'Pledge & Recovery',
      'Dues & Collections',
      'Finance & Ledgers',
      'Reports',
    ]);

    final routes = SidebarMenu.menuItems
        .expand((group) => group.subItems)
        .map((item) => item.routeId)
        .toList();
    expect(routes.toSet(), hasLength(routes.length));
    expect(routes, contains(AppRoutes.noticeAuctionRoute));
    expect(
      SidebarMenu.menuItems.first.subItems.map((item) => item.routeId),
      [
        AppRoutes.customerListRoute,
        AppRoutes.addCustomerRoute,
        AppRoutes.supplierListRoute,
        AppRoutes.addSupplierRoute,
      ],
    );
    for (final route in routes) {
      expect(RouteMapper.toPath(route), isNot(RoutePaths.dashboard));
    }
  });
}
