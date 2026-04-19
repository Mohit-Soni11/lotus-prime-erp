// =============================================================================
// FILE        : supplier_enums.dart
// MODULE      : Supplier
// LAYER       : Models / Enums
// DESCRIPTION : All enums for Supplier module. Single source of truth.
//               Pattern identical to stock_enums.dart.
// =============================================================================

enum SupplierType {
  manufacturer('Manufacturer'),
  wholesaler('Wholesaler'),
  retailer('Retailer'),
  individual('Individual');

  final String label;
  const SupplierType(this.label);

  static SupplierType fromLabel(String l) =>
      SupplierType.values.firstWhere(
        (e) => e.label == l,
        orElse: () => SupplierType.manufacturer,
      );

  static List<String> get labels =>
      SupplierType.values.map((e) => e.label).toList();
}

enum SupplierStatus {
  active('Active'),
  inactive('Inactive');

  final String label;
  const SupplierStatus(this.label);

  static SupplierStatus fromLabel(String l) =>
      SupplierStatus.values.firstWhere(
        (e) => e.label == l,
        orElse: () => SupplierStatus.active,
      );
}

/// Filter options for Supplier List screen
enum SupplierFilter {
  all('All'),
  manufacturer('Manufacturer'),
  wholesaler('Wholesaler'),
  retailer('Retailer'),
  individual('Individual');

  final String label;
  const SupplierFilter(this.label);
}