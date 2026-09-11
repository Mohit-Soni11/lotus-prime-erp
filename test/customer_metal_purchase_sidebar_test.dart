import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/constants/app_routes.dart';
import 'package:lotus_erp/ui/layout/sidebar/sidebar_menu.dart';

void main() {
  test('customer metal purchase report appears only in reports menu', () {
    final purchaseMenu = SidebarMenu.menuItems.singleWhere(
      (item) => item.title == 'Customer Metal & Purchase',
    );
    final reportsMenu = SidebarMenu.menuItems.singleWhere(
      (item) => item.title == 'Reports & Analytics',
    );

    expect(
      purchaseMenu.subItems.map((item) => item.routeId),
      isNot(contains(AppRoutes.purchaseReportRoute)),
    );
    expect(
      reportsMenu.subItems.map((item) => item.routeId),
      contains(AppRoutes.purchaseReportRoute),
    );

    final visibleReportEntries = SidebarMenu.menuItems
        .expand((item) => item.subItems)
        .where((item) => item.displayTitle == 'Customer Metal Purchase Report')
        .length;
    expect(visibleReportEntries, 1);
  });
}
