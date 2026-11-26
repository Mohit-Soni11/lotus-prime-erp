enum ShopIdentityStatus { configured, notConfigured }

class ShopIdentity {
  const ShopIdentity({
    required this.status,
    required this.displayName,
    required this.ownerName,
    required this.city,
    required this.state,
    required this.mobile,
    required this.email,
    required this.website,
    required this.gstin,
    required this.bisLicense,
    required this.logoPath,
    required this.logoShape,
  });

  const ShopIdentity.notConfigured()
      : status = ShopIdentityStatus.notConfigured,
        displayName = '',
        ownerName = '',
        city = '',
        state = '',
        mobile = '',
        email = '',
        website = '',
        gstin = '',
        bisLicense = '',
        logoPath = null,
        logoShape = 'circle';

  final ShopIdentityStatus status;
  final String displayName;
  final String ownerName;
  final String city;
  final String state;
  final String mobile;
  final String email;
  final String website;
  final String gstin;
  final String bisLicense;
  final String? logoPath;
  final String logoShape;

  bool get isConfigured => status == ShopIdentityStatus.configured;
  bool get hasLogo => (logoPath?.trim() ?? '').isNotEmpty;
  bool get isCircularLogo => logoShape == 'circle';

  String get formattedLocation {
    final parts = [city, state].where((part) => part.trim().isNotEmpty);
    return parts.join(', ');
  }

  String get initials {
    final words = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }
}
