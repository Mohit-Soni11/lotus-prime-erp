// -----------------------------------------------------------------------------
// FILE: supplier_list_strings.dart
// MODULE: Supplier → Supplier List
// -----------------------------------------------------------------------------

class SupplierListStrings {
  SupplierListStrings._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const String appBarTitle    = 'SUPPLIER DIRECTORY';
  static const String systemOnline   = 'SYSTEM ONLINE';
  static const String shopName       = 'Lotus Jewellers';

  // ── PAGE HEADER ───────────────────────────────────────────────────────────
  static const String pageTitle      = 'Supplier Directory';
  static const String pageSubtitle   = 'Manage all registered suppliers & manufacturers';

  // ── SEARCH & FILTER ───────────────────────────────────────────────────────
  static const String searchHint     = 'Search by name, mobile, or GST...';
  static const String filterAll      = 'All';

  // ── STATS STRIP ───────────────────────────────────────────────────────────
  static const String totalSuppliers = 'Total Suppliers';
  static const String todayNew       = 'New Today';
  static const String manufacturerCount = 'Manufacturers';

  // ── SUPPLIER CARD ─────────────────────────────────────────────────────────
  static const String mobile         = 'Mobile';
  static const String gstLabel       = 'GST';
  static const String viewDetails    = 'View Details';
  static const String noGst          = 'GST N/A';

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  static const String emptyTitle     = 'No Suppliers Found';
  static const String emptySubtitle  = 'Add your first supplier to get started';
  static const String noResultTitle  = 'No Results';
  static const String noResultSub    = 'Try a different search term';
  static const String addFirst       = 'Add Supplier';

  // ── BUTTONS ───────────────────────────────────────────────────────────────
  static const String btnAddNew      = 'Add New Supplier';
  static const String btnRefresh     = 'Refresh';

  // ── DEACTIVATE DIALOG ─────────────────────────────────────────────────────
  static const String deactivateTitle   = 'Deactivate Supplier?';
  static const String deactivateBody    = 'This supplier will be marked as inactive and removed from active lists.';
  static const String deactivateConfirm = 'Deactivate';
  static const String deactivateCancel  = 'Cancel';

  // ── SNACKBARS ─────────────────────────────────────────────────────────────
  static const String refreshDone    = 'Supplier directory refreshed';
  static const String loadError      = 'Failed to load suppliers';
  static const String deactivateDone = 'Supplier deactivated';
}