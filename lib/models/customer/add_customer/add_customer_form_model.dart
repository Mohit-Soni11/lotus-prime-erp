// =============================================================================
// FILE        : add_customer_form_model.dart
// MODULE      : Customer → Add New Customer
// LAYER       : Models
// DESCRIPTION : Immutable form model + FamilyMember sub-model.
// VERSION     : 2.0 — Full expansion
// =============================================================================

import 'dart:convert';
import '../customer_enums/add_customer_enums.dart';
import 'package:flutter/foundation.dart';

// =============================================================================
// FAMILY MEMBER MODEL
// =============================================================================

@immutable
class FamilyMember {
  final String id;
  final String name;
  final FamilyRelation relation;
  final DateTime? dateOfBirth;

  const FamilyMember({
    required this.id,
    this.name = '',
    this.relation = FamilyRelation.spouse,
    this.dateOfBirth,
  });

  FamilyMember copyWith({
    String? name,
    FamilyRelation? relation,
    DateTime? dateOfBirth,
    bool clearDob = false,
  }) {
    return FamilyMember(
      id: id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      dateOfBirth: clearDob ? null : (dateOfBirth ?? this.dateOfBirth),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'relation': relation.label,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
      };

  static FamilyMember fromJson(Map<String, dynamic> json, String id) {
    return FamilyMember(
      id: id,
      name: json['name'] ?? '',
      relation: FamilyRelation.fromLabel(json['relation'] ?? ''),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
    );
  }

  static String encodeList(List<FamilyMember> members) {
    return jsonEncode(members.map((m) => m.toJson()).toList());
  }

  static List<FamilyMember> decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .asMap()
          .entries
          .map((e) => FamilyMember.fromJson(e.value, 'fm_${e.key}'))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

// =============================================================================
// MAIN FORM MODEL
// =============================================================================

@immutable
class AddCustomerFormModel {
  // ── Entity ─────────────────────────────────────────────────────────────────
  final CustomerEntityType entityType;

  // ── Personal ───────────────────────────────────────────────────────────────
  final String firstName;
  final String lastName;
  final String companyName;
  final String contactPersonName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final DateTime? anniversaryDate;

  // ── Contact ────────────────────────────────────────────────────────────────
  final String mobile;
  final bool sameAsWhatsApp;
  final String whatsapp;
  final String email;
  final String alternateContact;

  // ── KYC ───────────────────────────────────────────────────────────────────
  final String panNumber;
  final IdProofType? idProofType;
  final String idProofNumber;
  final String? idProofDocPath;
  final String gstNumber;

  // ── Address ────────────────────────────────────────────────────────────────
  final String addressLine1;
  final String addressLine2;
  final String country;
  final String state;
  final String city;
  final String pincode;

  // ── Billing ────────────────────────────────────────────────────────────────
  final double openingBalance;
  final double creditLimit;
  final CustomerTier customerTier;
  final String membershipId;

  // ── Preferences ────────────────────────────────────────────────────────────
  final RingSize? ringSize;
  final BangleSize? bangleSize;
  final List<FamilyMember> familyMembers;

  // ── Additional ─────────────────────────────────────────────────────────────
  final ReferralSource? referralSource;
  final String notes;
  final String? profileImagePath;

  // ── Validation Errors ─────────────────────────────────────────────────────
  final String? firstNameError;
  final String? mobileError;
  final String? panError;
  final String? emailError;

  // ── Legacy ────────────────────────────────────────────────────────────────
  final NewCustomerType type;

  const AddCustomerFormModel({
    this.entityType = CustomerEntityType.individual,
    this.firstName = '',
    this.lastName = '',
    this.companyName = '',
    this.contactPersonName = '',
    this.dateOfBirth,
    this.gender,
    this.anniversaryDate,
    this.mobile = '',
    this.sameAsWhatsApp = false,
    this.whatsapp = '',
    this.email = '',
    this.alternateContact = '',
    this.panNumber = '',
    this.idProofType,
    this.idProofNumber = '',
    this.idProofDocPath,
    this.gstNumber = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.country = 'India',
    this.state = '',
    this.city = '',
    this.pincode = '',
    this.openingBalance = 0.0,
    this.creditLimit = 0.0,
    this.customerTier = CustomerTier.regular,
    this.membershipId = '',
    this.ringSize,
    this.bangleSize,
    this.familyMembers = const [],
    this.referralSource,
    this.notes = '',
    this.profileImagePath,
    this.firstNameError,
    this.mobileError,
    this.panError,
    this.emailError,
    this.type = NewCustomerType.regular,
  });

  bool get hasErrors =>
      firstNameError != null ||
      mobileError != null ||
      panError != null ||
      emailError != null;

  bool get isCorporate => entityType == CustomerEntityType.corporate;

  String get displayName {
    if (isCorporate) {
      return companyName.trim().isEmpty ? 'New Corporate' : companyName.trim();
    }
    final fn = firstName.trim();
    final ln = lastName.trim();
    if (fn.isEmpty) return 'New Customer';
    return ln.isEmpty ? fn : '$fn $ln';
  }

  bool get isReadyToSave {
    if (hasErrors) return false;
    if (isCorporate) {
      return companyName.trim().isNotEmpty;
    }
    return firstName.trim().isNotEmpty;
  }

  AddCustomerFormModel copyWith({
    CustomerEntityType? entityType,
    String? firstName,
    String? lastName,
    String? companyName,
    String? contactPersonName,
    DateTime? dateOfBirth,
    bool clearDob = false,
    Gender? gender,
    bool clearGender = false,
    DateTime? anniversaryDate,
    bool clearAnniversary = false,
    String? mobile,
    bool? sameAsWhatsApp,
    String? whatsapp,
    String? email,
    String? alternateContact,
    String? panNumber,
    IdProofType? idProofType,
    bool clearIdProofType = false,
    String? idProofNumber,
    String? idProofDocPath,
    bool clearIdProofDocPath = false,
    String? gstNumber,
    String? addressLine1,
    String? addressLine2,
    String? country,
    String? state,
    String? city,
    String? pincode,
    double? openingBalance,
    double? creditLimit,
    CustomerTier? customerTier,
    String? membershipId,
    RingSize? ringSize,
    bool clearRingSize = false,
    BangleSize? bangleSize,
    bool clearBangleSize = false,
    List<FamilyMember>? familyMembers,
    ReferralSource? referralSource,
    bool clearReferralSource = false,
    String? notes,
    String? profileImagePath,
    bool clearProfileImage = false,
    String? firstNameError,
    bool clearFirstNameError = false,
    String? mobileError,
    bool clearMobileError = false,
    String? panError,
    bool clearPanError = false,
    String? emailError,
    bool clearEmailError = false,
    NewCustomerType? type,
  }) {
    return AddCustomerFormModel(
      entityType: entityType ?? this.entityType,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      companyName: companyName ?? this.companyName,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      dateOfBirth: clearDob ? null : (dateOfBirth ?? this.dateOfBirth),
      gender: clearGender ? null : (gender ?? this.gender),
      anniversaryDate:
          clearAnniversary ? null : (anniversaryDate ?? this.anniversaryDate),
      mobile: mobile ?? this.mobile,
      sameAsWhatsApp: sameAsWhatsApp ?? this.sameAsWhatsApp,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      alternateContact: alternateContact ?? this.alternateContact,
      panNumber: panNumber ?? this.panNumber,
      idProofType: clearIdProofType ? null : (idProofType ?? this.idProofType),
      idProofNumber: idProofNumber ?? this.idProofNumber,
      idProofDocPath:
          clearIdProofDocPath ? null : (idProofDocPath ?? this.idProofDocPath),
      gstNumber: gstNumber ?? this.gstNumber,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      openingBalance: openingBalance ?? this.openingBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      customerTier: customerTier ?? this.customerTier,
      membershipId: membershipId ?? this.membershipId,
      ringSize: clearRingSize ? null : (ringSize ?? this.ringSize),
      bangleSize: clearBangleSize ? null : (bangleSize ?? this.bangleSize),
      familyMembers: familyMembers ?? this.familyMembers,
      referralSource:
          clearReferralSource ? null : (referralSource ?? this.referralSource),
      notes: notes ?? this.notes,
      profileImagePath: clearProfileImage
          ? null
          : (profileImagePath ?? this.profileImagePath),
      firstNameError:
          clearFirstNameError ? null : (firstNameError ?? this.firstNameError),
      mobileError: clearMobileError ? null : (mobileError ?? this.mobileError),
      panError: clearPanError ? null : (panError ?? this.panError),
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      type: type ?? this.type,
    );
  }
}
