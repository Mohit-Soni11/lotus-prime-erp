// =============================================================================
// FILE        : karigar_directory_strings.dart
// =============================================================================

class KarigarDirectoryStrings {
  KarigarDirectoryStrings._();

  // AppBar
  static const String screenTitle = 'Karigar Directory';
  static const String screenSub = 'Artisan Management';
  static const String moduleBadge = 'KARIGAR MODULE';
  static const String systemOnline = 'SYSTEM ONLINE';

  // Stats
  static const String statTotalActive = 'Active Karigars';
  static const String statNewMonth = 'New This Month';
  static const String statWithJobs = 'With Active Jobs';
  static const String statOutstanding = 'Outstanding (₹)';

  // Search
  static const String searchHint =
      'Search by name, phone, city or specialization...';

  // Filter chips
  static const String filterAll = 'All';
  static const String filterActive = 'Active';
  static const String filterInactive = 'Inactive';
  static const String filterJobs = 'With Jobs';

  // FAB
  static const String btnAddNew = 'Add Karigar';

  // Result count
  static String resultCount(int n) => '$n Karigar${n == 1 ? '' : 's'} found';

  // Empty
  static const String emptyTitle = 'No Karigars Yet';
  static const String emptySubtitle = 'Add your first karigar to get started.';
  static const String noResultTitle = 'No Matches Found';
  static const String noResultSub = 'Try a different name, phone or city.';
  static const String addFirst = 'Add First Karigar';
  static const String btnRefresh = 'Retry';

  // Card
  static const String activeJobs = 'active jobs';
  static const String overdueLabel = 'OVERDUE';
  static const String memberSince = 'Since';
  static const String statusActive = 'ACTIVE';
  static const String statusInactive = 'INACTIVE';
  static const String noCity = '—';

  // Confirm deactivate
  static const String deactivateTitle = 'Deactivate Karigar?';
  static String deactivateBody(String name) =>
      'Deactivating $name will hide them from new job assignments. Historical data is preserved.';
  static const String btnDeactivate = 'Deactivate';
  static const String btnCancel = 'Cancel';
  static const String btnActivate = 'Activate';
}
