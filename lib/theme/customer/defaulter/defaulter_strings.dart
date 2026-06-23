// ==========================================
// FILE: defaulter_strings.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: All UI text constants. Enables future localization.
// ==========================================

class DefaulterStrings {
  DefaulterStrings._();

  // --- SYSTEM SHELL ---
  static const String systemOnline = 'SYSTEM ONLINE';
  static const String moduleTitle = 'RISK & COLLECTIONS';
  static const String moduleSubtitle =
      'Girvi exposure, collection priority and settlement control';

  // --- STATS PANEL ---
  static const String statTotal = 'Risk Accounts';
  static const String statTotalDue = 'Collection Due';
  static const String statCritical = 'Critical Cases';
  static const String statPrincipal = 'Principal at Risk';
  static const String statReceived = 'Collected';
  static const String statSuffix = 'Open';

  // --- FILTER BAR ---
  static const String searchHint =
      'Search customer, mobile, ticket, item or city';
  static const String filterAll = 'All Accounts';
  static const String filterCritical = 'Critical';
  static const String filterHigh = 'High Risk';
  static const String filterMedium = 'Watchlist';
  static const String filterLow = 'Early Risk';
  static const String filterOverdue = 'Overdue';
  static const String filterSettlement = 'Settlement Pending';
  static const String sortBy = 'Sort:';
  static const String sortOverdue = 'Risk Age';
  static const String sortAmount = 'Exposure';
  static const String sortName = 'Customer';
  static const String sortRecent = 'Recent Activity';

  // --- TABLE HEADERS ---
  static const String colCustomer = 'CUSTOMER';
  static const String colRisk = 'RISK';
  static const String colReference = 'TICKET';
  static const String colPrincipal = 'PRINCIPAL';
  static const String colInterest = 'INTEREST';
  static const String colTotalDue = 'TOTAL DUE';
  static const String colDays = 'AGE';
  static const String colActions = 'ACTIONS';

  // --- RISK LABELS ---
  static const String riskCritical = 'CRITICAL';
  static const String riskHigh = 'HIGH RISK';
  static const String riskMedium = 'WATCHLIST';
  static const String riskLow = 'EARLY RISK';

  // --- DAYS OVERDUE LABELS ---
  static const String daysUnit = 'days';
  static const String daysOverdueLabel = 'overdue';
  static const String daysFormat = '%d days';

  // --- AMOUNT FORMAT ---
  static const String rupeeSymbol = '₹';
  static const String interestRateUnit = '% monthly';

  // --- ACTION BUTTONS ---
  static const String btnCall = 'Show Mobile';
  static const String btnNotify = 'Copy WhatsApp/SMS Reminder';
  static const String btnView = 'Open Account';
  static const String btnInterest = 'Collect Interest';

  // --- EMPTY STATE ---
  static const String emptyTitle = 'No Risk Accounts Found';
  static const String emptySubtitle =
      'All Girvi accounts are currently under control.\nNo overdue collection risk found.';
  static const String emptySearch = 'No results match your search.';
  static const String emptyFilter = 'No risk accounts in this category.';

  // --- LOADING ---
  static const String loadingData = 'Loading collection risk data...';
  static const String refreshing = 'Refreshing...';

  // --- TOOLTIPS ---
  static const String tooltipRefresh = 'Refresh Data';
  static const String tooltipExport = 'Export Report';
  static const String tooltipSort = 'Sort List';
  static const String tooltipFilter = 'Filter';

  // --- SNACKBARS ---
  static const String callInitiated = 'Opening phone dialer...';
  static const String copySuccess = 'Mobile number copied!';
  static const String noticeCopySuccess = 'Collection notice copied.';
  static const String exportSuccess = 'Report exported successfully.';

  // --- INTEREST CALCULATION INFO ---
  static const String interestNote = 'Simple Interest @ ';
  static const String interestPer = '% per month';
}
