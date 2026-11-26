class SecurityAccessIdentity {
  const SecurityAccessIdentity({
    required this.shopName,
    required this.logoPath,
    required this.logoShape,
    required this.lastPasswordChangedAt,
  });

  final String shopName;
  final String? logoPath;
  final String logoShape;
  final DateTime? lastPasswordChangedAt;

  String get initials {
    final parts = shopName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    return parts.isEmpty ? 'L' : parts.map((part) => part[0]).join();
  }
}
