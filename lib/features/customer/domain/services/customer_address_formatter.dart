class CustomerAddressFormatter {
  const CustomerAddressFormatter._();

  static String? format({
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String pincode,
    required String country,
  }) {
    if (addressLine1.trim().isEmpty && addressLine2.trim().isEmpty) return null;

    final parts = <String>[
      addressLine1,
      addressLine2,
      city,
      state,
      pincode,
      if (country.trim().toLowerCase() != 'india') country,
    ];
    final seen = <String>{};
    return parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && seen.add(part.toLowerCase()))
        .join(', ');
  }
}
