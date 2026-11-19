import 'package:flutter/material.dart';
import '../../../constants/app_routes.dart';

class MenuItemData {
  final String routeId;
  final String displayTitle;

  MenuItemData(this.routeId, {String? label})
      : displayTitle = label ?? AppRoutes.getTitle(routeId);
}

class SidebarItem {
  final String title;
  final IconData icon;
  final List<MenuItemData> subItems;

  const SidebarItem({
    required this.title,
    required this.icon,
    this.subItems = const [],
  });
}

class SidebarMenu {
  static final List<SidebarItem> menuItems = List.unmodifiable([
    SidebarItem(
      title: 'Customers & Suppliers',
      icon: Icons.groups_outlined,
      subItems: [
        MenuItemData(AppRoutes.customerListRoute, label: 'Customers'),
        MenuItemData(AppRoutes.addCustomerRoute, label: 'Add Customer'),
        MenuItemData(AppRoutes.supplierListRoute, label: 'Suppliers'),
        MenuItemData(AppRoutes.addSupplierRoute, label: 'Add Supplier'),
      ],
    ),
    SidebarItem(
      title: 'Sales',
      icon: Icons.shopping_cart_outlined,
      subItems: [
        MenuItemData(AppRoutes.newSaleRoute),
        MenuItemData(AppRoutes.bookingAdvanceRoute),
        MenuItemData(AppRoutes.salesReturnExchangeRoute,
            label: 'Returns & Reversals'),
      ],
    ),
    SidebarItem(
      title: 'Purchases',
      icon: Icons.shopping_bag_outlined,
      subItems: [
        MenuItemData(AppRoutes.purchaseEntryRoute),
        MenuItemData(AppRoutes.addStockRoute, label: 'Stock Intake'),
      ],
    ),
    SidebarItem(
      title: 'Inventory',
      icon: Icons.inventory_2_outlined,
      subItems: [
        MenuItemData(AppRoutes.stockSummaryRoute),
        MenuItemData(AppRoutes.inventoryRoute),
        MenuItemData(AppRoutes.stockSearchRoute, label: 'Stock Search'),
        MenuItemData(AppRoutes.stockActivityRoute, label: 'Stock Activity'),
        MenuItemData(AppRoutes.stockTransferRoute),
        MenuItemData(AppRoutes.lowStockAlertRoute),
      ],
    ),
    SidebarItem(
      title: 'Pledge & Recovery',
      icon: Icons.lock_outline_rounded,
      subItems: [
        MenuItemData(AppRoutes.newGirviRoute),
        MenuItemData(AppRoutes.girviReleaseRoute),
        MenuItemData(AppRoutes.interestCalcRoute),
        MenuItemData(AppRoutes.defaulterListRoute),
        MenuItemData(AppRoutes.noticeAuctionRoute),
      ],
    ),
    SidebarItem(
      title: 'Dues & Collections',
      icon: Icons.receipt_long_outlined,
      subItems: [
        MenuItemData(AppRoutes.dueReportRoute),
        MenuItemData(AppRoutes.dueCollectionRoute),
        MenuItemData(AppRoutes.dueReceiptHistoryRoute),
      ],
    ),
    SidebarItem(
      title: 'Finance & Ledgers',
      icon: Icons.account_balance_wallet_outlined,
      subItems: [
        MenuItemData(AppRoutes.cashBookRoute),
        MenuItemData(AppRoutes.bankBookRoute),
        MenuItemData(AppRoutes.expenseEntryRoute),
      ],
    ),
    SidebarItem(
      title: 'Reports',
      icon: Icons.assessment_outlined,
      subItems: [
        MenuItemData(AppRoutes.dayBookRoute),
        MenuItemData(AppRoutes.salesReportRoute),
        MenuItemData(AppRoutes.purchaseReportRoute),
        MenuItemData(AppRoutes.gstReportRoute),
      ],
    ),
  ]);
}
