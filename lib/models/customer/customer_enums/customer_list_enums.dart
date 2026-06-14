// -----------------------------------------------------------------------------
// FILE: customer_list_enums.dart
// MODULE: Customer -> Customer List
// DESCRIPTION: Type-safe values for filters, sorting, and activity labels.
// -----------------------------------------------------------------------------

enum CustomerFilter {
  all,
  standard,
  silver,
  gold,
  elite,
  today;

  String get label {
    switch (this) {
      case CustomerFilter.all:
        return "All";
      case CustomerFilter.standard:
        return "Standard";
      case CustomerFilter.silver:
        return "Silver";
      case CustomerFilter.gold:
        return "Gold";
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
  standard("Regular", "Standard"),
  silver("Silver", "Silver"),
  gold("Gold", "Gold"),
  elite("VIP", "Elite");

  /// Stable database label. Keep this compatible with existing saved records.
  final String value;
  final String displayLabel;

  const CustomerType(this.value, this.displayLabel);

  static CustomerType fromString(String? value) {
    final normalized = value?.trim().toLowerCase();
    switch (normalized) {
      case 'vip':
      case 'elite':
        return CustomerType.elite;
      case 'gold':
        return CustomerType.gold;
      case 'silver':
        return CustomerType.silver;
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
