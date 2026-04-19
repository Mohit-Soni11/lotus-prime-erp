// -----------------------------------------------------------------------------
// FILE: tax_gst_enums.dart
// TYPE: Core / Foundation
// AUTHOR: Senior System Architect
// DESCRIPTION: Strongly typed enums for Tax and GST configurations to prevent
//              typos, manage UI states, and ensure type safety across the module.
// -----------------------------------------------------------------------------

/// Defines the classification of the taxpayer.
enum TaxpayerType {
  regular('Regular'),
  composition('Composition'),
  consumer('Consumer'),
  overseas('Overseas');

  final String displayName;
  
  const TaxpayerType(this.displayName);

  /// Safely parses string from API/Database to Enum.
  /// Defaults to [TaxpayerType.regular] if the string doesn't match.
  static TaxpayerType fromString(String? value) {
    if (value == null || value.trim().isEmpty) return TaxpayerType.regular;
    
    return TaxpayerType.values.firstWhere(
      (type) => type.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => TaxpayerType.regular,
    );
  }
}

/// Defines the current interaction state of a specific form section.
/// This eliminates the need for multiple confusing boolean flags.
enum SectionEditState {
  locked,   // Read-only state, inputs are disabled
  editing,  // User is actively modifying the fields
  saving    // Async operation in progress, show loading spinner
}