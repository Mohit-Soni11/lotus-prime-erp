// =============================================================================
// FILE        : add_customer_enums.dart
// MODULE      : Customer → Add New Customer
// LAYER       : Models / Enums
// DESCRIPTION : Customer registration values and saved category mapping.
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
  validationError,
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
}
