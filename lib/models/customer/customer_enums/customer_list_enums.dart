// -----------------------------------------------------------------------------
// FILE: customer_list_enums.dart
// MODULE: Customer → Customer List
// DESCRIPTION: Type-safe enumerations to prevent string-typo bugs.
// -----------------------------------------------------------------------------
 
/// Customer type filter options in the list
enum CustomerFilter {
  all,
  vip,
  regular,
  today;
 
  String get label {
    switch (this) {
      case CustomerFilter.all:     return "All";
      case CustomerFilter.vip:     return "VIP";
      case CustomerFilter.regular: return "Regular";
      case CustomerFilter.today:   return "Today";
    }
  }
}
 
/// Sort options for customer list
enum CustomerSort {
  nameAsc,
  nameDesc,
  newest,
  oldest,
  mostBills;
 
  String get label {
    switch (this) {
      case CustomerSort.nameAsc:   return "Name (A-Z)";
      case CustomerSort.nameDesc:  return "Name (Z-A)";
      case CustomerSort.newest:    return "Newest First";
      case CustomerSort.oldest:    return "Oldest First";
      case CustomerSort.mostBills: return "Most Bills";
    }
  }
}
 
/// Screen loading state
enum CustomerListState {
  loading,
  loaded,
  empty,
  error,
  searching,
}
 
/// Customer type in the system
enum CustomerType {
  vip("VIP"),
  regular("Regular");
 
  final String value;
  const CustomerType(this.value);
 
  static CustomerType fromString(String? val) {
    if (val?.toLowerCase() == 'vip') return CustomerType.vip;
    return CustomerType.regular;
  }
}