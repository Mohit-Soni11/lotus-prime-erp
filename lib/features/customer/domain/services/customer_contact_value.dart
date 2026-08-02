class CustomerContactValue {
  const CustomerContactValue._();

  static bool isInternalWalkInKey(String value) {
    return value.trim().toUpperCase().startsWith('WALKIN-');
  }

  static String displayMobile(String value) {
    return isInternalWalkInKey(value) ? '' : value.trim();
  }

  static String storageMobile(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isNotEmpty) return clean;
    return 'WALKIN-${DateTime.now().microsecondsSinceEpoch}';
  }
}
