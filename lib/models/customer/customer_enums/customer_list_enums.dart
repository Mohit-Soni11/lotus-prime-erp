// -----------------------------------------------------------------------------
// FILE: customer_list_enums.dart
// MODULE: Customer -> Customer List
// DESCRIPTION: Type-safe values for filters, sorting, and activity labels.
// -----------------------------------------------------------------------------

enum CustomerFilter {
  all,
  alert,
  standard,
  elite,
  today;

  String get label {
    switch (this) {
      case CustomerFilter.all:
        return "All";
      case CustomerFilter.alert:
        return "Alert";
      case CustomerFilter.standard:
        return "Standard";
      case CustomerFilter.elite:
        return "Elite";
      case CustomerFilter.today:
        return "Today";
    }
  }
}

enum CustomerSort {
  nameAsc,
  nameDesc,
  newest,
  oldest,
  mostBills;

  String get label {
    switch (this) {
      case CustomerSort.nameAsc:
        return "Name (A-Z)";
      case CustomerSort.nameDesc:
        return "Name (Z-A)";
      case CustomerSort.newest:
        return "Recent Activity";
      case CustomerSort.oldest:
        return "Oldest Activity";
      case CustomerSort.mostBills:
        return "Most Bills";
    }
  }
}

enum CustomerListState {
  loading,
  loaded,
  empty,
  error,
  searching,
}

enum CustomerType {
  standard("Standard", "Standard"),
  alert("Alert", "Alert"),
  elite("Elite", "Elite");

  /// Canonical database label. Legacy labels are accepted by fromString.
  final String value;
  final String displayLabel;

  const CustomerType(this.value, this.displayLabel);

  static CustomerType fromString(String? value) {
    final normalized = value?.trim().toLowerCase();
    switch (normalized) {
      case 'vip':
      case 'elite':
        return CustomerType.elite;
      case 'alert':
        return CustomerType.alert;
      case 'gold':
      case 'silver':
      case 'standard':
      case 'regular':
      default:
        return CustomerType.standard;
    }
  }
}

enum CustomerActivityKind {
  profile("Profile"),
  invoice("Invoice"),
  advance("Advance"),
  girvi("Girvi");

  final String label;
  const CustomerActivityKind(this.label);
}
