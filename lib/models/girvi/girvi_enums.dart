/// Lifecycle state stored on a Girvi loan.
enum GirviStatus {
  active('ACTIVE', 'Active'),
  released('RELEASED', 'Released'),
  overdue('OVERDUE', 'Overdue'),
  partialRelease('PARTIAL_RELEASE', 'Settlement Pending'),
  readyForDelivery('READY_FOR_DELIVERY', 'Ready for Delivery'),
  auctioned('AUCTIONED', 'Auctioned');

  const GirviStatus(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static GirviStatus fromDb(String value) {
    return GirviStatus.values.firstWhere(
      (status) => status.dbValue == value,
      orElse: () => GirviStatus.active,
    );
  }

  bool get isActive => this == GirviStatus.active;
  bool get isOverdue => this == GirviStatus.overdue;
  bool get isClosed =>
      this == GirviStatus.released || this == GirviStatus.auctioned;
}

/// Supported pledged metal categories.
enum MetalType {
  gold('Gold', 'Gold'),
  silver('Silver', 'Silver'),
  diamond('Diamond', 'Diamond'),
  platinum('Platinum', 'Platinum'),
  mixed('Mixed', 'Mixed'),
  other('Other', 'Other');

  const MetalType(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static MetalType fromDb(String value) {
    return MetalType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => MetalType.gold,
    );
  }
}

/// Supported purity options and fineness factors.
enum MetalPurity {
  k24('24K', '24K (99.9% Pure)', 0.999),
  k22('22K', '22K (91.6% Pure)', 0.916),
  k18('18K', '18K (75.0% Pure)', 0.750),
  k14('14K', '14K (58.5% Pure)', 0.585),
  s999('999', 'Silver 999 (Fine)', 0.999),
  s925('925', 'Silver 925 (Sterling)', 0.925),
  s800('800', 'Silver 800', 0.800),
  other('Other', 'Other / Custom', 1.000);

  const MetalPurity(this.dbValue, this.displayName, this.fineness);

  final String dbValue;
  final String displayName;
  final double fineness;

  static MetalPurity fromDb(String value) {
    return MetalPurity.values.firstWhere(
      (purity) => purity.dbValue == value,
      orElse: () => MetalPurity.k22,
    );
  }
}

/// Collection and disbursement modes for Girvi entries.
enum GirviPaymentMode {
  cash('Cash', 'Cash'),
  upi('UPI', 'UPI / QR Code'),
  neft('NEFT', 'NEFT / IMPS'),
  bankTransfer('Bank Transfer', 'Bank Transfer'),
  cheque('Cheque', 'Cheque');

  const GirviPaymentMode(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static GirviPaymentMode fromDb(String value) {
    return GirviPaymentMode.values.firstWhere(
      (mode) => mode.dbValue == value,
      orElse: () => GirviPaymentMode.cash,
    );
  }
}

/// Payment ledger entry types stored in Girvi payments.
enum GirviPaymentType {
  interest('INTEREST', 'Interest Payment'),
  partialPrincipal('PARTIAL_PRINCIPAL', 'Partial Principal'),
  partialInterest('PARTIAL_INTEREST', 'Partial Interest'),
  fullRelease('FULL_RELEASE', 'Girvi Release'),
  penalty('PENALTY', 'Penalty / Fine');

  const GirviPaymentType(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static GirviPaymentType fromDb(String value) {
    return GirviPaymentType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => GirviPaymentType.interest,
    );
  }
}

/// Supported identity proof options for Girvi KYC.
enum GirviIdProofType {
  aadhaar('Aadhaar Card', 'Aadhaar Card'),
  pan('PAN Card', 'PAN Card'),
  voterId('Voter ID', 'Voter ID'),
  passport('Passport', 'Passport'),
  drivingLic('Driving License', 'Driving License'),
  rationCard('Ration Card', 'Ration Card'),
  other('Other', 'Other');

  const GirviIdProofType(this.dbValue, this.displayName);

  final String dbValue;
  final String displayName;

  static GirviIdProofType fromDb(String value) {
    return GirviIdProofType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => GirviIdProofType.aadhaar,
    );
  }
}

/// Filters available on the Girvi list screen.
enum GirviFilter {
  all('All'),
  active('Active'),
  overdue('Overdue'),
  settlementPending('Settlement Pending'),
  readyForDelivery('Ready for Delivery'),
  released('Released'),
  auctioned('Auctioned');

  const GirviFilter(this.displayName);

  final String displayName;
}
