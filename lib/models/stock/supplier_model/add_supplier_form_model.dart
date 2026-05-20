import 'supplier_enums.dart';
import 'supplier_model.dart';

enum SupplierActiveField {
  none,
  businessName,
  contactPerson,
  mobile,
  whatsapp,
  email,
  alternateContact,
  panNumber,
  gstNumber,
  addressLine1,
  addressLine2,
  state,
  pincode,
  openingBalance,
  notes,
}

class AddSupplierFormModel {
  final int? id;
  final String businessName;
  final String contactPersonName;
  final SupplierType supplierType;
  final String mobile;
  final bool sameAsWhatsApp;
  final String whatsapp;
  final String email;
  final String alternateContact;
  final String panNumber;
  final String gstNumber;
  final String addressLine1;
  final String addressLine2;
  final String state;
  final String pincode;
  final String country;
  final double openingBalance;
  final String notes;

  final String? businessNameError;
  final String? mobileError;
  final String? whatsappError;
  final String? emailError;
  final String? panError;
  final String? gstError;
  final String? pincodeError;
  final String? openingBalanceError;

  const AddSupplierFormModel({
    this.id,
    this.businessName = '',
    this.contactPersonName = '',
    this.supplierType = SupplierType.manufacturer,
    this.mobile = '',
    this.sameAsWhatsApp = true,
    this.whatsapp = '',
    this.email = '',
    this.alternateContact = '',
    this.panNumber = '',
    this.gstNumber = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.state = '',
    this.pincode = '',
    this.country = 'India',
    this.openingBalance = 0.0,
    this.notes = '',
    this.businessNameError,
    this.mobileError,
    this.whatsappError,
    this.emailError,
    this.panError,
    this.gstError,
    this.pincodeError,
    this.openingBalanceError,
  });

  bool get isReadyToSave =>
      businessName.trim().isNotEmpty &&
      mobile.replaceAll(RegExp(r'\D'), '').length == 10 &&
      businessNameError == null &&
      mobileError == null &&
      whatsappError == null &&
      emailError == null &&
      panError == null &&
      gstError == null &&
      pincodeError == null &&
      openingBalanceError == null;

  String get displayName =>
      businessName.trim().isEmpty ? 'New Supplier' : businessName.trim();

  String get avatarInitials {
    final name = displayName;
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  SupplierModel toSupplierModel() {
    return SupplierModel(
      id: id,
      businessName: businessName.trim(),
      contactPersonName: _nullable(contactPersonName),
      supplierType: supplierType,
      mobile: mobile.trim(),
      whatsapp: _nullable(whatsapp),
      email: _nullable(email),
      alternateContact: _nullable(alternateContact),
      panNumber: _nullable(panNumber)?.toUpperCase(),
      gstNumber: _nullable(gstNumber)?.toUpperCase(),
      addressLine1: _nullable(addressLine1),
      addressLine2: _nullable(addressLine2),
      state: _nullable(state),
      pincode: _nullable(pincode),
      country: country.trim().isEmpty ? 'India' : country.trim(),
      openingBalance: openingBalance,
      notes: _nullable(notes),
    );
  }

  factory AddSupplierFormModel.fromSupplier(SupplierModel supplier) {
    final whatsapp = supplier.whatsapp ?? '';
    return AddSupplierFormModel(
      id: supplier.id,
      businessName: supplier.businessName,
      contactPersonName: supplier.contactPersonName ?? '',
      supplierType: supplier.supplierType,
      mobile: supplier.mobile,
      sameAsWhatsApp: whatsapp == supplier.mobile,
      whatsapp: whatsapp,
      email: supplier.email ?? '',
      alternateContact: supplier.alternateContact ?? '',
      panNumber: supplier.panNumber ?? '',
      gstNumber: supplier.gstNumber ?? '',
      addressLine1: supplier.addressLine1 ?? '',
      addressLine2: supplier.addressLine2 ?? '',
      state: supplier.state ?? '',
      pincode: supplier.pincode ?? '',
      country: supplier.country,
      openingBalance: supplier.openingBalance,
      notes: supplier.notes ?? '',
    );
  }

  AddSupplierFormModel copyWith({
    int? id,
    String? businessName,
    String? contactPersonName,
    SupplierType? supplierType,
    String? mobile,
    bool? sameAsWhatsApp,
    String? whatsapp,
    String? email,
    String? alternateContact,
    String? panNumber,
    String? gstNumber,
    String? addressLine1,
    String? addressLine2,
    String? state,
    String? pincode,
    String? country,
    double? openingBalance,
    String? notes,
    String? businessNameError,
    String? mobileError,
    String? whatsappError,
    String? emailError,
    String? panError,
    String? gstError,
    String? pincodeError,
    String? openingBalanceError,
    bool clearBusinessNameError = false,
    bool clearMobileError = false,
    bool clearWhatsappError = false,
    bool clearEmailError = false,
    bool clearPanError = false,
    bool clearGstError = false,
    bool clearPincodeError = false,
    bool clearOpeningBalanceError = false,
  }) {
    return AddSupplierFormModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      supplierType: supplierType ?? this.supplierType,
      mobile: mobile ?? this.mobile,
      sameAsWhatsApp: sameAsWhatsApp ?? this.sameAsWhatsApp,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      alternateContact: alternateContact ?? this.alternateContact,
      panNumber: panNumber ?? this.panNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      openingBalance: openingBalance ?? this.openingBalance,
      notes: notes ?? this.notes,
      businessNameError: clearBusinessNameError
          ? null
          : businessNameError ?? this.businessNameError,
      mobileError: clearMobileError ? null : mobileError ?? this.mobileError,
      whatsappError:
          clearWhatsappError ? null : whatsappError ?? this.whatsappError,
      emailError: clearEmailError ? null : emailError ?? this.emailError,
      panError: clearPanError ? null : panError ?? this.panError,
      gstError: clearGstError ? null : gstError ?? this.gstError,
      pincodeError:
          clearPincodeError ? null : pincodeError ?? this.pincodeError,
      openingBalanceError: clearOpeningBalanceError
          ? null
          : openingBalanceError ?? this.openingBalanceError,
    );
  }
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
