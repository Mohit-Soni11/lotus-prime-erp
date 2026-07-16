import 'package:flutter/material.dart';
import '../../../constants/app_routes.dart';

// ✅ Helper Class: Ye ID aur Title dono hold karega
class MenuItemData {
  final String routeId;
  final String displayTitle;
  MenuItemData(this.routeId) : displayTitle = AppRoutes.getTitle(routeId);
}

class SidebarItem {
  final String title;
  final IconData icon;
  // ✅ Change: String ki jagah ab structured data hai
  final List<MenuItemData> subItems;

  const SidebarItem({
    required this.title,
    required this.icon,
    this.subItems = const [],
  });
}

class SidebarMenu {
  static List<SidebarItem> menuItems = [
    // ── Customer ────────────────────────────────────────────────
    SidebarItem(
      title: 'Customer',
      icon: Icons.people_outline_rounded,
      subItems: [
        MenuItemData(AppRoutes.customerListRoute),
        MenuItemData(AppRoutes.addCustomerRoute),
      ],
    ),

    // ── Supplier ✅ NEW ─────────────────────────────────────────
    SidebarItem(
      title: 'Supplier',
      icon: Icons.store_outlined,
      subItems: [
        MenuItemData(AppRoutes.supplierListRoute),
        MenuItemData(AppRoutes.addSupplierRoute),
      ],
    ),

    // ── sales_orders ──────────────────────────────────────────
    SidebarItem(
      title: 'sales_orders',
      icon: Icons.shopping_cart_outlined,
      subItems: [
        MenuItemData(AppRoutes.newSaleRoute),
        MenuItemData(AppRoutes.bookingAdvanceRoute),
        MenuItemData(AppRoutes.deliveryManagementRoute),
      ],
    ),

    // ── Purchase & Old Gold ─────────────────────────────────────
    SidebarItem(
      title: 'Purchase & Old Gold',
      icon: Icons.shopping_bag_outlined,
      subItems: [
        MenuItemData(AppRoutes.purchaseEntryRoute),
        MenuItemData(AppRoutes.oldGoldBuyRoute),
        MenuItemData(AppRoutes.purchaseReturnRoute),
      ],
    ),

    // ── Stock & Inventory ───────────────────────────────────────
    SidebarItem(
      title: 'Stock & Inventory',
      icon: Icons.inventory_2_outlined,
      subItems: [
        MenuItemData(AppRoutes.inventoryRoute),
        MenuItemData(AppRoutes.stockSummaryRoute),
        MenuItemData(AppRoutes.stockActivityRoute),
        MenuItemData(AppRoutes.stockSearchRoute),
        MenuItemData(AppRoutes.stockValuationRoute),
        MenuItemData(AppRoutes.addStockRoute),
        MenuItemData(AppRoutes.barcodePrintRoute),
        MenuItemData(AppRoutes.stockTransferRoute),
        MenuItemData(AppRoutes.lowStockAlertRoute),
      ],
    ),

    // ── Karigar ─────────────────────────────────────────────────
    SidebarItem(
      title: 'Karigar',
      icon: Icons.engineering_outlined,
      subItems: [
        MenuItemData(AppRoutes.issueToKarigarRoute),
        MenuItemData(AppRoutes.receiveFromKarigarRoute),
        MenuItemData(AppRoutes.pendingJobsRoute),
        MenuItemData(AppRoutes.karigarLedgerRoute),
      ],
    ),

    // ── Girvi / Loan ────────────────────────────────────────────
    SidebarItem(
      title: 'Girvi / Loan',
      icon: Icons.lock_outline_rounded,
      subItems: [
        MenuItemData(AppRoutes.newGirviRoute),
        MenuItemData(AppRoutes.interestCalcRoute),
        MenuItemData(AppRoutes.girviReleaseRoute),
        MenuItemData(AppRoutes.defaulterListRoute),
        MenuItemData(AppRoutes.noticeAuctionRoute),
      ],
    ),

    // Due & Collection
    SidebarItem(
      title: 'Due & Collection',
      icon: Icons.receipt_long_outlined,
      subItems: [
        MenuItemData(AppRoutes.dueReportRoute),
        MenuItemData(AppRoutes.dueCollectionRoute),
        MenuItemData(AppRoutes.dueReceiptHistoryRoute),
      ],
    ),

    // ── Finance & Ledgers ───────────────────────────────────────
    // Renamed from "Accounts & GST"
    // GST has been moved to Reports & Analytics > Taxation group
    SidebarItem(
      title: 'Finance & Ledgers',
      icon: Icons.account_balance_wallet_outlined,
      subItems: [
        MenuItemData(AppRoutes.cashBookRoute),
        MenuItemData(AppRoutes.bankBookRoute),
        MenuItemData(AppRoutes.expenseEntryRoute),
        MenuItemData(AppRoutes.journalEntryRoute),
      ],
    ),

    // ── Reports & Analytics ─────────────────────────────────────
    // Flat sidebar (Option A) — logical order:
    //   Daily Activity → Trading & Inventory → Financials → Taxation
    SidebarItem(
      title: 'Reports & Analytics',
      icon: Icons.assessment_outlined,
      subItems: [
        MenuItemData(AppRoutes.dayBookRoute), // Daily Activity
        MenuItemData(AppRoutes.salesReportRoute), // Trading
        MenuItemData(AppRoutes.purchaseReportRoute), // Trading
        MenuItemData(AppRoutes.profitLossRoute), // Financials
        MenuItemData(AppRoutes.gstReportRoute), // Taxation
      ],
    ),

    // ── Schemes (Kitty) ─────────────────────────────────────────
    SidebarItem(
      title: 'Schemes (Kitty)',
      icon: Icons.calendar_month_outlined,
      subItems: [
        MenuItemData(AppRoutes.newSchemeRoute),
        MenuItemData(AppRoutes.monthlyCollectionRoute),
      ],
    ),
  ];
}
