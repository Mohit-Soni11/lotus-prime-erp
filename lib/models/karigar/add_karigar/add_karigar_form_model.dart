// =============================================================================
// FILE        : add_karigar_form_model.dart
// MODULE      : Karigar → Add Karigar
// LAYER       : Models
// DESCRIPTION : Pure-data form model for the Add/Edit Karigar screen.
//               Holds all field values and inline validation errors.
// =============================================================================

import '../karigar_enums/karigar_enums.dart';

class AddKarigarFormModel {

  // ── 1. IDENTITY ────────────────────────────────────────────────────────────
  final String firstName;
  final String lastName;
  final String? profileImagePath;

  // ── 2. CONTACT ─────────────────────────────────────────────────────────────
  final String  phone;
  final String  alternatePhone;

  // ── 3. PROFESSIONAL ────────────────────────────────────────────────────────
  final KarigarSpecialization specialization;
  final KarigarRateType       rateType;
  final double                rateAmount;

  // ── 4. ADDRESS ─────────────────────────────────────────────────────────────
  final String address;
  final String city;

  // ── 5. FINANCIAL ───────────────────────────────────────────────────────────
  final double openingBalance;

  // ── 6. STATUS & NOTES ──────────────────────────────────────────────────────
  final bool   isActive;
  final String notes;

  // ── VALIDATION ERRORS ──────────────────────────────────────────────────────
  final String? firstNameError;
  final String? phoneError;

  const AddKarigarFormModel({
    this.firstName          = '',
    this.lastName           = '',
    this.profileImagePath,
    this.phone              = '',
    this.alternatePhone     = '',
    this.specialization     = KarigarSpecialization.allMetals,
    this.rateType           = KarigarRateType.perGram,
    this.rateAmount         = 0.0,
    this.address            = '',
    this.city               = '',
    this.openingBalance     = 0.0,
    this.isActive           = true,
    this.notes              = '',
    this.firstNameError,
    this.phoneError,
  });

  // ── COMPUTED ────────────────────────────────────────────────────────────────

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  bool get isValid =>
      firstNameError == null &&
      phoneError == null &&
      firstName.trim().isNotEmpty &&
      phone.trim().isNotEmpty;

  AddKarigarFormModel copyWith({
    String?                firstName,
    String?                lastName,
    String?                profileImagePath,
    bool                   clearProfileImage = false,
    String?                phone,
    String?                alternatePhone,
    KarigarSpecialization? specialization,
    KarigarRateType?       rateType,
    double?                rateAmount,
    String?                address,
    String?                city,
    double?                openingBalance,
    bool?                  isActive,
    String?                notes,
    String?                firstNameError,
    bool                   clearFirstNameError = false,
    String?                phoneError,
    bool                   clearPhoneError = false,
  }) {
    return AddKarigarFormModel(
      firstName:          firstName         ?? this.firstName,
      lastName:           lastName          ?? this.lastName,
      profileImagePath:   clearProfileImage ? null : (profileImagePath ?? this.profileImagePath),
      phone:              phone             ?? this.phone,
      alternatePhone:     alternatePhone    ?? this.alternatePhone,
      specialization:     specialization    ?? this.specialization,
      rateType:           rateType          ?? this.rateType,
      rateAmount:         rateAmount        ?? this.rateAmount,
      address:            address           ?? this.address,
      city:               city              ?? this.city,
      openingBalance:     openingBalance    ?? this.openingBalance,
      isActive:           isActive          ?? this.isActive,
      notes:              notes             ?? this.notes,
      firstNameError:     clearFirstNameError ? null : (firstNameError ?? this.firstNameError),
      phoneError:         clearPhoneError   ? null : (phoneError ?? this.phoneError),
    );
  }

  factory AddKarigarFormModel.empty() => const AddKarigarFormModel();
}
