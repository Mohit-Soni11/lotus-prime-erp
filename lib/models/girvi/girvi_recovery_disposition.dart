enum GirviRecoveryDisposition {
  melted('MELTED', 'Melted'),
  sold('SOLD', 'Sold');

  const GirviRecoveryDisposition(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static GirviRecoveryDisposition? fromDb(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final disposition in values) {
      if (disposition.dbValue == normalized) return disposition;
    }
    return null;
  }

  static GirviRecoveryDisposition? fromItemStatuses(
      Iterable<String?> statuses) {
    final resolved = statuses.map(fromDb).toList(growable: false);
    if (resolved.isEmpty || resolved.any((value) => value == null)) {
      return null;
    }
    final distinct = resolved.toSet();
    return distinct.length == 1 ? distinct.single : null;
  }
}
