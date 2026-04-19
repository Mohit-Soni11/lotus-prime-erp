// ==========================================
// FILE: defaulter_strings.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: All UI text constants. Enables future localization.
// ==========================================

class DefaulterStrings {
  DefaulterStrings._();

  // --- SYSTEM SHELL ---
  static const String systemOnline      = 'SYSTEM ONLINE';
  static const String moduleTitle       = 'DEFAULTER LIST';
  static const String moduleSubtitle    = 'Overdue Loans & Pending Dues';

  // --- STATS PANEL ---
  static const String statTotal         = 'Total Defaulters';
  static const String statTotalDue      = 'Total Amount Due';
  static const String statCritical      = 'Critical Cases';
  static const String statSuffix        = 'Accounts';

  // --- FILTER BAR ---
  static const String searchHint        = 'Search by name or mobile...';
  static const String filterAll         = 'All';
  static const String filterCritical    = 'Critical';
  static const String filterHigh        = 'High Risk';
  static const String filterMedium      = 'Medium';
  static const String filterLow         = 'Low';
  static const String filterLoan        = 'Loan Dues';
  static const String sortBy            = 'Sort:';
  static const String sortOverdue       = 'Days Overdue';
  static const String sortAmount        = 'Amount';
  static const String sortName          = 'Name';

  // --- TABLE HEADERS ---
  static const String colCustomer       = 'CUSTOMER';
  static const String colRisk           = 'RISK';
  static const String colReference      = 'REF NO.';
  static const String colPrincipal      = 'PRINCIPAL';
  static const String colInterest       = 'INTEREST';
  static const String colTotalDue       = 'TOTAL DUE';
  static const String colDays           = 'DAYS OVERDUE';
  static const String colActions        = 'ACTIONS';

  // --- RISK LABELS ---
  static const String riskCritical      = 'CRITICAL';
  static const String riskHigh          = 'HIGH';
  static const String riskMedium        = 'MEDIUM';
  static const String riskLow           = 'LOW';

  // --- DAYS OVERDUE LABELS ---
  static const String daysUnit          = 'days';
  static const String daysOverdueLabel  = 'overdue';
  static const String daysFormat        = '%d days';

  // --- AMOUNT FORMAT ---
  static const String rupeeSymbol       = '₹';
  static const String interestRateUnit  = '% / mo';

  // --- ACTION BUTTONS ---
  static const String btnCall           = 'Call';
  static const String btnNotify         = 'Notify';
  static const String btnView           = 'View';

  // --- EMPTY STATE ---
  static const String emptyTitle        = 'No Defaulters Found';
  static const String emptySubtitle     = 'All customers are up to date.\nNo overdue loans or pending dues.';
  static const String emptySearch       = 'No results match your search.';
  static const String emptyFilter       = 'No defaulters in this category.';

  // --- LOADING ---
  static const String loadingData       = 'Loading defaulter data...';
  static const String refreshing        = 'Refreshing...';

  // --- TOOLTIPS ---
  static const String tooltipRefresh    = 'Refresh Data';
  static const String tooltipExport     = 'Export Report';
  static const String tooltipSort       = 'Sort List';
  static const String tooltipFilter     = 'Filter';

  // --- SNACKBARS ---
  static const String callInitiated     = 'Opening phone dialer...';
  static const String copySuccess       = 'Mobile number copied!';
  static const String exportSuccess     = 'Report exported successfully.';

  // --- INTEREST CALCULATION INFO ---
  static const String interestNote      = 'Simple Interest @ ';
  static const String interestPer       = '% per month';
}