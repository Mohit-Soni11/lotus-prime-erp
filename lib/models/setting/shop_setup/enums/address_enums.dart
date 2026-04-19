// -----------------------------------------------------------------------------
// FILE: address_enums.dart
// TYPE: Core Foundation / Enums
// AUTHOR: Senior System Architect
// DESCRIPTION: Type-safe enumerations for the Address module to prevent typo crashes.
// -----------------------------------------------------------------------------

/// Represents the classification of the physical address.
enum AddressType {
  headOffice("Head Office"),
  branchOffice("Branch Office"),
  warehouse("Warehouse");

  final String label;
  const AddressType(this.label);

  /// Safely parse from API string to prevent runtime crashes.
  /// Provides a safe fallback to [AddressType.headOffice] if the value is unknown.
  static AddressType fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AddressType.headOffice;
    }

    final sanitizedValue = value.trim().toLowerCase().replaceAll(' ', '');

    switch (sanitizedValue) {
      case 'headoffice':
        return AddressType.headOffice;
      case 'branchoffice':
        return AddressType.branchOffice;
      case 'warehouse':
        return AddressType.warehouse;
      default:
        return AddressType.headOffice; 
    }
  }
}