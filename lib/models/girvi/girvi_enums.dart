// =============================================================================
// FILE        : girvi_enums.dart
// MODULE      : Girvi / Pawn
// LAYER       : Models / Enums
// DESCRIPTION : All enumerations for the Girvi module.
//               GirviStatus, MetalType, MetalPurity, PaymentMode,
//               DisbursementMode, PaymentType, IdProofType.
//               Each enum has a dbValue (stored in DB) and a displayName
//               (shown in UI) — never hardcode strings in logic or UI.
// =============================================================================

// ════════════════════════════════════════════════════════════════════════════
// 1. GIRVI STATUS
// ════════════════════════════════════════════════════════════════════════════

enum GirviStatus {
  active       ('ACTIVE',          'Active'),
  released     ('RELEASED',        'Released'),
  overdue      ('OVERDUE',         'Overdue'),
  partialRelease('PARTIAL_RELEASE','Partial Release'),
  auctioned    ('AUCTIONED',       'Auctioned'),
  ;

  const GirviStatus(this.dbValue, this.displayName);
  final String dbValue;
  final String displayName;

  static GirviStatus fromDb(String v) =>
      GirviStatus.values.firstWhere((e) => e.dbValue == v,
          orElse: () => GirviStatus.active);

  bool get isActive  => this == GirviStatus.active;
  bool get isOverdue => this == GirviStatus.overdue;
  bool get isClosed  =>
      this == GirviStatus.released || this == GirviStatus.auctioned;
}

// ════════════════════════════════════════════════════════════════════════════
// 2. METAL TYPE
// ════════════════════════════════════════════════════════════════════════════

enum MetalType {
  gold     ('Gold',      'Gold',      '🥇'),
  silver   ('Silver',    'Silver',    '🥈'),
  diamond  ('Diamond',   'Diamond',   '💎'),
  platinum ('Platinum',  'Platinum',  '🔘'),
  mixed    ('Mixed',     'Mixed',     '✨'),
  other    ('Other',     'Other',     '📦'),
  ;

  const MetalType(this.dbValue, this.displayName, this.emoji);
  final String dbValue;
  final String displayName;
  final String emoji;

  static MetalType fromDb(String v) =>
      MetalType.values.firstWhere((e) => e.dbValue == v,
          orElse: () => MetalType.gold);
}

// ════════════════════════════════════════════════════════════════════════════
// 3. METAL PURITY
// ════════════════════════════════════════════════════════════════════════════

enum MetalPurity {
  k24   ('24K',   '24K (99.9% Pure)',    0.999),
  k22   ('22K',   '22K (91.6% Pure)',    0.916),
  k18   ('18K',   '18K (75.0% Pure)',    0.750),
  k14   ('14K',   '14K (58.5% Pure)',    0.585),
  s999  ('999',   'Silver 999 (Fine)',   0.999),
  s925  ('925',   'Silver 925 (Sterlin)',0.925),
  s800  ('800',   'Silver 800',          0.800),
  other ('Other', 'Other / Custom',      1.000),
  ;

  const MetalPurity(this.dbValue, this.displayName, this.fineness);
  final String dbValue;
  final String displayName;
  final double fineness; // for calculation

  static MetalPurity fromDb(String v) =>
      MetalPurity.values.firstWhere((e) => e.dbValue == v,
          orElse: () => MetalPurity.k22);
}

// ════════════════════════════════════════════════════════════════════════════
// 4. PAYMENT / DISBURSEMENT MODE
// ════════════════════════════════════════════════════════════════════════════

enum GirviPaymentMode {
  cash        ('Cash',          'Cash'),
  upi         ('UPI',           'UPI / QR Code'),
  neft        ('NEFT',          'NEFT / IMPS'),
  bankTransfer('Bank Transfer', 'Bank Transfer'),
  cheque      ('Cheque',        'Cheque'),
  ;

  const GirviPaymentMode(this.dbValue, this.displayName);
  final String dbValue;
  final String displayName;

  static GirviPaymentMode fromDb(String v) =>
      GirviPaymentMode.values.firstWhere((e) => e.dbValue == v,
          orElse: () => GirviPaymentMode.cash);
}

// ════════════════════════════════════════════════════════════════════════════
// 5. PAYMENT TYPE (for GirviPayments table)
// ════════════════════════════════════════════════════════════════════════════

enum GirviPaymentType {
  interest        ('INTEREST',          'Interest Payment'),
  partialPrincipal('PARTIAL_PRINCIPAL', 'Partial Principal'),
  partialInterest ('PARTIAL_INTEREST',  'Partial Interest'),
  fullRelease     ('FULL_RELEASE',      'Full Release'),
  penalty         ('PENALTY',           'Penalty / Fine'),
  ;

  const GirviPaymentType(this.dbValue, this.displayName);
  final String dbValue;
  final String displayName;

  static GirviPaymentType fromDb(String v) =>
      GirviPaymentType.values.firstWhere((e) => e.dbValue == v,
          orElse: () => GirviPaymentType.interest);
}

// ════════════════════════════════════════════════════════════════════════════
// 6. ID PROOF TYPE
// ════════════════════════════════════════════════════════════════════════════

enum GirviIdProofType {
  aadhaar      ('Aadhaar Card',     'Aadhaar Card'),
  pan          ('PAN Card',         'PAN Card'),
  voterId      ('Voter ID',         'Voter ID'),
  passport     ('Passport',         'Passport'),
  drivingLic   ('Driving License',  'Driving License'),
  rationCard   ('Ration Card',      'Ration Card'),
  other        ('Other',            'Other'),
  ;

  const GirviIdProofType(this.dbValue, this.displayName);
  final String dbValue;
  final String displayName;

  static GirviIdProofType fromDb(String v) =>
      GirviIdProofType.values.firstWhere((e) => e.dbValue == v,
          orElse: () => GirviIdProofType.aadhaar);
}

// ════════════════════════════════════════════════════════════════════════════
// 7. GIRVI FILTER (for list screen)
// ════════════════════════════════════════════════════════════════════════════

enum GirviFilter {
  all      ('All'),
  active   ('Active'),
  overdue  ('Overdue'),
  released ('Released'),
  auctioned('Auctioned'),
  ;

  const GirviFilter(this.displayName);
  final String displayName;
}
