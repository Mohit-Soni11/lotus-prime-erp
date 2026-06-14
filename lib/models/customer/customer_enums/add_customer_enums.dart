// =============================================================================
// FILE        : add_customer_enums.dart
// MODULE      : Customer → Add New Customer
// LAYER       : Models / Enums
// VERSION     : 2.0 — Full expansion
// =============================================================================

// ── 1. CUSTOMER ENTITY TYPE ──────────────────────────────────────────────────
enum CustomerEntityType {
  individual('Individual'),
  corporate('Corporate');

  final String label;
  const CustomerEntityType(this.label);

  static CustomerEntityType fromLabel(String l) =>
      CustomerEntityType.values.firstWhere((e) => e.label == l,
          orElse: () => CustomerEntityType.individual);
}

// ── 2. CUSTOMER TIER ─────────────────────────────────────────────────────────
enum CustomerTier {
  regular(
    'Regular',
    'Standard',
    'Everyday client profile',
  ),
  silver(
    'Silver',
    'Silver',
    'Growing client relationship',
  ),
  gold(
    'Gold',
    'Gold',
    'High-value purchase profile',
  ),
  vip(
    'VIP',
    'Elite',
    'Priority client account',
  );

  /// Stable database label. Keep this compatible with existing saved records.
  final String label;
  final String displayLabel;
  final String description;

  const CustomerTier(this.label, this.displayLabel, this.description);

  static CustomerTier fromLabel(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'standard') return CustomerTier.regular;
    if (normalized == 'elite') return CustomerTier.vip;

    return CustomerTier.values.firstWhere(
      (tier) =>
          tier.label.toLowerCase() == normalized ||
          tier.displayLabel.toLowerCase() == normalized,
      orElse: () => CustomerTier.regular,
    );
  }
}

// ── 3. GENDER ────────────────────────────────────────────────────────────────
enum Gender {
  male('Male'),
  female('Female'),
  other('Other');

  final String label;
  const Gender(this.label);

  static Gender fromLabel(String l) =>
      Gender.values.firstWhere((e) => e.label == l, orElse: () => Gender.male);
}

// ── 4. ID PROOF TYPE ─────────────────────────────────────────────────────────
enum IdProofType {
  aadhar('Aadhar Card'),
  pan('PAN Card'),
  drivingLicense('Driving License'),
  passport('Passport'),
  voterId('Voter ID'),
  rationCard('Ration Card'),
  other('Other');

  final String label;
  const IdProofType(this.label);

  static IdProofType fromLabel(String l) => IdProofType.values
      .firstWhere((e) => e.label == l, orElse: () => IdProofType.aadhar);
}

// ── 5. RING SIZE ──────────────────────────────────────────────────────────────
enum RingSize {
  size6('Size 6'),
  size7('Size 7'),
  size8('Size 8'),
  size9('Size 9'),
  size10('Size 10'),
  size11('Size 11'),
  size12('Size 12'),
  size13('Size 13'),
  size14('Size 14'),
  size15('Size 15'),
  size16('Size 16'),
  size17('Size 17'),
  size18('Size 18'),
  size19('Size 19'),
  size20('Size 20'),
  notKnown('Not Known');

  final String label;
  const RingSize(this.label);
}

// ── 6. BANGLE SIZE ───────────────────────────────────────────────────────────
enum BangleSize {
  s22('2.2 inches'),
  s24('2.4 inches'),
  s26('2.6 inches'),
  s28('2.8 inches'),
  s30('3.0 inches'),
  s32('3.2 inches'),
  s34('3.4 inches'),
  notKnown('Not Known');

  final String label;
  const BangleSize(this.label);
}

// ── 7. FAMILY RELATION ───────────────────────────────────────────────────────
enum FamilyRelation {
  spouse('Spouse'),
  child('Child'),
  parent('Parent'),
  sibling('Sibling'),
  other('Other');

  final String label;
  const FamilyRelation(this.label);

  static FamilyRelation fromLabel(String l) => FamilyRelation.values
      .firstWhere((e) => e.label == l, orElse: () => FamilyRelation.other);
}

// ── 8. REFERRAL SOURCE ───────────────────────────────────────────────────────
enum ReferralSource {
  walkIn('Walk-in'),
  socialMedia('Social Media'),
  friendReferral('Friend Referral'),
  advertisement('Advertisement'),
  onlineSearch('Online Search'),
  existingCustomer('Existing Customer'),
  exhibition('Exhibition / Mela'),
  other('Other');

  final String label;
  const ReferralSource(this.label);
}

// ── 9. INDIA STATES ───────────────────────────────────────────────────────────
enum IndiaState {
  ap('Andhra Pradesh'),
  ar('Arunachal Pradesh'),
  as_('Assam'),
  br('Bihar'),
  cg('Chhattisgarh'),
  ga('Goa'),
  gj('Gujarat'),
  hr('Haryana'),
  hp('Himachal Pradesh'),
  jh('Jharkhand'),
  ka('Karnataka'),
  kl('Kerala'),
  mp('Madhya Pradesh'),
  mh('Maharashtra'),
  mn('Manipur'),
  ml('Meghalaya'),
  mz('Mizoram'),
  nl('Nagaland'),
  od('Odisha'),
  pb('Punjab'),
  rj('Rajasthan'),
  sk('Sikkim'),
  tn('Tamil Nadu'),
  tg('Telangana'),
  tr('Tripura'),
  up('Uttar Pradesh'),
  uk('Uttarakhand'),
  wb('West Bengal'),
  dl('Delhi'),
  jk('Jammu & Kashmir'),
  la('Ladakh'),
  other('Other');

  final String label;
  const IndiaState(this.label);
}

// ── 10. FORM SAVE STATE ──────────────────────────────────────────────────────
enum SaveState {
  idle,
  validating,
  saving,
  success,
  error,
  duplicate,
}

// ── 11. ACTIVE FIELD ─────────────────────────────────────────────────────────
enum ActiveField {
  none,
  firstName,
  lastName,
  companyName,
  contactPerson,
  mobile,
  whatsapp,
  email,
  alternateContact,
  panNumber,
  idProofNumber,
  gstNumber,
  addressLine1,
  addressLine2,
  pincode,
  openingBalance,
  creditLimit,
  membershipId,
  notes,
}

// ── LEGACY (kept for old code compatibility) ─────────────────────────────────
enum NewCustomerType {
  regular,
  vip;

  String get value {
    switch (this) {
      case NewCustomerType.regular:
        return 'Regular';
      case NewCustomerType.vip:
        return 'VIP';
    }
  }
}
