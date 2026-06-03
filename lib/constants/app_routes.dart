// =============================================================================
// FILE        : app_routes.dart
// LAYER       : Constants
// DESCRIPTION : Central route registry for all ERP modules.
//
// CHANGELOG:
//   v1 — Initial routes
//   v2 — Cash Book route added
//   v3 — Architecture overhaul:
//          • "Accounts & GST" renamed to "Finance & Ledgers"
//          • GST Returns removed from Finance — moved to Reports as "GST Report"
//          • Journal Entry added to Finance & Ledgers
//          • Purchase Report added to Reports & Analytics
//          • karigarHisaabRoute renamed to karigarLedgerRoute (consistent naming)
//          • Finance routes migrated from /accounts/* to /finance/*
//   v4 — Girvi Module routes confirmed & display titles verified
//   v5 — Supplier Module routes merged from separate branch
//   v7 — Delivery Management module:
//          • 'Delivery Dues' (deliveryDueRoute) removed
//          • 'Order Delivery' (orderDeliveryRoute) removed
//          • Merged into single 'Delivery Management' (deliveryManagementRoute)
//   v8 — Billing Setup module:
//          • billingSetupRoute added under Settings
// =============================================================================

class AppRoutes {
  // ============================================================
  // CORE NAVIGATION
  // ============================================================
  static const String dashboardRoute = '/dashboard';
  static const String settingsRoute = '/settings';
  static const String exitAppRoute = '/exit_app';
  static const String accountProfileRoute = '/account/profile';

  // ============================================================
  // SETTINGS MODULE
  // ============================================================
  static const String billingSetupRoute = '/settings/billing-setup'; // ✅ v8

  // ============================================================
  // CUSTOMER MODULE
  // ============================================================
  static const String customerListRoute = '/customer/list';
  static const String addCustomerRoute = '/customer/add';
  static const String customerProfileRoute = '/customer/profile';
  static const String creditLimitRoute = '/customer/credit_limit';
  static const String defaulterListRoute = '/customer/defaulters';

  // ============================================================
  // SUPPLIER MODULE
  // ============================================================
  static const String supplierListRoute = '/supplier/list';
  static const String addSupplierRoute = '/supplier/add';

  // ============================================================
  // SALES & ORDERS MODULE
  // ============================================================
  static const String newSaleRoute = '/sales/new';
  static const String bookingAdvanceRoute = '/sales/booking';
  static const String deliveryManagementRoute = '/sales/delivery';

  // ============================================================
  // PURCHASE & OLD GOLD MODULE
  // ============================================================
  static const String purchaseEntryRoute = '/purchase/entry';
  static const String oldGoldBuyRoute = '/purchase/old_gold';
  static const String purchaseReturnRoute = '/purchase/return';

  // ============================================================
  // STOCK & INVENTORY MODULE
  // ============================================================
  static const String inventoryRoute = '/stock/inventory';
  static const String addStockRoute = '/stock/add';
  static const String barcodePrintRoute = '/stock/barcode';
  static const String stockTransferRoute = '/stock/transfer';
  static const String lowStockAlertRoute = '/stock/low_alert';

  // ============================================================
  // KARIGAR MODULE
  // ============================================================
  static const String issueToKarigarRoute = '/karigar/issue';
  static const String receiveFromKarigarRoute = '/karigar/receive';
  static const String pendingJobsRoute = '/karigar/pending';
  static const String karigarLedgerRoute = '/karigar/ledger';

  // ============================================================
  // GIRVI / PAWN LOAN MODULE
  // ✅ All 4 routes wired in main_layout_wrapper.dart v5
  //    newGirviRoute      → NewGirviScreen
  //    girviReleaseRoute  → GirviListScreen (release happens inside)
  //    interestCalcRoute  → InterestCalcScreen
  //    noticeAuctionRoute → NoticeAuctionScreen
  // ============================================================
  static const String newGirviRoute = '/girvi/new';
  static const String girviReleaseRoute = '/girvi/release';
  static const String interestCalcRoute = '/girvi/interest';
  static const String noticeAuctionRoute = '/girvi/notice';

  // ============================================================
  // FINANCE & LEDGERS MODULE
  // (Renamed from "Accounts & GST" — GST moved to Reports & Analytics)
  // ============================================================
  static const String cashBookRoute = '/finance/cashbook'; // ✅ LIVE
  static const String bankBookRoute = '/finance/bankbook';
  static const String expenseEntryRoute = '/finance/expense'; // ✅ LIVE
  static const String journalEntryRoute = '/finance/journal';
  static const String dueReportRoute = '/finance/due/report';
  static const String dueCollectionRoute = '/finance/due/collection';
  static const String dueReceiptHistoryRoute = '/finance/due/receipts';

  // ============================================================
  // REPORTS & ANALYTICS MODULE
  //
  // Logical Groups (flat sidebar — Option A):
  //   Daily Activity  → dayBookRoute
  //   Trading         → salesReportRoute, purchaseReportRoute, stockSummaryRoute
  //   Financials      → profitLossRoute
  //   Taxation        → gstReportRoute
  // ============================================================
  static const String dayBookRoute = '/reports/daybook';
  static const String salesReportRoute = '/reports/sales';
  static const String purchaseReportRoute = '/reports/purchase';
  static const String stockSummaryRoute = '/reports/stock';
  static const String profitLossRoute = '/reports/pnl';
  static const String gstReportRoute = '/reports/gst';

  // ============================================================
  // SCHEMES (KITTY) MODULE
  // ============================================================
  static const String newSchemeRoute = '/schemes/new';
  static const String monthlyCollectionRoute = '/schemes/collection';

  // ============================================================
  // DISPLAY TITLES — User Interface Labels
  // ============================================================
  static const Map<String, String> _displayTitles = {
    // Core
    dashboardRoute: 'Dashboard',
    settingsRoute: 'Settings',
    exitAppRoute: 'Exit Application',
    accountProfileRoute: 'My Account',

    // Settings
    billingSetupRoute: 'Billing Setup', // ✅ v8

    // Customer
    customerListRoute: 'Customer List',
    addCustomerRoute: 'Add New Customer',
    customerProfileRoute: 'Customer Profile',
    creditLimitRoute: 'Set Credit Limits',
    defaulterListRoute: 'Defaulter List',

    // Supplier
    supplierListRoute: 'Supplier List',
    addSupplierRoute: 'Add New Supplier',

    // Sales & Orders
    newSaleRoute: 'New Sale (POS)',
    bookingAdvanceRoute: 'Booking & Advance',
    deliveryManagementRoute: 'Delivery Management',

    // Purchase & Old Gold
    purchaseEntryRoute: 'Purchase Entry',
    oldGoldBuyRoute: 'Old Gold Purchase',
    purchaseReturnRoute: 'Purchase Return',

    // Stock & Inventory
    inventoryRoute: 'Inventory Ledger',
    addStockRoute: 'Add Stock',
    barcodePrintRoute: 'Print Barcodes',
    stockTransferRoute: 'Stock Transfer',
    lowStockAlertRoute: 'Low Stock Alerts',

    // Karigar
    issueToKarigarRoute: 'Issue to Karigar',
    receiveFromKarigarRoute: 'Receive from Karigar',
    pendingJobsRoute: 'Pending Jobs',
    karigarLedgerRoute: 'Karigar Ledger',

    // Girvi / Pawn Loan ✅
    newGirviRoute: 'New Girvi Ticket',
    girviReleaseRoute: 'Girvi Ledger',
    interestCalcRoute: 'Interest Calculator',
    noticeAuctionRoute: 'Notice & Auction',

    // Finance & Ledgers
    cashBookRoute: 'Cash Book',
    bankBookRoute: 'Bank Book',
    expenseEntryRoute: 'Expense Entry',
    journalEntryRoute: 'Journal Entry',
    dueReportRoute: 'Due Report',
    dueCollectionRoute: 'Due Collection Entry',
    dueReceiptHistoryRoute: 'Due Receipt History',

    // Reports & Analytics
    dayBookRoute: 'Day Book',
    salesReportRoute: 'Sales Report',
    purchaseReportRoute: 'Purchase Report',
    stockSummaryRoute: 'Stock Summary',
    profitLossRoute: 'Profit & Loss',
    gstReportRoute: 'GST Report',

    // Schemes
    newSchemeRoute: 'New Scheme',
    monthlyCollectionRoute: 'Monthly Collection',
  };

  // ============================================================
  // HELPER
  // ============================================================
  static String getTitle(String routeId) {
    return _displayTitles[routeId] ?? 'Unknown Page';
  }
}
