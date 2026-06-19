// =============================================================================
// FILE        : supplier_model.dart
// MODULE      : Supplier
// LAYER       : Models
// DESCRIPTION : Pure data model for Supplier / Manufacturer.
//               Immutable + copyWith — mirrors CustomerListItemModel pattern.
// =============================================================================

import 'supplier_enums.dart';
import 'package:flutter/foundation.dart';

class SupplierModel {
  final int? id;
  final String businessName;
  final String? contactPersonName;
  final SupplierType supplierType;
  final String mobile;
  final String? whatsapp;
  final String? email;
  final String? alternateContact;
  final String? panNumber;
  final String? gstNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? state;
  final String? pincode;
  final String country;
  final double openingBalance;
  final String? notes;
  final SupplierStatus status;
  final DateTime? createdAt;

  const SupplierModel({
    this.id,
    required this.businessName,
    this.contactPersonName,
    this.supplierType = SupplierType.manufacturer,
    required this.mobile,
    this.whatsapp,
    this.email,
    this.alternateContact,
    this.panNumber,
    this.gstNumber,
    this.addressLine1,
    this.addressLine2,
    this.state,
    this.pincode,
    this.country = 'India',
    this.openingBalance = 0.0,
    this.notes,
    this.status = SupplierStatus.active,
    this.createdAt,
  });

  static SupplierModel empty() => const SupplierModel(
        businessName: '',
        mobile: '',
      );

  // ── DISPLAY HELPERS ─────────────────────────────────────────────────────

  /// Short display name for dropdowns / chips / autocomplete
  String get displayName => businessName.isNotEmpty ? businessName : mobile;

  /// Avatar initials (first letter of business name)
  String get avatarInitial =>
      businessName.isNotEmpty ? businessName[0].toUpperCase() : 'S';

  /// Formatted city + state line
  String get locationLine {
    final parts = [state].where((e) => e != null && e.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : '';
  }

  // ── copyWith ────────────────────────────────────────────────────────────
  SupplierModel copyWith({
    int? id,
    String? businessName,
    String? contactPersonName,
    SupplierType? supplierType,
    String? mobile,
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
    SupplierStatus? status,
    DateTime? createdAt,
  }) =>
      SupplierModel(
        id: id ?? this.id,
        businessName: businessName ?? this.businessName,
        contactPersonName: contactPersonName ?? this.contactPersonName,
        supplierType: supplierType ?? this.supplierType,
        mobile: mobile ?? this.mobile,
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
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
}

// =============================================================================
// Lightweight model for Supplier List cards (avoids loading all fields)
// =============================================================================

class SupplierListItemModel {
  final int id;
  final String businessName;
  final String? contactPersonName;
  final String mobile;
  final String? gstNumber;
  final SupplierType supplierType;
  final SupplierStatus status;
  final DateTime? createdAt;

  const SupplierListItemModel({
    required this.id,
    required this.businessName,
    this.contactPersonName,
    required this.mobile,
    this.gstNumber,
    required this.supplierType,
    required this.status,
    this.createdAt,
  });

  String get displayName => businessName;
  String get avatarInitial =>
      businessName.isNotEmpty ? businessName[0].toUpperCase() : 'S';
}
