// =============================================================================
// FILE        : karigar_directory_enums.dart
// MODULE      : Karigar → Karigar Directory
// LAYER       : Models / Enums
// DESCRIPTION : Enums for filter, sort, and screen state in the
//               Karigar Directory list screen.
// =============================================================================

// ── 1. FILTER ─────────────────────────────────────────────────────────────────
enum KarigarDirectoryFilter {
  all('All'),
  active('Active'),
  inactive('Inactive'),
  withJobs('With Jobs');

  final String label;
  const KarigarDirectoryFilter(this.label);
}

// ── 2. SORT ───────────────────────────────────────────────────────────────────
enum KarigarDirectorySort {
  nameAsc('Name A–Z'),
  newest('Newest First'),
  mostJobs('Most Active Jobs'),
  highestBalance('Highest Balance');

  final String label;
  const KarigarDirectorySort(this.label);
}

// ── 3. SCREEN STATE ───────────────────────────────────────────────────────────
enum KarigarDirectoryState {
  loading,
  loaded,
  empty,
  error,
  searching,
}
