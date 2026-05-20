// -----------------------------------------------------------------------------
// FILE: banking_enums.dart
// TYPE: Enumerations
// AUTHOR: Senior System Architect
// DESCRIPTION: Strongly typed enums for banking module to prevent string-typo bugs.
// -----------------------------------------------------------------------------

enum BankAccountType {
  current("Current"),
  savings("Savings"),
  overdraft("OD / CC");

  final String displayName;
  const BankAccountType(this.displayName);

  // Safely parse from API or local storage strings
  static BankAccountType fromString(String? value) {
    if (value == null || value.trim().isEmpty) return BankAccountType.current;

    final sanitizedValue = value.trim().toLowerCase();

    return BankAccountType.values.firstWhere(
      (e) =>
          e.displayName.toLowerCase() == sanitizedValue ||
          e.name.toLowerCase() == sanitizedValue,
      orElse: () => BankAccountType.current,
    );
  }
}
