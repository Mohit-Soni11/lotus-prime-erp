// =============================================================================
// FILE        : app_routes.dart
// LAYER       : Constants / Navigation
// DESCRIPTION : Single source of truth for route IDs, router paths, page titles,
//               and menu-to-router mapping.
// =============================================================================

class AppRoutes {
  AppRoutes._();

  // Core navigation IDs
  static const String dashboardRoute = '/dashboard';
  static const String settingsRoute = '/settings';
  static const String exitAppRoute = '/exit_app';
  static const String accountProfileRoute = '/account/profile';

  // Settings
  static const String billingSetupRoute = '/settings/billing-setup';
  static const String printTemplatesRoute = '/settings/print-templates';

  // Customer
  static const String customerListRoute = '/customer/list';
  static const String addCustomerRoute = '/customer/add';
  static const String customerProfileRoute = '/customer/profile';
  static const String creditLimitRoute = '/customer/credit-limit';
  static const String defaulterListRoute = '/customer/defaulters';

  // Supplier
  static const String supplierListRoute = '/supplier/list';
  static const String addSupplierRoute = '/supplier/add';

  // Sales
  static const String newSaleRoute = '/sales/pos';
  static const String bookingAdvanceRoute = '/sales/booking';
  static const String deliveryManagementRoute = '/sales/delivery';

  // Purchase
  static const String purchaseEntryRoute = '/purchase/entry';
  static const String oldGoldBuyRoute = '/purchase/old-gold';
  static const String purchaseReturnRoute = '/purchase/return';

  // Stock
  static const String inventoryRoute = '/stock/inventory';
  static const String stockSummaryRoute = '/stock/summary';
  static const String stockActivityRoute = '/stock/activity';
  static const String stockSearchRoute = '/stock/search';
  static const String stockValuationRoute = '/stock/valuation';
  static const String addStockRoute = '/stock/add';
  static const String barcodePrintRoute = '/stock/barcode';
  static const String stockTransferRoute = '/stock/transfer';
  static const String lowStockAlertRoute = '/stock/low-alert';

  // Karigar
  static const String issueToKarigarRoute = '/karigar/issue';
  static const String receiveFromKarigarRoute = '/karigar/receive';
  static const String pendingJobsRoute = '/karigar/pending';
  static const String karigarLedgerRoute = '/karigar/ledger';

  // Girvi / pawn loan
  static const String newGirviRoute = '/girvi/new';
  static const String girviReleaseRoute = '/girvi/ledger';
  static const String interestCalcRoute = '/girvi/interest';
  static const String noticeAuctionRoute = '/girvi/notice';

  // Finance
  static const String cashBookRoute = '/finance/cashbook';
  static const String bankBookRoute = '/finance/bankbook';
  static const String expenseEntryRoute = '/finance/expense';
  static const String journalEntryRoute = '/finance/journal';
  static const String dueReportRoute = '/finance/due-report';
  static const String dueCollectionRoute = '/finance/due-collection';
  static const String dueReceiptHistoryRoute = '/finance/due-receipts';

  // Reports
  static const String dayBookRoute = '/reports/daybook';
  static const String salesReportRoute = '/reports/sales';
  static const String purchaseReportRoute = '/reports/purchase';
  static const String profitLossRoute = '/reports/pnl';
  static const String gstReportRoute = '/reports/gst';

  // Schemes
  static const String newSchemeRoute = '/schemes/new';
  static const String monthlyCollectionRoute = '/schemes/collection';

  static const Map<String, String> _titles = {
    dashboardRoute: 'Dashboard',
    settingsRoute: 'Settings',
    exitAppRoute: 'Exit Application',
    accountProfileRoute: 'My Account',
    billingSetupRoute: 'Billing Setup',
    printTemplatesRoute: 'Print Templates',
    customerListRoute: 'Customer List',
    addCustomerRoute: 'Add New Customer',
    customerProfileRoute: 'Customer Profile',
    creditLimitRoute: 'Set Credit Limits',
    defaulterListRoute: 'Risk & Collections',
    supplierListRoute: 'Supplier List',
    addSupplierRoute: 'Add New Supplier',
    newSaleRoute: 'New Sale (POS)',
    bookingAdvanceRoute: 'Booking & Advance',
    deliveryManagementRoute: 'Delivery Management',
    purchaseEntryRoute: 'Purchase Entry',
    oldGoldBuyRoute: 'Old Gold Purchase',
    purchaseReturnRoute: 'Purchase Return',
    inventoryRoute: 'Inventory Ledger',
    stockActivityRoute: 'Stock Activity Ledger',
    stockSearchRoute: 'Stock Search Center',
    stockValuationRoute: 'Stock Valuation',
    addStockRoute: 'Add Stock',
    barcodePrintRoute: 'Print Barcodes',
    stockTransferRoute: 'Stock Transfer',
    lowStockAlertRoute: 'Low Stock Alerts',
    issueToKarigarRoute: 'Issue to Karigar',
    receiveFromKarigarRoute: 'Receive from Karigar',
    pendingJobsRoute: 'Pending Jobs',
    karigarLedgerRoute: 'Karigar Ledger',
    newGirviRoute: 'New Girvi Ticket',
    girviReleaseRoute: 'Girvi Ledger',
    interestCalcRoute: 'Interest Entry',
    noticeAuctionRoute: 'Notice & Auction',
    cashBookRoute: 'Cash Book',
    bankBookRoute: 'Bank Book',
    expenseEntryRoute: 'Expense Entry',
    journalEntryRoute: 'Journal Entry',
    dueReportRoute: 'Due Report',
    dueCollectionRoute: 'Due Collection Entry',
    dueReceiptHistoryRoute: 'Due Receipt History',
    dayBookRoute: 'Day Book',
    salesReportRoute: 'Sales Report',
    purchaseReportRoute: 'Purchase Report',
    stockSummaryRoute: 'Stock Summary',
    profitLossRoute: 'Profit & Loss',
    gstReportRoute: 'GST Report',
    newSchemeRoute: 'New Scheme',
    monthlyCollectionRoute: 'Monthly Collection',
  };

  static String getTitle(String routeId) => _titles[routeId] ?? 'Unknown Page';
}

class RoutePaths {
  RoutePaths._();

  static const String login = '/login';
  static const String app = '/app';

  // Core
  static const String dashboard = '/app/dashboard';
  static const String settings = '/app/settings';
  static const String accountProfile = '/app/account/profile';

  // Settings
  static const String billingSetup = '/app/settings/billing-setup';
  static const String printTemplates = '/app/settings/print-templates';

  // Customer
  static const String customerList = '/app/customer/list';
  static const String customerAdd = '/app/customer/add';
  static const String customerProfileBase = '/app/customer/profile';
  static const String customerProfile = '$customerProfileBase/:id';
  static const String customerCreditLimit = '/app/customer/credit-limit';
  static const String customerDefaulters = '/app/customer/defaulters';

  // Supplier
  static const String supplierList = '/app/supplier/list';
  static const String supplierAdd = '/app/supplier/add';
  static const String supplierProfileBase = '/app/supplier/profile';
  static const String supplierProfile = '$supplierProfileBase/:id';

  // Sales
  static const String salesPos = '/app/sales/pos';
  static const String salesBooking = '/app/sales/booking';
  static const String salesDelivery = '/app/sales/delivery';

  // Purchase
  static const String purchaseEntry = '/app/purchase/entry';
  static const String purchaseOldGold = '/app/purchase/old-gold';
  static const String purchaseReturn = '/app/purchase/return';

  // Stock
  static const String stockInventory = '/app/stock/inventory';
  static const String stockSummary = '/app/stock/summary';
  static const String stockActivity = '/app/stock/activity';
  static const String stockSearch = '/app/stock/search';
  static const String stockValuation = '/app/stock/valuation';
  static const String stockAdd = '/app/stock/add';
  static const String stockBarcode = '/app/stock/barcode';
  static const String stockTransfer = '/app/stock/transfer';
  static const String stockLowAlert = '/app/stock/low-alert';

  // Karigar
  static const String karigarIssue = '/app/karigar/issue';
  static const String karigarReceive = '/app/karigar/receive';
  static const String karigarPending = '/app/karigar/pending';
  static const String karigarLedger = '/app/karigar/ledger';

  // Girvi
  static const String girviNew = '/app/girvi/new';
  static const String girviList = '/app/girvi/list';
  static const String girviAccountBase = '/app/girvi/account';
  static const String girviAccountDetail = '$girviAccountBase/:loanId';
  static const String girviInterest = '/app/girvi/interest';
  static const String girviNotice = '/app/girvi/notice';

  // Finance
  static const String financeCashBook = '/app/finance/cashbook';
  static const String financeBankBook = '/app/finance/bankbook';
  static const String financeExpense = '/app/finance/expense';
  static const String financeJournal = '/app/finance/journal';
  static const String financeDueReport = '/app/finance/due-report';
  static const String financeDueCollection = '/app/finance/due-collection';
  static const String financeDueReceipts = '/app/finance/due-receipts';

  // Reports
  static const String reportDayBook = '/app/reports/daybook';
  static const String reportSales = '/app/reports/sales';
  static const String reportPurchase = '/app/reports/purchase';
  static const String reportPnl = '/app/reports/pnl';
  static const String reportGst = '/app/reports/gst';

  // Schemes
  static const String schemesNew = '/app/schemes/new';
  static const String schemesCollection = '/app/schemes/collection';

  static String customerProfileFor(int customerId) {
    return '$customerProfileBase/$customerId';
  }

  static String supplierProfileFor(int supplierId) {
    return '$supplierProfileBase/$supplierId';
  }

  static String girviAccountFor(int loanId) {
    return '$girviAccountBase/$loanId';
  }
}

class RouteMapper {
  RouteMapper._();

  static const Map<String, String> _pathByRouteId = {
    AppRoutes.dashboardRoute: RoutePaths.dashboard,
    AppRoutes.settingsRoute: RoutePaths.settings,
    AppRoutes.accountProfileRoute: RoutePaths.accountProfile,
    AppRoutes.billingSetupRoute: RoutePaths.billingSetup,
    AppRoutes.printTemplatesRoute: RoutePaths.printTemplates,
    AppRoutes.customerListRoute: RoutePaths.customerList,
    AppRoutes.addCustomerRoute: RoutePaths.customerAdd,
    AppRoutes.creditLimitRoute: RoutePaths.customerCreditLimit,
    AppRoutes.defaulterListRoute: RoutePaths.customerDefaulters,
    AppRoutes.supplierListRoute: RoutePaths.supplierList,
    AppRoutes.addSupplierRoute: RoutePaths.supplierAdd,
    AppRoutes.newSaleRoute: RoutePaths.salesPos,
    AppRoutes.bookingAdvanceRoute: RoutePaths.salesBooking,
    AppRoutes.deliveryManagementRoute: RoutePaths.salesDelivery,
    AppRoutes.purchaseEntryRoute: RoutePaths.purchaseEntry,
    AppRoutes.oldGoldBuyRoute: RoutePaths.purchaseOldGold,
    AppRoutes.purchaseReturnRoute: RoutePaths.purchaseReturn,
    AppRoutes.inventoryRoute: RoutePaths.stockInventory,
    AppRoutes.stockSummaryRoute: RoutePaths.stockSummary,
    AppRoutes.stockActivityRoute: RoutePaths.stockActivity,
    AppRoutes.stockSearchRoute: RoutePaths.stockSearch,
    AppRoutes.stockValuationRoute: RoutePaths.stockValuation,
    AppRoutes.addStockRoute: RoutePaths.stockAdd,
    AppRoutes.barcodePrintRoute: RoutePaths.stockBarcode,
    AppRoutes.stockTransferRoute: RoutePaths.stockTransfer,
    AppRoutes.lowStockAlertRoute: RoutePaths.stockLowAlert,
    AppRoutes.issueToKarigarRoute: RoutePaths.karigarIssue,
    AppRoutes.receiveFromKarigarRoute: RoutePaths.karigarReceive,
    AppRoutes.pendingJobsRoute: RoutePaths.karigarPending,
    AppRoutes.karigarLedgerRoute: RoutePaths.karigarLedger,
    AppRoutes.newGirviRoute: RoutePaths.girviNew,
    AppRoutes.girviReleaseRoute: RoutePaths.girviList,
    AppRoutes.interestCalcRoute: RoutePaths.girviInterest,
    AppRoutes.noticeAuctionRoute: RoutePaths.girviNotice,
    AppRoutes.cashBookRoute: RoutePaths.financeCashBook,
    AppRoutes.bankBookRoute: RoutePaths.financeBankBook,
    AppRoutes.expenseEntryRoute: RoutePaths.financeExpense,
    AppRoutes.journalEntryRoute: RoutePaths.financeJournal,
    AppRoutes.dueReportRoute: RoutePaths.financeDueReport,
    AppRoutes.dueCollectionRoute: RoutePaths.financeDueCollection,
    AppRoutes.dueReceiptHistoryRoute: RoutePaths.financeDueReceipts,
    AppRoutes.dayBookRoute: RoutePaths.reportDayBook,
    AppRoutes.salesReportRoute: RoutePaths.reportSales,
    AppRoutes.purchaseReportRoute: RoutePaths.reportPurchase,
    AppRoutes.profitLossRoute: RoutePaths.reportPnl,
    AppRoutes.gstReportRoute: RoutePaths.reportGst,
    AppRoutes.newSchemeRoute: RoutePaths.schemesNew,
    AppRoutes.monthlyCollectionRoute: RoutePaths.schemesCollection,
  };

  static final Map<String, String> _routeIdByPath = {
    for (final entry in _pathByRouteId.entries) entry.value: entry.key,
    RoutePaths.customerProfileBase: AppRoutes.customerListRoute,
    RoutePaths.supplierProfileBase: AppRoutes.supplierListRoute,
  };

  static String toPath(String routeId, {int? entityId}) {
    if (routeId == AppRoutes.customerProfileRoute && entityId != null) {
      return RoutePaths.customerProfileFor(entityId);
    }
    return _pathByRouteId[routeId] ?? RoutePaths.dashboard;
  }

  static String toRouteId(String location) {
    final parsedPath = Uri.tryParse(location)?.path ?? location;
    final normalizedPath = parsedPath.replaceAll(RegExp(r'/\d+$'), '');
    return _routeIdByPath[normalizedPath] ?? AppRoutes.dashboardRoute;
  }
}
