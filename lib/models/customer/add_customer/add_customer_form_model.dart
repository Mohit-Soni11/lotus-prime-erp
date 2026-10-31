// =============================================================================
// FILE        : add_customer_form_model.dart
// MODULE      : Customer → Add New Customer
// LAYER       : Models
// DESCRIPTION : Immutable customer registration form.
// VERSION     : 2.0 — Full expansion
// =============================================================================

import '../customer_enums/add_customer_enums.dart';
import '../customer_enums/customer_list_enums.dart';
import 'package:flutter/foundation.dart';

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
  final Gender? gender;

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

  // ── Customer category ─────────────────────────────────────────────────────
  final CustomerType customerTier;
  final String? profileImagePath;

  // ── Validation Errors ─────────────────────────────────────────────────────
  final String? firstNameError;
  final String? companyNameError;
  final String? mobileError;
  final String? whatsappError;
  final String? alternateContactError;
  final String? panError;
  final String? idProofError;
  final String? gstError;
  final String? emailError;
  final String? pincodeError;

  const AddCustomerFormModel({
    this.entityType = CustomerEntityType.individual,
    this.firstName = '',
    this.lastName = '',
    this.companyName = '',
    this.contactPersonName = '',
    this.gender,
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
    this.customerTier = CustomerType.standard,
    this.profileImagePath,
    this.firstNameError,
    this.companyNameError,
    this.mobileError,
    this.whatsappError,
    this.alternateContactError,
    this.panError,
    this.idProofError,
    this.gstError,
    this.emailError,
    this.pincodeError,
  });

  bool get hasErrors =>
      firstNameError != null ||
      companyNameError != null ||
      mobileError != null ||
      whatsappError != null ||
      alternateContactError != null ||
      panError != null ||
      idProofError != null ||
      gstError != null ||
      emailError != null ||
      pincodeError != null;

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
    Gender? gender,
    bool clearGender = false,
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
    CustomerType? customerTier,
    String? profileImagePath,
    bool clearProfileImage = false,
    String? firstNameError,
    bool clearFirstNameError = false,
    String? companyNameError,
    bool clearCompanyNameError = false,
    String? mobileError,
    bool clearMobileError = false,
    String? whatsappError,
    bool clearWhatsappError = false,
    String? alternateContactError,
    bool clearAlternateContactError = false,
    String? panError,
    bool clearPanError = false,
    String? idProofError,
    bool clearIdProofError = false,
    String? gstError,
    bool clearGstError = false,
    String? emailError,
    bool clearEmailError = false,
    String? pincodeError,
    bool clearPincodeError = false,
  }) {
    return AddCustomerFormModel(
      entityType: entityType ?? this.entityType,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      companyName: companyName ?? this.companyName,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      gender: clearGender ? null : (gender ?? this.gender),
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
      customerTier: customerTier ?? this.customerTier,
      profileImagePath: clearProfileImage
          ? null
          : (profileImagePath ?? this.profileImagePath),
      firstNameError:
          clearFirstNameError ? null : (firstNameError ?? this.firstNameError),
      companyNameError: clearCompanyNameError
          ? null
          : (companyNameError ?? this.companyNameError),
      mobileError: clearMobileError ? null : (mobileError ?? this.mobileError),
      whatsappError:
          clearWhatsappError ? null : (whatsappError ?? this.whatsappError),
      alternateContactError: clearAlternateContactError
          ? null
          : (alternateContactError ?? this.alternateContactError),
      panError: clearPanError ? null : (panError ?? this.panError),
      idProofError:
          clearIdProofError ? null : (idProofError ?? this.idProofError),
      gstError: clearGstError ? null : (gstError ?? this.gstError),
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      pincodeError:
          clearPincodeError ? null : (pincodeError ?? this.pincodeError),
    );
  }
}
