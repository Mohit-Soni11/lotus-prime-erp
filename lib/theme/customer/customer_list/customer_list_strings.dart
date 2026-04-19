// -----------------------------------------------------------------------------
// FILE: customer_list_strings.dart
// MODULE: Customer → Customer List
// -----------------------------------------------------------------------------
 
class CustomerListStrings {
  CustomerListStrings._();
 
  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const String appBarTitle     = "CLIENT DIRECTORY";
  static const String systemOnline    = "SYSTEM ONLINE";
  static const String shopName        = "Lotus Jewellers";
 
  // ── PAGE HEADER ───────────────────────────────────────────────────────────
  static const String pageTitle       = "Client Directory";
  static const String pageSubtitle    = "Manage and view all registered clients";
 
  // ── SEARCH & FILTER ───────────────────────────────────────────────────────
  static const String searchHint      = "Search by name, mobile, or city...";
  static const String filterAll       = "All";
  static const String filterVip       = "Elite"; // VIP is now Elite
  static const String filterRegular   = "Standard"; // Regular is now Standard
  static const String filterToday     = "Today";
  static const String sortBy          = "Sort By";
 
  // ── STATS STRIP ───────────────────────────────────────────────────────────
  static const String totalCustomers  = "Total Clients";
  static const String todayNew        = "New Enrollments";
  static const String vipCount        = "Elite Members";
  static const String activeClients   = "Active"; // For circular graph
 
  // ── CUSTOMER CARD ─────────────────────────────────────────────────────────
  static const String mobile          = "Mobile";
  static const String city            = "City";
  static const String since           = "Since";
  static const String bills           = "Invoices"; // Bills changed to Invoices
  static const String viewDetails     = "View Details";
  static const String noCity          = "City N/A";
  static const String noBills         = "0";
 
  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  static const String emptyTitle      = "No Clients Found";
  static const String emptySubtitle   = "Add your first client to get started";
  static const String noResultTitle   = "No Results";
  static const String noResultSub     = "Try a different search term";
  static const String addFirst        = "Add Client";
 
  // ── BUTTONS ───────────────────────────────────────────────────────────────
  static const String btnAddNew       = "Add New Client";
  static const String btnRefresh      = "Refresh";
 
  // ── SNACKBARS ─────────────────────────────────────────────────────────────
  static const String refreshDone     = "Client directory refreshed";
  static const String loadError       = "Failed to load clients";
}